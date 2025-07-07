// lib/features/appointments/domain/entities/appointment.dart

class Appointment {
  final int id;
  final DateTime scheduledAt;
  final String status;
  final String locationName;
  final String? locationMapsUrl;
  final String? meetingUrl;
  final String patientProfileUuid;
  final String doctorProfileUuid;

  Appointment({
    required this.id,
    required this.scheduledAt,
    required this.status,
    required this.locationName,
    required this.locationMapsUrl,
    required this.meetingUrl,
    required this.patientProfileUuid,
    required this.doctorProfileUuid,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Algunos campos vienen como literal "null" (String), o null real:
    String parseString(dynamic raw) {
      if (raw == null) return '';
      final s = raw.toString();
      return (s.toLowerCase() == 'null') ? '' : s;
    }

    String? parseNullableString(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      return (s.toLowerCase() == 'null') ? null : s;
    }

    return Appointment(
      id: json['id'] as int,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      status: json['status'] as String,
      locationName: parseString(json['locationName']),
      locationMapsUrl: parseNullableString(json['locationMapsUrl']),
      meetingUrl: parseNullableString(json['meetingUrl']),
      patientProfileUuid: json['patientProfileUuid'] as String,
      doctorProfileUuid: json['doctorProfileUuid'] as String,
    );
  }
}
