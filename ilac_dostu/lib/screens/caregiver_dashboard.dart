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
import 'mode_selection_screen.dart';

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

                final medication = MedicationModel(
                  name: nameController.text,
                  time: timeController.text,
                  timeOfDay: selectedTimeOfDay,
                  hungerStatus: selectedHungerStatus,
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
      return Scaffold(
        backgroundColor: PremiumColors.background,
        appBar: _buildPremiumAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: PremiumColors.pillBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.person_add_rounded,
                    size: 52, color: PremiumColors.pillBlue),
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz hasta eklenmedi',
                style: GoogleFonts.inter(
                    fontSize: 18, color: PremiumColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: _buildPremiumAppBar(),
      body: Column(
        children: [
          // Premium Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

          // Patient Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            child: DropdownButtonFormField<String>(
              value: _selectedPatientUid,
              decoration: InputDecoration(
                labelText: 'Hasta Seçin',
                labelStyle:
                    GoogleFonts.inter(color: PremiumColors.textSecondary),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem(
                  value: patient.uid,
                  child: Text(patient.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: PremiumColors.textPrimary)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPatientUid = value);
              },
            ),
          ),

          // TabBarView
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddMedicationDialog,
              backgroundColor: PremiumColors.coralAccent,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('İlaç Ekle',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white)),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: PremiumColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bakıcı Paneli',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: PremiumColors.textPrimary,
            ),
          ),
          Text(
            'Merhaba, $_caregiverName 👋',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: PremiumColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
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
          child: IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: PremiumColors.coralAccent),
            onPressed: _exportPdfReport,
            tooltip: 'PDF Rapor',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
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
          child: IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: PremiumColors.textSecondary),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const ModeSelectionScreen()),
                (route) => false,
              );
            },
            tooltip: 'Çıkış',
          ),
        ),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final med = medications[index];
            final borderColor = PremiumColors
                .pillColors[index % PremiumColors.pillColors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    // Pill icon
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.medication_rounded,
                            color: borderColor, size: 22),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 4, right: 8),
                        title: Text(
                          med.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: PremiumColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${med.time} - ${med.hungerStatusDisplay}',
                          style: GoogleFonts.inter(
                              color: PremiumColors.textTertiary, fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: PremiumColors.coralAccent),
                          onPressed: () async {
                            if (med.id != null) {
                              await _firestoreService.deleteMedication(
                                patientUid: _selectedPatientUid!,
                                medicationId: med.id!,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
