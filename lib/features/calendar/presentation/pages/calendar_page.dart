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

  /// Mapa unificado: día → lista de Tratamientos, PredictedExecution y Citas
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
    _selectedDay = DateTime.now();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
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
      if (!mounted) return;

      _treatments = results[0] as List<Treatment>;
      _appointments = results[1] as List<Appointment>;
      final links = results[2] as List<DoctorPatientLink>;
      _doctorNames = { for (var l in links) l.doctorUuid: l.doctorFullName };

      _predictedExecutions.clear();
      final futures = _treatments
          .map((t) => _treatmentRepo.getPredictedExecutions(t.externalId));
      final lists = await Future.wait(futures);
      _predictedExecutions = lists.expand((l) => l).toList();

      _buildEventMap();
    } catch (e) {
      debugPrint('Error cargando calendario: $e');
      if (!mounted) return;
      _error = 'No se pudo cargar el calendario';
    } finally {
      if (!mounted) return;
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

    // PredictedExecutions: todos, incluso futuros
    for (var p in _predictedExecutions) {
      final day = DateTime(p.scheduledAt.year, p.scheduledAt.month, p.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(p);
    }

    // Citas: cada cita en su día
    for (var a in _appointments) {
      final day = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
      _events.putIfAbsent(day, () => []).add(a);
    }
  }

  List<Object> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _formatDateTime(DateTime d) {
    final local = d.toLocal();
    final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${local.day} ${months[local.month - 1]} ${local.year} • '
           '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
  }

  String cleanStatus(String status) => status.replaceAll('_', ' ');

  String _formatTime(DateTime d) {
    final local = d.toLocal();
    return '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
  }

  Color _getEventTypeColor(Object event) {
    if (event is Treatment) return const Color.fromARGB(255, 44, 194, 49);
    if (event is PredictedExecution) return const Color.fromARGB(255, 105, 96, 197);
    if (event is Appointment) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildCategoryDot(Color color) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Calendario Médico',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tratamientos, procedimientos y citas',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // CALENDARIO
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TableCalendar<Object>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selected, focused) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                          },
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: const BoxDecoration(
                                color: Colors.orange, shape: BoxShape.circle),
                            selectedDecoration: const BoxDecoration(
                                color: Color.fromARGB(255, 44, 194, 49),
                                shape: BoxShape.circle),
                            weekendTextStyle: TextStyle(color: Colors.red.shade400),
                            defaultTextStyle: const TextStyle(color: Color(0xFF1E293B)),
                          ),
                          calendarBuilders: CalendarBuilders<Object>(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return const SizedBox();
                              final hasTreatment = events.any((e) => e is Treatment);
                              final hasProcedure = events.any((e) => e is PredictedExecution);
                              final hasAppointment = events.any((e) => e is Appointment);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasTreatment) _buildCategoryDot(const Color.fromARGB(255, 44, 194, 49)),
                                  if (hasProcedure) _buildCategoryDot(const Color.fromARGB(255, 105, 96, 197)),
                                  if (hasAppointment) _buildCategoryDot(Colors.orange),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      // EVENTOS DEL DÍA
                      if (_selectedDay != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: _getEventsForDay(_selectedDay!).map((event) {
                              if (event is Treatment) {
                                final doctor = _doctorNames[event.doctorProfileUuid] ?? 'Desconocido';
                                return _EventCard(
                                  icon: Icons.medical_services,
                                  color: _getEventTypeColor(event),
                                  backgroundColor: Colors.white,
                                  title: event.title.value,
                                  subtitle: 'Período: ${_formatDateTime(event.period.startDate)} — ${_formatDateTime(event.period.endDate)}',
                                  badge: event.status,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TreatmentDetailPage(
                                        treatment: event,
                                        doctorName: doctor,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (event is PredictedExecution) {
                                final now = DateTime.now();
                                final isFuture = event.scheduledAt.toLocal().isAfter(now);
                                final isError = event.id == null || isFuture;
                                final isCompleted = event.status == "REGULARIZED" || event.status == "COMPLETED_ON_TIME";
                                final canAccess = !isError && !isCompleted;

                                final bgColor = isError
                                    ? Colors.red.shade50
                                    : isCompleted
                                        ? Colors.blue.shade50
                                        : Colors.white;
                                final iconColor = isError
                                    ? Colors.red
                                    : isCompleted
                                        ? Colors.blue
                                        : _getEventTypeColor(event);

                                return _EventCard(
                                  icon: Icons.schedule,
                                  color: iconColor,
                                  backgroundColor: bgColor,
                                  title: event.procedureName,
                                  subtitle: 'Programado: ${_formatTime(event.scheduledAt)}',
                                  badge: cleanStatus(event.status),
                                  onTap: canAccess
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TreatmentProceduresExecutionPage(execution: event),
                                            ),
                                          ).then((_) => _loadAll())
                                      : null,
                                );
                              }
                              if (event is Appointment) {
                                final doctor = _doctorNames[event.doctorProfileUuid] ?? 'Desconocido';
                                return _EventCard(
                                  icon: Icons.event,
                                  color: _getEventTypeColor(event),
                                  backgroundColor: Colors.white,
                                  title: 'Cita Médica',
                                  subtitle: 'Dr. $doctor — ${_formatTime(event.scheduledAt)}',
                                  badge: event.status,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AppointmentDetailPage(
                                        appointment: event,
                                        doctorName: doctor,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reutilizable card de evento
class _EventCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback? onTap;

  const _EventCard({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: backgroundColor,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
