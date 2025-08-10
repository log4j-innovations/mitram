class DiagnosisResult {
  final String diseaseName;
  final int severity;
  final String simpleExplanation;
  final String causes;
  final String immediateTreatment;
  final String preventionTips;
  final String estimatedCost;
  final int confidenceScore;
  final String location;
  final String weatherCondition;
  final DateTime timestamp;

  DiagnosisResult({
    required this.diseaseName,
    required this.severity,
    required this.simpleExplanation,
    required this.causes,
    required this.immediateTreatment,
    required this.preventionTips,
    required this.estimatedCost,
    required this.confidenceScore,
    required this.location,
    required this.weatherCondition,
    required this.timestamp,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json, String location, String weather) {
    return DiagnosisResult(
      diseaseName: json['disease_name'] ?? 'Unknown Issue',
      severity: json['severity'] ?? 1,
      simpleExplanation: json['simple_explanation'] ?? '',
      causes: json['causes'] ?? '',
      immediateTreatment: json['immediate_treatment'] ?? '',
      preventionTips: json['prevention_tips'] ?? '',
      estimatedCost: json['estimated_cost'] ?? '',
      confidenceScore: json['confidence_score'] ?? 0,
      location: location,
      weatherCondition: weather,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_name': diseaseName,
      'severity': severity,
      'simple_explanation': simpleExplanation,
      'causes': causes,
      'immediate_treatment': immediateTreatment,
      'prevention_tips': preventionTips,
      'estimated_cost': estimatedCost,
      'confidence_score': confidenceScore,
      'location': location,
      'weather_condition': weatherCondition,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
