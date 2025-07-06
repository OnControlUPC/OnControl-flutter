// lib/features/auth/data/auth_repository_impl.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '.././datasources/auth_remote_datasource.dart';
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
    // 1️⃣ Llamada al endpoint de login
    print('▶️ [AuthRepo.login] identifier=$identifier');
    final user = await remoteDataSource.login(identifier, password);

    // 2️⃣ Guardar el token recibido
    await secureStorage.write(key: 'token', value: user.token);
    print('✅ [AuthRepo.login] token guardado: ${user.token}');

    // 3️⃣ Obtener y guardar el UUID del paciente (si existe)
    try {
      final patientUuid = await remoteDataSource.getPatientUuid(user.token);
      if (patientUuid.isNotEmpty) {
        print('✅ [AuthRepo.login] patientUuid guardado: $patientUuid');
      } else {
        print('⚠️ [AuthRepo.login] patientUuid no encontrado');
      }
    } catch (e) {
      print('⚠️ [AuthRepo.login] No se pudo obtener patientUuid: $e');
    }

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
    await secureStorage.delete(key: 'patient_uuid');
    print('✅ [AuthRepo.logout] token y patient_uuid eliminados');
  }
}
