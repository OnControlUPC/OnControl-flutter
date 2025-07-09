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
  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'activo':
        return Colors.green;
      case 'completed':
      case 'completado':
        return Colors.blue;
      case 'pending':
      case 'pendiente':
        return Colors.orange;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'activo':
        return Icons.play_circle_filled;
      case 'completed':
      case 'completado':
        return Icons.check_circle;
      case 'pending':
      case 'pendiente':
        return Icons.schedule;
      case 'cancelled':
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.treatment.status);
    final statusIcon = _getStatusIcon(widget.treatment.status);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER (sin botón de chat)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
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
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.treatment.title.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          widget.treatment.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Información del Doctor (con botón de chat)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      44,
                                      194,
                                      49,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color.fromARGB(255, 44, 194, 49),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Doctor Asignado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      44,
                                      194,
                                      49,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          doctorUuid: widget
                                              .treatment
                                              .doctorProfileUuid,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color.fromARGB(255, 44, 194, 49),
                                    ),
                                    tooltip: 'Chatear con el doctor',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dr. ${widget.doctorName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Período del Tratamiento
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Período de Tratamiento',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 16,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Inicio: ${_formatDate(widget.treatment.period.startDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.stop,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Fin: ${_formatDate(widget.treatment.period.endDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de Acción
                    Column(
                      children: [
                        // Botón Síntomas
                        Container(
                          width: double.infinity,
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
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
                            icon: const Icon(
                              Icons.healing,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Ver y reportar síntomas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                44,
                                194,
                                49,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),

                        // Botón Procedimientos
                        Container(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
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
                            icon: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Ver procedimientos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                105,
                                96,
                                197,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
