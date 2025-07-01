// lib/features/treatments/presentation/pages/treatment_detail_page.dart

import 'package:flutter/material.dart';
import '../../domain/entities/treatment.dart';

class TreatmentDetailPage extends StatelessWidget {
  final Treatment treatment;

  const TreatmentDetailPage({Key? key, required this.treatment})
      : super(key: key);

  String _formatDate(DateTime date) =>
      date.toLocal().toString().split(' ')[0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado degradado
            Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 44, 194, 49),
        Color.fromARGB(255, 105, 96, 197),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      const SizedBox(height: 8),
      Center(
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in, size: 56, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              treatment.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatDate(treatment.startDate)} → ${_formatDate(treatment.endDate)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    ],
  ),
),


            const SizedBox(height: 20),

            // Tarjeta de detalles (no se expande)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        icon: Icons.check_circle_outline,
                        label: 'Estado',
                        value: treatment.status,
                      ),
                      const Divider(indent: 48, endIndent: 16),
                      _infoRow(
                        icon: Icons.date_range,
                        label: 'Fecha de creación',
                        value: _formatDate(treatment.createdAt),
                      ),
                      const Divider(indent: 48, endIndent: 16),
                      _infoRow(
                        icon: Icons.person_pin,
                        label: 'Doctor UUID',
                        value: treatment.doctorProfileUuid,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 49, 209, 79)),
      title: Text(label),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
