import '/features/auth/data/models/user_model.dart';

/// Interfaz de repositorio de autenticación
abstract class AuthRepository {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> signUp(String name, String email, String password, String role);
  Future<void> logout();
}
