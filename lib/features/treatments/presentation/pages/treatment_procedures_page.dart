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
  final _searchController = TextEditingController();

  // filtros y orden
  String? _searchTerm;
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  SortField _sortField = SortField.date;
  SortOrder _sortOrder = SortOrder.asc;

  List<Procedure> _procedures = [];
  List<PredictedExecution> _predictedExecutions = [];
  bool _loading = false;

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
    _loadProcedures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProcedures() async {
    setState(() => _loading = true);
    try {
      final procs =
          await _repository.getProcedures(widget.treatment.externalId);

      // arrancar los pendientes
      for (var p in procs) {
        if (p.status.toUpperCase() == 'PENDING') {
          await _repository.startProcedure(p.id);
        }
      }

      final preds = await _repository
          .getPredictedExecutions(widget.treatment.externalId);

      setState(() {
        _procedures = procs;
        _predictedExecutions = preds;
      });
    } catch (e) {
      debugPrint('Error loading procedures: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar procedimientos')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<PredictedExecution> get _filteredAndSorted {
    // 1. Filtrar por texto & estado & rango de fechas
    final filtered = _predictedExecutions.where((e) {
      final nameMatch = _searchTerm == null ||
          _searchTerm!.isEmpty ||
          e.procedureName
              .toLowerCase()
              .contains(_searchTerm!.toLowerCase());

      final statusMatch = _selectedStatus == null ||
          e.status == _selectedStatus;

      final dateMatch = _dateRange == null ||
          (e.scheduledAt.isAfter(_dateRange!.start.subtract(const Duration(days:1))) &&
           e.scheduledAt.isBefore(_dateRange!.end.add(const Duration(days:1))));

      return nameMatch && statusMatch && dateMatch;
    }).toList();

    // 2. Ordenar
    filtered.sort((a, b) {
      int cmp;
      if (_sortField == SortField.name) {
        cmp = a.procedureName.compareTo(b.procedureName);
      } else {
        cmp = a.scheduledAt.compareTo(b.scheduledAt);
      }
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
          // ————— Controles de búsqueda y filtros —————
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Estado
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
                    onChanged: (v) =>
                        setState(() => _selectedStatus = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Rango de fecha
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
          // Ordenación
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
                            child: Text(f == SortField.name
                                ? 'Nombre'
                                : 'Fecha'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _sortField = v!),
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
          // ————— Lista de resultados —————
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAndSorted.isEmpty
                    ? const Center(
                        child:
                            Text('No hay registros que mostrar'),
                      )
                    : ListView.builder(
                        itemCount: _filteredAndSorted.length,
                        itemBuilder: (_, i) {
                          final e = _filteredAndSorted[i];
                          return ListTile(
                            title: Text(e.procedureName,
                                style: theme.titleMedium),
                            subtitle: Text(
                              'Agendado: ${df.format(e.scheduledAt)}',
                              style: theme.bodySmall,
                            ),
                            trailing: Text(e.status,
                                style: theme.labelMedium),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
