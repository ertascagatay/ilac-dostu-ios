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
          child: CircularProgressIndicator(),
        ),
      );

      final measurements = await _firestoreService
          .getMeasurementsStream(_selectedPatientUid!)
          .first;

      final logs = await _firestoreService
          .getMedicationLogsStream(_selectedPatientUid!)
          .first;

      final patient = _patients.firstWhere((p) => p.uid == _selectedPatientUid);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('İlaç Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'İlaç Adı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final barcode = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BarcodeScannerView(),
                          ),
                        );

                        if (barcode != null) {
                          final medName = BarcodeService.lookupMedication(barcode);
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TimeOfDayType>(
                  value: selectedTimeOfDay,
                  decoration: InputDecoration(
                    labelText: 'Zaman',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              child: const Text('İptal'),
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
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: const Text('Ekle'),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_patients.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Merhaba, $_caregiverName'),
          backgroundColor: const Color(0xFF6C63FF),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Henüz hasta eklenmedi',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: Text(
          'Bakıcı Paneli',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdfReport,
            tooltip: 'PDF Rapor',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: 'İlaçlar'),
            Tab(icon: Icon(Icons.show_chart), text: 'Sağlık'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Patient Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _selectedPatientUid,
              decoration: InputDecoration(
                labelText: 'Hasta Seçin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem(
                  value: patient.uid,
                  child: Text(patient.name),
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
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add),
              label: const Text('İlaç Ekle'),
            )
          : null,
    );
  }

  Widget _buildMedicationsTab() {
    if (_selectedPatientUid == null) {
      return const Center(child: Text('Hasta seçin'));
    }

    return StreamBuilder<List<MedicationModel>>(
      stream: _firestoreService.getMedicationsStream(_selectedPatientUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medications = snapshot.data ?? [];

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined,
                    size: 100, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'Henüz ilaç eklenmedi',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                title: Text(
                  med.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${med.time} - ${med.hungerStatusDisplay}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
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
            );
          },
        );
      },
    );
  }

  Widget _buildHealthTab() {
    if (_selectedPatientUid == null) {
      return const Center(child: Text('Hasta seçin'));
    }

    return StreamBuilder<List<MeasurementModel>>(
      stream: _firestoreService.getMeasurementsStream(_selectedPatientUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final measurements = snapshot.data ?? [];

        return HealthChartsWidget(measurements: measurements);
      },
    );
  }
}
