import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Email/Password ───────────────────────────────────────────

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
    await _saveToPrefs(uid: uid, role: role, name: name);

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
      await _saveToPrefs(uid: uid, role: appUser.role, name: appUser.name);
    }

    return appUser;
  }

  // ─── Google Sign-In ───────────────────────────────────────────

  /// Sign in with Google. Returns AppUser if the user already exists in Firestore.
  /// Returns null if the user is new and needs role selection.
  Future<AppUser?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google giriş iptal edildi.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return _handleSocialSignIn(userCredential);
  }

  // ─── Apple Sign-In ────────────────────────────────────────────

  /// Sign in with Apple. Returns AppUser if the user already exists in Firestore.
  /// Returns null if the user is new and needs role selection.
  Future<AppUser?> signInWithApple() async {
    // Generate nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only provides the name on the first sign-in
    if (userCredential.user?.displayName == null &&
        appleCredential.givenName != null) {
      await userCredential.user?.updateDisplayName(
        '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim(),
      );
    }

    return _handleSocialSignIn(userCredential);
  }

  // ─── Social Sign-In Helpers ───────────────────────────────────

  /// Shared handler for social sign-in results.
  /// Returns AppUser if exists in Firestore, null if new user.
  Future<AppUser?> _handleSocialSignIn(UserCredential userCredential) async {
    final uid = userCredential.user!.uid;
    final existingUser = await _firestoreService.getUser(uid);

    if (existingUser != null) {
      // Existing user → save prefs and return
      await _saveToPrefs(uid: uid, role: existingUser.role, name: existingUser.name);
      return existingUser;
    }

    // New social user → return null to signal role selection needed
    return null;
  }

  /// Complete registration for social sign-in users (after role selection)
  Future<AppUser> completeSocialRegistration({
    required String name,
    required UserRole role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

    String? pairingCode;
    if (role == UserRole.patient) {
      pairingCode = await _firestoreService.generatePatientCode();
    }

    final appUser = AppUser(
      uid: user.uid,
      role: role,
      name: name,
      email: user.email,
      pairingCode: pairingCode,
    );

    await _firestoreService.createUser(appUser);
    await _saveToPrefs(uid: user.uid, role: role, name: name);

    return appUser;
  }

  // ─── Common ───────────────────────────────────────────────────

  /// Sign out
  Future<void> signOut() async {
    // Also sign out from Google if signed in
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
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

  /// Save user info to SharedPreferences
  Future<void> _saveToPrefs({
    required String uid,
    required UserRole role,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role == UserRole.patient ? 'patient' : 'caregiver');
    await prefs.setString('userUid', uid);
    await prefs.setString('userName', name);
  }

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash for Apple Sign-In nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
