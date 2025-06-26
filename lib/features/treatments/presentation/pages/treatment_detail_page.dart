// lib/features/treatments/presentation/pages/treatment_detail_page.dart

import 'package:flutter/material.dart';
import '../../domain/entities/treatment.dart';

class TreatmentDetailPage extends StatelessWidget {
  final Treatment treatment;

  const TreatmentDetailPage({Key? key, required this.treatment})
      : super(key: key);

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Tratamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título:', style: theme.titleMedium),
            Text(treatment.title, style: theme.titleLarge),
            const SizedBox(height: 16),
            Text('Período:', style: theme.titleMedium),
            Text(
              '${_formatDate(treatment.startDate)}  →  ${_formatDate(treatment.endDate)}',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Estado:', style: theme.titleMedium),
            Text(treatment.status, style: theme.bodyMedium),
            const SizedBox(height: 16),
            Text('Creado el:', style: theme.titleMedium),
            Text(_formatDate(treatment.createdAt), style: theme.bodyMedium),
            const SizedBox(height: 16),
            Text('Perfil Doctor (UUID):', style: theme.titleMedium),
            Text(treatment.doctorProfileUuid, style: theme.bodyMedium),
          ],
        ),
      ),
    );
  }
}