import 'package:flutter/material.dart';
import '/features/doctors/presentation/pages/doctors_page.dart';
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
    DoctorsPage(),
    MessagesPage(),
    CalendarPage(),
    NotificationsPage(),
    ProfilePage(), // pestaña de perfil
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
            icon: Icon(Icons.medical_services),
            label: 'Doctores',
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