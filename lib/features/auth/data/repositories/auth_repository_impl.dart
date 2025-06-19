import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementación de `AuthRepository` usando `AuthRemoteDataSource`
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<UserModel> login(String identifier, String password) async {
    print('▶️ [AuthRepo.login] identifier=$identifier');
    final user = await remoteDataSource.login(identifier, password);
    await secureStorage.write(key: 'token', value: user.token);
    print('✅ [AuthRepo.login] token guardado: ${user.token}');
    return user;
  }

  @override
  Future<UserModel> signUp(String name, String email, String password, String role) async {
    print('▶️ [AuthRepo.signUp] email=$email');
    final user = await remoteDataSource.signUp(name, email, password, role);
    print('✅ [AuthRepo.signUp] id=${user.id}');
    return user;
  }

  @override
  Future<void> logout() async {
    print('▶️ [AuthRepo.logout]');
    await secureStorage.delete(key: 'token');
    print('✅ [AuthRepo.logout] token eliminado');
  }
}
