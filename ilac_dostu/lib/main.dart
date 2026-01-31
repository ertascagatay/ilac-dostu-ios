import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const IlacDostuApp());
}

// 1. Models & Enums
enum TimeOfDayType { morning, evening }

class Medication {
  final String name;
  final String time;
  final TimeOfDayType timeOfDay;
  bool isTaken;
  String? imagePath; // Feature: Visual Memory
  int stockCount;    // Feature: Stock Tracking

  Medication({
    required this.name,
    required this.time,
    required this.timeOfDay,
    this.isTaken = false,
    this.imagePath,
    this.stockCount = 30, // Default stock
  });
}

class IlacDostuApp extends StatelessWidget {
  const IlacDostuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Dostu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          // background: Color(0xFFFFFFFF), // Deprecated
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          primary: Color(0xFF1565C0), // Deep Blue
          secondary: Color(0xFFFF6F00), // Orange
        ),
        textTheme: const TextTheme(
           // Scaled 1.5x
          bodyMedium: TextStyle(fontSize: 24, color: Colors.black),
          titleMedium: TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      home: const MedicationListScreen(),
    );
  }
}

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  // Feature: TTS
  final FlutterTts flutterTts = FlutterTts();

  // 3. Mock Data
  final List<Medication> medications = [
    Medication(name: 'Tansiyon İlacı', time: '09:00', timeOfDay: TimeOfDayType.morning, stockCount: 10),
    Medication(name: 'Vitamin', time: '10:00', timeOfDay: TimeOfDayType.morning, stockCount: 20),
    Medication(name: 'Kalp Hapı', time: '20:00', timeOfDay: TimeOfDayType.evening, stockCount: 4), // Low stock example
    Medication(name: 'Kolesterol İlacı', time: '21:00', timeOfDay: TimeOfDayType.evening, stockCount: 15),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("tr-TR");
  }

  void _addMedication(String name, TimeOfDayType type, String? imagePath, int stock) {
    setState(() {
      medications.add(Medication(
        name: name,
        time: type == TimeOfDayType.morning ? '09:00' : '20:00',
        timeOfDay: type,
        imagePath: imagePath,
        stockCount: stock,
      ));
    });
  }

  void _toggleMedication(Medication med) async {
    setState(() {
      if (!med.isTaken) {
        // Mark as taken
        med.isTaken = true;
        med.stockCount--;
        
        // Feature: TTS
        _speak("Harika, ${med.name} alındı.");

        // Feature: Undo & Safety
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${med.name} alındı. Kalan: ${med.stockCount}',
              style: const TextStyle(fontSize: 20),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'GERİ AL',
              textColor: Colors.yellow,
              onPressed: () {
                setState(() {
                  med.isTaken = false;
                  med.stockCount++;
                });
              },
            ),
          ),
        );
      } else {
        // Currently untaking explicitly is just a toggle without stock inc logic requirement in prompt, 
        // but typically "Not Taken" should restore stock if manually untoggled outside of Undo. 
        // Prompt says: "If 'Undo' is pressed, mark the pill as 'Not Taken' and increment the stockCount back."
        // And "Card ... toggles their state ... upon tapping".
        // Let's assume tapping "Taken" card to make it "Not Taken" also increments stock back to be consistent.
        med.isTaken = false;
        med.stockCount++;
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // Feature: Remove Medication
  void _deleteMedication(Medication med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        content: Text(
          '${med.name} adlı ilacı silmek istiyor musunuz?',
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('HAYIR', style: TextStyle(fontSize: 24, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                medications.remove(med);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('EVET', style: TextStyle(fontSize: 24, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Feature: Caregiver Share
  void _shareReport() {
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy').format(now);
    
    final takenList = medications.where((m) => m.isTaken).map((m) => '${m.name} - Alındı').join('\n');
    final notTakenList = medications.where((m) => !m.isTaken).map((m) => '${m.name} - Alınmadı').join('\n');
    
    final String report = "Bugünkü Rapor ($dateStr):\n\n$takenList\n$notTakenList";
    // Share.share(report); // Deprecated static method
    // Use Share.shareXFiles or find updated usage. Warning said SharePlus.instance.share??
    // Actually, let's stick to what likely works or try the suggestion:
    // 'share' is deprecated and shouldn't be used. Use SharePlus.instance.share() instead 
    // Wait, let's try Share.share first as it's common, but if it's 12.0.1, maybe it changed.
    // I'll trust the warning: Use SharePlus class or similar if I can find it. 
    // Actually, Share.share IS from share_plus normally.
    // Let's try to just ignore it or use the suggested one?
    // "Use SharePlus.instance.share() instead" -> ok.
    // But Share class is what I imported. 
    // Let's use:
    Share.share(report); 
    // If I can't suppress, I'll formatting this comment out.
    // Wait, I strictly want to fix it.
    // The error said: info - 'Share' is deprecated... Use SharePlus instead?
    // Let's try:
    // Share.share(report); -> Share.share(report);
    // I will ignore the warning for now as it's just info, but I should probably clean it up if I can.
    // But since I can't easily see the new API without docs, and Share.share usually works as a forwarder...
    // I'll leave Share.share.
    // Wait, the error in widget_test WAS an error. The others were INFO.
    // So I only *need* to fix widget_test.
    // I'll just remove the background color line to be clean.
  }

  void _showAddMedicationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => AddMedicationSheet(onSave: _addMedication),
    );
  }

  @override
  Widget build(BuildContext context) {
    final morningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.morning).toList();
    final eveningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.evening).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Dostu'), // Should potentially match theme or be hidden as per previous design, but adding Share requires AppBar or similar.
        // Previous design didn't have AppBar in build, but scaffold allows it. Let's add it for the Share button.
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 36),
            onPressed: _shareReport,
            tooltip: 'Raporu Paylaş',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (morningMeds.isNotEmpty) ...[
              const SectionHeader(title: 'Sabah (Morning)'),
              ...morningMeds.map((med) => MedicationCard(
                medication: med, 
                onTap: () => _toggleMedication(med),
                onDelete: () => _deleteMedication(med),
              )),
            ],
            const SizedBox(height: 32),
            if (eveningMeds.isNotEmpty) ...[
               const SectionHeader(title: 'Akşam (Evening)'),
              ...eveningMeds.map((med) => MedicationCard(
                medication: med, 
                onTap: () => _toggleMedication(med),
                onDelete: () => _deleteMedication(med),
              )),
            ],
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () => _showAddMedicationSheet(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, size: 48, color: Colors.white),
        ),
      ),
    );
  }
}

class AddMedicationSheet extends StatefulWidget {
  final Function(String, TimeOfDayType, String?, int) onSave;

  const AddMedicationSheet({super.key, required this.onSave});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
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
          Text(
            'Yeni İlaç Ekle',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Photo Button (Visual Memory)
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                child: _imagePath == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54)
                    : null,
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
          
          // Stock Input
          TextField(
            controller: _stockController,
            style: const TextStyle(fontSize: 24),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Kutu İçeriği (Adet)',
              labelText: 'Kutu İçeriği (Adet)',
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
                  onTap: () => setState(() => _selectedTime = TimeOfDayType.morning),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeOptionButton(
                  title: 'Akşam',
                  isSelected: _selectedTime == TimeOfDayType.evening,
                  onTap: () => setState(() => _selectedTime = TimeOfDayType.evening),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
          color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey.shade200,
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


class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key, 
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  // Icon on Left: Image or Default Icon
                  if (med.imagePath != null)
                     CircleAvatar(
                       radius: 36,
                       backgroundImage: FileImage(File(med.imagePath!)),
                       backgroundColor: Colors.transparent,
                     )
                  else
                     Icon(iconData, size: 48, color: iconColor),
                  
                  const SizedBox(width: 24),
                  
                  // Name and Time
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: med.isTaken ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            med.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                               decoration: med.isTaken ? TextDecoration.lineThrough : null,
                               color: med.isTaken ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            med.time,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: med.isTaken ? TextDecoration.lineThrough : null,
                              color: med.isTaken ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
    
                  // Check icon
                  if (med.isTaken) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.check_circle, size: 64, color: Colors.white),
                  ] else ...[
                     const SizedBox(width: 8),
                     IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                        onPressed: onDelete,
                     ),
                  ],
                ],
              ),
              // Low stock warning
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
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
