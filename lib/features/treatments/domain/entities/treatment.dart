/// Entidad Treatment que representa un tratamiento asignado a un paciente.
class Treatment {
  final int id;
  final String externalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String doctorProfileUuid;
  final String patientProfileUuid;

  Treatment({
    required this.id,
    required this.externalId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.doctorProfileUuid,
    required this.patientProfileUuid,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    return Treatment(
      id: json['id'] as int,
      externalId: json['externalId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: (json['title'] as Map<String, dynamic>)['value'] as String,
      startDate: DateTime.parse(period['startDate'] as String),
      endDate: DateTime.parse(period['endDate'] as String),
      status: json['status'] as String,
      doctorProfileUuid: json['doctorProfileUuid'] as String,
      patientProfileUuid: json['patientProfileUuid'] as String,
    );
  }
}
