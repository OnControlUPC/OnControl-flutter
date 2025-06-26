/// Representa un enlace (solicitud) entre doctor y paciente.
class DoctorPatientLink {
  final String externalId;
  final String doctorUuid;
  final String patientUuid;
  final String doctorFullName;
  final String patientFullName;
  final String status;
  final DateTime createdAt;
  final DateTime? disabledAt;

  const DoctorPatientLink({
    required this.externalId,
    required this.doctorUuid,
    required this.patientUuid,
    required this.doctorFullName,
    required this.patientFullName,
    required this.status,
    required this.createdAt,
    this.disabledAt,
  });

  factory DoctorPatientLink.fromJson(Map<String, dynamic> json) {
    return DoctorPatientLink(
      externalId: json['externalId'] as String,
      doctorUuid: json['doctorUuid'] as String,
      patientUuid: json['patientUuid'] as String,
      doctorFullName: json['doctorFullName'] as String,
      patientFullName: json['patientFullName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      disabledAt: json['disabledAt'] != null
          ? DateTime.parse(json['disabledAt'] as String)
          : null,
    );
  }
}
