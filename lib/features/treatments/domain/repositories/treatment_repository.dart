import '../entities/treatment.dart';
import '../entities/symptom.dart';
import '../entities/symptom_log.dart';

/// Contrato de repositorio para tratamientos.
abstract class TreatmentRepository {
  Future<List<Treatment>> getTreatments();
  Future<void> addSymptom(String treatmentId, Symptom symptom);

  /// Obtiene el historial de síntomas del paciente en un rango.
  Future<List<SymptomLog>> getSymptomLogs({
    required DateTime from,
    required DateTime to,
  });
}
