import 'package:flutter/material.dart';
import '../../domain/entities/appointment.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;
  const AppointmentDetailPage({required this.appointment, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Status:', style: theme.titleMedium),
            Text(appointment.status, style: theme.bodyMedium),
            const Divider(),

            Text('Scheduled At:', style: theme.titleMedium),
            Text(appointment.scheduledAt.toLocal().toString(), style: theme.bodyMedium),
            const Divider(),

            Text('Location Name:', style: theme.titleMedium),
            Text(appointment.locationName, style: theme.bodyMedium),
            const Divider(),

            Text('Maps URL:', style: theme.titleMedium),
            Text(appointment.locationMapsUrl, style: theme.bodyMedium),
            const Divider(),

            Text('Meeting URL:', style: theme.titleMedium),
            Text(appointment.meetingUrl, style: theme.bodyMedium),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
