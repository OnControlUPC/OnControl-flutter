// lib/features/auth/data/auth_remote_data_source.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/http_client.dart';
import '../../../../core/config.dart';
import '../models/user_model.dart';

/// Interfaz de fuente remota de autenticación
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> signUp(String name, String email, String password, String role);

  /// Obtiene el UUID del paciente logueado y lo guarda en secure storage
  Future<String> getPatientUuid(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  AuthRemoteDataSourceImpl({
    http.Client? client,
    required this.secureStorage,
  }) : client = client ?? createHttpClient();

  @override
  Future<UserModel> login(String identifier, String password) async {
    final uri = Uri.parse(Config.BASE_URL + Config.LOGIN_URL);
    final bodyMap = {'identifier': identifier, 'password': password};
    final body = jsonEncode(bodyMap);

    debugPrint('🔵 [AuthRemoteDataSourceImpl.login] URL → $uri');
    debugPrint('▶️ [AuthRemoteDataSourceImpl.login] Payload → $bodyMap');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    debugPrint('⬅️ [AuthRemoteDataSourceImpl.login] Status → ${response.statusCode}');
    debugPrint('⬅️ [AuthRemoteDataSourceImpl.login] Body   → ${response.body}');

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;

      if (jsonMap.containsKey('token')) {
        await secureStorage.write(key: 'token', value: jsonMap['token'] as String);
        debugPrint('✅ [AuthRemoteDataSourceImpl.login] Token almacenado correctamente');
      } else {
        debugPrint('⚠️ [AuthRemoteDataSourceImpl.login] No vino token en la respuesta');
      }

      return UserModel.fromJson(jsonMap);
    } else {
      debugPrint('❌ [AuthRemoteDataSourceImpl.login] Login failed (${response.statusCode})');
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password, String role) async {
    final uri = Uri.parse(Config.BASE_URL + Config.SIGNUP_URL);
    final bodyMap = {
      'username': name,
      'email': email,
      'password': password,
      'role': role,
    };
    final body = jsonEncode(bodyMap);

    debugPrint('🔵 [AuthRemoteDataSourceImpl.signUp] URL → $uri');
    debugPrint('▶️ [AuthRemoteDataSourceImpl.signUp] Payload → $bodyMap');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    debugPrint('⬅️ [AuthRemoteDataSourceImpl.signUp] Status → ${response.statusCode}');
    debugPrint('⬅️ [AuthRemoteDataSourceImpl.signUp] Body   → ${response.body}');

    if (response.statusCode == 201) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('✅ [AuthRemoteDataSourceImpl.signUp] Usuario creado correctamente');
      return UserModel.fromJson(jsonMap);
    } else {
      debugPrint('❌ [AuthRemoteDataSourceImpl.signUp] SignUp failed (${response.statusCode})');
      throw Exception('SignUp failed: ${response.statusCode}');
    }
  }

  @override
  Future<String> getPatientUuid(String token) async {
    final uri = Uri.parse(Config.BASE_URL + Config.PATIENT_UUID_URL);
    debugPrint('🔵 [AuthRemoteDataSourceImpl.getPatientUuid] URL → $uri');

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }
    );

    debugPrint('⬅️ [AuthRemoteDataSourceImpl.getPatientUuid] Status → ${response.statusCode}');
    debugPrint('⬅️ [AuthRemoteDataSourceImpl.getPatientUuid] Body   → ${response.body}');

    if (response.statusCode == 200) {
      // Asumimos un JSON como { "uuid": "abc-123-xyz" }
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      final String uuid = jsonMap['uuid'] as String;

      // Guardamos el UUID en secure storage
      await secureStorage.write(key: 'patient_uuid', value: uuid);
      debugPrint('✅ [AuthRemoteDataSourceImpl.getPatientUuid] Patient UUID almacenado → $uuid');

      return uuid;
      } else if (response.statusCode == 404) {
      debugPrint('⚠️ [AuthRemoteDataSourceImpl.getPatientUuid] UUID no encontrado');
      return '';
    } else {
      debugPrint('❌ [AuthRemoteDataSourceImpl.getPatientUuid] Falló la petición (${response.statusCode})');
      throw Exception('getPatientUuid failed: ${response.statusCode}');
    }
  }
}
