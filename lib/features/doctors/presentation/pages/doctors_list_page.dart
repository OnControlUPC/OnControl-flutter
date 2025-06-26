import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/doctor_remote_datasource.dart';
import '../../data/repositories/doctor_repository_impl.dart';
import '../../domain/entities/doctor.dart';

class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({Key? key}) : super(key: key);

  @override
  _DoctorsListPageState createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  final _storage = const FlutterSecureStorage();
  late final DoctorRepositoryImpl _repo;
  List<Doctor> _doctors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = DoctorRepositoryImpl(
      remote: DoctorRemoteDataSourceImpl(),
      secureStorage: _storage,
    );
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final token = await _storage.read(key: 'token') ?? '';
    print('▶️ [DoctorsListPage] token=$token');
    if (token.isEmpty) {
      setState(() {
        _error = 'Sesión no iniciada';
        _loading = false;
      });
      return;
    }
    try {
      final list = await _repo.getAllDoctors(token);
      print('🔔 [DoctorsListPage] encontrados ${list.length} doctores');
      setState(() {
        _doctors = list;
        _loading = false;
      });
    } catch (e) {
      print('❌ [DoctorsListPage] error: $e');
      setState(() {
        _error = 'Error al cargar doctores';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_doctors.isEmpty) {
      return const Center(child: Text('No hay doctores disponibles'));
    }
    return ListView.builder(
      itemCount: _doctors.length,
      itemBuilder: (context, i) {
        final d = _doctors[i];
        return ListTile(
          leading: const Icon(Icons.medical_services),
          title: Text(d.username),
        );
      },
    );
  }
}
