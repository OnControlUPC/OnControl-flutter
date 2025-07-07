// lib/features/treatments/presentation/pages/treatments_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';
import 'treatment_detail_page.dart';

/// Página que muestra la lista de tratamientos del paciente autenticado,
/// junto con el nombre cacheado del doctor.
class TreatmentsListPage extends StatefulWidget {
  const TreatmentsListPage({Key? key}) : super(key: key);

  @override
  _TreatmentsListPageState createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends State<TreatmentsListPage> {
  late final TreatmentRepository _treatmentRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;
  Future<List<dynamic>>? _initFuture;

  /// Mapa: doctorUuid → doctorFullName
  Map<String, String> _doctorNames = {};

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage();
    _treatmentRepo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: storage,
    );
    _linkRepo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: storage,
    );

    // Carga tratamientos y vínculos doctor-paciente en paralelo
    _initFuture = Future.wait([
      _treatmentRepo.getTreatments(),
      _linkRepo.getActiveLinks(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tratamientos')),
      body: FutureBuilder<List<dynamic>>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final treatments = snap.data![0] as List<Treatment>;
          final links = snap.data![1] as List<DoctorPatientLink>;

          // Creamos el mapa doctorUuid → doctorFullName
          _doctorNames = {
            for (var l in links) l.doctorUuid: l.doctorFullName
          };

          if (treatments.isEmpty) {
            return const Center(child: Text('No treatments found.'));
          }

          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final t = treatments[index];
              final doctorName =
                  _doctorNames[t.doctorProfileUuid] ?? 'Desconocido';

              return ListTile(
                title: Text(t.title.value),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr: $doctorName'),
                    Text('Estado: ${t.status}'),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreatmentDetailPage(
                        treatment: t,
                        doctorName: doctorName,
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
