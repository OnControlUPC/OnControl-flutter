import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';
import '../../../doctor_patient_links/presentation/pages/chat_screen.dart'; // <-- importar ChatScreen
import '../../domain/entities/treatment.dart';

class TreatmentDetailPage extends StatefulWidget {
  final Treatment treatment;
  const TreatmentDetailPage({required this.treatment, Key? key}) : super(key: key);

  @override
  _TreatmentDetailPageState createState() => _TreatmentDetailPageState();
}

class _TreatmentDetailPageState extends State<TreatmentDetailPage> {
  late final Future<String> _futureDoctorName;

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

    final List<DoctorPatientLink> links = await repo.getActiveLinks();

    final match = links.firstWhere(
      (link) => link.doctorUuid == widget.treatment.doctorProfileUuid,
      orElse: () => throw Exception('Link doctor not found'),
    );
    return match.doctorFullName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Tratamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Title
            Text('Title:', style: theme.titleMedium),
            Text(widget.treatment.title.value, style: theme.bodyMedium),
            const Divider(),

            // Doctor Name con navegación a chat
            Text('Doctor:', style: theme.titleMedium),
            FutureBuilder<String>(
              future: _futureDoctorName,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Cargando doctor…',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  );
                } else if (snap.hasError) {
                  return Text('Error: \${snap.error}', style: theme.bodyMedium);
                }
                final name = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: theme.bodyMedium),
                    IconButton(
                      icon: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              doctorUuid: widget.treatment.doctorProfileUuid,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(),

            // Status
            Text('Status:', style: theme.titleMedium),
            Text(widget.treatment.status, style: theme.bodyMedium),
            const Divider(),

            // Created & Updated
            Text('Created:', style: theme.titleMedium),
            Text(widget.treatment.createdAt.toLocal().toString(), style: theme.bodyMedium),
            const SizedBox(height: 4),
            Text('Updated:', style: theme.titleMedium),
            Text(widget.treatment.updatedAt.toLocal().toString(), style: theme.bodyMedium),
            const Divider(),

            // Period
            Text('Period:', style: theme.titleMedium),
            Text('From: ${widget.treatment.period.startDate.toLocal()}', style: theme.bodyMedium),
            Text('To:   ${widget.treatment.period.endDate.toLocal()}', style: theme.bodyMedium),
            const Divider(),
          ],
        ),
      ),
    );
  }
}