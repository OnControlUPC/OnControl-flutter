import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/http_client.dart';
import '../../../../core/config.dart';
import '../models/user_model.dart';

/// Interfaz de fuente remota de autenticación
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> signUp(String name, String email, String password, String role);
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
  Future<UserModel> login(String identifier, String password) async {
    final uri = Uri.parse(Config.BASE_URL + Config.LOGIN_URL);
    final body = jsonEncode({
      'identifier': identifier,
      'password': password,
    });
    print('🔵 [AuthDS.login] → $uri');
    print('▶️ Payload: $body');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('◀️ Status: ${response.statusCode}');
    print('◀️ Body:   ${response.body}');

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password, String role) async {
    final uri = Uri.parse(Config.BASE_URL + Config.SIGNUP_URL);
    final body = jsonEncode({
      'username': name,
      'email': email,
      'password': password,
      'role': role,
    });
    print('🔵 [AuthDS.signUp] → $uri');
    print('▶️ Payload: $body');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('◀️ Status: ${response.statusCode}');
    print('◀️ Body:   ${response.body}');

    if (response.statusCode == 201) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } else {
      throw Exception('SignUp failed: ${response.statusCode}');
    }
  }
}
