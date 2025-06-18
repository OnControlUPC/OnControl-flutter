import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: const Center(
        child: Text(
          'Aquí verás tus notificaciones',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
