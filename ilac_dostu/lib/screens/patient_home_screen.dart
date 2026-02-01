import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/medication_model.dart';
import '../models/measurement_model.dart';
import '../services/firestore_service.dart';
import '../widgets/daily_medication_card.dart';
import '../widgets/vital_signs_dialog.dart';
import 'mode_selection_screen.dart';

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
          backgroundColor: const Color(0xFF4CAF50),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: Text(
          '${_getGreeting()}, $_userName',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded,
                color: Colors.white, size: 32),
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
        ],
      ),
      body: StreamBuilder<List<MedicationModel>>(
        stream: _firestoreService.getMedicationsStream(widget.patientUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final medications = snapshot.data ?? [];

          return Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          icon: Icons.medication,
                          label: 'Toplam İlaç',
                          value: '${medications.length}',
                        ),
                        _buildStatCard(
                          icon: Icons.check_circle,
                          label: 'Alınan',
                          value:
                              '${medications.where((m) => m.isTaken).length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Vital Signs Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: Color(0xFF6C63FF), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Sağlık Durumu Gir',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildVitalButton(
                          icon: Icons.favorite,
                          label: 'Tansiyon',
                          color: const Color(0xFFFF6B6B),
                          onTap: () => _showVitalSignsDialog(
                              MeasurementType.bloodPressure),
                        ),
                        const SizedBox(width: 12),
                        _buildVitalButton(
                          icon: Icons.water_drop,
                          label: 'Şeker',
                          color: const Color(0xFF6C63FF),
                          onTap: () => _showVitalSignsDialog(
                              MeasurementType.bloodSugar),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildVitalButton(
                          icon: Icons.monitor_weight,
                          label: 'Kilo',
                          color: const Color(0xFF4CAF50),
                          onTap: () =>
                              _showVitalSignsDialog(MeasurementType.weight),
                        ),
                        const SizedBox(width: 12),
                        _buildVitalButton(
                          icon: Icons.favorite_border,
                          label: 'Nabız',
                          color: const Color(0xFFFF9800),
                          onTap: () =>
                              _showVitalSignsDialog(MeasurementType.pulse),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Medications List
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
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
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
