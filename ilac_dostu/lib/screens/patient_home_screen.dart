import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../models/measurement_model.dart';
import '../services/firestore_service.dart';
import '../widgets/daily_medication_card.dart';
import '../widgets/vital_signs_dialog.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientUid;

  const PatientHomeScreen({super.key, required this.patientUid});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();
  String _userName = '';
  DateTime _selectedDate = DateTime.now();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadUserName();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Kullanıcı';
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _toggleMedication(MedicationModel med) async {
    if (med.id == null) return;

    final newIsTaken = !med.isTaken;
    final newStockCount = newIsTaken ? med.stockCount - 1 : med.stockCount + 1;

    await _firestoreService.updateMedication(
      patientUid: widget.patientUid,
      medicationId: med.id!,
      updates: {
        'isTaken': newIsTaken,
        'stockCount': newStockCount,
      },
    );

    if (newIsTaken) {
      await _firestoreService.logMedicationTaken(
        patientUid: widget.patientUid,
        medication: med.copyWith(stockCount: newStockCount),
      );

      _speak("Harika, ${med.name} alındı.");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} alındı. Kalan: $newStockCount'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PremiumColors.greenCheck,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showVitalSignsDialog(MeasurementType type) {
    showDialog(
      context: context,
      builder: (context) => VitalSignsDialog(
        patientUid: widget.patientUid,
        type: type,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      body: SafeArea(
        child: StreamBuilder<List<MedicationModel>>(
          stream: _firestoreService.getMedicationsStream(widget.patientUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: PremiumColors.coralAccent,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            }

            final medications = snapshot.data ?? [];

            return Column(
              children: [
                // --- Greeting Header ---
                _buildGreetingHeader(),

                // --- Date Display ---
                _buildDateDisplay(),

                // --- Calendar Strip ---
                _buildCalendarStrip(),

                const SizedBox(height: 8),

                // --- Section Header ---
                _buildSectionHeader(),

                // --- Medication List ---
                Expanded(
                  child: DailyMedicationCard(
                    medications: medications,
                    onToggleTaken: _toggleMedication,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildGreetingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PremiumColors.pillBlue.withOpacity(0.15),
              border: Border.all(
                color: PremiumColors.pillBlue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: PremiumColors.pillBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Greeting Text
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hey, ',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: PremiumColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: _userName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: PremiumColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: ' 👋', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
          // Settings gear
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(userUid: widget.patientUid),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PremiumColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: PremiumColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay() {
    final now = DateTime.now();
    final turkishMonths = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateStr = 'Bugün, ${now.day} ${turkishMonths[now.month]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          dateStr,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: PremiumColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    // Show 5 days centered on today
    final days = List.generate(5, (i) => now.add(Duration(days: i - 2)));

    final turkishDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          final isSelected = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? PremiumColors.darkNavy
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : PremiumColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    turkishDays[day.weekday - 1],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white70
                          : PremiumColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Yapılacaklar',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PremiumColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show vital signs options as a bottom sheet
              _showVitalsBottomSheet();
            },
            child: Row(
              children: [
                Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PremiumColors.coralAccent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.tune_rounded,
                  color: PremiumColors.coralAccent,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVitalsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: PremiumColors.cardWhite,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PremiumColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sağlık Durumu Gir',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PremiumColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildVitalButton(
                  icon: Icons.favorite,
                  label: 'Tansiyon',
                  color: PremiumColors.coralAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _showVitalSignsDialog(MeasurementType.bloodPressure);
                  },
                ),
                const SizedBox(width: 12),
                _buildVitalButton(
                  icon: Icons.water_drop,
                  label: 'Şeker',
                  color: PremiumColors.pillBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _showVitalSignsDialog(MeasurementType.bloodSugar);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVitalButton(
                  icon: Icons.monitor_weight,
                  label: 'Kilo',
                  color: PremiumColors.greenCheck,
                  onTap: () {
                    Navigator.pop(context);
                    _showVitalSignsDialog(MeasurementType.weight);
                  },
                ),
                const SizedBox(width: 12),
                _buildVitalButton(
                  icon: Icons.favorite_border,
                  label: 'Nabız',
                  color: PremiumColors.pillAmber,
                  onTap: () {
                    Navigator.pop(context);
                    _showVitalSignsDialog(MeasurementType.pulse);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: PremiumColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 0),
          _buildNavItem(Icons.chat_bubble_outline_rounded, 1),
          // Coral FAB
          GestureDetector(
            onTap: () => _showVitalsBottomSheet(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: PremiumColors.coralAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PremiumColors.coralAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          _buildNavItem(Icons.access_time_rounded, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          icon,
          color: isActive
              ? PremiumColors.darkNavy
              : PremiumColors.textTertiary,
          size: 26,
        ),
      ),
    );
  }
}
