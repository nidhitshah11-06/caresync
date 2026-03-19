import 'package:flutter/material.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VerificationScreen'),
      ),
      body: const Center(
        child: Text('Verification Screen'),
      ),
    );
  }
}
