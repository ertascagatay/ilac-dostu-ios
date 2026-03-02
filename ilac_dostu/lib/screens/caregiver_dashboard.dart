import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/measurement_model.dart';
import '../models/medication_log.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../services/barcode_service.dart';
import '../widgets/health_charts.dart';
import '../widgets/barcode_scanner_view.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'pairing_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  final String caregiverUid;

  const CaregiverDashboard({super.key, required this.caregiverUid});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  List<AppUser> _patients = [];
  bool _isLoading = true;
  String? _selectedPatientUid;
  String _caregiverName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
    _loadCaregiverName();
    _loadPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCaregiverName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caregiverName = prefs.getString('userName') ?? 'Bakıcı';
    });
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final patients =
        await _firestoreService.getCaregiverPatients(widget.caregiverUid);
    setState(() {
      _patients = patients;
      _isLoading = false;
      if (_patients.isNotEmpty && _selectedPatientUid == null) {
        _selectedPatientUid = _patients.first.uid;
      }
    });
  }

  Future<void> _exportPdfReport() async {
    if (_selectedPatientUid == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: PremiumColors.coralAccent,
          ),
        ),
      );

      final measurements = await _firestoreService
          .getMeasurementsStream(_selectedPatientUid!)
          .first;

      final logs = await _firestoreService
          .getMedicationLogsStream(_selectedPatientUid!)
          .first;

      final patient =
          _patients.firstWhere((p) => p.uid == _selectedPatientUid);

      final pdfFile = await PdfService.generateDoctorReport(
        patientName: patient.name,
        patientUid: _selectedPatientUid!,
        medicationLogs: logs,
        measurements: measurements,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      Navigator.of(context).pop();

      await PdfService.shareReport(pdfFile);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    TimeOfDayType selectedTimeOfDay = TimeOfDayType.morning;
    HungerStatus selectedHungerStatus = HungerStatus.neutral;
    MedicationFrequency selectedFrequency = MedicationFrequency.everyday;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: PremiumColors.cardWhite,
          title: Text(
            'İlaç Ekle',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: PremiumColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'İlaç Adı',
                    labelStyle:
                        GoogleFonts.inter(color: PremiumColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: PremiumColors.pillBlue),
                      onPressed: () async {
                        final barcode = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BarcodeScannerView(),
                          ),
                        );

                        if (barcode != null) {
                          final medName =
                              BarcodeService.lookupMedication(barcode);
                          if (medName != null) {
                            nameController.text = medName;
                          } else if (barcode.startsWith('869')) {
                            nameController.text = 'Demo İlaç';
                          } else {
                            nameController.text = barcode;
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Saat',
                    labelStyle:
                        GoogleFonts.inter(color: PremiumColors.textSecondary),
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
                    labelStyle:
                        GoogleFonts.inter(color: PremiumColors.textSecondary),
                    prefixIcon: const Icon(Icons.repeat_rounded,
                        color: PremiumColors.pillPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MedicationFrequency.everyday,
                      child: Text('Her gün'),
                    ),
                    DropdownMenuItem(
                      value: MedicationFrequency.twiceDaily,
                      child: Text('Günde 2 defa'),
                    ),
                    DropdownMenuItem(
                      value: MedicationFrequency.weekly,
                      child: Text('Haftada 1'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedFrequency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TimeOfDayType>(
                  value: selectedTimeOfDay,
                  decoration: InputDecoration(
                    labelText: 'Zaman',
                    labelStyle:
                        GoogleFonts.inter(color: PremiumColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TimeOfDayType.morning,
                      child: Text('Sabah'),
                    ),
                    DropdownMenuItem(
                      value: TimeOfDayType.evening,
                      child: Text('Akşam'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedTimeOfDay = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HungerStatus>(
                  value: selectedHungerStatus,
                  decoration: InputDecoration(
                    labelText: 'Mide Durumu',
                    labelStyle:
                        GoogleFonts.inter(color: PremiumColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: HungerStatus.empty,
                      child: Text('Aç'),
                    ),
                    DropdownMenuItem(
                      value: HungerStatus.full,
                      child: Text('Tok'),
                    ),
                    DropdownMenuItem(
                      value: HungerStatus.neutral,
                      child: Text('Fark Etmez'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedHungerStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'İptal',
                style: GoogleFonts.inter(color: PremiumColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final timeStr = timeController.text.trim();
                final parts = timeStr.split(':');
                final now = DateTime.now();
                final hour =
                    int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9;
                final minute =
                    int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                final scheduledTime =
                    DateTime(now.year, now.month, now.day, hour, minute);
                final alertTime =
                    scheduledTime.add(const Duration(minutes: 30));

                final medication = MedicationModel(
                  name: nameController.text,
                  time: timeStr,
                  timeOfDay: selectedTimeOfDay,
                  hungerStatus: selectedHungerStatus,
                  frequency: selectedFrequency,
                  caregiverAlertTime: alertTime,
                );

                await _firestoreService.addMedication(
                  patientUid: _selectedPatientUid!,
                  medication: medication,
                );

                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.coralAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Ekle',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: PremiumColors.background,
        body: Center(
          child: CircularProgressIndicator(color: PremiumColors.coralAccent),
        ),
      );
    }

    if (_patients.isEmpty) {
      return PairingScreen(caregiverUid: widget.caregiverUid);
    }

    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: _buildPremiumAppBar(),
      body: Column(
        children: [
          // Patient Selector (Minimalist)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: PremiumColors.background, 
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPatientUid,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: PremiumColors.textSecondary),
                items: _patients.map((patient) {
                  return DropdownMenuItem(
                    value: patient.uid,
                    child: Text(patient.name,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PremiumColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPatientUid = value);
                },
              ),
            ),
          ),

          // Premium Tab Bar (İlaçlar / Sağlık)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: PremiumColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: PremiumColors.darkNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: PremiumColors.textSecondary,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 14),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('İlaçlar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Sağlık'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TabBarView content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicationsTab(),
                _buildHealthTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddMedicationDialog,
              backgroundColor: PremiumColors.coralAccent,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          : null,
    );
  }

          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: PremiumColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Merhaba, $_caregiverName 👋',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: PremiumColors.textPrimary,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: PremiumColors.coralAccent, size: 28),
            onPressed: _exportPdfReport,
            tooltip: 'PDF Rapor',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    if (_selectedPatientUid == null) {
      return Center(
        child: Text('Hasta seçin',
            style: GoogleFonts.inter(color: PremiumColors.textSecondary)),
      );
    }

    return StreamBuilder<List<MedicationModel>>(
      stream: _firestoreService.getMedicationsStream(_selectedPatientUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(color: PremiumColors.coralAccent),
          );
        }

        final medications = snapshot.data ?? [];

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: PremiumColors.pillPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.medication_outlined,
                      size: 48, color: PremiumColors.pillPurple),
                ),
                const SizedBox(height: 24),
                Text(
                  'Henüz ilaç eklenmedi',
                  style: GoogleFonts.inter(
                      fontSize: 16, color: PremiumColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final takenCount = medications.where((m) => m.isTaken).length;
        final waitingCount = medications.length - takenCount;
        final progress = medications.isEmpty
            ? 0.0
            : takenCount / medications.length;

        return Column(
          children: [
            // Daily Progress Summary Cards
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PremiumColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today_rounded,
                          color: PremiumColors.pillBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bugünkü İlaçlar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PremiumColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (takenCount == medications.length)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PremiumColors.greenCheck.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tamamlandı ✓',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PremiumColors.greenCheck,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: PremiumColors.divider.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        takenCount == medications.length
                            ? PremiumColors.greenCheck
                            : PremiumColors.pillBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary cards row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: PremiumColors.greenCheck.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: PremiumColors.greenCheck.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: PremiumColors.greenCheck, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                '$takenCount / ${medications.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumColors.greenCheck,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Alındı',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PremiumColors.greenCheck,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: PremiumColors.coralAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  PremiumColors.coralAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.pending_rounded,
                                  color: PremiumColors.coralAccent, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                '$waitingCount',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumColors.coralAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bekliyor',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PremiumColors.coralAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Medication list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  final med = medications[index];
                  final borderColor = med.isTaken
                      ? PremiumColors.greenCheck
                      : PremiumColors
                          .pillColors[index % PremiumColors.pillColors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: med.isTaken
                          ? PremiumColors.greenCheck.withOpacity(0.06)
                          : PremiumColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Colored left border
                          Container(
                            width: 5,
                            decoration: BoxDecoration(
                              color: borderColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                          // Status icon
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: med.isTaken
                                    ? PremiumColors.greenCheck.withOpacity(0.15)
                                    : borderColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                med.isTaken
                                    ? Icons.check_circle_rounded
                                    : Icons.medication_rounded,
                                color: med.isTaken
                                    ? PremiumColors.greenCheck
                                    : borderColor,
                                size: 22,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.only(left: 4, right: 8),
                              title: Text(
                                med.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: med.isTaken
                                      ? PremiumColors.greenCheck
                                      : PremiumColors.textPrimary,
                                  decoration: med.isTaken
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                med.isTaken
                                    ? '${med.time} · Alındı ✓'
                                    : '${med.time} - ${med.hungerStatusDisplay}',
                                style: GoogleFonts.inter(
                                  color: med.isTaken
                                      ? PremiumColors.greenCheck
                                      : PremiumColors.textTertiary,
                                  fontSize: 13,
                                  fontWeight: med.isTaken
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          // Status badge + delete
                          if (med.isTaken)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      PremiumColors.greenCheck.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Alındı',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PremiumColors.greenCheck,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: PremiumColors.coralAccent
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Bekliyor',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: PremiumColors.coralAccent,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: PremiumColors.coralAccent,
                                      size: 20),
                                  onPressed: () async {
                                    if (med.id != null) {
                                      await _firestoreService.deleteMedication(
                                        patientUid: _selectedPatientUid!,
                                        medicationId: med.id!,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthTab() {
    if (_selectedPatientUid == null) {
      return Center(
        child: Text('Hasta seçin',
            style: GoogleFonts.inter(color: PremiumColors.textSecondary)),
      );
    }

    return StreamBuilder<List<MeasurementModel>>(
      stream: _firestoreService.getMeasurementsStream(_selectedPatientUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(color: PremiumColors.coralAccent),
          );
        }

        final measurements = snapshot.data ?? [];

        return HealthChartsWidget(measurements: measurements);
      },
    );
  }
}
