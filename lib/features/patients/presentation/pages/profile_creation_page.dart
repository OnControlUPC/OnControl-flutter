/// lib/features/patients/presentation/pages/profile_creation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/patient_profile.dart';
import '../../data/datasources/patient_remote_datasource.dart';
import '../../data/repositories/patient_repository_impl.dart';

class ProfileCreationPage extends StatefulWidget {
  final int userId;
  final String email;
  final String? token;

  const ProfileCreationPage({
    Key? key,
    required this.userId,
    required this.email,
    this.token,
  }) : super(key: key);

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _gender;
  final _photoUrlController = TextEditingController();
  bool _isLoading = false;

  late final PatientRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    final client = createHttpClient();
    _repository = PatientRepositoryImpl(
      remote: PatientRemoteDataSourceImpl(client),
    );
    print('▶️ [ProfilePage] init for userId=${widget.userId}');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    print('▶️ [ProfilePage] _submitProfile invoked for userId=${widget.userId}');
    if (!_formKey.currentState!.validate()) {
      print('‼️ [ProfilePage] Formulario inválido');
      return;
    }
    setState(() => _isLoading = true);

    final token = widget.token ??
        await const FlutterSecureStorage().read(key: 'token');
    if (token == null) {
      print('⚠️ [ProfilePage] Token no encontrado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: token no disponible')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final profile = PatientProfile(
      userId: widget.userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: widget.email,
      phoneNumber: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      gender: _gender!,
      photoUrl: _photoUrlController.text.trim(),
    );

    try {
      await _repository.createProfile(profile);
      print('✅ [ProfilePage] Perfil creado exitosamente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil creado exitosamente')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } catch (e) {
      print('❌ [ProfilePage] Error al crear perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear perfil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: widget.email,
                decoration: const InputDecoration(labelText: 'Correo'),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Femenino')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Género'),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(labelText: 'URL de foto'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitProfile,
                      child: const Text('Guardar perfil'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
