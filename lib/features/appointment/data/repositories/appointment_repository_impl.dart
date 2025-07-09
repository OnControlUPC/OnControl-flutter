// lib/features/appointments/data/repositories/appointment_repository_impl.dart

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

/// Implementación que delega 1:1 al remote datasource.
class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remote;

  AppointmentRepositoryImpl({required this.remote});

  @override
  Future<List<Appointment>> getAppointments() {
    return remote.fetchAppointments();
  }

  @override
  Future<void> deleteAppointment(int id) {
    return remote.deleteAppointment(id);
  }
}
