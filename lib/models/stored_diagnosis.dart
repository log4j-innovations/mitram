class StoredDiagnosis {
  final String userId;
  final String diagnosisId;
  final String imageUrl; // Firebase Storage path
  final String diseaseName;
  final String severity;
  final String cause;
  final String treatment;
  final String prevention;
  final String weatherAdvice;
  final DateTime timestamp;

  StoredDiagnosis({
    required this.userId,
    required this.diagnosisId,
    required this.imageUrl,
    required this.diseaseName,
    required this.severity,
    required this.cause,
    required this.treatment,
    required this.prevention,
    required this.weatherAdvice,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'diagnosisId': diagnosisId,
      'imageUrl': imageUrl,
      'diseaseName': diseaseName,
      'severity': severity,
      'cause': cause,
      'treatment': treatment,
      'prevention': prevention,
      'weatherAdvice': weatherAdvice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StoredDiagnosis.fromJson(Map<String, dynamic> json) {
    return StoredDiagnosis(
      userId: json['userId'] ?? '',
      diagnosisId: json['diagnosisId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      diseaseName: json['diseaseName'] ?? '',
      severity: json['severity'] ?? '',
      cause: json['cause'] ?? '',
      treatment: json['treatment'] ?? '',
      prevention: json['prevention'] ?? '',
      weatherAdvice: json['weatherAdvice'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}