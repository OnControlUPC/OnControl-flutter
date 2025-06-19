import 'package:equatable/equatable.dart';

/// Entidad de usuario para autenticación
abstract class User extends Equatable {
  final int id;
  final String username;

  const User({
    required this.id,
    required this.username,
  });

  @override
  List<Object?> get props => [id, username];
}
