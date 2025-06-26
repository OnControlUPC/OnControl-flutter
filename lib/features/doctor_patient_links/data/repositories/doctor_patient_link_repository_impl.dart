
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/doctor_patient_link.dart';
import '../../domain/repositories/doctor_patient_link_repository.dart';
import '../datasources/doctor_patient_link_remote_datasource.dart';

class DoctorPatientLinkRepositoryImpl
    implements DoctorPatientLinkRepository {
  final DoctorPatientLinkRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;

  DoctorPatientLinkRepositoryImpl({
    required this.remote,
    required this.secureStorage,
  });

  @override
  Future<List<DoctorPatientLink>> getPendingLinks() async {
    final token = await secureStorage.read(key: 'token') ?? '';
    if (token.isEmpty) throw Exception('No token');
    final uuid = await remote.fetchPatientUuid(token);
    return remote.fetchPendingLinks(uuid, token);
  }

  @override
  Future<void> acceptLink(String externalId) async {
    final token = await secureStorage.read(key: 'token') ?? '';
    if (token.isEmpty) throw Exception('No token');
    await remote.patchAcceptLink(externalId, token);
  }
}
