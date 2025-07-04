// lib/features/treatments/presentation/pages/treatment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/presentation/pages/chat_screen.dart';
import '../../domain/entities/treatment.dart';
import 'treatment_symptoms_page.dart';

class TreatmentDetailPage extends StatefulWidget {
  final Treatment treatment;
  const TreatmentDetailPage({Key? key, required this.treatment}) : super(key: key);

  @override
  _TreatmentDetailPageState createState() => _TreatmentDetailPageState();
}

class _TreatmentDetailPageState extends State<TreatmentDetailPage> {
  late Future<String> _futureDoctorName;

  @override
  void initState() {
    super.initState();
    _futureDoctorName = _loadDoctorName();
  }

  Future<String> _loadDoctorName() async {
    final storage = const FlutterSecureStorage();
    final patientUuid = await storage.read(key: 'patient_uuid');
    if (patientUuid == null || patientUuid.isEmpty) {
      throw Exception('No patient_uuid in storage');
    }
    final repo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: storage,
    );
    final links = await repo.getActiveLinks();
    final match = links.firstWhere(
      (l) => l.doctorUuid == widget.treatment.doctorProfileUuid,
      orElse: () => throw Exception('Doctor link not found'),
    );
    return match.doctorFullName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Tratamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text('Título', style: theme.titleMedium),
            Text(widget.treatment.title.value, style: theme.bodyMedium),
            const Divider(),

            // Nombre del doctor + chat
            Text('Doctor', style: theme.titleMedium),
            FutureBuilder<String>(
              future: _futureDoctorName,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Text('Cargando doctor…', style: TextStyle(fontStyle: FontStyle.italic));
                } else if (snap.hasError) {
                  return Text('Error: ${snap.error}', style: theme.bodyMedium);
                }
                final name = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: theme.bodyMedium),
                    IconButton(
                      icon: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(doctorUuid: widget.treatment.doctorProfileUuid),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(),

            // Estado
            Text('Estado', style: theme.titleMedium),
            Text(widget.treatment.status, style: theme.bodyMedium),
            const Divider(),

            // Período
            Text('Período', style: theme.titleMedium),
            Text('Desde: ${widget.treatment.period.startDate.toLocal()}', style: theme.bodyMedium),
            Text('Hasta: ${widget.treatment.period.endDate.toLocal()}', style: theme.bodyMedium),
            const SizedBox(height: 24),

            // Botón a página de síntomas
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TreatmentSymptomsPage(treatment: widget.treatment),
                  ),
                );
              },
              icon: const Icon(Icons.healing),
              label: const Text('Ver y reportar síntomas'),
            ),
          ],
        ),
      ),
    );
  }
}
