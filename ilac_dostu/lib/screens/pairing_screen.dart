import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'caregiver_dashboard.dart';

class PairingScreen extends StatefulWidget {
  final String caregiverUid;
  const PairingScreen({super.key, required this.caregiverUid});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Lütfen 6 haneli kodu girin.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _firestoreService.linkPatientToCaregiver(
        patientCode: code,
        caregiverUid: widget.caregiverUid,
      );

      if (!mounted) return;

      if (success) {
        _showMessage('Hasta başarıyla eşleştirildi! ✓', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CaregiverDashboard(caregiverUid: widget.caregiverUid),
          ),
          (route) => false,
        );
      } else {
        _showMessage('Kod bulunamadı. Lütfen kontrol edin.', isError: true);
      }
    } catch (e) {
      _showMessage('Hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : PremiumColors.greenCheck,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hasta Eşleştir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: PremiumColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PremiumColors.pillPurple.withValues(alpha: 0.15),
                      PremiumColors.pillBlue.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 56,
                  color: PremiumColors.pillPurple,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Hasta Eşleşme',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hastanızın paylaştığı 6 haneli\neşleşme kodunu girin',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: PremiumColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Code input
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PremiumColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                    color: PremiumColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 28,
                      color: PremiumColors.textTertiary,
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Pair button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pair,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    _isLoading ? 'Eşleştiriliyor...' : 'Eşleştir',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumColors.pillPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
