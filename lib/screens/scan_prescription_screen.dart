import 'package:flutter/material.dart';

class ScanPrescriptionScreen extends StatelessWidget {
  const ScanPrescriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanPrescriptionScreen'),
      ),
      body: const Center(
        child: Text('Scan Prescription Screen'),
      ),
    );
  }
}
