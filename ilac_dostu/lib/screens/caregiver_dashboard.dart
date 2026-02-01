import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log.dart';
import '../services/firestore_service.dart';
import 'mode_selection_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  final String caregiverUid;

  const CaregiverDashboard({super.key, required this.caregiverUid});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  List<AppUser> _patients = [];
  bool _isLoading = true;
  String? _selectedPatientUid;
  String _caregiverName = '';

  @override
  void initState() {
    super.initState();
    _loadCaregiverName();
    _loadPatients();
  }

  Future<void> _loadCaregiverName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caregiverName = prefs.getString('userName') ?? 'Bakıcı';
    });
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final patients = await _firestoreService.getCaregiverPatients(widget.caregiverUid);
    setState(() {
      _patients = patients;
      _isLoading = false;
      if (_patients.isNotEmpty && _selectedPatientUid == null) {
        _selectedPatientUid = _patients.first.uid;
      }
    });
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileModal(
        caregiverName: _caregiverName,
        onLogout: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  void _showAddPatientDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hasta Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hastanın 6 haneli kodunu girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kod 6 haneli olmalıdır!')),
                );
                return;
              }

              Navigator.of(ctx).pop();

              final success = await _firestoreService.linkPatientToCaregiver(
                patientCode: code,
                caregiverUid: widget.caregiverUid,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hasta başarıyla eklendi!')),
                );
                _loadPatients();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçersiz kod veya hasta bulunamadı!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // NEW: Add medication for patient
  void _showAddMedicationForPatient() {
    if (_selectedPatientUid == null) return;

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
            patientUid: _selectedPatientUid!,
            medication: medication,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlaç başarıyla eklendi!')),
          );
        },
      ),
    );
  }

  // NEW: Edit medication
  void _showEditMedicationDialog(MedicationModel med) {
    if (_selectedPatientUid == null || med.id == null) return;

    final nameController = TextEditingController(text: med.name);
    final stockController = TextEditingController(text: med.stockCount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İlacı Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'İlaç Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok Miktarı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestoreService.updateMedication(
                patientUid: _selectedPatientUid!,
                medicationId: med.id!,
                updates: {
                  'name': nameController.text.trim(),
                  'stockCount': int.tryParse(stockController.text) ?? med.stockCount,
                },
              );
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İlaç güncellendi!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // NEW: Delete medication
  void _deleteMedication(MedicationModel med) {
    if (_selectedPatientUid == null || med.id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Silme Onayı'),
        content: Text('${med.name} adlı ilacı silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestoreService.deleteMedication(
                patientUid: _selectedPatientUid!,
                medicationId: med.id!,
              );
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İlaç silindi!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        title: Text(
          'Bakıcı Paneli - $_caregiverName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            onPressed: _showAddPatientDialog,
            tooltip: 'Hasta Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 32),
            onPressed: _showProfileModal,
            tooltip: 'Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_outlined, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 24),
                      const Text(
                        'Henüz hasta eklenmedi',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddPatientDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Hasta Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_patients.length > 1)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPatientUid,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          style: const TextStyle(fontSize: 18, color: Color(0xFF212121)),
                          items: _patients.map((patient) {
                            return DropdownMenuItem(
                              value: patient.uid,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_rounded, color: Color(0xFF009688)),
                                  const SizedBox(width: 12),
                                  Text('Hasta: ${patient.uid}'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPatientUid = value);
                          },
                        ),
                      ),
                    if (_selectedPatientUid != null)
                      Expanded(
                        child: _PatientMonitor(
                          patientUid: _selectedPatientUid!,
                          onEdit: _showEditMedicationDialog,
                          onDelete: _deleteMedication,
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _selectedPatientUid != null
          ? FloatingActionButton.extended(
              onPressed: _showAddMedicationForPatient,
              backgroundColor: const Color(0xFF009688),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'İlaç Ekle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

class _ProfileModal extends StatelessWidget {
  final String caregiverName;
  final VoidCallback onLogout;

  const _ProfileModal({
    required this.caregiverName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF009688),
            child: Icon(Icons.health_and_safety_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            caregiverName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bakıcı Hesabı',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PatientMonitor extends StatelessWidget {
  final String patientUid;
  final Function(MedicationModel) onEdit;
  final Function(MedicationModel) onDelete;

  const _PatientMonitor({
    required this.patientUid,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF009688),
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF009688),
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'İlaçlar'),
                Tab(text: 'Geçmiş'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                StreamBuilder<List<MedicationModel>>(
                  stream: firestoreService.getMedicationsStream(patientUid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    final medications = snapshot.data ?? [];

                    if (medications.isEmpty) {
                      return const Center(
                        child: Text(
                          'Hasta henüz ilaç eklemedi\n\n+ butonuna basarak ilaç ekleyin',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final morningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.morning).toList();
                    final eveningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.evening).toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (morningMeds.isNotEmpty) ...[
                          _SectionHeader(title: 'Sabah İlaçları', icon: Icons.wb_sunny_rounded),
                          ...morningMeds.map((med) => _MedicationAdminCard(
                            medication: med,
                            onEdit: () => onEdit(med),
                            onDelete: () => onDelete(med),
                          )),
                        ],
                        const SizedBox(height: 16),
                        if (eveningMeds.isNotEmpty) ...[
                          _SectionHeader(title: 'Akşam İlaçları', icon: Icons.nights_stay_rounded),
                          ...eveningMeds.map((med) => _MedicationAdminCard(
                            medication: med,
                            onEdit: () => onEdit(med),
                            onDelete: () => onDelete(med),
                          )),
                        ],
                      ],
                    );
                  },
                ),
                StreamBuilder<List<MedicationLog>>(
                  stream: firestoreService.getLogsStream(patientUid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    final logs = snapshot.data ?? [];

                    if (logs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz ilaç alınmadı',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _LogCard(log: log);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF009688), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationAdminCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationAdminCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final med = medication;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: med.isTaken ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (med.isTaken ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  med.isTaken ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 32,
                  color: med.isTaken ? Colors.green : Colors.orange,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: med.isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${med.time}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(width: 12),
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${med.stockCount} adet',
                          style: TextStyle(
                            fontSize: 14,
                            color: med.stockCount < 5 ? Colors.red : Colors.grey[600],
                            fontWeight: med.stockCount < 5 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: med.isTaken ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med.isTaken ? 'ALINDI' : 'BEKLİYOR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF009688),
                    side: const BorderSide(color: Color(0xFF009688)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: const Text('Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final MedicationLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 28,
              color: Color(0xFF009688),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(log.takenAt),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'Kalan: ${log.stockAfter}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
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
            'Hastaya İlaç Ekle',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
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
          color: isSelected ? const Color(0xFF009688) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey[300]!,
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
