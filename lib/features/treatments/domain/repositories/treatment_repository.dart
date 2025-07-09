import '../entities/treatment.dart';
import '../entities/symptom.dart';
import '../entities/symptom_log.dart';
import '../entities/procedure.dart';
import '../entities/predicted_execution.dart';

/// Contrato de repositorio para tratamientos.
abstract class TreatmentRepository {
  Future<List<Treatment>> getTreatments();
  Future<void> addSymptom(String treatmentId, Symptom symptom);

  /// Obtiene el historial de síntomas del paciente en un rango.
  Future<List<SymptomLog>> getSymptomLogs({
    required DateTime from,
    required DateTime to,
  });

    /// Lista de procedimientos para un tratamiento.
  Future<List<Procedure>> getProcedures(String treatmentExternalId);

  /// Inicia un procedimiento pendiente.
  Future<void> startProcedure(int procedureId, DateTime startDateTime);

  /// Devuelve las ejecuciones previstas de los procedimientos.
  Future<List<PredictedExecution>> getPredictedExecutions(String treatmentExternalId);

    Future<void> completeExecution(int executionId, DateTime completionDateTime);

}
