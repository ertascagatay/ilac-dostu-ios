import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../services/firestore_service.dart';
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

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesaptan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
        (route) => false,
      );
    }
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${med.name} alındı. Kalan: $newStockCount',
            style: const TextStyle(fontSize: 16),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'GERİ AL',
            textColor: Colors.yellow,
            onPressed: () async {
              await _firestoreService.updateMedication(
                patientUid: widget.patientUid,
                medicationId: med.id!,
                updates: {
                  'isTaken': false,
                  'stockCount': med.stockCount,
                },
              );
            },
          ),
        ),
      );
    }
  }

  void _showAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMedicationSheet(
        onSave: (name, timeOfDay, imagePath, stock) async {
          final medication = MedicationModel(
            name: name,
            time: timeOfDay == TimeOfDayType.morning ? '09:00' : '20:00',
            timeOfDay: timeOfDay,
            imagePath: imagePath,
            stockCount: stock,
          );

          await _firestoreService.addMedication(
            patientUid: widget.patientUid,
            medication: medication,
          );
        },
      ),
    );
  }

  void _deleteMedication(MedicationModel med) {
    if (med.id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Silme Onayı'),
        content: Text('${med.name} adlı ilacı silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestoreService.deleteMedication(
                patientUid: widget.patientUid,
                medicationId: med.id!,
              );
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'İlaç Dostu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Benim Kodum:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.patientUid,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.patientUid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kod kopyalandı!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Çıkış Yap',
              ),
            ],
          ),
          StreamBuilder<List<MedicationModel>>(
            stream: _firestoreService.getMedicationsStream(widget.patientUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Hata: ${snapshot.error}')),
                );
              }

              final medications = snapshot.data ?? [];

              if (medications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        const Text(
                          'Henüz ilaç eklenmedi',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '+ butonuna basarak ilaç ekleyin',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final morningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.morning).toList();
              final eveningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.evening).toList();

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (morningMeds.isNotEmpty) ...[
                      _SectionHeader(title: 'Sabah İlaçları', icon: Icons.wb_sunny_rounded),
                      ...morningMeds.map((med) => _TeslaMedicationCard(
                        medication: med,
                        onTap: () => _toggleMedication(med),
                        onDelete: () => _deleteMedication(med),
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (eveningMeds.isNotEmpty) ...[
                      _SectionHeader(title: 'Akşam İlaçları', icon: Icons.nights_stay_rounded),
                      ...eveningMeds.map((med) => _TeslaMedicationCard(
                        medication: med,
                        onTap: () => _toggleMedication(med),
                        onDelete: () => _deleteMedication(med),
                      )),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationSheet,
        backgroundColor: const Color(0xFF1E88E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'İlaç Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeslaMedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TeslaMedicationCard({
    required this.medication,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final med = medication;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    if (med.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(med.imagePath!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF1E88E5),
                          size: 32,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: med.isTaken ? TextDecoration.lineThrough : null,
                              color: med.isTaken ? Colors.grey : const Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                med.time,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${med.stockCount} adet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: med.stockCount < 5 ? Colors.red : Colors.grey[600],
                                  fontWeight: med.stockCount < 5 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (med.isTaken)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 32,
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: onDelete,
                      ),
                  ],
                ),
                if (!med.isTaken && med.stockCount < 5) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stok azaldı! Eczaneye gidin.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  final Function(String, TimeOfDayType, String?, int) onSave;

  const _AddMedicationSheet({required this.onSave});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  TimeOfDayType _selectedTime = TimeOfDayType.morning;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yeni İlaç Ekle',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _imagePath == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Fotoğraf Çek', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'İlaç Adı',
              prefixIcon: Icon(Icons.medication_rounded),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kutu İçeriği (Adet)',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  label: 'Sabah',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: _selectedTime == TimeOfDayType.morning,
                  onTap: () => setState(() => _selectedTime = TimeOfDayType.morning),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeChip(
                  label: 'Akşam',
                  icon: Icons.nights_stay_rounded,
                  isSelected: _selectedTime == TimeOfDayType.evening,
                  onTap: () => setState(() => _selectedTime = TimeOfDayType.evening),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  final int stock = int.tryParse(_stockController.text) ?? 30;
                  widget.onSave(
                    _nameController.text.trim(),
                    _selectedTime,
                    _imagePath,
                    stock,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
