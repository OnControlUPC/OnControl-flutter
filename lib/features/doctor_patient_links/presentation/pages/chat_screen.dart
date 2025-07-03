import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config.dart';

class ChatScreen extends StatefulWidget {
  final String doctorUuid;
  const ChatScreen({Key? key, required this.doctorUuid}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <String>[];
  late StompClient _stompClient;
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? _patientUuid;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _token = await _storage.read(key: 'token');
    _patientUuid = await _storage.read(key: 'patient_uuid');
    if (_token == null || _patientUuid == null) {
      setState(() => _messages.add('❌ Error: credenciales no encontradas.'));
      return;
    }

    // 🚀 Cargar mensajes antiguos al iniciar
    await _loadPastMessages();

    // 🔌 Iniciar conexión STOMP (sin cambios en tu lógica)
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${Config.BASE_URL}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        beforeConnect: () async {
          debugPrint('🔄 Conectando al websocket...');
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onConnect: _onConnect,
        onStompError: (f) => debugPrint('STOMP Error: ${f.body}'),
        onWebSocketError: (e) => debugPrint('WS Error: $e'),
        onDisconnect: (_) => debugPrint('🔌 Desconectado'),
      ),
    )..activate();
  }

  // 📥 Obtener mensajes antiguos en orden cronológico
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
      setState(() {
        _messages.addAll(
          data
              .map((m) => '🕒 ${m['senderRole']}: ${m['content']}')
              .toList()
              .reversed, // ✅ Más antiguos primero
        );
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
        setState(() => _messages.add('🟢 ${body['senderRole']}: ${body['content']}'));
        _scrollToBottom();
      },
    );
    setState(() => _messages.add('✅ Conectado como PACIENTE'));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final payload = {'content': text, 'type': 'TEXT', 'fileUrl': null};
    final dest = '/app/chat/${widget.doctorUuid}/$_patientUuid/send';
    _stompClient.send(destination: dest, body: jsonEncode(payload));
    setState(() => _messages.add('📤 Tú: $text'));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              reverse: false, // Mostrar en orden cronológico: antiguo arriba
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_messages[i]),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),
                  ),
                ),
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
