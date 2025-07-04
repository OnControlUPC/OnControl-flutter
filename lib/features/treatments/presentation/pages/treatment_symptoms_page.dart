// lib/features/treatments/presentation/pages/treatment_symptoms_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/symptom.dart';
import '../../domain/entities/symptom_log.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

class TreatmentSymptomsPage extends StatefulWidget {
  final Treatment treatment;
  const TreatmentSymptomsPage({Key? key, required this.treatment}) : super(key: key);

  @override
  _TreatmentSymptomsPageState createState() => _TreatmentSymptomsPageState();
}

class _TreatmentSymptomsPageState extends State<TreatmentSymptomsPage> {
  late final TreatmentRepository _repo;
  late Future<List<SymptomLog>> _futureLogs;
  bool _loading = false;

  final _typeCtrl = TextEditingController();
  SymptomSeverity _severity = SymptomSeverity.MILD;
  final _notesCtrl = TextEditingController();
  DateTime _loggedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _repo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _loadLogs();
  }

  void _loadLogs() {
    _futureLogs = _repo.getSymptomLogs(
      from: widget.treatment.period.startDate.toUtc(),
      to: widget.treatment.period.endDate.toUtc(),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: widget.treatment.period.startDate,
      lastDate: widget.treatment.period.endDate,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
    );
    if (time == null) return;
    setState(() {
      _loggedAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final storage = const FlutterSecureStorage();
      final patientUuid = await storage.read(key: 'patient_uuid');
      final symptom = Symptom(
        patientProfileUuid: patientUuid!,
        symptomType: _typeCtrl.text.trim(),
        severity: _severity,
        notes: _notesCtrl.text.trim(),
        loggedAt: _loggedAt,
      );
      await _repo.addSymptom(widget.treatment.externalId, symptom);
      _typeCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _severity = SymptomSeverity.MILD;
        _loggedAt = DateTime.now();
        _loadLogs();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Formatea restando 5 horas (UTC–5)
  String _fmt(DateTime dt) {
    final adjusted = dt.subtract(const Duration(hours: 5));
    return adjusted.toLocal().toString().split('.')[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Síntomas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<SymptomLog>>(
                future: _futureLogs,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snap.hasError) {
                    return Text('Error: ${snap.error}', style: theme.bodyMedium);
                  }
                  final logs = snap.data!;
                  if (logs.isEmpty) {
                    return const Center(child: Text('No hay síntomas.'));
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final log = logs[i];
                      return ListTile(
                        title: Text(log.symptomType),
                        subtitle: Text(
                          '${log.severity.name} • ${_fmt(log.loggedAt)}\n${log.notes}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Text('Reportar Síntoma', style: theme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _typeCtrl,
              decoration: const InputDecoration(
                labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            DropdownButton<SymptomSeverity>(
              value: _severity,
              isExpanded: true,
              onChanged: (v) => setState(() => _severity = v!),
              items: SymptomSeverity.values.map((e) =>
                DropdownMenuItem(value: e, child: Text(e.name))
              ).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Fecha: ${_fmt(_loggedAt)}')),
                TextButton(onPressed: _pickDateTime, child: const Text('Seleccionar')),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator())
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
