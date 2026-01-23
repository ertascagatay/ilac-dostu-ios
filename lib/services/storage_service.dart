import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload medication photo to Firebase Storage
  /// Returns the download URL
  static Future<String?> uploadMedicationPhoto({
    required String userId,
    required String medicationId,
    required File imageFile,
  }) async {
    if (kIsWeb) return null; // Web doesn't support File
    
    try {
      // Create a reference to the file location
      final ref = _storage.ref().child('medications/$userId/$medicationId.jpg');
      
      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }
  
  /// Delete medication photo from Firebase Storage
  static Future<void> deleteMedicationPhoto({
    required String userId,
    required String medicationId,
  }) async {
    if (kIsWeb) return;
    
    try {
      final ref = _storage.ref().child('medications/$userId/$medicationId.jpg');
      await ref.delete();
      print('Photo deleted successfully');
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }
  
  /// Delete photo by URL (alternative method)
  static Future<void> deletePhotoByUrl(String photoUrl) async {
    if (kIsWeb) return;
    
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      print('Photo deleted by URL');
    } catch (e) {
      print('Error deleting photo by URL: $e');
    }
  }
}
