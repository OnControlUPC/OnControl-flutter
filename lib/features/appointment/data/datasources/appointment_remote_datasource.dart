// lib/features/appointments/data/datasources/appointment_remote_datasource.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/appointment.dart';

/// Solo calendario de citas para paciente.
/// Endpoint: GET /api/v1/appointments/calendar
///           DELETE /api/v1/appointments/{id}/delete
abstract class AppointmentRemoteDataSource {
  Future<List<Appointment>> fetchAppointments();

  /// Llama a DELETE /api/v1/appointments/{id}/delete
  Future<void> deleteAppointment(int id);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final http.Client client;
  final _storage = const FlutterSecureStorage();

  AppointmentRemoteDataSourceImpl({http.Client? client})
      : client = client ?? createHttpClient();

  @override
  Future<List<Appointment>> fetchAppointments() async {
    final uri = Uri.parse('${Config.BASE_URL}/api/v1/appointments/calendar');
    debugPrint('🔵 [AppointmentDS] GET Calendar → $uri');

    final response = await client.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    debugPrint('⬅️ [AppointmentDS] status → ${response.statusCode}');
    debugPrint('⬅️ [AppointmentDS] body   → ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch appointments calendar: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteAppointment(int id) async {
    final token = await _storage.read(key: 'token');
    final uri = Uri.parse('${Config.BASE_URL}/api/v1/appointments/$id/delete');
    debugPrint('🔴 [AppointmentDS] DELETE → $uri');
    final response = await client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    debugPrint('⬅️ [AppointmentDS] DELETE status → ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete appointment: ${response.statusCode}');
    }
  }
}
