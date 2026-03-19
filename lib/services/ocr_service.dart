import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class OcrService {
  static const String _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  Future<String> extractTextFromImage(String imagePath) async {
    try {
      // Read image and convert to base64
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Build request body
      final Map<String, dynamic> requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {
                'type': 'DOCUMENT_TEXT_DETECTION',
                'maxResults': 1,
              }
            ],
            'imageContext': {
              'languageHints': ['en', 'hi']
            }
          }
        ]
      };

      // Call Vision API
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${ApiKeys.googleVisionApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract text from response
        final responses = data['responses'] as List;
        if (responses.isNotEmpty) {
          final fullTextAnnotation =
              responses[0]['fullTextAnnotation'];
          if (fullTextAnnotation != null) {
            return fullTextAnnotation['text'] as String;
          }
        }
        return 'No text found in image';
      } else {
        throw Exception(
            'Vision API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('OCR failed: ${e.toString()}');
    }
  }
}