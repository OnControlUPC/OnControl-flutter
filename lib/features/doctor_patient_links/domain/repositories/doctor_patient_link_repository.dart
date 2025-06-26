
import '../entities/doctor_patient_link.dart';

/// Repositorio de solicitudes (enlaces) doctor-paciente.
abstract class DoctorPatientLinkRepository {
  /// Obtiene las solicitudes pendientes para el paciente autenticado.
  Future<List<DoctorPatientLink>> getPendingLinks();

  /// Acepta la solicitud con el externalId dado.
  Future<void> acceptLink(String externalId);
}

