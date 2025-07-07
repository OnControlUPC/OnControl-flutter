// lib/features/treatments/presentation/pages/treatment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:oncontrol/features/treatments/presentation/pages/treatment_procedures_page.dart';
import '../../../doctor_patient_links/presentation/pages/chat_screen.dart';
import '../../domain/entities/treatment.dart';
import 'treatment_symptoms_page.dart';

/// Detalle de un tratamiento, recibiendo el nombre del doctor por parámetro.
/// Ya no hace ninguna llamada adicional para cargar el nombre.
class TreatmentDetailPage extends StatefulWidget {
  final Treatment treatment;
  final String doctorName;
  const TreatmentDetailPage({
    Key? key,
    required this.treatment,
    required this.doctorName,
  }) : super(key: key);

  @override
  _TreatmentDetailPageState createState() => _TreatmentDetailPageState();
}

class _TreatmentDetailPageState extends State<TreatmentDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Tratamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text('Título', style: theme.titleMedium),
            Text(widget.treatment.title.value, style: theme.bodyMedium),
            const Divider(),

            // Nombre del doctor + chat
            Text('Doctor', style: theme.titleMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.doctorName, style: theme.bodyMedium),
                IconButton(
                  icon: Icon(
                    Icons.chat,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        doctorUuid: widget.treatment.doctorProfileUuid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Estado
            Text('Estado', style: theme.titleMedium),
            Text(widget.treatment.status, style: theme.bodyMedium),
            const Divider(),

            // Período
            Text('Período', style: theme.titleMedium),
            Text(
              'Desde: ${widget.treatment.period.startDate.toLocal()}',
              style: theme.bodyMedium,
            ),
            Text(
              'Hasta: ${widget.treatment.period.endDate.toLocal()}',
              style: theme.bodyMedium,
            ),
            const Divider(),

            // Botones de navegación
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TreatmentSymptomsPage(
                      treatment: widget.treatment,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.healing),
              label: const Text('Ver y reportar síntomas'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TreatmentProcedurePage(
                      treatment: widget.treatment,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.healing),
              label: const Text('Procedimientos'),
            ),
          ],
        ),
      ),
    );
  }
}
