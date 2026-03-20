import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  // Speak in English
  static Future<void> speakEnglish(String medicineName,
      String timing, String instructions) async {
    await initialize();
    await _tts.setLanguage('en-IN');
    final String message =
        'Time to take your medicine. $medicineName. $timing. $instructions.';
    await _tts.speak(message);
  }

  // Speak in Hindi
  static Future<void> speakHindi(String medicineName,
      String timing, String instructions) async {
    await initialize();
    await _tts.setLanguage('hi-IN');
    final String message =
        'दवाई लेने का समय है। $medicineName। $timing। $instructions।';
    await _tts.speak(message);
  }

  // Speak in Marathi
  static Future<void> speakMarathi(String medicineName,
      String timing, String instructions) async {
    await initialize();
    await _tts.setLanguage('mr-IN');
    final String message =
        'औषध घेण्याची वेळ आहे। $medicineName। $timing। $instructions।';
    await _tts.speak(message);
  }

  // Auto detect language and speak
  static Future<void> speakReminder({
    required String medicineName,
    required String timing,
    required String instructions,
    String language = 'english',
  }) async {
    await initialize();
    switch (language.toLowerCase()) {
      case 'marathi':
        await speakMarathi(medicineName, timing, instructions);
        break;
      case 'hindi':
        await speakHindi(medicineName, timing, instructions);
        break;
      default:
        await speakEnglish(medicineName, timing, instructions);
    }
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static Future<void> dispose() async {
    await _tts.stop();
  }
}