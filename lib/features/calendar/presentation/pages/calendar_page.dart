// lib/features/calendar/presentation/pages/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../treatments/data/datasources/treatment_remote_datasource.dart';
import '../../../treatments/data/repositories/treatment_repository_impl.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/domain/entities/predicted_execution.dart';
import '../../../treatments/presentation/pages/treatment_detail_page.dart';
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
  final _storage = const FlutterSecureStorage();
  late final _treatmentRepo = TreatmentRepositoryImpl(
    remote: TreatmentRemoteDataSourceImpl(),
    secureStorage: _storage,
  );
  late final _appointmentRepo = AppointmentRepositoryImpl(
    remote: AppointmentRemoteDataSourceImpl(),
  );
  late final _linkRepo = DoctorPatientLinkRepositoryImpl(
    remote: DoctorPatientLinkRemoteDataSourceImpl(),
    secureStorage: _storage,
  );

  List<Treatment> _treatments = [];
  List<PredictedExecution> _predictedExecutions = [];
  List<Appointment> _appointments = [];
  Map<String, String> _doctorNames = {};
  final Map<DateTime, List<Object>> _events = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _treatmentRepo.getTreatments(),
        _appointmentRepo.getAppointments(),
        _linkRepo.getActiveLinks(),
      ]);
      _treatments = results[0] as List<Treatment>;
      _appointments = results[1] as List<Appointment>;
      final links = results[2] as List<DoctorPatientLink>;
      _doctorNames = { for (var l in links) l.doctorUuid: l.doctorFullName };

      _predictedExecutions.clear();
      for (var t in _treatments) {
        final preds = await _treatmentRepo.getPredictedExecutions(t.externalId);
        _predictedExecutions.addAll(preds);
      }

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

    // Treatments: cada día del periodo
    for (var t in _treatments) {
      var day = DateTime(t.period.startDate.year, t.period.startDate.month, t.period.startDate.day);
      final end = DateTime(t.period.endDate.year, t.period.endDate.month, t.period.endDate.day);
      while (!day.isAfter(end)) {
        _events.putIfAbsent(day, () => []).add(t);
        day = day.add(const Duration(days: 1));
      }
    }

    // PredictedExecutions: todos, incluso id == null
    for (var p in _predictedExecutions) {
      final day = DateTime(p.scheduledAt.year, p.scheduledAt.month, p.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(p);
    }

    // Appointments: cada cita en su día
    for (var a in _appointments) {
      final day = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(a);
    }
  }

  List<Object> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2,'0')}-${l.day.toString().padLeft(2,'0')} '
        '${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
  }

  Widget _buildCategoryDot(Color color) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // cabecera con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2CC231), Color(0xFF695EC5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Text(
                  'Calendario de Tratamientos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            TableCalendar<Object>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: _getEventsForDay,
              onDaySelected: (sel, foc) {
                setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration:
                    BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                selectedDecoration:
                    BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              calendarBuilders: CalendarBuilders<Object>(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  final hasTreatment =
                      events.any((e) => e is Treatment);
                  final hasProcedure =
                      events.any((e) => e is PredictedExecution);
                  final hasAppointment =
                      events.any((e) => e is Appointment);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasTreatment) _buildCategoryDot(Colors.green),
                      if (hasProcedure) _buildCategoryDot(Colors.blue),
                      if (hasAppointment) _buildCategoryDot(Colors.pink),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text('Seleccione un día'))
                  : ListView.builder(
                      itemCount: _getEventsForDay(_selectedDay!).length,
                      itemBuilder: (ctx, i) {
                        final ev = _getEventsForDay(_selectedDay!)[i];

                        if (ev is Treatment) {
                          final doc =
                              _doctorNames[ev.doctorProfileUuid] ?? 'Desconocido';
                          return Card(
                            color: Colors.green.shade50,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(ev.title.value),
                              subtitle: Text(
                                'Período: ${_formatDate(ev.period.startDate)} → ${_formatDate(ev.period.endDate)}',
                              ),
                              trailing: Text(ev.status),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TreatmentDetailPage(
                                    treatment: ev,
                                    doctorName: doc,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (ev is PredictedExecution) {
                          final canAccess = ev.id != null &&
                              ev.status.toUpperCase() == 'PENDING';
                          return Card(
                            color: canAccess
                                ? Colors.blue.shade50
                                : Colors.blue.shade100,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.medical_services,
                                  color: Colors.blue),
                              title: Text(ev.procedureName),
                              subtitle: Text(
                                  'Agendado: ${_formatDate(ev.scheduledAt)}'),
                              trailing: Text(ev.status),
                              onTap: canAccess
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TreatmentProceduresExecutionPage(
                                                  execution: ev),
                                        ),
                                      )
                                  : null,
                            ),
                          );
                        }

                        if (ev is Appointment) {
                          final doc =
                              _doctorNames[ev.doctorProfileUuid] ?? 'Desconocido';
                          return Card(
                            color: Colors.pink.shade50,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.event, color: Colors.pink),
                              title: Text('Cita: ${_formatDate(ev.scheduledAt)}'),
                              subtitle: Text('Dr. $doc • ${ev.status}'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailPage(
                                    appointment: ev,
                                    doctorName: doc,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
