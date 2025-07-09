// lib/features/treatments/presentation/pages/treatment_procedures_execution_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/predicted_execution.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

class TreatmentProceduresExecutionPage extends StatefulWidget {
  final PredictedExecution execution;
  const TreatmentProceduresExecutionPage({Key? key, required this.execution})
      : super(key: key);

  @override
  _TreatmentProceduresExecutionPageState createState() =>
      _TreatmentProceduresExecutionPageState();
}

class _TreatmentProceduresExecutionPageState
    extends State<TreatmentProceduresExecutionPage> {
  DateTime? _selectedDateTime;
  late final TreatmentRepository _repository;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _repository = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final date = await showDatePicker(
      context: context,
      firstDate: twoDaysAgo,
      lastDate: now,
      initialDate: now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _selectedDateTime = dt.toUtc());
  }

  Future<void> _onCompletePressed() async {
    if (_selectedDateTime == null) return;
    try {
      await _repository.completeExecution(
        widget.execution.id!,
        _selectedDateTime!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedimiento completado')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Procedimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.execution.procedureName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Agendado: ${df.format(widget.execution.scheduledAt.toLocal())}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDateTime == null
                  ? 'Seleccionar fecha y hora'
                  : 'Seleccionado: ${df.format(_selectedDateTime!.toLocal())}'),
              onPressed: _pickDateTime,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _selectedDateTime == null ? null : _onCompletePressed,
              child: const Text('Marcar como completado'),
            ),
          ],
        ),
      ),
    );
  }
}
