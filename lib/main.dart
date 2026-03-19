import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CareSync());
}

class CareSync extends StatelessWidget {
  const CareSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
