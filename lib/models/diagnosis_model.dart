class DiagnosisResult {
  final String diseaseName;
  final String severity;
  final String cause;
  final String treatment;
  final String prevention;
  final String weatherAdvice;
  final DateTime timestamp;

  DiagnosisResult({
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
      'diseaseName': diseaseName,
      'severity': severity,
      'cause': cause,
      'treatment': treatment,
      'prevention': prevention,
      'weatherAdvice': weatherAdvice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
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

class WeatherData {
  final double temperature;
  final int humidity;
  final String condition;
  final String description;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      humidity: json['main']['humidity'],
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
    );
  }
}

