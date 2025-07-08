// lib/features/treatments/domain/entities/procedure.dart

class Procedure {
  final int id;
  final String externalId;
  final String? description;
  final String status;
  final String recurrenceType;
  final int interval;
  final int totalOccurrences;
  final DateTime? untilDate;
  final DateTime? startDateTime;

  Procedure({
    required this.id,
    required this.externalId,
    this.description,
    required this.status,
    required this.recurrenceType,
    required this.interval,
    required this.totalOccurrences,
    this.untilDate,
    this.startDateTime,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    String? parseNullableString(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      return (s.toLowerCase() == 'null' || s.isEmpty) ? null : s;
    }
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      try {
        return DateTime.parse(raw as String).toUtc();
      } catch (_) {
        return null;
      }
    }

    return Procedure(
      id: json['id'] as int,
      externalId: json['external_id'] as String,
      description: parseNullableString(json['description']),
      status: json['status'] as String,
      recurrenceType: json['recurrenceType'] as String,
      interval: json['interval'] as int,
      totalOccurrences: json['totalOccurrences'] as int,
      untilDate: parseDate(json['untilDate']),
      startDateTime: parseDate(json['startDateTime']),
    );
  }
}
