import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'reminder_screen.dart';
import 'scan_prescription_screen.dart';
import 'qr_screen.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReminderScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP HEADER
            Container(
              color: const Color(0xFF2E7D6E),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Patient?>(
                    future: PatientService.getCurrentPatient(),
                    builder: (context, snapshot) {
                      final patientName = snapshot.data?.name ?? 'User';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Morning 🌅',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            patientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // TODAY'S MEDICINES SECTION
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Today's Medicines",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  _buildMedicineItem(
                    'Metformin 500mg',
                    'Morning',
                    'Taken',
                    Colors.green,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildMedicineItem(
                    'Amlodipine 5mg',
                    'Morning',
                    'Taken',
                    Colors.green,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildMedicineItem(
                    'Ecosprin 75mg',
                    'Night',
                    'Pending',
                    Colors.orange,
                  ),
                ],
              ),
            ),

            // SCAN PRESCRIPTION BUTTON
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanPrescriptionScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D6E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Scan Prescription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MY HEALTH QR BUTTON
            GestureDetector(
              onTap: () async {
                final patient = await PatientService.getCurrentPatient();
                
                if (patient == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Patient not found'),
                      backgroundColor: Color(0xFFE53935),
                    ),
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrScreen(
                      patientPublicId: patient.id,
                      patientName: patient.name,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E7D6E),
                    width: 2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, color: Color(0xFF2E7D6E), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'My Health QR',
                      style: TextStyle(
                        color: Color(0xFF2E7D6E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: const Color(0xFF2E7D6E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(
    String medicineName,
    String time,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.local_pharmacy,
            color: Color(0xFF2E7D6E),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}