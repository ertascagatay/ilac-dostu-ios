import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  final String userUid;
  final UserRole role;

  const HistoryScreen({super.key, required this.userUid, required this.role});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: AppBar(
        title: Text(
          'Geçmiş / Raporlar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: PremiumColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: widget.role == UserRole.patient
            ? _buildPatientHistory()
            : _buildCaregiverHistory(),
      ),
    );
  }

  Widget _buildPatientHistory() {
    return StreamBuilder<List<MedicationModel>>(
      stream: _firestoreService.getMedicationsStream(widget.userUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: PremiumColors.coralAccent));
        }

        final medications = snapshot.data ?? [];
        final taken = medications.where((m) => m.isTaken).toList();
        final notTaken = medications.where((m) => !m.isTaken).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Günlük Özet',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bugünkü ilaç durumunuz',
                style: GoogleFonts.inter(fontSize: 15, color: PremiumColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Alındı',
                      count: taken.length,
                      total: medications.length,
                      color: PremiumColors.greenCheck,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Bekliyor',
                      count: notTaken.length,
                      total: medications.length,
                      color: PremiumColors.coralAccent,
                      icon: Icons.pending_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (taken.isNotEmpty) ...[
                Text(
                  'Alınan İlaçlar ✓',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: PremiumColors.greenCheck,
                  ),
                ),
                const SizedBox(height: 8),
                ...taken.map((m) => _buildHistoryItem(m, true)),
                const SizedBox(height: 16),
              ],
              if (notTaken.isNotEmpty) ...[
                Text(
                  'Bekleyen İlaçlar',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: PremiumColors.coralAccent,
                  ),
                ),
                const SizedBox(height: 8),
                ...notTaken.map((m) => _buildHistoryItem(m, false)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaregiverHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 64, color: PremiumColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Raporlar Bölümü',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PremiumColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hastanızın geçmişe dönük ilaç ve sağlık raporlarını "Ana Sayfa"daki Rapor İndirme butonunu kullanarak dışa aktarabilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: PremiumColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: PremiumColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: PremiumColors.darkNavy,
                ),
              ),
              Text(
                ' / $total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PremiumColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(MedicationModel med, bool isTaken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTaken ? PremiumColors.greenCheck.withValues(alpha: 0.1) : PremiumColors.coralAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isTaken ? PremiumColors.greenCheck : PremiumColors.coralAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: PremiumColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${med.dosage} - ${med.time}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: PremiumColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
