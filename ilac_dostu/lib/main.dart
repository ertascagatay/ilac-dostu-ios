import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/caregiver_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    runApp(const IlacDostuApp());
  } catch (e) {
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

class IlacDostuApp extends StatelessWidget {
  const IlacDostuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Dostu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.patientTheme,
      home: const SplashScreen(),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;
  
  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Firebase Initialization Error',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please check:\n\n'
                  '1. GoogleService-Info.plist is in ios/Runner/\n'
                  '2. google-services.json is in android/app/\n'
                  '3. Firebase is configured correctly',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserMode();
  }

  Future<void> _checkUserMode() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');
    final userUid = prefs.getString('userUid');

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (userRole == null || userUid == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
      );
    } else {
      if (userRole == 'patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PatientHomeScreen(patientUid: userUid)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CaregiverDashboard(caregiverUid: userUid)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'İlaç Dostu',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
