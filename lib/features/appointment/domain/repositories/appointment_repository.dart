import '../../domain/entities/appointment.dart';
abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments();
}