import '../entities/treatment.dart';

/// Repositorio para gestión de tratamientos.
abstract class TreatmentRepository {
  /// Recupera todos los tratamientos del paciente autenticado.
  Future<List<Treatment>> getTreatments();
}
