import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';
import '../../../patients/domain/entities/patient_profile.dart';

abstract class PatientRemoteDataSource {
  Future<void> createProfile(
    PatientProfile profile,
    String token,
  );
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final http.Client client;

  PatientRemoteDataSourceImpl(this.client);

  @override
  Future<void> createProfile(
    PatientProfile profile,
    String token,
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
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear perfil: \${response.statusCode}');
    }
  }
}

