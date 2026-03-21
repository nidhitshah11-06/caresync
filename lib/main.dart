import 'screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/reminder_service.dart';
import 'services/voice_service.dart';
import 'config/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  await ReminderService.initialize();
  await VoiceService.initialize();

  runApp(const CareSync());
}

final supabase = Supabase.instance.client;

class CareSync extends StatelessWidget {
  const CareSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D6E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6E),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: supabase.auth.currentSession == null
    ? const LoginScreen()
    : const SplashScreen(),
    );
  }
}