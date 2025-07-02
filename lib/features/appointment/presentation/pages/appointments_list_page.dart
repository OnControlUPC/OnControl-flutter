import 'package:flutter/material.dart';
import '../../domain/entities/appointment.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import 'appointment_detail_page.dart';

class AppointmentsListPage extends StatefulWidget {
  const AppointmentsListPage({Key? key}) : super(key: key);

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  late Future<List<Appointment>> _appointments;

  @override
  void initState() {
    super.initState();
    _appointments = AppointmentRepositoryImpl(
      remote: AppointmentRemoteDataSourceImpl(),
    ).getAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final a = list[index];
              return ListTile(
                title: Text(a.status),
                subtitle: Text('At ${a.scheduledAt}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailPage(appointment: a),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
