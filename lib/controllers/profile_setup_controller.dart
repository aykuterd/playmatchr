import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:playmatchr/controllers/auth_controller.dart';

class ProfileSetupController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  var usernameError = Rxn<String>();
  var isLoading = false.obs;

  // City and District selection (using dropdown instead of TextFields)
  var selectedCity = ''.obs;
  var selectedDistrict = ''.obs;

  // Sports selection
  final List<String> availableSports = ['Futbol', 'Basketbol', 'Tenis', 'Voleybol', 'Koşu', 'Fitness'];
  var selectedSports = <String>[].obs;

  // Profile photo
  var selectedImagePath = Rxn<String>();
  var existingPhotoUrl = Rxn<String>();

  // Cover photo
  var selectedCoverImagePath = Rxn<String>();
  var existingCoverPhotoUrl = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(_validateUsername);
    _loadExistingData();
  }

  @override
  void onClose() {
    usernameController.dispose();
    bioController.dispose();
    super.onClose();
  }

  // Toggle sport selection
  void toggleSport(String sport) {
    if (selectedSports.contains(sport)) {
      selectedSports.remove(sport);
    } else {
      selectedSports.add(sport);
    }
  }

  // Load existing Google photo if available
  Future<void> _loadExistingData() async {
    final user = _authController.user.value;
    if (user == null) return;

    // Check if user already has a photo from Google
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data?['photoUrl'] != null && data!['photoUrl'].isNotEmpty) {
        existingPhotoUrl.value = data['photoUrl'];
        debugPrint('Existing photo found: ${existingPhotoUrl.value}');
      }
      if (data?['coverPhotoUrl'] != null && data!['coverPhotoUrl'].isNotEmpty) {
        existingCoverPhotoUrl.value = data['coverPhotoUrl'];
        debugPrint('Existing cover photo found: ${existingCoverPhotoUrl.value}');
      }
      if (data?['bio'] != null) {
        bioController.text = data?['bio'];
      }
      if (data?['preferredCity'] != null) {
        selectedCity.value = data?['preferredCity'];
      }
      if (data?['preferredDistrict'] != null) {
        selectedDistrict.value = data?['preferredDistrict'];
      }
      if (data?['favoriteSports'] != null) {
        selectedSports.value = List<String>.from(data?['favoriteSports']);
      }
    }
  }

  // Pick profile image from gallery
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        debugPrint('Image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Hata',
        'Fotoğraf seçilirken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Pick cover image from gallery
  Future<void> pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedCoverImagePath.value = image.path;
        debugPrint('Cover image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
      Get.snackbar(
        'Hata',
        'Kapak fotoğrafı seçilirken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Upload photo to Firebase Storage
  Future<String?> _uploadPhoto(String imagePath) async {
    try {
      final user = _authController.user.value;
      if (user == null) return null;

      final File imageFile = File(imagePath);
      final String fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('profile_photos')
          .child(fileName);

      debugPrint('Uploading photo to: profile_photos/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      Get.snackbar(
        'Hata',
        'Fotoğraf yüklenirken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Upload cover photo to Firebase Storage
  Future<String?> _uploadCoverPhoto(String imagePath) async {
    try {
      final user = _authController.user.value;
      if (user == null) return null;

      final File imageFile = File(imagePath);
      final String fileName =
          'cover_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('profile_photos')
          .child(fileName);

      debugPrint('Uploading cover photo to: cover_photos/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Cover photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      Get.snackbar(
        'Hata',
        'Kapak fotoğrafı yüklenirken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  void _validateUsername() {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      usernameError.value = 'Kullanıcı adı boş bırakılamaz.';
    } else if (username.length < 3) {
      usernameError.value = 'Kullanıcı adı en az 3 karakter olmalı.';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      usernameError.value = 'Sadece harf, sayı ve alt çizgi kullanın.';
    } else {
      usernameError.value = null;
    }
  }

  Future<void> saveProfile() async {
    if (isLoading.value) return;

    isLoading.value = true;

    _validateUsername();
    if (usernameError.value != null) {
      isLoading.value = false;
      return;
    }

    final username = usernameController.text.trim();
    final bio = bioController.text.trim();
    final city = selectedCity.value;
    final district = selectedDistrict.value;
    final user = _authController.user.value;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    // Şehir ve ilçe zorunlu
    if (city.isEmpty) {
      Get.snackbar(
        'Eksik Bilgi',
        'Lütfen şehir seçin. Sana yakın sporcular bulabilmemiz için gereklidir.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      isLoading.value = false;
      return;
    }

    if (district.isEmpty) {
      Get.snackbar(
        'Eksik Bilgi',
        'Lütfen ilçe seçin. Sana yakın sporcular bulabilmemiz için gereklidir.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      isLoading.value = false;
      return;
    }

    try {
      // Check if username is unique
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && snapshot.docs.first.id != user.uid) {
        usernameError.value = 'Bu kullanıcı adı zaten alınmış.';
        isLoading.value = false;
        return;
      }

      String? photoUrl;
      String? coverPhotoUrl;

      // Upload new photo if selected
      if (selectedImagePath.value != null) {
        debugPrint('Uploading new profile photo...');
        photoUrl = await _uploadPhoto(selectedImagePath.value!);
        if (photoUrl == null) {
          // Upload failed, but continue anyway
          debugPrint('Photo upload failed, continuing without photo');
        }
      } else if (existingPhotoUrl.value != null) {
        // Keep existing Google photo
        photoUrl = existingPhotoUrl.value;
        debugPrint('Keeping existing Google photo: $photoUrl');
      }

      // Upload new cover photo if selected
      if (selectedCoverImagePath.value != null) {
        debugPrint('Uploading new cover photo...');
        coverPhotoUrl = await _uploadCoverPhoto(selectedCoverImagePath.value!);
        if (coverPhotoUrl == null) {
          // Upload failed, but continue anyway
          debugPrint('Cover photo upload failed, continuing without cover photo');
        }
      } else if (existingCoverPhotoUrl.value != null) {
        // Keep existing cover photo
        coverPhotoUrl = existingCoverPhotoUrl.value;
        debugPrint('Keeping existing cover photo: $coverPhotoUrl');
      }

      // Update user profile in Firestore
      final Map<String, dynamic> updateData = {
        'username': username,
        'bio': bio.isNotEmpty ? bio : null,
        'preferredCity': city.isNotEmpty ? city : null,
        'preferredDistrict': district.isNotEmpty ? district : null,
        'favoriteSports': selectedSports.toList(),
        'preferredSports': selectedSports.toList(), // Use same sports for match recommendations
      };

      // Only update photoUrl if we have a new one
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      // Only update coverPhotoUrl if we have a new one
      if (coverPhotoUrl != null) {
        updateData['coverPhotoUrl'] = coverPhotoUrl;
      }

      debugPrint('Updating user profile with: $updateData');
      await _firestore.collection('users').doc(user.uid).update(updateData);

      debugPrint('Profile setup completed successfully');
      Get.offAllNamed('/main_screen');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      Get.snackbar(
        'Hata',
        'Profil kaydedilirken bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoading.value = false;
    }
  }
}
