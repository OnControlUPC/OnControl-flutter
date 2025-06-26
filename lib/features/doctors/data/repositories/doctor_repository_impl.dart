import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;

  DoctorRepositoryImpl({
    required this.remote,
    required this.secureStorage,
  });

  @override
  Future<List<Doctor>> getAllDoctors(String token) {
    print('▶️ [DoctorRepo] getAllDoctors token=$token');
    return remote.fetchAllDoctors(token);
  }
}
