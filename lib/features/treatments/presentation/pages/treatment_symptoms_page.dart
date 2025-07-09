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

  const TreatmentSymptomsPage({Key? key, required this.treatment})
    : super(key: key);

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
    loadLogs(); // Cambiar _loadLogs() por loadLogs()
  }

  /// Carga los logs de síntomas
  Future<void> loadLogs() async {
    try {
      setState(() {
        _futureLogs = _repo.getSymptomLogs(
          from: widget.treatment.period.startDate.toUtc(),
          to: widget.treatment.period.endDate.toUtc(),
        );
      });

      // Esperar a que se complete
      await _futureLogs;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Síntomas actualizados'),
          backgroundColor: Color.fromARGB(255, 44, 194, 49),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_typeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el tipo de síntoma')),
      );
      return;
    }

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
        loadLogs(); // Cambiar _loadLogs() por loadLogs()
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Síntoma reportado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Formatea restando 5 horas (UTC–5)
  String _fmt(DateTime dt) {
    final adjusted = dt.subtract(const Duration(hours: 5));
    return adjusted.toLocal().toString().split('.')[0];
  }

  String _formatDateOnly(DateTime dt) {
    final adjusted = dt.subtract(const Duration(hours: 5));
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${adjusted.day} ${months[adjusted.month - 1]} ${adjusted.year}';
  }

  Color _getSeverityColor(SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.MILD:
        return Colors.green;
      case SymptomSeverity.MODERATE:
        return Colors.orange;
      case SymptomSeverity.SEVERE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.MILD:
        return Icons.sentiment_satisfied;
      case SymptomSeverity.MODERATE:
        return Icons.sentiment_neutral;
      case SymptomSeverity.SEVERE:
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true, // Importante para evitar overflow
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 44, 194, 49),
                    Color.fromARGB(255, 105, 96, 197),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.healing,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Síntomas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reporta y consulta tus síntomas',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT - Usando SingleChildScrollView para evitar overflow
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadLogs,
                color: const Color.fromARGB(255, 44, 194, 49),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Lista de síntomas
                      SizedBox(
                        height: 300, // Altura fija para el historial
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          44,
                                          194,
                                          49,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.history,
                                        color: Color.fromARGB(255, 44, 194, 49),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Historial de Síntomas',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: FutureBuilder<List<SymptomLog>>(
                                    future: _futureLogs,
                                    builder: (context, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color.fromARGB(
                                              255,
                                              44,
                                              194,
                                              49,
                                            ),
                                          ),
                                        );
                                      } else if (snap.hasError) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                size: 48,
                                                color: Colors.red.shade300,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Error al cargar síntomas',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final logs = snap.data!;
                                      if (logs.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.sentiment_satisfied_alt,
                                                size: 48,
                                                color: Colors.grey.shade300,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No hay síntomas reportados',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: logs.length,
                                        itemBuilder: (_, i) {
                                          final log = logs[i];
                                          final severityColor =
                                              _getSeverityColor(log.severity);
                                          final severityIcon = _getSeverityIcon(
                                            log.severity,
                                          );

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Card(
                                              color: severityColor.withOpacity(
                                                0.05,
                                              ),
                                              child: ListTile(
                                                leading: Icon(
                                                  severityIcon,
                                                  color: severityColor,
                                                ),
                                                title: Text(
                                                  log.symptomType,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: severityColor
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            log.severity.name,
                                                            style: TextStyle(
                                                              color:
                                                                  severityColor,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          _formatDateOnly(
                                                            log.loggedAt,
                                                          ),
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (log
                                                        .notes
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        log.notes,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Formulario para reportar síntoma
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        105,
                                        96,
                                        197,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color.fromARGB(255, 105, 96, 197),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Reportar Síntoma',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Campo tipo
                              TextField(
                                controller: _typeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de síntoma',
                                  hintText: 'Ej: Dolor de cabeza, náuseas...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.medical_information_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Dropdown severidad
                              DropdownButtonFormField<SymptomSeverity>(
                                value: _severity,
                                decoration: InputDecoration(
                                  labelText: 'Severidad',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(
                                    _getSeverityIcon(_severity),
                                    color: _getSeverityColor(_severity),
                                  ),
                                ),
                                onChanged: (v) =>
                                    setState(() => _severity = v!),
                                items: SymptomSeverity.values
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getSeverityIcon(e),
                                              color: _getSeverityColor(e),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(e.name),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),

                              // Campo notas
                              TextField(
                                controller: _notesCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Notas adicionales (opcional)',
                                  hintText: 'Describe más detalles...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.note_outlined),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),

                              // Selector de fecha
                              InkWell(
                                onTap: _pickDateTime,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined),
                                      const SizedBox(width: 12),
                                      Text('Fecha: ${_fmt(_loggedAt)}'),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Botón enviar
                              Container(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _submit,
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                  label: Text(
                                    _loading
                                        ? 'Enviando...'
                                        : 'Reportar Síntoma',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      105,
                                      96,
                                      197,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Espacio adicional para evitar que el teclado tape el botón
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
