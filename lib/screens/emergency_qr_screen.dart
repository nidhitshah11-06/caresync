import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmergencyQrScreen extends StatefulWidget {
  const EmergencyQrScreen({super.key});

  @override
  State<EmergencyQrScreen> createState() => _EmergencyQrScreenState();
}

class _EmergencyQrScreenState extends State<EmergencyQrScreen> {
  bool _isProcessing = false;
  static const Color _red = Color(0xFFE53935);

  static const Map<String, dynamic> _emergencyPayload = {
    "name": "Patient Name",
    "age": 67,
    "blood_group": "B+",
    "allergies": ["Penicillin"],
    "medicines": ["Metformin 500mg", "Amlodipine 5mg"],
    "emergency_contact": "Rahul - 9876543210",
  };

  String get _qrData => jsonEncode(_emergencyPayload);

  Future<Uint8List> _renderQrPngBytes({required int size}) async {
    final painter = QrPainter(
      data: _qrData,
      version: QrVersions.auto,
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    painter.paint(canvas, ui.Size(size.toDouble(), size.toDouble()));

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(size, size);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      throw Exception('Failed to render QR image.');
    }
    return bytes;
  }

  Future<void> _saveAsWallpaper() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      const int qrSize = 280;
      final bytes = await _renderQrPngBytes(size: qrSize);

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          p.join(dir.path, 'emergency_qr_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png');

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved QR to: $filePath'),
          backgroundColor: _red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _printQr() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      const int qrSize = 280;
      final bytes = await _renderQrPngBytes(size: qrSize);

      final pdf = pw.Document();
      final qrImage = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Emergency QR',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Image(qrImage, width: 220, height: 220),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat _) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text(
          'Emergency QR',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'This QR works without internet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 280,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _saveAsWallpaper,
                        icon: const Icon(Icons.wallpaper),
                        label: const Text('Save as Wallpaper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _printQr,
                        icon: const Icon(Icons.print),
                        label: const Text('Print QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}

