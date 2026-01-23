import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DailyResetService {
  static Timer? _dailyTimer;
  
  /// Start daily reset timer that runs at midnight
  static void startDailyReset(String userId) {
    if (kIsWeb) return; // Web doesn't support background tasks
    
    // Cancel existing timer if any
    _dailyTimer?.cancel();
    
    // Calculate time until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);
    
    // Schedule first reset at midnight
    Future.delayed(durationUntilMidnight, () {
      _resetMedications(userId);
      
      // Then repeat every 24 hours
      _dailyTimer = Timer.periodic(const Duration(days: 1), (_) {
        _resetMedications(userId);
      });
    });
  }
  
  /// Reset all medications for a user
  static Future<void> _resetMedications(String userId) async {
    try {
      final db = FirebaseFirestore.instance;
      final medsSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('medications')
          .where('taken', isEqualTo: true)
          .get();
      
      // Batch update for better performance
      final batch = db.batch();
      for (var doc in medsSnapshot.docs) {
        batch.update(doc.reference, {
          'taken': false,
          'takenAt': null,
        });
      }
      
      await batch.commit();
      print('Daily reset completed for user: $userId at ${DateTime.now()}');
    } catch (e) {
      print('Error during daily reset: $e');
    }
  }
  
  /// Stop the daily reset timer
  static void stopDailyReset() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }
  
  /// Manually trigger reset (for testing)
  static Future<void> manualReset(String userId) async {
    await _resetMedications(userId);
  }
}
