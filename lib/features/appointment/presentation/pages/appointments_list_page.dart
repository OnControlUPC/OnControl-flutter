// lib/features/appointments/presentation/pages/appointments_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';
import '../../domain/entities/appointment.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import 'appointment_detail_page.dart';

/// Página de lista de citas que abre un diálogo detallado
class AppointmentsListPage extends StatefulWidget {
  const AppointmentsListPage({Key? key}) : super(key: key);
  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  late final AppointmentRepositoryImpl _apptRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;
  late Future<List<dynamic>> _initFuture;
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
    _loadData();
  }

  void _loadData() {
    _initFuture = Future.wait([
      _apptRepo.getAppointments(),
      _linkRepo.getActiveLinks(),
    ]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy • HH:mm');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        centerTitle: true,
        elevation: 2,
      ),
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
          _doctorNames = {for (var l in links) l.doctorUuid: l.doctorFullName};

          if (appointments.isEmpty) {
            return const Center(child: Text('No hay citas programadas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: appointments.length,
            itemBuilder: (context, i) {
              final appt = appointments[i];
              final doctor =
                  _doctorNames[appt.doctorProfileUuid] ?? 'Desconocido';
              final dateStr = df.format(appt.scheduledAt.toLocal());

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await showAppointmentDetailDialog(
                        context,
                        appt,
                        doctor,
                      );
                      // tras cerrar, recargar
                      _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            child: Text(
                              doctor
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join(),
                              style:
                                  theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(doctor,
                                    style:
                                        theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(dateStr,
                                    style:
                                        theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
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
