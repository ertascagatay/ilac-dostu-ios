import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medication_model.dart';
import '../theme/app_theme.dart';

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
    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: PremiumColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz ilaç eklenmemiş',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: PremiumColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: medications.length,
      itemBuilder: (context, index) =>
          _buildPremiumMedCard(context, medications[index], index),
    );
  }

  Widget _buildPremiumMedCard(
      BuildContext context, MedicationModel med, int index) {
    // Cycle through pill colors
    final borderColor =
        PremiumColors.pillColors[index % PremiumColors.pillColors.length];

    final hungerLabel = _getHungerLabel(med);
    final timeLabel = med.time;

    return GestureDetector(
      onTap: () => onToggleTaken(med),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: PremiumColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left border
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),

              // Pill icon
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 8, 18),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: borderColor,
                    size: 24,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle info
                      if (hungerLabel.isNotEmpty)
                        Text(
                          hungerLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PremiumColors.textTertiary,
                          ),
                        ),
                      const SizedBox(height: 2),
                      // Med name
                      Text(
                        med.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: med.isTaken
                              ? PremiumColors.textTertiary
                              : PremiumColors.textPrimary,
                          decoration:
                              med.isTaken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Time row
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: PremiumColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: PremiumColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (med.stockCount < 5) ...[
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: PremiumColors.coralAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stok: ${med.stockCount}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PremiumColors.coralAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Status check
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: med.isTaken
                      ? Container(
                          key: const ValueKey('taken'),
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: PremiumColors.greenCheck,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : Container(
                          key: const ValueKey('untaken'),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: PremiumColors.divider,
                              width: 2,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHungerLabel(MedicationModel med) {
    String parts = '';
    if (med.timeOfDay == TimeOfDayType.morning) {
      parts = '☀️ Sabah';
    } else {
      parts = '🌙 Akşam';
    }

    switch (med.hungerStatus) {
      case HungerStatus.empty:
        return '$parts, Aç Karnına';
      case HungerStatus.full:
        return '$parts, Tok Karnına';
      case HungerStatus.neutral:
        return parts;
    }
  }
}
