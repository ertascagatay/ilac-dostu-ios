import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  /// Register with email/password, create Firestore user doc
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Generate pairing code for patients
    String? pairingCode;
    if (role == UserRole.patient) {
      pairingCode = await _firestoreService.generatePatientCode();
    }

    final appUser = AppUser(
      uid: uid,
      role: role,
      name: name,
      email: email,
      pairingCode: pairingCode,
    );

    await _firestoreService.createUser(appUser);

    // Save to SharedPreferences for quick access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role == UserRole.patient ? 'patient' : 'caregiver');
    await prefs.setString('userUid', uid);
    await prefs.setString('userName', name);

    return appUser;
  }

  /// Login with email/password
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final appUser = await _firestoreService.getUser(uid);

    if (appUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', appUser.role == UserRole.patient ? 'patient' : 'caregiver');
      await prefs.setString('userUid', uid);
      await prefs.setString('userName', appUser.name);
    }

    return appUser;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get current user's AppUser from Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _firestoreService.getUser(user.uid);
  }
}
