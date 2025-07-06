import '../entities/doctor_patient_link.dart';

/// Repositorio de solicitudes doctor-paciente.
abstract class DoctorPatientLinkRepository {
  Future<List<DoctorPatientLink>> getPendingLinks();
  Future<void> acceptLink(String externalId);
  Future<void> activateLink(String externalId);

  Future<List<DoctorPatientLink>> getActiveLinks();  // nuevos doctores activos
}
