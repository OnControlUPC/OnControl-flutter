// lib/features/treatments/domain/entities/predicted_execution.dart

class PredictedExecution {
  final String procedureName;
  final DateTime scheduledAt;
  final String status;

  PredictedExecution({
    required this.procedureName,
    required this.scheduledAt,
    required this.status,
  });

  factory PredictedExecution.fromJson(Map<String, dynamic> json) =>
      PredictedExecution(
        procedureName: json['procedureName'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        status: json['status'] as String,
      );
}
