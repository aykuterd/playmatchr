import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user profile photo to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Create a reference to the file location
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Profile photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Delete user profile photo
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      await ref.delete();
      debugPrint('Profile photo deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting profile photo: $e');
      return false;
    }
  }

  /// Get profile photo URL
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error getting profile photo URL: $e');
      return null;
    }
  }
}
