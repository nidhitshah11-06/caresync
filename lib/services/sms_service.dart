import 'dart:convert';

import 'package:http/http.dart' as http;

class SmsService {
  // MSG91 Auth key placeholder (replace in production).
  static const String _authKey = 'YOUR_MSG91_KEY';

  // MSG91 Flow API endpoint (as provided).
  static const String _flowEndpoint =
      'https://api.msg91.com/api/v5/flow/';

  // MSG91 Flow API requires these fields.
  // Create one flow where the SMS template uses VAR1 for the full text,
  // and then set these placeholders to your actual values.
  static const String _sender = 'CareSync';
  static const String _flowId = 'YOUR_MSG91_FLOW_ID';

  static Future<void> _sendViaMsg91Flow({
    required String guardianPhone,
    required String message,
  }) async {
    final uri = Uri.parse(_flowEndpoint);

    // If you need strict validation for phone format, apply it here.
    final payload = <String, dynamic>{
      'authkey': _authKey,
      'flow_id': _flowId,
      'sender': _sender,
      'recipients': [
        {
          'mobiles': guardianPhone,
          // Use VAR1 for the entire message text.
          'VAR1': message,
        }
      ],
    };

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'MSG91 SMS failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Sends SMS:
  /// "{patientName} missed their {time} {medicineName}.
  /// Please check on them. — CareSync"
  static Future<void> sendMissedDoseAlert({
    required String guardianPhone,
    required String patientName,
    required String medicineName,
    required String time,
  }) async {
    final message =
        '$patientName missed their $time $medicineName.\nPlease check on them. — CareSync';
    await _sendViaMsg91Flow(
      guardianPhone: guardianPhone,
      message: message,
    );
  }

  /// Sends SMS:
  /// "Weekly report for {patientName}:
  /// {takenDoses}/{totalDoses} doses taken. — CareSync"
  static Future<void> sendWeeklySummary({
    required String guardianPhone,
    required String patientName,
    required int totalDoses,
    required int takenDoses,
    required int missedDoses,
  }) async {
    final message =
        'Weekly report for $patientName:\n$takenDoses/$totalDoses doses taken. — CareSync';
    // NOTE: missedDoses is provided in the API, but the required SMS text
    // doesn't include it.
    await _sendViaMsg91Flow(
      guardianPhone: guardianPhone,
      message: message,
    );
  }

  /// Sends SMS:
  /// "Safety Alert: {newMedicine} may clash with {clashingMedicine}
  /// for {patientName}. — CareSync"
  static Future<void> sendSafetyAlert({
    required String guardianPhone,
    required String patientName,
    required String newMedicine,
    required String clashingMedicine,
  }) async {
    final message =
        'Safety Alert: $newMedicine may clash with $clashingMedicine for $patientName. — CareSync';
    await _sendViaMsg91Flow(
      guardianPhone: guardianPhone,
      message: message,
    );
  }
}

