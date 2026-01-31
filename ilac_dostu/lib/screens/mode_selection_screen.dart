import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'patient_home_screen.dart';
import 'caregiver_dashboard.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future<void> _selectMode(BuildContext context, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final firestoreService = FirestoreService();

    String uid;
    String name;

    if (role == UserRole.patient) {
      uid = await firestoreService.generatePatientCode();
      name = 'Patient';
    } else {
      uid = DateTime.now().millisecondsSinceEpoch.toString();
      name = 'Caregiver';
    }

    final user = AppUser(
      uid: uid,
      role: role,
      name: name,
    );
    await firestoreService.createUser(user);

    await prefs.setString('userRole', role == UserRole.patient ? 'patient' : 'caregiver');
    await prefs.setString('userUid', uid);

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => role == UserRole.patient
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
              Text(
                'İlaç Dostu',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu cihazı kim kullanacak?',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              _ModeButton(
                icon: '👴',
                title: 'Hasta',
                subtitle: 'İlaçlarımı takip edeceğim',
                color: Colors.blue,
                onTap: () => _selectMode(context, UserRole.patient),
              ),
              const SizedBox(height: 32),
              _ModeButton(
                icon: '🛡️',
                title: 'Bakıcı',
                subtitle: 'Hastamı izleyeceğim',
                color: Colors.green,
                onTap: () => _selectMode(context, UserRole.caregiver),
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
          color: color.withOpacity(0.1),
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
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 20,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
