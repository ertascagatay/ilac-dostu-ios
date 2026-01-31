import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'patient_home_screen.dart';
import 'caregiver_dashboard.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future&lt;void&gt; _selectMode(BuildContext context, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final firestoreService = FirestoreService();

    String uid;
    String name;

    if (role == UserRole.patient) {
      // Generate 6-digit code for patient
      uid = await firestoreService.generatePatientCode();
      name = 'Patient';
    } else {
      // Generate random UID for caregiver
      uid = DateTime.now().millisecondsSinceEpoch.toString();
      name = 'Caregiver';
    }

    // Create user in Firestore
    final user = AppUser(
      uid: uid,
      role: role,
      name: name,
    );
    await firestoreService.createUser(user);

    // Save mode and UID locally
    await prefs.setString('userRole', role == UserRole.patient ? 'patient' : 'caregiver');
    await prefs.setString('userUid', uid);

    if (!context.mounted) return;

    // Navigate to appropriate screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =&gt; role == UserRole.patient
            ? PatientHomeScreen(patientUid: uid)
            : CaregiverDashboard(caregiverUid: uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'İlaç Dostu',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu cihazı kim kullanacak?',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // Patient Button
              _ModeButton(
                icon: '👴',
                title: 'Hasta',
                subtitle: 'İlaçlarımı takip edeceğim',
                color: Colors.blue,
                onTap: () =&gt; _selectMode(context, UserRole.patient),
              ),

              const SizedBox(height: 32),

              // Caregiver Button
              _ModeButton(
                icon: '🛡️',
                title: 'Bakıcı',
                subtitle: 'Hastamı izleyeceğim',
                color: Colors.green,
                onTap: () =&gt; _selectMode(context, UserRole.caregiver),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 20,
                color: color.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
