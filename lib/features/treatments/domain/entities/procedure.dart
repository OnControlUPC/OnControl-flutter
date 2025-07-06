// lib/features/treatments/domain/entities/procedure.dart

class Procedure {
  final int id;
  final String externalId;
  final String description;
  final String status;
  final String recurrenceType;
  final int interval;
  final int totalOccurrences;
  final DateTime untilDate;
  final DateTime startDateTime;

  Procedure({
    required this.id,
    required this.externalId,
    required this.description,
    required this.status,
    required this.recurrenceType,
    required this.interval,
    required this.totalOccurrences,
    required this.untilDate,
    required this.startDateTime,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) => Procedure(
        id: json['id'] as int,
        externalId: json['external_id'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        recurrenceType: json['recurrenceType'] as String,
        interval: json['interval'] as int,
        totalOccurrences: json['totalOccurrences'] as int,
        untilDate: DateTime.parse(json['untilDate'] as String).toLocal(),
        startDateTime:
            DateTime.parse(json['startDateTime'] as String).toLocal(),
      );
}
