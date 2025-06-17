// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/core/config.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> signUp(
      String username, String email, String password, String role);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  AuthRemoteDataSourceImpl(this.client, this.storage);

  @override
  Future<UserModel> login(String identifier, String password) async {
    final uri = Uri.parse(LOGIN_URL);
    final body = jsonEncode({
      'identifier': identifier,
      'password': password,
    });

    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('🔵 LOGIN REQUEST → $uri');
    print('   ▶️ Payload: $body');
    print('   ◀️ Status: ${resp.statusCode}');
    print('   ◀️ Body:   ${resp.body}');

    if (resp.statusCode == 200) {
      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('Error de login (${resp.statusCode}): ${resp.body}');
    }
  }

  @override
  Future<UserModel> signUp(
      String username, String email, String password, String role) async {
    final uri = Uri.parse(SIGNUP_URL);
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });

    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('🟢 SIGNUP REQUEST → $uri');
    print('   ▶️ Payload: $body');
    print('   ◀️ Status: ${resp.statusCode}');
    print('   ◀️ Body:   ${resp.body}');

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('Error de signup (${resp.statusCode}): ${resp.body}');
    }
  }
}
