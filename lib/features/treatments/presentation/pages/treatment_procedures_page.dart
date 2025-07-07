// lib/features/treatments/presentation/pages/treatment_procedures_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/treatment.dart';
import '../../domain/entities/procedure.dart';
import '../../domain/entities/predicted_execution.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

enum SortField { name, date }
enum SortOrder { asc, desc }

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
    _futureExecutions = _loadAndStartProcedures();
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
        await _repository.startProcedure(p.id);
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
          // — Buscador —
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // — Filtros de estado y rango —
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Filtrar por estado'),
                    value: _selectedStatus,
                    items: <String>['PENDING', 'ACTIVE', 'COMPLETED']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedStatus = v;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
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

          // — Ordenación —
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Text('Ordenar por:'),
                const SizedBox(width: 8),
                DropdownButton<SortField>(
                  value: _sortField,
                  items: SortField.values
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child:
                                Text(f == SortField.name ? 'Nombre' : 'Fecha'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _sortField = v;
                  }),
                ),
                IconButton(
                  icon: Icon(_sortOrder == SortOrder.asc
                      ? Icons.arrow_upward
                      : Icons.arrow_downward),
                  onPressed: () => setState(() {
                    _sortOrder = _sortOrder == SortOrder.asc
                        ? SortOrder.desc
                        : SortOrder.asc;
                  }),
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
