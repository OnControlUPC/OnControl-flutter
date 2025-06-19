import 'package:flutter_bloc/flutter_bloc.dart';
import '../.././data/repositories/auth_repository_impl.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('▶️ [AuthBloc] SignUpRequested: ${event.email}');
    emit(AuthLoading());
    try {
      final user = await _repository.signUp(
        event.name,
        event.email,
        event.password,
        event.role,
      );
      print('✅ [AuthBloc] AuthSignUpSuccess: id=${user.id}');
      emit(AuthSignUpSuccess(user));
    } catch (e) {
      print('❌ [AuthBloc] SignUp error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('▶️ [AuthBloc] LoginRequested: ${event.username}');
    emit(AuthLoading());
    try {
      final user = await _repository.login(
        event.username,
        event.password,
      );
      print('✅ [AuthBloc] AuthAuthenticated: token=${user.token}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      print('❌ [AuthBloc] Login error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('▶️ [AuthBloc] LogoutRequested');
    await _repository.logout();
    print('✅ [AuthBloc] AuthUnauthenticated');
    emit(AuthUnauthenticated());
  }
}
