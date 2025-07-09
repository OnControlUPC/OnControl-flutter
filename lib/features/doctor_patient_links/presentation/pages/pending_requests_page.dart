import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/doctor_patient_link_remote_datasource.dart';
import '../../data/repositories/doctor_patient_link_repository_impl.dart';
import '../../domain/entities/doctor_patient_link.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({Key? key}) : super(key: key);

  @override
  _PendingRequestsPageState createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  final _storage = const FlutterSecureStorage();
  late final DoctorPatientLinkRepositoryImpl _repo;
  List<DoctorPatientLink> _links = [];
  bool _loading = true;
  String? _error;
  Set<String> _processingLinks =
      {}; // Para manejar estados de carga individuales

  @override
  void initState() {
    super.initState();
    _repo = DoctorPatientLinkRepositoryImpl(
      remote: DoctorPatientLinkRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _repo.getPendingLinks();
      print('🔔 [PendingRequests] encontrados: ${list.length}');
      setState(() {
        _links = list;
        _loading = false;
      });
    } catch (e) {
      print('❌ [PendingRequests] error: $e');
      setState(() {
        _error = 'Error al cargar solicitudes';
        _loading = false;
      });
    }
  }

  Future<void> _acceptRequest(String externalId, String doctorName) async {
    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Solicitud'),
        content: Text(
          '¿Estás seguro de que quieres aceptar la solicitud del Dr. $doctorName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 44, 194, 49),
            ),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _processingLinks.add(externalId);
    });

    try {
      // Primero aceptar
      await _repo.acceptLink(externalId);
      print('✅ [PendingRequests] aceptado $externalId');

      // Luego activar
      await _repo.activateLink(externalId);
      print('✅ [PendingRequests] activado $externalId');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud del Dr. $doctorName aceptada y activada'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      await _loadLinks();
    } catch (e) {
      print('❌ [PendingRequests] accept error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar solicitud: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _processingLinks.remove(externalId);
      });
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
    final localDate = date.toLocal();
    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
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
                      Icons.person_add_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Solicitudes Pendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisa y acepta solicitudes de doctores',
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
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color.fromARGB(255, 44, 194, 49),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Cargando solicitudes...',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                  ? Center(
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
                            'Error al cargar solicitudes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadLinks,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                44,
                                194,
                                49,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _links.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay solicitudes pendientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Todas las solicitudes han sido procesadas',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLinks,
                      color: const Color.fromARGB(255, 44, 194, 49),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView.builder(
                          itemCount: _links.length,
                          itemBuilder: (context, i) {
                            final link = _links[i];
                            final isProcessing = _processingLinks.contains(
                              link.externalId,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header de la solicitud
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                255,
                                                44,
                                                194,
                                                49,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.local_hospital,
                                              color: Color.fromARGB(
                                                255,
                                                44,
                                                194,
                                                49,
                                              ),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Dr. ${link.doctorFullName}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Solicitud de conexión',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.pending_actions,
                                                  size: 14,
                                                  color: Colors.orange.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Pendiente',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade600,
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

                                      // Información adicional
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Solicitada el ${_formatDate(link.createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Descripción
                                      Text(
                                        'El Dr. ${link.doctorFullName} ha solicitado conectarse contigo para poder gestionar tus tratamientos médicos.',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Botón de acción
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _acceptRequest(
                                                  link.externalId,
                                                  link.doctorFullName,
                                                ),
                                          icon: isProcessing
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                          label: Text(
                                            isProcessing
                                                ? 'Procesando...'
                                                : 'Aceptar Solicitud',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  44,
                                                  194,
                                                  49,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
