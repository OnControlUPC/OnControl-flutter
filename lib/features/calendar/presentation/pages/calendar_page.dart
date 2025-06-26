// lib/features/calendar/presentation/pages/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/http_client.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../treatments/data/datasources/treatment_remote_datasource.dart';
import '../../../treatments/data/repositories/treatment_repository_impl.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '/features/treatments/presentation/pages/treatment_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final TreatmentRepositoryImpl _repo;
  late final DoctorPatientLinkRemoteDataSourceImpl _linkDs;

  List<Treatment> _treatments = [];
  Map<DateTime, List<Treatment>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _linkDs = DoctorPatientLinkRemoteDataSourceImpl(
      client: createHttpClient(),
    );
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _storage.read(key: 'token') ?? '';
    print('▶️ [CalendarPage] token=$token');
    if (token.isEmpty) {
      setState(() {
        _error = 'Sesión no iniciada';
        _loading = false;
      });
      return;
    }

    try {
      // Obtener UUID del paciente desde doctor_patient_links
      final patientUuid = await _linkDs.fetchPatientUuid(token);
      print('🔍 [CalendarPage] patientUuid=$patientUuid');

      // Obtener tratamientos usando la UUID obtenida
      final list = await _repo.getTreatments(patientUuid, token);
      print('🔔 [CalendarPage] tratamientos encontrados: ${list.length}');
      _treatments = list;
      _buildEventMap();
    } catch (e) {
      print('❌ [CalendarPage] error: $e');
      _error = 'Error cargando tratamientos';
    }

    setState(() {
      _loading = false;
    });
  }

  void _buildEventMap() {
    _events.clear();
    for (var treatment in _treatments) {
      DateTime day = treatment.startDate.toLocal();
      final end = treatment.endDate.toLocal();
      while (!day.isAfter(end)) {
        final key = DateTime(day.year, day.month, day.day);
        _events.putIfAbsent(key, () => []).add(treatment);
        day = day.add(const Duration(days: 1));
      }
    }
  }

  List<Treatment> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          TableCalendar<Treatment>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
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
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Seleccione un día'))
                : ListView(
                    children: _getEventsForDay(_selectedDay!).map((t) {
                      return ListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          'Del ${_formatDate(t.startDate)} al ${_formatDate(t.endDate)}',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreatmentDetailPage(treatment: t),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}