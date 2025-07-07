// lib/features/appointments/presentation/pages/appointment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment.dart';

/// Detalle de cita sin mostrar el ID, con nombre de doctor pasado desde la lista.
class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;
  final String doctorName;

  const AppointmentDetailPage({
    Key? key,
    required this.appointment,
    required this.doctorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = appointment;
    final theme = Theme.of(context).textTheme;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Cita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Doctor:', style: theme.titleMedium),
            Text('Dr. $doctorName', style: theme.bodyMedium),
            const Divider(),

            Text('Fecha y hora:', style: theme.titleMedium),
            Text(df.format(t.scheduledAt), style: theme.bodyMedium),
            const Divider(),

            Text('Estado:', style: theme.titleMedium),
            Text(t.status, style: theme.bodyMedium),
            const Divider(),

            Text('Ubicación:', style: theme.titleMedium),
            Text(
              t.locationName.isNotEmpty ? t.locationName : 'No especificada',
              style: theme.bodyMedium,
            ),
            const Divider(),

            Text('Mapa (URL):', style: theme.titleMedium),
            Text(t.locationMapsUrl ?? 'No disponible',
                style: theme.bodyMedium),
            const Divider(),

            Text('Reunión (URL):', style: theme.titleMedium),
            Text(t.meetingUrl ?? 'No disponible', style: theme.bodyMedium),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
