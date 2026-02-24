import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, caregiver }

class AppUser {
  final String uid;
  final UserRole role;
  final String name;
  final String? email;
  final String? pairingCode;
  final List<String> caregiverIds;
  final List<String> patientIds;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    this.email,
    this.pairingCode,
    this.caregiverIds = const [],
    this.patientIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role == UserRole.patient ? 'patient' : 'caregiver',
      'name': name,
      'email': email,
      'pairingCode': pairingCode,
      'caregiverIds': caregiverIds,
      'patientIds': patientIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      role: map['role'] == 'patient' ? UserRole.patient : UserRole.caregiver,
      name: map['name'] as String,
      email: map['email'] as String?,
      pairingCode: map['pairingCode'] as String?,
      caregiverIds: List<String>.from(map['caregiverIds'] ?? []),
      patientIds: List<String>.from(map['patientIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
