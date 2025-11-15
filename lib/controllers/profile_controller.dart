import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  var currentUser = Rx<UserProfile?>(null);
  var friends = <UserProfile>[].obs;
  var pendingRequests = <UserProfile>[].obs;
  var myTeams = <Team>[].obs;
  var isLoading = true.obs;
  var isUploading = false.obs;

  StreamSubscription<DocumentSnapshot>? _userProfileSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToUserProfile();
    loadProfile();
  }

  @override
  void onClose() {
    _userProfileSubscription?.cancel();
    super.onClose();
  }

  /// Firestore'daki kullanıcı profilini dinle (real-time updates)
  void _listenToUserProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _userProfileSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        currentUser.value = UserProfile.fromFirestore(snapshot);
        debugPrint('✅ Profile updated from Firestore stream');
      }
    }, onError: (error) {
      debugPrint('❌ Error listening to user profile: $error');
    });
  }

  Future<void> pickAndUploadProfileImage() async {
    try {
      isUploading.value = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;

        // Upload to Firebase Storage
        final File imageFile = File(image.path);
        final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child('profile_photos').child(fileName);

        debugPrint('Uploading profile photo to Firebase Storage...');
        final UploadTask uploadTask = ref.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('Profile photo uploaded successfully: $downloadUrl');

        // Update Firestore with the download URL
        await _firestoreService.updateUserProfilePhoto(userId, downloadUrl);

        Get.snackbar('Başarılı', 'Profil fotoğrafınız güncellendi.');
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      Get.snackbar('Hata', 'Fotoğraf yüklenirken bir hata oluştu.');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> pickAndUploadCoverPhoto() async {
    try {
      isUploading.value = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;

        // Upload to Firebase Storage
        final File imageFile = File(image.path);
        final String fileName = 'cover_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child('profile_photos').child(fileName);

        debugPrint('Uploading cover photo to Firebase Storage...');
        final UploadTask uploadTask = ref.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('Cover photo uploaded successfully: $downloadUrl');

        // Update Firestore with the download URL
        await _firestoreService.updateUserCoverPhoto(userId, downloadUrl);

        Get.snackbar('Başarılı', 'Kapak fotoğrafınız güncellendi.');
      }
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      Get.snackbar('Hata', 'Kapak fotoğrafı yüklenirken bir hata oluştu.');
    } finally {
      isUploading.value = false;
    }
  }


  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) return;

      // Kullanıcı profilini yükle
      final profile = await _firestoreService.getUserProfile(userId);
      currentUser.value = profile;

      if (profile != null) {
        // Arkadaşları yükle
        await loadFriends();

        // Bekleyen istekleri yükle
        await loadPendingRequests();

        // Takımları yükle
        await loadTeams();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      Get.snackbar('Hata', 'Profil yüklenirken hata oluştu');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFriends() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final friendsList = await _firestoreService.getFriends(userId);
      friends.value = friendsList;
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      final profile = currentUser.value;
      if (profile == null) return;

      List<UserProfile> requests = [];
      for (String userId in profile.pendingFriendRequests) {
        final user = await _firestoreService.getUserProfile(userId);
        if (user != null) {
          requests.add(user);
        }
      }
      pendingRequests.value = requests;
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<void> loadTeams() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final teamsList = await _firestoreService.getUserTeams(userId);
      myTeams.value = teamsList;
    } catch (e) {
      debugPrint('Error loading teams: $e');
    }
  }

  Future<void> acceptFriendRequest(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestoreService.acceptFriendRequest(userId, friendId);

      // Listeyi güncelle
      await loadProfile();

      Get.snackbar('Başarılı', 'Arkadaşlık isteği kabul edildi');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      Get.snackbar('Hata', 'İşlem başarısız oldu');
    }
  }

  Future<void> rejectFriendRequest(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestoreService.rejectFriendRequest(userId, friendId);

      // Listeyi güncelle
      await loadProfile();

      Get.snackbar('Başarılı', 'Arkadaşlık isteği reddedildi');
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      Get.snackbar('Hata', 'İşlem başarısız oldu');
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestoreService.removeFriend(userId, friendId);

      // Listeyi güncelle
      await loadProfile();

      Get.snackbar('Başarılı', 'Arkadaş listenizden çıkarıldı');
    } catch (e) {
      debugPrint('Error removing friend: $e');
      Get.snackbar('Hata', 'İşlem başarısız oldu');
    }
  }

  Future<void> updatePreferences({
    required String city,
    required String district,
    required List<String> sports,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'preferredCity': city.isNotEmpty ? city : null,
        'preferredDistrict': district.isNotEmpty ? district : null,
        'preferredSports': sports,
        'favoriteSports': sports, // Backward compatibility
      });

      debugPrint('✅ User preferences updated successfully');

      // Refresh discovery matches with new preferences (if MatchController exists)
      // This is optional and won't cause errors if MatchController is not initialized
      try {
        if (Get.isRegistered<dynamic>()) {
          final matchController = Get.find<dynamic>();
          if (matchController.toString().contains('MatchController')) {
            matchController.fetchDiscoveryMatches();
          }
        }
      } catch (e) {
        // Silently ignore if MatchController is not available
        // This is expected behavior when user hasn't visited match discovery yet
      }
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      Get.snackbar('Hata', 'Tercihler kaydedilirken bir hata oluştu');
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String bio,
    required String city,
    required String district,
    required List<String> sports,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'bio': bio.isNotEmpty ? bio : null,
        'preferredCity': city.isNotEmpty ? city : null,
        'preferredDistrict': district.isNotEmpty ? district : null,
        'preferredSports': sports,
        'favoriteSports': sports, // Backward compatibility
      });

      debugPrint('✅ User profile updated successfully');

      // Refresh discovery matches with new preferences (if MatchController exists)
      // This is optional and won't cause errors if MatchController is not initialized
      try {
        if (Get.isRegistered<dynamic>()) {
          final matchController = Get.find<dynamic>();
          if (matchController.toString().contains('MatchController')) {
            matchController.fetchDiscoveryMatches();
          }
        }
      } catch (e) {
        // Silently ignore if MatchController is not available
        // This is expected behavior when user hasn't visited match discovery yet
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      Get.snackbar('Hata', 'Profil kaydedilirken bir hata oluştu');
      rethrow;
    }
  }
}
