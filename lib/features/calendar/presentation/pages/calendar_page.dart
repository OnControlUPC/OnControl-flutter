import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: const Center(
        child: Text(
          'Aquí se mostrará tu calendario',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
