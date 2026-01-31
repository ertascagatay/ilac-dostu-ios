import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationLog {
  final String? id;
  final String medicationId;
  final String medicationName;
  final DateTime takenAt;
  final int stockAfter;

  MedicationLog({
    this.id,
    required this.medicationId,
    required this.medicationName,
    required this.takenAt,
    required this.stockAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'takenAt': Timestamp.fromDate(takenAt),
      'stockAfter': stockAfter,
    };
  }

  factory MedicationLog.fromMap(String id, Map<String, dynamic> map) {
    return MedicationLog(
      id: id,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      takenAt: (map['takenAt'] as Timestamp).toDate(),
      stockAfter: map['stockAfter'] as int,
    );
  }
}
