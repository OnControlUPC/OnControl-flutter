import 'package:equatable/equatable.dart';

/// Eventos para el AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthSignUpRequested(
    this.name,
    this.email,
    this.password,
    this.role,
  );

  @override
  List<Object?> get props => [name, email, password, role];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
