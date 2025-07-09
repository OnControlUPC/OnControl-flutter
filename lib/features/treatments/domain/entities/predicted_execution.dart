// lib/features/treatments/domain/entities/predicted_execution.dart

class PredictedExecution {
  final int? id;
  final String procedureName;
  final DateTime scheduledAt;
  final String status;
  final String treatmentExternalId;

  PredictedExecution({
    required this.id,
    required this.procedureName,
    required this.scheduledAt,
    required this.status,
    required this.treatmentExternalId,
  });
  factory PredictedExecution.fromJson(
    Map<String, dynamic> json,
    String treatmentExternalId,
  ) {

     // Fuerzamos que la cadena se trate como UTC,
     // luego la convertimos a hora local (UTC–5)
     final dtUtc = DateTime.parse('${json['scheduledAt']}Z');
     final dtLocal = dtUtc.toLocal();

    return PredictedExecution(
      id: json['id'] as int?,
      procedureName: json['procedureName'] as String,
      scheduledAt: dtLocal,
      status: json['status'] as String,
      treatmentExternalId: treatmentExternalId,
    );
  }
}
