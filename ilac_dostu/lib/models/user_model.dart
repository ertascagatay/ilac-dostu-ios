import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, caregiver }

class AppUser {
  final String uid;
  final UserRole role;
  final String name;
  final List&lt;String&gt; caregiverIds; // For patients: list of caregiver UIDs
  final List&lt;String&gt; patientIds;   // For caregivers: list of patient UIDs
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    this.caregiverIds = const [],
    this.patientIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore
  Map&lt;String, dynamic&gt; toMap() {
    return {
      'uid': uid,
      'role': role == UserRole.patient ? 'patient' : 'caregiver',
      'name': name,
      'caregiverIds': caregiverIds,
      'patientIds': patientIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore
  factory AppUser.fromMap(Map&lt;String, dynamic&gt; map) {
    return AppUser(
      uid: map['uid'] as String,
      role: map['role'] == 'patient' ? UserRole.patient : UserRole.caregiver,
      name: map['name'] as String,
      caregiverIds: List&lt;String&gt;.from(map['caregiverIds'] ?? []),
      patientIds: List&lt;String&gt;.from(map['patientIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
