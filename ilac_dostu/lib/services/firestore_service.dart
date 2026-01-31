import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> generatePatientCode() async {
    final random = Random();
    String code;
    bool exists = true;

    while (exists) {
      code = (100000 + random.nextInt(900000)).toString();
      final doc = await _db.collection('users').doc(code).get();
      exists = doc.exists;
      if (!exists) return code;
    }
    return '';
  }

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  Future<bool> linkPatientToCaregiver({
    required String patientCode,
    required String caregiverUid,
  }) async {
    try {
      final patientDoc = await _db.collection('users').doc(patientCode).get();
      if (!patientDoc.exists) {
        return false;
      }

      final patientData = patientDoc.data()!;
      if (patientData['role'] != 'patient') {
        return false;
      }

      await _db.collection('users').doc(patientCode).update({
        'caregiverIds': FieldValue.arrayUnion([caregiverUid]),
      });

      await _db.collection('users').doc(caregiverUid).update({
        'patientIds': FieldValue.arrayUnion([patientCode]),
      });

      return true;
    } catch (e) {
      print('Error linking patient to caregiver: $e');
      return false;
    }
  }

  Stream<List<MedicationModel>> getMedicationsStream(String patientUid) {
    return _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> addMedication({
    required String patientUid,
    required MedicationModel medication,
  }) async {
    final docRef = await _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .add(medication.toMap());
    return docRef.id;
  }

  Future<void> updateMedication({
    required String patientUid,
    required String medicationId,
    required Map<String, dynamic> updates,
  }) async {
    await _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .doc(medicationId)
        .update(updates);
  }

  Future<void> deleteMedication({
    required String patientUid,
    required String medicationId,
  }) async {
    await _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .doc(medicationId)
        .delete();
  }

  Future<void> logMedicationTaken({
    required String patientUid,
    required MedicationModel medication,
  }) async {
    final log = MedicationLog(
      medicationId: medication.id!,
      medicationName: medication.name,
      takenAt: DateTime.now(),
      stockAfter: medication.stockCount,
    );

    await _db
        .collection('users')
        .doc(patientUid)
        .collection('logs')
        .add(log.toMap());
  }

  Stream<List<MedicationLog>> getLogsStream(String patientUid) {
    return _db
        .collection('users')
        .doc(patientUid)
        .collection('logs')
        .orderBy('takenAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicationLog.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<AppUser>> getCaregiverPatients(String caregiverUid) async {
    final caregiverDoc = await _db.collection('users').doc(caregiverUid).get();
    if (!caregiverDoc.exists) return [];

    final patientIds = List<String>.from(caregiverDoc.data()!['patientIds'] ?? []);
    final List<AppUser> patients = [];

    for (final patientId in patientIds) {
      final patient = await getUser(patientId);
      if (patient != null) {
        patients.add(patient);
      }
    }

    return patients;
  }
}
