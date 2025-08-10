class Constants {
  static const String geminiApiKey = 'AIzaSyD10Ew0v1SbTeF8mG1Td0D3p43WoU7U8Pg';
  static const String weatherApiKey = '7dd1affdf372adbca221a5695fb98cd8'; // Get from OpenWeatherMap
   
  // Gemini model for best image analysis results
  static const String geminiModel = 'gemini-2.0-flash';
  
  static const String cropDiagnosisPrompt = '''
You are an expert agricultural advisor helping Indian farmers. Analyze this crop image and provide:

1. **Disease/Problem Identification:** What specific disease, pest, or issue do you see?

2. **Severity Level:** Rate from 1-5 (1=minor, 5=critical)

3. **Simple Explanation:** Explain in simple Hindi/English what's wrong with the crop in language a farmer can understand.

4. **Why This Happened:** What causes this problem? (weather, soil, pests, etc.)

5. **Immediate Treatment:** What should the farmer do RIGHT NOW? Include:
   - Specific medicines/chemicals to use
   - How to apply them
   - Dosage in simple terms

6. **Prevention:** How to prevent this in future? Include:
   - Crop rotation advice
   - Timing of treatments
   - Soil management

7. **Cost Estimate:** Approximate treatment cost in Indian Rupees

Format response in JSON with these exact keys:
{
  "disease_name": "",
  "severity": 1-5,
  "simple_explanation": "",
  "causes": "",
  "immediate_treatment": "",
  "prevention_tips": "",
  "estimated_cost": "",
  "confidence_score": 0-100
}

Be specific to Indian farming conditions and use terms farmers understand.
''';
}
