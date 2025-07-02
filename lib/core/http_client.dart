// lib/core/http_client.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' show IOClient;

/// Cliente que inyecta automáticamente el Bearer token en cada petición.
class AuthClient extends http.BaseClient {
  final http.Client _inner;
  final FlutterSecureStorage _storage;

  AuthClient(this._inner, this._storage);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

/// Factory que devuelve un http.Client —en tu caso un IOClient— 
/// envuelto en AuthClient para manejar auth automáticamente.
http.Client createHttpClient() {
  final storage = const FlutterSecureStorage();
  final realClient = IOClient();
  return AuthClient(realClient, storage);
}