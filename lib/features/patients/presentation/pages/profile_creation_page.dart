import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final _photoUrlController = TextEditingController();
  String? _gender;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _imageLoadError = false;
  int _step = 0;
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

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _submitProfile() async {
    print(
      '▶️ [ProfilePage] _submitProfile invoked for userId=${widget.userId}',
    );
    if (!_formKey.currentState!.validate()) {
      print('‼️ [ProfilePage] Formulario inválido');
      return;
    }

    setState(() => _isLoading = true);

    final token =
        widget.token ?? await const FlutterSecureStorage().read(key: 'token');
    if (token == null) {
      print('⚠️ [ProfilePage] Token no encontrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error: token no disponible'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      photoUrl: _photoUrlController.text.trim().isEmpty
          ? ''
          : _photoUrlController.text.trim(),
    );

    try {
      await _repository.createProfile(profile);
      print('✅ [ProfilePage] Perfil creado exitosamente');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Perfil creado exitosamente'),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 44, 194, 49),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } catch (e) {
      print('❌ [ProfilePage] Error al crear perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al crear perfil: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (picked == null) return;

      final token =
          widget.token ?? await const FlutterSecureStorage().read(key: 'token');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Error: token no disponible'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingPhoto = true);

      try {
        final url = await _repository.uploadProfilePhoto(
          File(picked.path),
          token,
        );
        if (mounted) {
          setState(() {
            _photoUrlController.text = url;
            _imageLoadError = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Foto subida correctamente'),
                ],
              ),
              backgroundColor: Color.fromARGB(255, 44, 194, 49),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('❌ Error uploading photo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error al subir foto: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al seleccionar imagen: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _goToPhotoStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  void _goBackToInfoStep() {
    setState(() => _step = 0);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color.fromARGB(255, 44, 194, 49),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          // Step 1
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 44, 194, 49),
                  Color.fromARGB(255, 105, 96, 197),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _step >= 1
                      ? [
                          const Color.fromARGB(255, 44, 194, 49),
                          const Color.fromARGB(255, 105, 96, 197),
                        ]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                ),
              ),
            ),
          ),
          // Step 2
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: _step >= 1
                  ? const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 44, 194, 49),
                        Color.fromARGB(255, 105, 96, 197),
                      ],
                    )
                  : null,
              color: _step < 1 ? Colors.grey.shade300 : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '2',
                style: TextStyle(
                  color: _step >= 1 ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Email Field (disabled)
          TextFormField(
            initialValue: widget.email,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(0xFF9CA3AF),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
            ),
            enabled: false,
          ),
          const SizedBox(height: 20),
          // First Name Field
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nombre requerido' : null,
          ),
          const SizedBox(height: 20),
          // Last Name Field
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Apellidos',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Apellidos requeridos' : null,
          ),
          const SizedBox(height: 20),
          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.isEmpty ? 'Teléfono requerido' : null,
          ),
          const SizedBox(height: 20),
          // Birth Date Field
          TextFormField(
            controller: _birthDateController,
            decoration: InputDecoration(
              labelText: 'Fecha de nacimiento',
              hintText: 'Toca para seleccionar fecha',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.date_range,
                  color: Color.fromARGB(255, 44, 194, 49),
                ),
                onPressed: _selectDate,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            readOnly: true,
            onTap: _selectDate,
            validator: (v) =>
                v == null || v.isEmpty ? 'Fecha de nacimiento requerida' : null,
          ),
          const SizedBox(height: 20),
          // Gender Dropdown
          DropdownButtonFormField<String>(
            value: _gender,
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Femenino')),
            ],
            onChanged: (v) => setState(() => _gender = v),
            decoration: InputDecoration(
              labelText: 'Género',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.wc_outlined,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            validator: (v) => v == null ? 'Género requerido' : null,
          ),
          const SizedBox(height: 32),
          // Next Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 44, 194, 49),
                  Color.fromARGB(255, 105, 96, 197),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    44,
                    194,
                    49,
                  ).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _goToPhotoStep,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                'Siguiente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Photo Preview
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _photoUrlController.text.isNotEmpty && !_imageLoadError
                    ? const Color.fromARGB(255, 44, 194, 49)
                    : Colors.grey.shade300,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _photoUrlController.text.isNotEmpty && !_imageLoadError
                  ? Image.network(
                      _photoUrlController.text,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color.fromARGB(255, 44, 194, 49),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _imageLoadError = true);
                          }
                        });
                        return Icon(
                          Icons.error,
                          size: 40,
                          color: Colors.red.shade400,
                        );
                      },
                    )
                  : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 20),

          // Photo URL Field
          TextFormField(
            controller: _photoUrlController,
            decoration: InputDecoration(
              labelText: 'URL de foto (opcional)',
              hintText: 'https://ejemplo.com/foto.jpg',
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.link,
                color: Color.fromARGB(255, 44, 194, 49),
              ),
              suffixIcon: _photoUrlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _photoUrlController.clear();
                          _imageLoadError = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 194, 49),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            onChanged: (value) {
              setState(() {
                _imageLoadError = false;
              });
            },
            validator: (value) {
              if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
                return 'URL no válida';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 20),

          // Upload Photo Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 44, 194, 49),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isUploadingPhoto
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 44, 194, 49),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _pickAndUploadImage,
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      color: Color.fromARGB(255, 44, 194, 49),
                    ),
                    label: const Text(
                      'Seleccionar desde galería',
                      style: TextStyle(
                        color: Color.fromARGB(255, 44, 194, 49),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // Create Account Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 44, 194, 49),
                  Color.fromARGB(255, 105, 96, 197),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    44,
                    194,
                    49,
                  ).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _submitProfile,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // Back Button
          TextButton.icon(
            onPressed: _goBackToInfoStep,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
            label: const Text(
              'Volver atrás',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Header Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 44, 194, 49),
                        Color.fromARGB(255, 105, 96, 197),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          44,
                          194,
                          49,
                        ).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Crear Perfil',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 0
                      ? 'Completa tu información personal'
                      : 'Agrega tu foto de perfil',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),

                // Step Indicator
                _buildStepIndicator(),

                // Form Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          44,
                          194,
                          49,
                        ).withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: IndexedStack(
                      index: _step,
                      children: [_buildInfoStep(), _buildPhotoStep()],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
