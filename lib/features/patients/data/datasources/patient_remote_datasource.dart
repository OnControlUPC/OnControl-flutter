import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';
import '../../../patients/domain/entities/patient_profile.dart';

abstract class PatientRemoteDataSource {
  Future<void> createProfile(
    PatientProfile profile
  );
    /// Sube una imagen de perfil y devuelve la URL generada
  Future<String> uploadProfilePhoto(
    File file,
    String token,
  );
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final http.Client client;

  PatientRemoteDataSourceImpl(this.client);

  @override
  Future<void> createProfile(
    PatientProfile profile
  ) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.CREATE_PROFILE_URL}');
    final body = jsonEncode({
      'userId': profile.userId,
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'email': profile.email,
      'phoneNumber': profile.phoneNumber,
      'birthDate': profile.birthDate,
      'gender': profile.gender,
      'photoUrl': profile.photoUrl,
    });
    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json'
      },
      body: body,
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear perfil: \${response.statusCode}');
    }
  }
    @override
  Future<String> uploadProfilePhoto(
    File file,
    String token,
  ) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.UPLOAD_PHOTO_URL}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await client.send(request);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al subir foto: ${response.statusCode}');
    }
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}

