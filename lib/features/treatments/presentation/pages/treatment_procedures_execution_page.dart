// lib/features/treatments/presentation/pages/treatment_procedures_page.dart
/*
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/treatment.dart';
import '../../domain/entities/predicted_execution.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

enum SortField { name, date }
enum SortOrder { asc, desc }

class TreatmentProcedureExecutionPage extends StatefulWidget {
  final Treatment treatment;
  const TreatmentProcedureExecutionPage({Key? key, required this.treatment})
      : super(key: key);

  @override
  _TreatmentProcedureExecutionPageState createState() =>
      _TreatmentProcedureExecutionPageState();
}

class _TreatmentProcedureExecutionPageState extends State<TreatmentProcedureExecutionPage> {
  late final TreatmentRepository _repository;
  late final Future<List<PredictedExecution>> _futureExecutions;
  final _searchController = TextEditingController();

  // filtros y orden
  String? _searchTerm;
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  SortField _sortField = SortField.date;
  SortOrder _sortOrder = SortOrder.asc;

  @override
  void initState() {
    super.initState();
    _repository = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Trae los procedures, arranca los PENDING y devuelve la lista de ejecuciones previstas.
  Future<List<PredictedExecution>> _loadAndStartProcedures() async {
    final procs =
        await _repository.getProcedures(widget.treatment.externalId);
    for (var p in procs) {
      if (p.status.toUpperCase() == 'PENDING') {
        await _repository.startProcedure(p.id, p.startDateTime);
      }
    }
    return _repository.getPredictedExecutions(widget.treatment.externalId);
  }

  List<PredictedExecution> _applyFiltersAndSort(
      List<PredictedExecution> list) {
    final filtered = list.where((e) {
      final nameMatch = _searchTerm == null ||
          _searchTerm!.isEmpty ||
          e.procedureName
              .toLowerCase()
              .contains(_searchTerm!.toLowerCase());
      final statusMatch =
          _selectedStatus == null || e.status == _selectedStatus;
      final dateMatch = _dateRange == null ||
          (e.scheduledAt
                  .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              e.scheduledAt
                  .isBefore(_dateRange!.end.add(const Duration(days: 1))));
      return nameMatch && statusMatch && dateMatch;
    }).toList();

    filtered.sort((a, b) {
      final cmp = (_sortField == SortField.name)
          ? a.procedureName.compareTo(b.procedureName)
          : a.scheduledAt.compareTo(b.scheduledAt);
      return _sortOrder == SortOrder.asc ? cmp : -cmp;
    });

    return filtered;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Procedimientos')),
      body: Column(
        children: [

          // — Filtros de estado y rango —
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange == null
                      ? 'Rango fecha'
                      : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} → ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'),
                ),
              ],
            ),
          ),



          const Divider(height: 1),

          // — FutureBuilder: carga + UI de lista —
          Expanded(
            child: FutureBuilder<List<PredictedExecution>>(
              future: _futureExecutions,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error al cargar: ${snap.error}'));
                }
                // datos cargados
                final allExecs = snap.data!;
                final list = _applyFiltersAndSort(allExecs);

                if (list.isEmpty) {
                  return const Center(
                      child: Text('No hay registros que mostrar'));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    return ListTile(
                      title: Text(e.procedureName,
                          style: theme.titleMedium),
                      subtitle: Text('Agendado: ${df.format(e.scheduledAt)}',
                          style: theme.bodySmall),
                      trailing: Text(e.status,
                          style: theme.labelMedium),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/