import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/reminder_service.dart';
import 'services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await ReminderService.initialize();
  await VoiceService.initialize();
  
  runApp(const CareSyncApp());
}

class CareSyncApp extends StatelessWidget {
  const CareSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6E),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}