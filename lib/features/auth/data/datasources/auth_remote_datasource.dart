// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/http_client.dart';
import '../../../../core/config.dart';                   // ← IMPORTACIÓN DE Config
import '.././models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
  Future<UserModel> signUp(
      String name, String email, String password, String role);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthRemoteDataSourceImpl({
    http.Client? client,
    required this.secureStorage,
    required this.sharedPreferences,
  }) : client = client ?? createHttpClient();

  @override
  Future<UserModel> login(String username, String password) async {
    final uri = Uri.parse(Config.BASE_URL + Config.LOGIN_URL);
    final body = jsonEncode({
      'identifier': username,
      'password': password,
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
        print('🔵 LOGIN REQUEST → $uri');
    print('   ▶️ Payload: $body');
    print('   ◀️ Status: ${response.statusCode}');
    print('   ◀️ Body:   ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('Error en login: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> signUp(
      String name, String email, String password, String role) async {
    final uri = Uri.parse(Config.BASE_URL + Config.SIGNUP_URL);
    final body = jsonEncode({
      'username': name,
      'email': email,
      'password': password,
      'role': 'ROLE_PATIENT',
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

            print('🔵 signUp REQUEST → $uri');
    print('   ▶️ Payload: $body');
    print('   ◀️ Status: ${response.statusCode}');
    print('   ◀️ Body:   ${response.body}');

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('Error en signUp: ${response.statusCode}');
    }
  }
}
