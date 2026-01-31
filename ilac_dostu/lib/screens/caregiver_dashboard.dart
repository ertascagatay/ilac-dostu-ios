import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
              backgroundColor: const Color(0xFF009688),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF009688),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Bakıcı Paneli',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF009688), Color(0xFF00796B)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                onPressed: _showAddPatientDialog,
                tooltip: 'Hasta Ekle',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Çıkış Yap',
              ),
            ],
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _patients.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
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
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: Column(
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
                            _PatientMonitor(patientUid: _selectedPatientUid!),
                        ],
                      ),
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
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
                          'Hasta henüz ilaç eklemedi',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
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
                          ...morningMeds.map((med) => _MedicationStatusCard(medication: med)),
                        ],
                        const SizedBox(height: 16),
                        if (eveningMeds.isNotEmpty) ...[
                          _SectionHeader(title: 'Akşam İlaçları', icon: Icons.nights_stay_rounded),
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

class _MedicationStatusCard extends StatelessWidget {
  final MedicationModel medication;

  const _MedicationStatusCard({required this.medication});

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
      child: Row(
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
