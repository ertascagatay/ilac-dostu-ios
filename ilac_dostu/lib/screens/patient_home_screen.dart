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
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            // Tab 0: Home (Medications)
            _buildHomeTab(),
            // Tab 1: Vitals (Health)
            _buildVitalsTab(),
            // Tab 2: History
            _buildHistoryTab(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddMedicationDialog,
              backgroundColor: PremiumColors.coralAccent,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
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
        children: [
          const SizedBox(height: 16),
          Text(
            'Sağlık Durumu',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: PremiumColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ölçüm değerlerinizi kaydedin',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: PremiumColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildVitalButton(
                icon: Icons.favorite,
                label: 'Tansiyon',
                color: PremiumColors.coralAccent,
                onTap: () => _showVitalSignsDialog(MeasurementType.bloodPressure),
              ),
              const SizedBox(width: 12),
              _buildVitalButton(
                icon: Icons.water_drop,
                label: 'Şeker',
                color: PremiumColors.pillBlue,
                onTap: () => _showVitalSignsDialog(MeasurementType.bloodSugar),
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
                onTap: () => _showVitalSignsDialog(MeasurementType.weight),
              ),
              const SizedBox(width: 12),
              _buildVitalButton(
                icon: Icons.favorite_border,
                label: 'Nabız',
                color: PremiumColors.pillAmber,
                onTap: () => _showVitalSignsDialog(MeasurementType.pulse),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: History ───────────────────────────────────────────

  Widget _buildHistoryTab() {
    return StreamBuilder<List<MedicationModel>>(
      stream: _firestoreService.getMedicationsStream(widget.patientUid),
      builder: (context, snapshot) {
        final medications = snapshot.data ?? [];
        final taken = medications.where((m) => m.isTaken).toList();
        final notTaken = medications.where((m) => !m.isTaken).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Günlük Özet',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bugünkü ilaç durumunuz',
                style: GoogleFonts.inter(fontSize: 15, color: PremiumColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Alındı',
                      count: taken.length,
                      total: medications.length,
                      color: PremiumColors.greenCheck,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Bekliyor',
                      count: notTaken.length,
                      total: medications.length,
                      color: PremiumColors.coralAccent,
                      icon: Icons.pending_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (taken.isNotEmpty) ...[
                Text(
                  'Alınan İlaçlar ✓',
                  style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: PremiumColors.greenCheck,
                  ),
                ),
                const SizedBox(height: 8),
                ...taken.map((m) => _buildHistoryItem(m, true)),
                const SizedBox(height: 16),
              ],

              if (notTaken.isNotEmpty) ...[
                Text(
                  'Bekleyen İlaçlar',
                  style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: PremiumColors.coralAccent,
                  ),
                ),
                const SizedBox(height: 8),
                ...notTaken.map((m) => _buildHistoryItem(m, false)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            '$count / $total',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(MedicationModel med, bool isTaken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PremiumColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isTaken ? PremiumColors.greenCheck : PremiumColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              med.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: PremiumColors.textPrimary,
                decoration: isTaken ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            med.time,
            style: GoogleFonts.inter(fontSize: 13, color: PremiumColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────

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
                fontWeight: FontWeight.bold,
                color: PremiumColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final authService = AuthService();
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
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
                Icons.logout,
                color: PremiumColors.coralAccent,
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

  // ─── Bottom Navigation ─────────────────────────────────────────

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
          _buildNavItem(Icons.home_rounded, 'Anasayfa', 0),
          _buildNavItem(Icons.monitor_heart_outlined, 'Sağlık', 1),
          _buildNavItem(Icons.access_time_rounded, 'Özet', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? PremiumColors.darkNavy
                  : PremiumColors.textTertiary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? PremiumColors.darkNavy
                    : PremiumColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
