import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/config.dart';

/// Modelo de mensaje
class ChatMessage {
  final String
  senderRole; // e.g. 'ROLE_PATIENT', 'ROLE_ADMIN' (doctor), o 'SYSTEM'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.senderRole,
    required this.content,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final String doctorUuid;

  const ChatScreen({Key? key, required this.doctorUuid}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _storage = const FlutterSecureStorage();

  StompClient? _stompClient;
  String? _token;
  String? _patientUuid;
  bool _isConnected = false;
  bool _isDisposed = false;

  // Ahora guardamos una lista de ChatMessage
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    if (_isDisposed) return;

    _token = await _storage.read(key: 'token');
    _patientUuid = await _storage.read(key: 'patient_uuid');

    if (_token == null || _patientUuid == null) {
      if (mounted && !_isDisposed) {
        setState(
          () => _messages.add(
            ChatMessage(
              senderRole: 'SYSTEM',
              content: '❌ Error: credenciales no encontradas.',
              timestamp: DateTime.now(),
            ),
          ),
        );
      }
      return;
    }

    // 1) Cargar mensajes antiguos
    await _loadPastMessages();

    // 2) Conectar STOMP solo si el widget sigue montado
    if (mounted && !_isDisposed) {
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    try {
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: '${Config.BASE_URL}/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $_token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
          beforeConnect: () async {
            await Future.delayed(const Duration(milliseconds: 200));
          },
          onConnect: _onConnect,
          onStompError: (f) {
            debugPrint('STOMP Error: ${f.body}');
            if (mounted && !_isDisposed) {
              setState(() => _isConnected = false);
            }
          },
          onWebSocketError: (e) {
            debugPrint('WS Error: $e');
            if (mounted && !_isDisposed) {
              setState(() => _isConnected = false);
            }
          },
          onDisconnect: (_) {
            debugPrint('🔌 Desconectado');
            if (mounted && !_isDisposed) {
              setState(() => _isConnected = false);
            }
          },
        ),
      );

      _stompClient?.activate();
    } catch (e) {
      debugPrint('Error conectando WebSocket: $e');
      if (mounted && !_isDisposed) {
        setState(() => _isConnected = false);
      }
    }
  }

  Future<void> _loadPastMessages() async {
    if (_isDisposed) return;

    final uri = Uri.parse(
      '${Config.BASE_URL}/api/v1/conversations/${widget.doctorUuid}/$_patientUuid?page=0&size=50',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final loaded = data.map(
          (m) => ChatMessage(
            senderRole: m['senderRole'],
            content: m['content'],
            timestamp: DateTime.parse(m['createdAt']).toUtc().toLocal(),
          ),
        );

        if (mounted && !_isDisposed) {
          setState(() {
            // mantenemos orden cronológico
            _messages.addAll(loaded.toList().reversed);
          });
          _scrollToBottom();
        }
      } else {
        debugPrint('Error cargando mensajes antiguos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error cargando mensajes: $e');
    }
  }

  void _onConnect(StompFrame frame) {
    if (_isDisposed) return;

    if (mounted) {
      setState(() => _isConnected = true);
    }

    final dest = '/topic/chat.${widget.doctorUuid}.$_patientUuid';

    try {
      _stompClient?.subscribe(
        destination: dest,
        callback: (f) {
          if (_isDisposed) return;

          try {
            final body = json.decode(f.body!);
            final role = body['senderRole'];
            final content = body['content'];
            // parsear como UTC y luego convertir a tu hora local
            final createdAt = DateTime.parse(
              body['createdAt'],
            ).toUtc().toLocal();

            // ignorar tus ecos
            if (role == 'ROLE_PATIENT') return;

            if (mounted && !_isDisposed) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    senderRole: role,
                    content: content,
                    timestamp: createdAt,
                  ),
                );
              });
              _scrollToBottom();
            }
          } catch (e) {
            debugPrint('Error procesando mensaje: $e');
          }
        },
      );
    } catch (e) {
      debugPrint('Error suscribiéndose al chat: $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected || _isDisposed || _stompClient == null)
      return;

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            senderRole: 'ROLE_PATIENT',
            content: text,
            timestamp: DateTime.now().toLocal(),
          ),
        );
      });
    }

    try {
      _stompClient?.send(
        destination: '/app/chat/${widget.doctorUuid}/$_patientUuid/send',
        body: jsonEncode({'content': text, 'type': 'TEXT', 'fileUrl': null}),
      );
    } catch (e) {
      debugPrint('Error enviando mensaje: $e');
    }

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_isDisposed) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Desconectar WebSocket de forma segura
    try {
      _stompClient?.deactivate();
    } catch (e) {
      debugPrint('Error desactivando STOMP client: $e');
    }

    // Limpiar controladores
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 44, 194, 49),
                    Color.fromARGB(255, 105, 96, 197),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Asegurar limpieza antes de navegar hacia atrás
                            _isDisposed = true;
                            try {
                              _stompClient?.deactivate();
                            } catch (e) {
                              debugPrint(
                                'Error desactivando STOMP en back: $e',
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Indicador de conexión
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isConnected ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isConnected ? 'Conectado' : 'Desconectado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chat con tu Doctor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comunicación segura y privada',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ─── LISTA DE MENSAJES ─────────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      reverse: false,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];

                        // Si es mensaje de sistema, lo centramos
                        if (msg.senderRole == 'SYSTEM') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    44,
                                    194,
                                    49,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  msg.content,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color.fromARGB(255, 44, 194, 49),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final isPatient = msg.senderRole == 'ROLE_PATIENT';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: isPatient
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isPatient
                                      ? const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 44, 194, 49),
                                            Color.fromARGB(255, 105, 96, 197),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isPatient ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isPatient
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  DateFormat('HH:mm').format(
                                    msg.timestamp.subtract(
                                      const Duration(hours: 5),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ─── CAJA DE TEXTO + BOTÓN ENVIAR ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isConnected
                          ? const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 44, 194, 49),
                                Color.fromARGB(255, 105, 96, 197),
                              ],
                            )
                          : null,
                      color: _isConnected ? null : Colors.grey,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _isConnected ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 44, 194, 49),
                  Color.fromARGB(255, 105, 96, 197),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Inicia la conversación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envía tu primer mensaje para comenzar\nel chat con tu doctor',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
