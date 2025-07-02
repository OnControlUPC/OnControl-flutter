class Period {
  final DateTime startDate;
  final DateTime endDate;

  Period({required this.startDate, required this.endDate});

  factory Period.fromJson(Map<String, dynamic> json) => Period(
        startDate: DateTime.parse(json['period']['startDate'] as String),
        endDate: DateTime.parse(json['period']['endDate'] as String),
      );
}

class TitleValue {
  final String value;

  TitleValue({required this.value});

  factory TitleValue.fromJson(Map<String, dynamic> json) =>
      TitleValue(value: json['title']['value'] as String);
}

class Treatment {
  final int id;
  final String externalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TitleValue title;
  final Period period;
  final String status;
  final String doctorProfileUuid;
  final String patientProfileUuid;

  Treatment({
    required this.id,
    required this.externalId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.period,
    required this.status,
    required this.doctorProfileUuid,
    required this.patientProfileUuid,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
        id: json['id'] as int,
        externalId: json['externalId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        title: TitleValue.fromJson(json),
        period: Period.fromJson(json),
        status: json['status'] as String,
        doctorProfileUuid: json['doctorProfileUuid'] as String,
        patientProfileUuid: json['patientProfileUuid'] as String,
      );
}
