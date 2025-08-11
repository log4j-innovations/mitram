import 'package:flutter/material.dart';
import '../services/govt_schemes_service.dart';

class GovtSchemesScreen extends StatefulWidget {
  static const routeName = '/govt-schemes';
  const GovtSchemesScreen({super.key});

  @override
  _GovtSchemesScreenState createState() => _GovtSchemesScreenState();
}

class _GovtSchemesScreenState extends State<GovtSchemesScreen> {
  final GovtSchemesService _schemesService = GovtSchemesService();
  final TextEditingController _profileController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _landSizeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  List<GovtScheme> _schemes = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultSchemes();
  }

  void _loadDefaultSchemes() {
    setState(() {
      _schemes = _schemesService.getDefaultSchemes();
    });
  }

  Future<void> _findEligibleSchemes() async {
    if (_profileController.text.trim().isEmpty) {
      _showErrorSnackBar('Please describe your farming situation');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final schemes = await _schemesService.findEligibleSchemes(
        farmerProfile: _profileController.text.trim(),
        cropType: _cropController.text.trim().isNotEmpty ? _cropController.text.trim() : null,
        landSize: _landSizeController.text.trim().isNotEmpty ? _landSizeController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        incomeLevel: _incomeController.text.trim().isNotEmpty ? _incomeController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _schemes = schemes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to find schemes. Please try again.');
      }
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8D5A8),
        title: Text(
          'Government Schemes',
          style: TextStyle(
            color: Colors.black,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI-Powered Scheme Finder Section
              _buildSchemeFinderSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),

              // Results Section
              if (_hasSearched) ...[
                _buildResultsHeader(screenWidth),
                SizedBox(height: screenHeight * 0.02),
              ],

              // Schemes List
              _buildSchemesList(screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchemeFinderSection(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: screenWidth * 0.06),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'AI-Powered Scheme Finder',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Tell us about your farming situation and we\'ll find the best schemes for you:',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Profile Description
            TextFormField(
              controller: _profileController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe your farming situation*',
                hintText: 'e.g., I am a small farmer growing wheat and rice on 2 acres in Uttar Pradesh...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Additional Details Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cropController,
                    decoration: InputDecoration(
                      labelText: 'Main Crops',
                      hintText: 'e.g., Wheat, Rice',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: TextFormField(
                    controller: _landSizeController,
                    decoration: InputDecoration(
                      labelText: 'Land Size',
                      hintText: 'e.g., 2 acres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      hintText: 'e.g., Uttar Pradesh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: TextFormField(
                    controller: _incomeController,
                    decoration: InputDecoration(
                      labelText: 'Income Level',
                      hintText: 'e.g., Low, Medium',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),

            // Find Schemes Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _findEligibleSchemes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.04,
                            height: screenWidth * 0.04,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Finding Schemes...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white, size: screenWidth * 0.05),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Find Eligible Schemes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(double screenWidth) {
    return Row(
      children: [
        Icon(Icons.list_alt, color: Colors.green.shade700, size: screenWidth * 0.05),
        SizedBox(width: screenWidth * 0.02),
        Text(
          'Recommended Schemes',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSchemesList(double screenWidth, double screenHeight) {
    return Column(
      children: _schemes.map((scheme) => _buildSchemeCard(scheme, screenWidth, screenHeight)).toList(),
    );
  }

  Widget _buildSchemeCard(GovtScheme scheme, double screenWidth, double screenHeight) {
    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(scheme.category),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Text(
                    scheme.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.verified, color: Colors.green.shade600, size: screenWidth * 0.05),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              scheme.name,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              scheme.description,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Eligibility
            _buildInfoSection('Eligibility', scheme.eligibility, Icons.check_circle, screenWidth),
            SizedBox(height: screenHeight * 0.01),

            // Benefits
            _buildInfoSection('Benefits', scheme.benefits, Icons.monetization_on, screenWidth),
            SizedBox(height: screenHeight * 0.01),

            // Application Process
            _buildInfoSection('How to Apply', scheme.applicationProcess, Icons.how_to_reg, screenWidth),
            SizedBox(height: screenHeight * 0.02),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showApplicationGuide(scheme),
                    icon: Icon(Icons.help_outline, size: screenWidth * 0.04),
                    label: Text(
                      'Application Guide',
                      style: TextStyle(fontSize: screenWidth * 0.03),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSchemeDetails(scheme),
                    icon: Icon(Icons.info_outline, size: screenWidth * 0.04),
                    label: Text(
                      'More Details',
                      style: TextStyle(fontSize: screenWidth * 0.03),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green.shade600, size: screenWidth * 0.04),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                content,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'financial support':
        return Colors.green.shade600;
      case 'insurance':
        return Colors.blue.shade600;
      case 'infrastructure':
        return Colors.orange.shade600;
      case 'technology':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showApplicationGuide(GovtScheme scheme) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Application Guide - ${scheme.name}'),
        content: FutureBuilder<String>(
          future: _schemesService.getSchemeApplicationGuide(
            scheme.name,
            _profileController.text.trim(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Text(snapshot.data ?? 'Guide not available'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSchemeDetails(GovtScheme scheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(scheme.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(scheme.description),
              SizedBox(height: 16),
              Text(
                'Eligibility',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(scheme.eligibility),
              SizedBox(height: 16),
              Text(
                'Benefits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(scheme.benefits),
              SizedBox(height: 16),
              Text(
                'Application Process',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(scheme.applicationProcess),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _profileController.dispose();
    _cropController.dispose();
    _landSizeController.dispose();
    _stateController.dispose();
    _incomeController.dispose();
    super.dispose();
  }
}
