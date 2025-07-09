// lib/features/appointments/presentation/pages/appointment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment.dart';

/// Diálogo modal para mostrar el detalle de una cita mejorado
class AppointmentDetailDialog extends StatelessWidget {
  final Appointment appointment;
  final String doctorName;

  const AppointmentDetailDialog({
    Key? key,
    required this.appointment,
    required this.doctorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy • HH:mm');
    final isVirtual = (appointment.meetingUrl ?? '').isNotEmpty;
    final theme = Theme.of(context);
    final repo = AppointmentRepositoryImpl(
      remote: AppointmentRemoteDataSourceImpl(),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con avatar y cerrar
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      doctorName
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Dr. $doctorName',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fecha y Estado
              Card(
                color: theme.colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          df.format(appointment.scheduledAt.toLocal()),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Chip(
                        label: Text(
                          appointment.status.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: appointment.status == 'SCHEDULED'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Detalle de ubicación o enlace virtual
              Text(
                isVirtual ? 'Reunión virtual' : 'Ubicación presencial',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isVirtual ? Icons.videocam : Icons.location_on,
                  color: isVirtual ? Colors.blue : Colors.red,
                ),
                title: Text(
                  isVirtual
                      ? appointment.meetingUrl!
                      : (appointment.locationName.isNotEmpty
                          ? appointment.locationName
                          : 'No especificada'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () async {
                  final url = isVirtual
                      ? appointment.meetingUrl!
                      : appointment.locationMapsUrl!;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
              const SizedBox(height: 32),

              // Botón Cancelar cita
              ElevatedButton(
                onPressed: () async {
                  await repo.deleteAppointment(appointment.id);
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cancelar cita',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra el diálogo y devuelve true si la cita fue cancelada
Future<bool?> showAppointmentDetailDialog(
  BuildContext context,
  Appointment appointment,
  String doctorName,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AppointmentDetailDialog(
      appointment: appointment,
      doctorName: doctorName,
    ),
  );
}