import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log.dart';
import '../services/firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPatients();
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

  void _showAddPatientDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hasta Ekle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hastanın 6 haneli kodunu girin:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İPTAL', style: TextStyle(fontSize: 20, color: Colors.grey)),
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
            child: const Text('EKLE', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakıcı Paneli'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 32),
            onPressed: _showAddPatientDialog,
            tooltip: 'Hasta Ekle',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_outlined, size: 100, color: Colors.grey.shade400),
                      const SizedBox(height: 24),
                      const Text(
                        'Henüz hasta eklenmedi',
                        style: TextStyle(fontSize: 28, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddPatientDialog,
                        icon: const Icon(Icons.add, size: 32),
                        label: const Text('Hasta Ekle', style: TextStyle(fontSize: 24)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
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
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.shade50,
                        child: DropdownButton<String>(
                          value: _selectedPatientUid,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 24, color: Colors.black),
                          items: _patients.map((patient) {
                            return DropdownMenuItem(
                              value: patient.uid,
                              child: Text('Hasta: ${patient.uid}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPatientUid = value);
                          },
                        ),
                      ),
                    Expanded(
                      child: _selectedPatientUid != null
                          ? _PatientMonitor(patientUid: _selectedPatientUid!)
                          : const Center(child: Text('Hasta seçin')),
                    ),
                  ],
                ),
    );
  }
}

class _PatientMonitor extends StatelessWidget {
  final String patientUid;

  const _PatientMonitor({required this.patientUid});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.green.shade700,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              tabs: [
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
                      return Center(
                        child: Text('Hata: ${snapshot.error}', style: const TextStyle(fontSize: 20)),
                      );
                    }

                    final medications = snapshot.data ?? [];

                    if (medications.isEmpty) {
                      return const Center(
                        child: Text(
                          'Hasta henüz ilaç eklemedi',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
                        ),
                      );
                    }

                    final morningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.morning).toList();
                    final eveningMeds = medications.where((m) => m.timeOfDay == TimeOfDayType.evening).toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (morningMeds.isNotEmpty) ...[
                          const _SectionHeader(title: 'Sabah İlaçları'),
                          ...morningMeds.map((med) => _MedicationStatusCard(medication: med)),
                        ],
                        const SizedBox(height: 24),
                        if (eveningMeds.isNotEmpty) ...[
                          const _SectionHeader(title: 'Akşam İlaçları'),
                          ...eveningMeds.map((med) => _MedicationStatusCard(medication: med)),
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
                      return Center(
                        child: Text('Hata: ${snapshot.error}', style: const TextStyle(fontSize: 20)),
                      );
                    }

                    final logs = snapshot.data ?? [];

                    if (logs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz ilaç alınmadı',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MedicationStatusCard extends StatelessWidget {
  final MedicationModel medication;

  const _MedicationStatusCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    final med = medication;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: med.isTaken ? Colors.green.shade100 : Colors.orange.shade50,
      elevation: 2,
      child: ListTile(
        leading: Icon(
          med.isTaken ? Icons.check_circle : Icons.pending,
          size: 48,
          color: med.isTaken ? Colors.green : Colors.orange,
        ),
        title: Text(
          med.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            decoration: med.isTaken ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saat: ${med.time}', style: const TextStyle(fontSize: 18)),
            Text('Kalan: ${med.stockCount} adet', style: const TextStyle(fontSize: 18)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: med.isTaken ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            med.isTaken ? 'ALINDI' : 'BEKLİYOR',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, size: 40, color: Colors.blue),
        title: Text(
          log.medicationName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dateFormat.format(log.takenAt),
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Text(
          'Kalan: ${log.stockAfter}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
