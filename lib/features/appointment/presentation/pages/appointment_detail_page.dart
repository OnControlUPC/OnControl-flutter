
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/appointment.dart';

/// Página completa de detalle de cita con estilo mejorado y acciones
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
    final df = DateFormat('dd MMM yyyy • HH:mm');
    final theme = Theme.of(context);
    final isVirtual = appointment.meetingUrl?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $doctorName',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      df.format(appointment.scheduledAt.toLocal()),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      appointment.status.toUpperCase(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Enlace según tipo de cita
                if (isVirtual) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.videocam, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse(appointment.meetingUrl!)),
                          child: Text(
                            'Google Meet: ${appointment.meetingUrl}',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse(appointment.locationMapsUrl!)),
                          child: Text(
                            appointment.locationName.isNotEmpty
                                ? appointment.locationName
                                : 'Ubicación sin especificar',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(appointment.locationMapsUrl!)),
                    child: const Text(
                      'Abrir en Google Maps',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Botón Cancelar Cita
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: manejar cancelación
                    },
                    child: const Text('Cancelar cita'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
