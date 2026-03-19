import 'package:flutter/material.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReminderScreen'),
      ),
      body: const Center(
        child: Text('Reminder Screen'),
      ),
    );
  }
}
