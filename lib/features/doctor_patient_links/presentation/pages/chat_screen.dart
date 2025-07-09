// lib/features/doctor_patient_links/presentation/chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/config.dart';

/// Modelo de mensaje
class ChatMessage {
  final String senderRole;   // e.g. 'ROLE_PATIENT', 'ROLE_ADMIN' (doctor), o 'SYSTEM'
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
  late StompClient _stompClient;

  String? _token;
  String? _patientUuid;

  // Ahora guardamos una lista de ChatMessage
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _token = await _storage.read(key: 'token');
    _patientUuid = await _storage.read(key: 'patient_uuid');
    if (_token == null || _patientUuid == null) {
      setState(() => _messages.add(
            ChatMessage(
              senderRole: 'SYSTEM',
              content: '❌ Error: credenciales no encontradas.',
              timestamp: DateTime.now(),
            ),
          ));
      return;
    }

    // 1) Cargar mensajes antiguos
    await _loadPastMessages();

    // 2) Conectar STOMP
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${Config.BASE_URL}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        beforeConnect: () async {
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onConnect: _onConnect,
        onStompError: (f) => debugPrint('STOMP Error: ${f.body}'),
        onWebSocketError: (e) => debugPrint('WS Error: $e'),
        onDisconnect: (_) => debugPrint('🔌 Desconectado'),
      ),
    )..activate();
  }

  Future<void> _loadPastMessages() async {
    final uri = Uri.parse(
      '${Config.BASE_URL}/api/v1/conversations/${widget.doctorUuid}/$_patientUuid?page=0&size=50',
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      final loaded = data.map((m) => ChatMessage(
            senderRole: m['senderRole'],
            content: m['content'],
            timestamp: DateTime.parse(m['createdAt']).toUtc().toLocal(),
          ));
      setState(() {
        // mantenemos orden cronológico
        _messages.addAll(loaded.toList().reversed);
      });
      _scrollToBottom();
    } else {
      debugPrint('Error cargando mensajes antiguos: ${response.statusCode}');
    }
  }

  void _onConnect(StompFrame frame) {
  final dest = '/topic/chat.${widget.doctorUuid}.$_patientUuid';
  _stompClient.subscribe(
    destination: dest,
    callback: (f) {
      final body = json.decode(f.body!);
      final role = body['senderRole'];
      final content = body['content'];

      // parsear como UTC y luego convertir a tu hora local
      final createdAt = DateTime.parse(body['createdAt'])
                              .toUtc()
                              .toLocal();

      // ignorar tus ecos
      if (role == 'ROLE_PATIENT') return;

      setState(() {
        _messages.add(ChatMessage(
          senderRole: role,
          content: content,
          timestamp: createdAt,
        ));
      });
      _scrollToBottom();
    },
  );
}




  void _sendMessage() {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  setState(() {
    _messages.add(ChatMessage(
      senderRole: 'ROLE_PATIENT',
      content: text,
      timestamp: DateTime.now().toLocal(),
    ));
  });

  _stompClient.send(
    destination: '/app/chat/${widget.doctorUuid}/$_patientUuid/send',
    body: jsonEncode({'content': text, 'type': 'TEXT', 'fileUrl': null}),
  );

  _controller.clear();
  _scrollToBottom();
}


  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat con tu Doctor')),
      body: Column(
        children: [
          // ─── LISTA DE MENSAJES ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              reverse: false,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                // Si es mensaje de sistema, lo centramos
                if (msg.senderRole == 'SYSTEM') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Text(
                        msg.content,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                }

                final isPatient = msg.senderRole == 'ROLE_PATIENT';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: isPatient
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isPatient
                              ? Colors.blue[200]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          msg.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm')
                            .format(msg.timestamp.subtract(const Duration(hours: 5))),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ─── CAJA DE TEXTO + BOTÓN ENVIAR ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
