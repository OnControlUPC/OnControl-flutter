class Appointment {
  final int id;
  final DateTime scheduledAt;
  final String status;
  final String locationName;
  final String locationMapsUrl;
  final String meetingUrl;
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

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int,
        scheduledAt: DateTime.parse(json['scheduledAt']),
        status: json['status'],
        locationName: json['locationName'],
        locationMapsUrl: json['locationMapsUrl'],
        meetingUrl: json['meetingUrl'],
        patientProfileUuid: json['patientProfileUuid'],
        doctorProfileUuid: json['doctorProfileUuid'],
      );
}
