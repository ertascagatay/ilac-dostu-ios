import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/medication_model.dart';
import '../services/firestore_service.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientUid;

  const PatientHomeScreen({super.key, required this.patientUid});

  @override
  State&lt;PatientHomeScreen&gt; createState() =&gt; _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State&lt;PatientHomeScreen&gt; {
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future&lt;void&gt; _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
  }

  Future&lt;void&gt; _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _toggleMedication(MedicationModel med) async {
    if (med.id == null) return;

    final newIsTaken = !med.isTaken;
    final newStockCount = newIsTaken ? med.stockCount - 1 : med.stockCount + 1;

    // Update in Firestore
    await _firestoreService.updateMedication(
      patientUid: widget.patientUid,
      medicationId: med.id!,
      updates: {
        'isTaken': newIsTaken,
        'stockCount': newStockCount,
      },
    );

    if (newIsTaken) {
      // Log the medication
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
            style: const TextStyle(fontSize: 20),
          ),
          duration: const Duration(seconds: 4),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) =&gt; _AddMedicationSheet(
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
      builder: (ctx) =&gt; AlertDialog(
        title: const Text('Silme Onayı', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        content: Text(
          '${med.name} adlı ilacı silmek istiyor musunuz?',
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () =&gt; Navigator.of(ctx).pop(),
            child: const Text('HAYIR', style: TextStyle(fontSize: 24, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteMedication(
                patientUid: widget.patientUid,
                medicationId: med.id!,
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('EVET', style: TextStyle(fontSize: 24, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Dostu'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Patient Code Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Benim Kodum:',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.patientUid,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 32),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.patientUid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kod kopyalandı!')),
                        );
                      },
                    ),
                  ],
                ),
                const Text(
                  'Bakıcınıza bu kodu verin',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Medications List
          Expanded(
            child: StreamBuilder&lt;List&lt;MedicationModel&gt;&gt;(
              stream: _firestoreService.getMedicationsStream(widget.patientUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}', style: const TextStyle(fontSize: 20)),
                  );
                }

                final medications = snapshot.data ?? [];

                if (medications.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz ilaç eklenmedi.\n+ butonuna basın.',
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final morningMeds = medications.where((m) =&gt; m.timeOfDay == TimeOfDayType.morning).toList();
                final eveningMeds = medications.where((m) =&gt; m.timeOfDay == TimeOfDayType.evening).toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (morningMeds.isNotEmpty) ...[ 
                      const _SectionHeader(title: 'Sabah'),
                      ...morningMeds.map((med) =&gt; _MedicationCard(
                        medication: med,
                        onTap: () =&gt; _toggleMedication(med),
                        onDelete: () =&gt; _deleteMedication(med),
                      )),
                    ],
                    const SizedBox(height: 32),
                    if (eveningMeds.isNotEmpty) ...[
                      const _SectionHeader(title: 'Akşam'),
                      ...eveningMeds.map((med) =&gt; _MedicationCard(
                        medication: med,
                        onTap: () =&gt; _toggleMedication(med),
                        onDelete: () =&gt; _deleteMedication(med),
                      )),
                    ],
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: _showAddMedicationSheet,
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.add, size: 48, color: Colors.white),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final med = medication;
    final isMorning = med.timeOfDay == TimeOfDayType.morning;

    Color backgroundColor;
    if (med.isTaken) {
      backgroundColor = const Color(0xFF2E7D32);
    } else {
      backgroundColor = isMorning ? Colors.lightBlue.shade50 : Colors.deepPurple.shade50;
    }

    final IconData iconData = isMorning ? Icons.wb_sunny : Icons.nights_stay;
    final Color iconColor = med.isTaken ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        color: backgroundColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (med.imagePath != null)
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: FileImage(File(med.imagePath!)),
                      backgroundColor: Colors.transparent,
                    )
                  else
                    Icon(iconData, size: 48, color: iconColor),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            decoration: med.isTaken ? TextDecoration.lineThrough : null,
                            color: med.isTaken ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          med.time,
                          style: TextStyle(
                            fontSize: 24,
                            decoration: med.isTaken ? TextDecoration.lineThrough : null,
                            color: med.isTaken ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (med.isTaken)
                    const Icon(Icons.check_circle, size: 64, color: Colors.white)
                  else
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                      onPressed: onDelete,
                    ),
                ],
              ),
              if (!med.isTaken && med.stockCount < 5) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "⚠️ Az Kaldı! Eczaneye Gidin.",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  final Function(String, TimeOfDayType, String?, int) onSave;

  const _AddMedicationSheet({required this.onSave});

  @override
  State&lt;_AddMedicationSheet&gt; createState() =&gt; _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State&lt;_AddMedicationSheet&gt; {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  TimeOfDayType _selectedTime = TimeOfDayType.morning;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future&lt;void&gt; _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                child: _imagePath == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(
              hintText: 'İlaç Adı Girin',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _stockController,
            style: const TextStyle(fontSize: 24),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Kutu İçeriği (Adet)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TimeOptionButton(
                  title: 'Sabah',
                  isSelected: _selectedTime == TimeOfDayType.morning,
                  onTap: () =&gt; setState(() =&gt; _selectedTime = TimeOfDayType.morning),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeOptionButton(
                  title: 'Akşam',
                  isSelected: _selectedTime == TimeOfDayType.evening,
                  onTap: () =&gt; setState(() =&gt; _selectedTime = TimeOfDayType.evening),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 64,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('KAYDET', style: TextStyle(fontSize: 28, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimeOptionButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeOptionButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
