import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/group_detail_screen.dart';
import 'package:playmatchr/services/firestore_service.dart';

class GroupController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable lists
  var publicGroups = <Group>[].obs;
  var myGroups = <Group>[].obs;
  var isLoading = true.obs;
  var searchResults = <Group>[].obs;
  var isSearching = false.obs;

  // Stream subscriptions
  StreamSubscription<List<Group>>? _publicGroupsSubscription;
  StreamSubscription<List<Group>>? _myGroupsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  @override
  void onClose() {
    _publicGroupsSubscription?.cancel();
    _myGroupsSubscription?.cancel();
    super.onClose();
  }

  /// Load all groups
  void loadGroups() {
    try {
      isLoading.value = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Load public groups
      _publicGroupsSubscription = _firestoreService.getPublicGroups().listen(
        (groups) {
          publicGroups.value = groups;
          debugPrint('✅ Loaded ${groups.length} public groups');
        },
        onError: (error) {
          debugPrint('❌ Error loading public groups: $error');
        },
      );

      // Load user's groups if logged in
      if (userId != null) {
        _myGroupsSubscription = _firestoreService
            .getUserGroups(userId)
            .listen(
              (groups) {
                myGroups.value = groups;
                debugPrint('✅ Loaded ${groups.length} user groups');
              },
              onError: (error) {
                debugPrint('❌ Error loading user groups: $error');
              },
            );
      }
    } catch (e) {
      debugPrint('❌ Error in loadGroups: $e');
      Get.snackbar('Hata', 'Gruplar yüklenirken hata oluştu');
    } finally {
      isLoading.value = false;
    }
  }

  /// Search groups
  Future<void> searchGroups(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    try {
      isSearching.value = true;
      final results = await _firestoreService.searchGroups(query);
      searchResults.value = results;
      debugPrint('🔍 Found ${results.length} groups matching "$query"');
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      Get.snackbar('Hata', 'Arama sırasında hata oluştu');
    } finally {
      isSearching.value = false;
    }
  }

  /// Create a new group
  Future<String?> createGroup({
    required String name,
    required String description,
    String? sport,
    required GroupType type,
    String? city,
    String? district,
    List<String> tags = const [],
    int? maxMembers,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Hata', 'Giriş yapmanız gerekiyor');
        return null;
      }

      final group = Group(
        id: '',
        name: name,
        description: description,
        sport: sport,
        adminId: userId,
        memberIds: [userId], // Admin is the first member
        type: type,
        tags: tags,
        city: city,
        district: district,
        maxMembers: maxMembers,
        createdAt: DateTime.now(),
      );

      final groupId = await _firestoreService.createGroup(group);

      Get.back(); // Close create screen

      // Kullanıcıyı yeni oluşturulan grubun detay sayfasına yönlendir
      Get.to(() => GroupDetailScreen(groupId: groupId));

      Get.snackbar(
        'Başarılı',
        'Grup oluşturuldu!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return groupId;
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      Get.snackbar('Hata', 'Grup oluşturulurken hata oluştu');
      return null;
    }
  }

  /// Join a group
  Future<void> joinGroup(String groupId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Hata', 'Giriş yapmanız gerekiyor');
        return;
      }

      await _firestoreService.joinGroup(groupId, userId);

      // Kullanıcıyı grubun detay sayfasına yönlendir
      Get.to(() => GroupDetailScreen(groupId: groupId));

      Get.snackbar(
        'Başarılı',
        'Gruba katıldınız!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Error joining group: $e');
      Get.snackbar('Hata', 'Gruba katılırken hata oluştu');
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check if user is admin
      final group = await _firestoreService.getGroup(groupId);
      if (group?.adminId == userId) {
        Get.snackbar(
          'Uyarı',
          'Grup adminiyseniz, önce bir moderatörü admin yapmalısınız',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      await _firestoreService.leaveGroup(groupId, userId);

      Get.snackbar(
        'Başarılı',
        'Gruptan ayrıldınız',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
      Get.snackbar('Hata', 'Gruptan ayrılırken hata oluştu');
    }
  }

  /// Update group
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      await _firestoreService.updateGroup(groupId, updates);

      Get.snackbar(
        'Başarılı',
        'Grup güncellendi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      Get.snackbar('Hata', 'Grup güncellenirken hata oluştu');
    }
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestoreService.deleteGroup(groupId);

      Get.back(); // Close detail screen
      Get.snackbar(
        'Başarılı',
        'Grup silindi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      Get.snackbar('Hata', 'Grup silinirken hata oluştu');
    }
  }

  /// Send a message to group
  Future<void> sendMessage(String groupId, String message) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Kullanıcı';

      if (userId == null) return;

      final groupMessage = GroupMessage(
        id: '',
        groupId: groupId,
        userId: userId,
        userName: userName,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestoreService.sendGroupMessage(groupMessage);
      debugPrint('✅ Message sent to group $groupId');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      Get.snackbar('Hata', 'Mesaj gönderilirken hata oluştu');
    }
  }

  /// Check if user is member of a group
  bool isMember(Group group) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null && group.memberIds.contains(userId);
  }

  /// Check if user is admin of a group
  bool isAdmin(Group group) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null && group.adminId == userId;
  }

  /// Check if user is moderator of a group
  bool isModerator(Group group) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null && group.moderatorIds.contains(userId);
  }
}
