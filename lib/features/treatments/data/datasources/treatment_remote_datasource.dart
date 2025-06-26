import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/treatment.dart';

/// Fuente remota HTTP para tratamientos.
abstract class TreatmentRemoteDataSource {
  Future<List<Treatment>> fetchTreatments(String patientUuid, String token);
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final http.Client client;

  TreatmentRemoteDataSourceImpl({http.Client? client})
      : client = client ?? createHttpClient();

  @override
  Future<List<Treatment>> fetchTreatments(String patientUuid, String token) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.TREATMENTS_URL}/$patientUuid',
    );
    print('🔵 [TreatmentDS] GET → $uri');
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
      throw Exception('Failed fetchTreatments: ${resp.statusCode}');
    }
    final list = json.decode(resp.body) as List<dynamic>;
    return list
        .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
