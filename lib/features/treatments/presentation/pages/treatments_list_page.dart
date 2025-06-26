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
  _TreatmentsListPageState createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends State<TreatmentsListPage> {
  final _storage = const FlutterSecureStorage();
  late final TreatmentRepositoryImpl _repo;
  late final DoctorPatientLinkRemoteDataSourceImpl _linkDs;

  List<Treatment> _treatments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Inicializa tu repositorio y el DS para UUID
    _repo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _linkDs = DoctorPatientLinkRemoteDataSourceImpl(client: createHttpClient());
    _loadUuidAndTreatments();
  }

  Future<void> _loadUuidAndTreatments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _storage.read(key: 'token') ?? '';
    print('▶️ [TreatmentsList] token=$token');

    if (token.isEmpty) {
      setState(() {
        _error = 'Sesión no iniciada';
        _loading = false;
      });
      return;
    }

    try {
      // Ahora pedimos la UUID directamente al endpoint /patients/me/uuid
      final patientUuid = await _linkDs.fetchPatientUuid(token);
      print('🔍 [TreatmentsList] patientUuid=$patientUuid');

      // Con esa UUID traemos los tratamientos
      final list = await _repo.getTreatments(patientUuid, token);
      print('🔔 [TreatmentsList] encontrados: ${list.length}');
      setState(() {
        _treatments = list;
        _loading = false;
      });
    } catch (e) {
      print('❌ [TreatmentsList] error: $e');
      setState(() {
        _error = 'Error al cargar tratamientos';
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) =>
      date.toLocal().toString().split(' ')[0];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_treatments.isEmpty) {
      return const Center(child: Text('No tienes tratamientos'));
    }
    return ListView.separated(
      itemCount: _treatments.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final t = _treatments[i];
        return ListTile(
          title: Text(t.title),
          subtitle: Text('Desde ${_formatDate(t.startDate)}'),
          trailing: Text(t.status),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TreatmentDetailPage(treatment: t),
            ),
          ),
        );
      },
    );
  }
}
