// lib/features/appointments/presentation/pages/appointments_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';
import '../../domain/entities/appointment.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import 'appointment_detail_page.dart';
import 'package:intl/intl.dart';

/// Lista de citas con nombre de doctor cacheado localmente.
class AppointmentsListPage extends StatefulWidget {
  const AppointmentsListPage({Key? key}) : super(key: key);

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  late final AppointmentRepositoryImpl _apptRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;
  late final Future<List<dynamic>> _initFuture;
  Map<String, String> _doctorNames = {};

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage();
    _apptRepo = AppointmentRepositoryImpl(
      remote: AppointmentRemoteDataSourceImpl(),
    );
    _linkRepo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: storage,
    );
    // Cargamos citas y vínculos simultáneamente
    _initFuture = Future.wait([
      _apptRepo.getAppointments(),
      _linkRepo.getActiveLinks(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas')),
      body: FutureBuilder<List<dynamic>>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final appointments = snap.data![0] as List<Appointment>;
          final links = snap.data![1] as List<DoctorPatientLink>;

          // Build map doctorUuid → doctorFullName
          _doctorNames = {
            for (var l in links) l.doctorUuid: l.doctorFullName
          };

          if (appointments.isEmpty) {
            return const Center(child: Text('No hay citas programadas'));
          }
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final a = appointments[index];
              final doctorName =
                  _doctorNames[a.doctorProfileUuid] ?? 'Desconocido';
              return ListTile(
                title: Text(df.format(a.scheduledAt)),
                subtitle: Text('Dr. $doctorName • ${a.status}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentDetailPage(
                      appointment: a,
                      doctorName: doctorName,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
