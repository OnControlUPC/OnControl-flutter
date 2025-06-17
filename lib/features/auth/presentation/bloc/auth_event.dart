// lib/features/auth/presentation/bloc/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username, password;
  AuthLoginRequested(this.username, this.password);
  @override List<Object?> get props => [username, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String username, email, password, role;
  AuthSignUpRequested(this.username, this.email, this.password, this.role);
  @override List<Object?> get props => [username, email, password, role];
}

class AuthLogoutRequested extends AuthEvent {}
