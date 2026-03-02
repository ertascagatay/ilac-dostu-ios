import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'patient_home_screen.dart';
import 'caregiver_dashboard.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainWrapper extends StatefulWidget {
  final String userUid;
  final UserRole role;

  const MainWrapper({
    super.key,
    required this.userUid,
    required this.role,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Ana Sayfa
          widget.role == UserRole.patient
              ? PatientHomeScreen(patientUid: widget.userUid)
              : CaregiverDashboard(caregiverUid: widget.userUid),

          // 1: Geçmiş / Raporlar
          HistoryScreen(userUid: widget.userUid, role: widget.role),

          // 2: Profil & Ayarlar
          SettingsScreen(userUid: widget.userUid),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: PremiumColors.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
                _buildNavItem(1, Icons.history_rounded, Icons.history_outlined, 'Geçmiş'),
                _buildNavItem(2, Icons.settings_rounded, Icons.settings_outlined, 'Ayarlar'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? PremiumColors.coralAccent : PremiumColors.textSecondary;
    final icon = isSelected ? activeIcon : inactiveIcon;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PremiumColors.coralAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
