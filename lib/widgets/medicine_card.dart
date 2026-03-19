import 'package:flutter/material.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedicineCard'),
      ),
      body: const Center(
        child: Text('Medicine Card'),
      ),
    );
  }
}
