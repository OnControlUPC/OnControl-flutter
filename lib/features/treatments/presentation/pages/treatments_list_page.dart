import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';
import '../../../doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../../doctor_patient_links/data/repositories/doctor_patient_link_repository_impl.dart';
import '../../../doctor_patient_links/domain/entities/doctor_patient_link.dart';
import 'treatment_detail_page.dart';

/// Página que muestra la lista de tratamientos del paciente autenticado,
/// junto con el nombre cacheado del doctor.
class TreatmentsListPage extends StatefulWidget {
  const TreatmentsListPage({Key? key}) : super(key: key);

  @override
  _TreatmentsListPageState createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends State<TreatmentsListPage> {
  late final TreatmentRepository _treatmentRepo;
  late final DoctorPatientLinkRepositoryImpl _linkRepo;
  Future<List<dynamic>>? _initFuture;

  /// Mapa: doctorUuid → doctorFullName
  Map<String, String> _doctorNames = {};

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage();
    _treatmentRepo = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: storage,
    );
    _linkRepo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: storage,
    );

    // Carga tratamientos y vínculos doctor-paciente en paralelo
    _initFuture = Future.wait([
      _treatmentRepo.getTreatments(),
      _linkRepo.getActiveLinks(),
    ]);
  }

  /// Refresca los datos cuando el usuario arrastra hacia abajo
  Future<void> _refreshData() async {
    setState(() {
      _initFuture = Future.wait([
        _treatmentRepo.getTreatments(),
        _linkRepo.getActiveLinks(),
      ]);
    });

    // Esperar a que se complete la carga
    try {
      final results = await _initFuture!;
      final treatments = results[0] as List<Treatment>;
      final links = results[1] as List<DoctorPatientLink>;

      // Actualizar el mapa de doctores
      _doctorNames = {for (var l in links) l.doctorUuid: l.doctorFullName};

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tratamientos actualizados'),
          backgroundColor: Color.fromARGB(255, 44, 194, 49),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Mostrar error si falla la actualización
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER (sin botón de retroceso)
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
                  const Text(
                    'Mis Tratamientos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona tus tratamientos médicos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color.fromARGB(255, 44, 194, 49),
                child: FutureBuilder<List<dynamic>>(
                  future: _initFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color.fromARGB(255, 44, 194, 49),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cargando tratamientos...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar tratamientos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snap.error}',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final treatments = snap.data![0] as List<Treatment>;
                    final links = snap.data![1] as List<DoctorPatientLink>;

                    // Creamos el mapa doctorUuid → doctorFullName
                    _doctorNames = {
                      for (var l in links) l.doctorUuid: l.doctorFullName,
                    };

                    if (treatments.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medical_services_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay tratamientos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aún no tienes tratamientos asignados',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Arrastra hacia abajo para actualizar',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: treatments.length,
                        itemBuilder: (context, index) {
                          final t = treatments[index];
                          final doctorName =
                              _doctorNames[t.doctorProfileUuid] ??
                              'Desconocido';
                          final statusColor = _getStatusColor(t.status);
                          final statusIcon = _getStatusIcon(t.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TreatmentDetailPage(
                                        treatment: t,
                                        doctorName: doctorName,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header del tratamiento
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.medical_services,
                                              color: Color.fromARGB(
                                                255,
                                                44,
                                                194,
                                                49,
                                              ),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              t.title.value,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  statusIcon,
                                                  size: 14,
                                                  color: statusColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  t.status,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Información del doctor
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dr. $doctorName',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Período del tratamiento
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_formatDate(t.period.startDate)} - ${_formatDate(t.period.endDate)}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Botón de acción
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      TreatmentDetailPage(
                                                        treatment: t,
                                                        doctorName: doctorName,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                            ),
                                            label: const Text('Ver detalles'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    44,
                                                    194,
                                                    49,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
