
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

  Future<void> _accept(String externalId) async {
    setState(() => _loading = true);
    try {
      await _repo.acceptLink(externalId);
      print('✅ [PendingRequests] aceptado $externalId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud aceptada')),
      );
      await _loadLinks();
    } catch (e) {
      print('❌ [PendingRequests] accept error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes Pendientes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _links.isEmpty
                  ? const Center(child: Text('No hay solicitudes'))
                  : ListView.builder(
                      itemCount: _links.length,
                      itemBuilder: (context, i) {
                        final link = _links[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(link.doctorFullName),
                            subtitle: Text(
                                'Solicitada el ${link.createdAt.toLocal()}'),
                            trailing: ElevatedButton(
                              onPressed: () => _accept(link.externalId),
                              child: const Text('Aceptar'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
