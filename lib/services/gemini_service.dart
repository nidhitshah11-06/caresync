import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<List<Map<String, dynamic>>> extractMedicinesFromText(
      String ocrText) async {
    try {
      final String prompt = '''
You are a medical prescription reader assistant.

Extract all medicines from this prescription text and return ONLY a JSON array.
For any field you cannot read clearly, write exactly "UNCLEAR".

Prescription text:
$ocrText

Return ONLY this JSON format, nothing else:
[
  {
    "name": "Medicine name and dosage",
    "timing": "Morning/Afternoon/Night or UNCLEAR",
    "duration": "X days or UNCLEAR",
    "instructions": "Before food/After food or UNCLEAR"
  }
]

Rules:
- Interpret timing codes: 1-0-1 means Morning and Night, 1-1-1 means Morning Afternoon Night
- Correct obvious OCR errors (Metf0rmin → Metformin)
- If unsure about ANY field, write UNCLEAR
- Return ONLY the JSON array, no explanation
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1000,
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract text from Gemini response
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            String jsonText = parts[0]['text'] as String;

            // Clean up response — remove markdown if present
            jsonText = jsonText
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();

            // Parse JSON array
            final List<dynamic> medicines = jsonDecode(jsonText);
            return medicines
                .map((m) => Map<String, dynamic>.from(m))
                .toList();
          }
        }
        return [];
      } else {
        throw Exception(
            'Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Medicine extraction failed: ${e.toString()}');
    }
  }

  Future<List<String>> checkDrugInteractions(
      List<String> medicineNames) async {
    try {
      final String medicineList = medicineNames.join(', ');
      final String prompt = '''
You are a medical safety checker.

Check if there are any dangerous drug interactions between these medicines:
$medicineList

Return ONLY a JSON array of warning strings.
If no interactions found, return an empty array [].

Example response:
["Metformin and Amlodipine may cause low blood pressure",
 "Take Ecosprin with food to avoid stomach issues"]

Return ONLY the JSON array, no explanation.
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 500,
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            String jsonText = parts[0]['text'] as String;
            jsonText = jsonText
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
            final List<dynamic> warnings = jsonDecode(jsonText);
            return warnings.map((w) => w.toString()).toList();
          }
        }
        return [];
      } else {
        throw Exception(
            'Gemini safety check error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Safety check failed: ${e.toString()}');
    }
  }
}