import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../data/repositories/doctor_patient_link_repository_impl.dart';
import '../../domain/entities/doctor_patient_link.dart';
import '../pages/chat_screen.dart';

class ActiveDoctorsPage extends StatefulWidget {
  const ActiveDoctorsPage({Key? key}) : super(key: key);

  @override
  _ActiveDoctorsPageState createState() => _ActiveDoctorsPageState();
}

class _ActiveDoctorsPageState extends State<ActiveDoctorsPage> {
  late final DoctorPatientLinkRepositoryImpl _repo;
  late Future<List<DoctorPatientLink>> _futureActive;

  @override
  void initState() {
    super.initState();
    _repo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _futureActive = _repo.getActiveLinks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctores Activos')),
      body: FutureBuilder<List<DoctorPatientLink>>(
        future: _futureActive,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No tienes doctores activos.'));
          }
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final link = list[i];
              return ListTile(
                leading: const Icon(Icons.medical_services),
                title: Text(link.doctorFullName),
                subtitle: Text('Desde: ${link.createdAt.toLocal().toString().split(" ")[0]}'),
                trailing: Text(link.status),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        doctorUuid: link.doctorUuid,  // ← campo corregido
                      ),
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
