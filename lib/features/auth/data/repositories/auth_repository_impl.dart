// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl({
    required this.remote,
    required this.storage,
  });

  @override
  Future<User> login(String identifier, String password) async {
    // La obtención del UserModel se hace en el remote
    return await remote.login(identifier, password);
  }

  @override
  Future<User> signUp(
    String username,
    String email,
    String password,
    String role,
  ) async {
    return await remote.signUp(username, email, password, role);
  }

  @override
  Future<void> logout() async {
    // Al cerrar sesión, borramos tanto el token como la preferencia de mantener sesión
    await storage.delete(key: 'token');
    await storage.delete(key: 'keepSignedIn');
  }
}
