import '../entities/treatment.dart';

/// Interfaz de repositorio para tratamientos de un paciente.
abstract class TreatmentRepository {
  /// Obtiene la lista de tratamientos para el paciente autenticado.
  Future<List<Treatment>> getTreatments(String patientUuid, String token);
}
