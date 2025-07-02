import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/treatment.dart';

/// Fuente de datos HTTP para tratamientos.
abstract class TreatmentRemoteDataSource {
  /// Obtiene la lista de tratamientos del paciente.
  Future<List<Treatment>> fetchTreatments(String patientUuid);
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final http.Client _client;

  TreatmentRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? createHttpClient();

  @override
  Future<List<Treatment>> fetchTreatments(String patientUuid) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.TREATMENTS_URL}/$patientUuid',
    );
    debugPrint('🔵 [TreatmentDS] GET Treatments → $uri');

    final resp = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    debugPrint('⬅️ [TreatmentDS] status: ${resp.statusCode}');
    debugPrint('⬅️ [TreatmentDS] body:   ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception('fetchTreatments failed: ${resp.statusCode}');
    }

    final list = json.decode(resp.body) as List<dynamic>;
    return list
        .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
