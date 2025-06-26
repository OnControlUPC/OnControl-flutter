import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_remote_datasource.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;

  TreatmentRepositoryImpl({
    required this.remote,
    required this.secureStorage,
  });

  @override
  Future<List<Treatment>> getTreatments(String patientUuid, String token) {
    print('▶️ [TreatmentRepo] getTreatments uuid=$patientUuid');
    return remote.fetchTreatments(patientUuid, token);
  }
}
