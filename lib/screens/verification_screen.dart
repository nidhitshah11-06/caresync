import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../services/gemini_service.dart';
import '../services/reminder_service.dart';
import '../services/supabase_service.dart';
import '../services/patient_service.dart';

class VerificationScreen extends StatefulWidget {
  final String? imagePath;
  const VerificationScreen({Key? key, this.imagePath}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final OcrService _ocrService = OcrService();
  final GeminiService _geminiService = GeminiService();

  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _loadingMessage = 'Reading prescription...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processPrescription();
  }

  Future<void> _processPrescription() async {
    try {
      if (widget.imagePath == null) {
        // Use demo data if no image provided
        setState(() {
          _medicines = [
            {
              'name': 'Metformin 500mg',
              'timing': 'Morning, Night',
              'duration': '30 days',
              'instructions': 'After food',
              'unclear': false,
            },
            {
              'name': 'Amlodipine 5mg',
              'timing': 'Morning',
              'duration': 'UNCLEAR',
              'instructions': 'Before food',
              'unclear': false,
            },
            {
              'name': 'UNCLEAR',
              'timing': '1-0-1',
              'duration': '15 days',
              'instructions': 'UNCLEAR',
              'unclear': true,
            },
          ];
          _isLoading = false;
        });
        return;
      }

      // Step 1: OCR
      setState(() => _loadingMessage = 'Reading prescription...');
      final String ocrText =
          await _ocrService.extractTextFromImage(widget.imagePath!);

      // Step 2: Gemini extraction
      setState(() => _loadingMessage = 'Extracting medicines with AI...');
      final List<Map<String, dynamic>> extracted =
          await _geminiService.extractMedicinesFromText(ocrText);

      // Step 3: Mark unclear fields
      final List<Map<String, dynamic>> processed = extracted.map((med) {
        return {
          'name': med['name'] ?? 'UNCLEAR',
          'timing': med['timing'] ?? 'UNCLEAR',
          'duration': med['duration'] ?? 'UNCLEAR',
          'instructions': med['instructions'] ?? 'UNCLEAR',
          'unclear': med['name'] == 'UNCLEAR' ||
              med['timing'] == 'UNCLEAR' ||
              med['duration'] == 'UNCLEAR' ||
              med['instructions'] == 'UNCLEAR',
        };
      }).toList();

      // Step 4: Safety check
      setState(() => _loadingMessage = 'Checking medicine safety...');
      final List<String> medicineNames =
          processed.map((m) => m['name'] as String).toList();
      final List<String> warnings =
          await _geminiService.checkDrugInteractions(medicineNames);

      if (warnings.isNotEmpty && mounted) {
        _showSafetyWarnings(warnings);
      }

      setState(() {
        _medicines = processed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing prescription: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showSafetyWarnings(List<String> warnings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF5A623), size: 28),
            SizedBox(width: 8),
            Text(
              'Safety Alert',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please review these medicine interactions:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(w, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('I Understand',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editField(int index, String field, String current) {
    final controller =
        TextEditingController(text: current == 'UNCLEAR' ? '' : current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit $field',
          style: const TextStyle(
            color: Color(0xFF2E7D6E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter $field',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D6E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D6E), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _medicines[index][field.toLowerCase()] =
                    controller.text.isEmpty ? 'UNCLEAR' : controller.text;
                _medicines[index]['unclear'] =
                    _medicines[index].values.any((v) => v == 'UNCLEAR');
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool get _hasUnclear => _medicines.any((m) =>
      m['name'] == 'UNCLEAR' ||
      m['timing'] == 'UNCLEAR' ||
      m['duration'] == 'UNCLEAR' ||
      m['instructions'] == 'UNCLEAR');

  Future<void> _confirmAndSave() async {
    if (_hasUnclear) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fix all UNCLEAR fields before confirming'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get current patient
      final patient = await PatientService.getCurrentPatient();

      if (patient == null) {
        throw Exception('Patient not found. Please login again.');
      }

      // Save prescription to Supabase
      final supabaseService = SupabaseService();
      await supabaseService.savePrescription(
        patientId: patient.id,
        patientName: patient.name,
        medicines: _medicines,
        prescriptionImagePath: widget.imagePath,
      );

      // Schedule reminders for each medicine
      for (int i = 0; i < _medicines.length; i++) {
        final med = _medicines[i];
        final String timing = med['timing'] as String;

        if (timing.toLowerCase().contains('morning')) {
          await ReminderService.scheduleReminder(
            id: i * 10 + 1,
            medicineName: med['name'],
            timing: 'Morning',
            hour: 8,
            minute: 5,
          );
        }
        if (timing.toLowerCase().contains('night')) {
          await ReminderService.scheduleReminder(
            id: i * 10 + 2,
            medicineName: med['name'],
            timing: 'Night',
            hour: 21,
            minute: 5,
          );
        }
        if (timing.toLowerCase().contains('afternoon')) {
          await ReminderService.scheduleReminder(
            id: i * 10 + 3,
            medicineName: med['name'],
            timing: 'Afternoon',
            hour: 13,
            minute: 5,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Prescription saved to cloud and reminders set!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6E),
        foregroundColor: Colors.white,
        title: const Text(
          'Verify Prescription',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2E7D6E),
          ),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2E7D6E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a few seconds...',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFE53935), size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D6E),
              ),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_hasUnclear)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF3CD),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF5A623), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some fields are UNCLEAR — tap ✏️ to fix them.',
                    style: TextStyle(color: Color(0xFF856404), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _medicines.length,
            itemBuilder: (context, index) =>
                _buildMedicineCard(index, _medicines[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_hasUnclear)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ Fix all UNCLEAR fields to enable Save',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE53935), fontSize: 13),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_hasUnclear || _isSaving) ? null : _confirmAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D6E),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          _hasUnclear
                              ? 'Fix UNCLEAR fields first'
                              : '✅ Confirm & Save Prescription',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(int index, Map<String, dynamic> med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: med['unclear'] == true
              ? const Color(0xFFF5A623)
              : Colors.grey.shade200,
          width: med['unclear'] == true ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: med['unclear'] == true
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFF2E7D6E).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication,
                    color: Color(0xFF2E7D6E), size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildUnclearField(med['name'], 'name',
                        isHeader: true)),
                IconButton(
                  onPressed: () => _editField(index, 'name', med['name']),
                  icon: const Icon(Icons.edit,
                      color: Color(0xFF2E7D6E), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow(index, 'Timing', 'timing', med['timing'],
                    Icons.access_time),
                const Divider(height: 20),
                _buildRow(index, 'Duration', 'duration', med['duration'],
                    Icons.calendar_today),
                const Divider(height: 20),
                _buildRow(index, 'Instructions', 'instructions',
                    med['instructions'], Icons.info_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
      int index, String label, String field, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(child: _buildUnclearField(value, field)),
        IconButton(
          onPressed: () => _editField(index, label, value),
          icon: const Icon(Icons.edit, color: Color(0xFF2E7D6E), size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildUnclearField(String value, String field,
      {bool isHeader = false}) {
    final isUnclear = value == 'UNCLEAR';
    return Container(
      padding: isUnclear
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : EdgeInsets.zero,
      decoration: isUnclear
          ? BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF5A623)),
            )
          : null,
      child: Text(
        value,
        style: TextStyle(
          fontSize: isHeader ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isUnclear
              ? const Color(0xFF856404)
              : (isHeader ? Colors.grey[800] : Colors.grey[700]),
        ),
      ),
    );
  }
}