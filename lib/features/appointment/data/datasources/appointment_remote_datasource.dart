import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config.dart';
import '../../../../core/http_client.dart';
import '../../domain/entities/appointment.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<Appointment>> fetchAppointments();
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  AppointmentRemoteDataSourceImpl({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : client = client ?? createHttpClient(),
        storage = storage ?? const FlutterSecureStorage();

  @override
  Future<List<Appointment>> fetchAppointments() async {
    final patientUuid = await storage.read(key: 'patient_uuid');
    if (patientUuid == null) throw Exception('No patient_uuid found');

    final uri = Uri.parse(
      '${Config.BASE_URL}/api/v1/appointments/doctor/$patientUuid',
    );

    final response = await client.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch appointments');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => Appointment.fromJson(e)).toList();
  }
}
