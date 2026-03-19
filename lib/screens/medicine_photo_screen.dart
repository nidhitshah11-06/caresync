import 'package:flutter/material.dart';

class MedicinePhotoScreen extends StatelessWidget {
  const MedicinePhotoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedicinePhotoScreen'),
      ),
      body: const Center(
        child: Text('Medicine Photo Screen'),
      ),
    );
  }
}
