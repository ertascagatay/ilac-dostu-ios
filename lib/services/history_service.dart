import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilac_dostu/main.dart';

class HistoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  /// Get medication history for last N days
  static Stream<List<MedicationHistory>> getMedicationHistory({
    required String userId,
    int days = 30,
  }) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    return _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .snapshots()
        .asyncMap((snapshot) async {
      final List<MedicationHistory> history = [];
      
      for (var doc in snapshot.docs) {
        final med = Medication.fromFirestore(doc.id, doc.data());
        
        // Add entry if taken
        if (med.taken && med.takenAt != null && med.takenAt!.isAfter(startDate)) {
          history.add(MedicationHistory(
            medicationName: med.name,
            takenAt: med.takenAt!,
            timeOfDay: med.timeOfDay,
          ));
        }
      }
      
      // Sort by date (newest first)
      history.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      return history;
    });
  }
  
  /// Calculate compliance rate (percentage of medications taken on time)
  static Future<ComplianceStats> getComplianceStats({
    required String userId,
    int days = 7,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    // Get all medications
    final medsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .get();
    
    if (medsSnapshot.docs.isEmpty) {
      return ComplianceStats(
        totalExpected: 0,
        totalTaken: 0,
        complianceRate: 0.0,
        streak: 0,
        dailyStats: {},
      );
    }
    
    final medications = medsSnapshot.docs
        .map((doc) => Medication.fromFirestore(doc.id, doc.data()))
        .toList();
    
    // Calculate expected doses and taken doses
    int totalExpected = medications.length * days;
    int totalTaken = 0;
    Map<String, int> dailyStats = {};
    
    for (var med in medications) {
      if (med.taken && med.takenAt != null && med.takenAt!.isAfter(startDate)) {
        totalTaken++;
        
        final dateKey = '${med.takenAt!.year}-${med.takenAt!.month.toString().padLeft(2, '0')}-${med.takenAt!.day.toString().padLeft(2, '0')}';
        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + 1;
      }
    }
    
    final complianceRate = totalExpected > 0 ? (totalTaken / totalExpected) * 100 : 0.0;
    final streak = _calculateStreak(dailyStats, medications.length);
    
    return ComplianceStats(
      totalExpected: totalExpected,
      totalTaken: totalTaken,
      complianceRate: complianceRate,
      streak: streak,
      dailyStats: dailyStats,
    );
  }
  
  /// Calculate current streak (consecutive days)
  static int _calculateStreak(Map<String, int> dailyStats, int medsPerDay) {
    if (dailyStats.isEmpty) return 0;
    
    int streak = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final takenCount = dailyStats[dateKey] ?? 0;
      
      if (takenCount >= medsPerDay) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    
    return streak;
  }
}

class MedicationHistory {
  final String medicationName;
  final DateTime takenAt;
  final String timeOfDay;
  
  MedicationHistory({
    required this.medicationName,
    required this.takenAt,
    required this.timeOfDay,
  });
}

class ComplianceStats {
  final int totalExpected;
  final int totalTaken;
  final double complianceRate;
  final int streak;
  final Map<String, int> dailyStats;
  
  ComplianceStats({
    required this.totalExpected,
    required this.totalTaken,
    required this.complianceRate,
    required this.streak,
    required this.dailyStats,
  });
}
