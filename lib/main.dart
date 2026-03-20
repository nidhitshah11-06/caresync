import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/reminder_service.dart';
import 'services/voice_service.dart';
import 'services/patient_service.dart';
import 'config/api_keys.dart';

// Supabase client instance
late final supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );
  
  supabase = Supabase.instance.client;
  
  // Initialize other services
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
      home: const AuthCheck(),
    );
  }
}

// Check if user is logged in
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    
    final isLoggedIn = await PatientService.isLoggedIn();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn 
            ? const HomeScreen() 
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}