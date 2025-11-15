import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Bildirimler
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı giriş yapınca bildirimleri dinlemeye başla
    ever(_authController.user, (user) {
      if (user != null) {
        _listenToNotifications();
      } else {
        // Kullanıcı çıkış yaparsa bildirimleri temizle
        notifications.clear();
        unreadCount.value = 0;
      }
    });

    // Eğer kullanıcı zaten giriş yaptıysa hemen başlat
    if (_authController.user.value != null) {
      _listenToNotifications();
    }
  }

  // Bildirimleri dinle
  void _listenToNotifications() {
    final userId = _authController.user.value?.uid;
    if (userId == null) {
      debugPrint('Cannot listen to notifications: user is null');
      return;
    }

    debugPrint('Starting to listen notifications for user: $userId');

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Performans için limit ekle
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      // Okunmamış bildirim sayısını hesapla
      unreadCount.value = notifications.where((n) => !n.isRead).length;

      debugPrint('Notifications loaded: ${notifications.length}, Unread: ${unreadCount.value}');
    });
  }

  // Bildirim oluştur (Generic metod)
  Future<void> createNotification({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final currentUserId = _authController.user.value?.uid;
      if (currentUserId == null) {
        debugPrint('Cannot create notification: user not logged in');
        return;
      }

      // Get current user profile
      var fromUser = _authController.userProfile.value;

      // If userProfile is null, fetch it from Firestore
      if (fromUser == null) {
        debugPrint('UserProfile is null, fetching from Firestore...');
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (!userDoc.exists) {
          debugPrint('User document not found in Firestore');
          return;
        }
        fromUser = UserProfile.fromFirestore(userDoc);
      }

      debugPrint('Creating notification: $type to $toUserId from ${fromUser.displayName}');

      await _firestore.collection('notifications').add({
        'userId': toUserId,
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'fromUserId': fromUser.uid,
        'fromUserName': fromUser.displayName,
        'fromUserPhoto': fromUser.photoUrl,
        'relatedId': relatedId,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification created successfully in Firestore');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow; // Re-throw to see the error in CreateMatchController
    }
  }

  // Arkadaşlık daveti bildirimi
  Future<void> sendFriendRequestNotification(String toUserId) async {
    // Get user info from createNotification method
    final userName = _authController.userProfile.value?.displayName ??
                     _authController.user.value?.displayName ??
                     'Bir kullanıcı';

    await createNotification(
      toUserId: toUserId,
      type: NotificationType.friendRequest,
      title: 'Yeni Arkadaşlık İsteği',
      message: '$userName sana arkadaşlık isteği gönderdi',
    );
  }

  // Arkadaşlık kabul bildirimi
  Future<void> sendFriendAcceptNotification(String toUserId) async {
    final userName = _authController.userProfile.value?.displayName ??
                     _authController.user.value?.displayName ??
                     'Bir kullanıcı';

    await createNotification(
      toUserId: toUserId,
      type: NotificationType.friendAccept,
      title: 'Arkadaşlık Kabul Edildi',
      message: '$userName arkadaşlık isteğini kabul etti',
    );
  }

  // Maç daveti bildirimi
  Future<void> sendMatchInviteNotification({
    required String toUserId,
    required String matchId,
    required String sportType,
    required DateTime matchDate,
  }) async {
    final userName = _authController.userProfile.value?.displayName ??
                     _authController.user.value?.displayName ??
                     'Bir kullanıcı';

    await createNotification(
      toUserId: toUserId,
      type: NotificationType.matchInvite,
      title: 'Yeni Maç Daveti',
      message: '$userName seni $sportType maçına davet etti',
      relatedId: matchId,
      data: {
        'matchDate': matchDate.toIso8601String(),
        'sportType': sportType,
      },
    );
  }

  // Takım daveti bildirimi
  Future<void> sendTeamInviteNotification({
    required String toUserId,
    required String teamId,
    required String teamName,
  }) async {
    final userName = _authController.userProfile.value?.displayName ??
                     _authController.user.value?.displayName ??
                     'Bir kullanıcı';

    await createNotification(
      toUserId: toUserId,
      type: NotificationType.teamInvite,
      title: 'Yeni Takım Daveti',
      message: '$userName seni $teamName takımına davet etti',
      relatedId: teamId,
    );
  }

  // Maç güncelleme bildirimi
  Future<void> sendMatchUpdateNotification({
    required List<String> userIds,
    required String matchId,
    required String sportType,
    required String updateMessage,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        toUserId: userId,
        type: NotificationType.matchUpdate,
        title: 'Maç Güncellendi',
        message: '$sportType maçı: $updateMessage',
        relatedId: matchId,
      );
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    try {
      final userId = _authController.user.value?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Tüm bildirimleri sil
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _authController.user.value?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All notifications deleted');
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // Bildirim tipine göre filtrele
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return notifications.where((n) => n.type == type).toList();
  }

  // Okunmamış bildirimleri getir
  List<AppNotification> get unreadNotifications {
    return notifications.where((n) => !n.isRead).toList();
  }

  // Okunmuş bildirimleri getir
  List<AppNotification> get readNotifications {
    return notifications.where((n) => n.isRead).toList();
  }
}
