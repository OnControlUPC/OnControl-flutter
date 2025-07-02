// lib/features/calendar/presentation/pages/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../treatments/data/datasources/treatment_remote_datasource.dart';
import '../../../treatments/data/repositories/treatment_repository_impl.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/presentation/pages/treatment_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final TreatmentRepositoryImpl _treatmentRepo;
  List<Treatment> _treatments = [];
  Map<DateTime, List<Treatment>> _events = {};
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
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _treatments = await _treatmentRepo.getTreatments();
      _buildEventMap();
    } catch (e) {
      debugPrint('Error loading treatments: $e');
      _error = 'Error cargando tratamientos';
    }
    setState(() {
      _loading = false;
    });
  }

  void _buildEventMap() {
    _events.clear();
    for (var t in _treatments) {
      DateTime day = DateTime(
        t.period.startDate.year,
        t.period.startDate.month,
        t.period.startDate.day,
      );
      final end = DateTime(
        t.period.endDate.year,
        t.period.endDate.month,
        t.period.endDate.day,
      );
      while (!day.isAfter(end)) {
        _events.putIfAbsent(day, () => []).add(t);
        day = day.add(const Duration(days: 1));
      }
    }
  }

  List<Treatment> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];

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
                                t.title.value,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('Desde ${_formatDate(t.period.startDate)}'),
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
