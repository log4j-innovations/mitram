//lib/screens/diagnose_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Re-add for camera permission
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';

import '../utils/api_keys.dart';

class DiagnoseScreen extends StatefulWidget {
  static const routeName = '/diagnose'; // Add routeName
  const DiagnoseScreen({super.key});

  @override
  _DiagnoseScreenState createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  DiagnosisResult? _diagnosisResult;
  
  late GenerativeModel _model;
  
  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }
  
  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: geminiApiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 600;
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      return SingleChildScrollView(
        child: _buildResponsiveBody(
            context, constraints, isTablet, isLandscape),
      );
    });
  }

  Widget _buildResponsiveBody(BuildContext context, BoxConstraints constraints, bool isTablet, bool isLandscape) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          color: const Color(0xFFA8D5A8),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.green.shade700,
                size: screenWidth * 0.08,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'AI-Powered Crop Diagnosis',
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                'Take a photo of your crop to get instant diagnosis',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Camera Section
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              _buildCameraSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.02),
              

              
              // Analysis Result
              if (_diagnosisResult != null)
                _buildDiagnosisCard(screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSection(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // Image Display
            Container(
              width: double.infinity,
              height: screenHeight * 0.3,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: screenWidth * 0.12,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Take or Select Photo',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Camera Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Analyze Button
            if (_selectedImage != null)
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  child: _isAnalyzing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'Analyzing...',
                            style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Analyze Crop',
                        style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenHeight * 0.06,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.green.shade700,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildDiagnosisCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: Colors.red.shade600,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Diagnosis Result',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            
            // Disease Name
            _buildResultSection('Disease Identified:', _diagnosisResult!.diseaseName, Colors.red.shade600, screenWidth),
            SizedBox(height: screenHeight * 0.015),
            
            // Severity
            _buildResultSection('Severity Level:', _diagnosisResult!.severity, _getSeverityColor(_diagnosisResult!.severity), screenWidth),
            SizedBox(height: screenHeight * 0.015),
            
            // Cause
            Text(
              'Why this happened:',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              _diagnosisResult!.cause,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            
            // Treatment
            Text(
              'Treatment Solution:',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              _diagnosisResult!.treatment,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            
            // Prevention
            Text(
              'How to prevent in future:',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              _diagnosisResult!.prevention,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, String value, Color color, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'high':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }



  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          _showErrorSnackBar('Camera permission is required');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _diagnosisResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }



  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    if (mounted) {
      setState(() {
        _isAnalyzing = true;
      });
    }

    try {
      // Get Gemini AI diagnosis result
      final imageBytes = await _selectedImage!.readAsBytes();
      final prompt = _createDiagnosisPrompt();
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await _model.generateContent(content);
      final diagnosis = _parseDiagnosisResponse(response.text ?? '');

      if (mounted) {
        setState(() {
          _diagnosisResult = diagnosis;
        });
      }

    } catch (e) {
      debugPrint('Failed to analyze image: $e');
      _showErrorSnackBar('Failed to analyze image. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String _createDiagnosisPrompt() {
    return '''
You are an expert agricultural pathologist helping Indian farmers. Analyze this crop image and provide a detailed diagnosis in simple language that a farmer can easily understand.
 
Please provide your response in the following JSON format:
{
  "disease_name": "Name of the disease or condition",
  "severity": "Low/Medium/High",
  "cause": "Simple explanation of why this problem occurred (2-3 sentences)",
  "treatment": "Step-by-step treatment solution in simple language (3-4 steps)",
  "prevention": "How to prevent this problem in future (2-3 practical tips)",
  "weather_advice": "Specific advice based on current weather conditions"
}
 
Focus on:
1. Simple Hindi-English mixed language that Indian farmers understand
2. Practical, affordable solutions available in local markets
3. Consider the current weather conditions in your advice
4. Preventive measures that are easy to implement
5. Timing recommendations for treatment
''';
  }

  DiagnosisResult _parseDiagnosisResponse(String response) {
    try {
      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json').last.split('```').first;
      }
      
      final jsonData = json.decode(jsonStr);
      
      return DiagnosisResult(
        diseaseName: jsonData['disease_name'] ?? 'Unknown Disease',
        severity: jsonData['severity'] ?? 'Medium',
        cause: jsonData['cause'] ?? 'Cause could not be determined',
        treatment: jsonData['treatment'] ?? 'Consult local agriculture expert',
        prevention: jsonData['prevention'] ?? 'Follow good farming practices',
        weatherAdvice: jsonData['weather_advice'] ?? 'Monitor weather conditions',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return DiagnosisResult(
        diseaseName: 'Crop Disease Detected',
        severity: 'Medium',
        cause: 'Disease analysis completed. Please consult with local agriculture expert for detailed diagnosis.',
        treatment: response.length > 200 ? '${response.substring(0, 200)}...' : response,
        prevention: 'Follow proper crop management practices and maintain field hygiene.',
        weatherAdvice: 'Monitor weather conditions regularly',
        timestamp: DateTime.now(),
      );
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
}

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
}


