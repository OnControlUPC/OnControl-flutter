import 'package:flutter/material.dart';
import '../../../appointment/presentation/pages/appointments_list_page.dart';
import '/features/treatments/presentation/pages/treatments_list_page.dart';
import '../../../doctor_patient_links/presentation/pages/active_doctors_page.dart';
import '/features/calendar/presentation/pages/calendar_page.dart';
import '/features/home/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    TreatmentsListPage(), // pestaña de tratamientos
    AppointmentsListPage(), // solicitudes de doctor-paciente
    ActiveDoctorsPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 44, 194, 49).withOpacity(0.05),
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages.map((page) => SafeArea(child: page)).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 44, 194, 49).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 44, 194, 49),
                  Color.fromARGB(255, 105, 96, 197),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.healing_outlined, Icons.healing, 0),
                  label: 'Tratamientos',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.medical_services_outlined,
                    Icons.medical_services,
                    1,
                  ),
                  label: 'Citas',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.message_outlined, Icons.message, 2),
                  label: 'Mensajes',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.calendar_today_outlined,
                    Icons.calendar_today,
                    3,
                  ),
                  label: 'Calendario',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData unselectedIcon,
    IconData selectedIcon,
    int index,
  ) {
    final isSelected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        size: isSelected ? 26 : 24,
      ),
    );
  }
}
