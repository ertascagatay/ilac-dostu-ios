import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../models/measurement_model.dart';
import '../services/firestore_service.dart';
import '../widgets/daily_medication_card.dart';
import '../widgets/vital_signs_dialog.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientUid;

  const PatientHomeScreen({super.key, required this.patientUid});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _userName = '';
  DateTime _selectedDate = DateTime.now();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadUserName();
  }



  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Kullanıcı';
    });
  }



  void _toggleMedication(MedicationModel med) async {
    if (med.id == null) return;

    final newIsTaken = !med.isTaken;
    final newStockCount = newIsTaken ? med.stockCount - 1 : med.stockCount + 1;

    final Map<String, dynamic> updates = {
      'isTaken': newIsTaken,
      'stockCount': newStockCount,
    };

    // Cancel caregiver alert when medication is taken
    if (newIsTaken) {
      updates['caregiverAlertTime'] = null;
    }

    await _firestoreService.updateMedication(
      patientUid: widget.patientUid,
      medicationId: med.id!,
      updates: updates,
    );

    if (newIsTaken) {
      await _firestoreService.logMedicationTaken(
        patientUid: widget.patientUid,
        medication: med.copyWith(stockCount: newStockCount),
      );

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

  // ─── Notification Prompt ─────────────────────────────────────────

  Future<void> _showNotificationPrompt() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: PremiumColors.cardWhite,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PremiumColors.pillBlue.withOpacity(0.15),
                      PremiumColors.pillPurple.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: PremiumColors.pillBlue,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bildirimler',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bildirimleri açmak ister misiniz?\nİlaç saatiniz geldiğinde hatırlatma alın.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: PremiumColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: PremiumColors.divider.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Hayır',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: PremiumColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: PremiumColors.pillBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Evet',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await Permission.notification.request();
    }
  }

  // ─── Caregiver Alert Time Helper ────────────────────────────────

  DateTime _computeAlertTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    return scheduledTime.add(const Duration(minutes: 30));
  }

  // ─── Add Medication Dialog ──────────────────────────────────────

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    TimeOfDayType selectedTimeOfDay = TimeOfDayType.morning;
    HungerStatus selectedHungerStatus = HungerStatus.neutral;
    MedicationFrequency selectedFrequency = MedicationFrequency.everyday;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: PremiumColors.cardWhite,
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: PremiumColors.coralAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_rounded, color: PremiumColors.coralAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'İlaç Ekle',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'İlaç Adı',
                    labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.medication_outlined, color: PremiumColors.pillBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Saat',
                    labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.access_time, color: PremiumColors.pillBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MedicationFrequency>(
                  value: selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Sıklık',
                    labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.repeat_rounded, color: PremiumColors.pillPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: MedicationFrequency.everyday, child: Text('Günde 1 kez (Her gün)')),
                    DropdownMenuItem(value: MedicationFrequency.twiceDaily, child: Text('Günde 2 kez')),
                    DropdownMenuItem(value: MedicationFrequency.threeTimesDaily, child: Text('Günde 3 kez')),
                    DropdownMenuItem(value: MedicationFrequency.fourTimesDaily, child: Text('Günde 4 kez')),
                    DropdownMenuItem(value: MedicationFrequency.everyOtherDay, child: Text('Gün aşırı (2 günde bir)')),
                    DropdownMenuItem(value: MedicationFrequency.weekly, child: Text('Haftada 1 kez')),
                    DropdownMenuItem(value: MedicationFrequency.twiceWeekly, child: Text('Haftada 2 kez')),
                    DropdownMenuItem(value: MedicationFrequency.monthly, child: Text('Ayda 1 kez')),
                    DropdownMenuItem(value: MedicationFrequency.asNeeded, child: Text('İhtiyaç halinde')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedFrequency = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TimeOfDayType>(
                  value: selectedTimeOfDay,
                  decoration: InputDecoration(
                    labelText: 'Zaman',
                    labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.wb_sunny_outlined, color: PremiumColors.pillAmber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: TimeOfDayType.morning, child: Text('Sabah')),
                    DropdownMenuItem(value: TimeOfDayType.evening, child: Text('Akşam')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedTimeOfDay = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HungerStatus>(
                  value: selectedHungerStatus,
                  decoration: InputDecoration(
                    labelText: 'Mide Durumu',
                    labelStyle: GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.restaurant, color: PremiumColors.greenCheck),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: HungerStatus.empty, child: Text('Aç')),
                    DropdownMenuItem(value: HungerStatus.full, child: Text('Tok')),
                    DropdownMenuItem(value: HungerStatus.neutral, child: Text('Fark Etmez')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedHungerStatus = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'İptal',
                style: GoogleFonts.inter(color: PremiumColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final timeStr = timeController.text.trim();
                final alertTime = _computeAlertTime(timeStr);

                final med = MedicationModel(
                  name: name,
                  time: timeStr,
                  timeOfDay: selectedTimeOfDay,
                  hungerStatus: selectedHungerStatus,
                  frequency: selectedFrequency,
                  isTaken: false,
                  stockCount: 30,
                  createdAt: DateTime.now(),
                  caregiverAlertTime: alertTime,
                );

                await _firestoreService.addMedication(
                  patientUid: widget.patientUid,
                  medication: med,
                );

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name eklendi ✓'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PremiumColors.greenCheck,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );

                  // Show notification opt-in prompt
                  _showNotificationPrompt();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.coralAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      body: SafeArea(
        child: _buildHomeTab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        backgroundColor: PremiumColors.coralAccent,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  // ─── Tab 0: Home ───────────────────────────────────────────────

  Widget _buildHomeTab() {
    return StreamBuilder<List<MedicationModel>>(
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

        final rawMedications = snapshot.data ?? [];
        final medications = rawMedications.where((med) {
          final start = DateTime(med.createdAt.year, med.createdAt.month, med.createdAt.day);
          final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          if (target.isBefore(start)) return false;

          final daysDiff = target.difference(start).inDays;
          switch (med.frequency) {
            case MedicationFrequency.everyday: return true;
            case MedicationFrequency.everyOtherDay: return daysDiff % 2 == 0;
            case MedicationFrequency.weekly: return daysDiff % 7 == 0;
            case MedicationFrequency.twiceWeekly: return daysDiff % 7 == 0 || daysDiff % 7 == 3;
            case MedicationFrequency.monthly: return target.day == start.day;
            default: return true;
          }
        }).toList();

        return Column(
          children: [
            _buildGreetingHeader(),
            _buildDateDisplay(),
            _buildCalendarStrip(),
            const SizedBox(height: 8),
            _buildSectionHeader(),
            Expanded(
              child: medications.isEmpty
                  ? _buildEmptyMedicationsState()
                  : DailyMedicationCard(
                      medications: medications,
                      onToggleTaken: _toggleMedication,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMedicationsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: PremiumColors.coralAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 40,
                color: PremiumColors.coralAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz ilaç eklenmemiş',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: PremiumColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aşağıdaki "İlaç Ekle" butonuna\ntıklayarak ilaçlarınızı ekleyin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: PremiumColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Vitals ────────────────────────────────────────────

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
  // ─── Shared Widgets ────────────────────────────────────────────

  Widget _buildEmptyMedicationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_rounded, size: 64, color: PremiumColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Bugün için ilaç bulunamadı',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PremiumColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
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
          Expanded(
            child: Text(
              'Merhaba, $_userName 👋',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PremiumColors.textPrimary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: EasyDateTimeLine(
        initialDate: _selectedDate,
        onDateChange: (selectedDate) {
          setState(() => _selectedDate = selectedDate);
        },
        locale: "tr_TR",
        headerProps: const EasyHeaderProps(
          showHeader: false, 
        ),
        dayProps: EasyDayProps(
          height: 72,
          width: 56,
          dayStructure: DayStructure.dayNumDayStr,
          activeDayStyle: DayStyle(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: PremiumColors.darkNavy,
            ),
            dayNumStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            dayStrStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          inactiveDayStyle: DayStyle(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: Colors.transparent,
            ),
            dayNumStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: PremiumColors.textPrimary),
            dayStrStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: PremiumColors.textTertiary),
          ),
        ),
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
            'Günlük İlaçlarım',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PremiumColors.textPrimary,
            ),
          ),
        ],
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
  }
}
