import '../../domain/entities/user.dart';

/// Modelo de usuario que extiende la entidad `User`
/// Añade `token` y `role`
class UserModel extends User {
  final String token;
  final String role;

  const UserModel({
    required int id,
    required String username,
    required this.token,
    required this.role,
  }) : super(id: id, username: username);

  /// Deserializa el JSON de respuesta, manejando token nulo en sign-up
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      token: (json['token'] as String?) ?? '',
      role: json['role'] as String,
    );
  }

  /// Serialización opcional
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'token': token,
      'role': role,
    };
  }
}
