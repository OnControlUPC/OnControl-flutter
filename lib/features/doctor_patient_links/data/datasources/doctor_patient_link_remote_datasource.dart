// lib/features/doctor_patient_links/data/datasources/doctor_patient_link_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/doctor_patient_link.dart';

/// Fuente de datos HTTP para doctor-patient links.
abstract class DoctorPatientLinkRemoteDataSource {
  Future<String> fetchPatientUuid(String token);
  Future<List<DoctorPatientLink>> fetchPendingLinks(String patientUuid, String token);

  /// Acepta la solicitud identificada por externalId.
  /// Considera 200 o 204 como éxito.
  Future<void> patchAcceptLink(String externalId, String token);
}

class DoctorPatientLinkRemoteDataSourceImpl
    implements DoctorPatientLinkRemoteDataSource {
  final http.Client client;

  DoctorPatientLinkRemoteDataSourceImpl({http.Client? client})
      : client = client ?? createHttpClient();

  @override
  Future<String> fetchPatientUuid(String token) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.PATIENT_UUID_URL}');
    print('🔵 [LinkDS] GET Patient UUID → $uri');
    final resp = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀️ Status UUID: ${resp.statusCode}');
    print('◀️ Body   UUID: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Failed fetchPatientUuid: ${resp.statusCode}');
    }
    final map = json.decode(resp.body) as Map<String, dynamic>;
    return map['uuid'] as String;
  }

  @override
  Future<List<DoctorPatientLink>> fetchPendingLinks(
      String patientUuid, String token) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.PENDING_LINKS_URL}/$patientUuid/pending',
    );
    print('🔵 [LinkDS] GET Pending → $uri');
    final resp = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀️ Status Pending: ${resp.statusCode}');
    print('◀️ Body   Pending: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('Failed fetchPendingLinks: ${resp.statusCode}');
    }
    final list = json.decode(resp.body) as List<dynamic>;
    return list
        .map((e) => DoctorPatientLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> patchAcceptLink(String externalId, String token) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.ACCEPT_LINK_URL}/$externalId/accept',
    );
    print('🔵 [LinkDS] PATCH Accept → $uri');
    final resp = await client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀️ Status Accept: ${resp.statusCode}');
    // 200 OK o 204 No Content se consideran éxito
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed patchAcceptLink: ${resp.statusCode}');
    }
  }
}
