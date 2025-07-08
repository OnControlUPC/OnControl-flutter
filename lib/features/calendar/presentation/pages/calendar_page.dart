// lib/features/calendar/presentation/pages/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../treatments/data/datasources/treatment_remote_datasource.dart';
import '../../../treatments/data/repositories/treatment_repository_impl.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/domain/entities/predicted_execution.dart';
import '../../../treatments/presentation/pages/treatment_detail_page.dart';
import '../../../treatments/presentation/pages/treatment_procedures_page.dart';
import '../../../treatments/presentation/pages/treatment_procedures_execution_page.dart';


import '../../../appointment/data/datasources/appointment_remote_datasource.dart';
import '../../../appointment/data/repositories/appointment_repository_impl.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../appointment/presentation/pages/appointment_detail_page.dart';

import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final TreatmentRepositoryImpl _treatmentRepo;
  late final AppointmentRepositoryImpl _appointmentRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;

  List<Treatment> _treatments = [];
  List<PredictedExecution> _predictedExecutions = [];
  List<Appointment> _appointments = [];
  Map<String, String> _doctorNames = {};

  /// Mapa unificado: día → lista de Tratamientos, Procedimientos y Citas
  final Map<DateTime, List<Object>> _events = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _treatmentRepo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _appointmentRepo = AppointmentRepositoryImpl(
      remote: AppointmentRemoteDataSourceImpl(),
    );
    _linkRepo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 1. Traer tratamientos, citas y vínculos en paralelo
      final results = await Future.wait([
        _treatmentRepo.getTreatments(),
        _appointmentRepo.getAppointments(),
        _linkRepo.getActiveLinks(),
      ]);
      _treatments = results[0] as List<Treatment>;
      _appointments = results[1] as List<Appointment>;
      final links = results[2] as List<DoctorPatientLink>;

      // 2. Cachear doctorUuid → doctorFullName
      _doctorNames = {for (var l in links) l.doctorUuid: l.doctorFullName};

      // 3. Traer procedimientos predichos
      _predictedExecutions.clear();
      for (var t in _treatments) {
        final preds = await _treatmentRepo.getPredictedExecutions(t.externalId);
        _predictedExecutions.addAll(preds);
      }

      // 4. Construir mapa de eventos mixto
      _buildEventMap();
    } catch (e) {
      debugPrint('Error cargando calendario: $e');
      _error = 'No se pudo cargar el calendario';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _buildEventMap() {
    _events.clear();

    // Tratamientos: cada día del periodo
    for (var t in _treatments) {
      var day = DateTime(t.period.startDate.year, t.period.startDate.month, t.period.startDate.day);
      final end = DateTime(t.period.endDate.year, t.period.endDate.month, t.period.endDate.day);
      while (!day.isAfter(end)) {
        _events.putIfAbsent(day, () => []).add(t);
        day = day.add(const Duration(days: 1));
      }
    }

    // Procedimientos previstos
    for (var p in _predictedExecutions) {
      final day = DateTime(p.scheduledAt.year, p.scheduledAt.month, p.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(p);
    }

    // Citas
    for (var a in _appointments) {
      final day = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(a);
    }
  }

  /// Devuelve la lista mixta de eventos para un día dado
  List<Object> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2,'0')}-${local.day.toString().padLeft(2,'0')} '
           '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 44, 194, 49), Color.fromARGB(255, 105, 96, 197)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: const Center(
                child: Text('Calendario de Tratamientos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),

            // Calendario
            TableCalendar<Object>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
            ),

            const SizedBox(height: 12),

            // Lista de eventos del día
            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text('Seleccione un día para ver eventos'))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: ListView.builder(
                        itemCount: _getEventsForDay(_selectedDay!).length,
                        itemBuilder: (context, i) {
                          final ev = _getEventsForDay(_selectedDay!)[i];

                          if (ev is Treatment) {
                            final doctorName = _doctorNames[ev.doctorProfileUuid] ?? 'Desconocido';
                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                title: Text(ev.title.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('Periodo: ${_formatDate(ev.period.startDate)} → ${_formatDate(ev.period.endDate)}'),
                                trailing: Text(ev.status, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TreatmentDetailPage(treatment: ev, doctorName: doctorName))),
                              ),
                            );
                          }

                          if (ev is PredictedExecution) {
                            final treatment = _treatments.firstWhere((t) => t.externalId == ev.treatmentExternalId);
                            return Card(
                              color: Colors.blue.shade50,
                              child: ListTile(
                                leading: const Icon(Icons.medical_services, color: Colors.blue),
                                title: Text(ev.procedureName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('Agendado: ${_formatDate(ev.scheduledAt)}'),
                                trailing: Text(ev.status, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TreatmentProcedurePage(treatment: treatment))),
                              ),
                            );
                          }

                          if (ev is Appointment) {
                            final doctorName = _doctorNames[ev.doctorProfileUuid] ?? 'Desconocido';
                            return Card(
                              color: Colors.pink.shade50,
                              child: ListTile(
                                leading: const Icon(Icons.event, color: Colors.pink),
                                title: Text('Cita: ${_formatDate(ev.scheduledAt)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('Dr. $doctorName • ${ev.status}'),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailPage(appointment: ev, doctorName: doctorName))),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
