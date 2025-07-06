import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/doctor_patient_link.dart';

/// Fuente de datos HTTP para doctor-patient links.
abstract class DoctorPatientLinkRemoteDataSource {
  /// Solicitudes pendientes para este paciente
  Future<List<DoctorPatientLink>> fetchPendingLinks(String patientUuid);

  /// Acepta la solicitud identificada por externalId.
  Future<void> patchAcceptLink(String externalId);

  Future<void> patchActivateLink(String externalId);

  /// Relaciones activas (ya aceptadas) para este paciente
  Future<List<DoctorPatientLink>> fetchActiveLinks(String patientUuid);
}

class DoctorPatientLinkRemoteDataSourceImpl
    implements DoctorPatientLinkRemoteDataSource {
  final http.Client client;

  DoctorPatientLinkRemoteDataSourceImpl({http.Client? client})
      : client = client ?? createHttpClient();

  @override
  Future<List<DoctorPatientLink>> fetchPendingLinks(String patientUuid) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.PENDING_LINKS_URL}/$patientUuid/pending',
    );
    debugPrint('🔵 [LinkDS] GET Pending → $uri');
    final resp = await client.get(uri, headers: {
      'Content-Type': 'application/json',
    });
    debugPrint('⬅️ [LinkDS] Pending status: ${resp.statusCode}');
    debugPrint('⬅️ [LinkDS] Pending body:   ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('fetchPendingLinks failed: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as List<dynamic>;
    return data
        .map((e) => DoctorPatientLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> patchAcceptLink(String externalId) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.ACCEPT_LINK_URL}/$externalId/accept',
    );
    debugPrint('🔵 [LinkDS] PATCH Accept → $uri');
    final resp = await client.patch(uri, headers: {
      'Content-Type': 'application/json',
    });
    debugPrint('⬅️ [LinkDS] Accept status: ${resp.statusCode}');
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('patchAcceptLink failed: ${resp.statusCode}');
    }
  }

    @override
  Future<void> patchActivateLink(String externalId) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.ACCEPT_LINK_URL}/$externalId/activate',
    );
    debugPrint('🔵 [LinkDS] PATCH Accept → $uri');
    final resp = await client.patch(uri, headers: {
      'Content-Type': 'application/json',
    });
    debugPrint('⬅️ [LinkDS] Accept status: ${resp.statusCode}');
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('patchAcceptLink failed: ${resp.statusCode}');
    }
  }

  @override
  Future<List<DoctorPatientLink>> fetchActiveLinks(String patientUuid) async {
    final uri = Uri.parse(
      '${Config.BASE_URL}${Config.ACTIVE_LINKS_URL}/$patientUuid/active',
    );
    debugPrint('🔵 [LinkDS] GET Active → $uri');
    final resp = await client.get(uri, headers: {
      'Content-Type': 'application/json',
    });
    debugPrint('⬅️ [LinkDS] Active status: ${resp.statusCode}');
    debugPrint('⬅️ [LinkDS] Active body:   ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('fetchActiveLinks failed: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as List<dynamic>;
    return data
        .map((e) => DoctorPatientLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
