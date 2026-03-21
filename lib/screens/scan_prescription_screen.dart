import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'verification_screen.dart';

// Web-only imports
import 'package:flutter/services.dart';
import 'dart:html' as html;

class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({super.key});

  @override
  State<ScanPrescriptionScreen> createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // Web: use HTML file input
        final html.FileUploadInputElement input = html.FileUploadInputElement();
        input.accept = 'image/*';
        input.click();

        await input.onChange.first;

        if (input.files!.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        final file = input.files![0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final Uint8List bytes =
            Uint8List.fromList(reader.result as List<int>);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              imagePath: null,
              imageBytes: bytes,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Prescription'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For best results:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('→ Lay prescription flat',
                      style: TextStyle(color: Colors.white70)),
                  Text('→ Good lighting',
                      style: TextStyle(color: Colors.white70)),
                  Text('→ All text visible',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF2E7D6E))
                          : const Text('Upload Prescription'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D6E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Color(0xFF2E7D6E), width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skip button for demo
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VerificationScreen(
                              imagePath: null,
                              imageBytes: null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Use Demo Data (for testing)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D6E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}