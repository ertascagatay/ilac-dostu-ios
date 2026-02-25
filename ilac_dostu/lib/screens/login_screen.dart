import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'register_screen.dart';
import 'patient_home_screen.dart';
import 'caregiver_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Email Login ──────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (user == null) {
        _showError('Kullanıcı bilgileri bulunamadı.');
        return;
      }

      _navigateToHome(user);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          message = 'Şifre hatalı.';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi.';
          break;
        case 'invalid-credential':
          message = 'E-posta veya şifre hatalı.';
          break;
        case 'too-many-requests':
          message = 'Çok fazla deneme. Lütfen bekleyin.';
          break;
        default:
          message = 'Giriş hatası: ${e.message}';
      }
      _showError(message);
    } catch (e) {
      _showError('Giriş hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final appUser = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (appUser != null) {
        _navigateToHome(appUser);
      } else {
        // New user → ask for role
        _showRoleSelectionDialog();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        _showError('Google giriş hatası: $msg');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Apple Sign-In ────────────────────────────────────────────

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appUser = await _authService.signInWithApple();

      if (!mounted) return;

      if (appUser != null) {
        _navigateToHome(appUser);
      } else {
        // New user → ask for role
        _showRoleSelectionDialog();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        _showError('Apple giriş hatası: $msg');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Role Selection for Social Login ──────────────────────────

  void _showRoleSelectionDialog() {
    final nameController = TextEditingController(
      text: _authService.currentUser?.displayName ?? '',
    );
    UserRole selectedRole = UserRole.patient;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: PremiumColors.cardWhite,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: PremiumColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hesabınızı Tamamlayın',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'İsminizi girin ve rolünüzü seçin.',
                style: GoogleFonts.inter(
                  fontSize: 14, color: PremiumColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: nameController,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: const Icon(Icons.person_outline, color: PremiumColors.pillBlue),
                  labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector
              Text(
                'Rolünüz',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleOption(
                      icon: Icons.person,
                      label: 'Hasta',
                      isSelected: selectedRole == UserRole.patient,
                      color: PremiumColors.pillBlue,
                      onTap: () => setSheetState(() => selectedRole = UserRole.patient),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleOption(
                      icon: Icons.health_and_safety,
                      label: 'Bakıcı',
                      isSelected: selectedRole == UserRole.caregiver,
                      color: PremiumColors.pillPurple,
                      onTap: () => setSheetState(() => selectedRole = UserRole.caregiver),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Complete Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showError('Lütfen isminizi girin.');
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      final appUser = await _authService.completeSocialRegistration(
                        name: name,
                        role: selectedRole,
                      );
                      if (mounted) _navigateToHome(appUser);
                    } catch (e) {
                      if (mounted) _showError('Kayıt hatası: $e');
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumColors.coralAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Devam Et',
                    style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w600,
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

  Widget _buildRoleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : PremiumColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : PremiumColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : PremiumColors.textTertiary),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: isSelected ? color : PremiumColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Guest Sign-In ─────────────────────────────────────────────

  Future<void> _signInAsGuest() async {
    // Show role selection bottom sheet for guest users
    final nameController = TextEditingController(text: 'Misafir');
    UserRole selectedRole = UserRole.patient;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: PremiumColors.cardWhite,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: PremiumColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Misafir Olarak Başla',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'İsminizi girin ve rolünüzü seçin.\nVerileriniz güvende tutulur.',
                style: GoogleFonts.inter(
                  fontSize: 14, color: PremiumColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: nameController,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: const Icon(Icons.person_outline, color: PremiumColors.pillBlue),
                  labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector
              Text(
                'Rolünüz',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleOption(
                      icon: Icons.person,
                      label: 'Hasta',
                      isSelected: selectedRole == UserRole.patient,
                      color: PremiumColors.pillBlue,
                      onTap: () => setSheetState(() => selectedRole = UserRole.patient),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleOption(
                      icon: Icons.health_and_safety,
                      label: 'Bakıcı',
                      isSelected: selectedRole == UserRole.caregiver,
                      color: PremiumColors.pillPurple,
                      onTap: () => setSheetState(() => selectedRole = UserRole.caregiver),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showError('Lütfen isminizi girin.');
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      final appUser = await _authService.signInAsGuest(
                        name: name,
                        role: selectedRole,
                      );
                      if (mounted) _navigateToHome(appUser);
                    } catch (e) {
                      if (mounted) _showError('Giriş hatası: $e');
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'Başla',
                    style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumColors.greenCheck,
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

  // ─── Navigation ───────────────────────────────────────────────

  void _navigateToHome(AppUser user) {
    if (user.role == UserRole.patient) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PatientHomeScreen(patientUid: user.uid),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CaregiverDashboard(caregiverUid: user.uid),
        ),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [PremiumColors.coralAccent, Color(0xFFFF8A80)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: PremiumColors.coralAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'İlaç Dostu',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: PremiumColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hesabınıza giriş yapın',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: const Icon(Icons.email_outlined, color: PremiumColors.pillBlue),
                      labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                      if (!v.contains('@')) return 'Geçerli e-posta girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline, color: PremiumColors.pillBlue),
                      labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: PremiumColors.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre gerekli';
                      if (v.length < 6) return 'En az 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumColors.coralAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Giriş Yap',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Divider ────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: PremiumColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'veya',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: PremiumColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: PremiumColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Google Sign-In Button ──────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 22, height: 22,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata, size: 28, color: Colors.red,
                        ),
                      ),
                      label: Text(
                        'Google ile Giriş Yap',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: PremiumColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: PremiumColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Apple Sign-In Button ───────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 26, color: Colors.white),
                      label: Text(
                        'Apple ile Giriş Yap',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Guest Sign-In Button ───────────────────
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          PremiumColors.greenCheck.withValues(alpha: 0.08),
                          PremiumColors.pillBlue.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: PremiumColors.greenCheck.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _signInAsGuest,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 22,
                              color: PremiumColors.greenCheck,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Kayıt Olmadan Başla',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: PremiumColors.greenCheck,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hesabınız yok mu? ',
                        style: GoogleFonts.inter(
                          color: PremiumColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(
                          'Kayıt Ol',
                          style: GoogleFonts.inter(
                            color: PremiumColors.coralAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
