import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/notification_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';

class SocialController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  late final NotificationController _notificationController;

  // Observable lists
  var friends = <UserProfile>[].obs;
  var friendRequests = <UserProfile>[].obs;
  var sentRequests = <UserProfile>[].obs;
  var suggestedUsers = <UserProfile>[].obs;
  var searchResults = <UserProfile>[].obs;
  var isSearching = false.obs;

  // Current user's friend lists (IDs)
  var friendIds = <String>[].obs;
  var requestIds = <String>[].obs;
  var sentRequestIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _notificationController = Get.find<NotificationController>();
    } catch (e) {
      debugPrint('NotificationController not found, will be initialized later: $e');
    }
    ensureCurrentUserProfile().then((_) {
      _loadFriendData();
      _loadSuggestedUsers();
    });
  }

  // Lazy getter for notification controller
  NotificationController get notificationController {
    try {
      return _notificationController;
    } catch (e) {
      _notificationController = Get.find<NotificationController>();
      return _notificationController;
    }
  }

  Future<void> _loadFriendData() async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    // Listen to current user's profile for real-time updates
    _firestore.collection('users').doc(currentUserId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final profile = UserProfile.fromFirestore(doc);
      friendIds.value = profile.friends;
      requestIds.value = profile.pendingFriendRequests;
      sentRequestIds.value = profile.sentFriendRequests;

      // Load friend profiles
      _loadFriends();
      _loadFriendRequests();
      _loadSentRequests();
    });
  }

  Future<void> _loadFriends() async {
    if (friendIds.isEmpty) {
      friends.clear();
      return;
    }

    try {
      // Firestore 'in' query limit is 10, so we need to batch
      final friendsList = <UserProfile>[];
      for (var i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        friendsList.addAll(
          snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList(),
        );
      }
      friends.value = friendsList;
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  Future<void> _loadFriendRequests() async {
    if (requestIds.isEmpty) {
      friendRequests.clear();
      return;
    }

    try {
      final requestsList = <UserProfile>[];
      for (var i = 0; i < requestIds.length; i += 10) {
        final batch = requestIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        requestsList.addAll(
          snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList(),
        );
      }
      friendRequests.value = requestsList;
    } catch (e) {
      print('Error loading friend requests: $e');
    }
  }

  Future<void> _loadSentRequests() async {
    if (sentRequestIds.isEmpty) {
      sentRequests.clear();
      return;
    }

    try {
      final sentList = <UserProfile>[];
      for (var i = 0; i < sentRequestIds.length; i += 10) {
        final batch = sentRequestIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        sentList.addAll(
          snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList(),
        );
      }
      sentRequests.value = sentList;
    } catch (e) {
      print('Error loading sent requests: $e');
    }
  }

  Future<void> _loadSuggestedUsers() async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(20)
          .get();

      final users = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();

      suggestedUsers.value = users
          .where((user) =>
              !friendIds.contains(user.uid) &&
              !requestIds.contains(user.uid) &&
              !sentRequestIds.contains(user.uid))
          .toList();

      print('Loaded ${suggestedUsers.length} suggested users');
    } catch (e) {
      print('Error loading suggested users: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    isSearching.value = true;

    try {
      final queryLower = query.toLowerCase();

      // Search by username
      final usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: queryLower)
          .where('username', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(10)
          .get();

      // Search by display name
      final displayNameSnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      final results = <UserProfile>[];
      final seenIds = <String>{};

      for (var doc in [...usernameSnapshot.docs, ...displayNameSnapshot.docs]) {
        if (!seenIds.contains(doc.id) && doc.id != currentUserId) {
          results.add(UserProfile.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      searchResults.value = results;
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      // Add to current user's sent requests
      await _firestore.collection('users').doc(currentUserId).update({
        'sentFriendRequests': FieldValue.arrayUnion([toUserId]),
      });

      // Add to target user's pending requests
      await _firestore.collection('users').doc(toUserId).update({
        'pendingFriendRequests': FieldValue.arrayUnion([currentUserId]),
      });

      // Send notification
      debugPrint('Sending friend request notification to $toUserId');
      await notificationController.sendFriendRequestNotification(toUserId);

      Get.snackbar(
        'Başarılı',
        'Arkadaşlık isteği gönderildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      Get.snackbar(
        'Hata',
        'Arkadaşlık isteği gönderilemedi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> cancelFriendRequest(String toUserId) async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      // Remove from current user's sent requests
      await _firestore.collection('users').doc(currentUserId).update({
        'sentFriendRequests': FieldValue.arrayRemove([toUserId]),
      });

      // Remove from target user's pending requests
      await _firestore.collection('users').doc(toUserId).update({
        'pendingFriendRequests': FieldValue.arrayRemove([currentUserId]),
      });

      Get.snackbar(
        'İptal Edildi',
        'Arkadaşlık isteği iptal edildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error canceling friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      // Add to both users' friends lists
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([fromUserId]),
        'pendingFriendRequests': FieldValue.arrayRemove([fromUserId]),
      });

      await _firestore.collection('users').doc(fromUserId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
        'sentFriendRequests': FieldValue.arrayRemove([currentUserId]),
      });

      // Send notification to the user who sent the request
      debugPrint('Sending friend accept notification to $fromUserId');
      await notificationController.sendFriendAcceptNotification(fromUserId);

      Get.snackbar(
        'Başarılı',
        'Arkadaşlık isteği kabul edildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      Get.snackbar(
        'Hata',
        'İstek kabul edilemedi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> rejectFriendRequest(String fromUserId) async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      // Remove from current user's pending requests
      await _firestore.collection('users').doc(currentUserId).update({
        'pendingFriendRequests': FieldValue.arrayRemove([fromUserId]),
      });

      // Remove from sender's sent requests
      await _firestore.collection('users').doc(fromUserId).update({
        'sentFriendRequests': FieldValue.arrayRemove([currentUserId]),
      });

      Get.snackbar(
        'Reddedildi',
        'Arkadaşlık isteği reddedildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error rejecting friend request: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      // Remove from both users' friends lists
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      Get.snackbar(
        'Başarılı',
        'Arkadaşlıktan çıkarıldı',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error removing friend: $e');
      Get.snackbar(
        'Hata',
        'Arkadaşlıktan çıkarılamadı',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper methods
  bool isFriend(String userId) => friendIds.contains(userId);
  bool hasSentRequest(String userId) => sentRequestIds.contains(userId);
  bool hasReceivedRequest(String userId) => requestIds.contains(userId);

  // DEBUG: Ensure current user has a proper profile
  Future<void> ensureCurrentUserProfile() async {
    final currentUserId = _authController.user.value?.uid;
    if (currentUserId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();

      if (!doc.exists) {
        // Create profile for current user
        await _firestore.collection('users').doc(currentUserId).set({
          'username': 'user_${currentUserId.substring(0, 8)}',
          'displayName': _authController.user.value?.email?.split('@')[0] ?? 'Kullanıcı',
          'email': _authController.user.value?.email ?? '',
          'bio': 'PlayMatchr kullanıcısı',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': [],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        });
        print('DEBUG: Created profile for current user');
      } else {
        final data = doc.data();
        if (data != null && (data['username'] == null || data['username'] == '')) {
          // Update username if it's null
          await _firestore.collection('users').doc(currentUserId).update({
            'username': 'user_${currentUserId.substring(0, 8)}',
          });
          print('DEBUG: Updated username for current user');
        }
      }
    } catch (e) {
      print('Error ensuring current user profile: $e');
    }
  }

  // DEBUG: Create test users
  Future<void> createTestUsers() async {
    // First ensure current user has a profile
    await ensureCurrentUserProfile();
    try {
      final testUsers = [
        {
          'username': 'ahmet_yilmaz',
          'displayName': 'Ahmet Yılmaz',
          'email': 'ahmet@test.com',
          'bio': 'Futbol ve basketbol sevdalısı',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': ['Futbol', 'Basketbol'],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        },
        {
          'username': 'mehmet_kaya',
          'displayName': 'Mehmet Kaya',
          'email': 'mehmet@test.com',
          'bio': 'Tenis oyuncusu',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': ['Tenis'],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        },
        {
          'username': 'ayse_demir',
          'displayName': 'Ayşe Demir',
          'email': 'ayse@test.com',
          'bio': 'Voleybol takım kaptanı',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': ['Voleybol'],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        },
        {
          'username': 'can_ozturk',
          'displayName': 'Can Öztürk',
          'email': 'can@test.com',
          'bio': 'Badminton meraklısı',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': ['Badminton'],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        },
        {
          'username': 'zeynep_arslan',
          'displayName': 'Zeynep Arslan',
          'email': 'zeynep@test.com',
          'bio': 'Masa tenisi şampiyonu',
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': ['Masa Tenisi'],
          'myTeams': [],
          'createdAt': Timestamp.now(),
        },
      ];

      for (var i = 0; i < testUsers.length; i++) {
        final userId = 'test_user_$i';
        await _firestore.collection('users').doc(userId).set(testUsers[i]);
      }

      Get.snackbar(
        'Başarılı',
        '${testUsers.length} test kullanıcısı oluşturuldu',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload users
      await _loadSuggestedUsers();
    } catch (e) {
      print('Error creating test users: $e');
      Get.snackbar(
        'Hata',
        'Test kullanıcıları oluşturulamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
