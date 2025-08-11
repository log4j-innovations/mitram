import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';
import 'dart:convert'; // Added missing import for json

class GovtScheme {
  final String name;
  final String description;
  final String eligibility;
  final String benefits;
  final String applicationProcess;
  final String category;

  GovtScheme({
    required this.name,
    required this.description,
    required this.eligibility,
    required this.benefits,
    required this.applicationProcess,
    required this.category,
  });
}

class GovtSchemesService {
  late GenerativeModel _model;

  GovtSchemesService() {
    _initializeGemini();
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: Constants.geminiApiKey,
    );
  }

  Future<List<GovtScheme>> findEligibleSchemes({
    required String farmerProfile,
    String? cropType,
    String? landSize,
    String? state,
    String? incomeLevel,
  }) async {
    try {
      final prompt = _createSchemeMatchingPrompt(
        farmerProfile: farmerProfile,
        cropType: cropType,
        landSize: landSize,
        state: state,
        incomeLevel: incomeLevel,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      return _parseSchemeResponse(responseText);
    } catch (e) {
      print('Error finding eligible schemes: $e');
      return getDefaultSchemes();
    }
  }

  String _createSchemeMatchingPrompt({
    required String farmerProfile,
    String? cropType,
    String? landSize,
    String? state,
    String? incomeLevel,
  }) {
    return '''
You are an expert agricultural policy advisor helping Indian farmers find suitable government schemes. Based on the farmer's profile, recommend the most relevant government schemes.

Farmer Profile:
- Description: $farmerProfile
- Crop Type: ${cropType ?? 'Not specified'}
- Land Size: ${landSize ?? 'Not specified'}
- State: ${state ?? 'Not specified'}
- Income Level: ${incomeLevel ?? 'Not specified'}

Please analyze this profile and recommend suitable government schemes. Consider schemes like:
- PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)
- PMFBY (Pradhan Mantri Fasal Bima Yojana)
- PMKSY (Pradhan Mantri Krishi Sinchayee Yojana)
- Soil Health Card Scheme
- National Agriculture Market (eNAM)
- Kisan Credit Card
- PM-KMY (Pradhan Mantri Kisan Maan Dhan Yojana)
- PM-KUSUM (Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan)
- And other relevant state and central schemes

Provide your response in the following JSON format:
{
  "schemes": [
    {
      "name": "Scheme Name",
      "description": "Brief description of the scheme",
      "eligibility": "Eligibility criteria",
      "benefits": "Benefits and financial assistance",
      "applicationProcess": "How to apply",
      "category": "Category (e.g., Financial Support, Insurance, Infrastructure, etc.)"
    }
  ]
}

Focus on schemes that are most relevant to the farmer's specific situation. Provide 3-5 most suitable schemes.
''';
  }

  List<GovtScheme> _parseSchemeResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        return getDefaultSchemes();
      }

      final jsonString = response.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        json.decode(jsonString),
      );

      final schemes = data['schemes'] as List<dynamic>;
      return schemes.map((scheme) {
        return GovtScheme(
          name: scheme['name'] ?? 'Unknown Scheme',
          description: scheme['description'] ?? 'No description available',
          eligibility: scheme['eligibility'] ?? 'Check official website',
          benefits: scheme['benefits'] ?? 'Contact local agriculture office',
          applicationProcess: scheme['applicationProcess'] ?? 'Visit nearest agriculture office',
          category: scheme['category'] ?? 'General',
        );
      }).toList();
    } catch (e) {
      print('Error parsing scheme response: $e');
      return getDefaultSchemes();
    }
  }

  List<GovtScheme> getDefaultSchemes() {
    return [
      GovtScheme(
        name: 'PM-KISAN',
        description: 'Direct income support of ₹6,000 per year to eligible farmer families',
        eligibility: 'Small and marginal farmers with cultivable land up to 2 hectares',
        benefits: '₹6,000 per year in three equal installments of ₹2,000 each',
        applicationProcess: 'Apply through Common Service Centers (CSC) or online at pmkisan.gov.in',
        category: 'Financial Support',
      ),
      GovtScheme(
        name: 'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
        description: 'Comprehensive crop insurance scheme for farmers',
        eligibility: 'All farmers growing notified crops in notified areas',
        benefits: 'Crop insurance coverage with low premium rates (1.5% to 5%)',
        applicationProcess: 'Apply through banks, insurance companies, or Common Service Centers',
        category: 'Insurance',
      ),
      GovtScheme(
        name: 'Soil Health Card Scheme',
        description: 'Free soil testing and recommendations for farmers',
        eligibility: 'All farmers across India',
        benefits: 'Free soil testing every 3 years with personalized recommendations',
        applicationProcess: 'Contact nearest agriculture office or apply online',
        category: 'Infrastructure',
      ),
    ];
  }

  Future<String> getSchemeApplicationGuide(String schemeName, String farmerProfile) async {
    try {
      final prompt = '''
You are an expert government scheme application advisor helping Indian farmers. Provide a detailed, step-by-step guide for applying to the $schemeName scheme.

Farmer Profile: $farmerProfile

Please provide a comprehensive application guide in simple language that includes:

1. **Required Documents:**
   - List all necessary documents with specific details
   - Mention if photocopies or originals are needed
   - Include any specific format requirements

2. **Application Process:**
   - Step-by-step instructions
   - Whether online or offline application
   - Any specific forms to fill

3. **Where to Apply:**
   - Exact locations (CSC, banks, agriculture offices)
   - Contact information if available
   - Online portal links if applicable

4. **Timeline:**
   - When to apply
   - How long the process takes
   - When to expect benefits

5. **Important Tips:**
   - Common mistakes to avoid
   - Best practices
   - What to do if application is rejected

Make the guide practical, easy to understand, and specifically tailored for Indian farmers. Use simple language and provide actionable steps.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      
      if (responseText != null && responseText.isNotEmpty) {
        return responseText;
      } else {
        return _getDefaultApplicationGuide(schemeName);
      }
    } catch (e) {
      print('Error generating application guide: $e');
      return _getDefaultApplicationGuide(schemeName);
    }
  }

  String _getDefaultApplicationGuide(String schemeName) {
    switch (schemeName.toLowerCase()) {
      case 'pm-kisan':
        return '''
**PM-KISAN Application Guide**

**Required Documents:**
- Aadhaar Card (original + photocopy)
- Land records (Khasra/Khatauni)
- Bank account details
- Passport size photographs
- Mobile number

**Application Process:**
1. Visit nearest Common Service Center (CSC)
2. Provide your Aadhaar number
3. Submit land records for verification
4. Fill the application form
5. Submit all required documents

**Where to Apply:**
- Common Service Centers (CSC)
- Online at pmkisan.gov.in
- Nearest agriculture office

**Timeline:**
- Application processing: 15-30 days
- First installment: Within 2-3 months
- Subsequent installments: Every 4 months

**Important Tips:**
- Ensure land records are up to date
- Keep Aadhaar linked to bank account
- Verify details before submission
- Keep application receipt safe
''';

      case 'pmfby':
      case 'pmfby (pradhan mantri fasal bima yojana)':
        return '''
**PMFBY Application Guide**

**Required Documents:**
- Land records
- Bank account details
- Crop details
- Previous year's yield data
- Aadhaar Card

**Application Process:**
1. Contact your bank or insurance company
2. Provide crop and land details
3. Pay premium (1.5% to 5% of sum insured)
4. Receive insurance certificate

**Where to Apply:**
- Banks (where you have loan)
- Insurance companies
- Common Service Centers
- Agriculture offices

**Timeline:**
- Apply before sowing season
- Coverage period: Sowing to harvesting
- Claim settlement: Within 2 months of loss

**Important Tips:**
- Apply before crop sowing
- Keep all documents ready
- Report crop damage within 48 hours
- Maintain proper records
''';

      case 'soil health card':
        return '''
**Soil Health Card Application Guide**

**Required Documents:**
- Land records
- Aadhaar Card
- Mobile number
- Previous soil test reports (if any)

**Application Process:**
1. Visit nearest agriculture office
2. Submit land details
3. Soil sample collection scheduled
4. Receive soil health card

**Where to Apply:**
- District agriculture office
- Krishi Vigyan Kendras
- Online through state portals

**Timeline:**
- Soil sampling: Within 15 days
- Report generation: 30-45 days
- Card delivery: Within 60 days

**Important Tips:**
- Apply during non-cropping season
- Ensure proper soil sampling
- Follow recommendations provided
- Reapply every 3 years
''';

      default:
        return '''
**Application Guide for $schemeName**

**Required Documents:**
- Aadhaar Card
- Land records
- Bank account details
- Income certificate
- Caste certificate (if applicable)

**Application Process:**
1. Visit nearest agriculture office
2. Collect application form
3. Fill all required details
4. Submit with documents
5. Get acknowledgment receipt

**Where to Apply:**
- District agriculture office
- Common Service Centers
- Online portals (if available)

**Timeline:**
- Processing time: 30-60 days
- Verification period: 15-30 days
- Benefit disbursement: As per scheme

**Important Tips:**
- Keep all documents ready
- Verify information before submission
- Follow up on application status
- Keep copies of all documents
''';
    }
  }
}
