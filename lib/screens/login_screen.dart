import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create patient with phone as ID (unique identifier)
    final patient = Patient(
      id: 'P${phone.replaceAll(' ', '')}', // e.g., P9876543210
      name: name,
      phone: phone,
    );

    // Save to local storage
    await PatientService.savePatient(patient);

    if (!mounted) return;

    // Navigate to home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D6E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'CareSync',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medicine Reminder for You',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              
              // Name Field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E7D6E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}