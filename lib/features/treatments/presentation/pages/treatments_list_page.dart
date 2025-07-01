// lib/features/treatments/presentation/pages/treatments_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/http_client.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';
import '../../domain/entities/treatment.dart';
import 'treatment_detail_page.dart';

class TreatmentsListPage extends StatefulWidget {
  const TreatmentsListPage({Key? key}) : super(key: key);

  @override
  State<TreatmentsListPage> createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends State<TreatmentsListPage> {
  final _storage = const FlutterSecureStorage();
  late final TreatmentRepositoryImpl _repo;
  late final DoctorPatientLinkRemoteDataSourceImpl _linkDs;
  late Future<List<Treatment>> _treatmentsFuture;

  @override
  void initState() {
    super.initState();
    _repo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _linkDs = DoctorPatientLinkRemoteDataSourceImpl(client: createHttpClient());
    _treatmentsFuture = _loadTreatments();
  }

  Future<List<Treatment>> _loadTreatments() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) throw Exception('Sesión no iniciada');

    final patientUuid = await _linkDs.fetchPatientUuid(token);
    return await _repo.getTreatments(patientUuid, token);
  }

  String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade50,
    body: Column(
      children: [
        // Encabezado con gradiente y título
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 44, 194, 49),
                Color.fromARGB(255, 105, 96, 197)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const Center(
            child: Text(
              'Mis Tratamientos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Lista con future builder
        Expanded(
          child: FutureBuilder<List<Treatment>>(
            future: _treatmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }

              final treatments = snapshot.data!;
              if (treatments.isEmpty) {
                return const Center(child: Text('No tienes tratamientos'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _treatmentsFuture = _loadTreatments();
                  });
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: treatments.length,
                  itemBuilder: (context, i) {
                    final t = treatments[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          t.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Desde ${_formatDate(t.startDate)}'),
                        trailing: Text(
                          t.status,
                          style: const TextStyle(color: Colors.teal),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreatmentDetailPage(treatment: t),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

}
