import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remote;

  AppointmentRepositoryImpl({required this.remote});

  @override
  Future<List<Appointment>> getAppointments() {
    return remote.fetchAppointments();
  }
}