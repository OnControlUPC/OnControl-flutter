import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/doctor.dart';

/// Fuente de datos HTTP para usuarios que sean doctores (ROLE_ADMIN).
abstract class DoctorRemoteDataSource {
  Future<List<Doctor>> fetchAllDoctors(String token);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final http.Client client;

  DoctorRemoteDataSourceImpl({http.Client? client})
      : client = client ?? createHttpClient();

  @override
  Future<List<Doctor>> fetchAllDoctors(String token) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.GET_USERS_URL}');
    print('🔵 [DoctorDS] GET → $uri');
    final resp = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀️ Status: ${resp.statusCode}');
    print('◀️ Body:   ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception('Error fetchAllDoctors: ${resp.statusCode}');
    }

    final decoded = json.decode(resp.body);
    late final List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map && decoded.containsKey('data')) {
      rawList = decoded['data'] as List<dynamic>;
    } else {
      throw Exception('Formato inesperado en fetchAllDoctors');
    }

    // Solo ROLE_ADMIN
    return rawList
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .where((d) => d.role == 'ROLE_ADMIN')
        .toList();
  }
}
