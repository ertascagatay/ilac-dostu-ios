import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.medication_rounded,
      iconColor: PremiumColors.coralAccent,
      gradientColors: [
        const Color(0xFF2D3142),
        const Color(0xFF3D4260),
      ],
      title: 'İlaç Dostu\'na\nHoş Geldiniz',
      subtitle:
          'Sevdiklerinizin ilaçlarını takip edin,\nsağlıklarını güvence altına alın.',
      accentColor: PremiumColors.coralAccent,
    ),
    _OnboardingSlide(
      icon: Icons.link_rounded,
      iconColor: PremiumColors.pillBlue,
      gradientColors: [
        const Color(0xFF1A3A5C),
        const Color(0xFF2D5F8A),
      ],
      title: 'Hasta ve Bakıcı\nBağlantısı',
      subtitle:
          '6 haneli kod ile hasta ve bakıcıyı\neşleştirin. Gerçek zamanlı takip başlasın!',
      accentColor: PremiumColors.pillBlue,
    ),
    _OnboardingSlide(
      icon: Icons.notifications_active_rounded,
      iconColor: PremiumColors.pillAmber,
      gradientColors: [
        const Color(0xFF3D2E1E),
        const Color(0xFF5C4A32),
      ],
      title: 'Asla İlaç\nUnutmayın',
      subtitle:
          'İlaç saatinde bildirim alın.\n30 dakika geçerse bakıcıya otomatik uyarı!',
      accentColor: PremiumColors.pillAmber,
    ),
  ];

  Future<void> _finishOnboarding() async {
    // Save flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    // Request notification permission
    await Permission.notification.request();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
            },
          ),

          // Skip button (top right)
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Geç',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

          // Bottom section: dots + button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? _slides[_currentPage].accentColor
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage].accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _currentPage < _slides.length - 1
                              ? 'Devam'
                              : 'Başla',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon container with glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: slide.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: slide.accentColor.withValues(alpha: 0.2),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  slide.icon,
                  size: 72,
                  color: slide.iconColor,
                ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // Subtitle
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white60,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
