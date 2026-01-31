import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Generate unique 6-digit patient code
  Future&lt;String&gt; generatePatientCode() async {
    final random = Random();
    String code;
    bool exists = true;

    // Keep generating until we find a unique code
    while (exists) {
      code = (100000 + random.nextInt(900000)).toString();
      final doc = await _db.collection('users').doc(code).get();
      exists = doc.exists;
      if (!exists) return code;
    }
    return '';
  }

  // Create a new user (Patient or Caregiver)
  Future&lt;void&gt; createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user by UID
  Future&lt;AppUser?&gt; getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  // Link patient to caregiver (Pairing Logic)
  Future&lt;bool&gt; linkPatientToCaregiver({
    required String patientCode,
    required String caregiverUid,
  }) async {
    try {
      // Check if patient exists
      final patientDoc = await _db.collection('users').doc(patientCode).get();
      if (!patientDoc.exists) {
        return false; // Patient code not found
      }

      final patientData = patientDoc.data()!;
      if (patientData['role'] != 'patient') {
        return false; // Not a patient
      }

      // Add caregiver to patient's caregiverIds
      await _db.collection('users').doc(patientCode).update({
        'caregiverIds': FieldValue.arrayUnion([caregiverUid]),
      });

      // Add patient to caregiver's patientIds
      await _db.collection('users').doc(caregiverUid).update({
        'patientIds': FieldValue.arrayUnion([patientCode]),
      });

      return true;
    } catch (e) {
      print('Error linking patient to caregiver: $e');
      return false;
    }
  }

  // Get medications stream for real-time updates
  Stream&lt;List&lt;MedicationModel&gt;&gt; getMedicationsStream(String patientUid) {
    return _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =&gt; MedicationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Add medication
  Future&lt;String&gt; addMedication({
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

  // Update medication
  Future&lt;void&gt; updateMedication({
    required String patientUid,
    required String medicationId,
    required Map&lt;String, dynamic&gt; updates,
  }) async {
    await _db
        .collection('users')
        .doc(patientUid)
        .collection('medications')
        .doc(medicationId)
        .update(updates);
  }

  // Delete medication
  Future&lt;void&gt; deleteMedication({
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

  // Log medication taken
  Future&lt;void&gt; logMedicationTaken({
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

  // Get medication logs stream
  Stream&lt;List&lt;MedicationLog&gt;&gt; getLogsStream(String patientUid) {
    return _db
        .collection('users')
        .doc(patientUid)
        .collection('logs')
        .orderBy('takenAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =&gt; MedicationLog.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get caregiver's patients
  Future&lt;List&lt;AppUser&gt;&gt; getCaregiverPatients(String caregiverUid) async {
    final caregiverDoc = await _db.collection('users').doc(caregiverUid).get();
    if (!caregiverDoc.exists) return [];

    final patientIds = List&lt;String&gt;.from(caregiverDoc.data()!['patientIds'] ?? []);
    final List&lt;AppUser&gt; patients = [];

    for (final patientId in patientIds) {
      final patient = await getUser(patientId);
      if (patient != null) {
        patients.add(patient);
      }
    }

    return patients;
  }
}
