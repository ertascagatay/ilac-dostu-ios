import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medication_model.dart';

class DailyMedicationCard extends StatelessWidget {
  final List<MedicationModel> medications;
  final Function(MedicationModel) onToggleTaken;

  const DailyMedicationCard({
    super.key,
    required this.medications,
    required this.onToggleTaken,
  });

  @override
  Widget build(BuildContext context) {
    // Split medications into morning (before 17:00) and evening (17:00+)
    final morningMeds = medications.where((med) {
      final hour = int.tryParse(med.time.split(':')[0]) ?? 0;
      return hour < 17;
    }).toList();

    final eveningMeds = medications.where((med) {
      final hour = int.tryParse(med.time.split(':')[0]) ?? 0;
      return hour >= 17;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF),
                  const Color(0xFF6C63FF).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Bugünün İlaçları',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Morning Section
          if (morningMeds.isNotEmpty) ...[
            _buildSectionHeader('☀️ SABAH', morningMeds.length),
            ...morningMeds.map((med) => _buildMedicationItem(context, med)),
          ],

          // Evening Section
          if (eveningMeds.isNotEmpty) ...[
            _buildSectionHeader('🌙 AKŞAM', eveningMeds.length),
            ...eveningMeds.map((med) => _buildMedicationItem(context, med)),
          ],

          // Empty state
          if (medications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz ilaç eklenmemiş',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(BuildContext context, MedicationModel med) {
    return InkWell(
      onTap: () => onToggleTaken(med),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: med.isTaken
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[300]!,
                  width: 2,
                ),
                color: med.isTaken
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
              ),
              child: med.isTaken
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Medication Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          med.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: med.isTaken
                                ? Colors.grey[400]
                                : const Color(0xFF2D3436),
                            decoration: med.isTaken
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hunger Status Badge
                      if (med.hungerStatusDisplay.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: med.hungerStatus == HungerStatus.empty
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            med.hungerStatusDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: med.hungerStatus == HungerStatus.empty
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF388E3C),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        med.time,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stok: ${med.stockCount}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: med.stockCount < 5
                              ? const Color(0xFFFF6B6B)
                              : Colors.grey[600],
                          fontWeight: med.stockCount < 5
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Icon
            Icon(
              med.isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
              color: med.isTaken
                  ? const Color(0xFF4CAF50)
                  : Colors.grey[300],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
