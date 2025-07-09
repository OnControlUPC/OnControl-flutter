import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/procedure.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';

class TreatmentProcedurePage extends StatefulWidget {
  final Treatment treatment;

  const TreatmentProcedurePage({Key? key, required this.treatment})
    : super(key: key);

  @override
  _TreatmentProcedurePageState createState() => _TreatmentProcedurePageState();
}

class _TreatmentProcedurePageState extends State<TreatmentProcedurePage> {
  late final TreatmentRepository _repository;
  late Future<List<Procedure>> _proceduresFuture;
  Set<int> _acceptedProcedures =
      {}; // IDs de procedimientos aceptados localmente

  @override
  void initState() {
    super.initState();
    _repository = TreatmentRepositoryImpl(
      remote: TreatmentRemoteDataSourceImpl(),
      secureStorage: const FlutterSecureStorage(),
    );
    _loadAcceptedProcedures();
    _proceduresFuture = _loadProcedures();
  }

  /// Carga los procedimientos aceptados localmente
  Future<void> _loadAcceptedProcedures() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedIds =
        prefs.getStringList(
          'accepted_procedures_${widget.treatment.externalId}',
        ) ??
        [];
    setState(() {
      _acceptedProcedures = acceptedIds.map((id) => int.parse(id)).toSet();
    });
  }

  /// Guarda un procedimiento como aceptado localmente
  Future<void> _saveAcceptedProcedure(int procedureId) async {
    final prefs = await SharedPreferences.getInstance();
    _acceptedProcedures.add(procedureId);
    final acceptedIds = _acceptedProcedures.map((id) => id.toString()).toList();
    await prefs.setStringList(
      'accepted_procedures_${widget.treatment.externalId}',
      acceptedIds,
    );
  }

  /// Carga los procedures
  Future<List<Procedure>> _loadProcedures() async {
    final procs = await _repository.getProcedures(widget.treatment.externalId);
    return procs;
  }

  /// Refresca la lista de procedimientos
  Future<void> _refreshProcedures() async {
    try {
      // Recargar procedimientos aceptados localmente
      await _loadAcceptedProcedures();

      // Recargar procedimientos del servidor
      setState(() {
        _proceduresFuture = _loadProcedures();
      });

      // Esperar a que se complete
      await _proceduresFuture;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimientos actualizados'),
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

  /// Acepta un procedimiento pendiente (solo localmente)
  Future<void> _onAcceptPressed(int procedureId) async {
    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Procedimiento'),
        content: const Text(
          '¿Estás seguro de que quieres aceptar este procedimiento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Guardar como aceptado localmente
      await _saveAcceptedProcedure(procedureId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimiento aceptado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        // Recargar la vista para mostrar el nuevo estado
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Inicia un procedimiento ya aceptado
  Future<void> _onStartPressed(int procedureId) async {
    // Mostrar confirmación antes de iniciar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Procedimiento'),
        content: const Text(
          '¿Estás seguro de que quieres iniciar este procedimiento ahora?',
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
            child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final nowUtc = DateTime.now().toUtc().add(const Duration(minutes: 2));
    try {
      await _repository.startProcedure(procedureId, nowUtc);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimiento iniciado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _proceduresFuture = _loadProcedures();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return df.format(date);
  }

  /// Determina el estado del procedimiento basado en datos del backend y aceptación local
  ProcedureStatus _getProcedureStatus(Procedure procedure) {
    // Si ya tiene startDateTime, está iniciado
    if (procedure.startDateTime != null) {
      return ProcedureStatus.started;
    }

    // Si fue aceptado localmente, está aceptado
    if (_acceptedProcedures.contains(procedure.id)) {
      return ProcedureStatus.accepted;
    }

    // Verificar el estado del backend para casos especiales
    switch (procedure.status.toUpperCase()) {
      case 'ACCEPTED':
      case 'ACEPTADO':
      case 'APPROVED':
      case 'APROBADO':
      case 'READY':
      case 'LISTO':
      case 'ACTIVE':
      case 'ACTIVO':
        return ProcedureStatus.accepted;
      case 'STARTED':
      case 'INICIADO':
      case 'IN_PROGRESS':
      case 'EN_PROGRESO':
      case 'COMPLETED':
      case 'COMPLETADO':
        return ProcedureStatus.started;
      default:
        return ProcedureStatus.pending; // Por defecto, pendiente
    }
  }

  Color _getStatusColor(ProcedureStatus status) {
    switch (status) {
      case ProcedureStatus.pending:
        return Colors.orange;
      case ProcedureStatus.accepted:
        return Colors.blue;
      case ProcedureStatus.started:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ProcedureStatus status) {
    switch (status) {
      case ProcedureStatus.pending:
        return Icons.pending_actions;
      case ProcedureStatus.accepted:
        return Icons.check_circle_outline;
      case ProcedureStatus.started:
        return Icons.play_circle_filled;
    }
  }

  String _getStatusText(ProcedureStatus status) {
    switch (status) {
      case ProcedureStatus.pending:
        return 'Pendiente';
      case ProcedureStatus.accepted:
        return 'Aceptado';
      case ProcedureStatus.started:
        return 'Iniciado';
    }
  }

  String _getStatusDescription(ProcedureStatus status, Procedure procedure) {
    switch (status) {
      case ProcedureStatus.pending:
        return 'Pendiente de aceptación';
      case ProcedureStatus.accepted:
        return 'Aceptado - Listo para iniciar';
      case ProcedureStatus.started:
        return 'Iniciado el ${_formatDate(procedure.startDateTime!)}';
    }
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
                      Icons.medical_services_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Procedimientos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona los procedimientos del tratamiento',
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
                onRefresh: _refreshProcedures,
                color: const Color.fromARGB(255, 44, 194, 49),
                child: FutureBuilder<List<Procedure>>(
                  future: _proceduresFuture,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color.fromARGB(255, 44, 194, 49),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cargando procedimientos...',
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
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
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
                                  'Error al cargar procedimientos',
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
                                const SizedBox(height: 16),
                                Text(
                                  'Arrastra hacia abajo para reintentar',
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

                    final procs = snap.data!;
                    if (procs.isEmpty) {
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
                                  'No hay procedimientos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aún no hay procedimientos asignados',
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
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: procs.length,
                        itemBuilder: (context, i) {
                          final p = procs[i];
                          final status = _getProcedureStatus(p);
                          final statusColor = _getStatusColor(status);
                          final statusIcon = _getStatusIcon(status);
                          final statusText = _getStatusText(status);

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header del procedimiento
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            p.description ?? 'Sin descripción',
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
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Información adicional del procedimiento
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.repeat,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Recurrencia: ${p.recurrenceType}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Intervalo: ${p.interval}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.numbers,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Total ocurrencias: ${p.totalOccurrences}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Información del estado
                                    Row(
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getStatusDescription(status, p),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Botones de acción según el estado
                                    const SizedBox(height: 16),
                                    if (status == ProcedureStatus.pending) ...[
                                      // Botón Aceptar para procedimientos pendientes
                                      Container(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _onAcceptPressed(p.id),
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Aceptar Procedimiento',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                    ] else if (status ==
                                        ProcedureStatus.accepted) ...[
                                      // Botón Iniciar para procedimientos aceptados
                                      Container(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _onStartPressed(p.id),
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Iniciar Procedimiento',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
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
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      // Sin botón para procedimientos ya iniciados
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Procedimiento Iniciado',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
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

// Enum para los estados del procedimiento
enum ProcedureStatus {
  pending, // Pendiente de aceptación
  accepted, // Aceptado, listo para iniciar
  started, // Ya iniciado/completado
}
