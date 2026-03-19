import 'package:flutter/material.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReminderCard'),
      ),
      body: const Center(
        child: Text('Reminder Card'),
      ),
    );
  }
}
