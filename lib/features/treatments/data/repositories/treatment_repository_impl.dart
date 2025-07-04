import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/symptom.dart';
import '../../domain/entities/symptom_log.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_remote_datasource.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentRemoteDataSource _remote;
  final FlutterSecureStorage _secureStorage;

  TreatmentRepositoryImpl({
    required TreatmentRemoteDataSource remote,
    required FlutterSecureStorage secureStorage,
  })  : _remote = remote,
        _secureStorage = secureStorage;

  @override
  Future<List<Treatment>> getTreatments() async {
    final patientUuid = await _secureStorage.read(key: 'patient_uuid');
    if (patientUuid == null || patientUuid.isEmpty) {
      throw Exception('Patient UUID not found in storage');
    }
    return _remote.fetchTreatments(patientUuid);
  }

  @override
  Future<void> addSymptom(String treatmentId, Symptom symptom) {
    return _remote.postSymptom(treatmentId, symptom);
  }

  @override
  Future<List<SymptomLog>> getSymptomLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final patientUuid = await _secureStorage.read(key: 'patient_uuid');
    if (patientUuid == null || patientUuid.isEmpty) {
      throw Exception('Patient UUID not found in storage');
    }
    return _remote.fetchPatientSymptomLogs(
      patientUuid: patientUuid,
      from: from,
      to: to,
    );
  }
}
