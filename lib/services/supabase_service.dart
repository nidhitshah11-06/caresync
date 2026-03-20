import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client instance.
// NOTE: Supabase must be initialized in `main.dart` elsewhere in the app.
final supabase = Supabase.instance.client;

// Supabase project URL used for initialization in `main.dart`.
// https://thookypqhiswdckxwjzc.supabase.co

String _guessContentType(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}

Future<void> _savePrescriptionToDatabase({
  required String patientId,
  required String originalImageUrl,
  required String doctorName,
  required String hospitalName,
  required DateTime prescriptionDate,
  required List<Map<String, dynamic>> medicines,
  required Map<String, dynamic> extractedData,
}) async {
  try {
    // Insert prescription row and get the created `id`.
    final inserted = await supabase
        .from('prescriptions')
        .insert({
          'patient_id': patientId,
          'original_image_url': originalImageUrl,
          'doctor_name': doctorName,
          'hospital_name': hospitalName,
          'prescription_date': prescriptionDate.toIso8601String(),
          'extracted_data': extractedData,
        })
        .select('id')
        .single();

    final dynamic prescriptionId = inserted['id'];

    // Insert each medicine row, linking it back to the prescription.
    for (final medicine in medicines) {
      final Map<String, dynamic> medicineRow = Map<String, dynamic>.from(
        medicine,
      );
      medicineRow['prescription_id'] = prescriptionId;

      await supabase.from('medicines').insert(medicineRow);
    }
  } catch (e) {
    throw Exception('Failed to save prescription: $e');
  }
}

Future<String> uploadPrescriptionImage({
  required String imageFilePath,
  String? fileName,
}) async {
  final bucket = 'prescription-images';
  final file = File(imageFilePath);
  if (!file.existsSync()) {
    throw Exception('File not found: $imageFilePath');
  }

  final String extInPath = p.extension(imageFilePath).toLowerCase();
  final String resolvedExt = extInPath.isNotEmpty ? extInPath : '.jpg';
  final String baseName = fileName != null
      ? p.basenameWithoutExtension(fileName)
      : 'prescription_${DateTime.now().millisecondsSinceEpoch}';
  final String storagePath = 'prescriptions/$baseName$resolvedExt';

  await supabase.storage.from(bucket).upload(
        storagePath,
        file,
        fileOptions: FileOptions(contentType: _guessContentType(imageFilePath)),
      );

  // Requires the bucket (or object) to be configured for public access.
  return supabase.storage.from(bucket).getPublicUrl(storagePath);
}

Future<String> uploadMedicinePhoto({
  required String imageFilePath,
  String? fileName,
}) async {
  final bucket = 'medicine-photos';
  final file = File(imageFilePath);
  if (!file.existsSync()) {
    throw Exception('File not found: $imageFilePath');
  }

  final String extInPath = p.extension(imageFilePath).toLowerCase();
  final String resolvedExt = extInPath.isNotEmpty ? extInPath : '.jpg';
  final String baseName = fileName != null
      ? p.basenameWithoutExtension(fileName)
      : 'medicine_${DateTime.now().millisecondsSinceEpoch}';
  final String storagePath = 'medicines/$baseName$resolvedExt';

  await supabase.storage.from(bucket).upload(
        storagePath,
        file,
        fileOptions: FileOptions(contentType: _guessContentType(imageFilePath)),
      );

  // Requires the bucket (or object) to be configured for public access.
  return supabase.storage.from(bucket).getPublicUrl(storagePath);
}

/// Service class for Supabase operations from the Flutter app
class SupabaseService {
  /// Save prescription from verification screen
  Future<void> savePrescription({
    required String patientId,
    required String patientName,
    required List<Map<String, dynamic>> medicines,
    String? prescriptionImagePath,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (prescriptionImagePath != null && prescriptionImagePath.isNotEmpty) {
        try {
          imageUrl = await uploadPrescriptionImage(
            imageFilePath: prescriptionImagePath,
          );
        } catch (e) {
          print('⚠️ Image upload failed, continuing without image: $e');
          imageUrl = null;
        }
      }

      // Prepare extracted data
      final extractedData = {
        'patient_name': patientName,
        'medicines': medicines,
        'extracted_at': DateTime.now().toIso8601String(),
      };

      // Call the database save function
      await _savePrescriptionToDatabase(
        patientId: patientId,
        originalImageUrl: imageUrl ?? '',
        doctorName: 'Self-scanned',
        hospitalName: 'CareSync Mobile App',
        prescriptionDate: DateTime.now(),
        medicines: medicines,
        extractedData: extractedData,
      );

      print('✅ Prescription saved successfully for patient: $patientId');
    } catch (e) {
      print('❌ Error saving prescription: $e');
      rethrow;
    }
  }
}