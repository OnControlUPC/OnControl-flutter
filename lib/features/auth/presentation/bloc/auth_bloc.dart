// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repo;
  AuthBloc(this.repo) : super(AuthInitial()) {
    on<AuthLoginRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        final u = await repo.login(e.username, e.password);
        emit(AuthAuthenticated(u));
      } catch (ex) {
        emit(AuthError(ex.toString()));
      }
    });

    on<AuthSignUpRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        final u = await repo.signUp(e.username, e.email, e.password, e.role);
        emit(AuthSignUpSuccess(u));
      } catch (ex) {
        emit(AuthError(ex.toString()));
      }
    });

    on<AuthLogoutRequested>((_, emit) async {
      await repo.logout();
      emit(AuthUnauthenticated());
    });
  }
}
