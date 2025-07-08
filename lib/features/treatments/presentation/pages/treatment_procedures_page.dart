// lib/features/treatments/presentation/pages/treatment_procedures_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/procedure.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

class TreatmentProcedurePage extends StatefulWidget {
  final Treatment treatment;
  const TreatmentProcedurePage({Key? key, required this.treatment})
      : super(key: key);

  @override
  _TreatmentProcedurePageState createState() =>
      _TreatmentProcedurePageState();
}

class _TreatmentProcedurePageState extends State<TreatmentProcedurePage> {
  late final TreatmentRepository _repository;
  late Future<List<Procedure>> _proceduresFuture;

  @override
  void initState() {
    super.initState();
    _repository = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _proceduresFuture = _loadProcedures();
  }

  /// Carga los procedures, y para aquellos que ya vienen con startDateTime
  /// llama automáticamente al endpoint de inicio.
  Future<List<Procedure>> _loadProcedures() async {
    final procs =
        await _repository.getProcedures(widget.treatment.externalId);
    for (var p in procs) {

    }
    return procs;
  }

  /// Lanza el startProcedure con la fecha actual UTC y recarga la lista.
  Future<void> _onStartPressed(int procedureId) async {
    final nowUtc = DateTime.now().toUtc().add(const Duration(minutes: 2));
    try {
      await _repository.startProcedure(procedureId, nowUtc);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedimiento iniciado')),
      );
      setState(() {
        _proceduresFuture = _loadProcedures();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Procedimientos')),
      body: FutureBuilder<List<Procedure>>(
        future: _proceduresFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final procs = snap.data!;
          if (procs.isEmpty) {
            return const Center(child: Text('No hay procedimientos'));
          }

          return ListView.builder(
            itemCount: procs.length,
            itemBuilder: (context, i) {
              final p = procs[i];
              final hasStart = p.startDateTime != null;
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(p.description ?? 'Sin descripción'),
                  subtitle: hasStart
                      ? Text('Inicio: ${df.format(p.startDateTime!)}')
                      : const Text('Aún no iniciado'),
                  trailing: hasStart
                      ? null
                      : ElevatedButton(
                          onPressed: () => _onStartPressed(p.id),
                          child: const Text('Iniciar'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
