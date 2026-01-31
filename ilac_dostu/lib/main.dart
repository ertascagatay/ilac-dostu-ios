import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/caregiver_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const IlacDostuApp());
}

class IlacDostuApp extends StatelessWidget {
  const IlacDostuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Dostu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          primary: Color(0xFF1565C0),
          secondary: Color(0xFFFF6F00),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 24, color: Colors.black),
          titleMedium: TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      home: const SplashScreen(),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication,
              size: 100,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 24),
            const Text(
              'İlaç Dostu',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
