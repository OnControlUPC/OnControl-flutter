import '../entities/doctor.dart';

/// Repositorio para obtener doctores (usuarios con ROLE_ADMIN).
abstract class DoctorRepository {
  Future<List<Doctor>> getAllDoctors(String token);
}
