import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/symptom.dart';
import '../../domain/entities/symptom_log.dart';

/// Fuente de datos HTTP para tratamientos.
abstract class TreatmentRemoteDataSource {
  Future<List<Treatment>> fetchTreatments(String patientUuid);
  Future<void> postSymptom(String treatmentExternalId, Symptom symptom);

  /// Obtiene el historial de síntomas para el paciente en un rango UTC.
  Future<List<SymptomLog>> fetchPatientSymptomLogs({
    required String patientUuid,
    required DateTime from,
    required DateTime to,
  });
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final http.Client _client;

  TreatmentRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? createHttpClient();

  @override
  Future<List<Treatment>> fetchTreatments(String patientUuid) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.TREATMENTS_URL}/$patientUuid');
    debugPrint('🔵 [TreatmentDS] GET Treatments → $uri');
    final resp = await _client.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('⬅️ status: ${resp.statusCode}');
    debugPrint('⬅️ body:   ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('fetchTreatments failed: ${resp.statusCode}');
    }
    final list = json.decode(resp.body) as List<dynamic>;
    return list.map((e) => Treatment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> postSymptom(String treatmentExternalId, Symptom symptom) async {
    // Usa SYMPTOMS_URL, que apunta a "/api/v1/treatments"
    final uri = Uri.parse('${Config.BASE_URL}${Config.SYMPTOMS_URL}/$treatmentExternalId/symptoms');
    final body = jsonEncode(symptom.toJson());
    debugPrint('🔵 [TreatmentDS] POST Symptom → $uri');
    debugPrint('▶️ payload:   $body');
    final resp = await _client.post(uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('⬅️ status: ${resp.statusCode}');
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('postSymptom failed: ${resp.statusCode}');
    }
  }

  @override
  Future<List<SymptomLog>> fetchPatientSymptomLogs({
    required String patientUuid,
    required DateTime from,
    required DateTime to,
  }) async {
    // Imprime rangos en UTC
    debugPrint(
      '🕗 [TreatmentDS] fetchPatientSymptomLogs range → '
      'from: ${from.toUtc().toIso8601String()} – to: ${to.toUtc().toIso8601String()}',
    );
    final uri = Uri.parse('${Config.BASE_URL}/api/v1/treatments/symptom-logs/patient')
        .replace(queryParameters: {
      'patientUuid': patientUuid,
      'from': from.toUtc().toIso8601String(),
      'to':   to.toUtc().toIso8601String(),
    });
    debugPrint('🔵 [TreatmentDS] GET SymptomLogs → $uri');
    final resp = await _client.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('⬅️ status: ${resp.statusCode}');
    debugPrint('⬅️ body:   ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('fetchPatientSymptomLogs failed: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as List<dynamic>;
    return data.map((e) => SymptomLog.fromJson(e as Map<String, dynamic>)).toList();
  }
}
