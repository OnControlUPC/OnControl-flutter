import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/doctor_patient_link.dart';
import '../../domain/repositories/doctor_patient_link_repository.dart';
import '../datasources/doctor_patient_link_remote_datasource.dart';

class DoctorPatientLinkRepositoryImpl implements DoctorPatientLinkRepository {
  final DoctorPatientLinkRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;

  DoctorPatientLinkRepositoryImpl({
    required this.remote,
    required this.secureStorage,
  });

  @override
  Future<List<DoctorPatientLink>> getPendingLinks() async {
    final patientUuid = await secureStorage.read(key: 'patient_uuid');
    if (patientUuid == null || patientUuid.isEmpty) {
      throw Exception('Patient UUID not found in storage');
    }
    return remote.fetchPendingLinks(patientUuid);
  }

  @override
  Future<void> acceptLink(String externalId) async {
    return remote.patchAcceptLink(externalId);
    
  }

  @override
  Future<void> activateLink(String externalId) async {
    return remote.patchActivateLink(externalId);
  }



  @override
  Future<List<DoctorPatientLink>> getActiveLinks() async {
    final patientUuid = await secureStorage.read(key: 'patient_uuid');
    if (patientUuid == null || patientUuid.isEmpty) {
      throw Exception('Patient UUID not found in storage');
    }
    return remote.fetchActiveLinks(patientUuid);
  }
}