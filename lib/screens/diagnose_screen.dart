//lib/screens/diagnose_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Re-add for camera permission
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth
import '../services/database_service.dart';
import '../models/diagnosis_model.dart';
import '../models/stored_diagnosis.dart'; // Added for StoredDiagnosis
import '../services/location_service.dart'; // Import LocationService and UserLocation
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
  bool _isLoadingWeather = false;
  DiagnosisResult? _diagnosisResult;
  WeatherData? _weatherData;
  UserLocation? _currentLocation; // Changed from Position to UserLocation

  // At top of your state class
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final LocationService _locationService = LocationService(); // Instantiate LocationService
  
  late GenerativeModel _model;
  
  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _getCurrentLocation();
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
              
              // Weather Info
              if (_weatherData != null)
                _buildWeatherCard(screenWidth, screenHeight),
              
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

  Widget _buildWeatherCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 3,
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
                  Icons.wb_sunny,
                  color: Colors.orange.shade600,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Current Weather',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo('Temperature', '${_weatherData!.temperature.toStringAsFixed(1)}°C', screenWidth),
                _buildWeatherInfo('Humidity', '${_weatherData!.humidity}%', screenWidth),
                _buildWeatherInfo('Condition', _weatherData!.condition, screenWidth),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value, double screenWidth) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
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

  Future<void> _requestLocationPermission() async {
    // Check if permission granted
    var status = await Permission.location.request();
    if (status.isGranted) {
      var position = await Geolocator.getCurrentPosition();
      // Now you can save location to Firestore
    } else {
      // Handle permission denied
      debugPrint('Location permission denied');
      // Optionally show error and exit flow
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

  Future<void> _getCurrentLocation() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingWeather = true;
        });
      }

      final bool permissionGranted = await _locationService.requestLocationPermission();
      if (!permissionGranted) {
        _showErrorSnackBar('Location permission not granted. Cannot fetch weather.');
        if (mounted) {
          setState(() {
            _isLoadingWeather = false;
          });
        }
        return;
      }

      final UserLocation? location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        if (mounted) {
          setState(() {
            _currentLocation = location;
          });
        }
        await _getWeatherData(location.latitude, location.longitude);
        await _saveLocationToDatabase(); // Call without parameters
      } else {
        _showErrorSnackBar('Could not get current location.');
      }
      
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _getWeatherData(double lat, double lon) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _weatherData = WeatherData.fromJson(data);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get weather data: $e');
    }
  }

  Future<void> _saveLocationToDatabase() async { // No longer takes parameters
    try {
      final dbService = DatabaseService();
      await dbService.saveUserLocation(); // Call without parameters
    } catch (e) {
      debugPrint('Failed to save location: $e');
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
      // 1. Get user ID (anonymous or authenticated)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // 2. Upload image to Firebase Storage
      final imagePath = 'users/$userId/diagnoses/${_uuid.v4()}.jpg';
      final ref = _storage.ref().child(imagePath);
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // 3. Get Gemini AI diagnosis result
      final imageBytes = await _selectedImage!.readAsBytes();
      final prompt = _createDiagnosisPrompt();
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await _model.generateContent(content);
      final diagnosis = _parseDiagnosisResponse(response.text ?? '');

      // 4. Create StoredDiagnosis
      final storedDiagnosis = StoredDiagnosis(
        userId: userId,
        diagnosisId: _uuid.v4(),
        imageUrl: imageUrl,
        diseaseName: diagnosis.diseaseName,
        severity: diagnosis.severity,
        cause: diagnosis.cause,
        treatment: diagnosis.treatment,
        prevention: diagnosis.prevention,
        weatherAdvice: diagnosis.weatherAdvice,
        timestamp: DateTime.now(),
      );

      // 5. Save to Firestore
      final dbService = DatabaseService();
      await dbService.saveStoredDiagnosis(storedDiagnosis);

      if (mounted) {
        setState(() {
          _diagnosisResult = diagnosis;
        });
      }

    } catch (e) {
      debugPrint('Failed to analyze and store diagnosis: $e');
      _showErrorSnackBar('Failed to save diagnosis. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String _createDiagnosisPrompt() {
    String weatherInfo = '';
    if (_weatherData != null) {
      weatherInfo = '''
Current Weather Conditions:
- Temperature: ${_weatherData!.temperature}°C
- Humidity: ${_weatherData!.humidity}%
- Weather: ${_weatherData!.condition}
''';
    }

    return '''
You are an expert agricultural pathologist helping Indian farmers. Analyze this crop image and provide a detailed diagnosis in simple language that a farmer can easily understand.
 
$weatherInfo
 
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
        weatherAdvice: _weatherData != null 
          ? 'Current weather: ${_weatherData!.condition}, Temperature: ${_weatherData!.temperature}°C'
          : 'Monitor weather conditions regularly',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _saveDiagnosisToDatabase(DiagnosisResult diagnosis) async {
    try {
      final dbService = DatabaseService();
      await dbService.saveDiagnosis(diagnosis);
    } catch (e) {
      debugPrint('Failed to save diagnosis: $e');
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
