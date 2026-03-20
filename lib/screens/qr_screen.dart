import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrScreen extends StatefulWidget {
  final String patientPublicId;
  final String patientName;

  const QrScreen({
    super.key,
    required this.patientPublicId,
    required this.patientName,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  bool _isDownloading = false;

  String get _qrUrl =>
      'https://v0-patient-health-portal.vercel.app/patient/$patientPublicId';

  Future<void> _downloadQr() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      const double qrSize = 250;

      // Generate QR as PNG bytes (no extra screenshot/gallery dependency).
      final painter = QrPainter(
        data: _qrUrl,
        version: QrVersions.auto,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(canvas, const ui.Size(qrSize, qrSize));
      final picture = recorder.endRecording();

      final uiImage = await picture.toImage(qrSize.toInt(), qrSize.toInt());
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes == null) {
        throw Exception('Failed to encode QR image.');
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/my_health_qr_${widget.patientPublicId}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR downloaded to: $filePath'),
          backgroundColor: const Color(0xFF2E7D6E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareQr() async {
    // Without adding extra packages, sharing is implemented as copying the
    // QR URL to clipboard (user can paste it anywhere).
    try {
      await Clipboard.setData(ClipboardData(text: _qrUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR link copied. You can now share it.'),
          backgroundColor: Color(0xFF2E7D6E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF2E7D6E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        title: const Text(
          'My Health QR',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: _qrUrl,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.patientName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Public ID: ${widget.patientPublicId}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadQr,
                        icon: const Icon(Icons.download),
                        label: const Text('Download QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
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
                        onPressed: _shareQr,
                        icon: const Icon(Icons.share),
                        label: const Text('Share QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 10),
                child: Text(
                  'Show this QR to any doctor for instant access to your medical history',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

