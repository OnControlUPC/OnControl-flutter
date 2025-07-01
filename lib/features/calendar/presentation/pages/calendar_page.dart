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
    _linkDs = DoctorPatientLinkRemoteDataSourceImpl(client: createHttpClient());
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      setState(() {
        _error = 'Sesión no iniciada';
        _loading = false;
      });
      return;
    }

    try {
      final patientUuid = await _linkDs.fetchPatientUuid(token);
      final list = await _repo.getTreatments(patientUuid, token);
      _treatments = list;
      _buildEventMap();
    } catch (e) {
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header degradado
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
              child: const Center(
                child: Text(
                  'Calendario de Tratamientos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Calendario
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
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Lista de tratamientos del día
            Expanded(
  child: _selectedDay == null
      ? const Center(child: Text('Seleccione un día para ver tratamientos'))
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.builder(
            itemCount: _getEventsForDay(_selectedDay!).length,
            itemBuilder: (context, i) {
              final t = _getEventsForDay(_selectedDay!)[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Desde ${_formatDate(t.startDate)}'),
                  trailing: Text(
                    t.status,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreatmentDetailPage(treatment: t),
                    ),
                  ),
                ),
              );
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
