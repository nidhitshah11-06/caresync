import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://thookypqhiswdckxwjzc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRob29reXBxaGlzd2Rja3h3anpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5Mzk4MzcsImV4cCI6MjA4OTUxNTgzN30.hdwQhalGttEuJqVPeNxxESyxV3gJep4BJugXQseZOVU',
  );

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
      ),
      home: const SplashScreen(),
    );
  }
}