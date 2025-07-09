// lib/features/appointments/domain/repositories/appointment_repository.dart

import '../entities/appointment.dart';

/// Contrato de repositorio de citas (solo calendario).
abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments();

  /// Cancela (elimina) la cita con el ID dado.
  Future<void> deleteAppointment(int id);
}
