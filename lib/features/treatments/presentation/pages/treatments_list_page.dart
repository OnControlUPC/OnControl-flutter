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

/// Página que muestra la lista de tratamientos del paciente autenticado.
class TreatmentsListPage extends StatefulWidget {
  const TreatmentsListPage({Key? key}) : super(key: key);

  @override
  _TreatmentsListPageState createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends State<TreatmentsListPage> {
  late final TreatmentRepository _treatmentRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;
  late final Future<List<Treatment>> _futureTreatments;

  @override
  void initState() {
    super.initState();
    _treatmentRepo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _linkRepo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _futureTreatments = _treatmentRepo.getTreatments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treatments')),
      body: FutureBuilder<List<Treatment>>(
        future: _futureTreatments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No treatments found.'));
          }

          final treatments = snapshot.data!;
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final t = treatments[index];

              return FutureBuilder<List<DoctorPatientLink>>(
                future: _linkRepo.getActiveLinks(),
                builder: (context, linkSnap) {
                  String doctorName = 'Desconocido';
                  if (linkSnap.hasData) {
                    try {
                      final link = linkSnap.data!.firstWhere(
                        (l) => l.doctorUuid == t.doctorProfileUuid,
                      );
                      doctorName = link.doctorFullName;
                    } catch (_) {}
                  }
                  return ListTile(
                    title: Text(t.title.value),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr: $doctorName'),
                        Text('Status: ${t.status}'),
                        Text(
                          'Period: ${t.period.startDate.toLocal()} - '
                          '${t.period.endDate.toLocal()}',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TreatmentDetailPage(treatment: t),
                        ),
                      );
                    },
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