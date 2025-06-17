// lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> signUp(String username, String email, String password, String role);
  Future<void> logout();
}
