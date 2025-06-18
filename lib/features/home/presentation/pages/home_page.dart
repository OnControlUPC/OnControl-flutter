// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import '/features/doctors/presentation/pages/doctors_page.dart';
import '/features/messages/presentation/pages/messages_page.dart';
import '/features/calendar/presentation/pages/calendar_page.dart';
import '/features/notifications/presentation/pages/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DoctorsPage(),        // ← primera pestaña: doctores
    MessagesPage(),
    CalendarPage(),
    NotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Doctores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notificaciones',
          ),
        ],
      ),
    );
  }
}
