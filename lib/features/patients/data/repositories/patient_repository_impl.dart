
import '../../domain/entities/patient_profile.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remote;

  PatientRepositoryImpl({required this.remote});

  @override
  Future<void> createProfile(
    PatientProfile profile
  ) => remote.createProfile(profile);
}

