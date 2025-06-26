// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import '/features/treatments/presentation/pages/treatments_list_page.dart';
import '/features/doctor_patient_links/presentation/pages/pending_requests_page.dart';
import '/features/messages/presentation/pages/messages_page.dart';
import '/features/calendar/presentation/pages/calendar_page.dart';
import '/features/notifications/presentation/pages/notifications_page.dart';
import '/features/home/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const List<Widget> _pages = <Widget>[
    TreatmentsListPage(),  // pestaña de tratamientos
    PendingRequestsPage(),  // solicitudes de doctor-paciente
    MessagesPage(),
    CalendarPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) {
          print('🔀 [HomePage] Cambiando a pestaña índice=$idx');
          setState(() => _currentIndex = idx);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.healing),
            label: 'Tratamientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
