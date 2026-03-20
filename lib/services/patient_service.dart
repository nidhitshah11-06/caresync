import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/patient.dart';

class PatientService {
  static const String _patientKey = 'current_patient';

  // Save current patient
  static Future<void> savePatient(Patient patient) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patientKey, jsonEncode(patient.toJson()));
  }

  // Get current patient
  static Future<Patient?> getCurrentPatient() async {
    final prefs = await SharedPreferences.getInstance();
    final patientJson = prefs.getString(_patientKey);
    
    if (patientJson == null) return null;
    
    return Patient.fromJson(jsonDecode(patientJson));
  }

  // Check if patient is logged in
  static Future<bool> isLoggedIn() async {
    final patient = await getCurrentPatient();
    return patient != null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patientKey);
  }
}