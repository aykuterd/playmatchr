import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/notification_controller.dart';
import 'package:playmatchr/controllers/social_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/match_result_confirmation_screen.dart';
import 'package:playmatchr/widgets/profile_avatar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  final SocialController _socialController = Get.find<SocialController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const DefaultTextStyle(
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
          child: Text('Bildirimler'),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _notificationController.markAllAsRead();
              } else if (value == 'delete_all') {
                _showDeleteAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 12),
                    Text('Tümünü Okundu İşaretle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Tümünü Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Okunmamış'),
            Tab(text: 'Okunmuş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(null),
          _buildNotificationList(false), // Okunmamış
          _buildNotificationList(true), // Okunmuş
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool? isRead) {
    return Obx(() {
      List<AppNotification> filteredNotifications;

      if (isRead == null) {
        filteredNotifications = _notificationController.notifications;
      } else if (isRead) {
        filteredNotifications = _notificationController.readNotifications;
      } else {
        filteredNotifications = _notificationController.unreadNotifications;
      }

      if (filteredNotifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Bildirim Yok'),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Roboto',
                ),
                child: Text(
                  isRead == null
                      ? 'Henüz bildiriminiz bulunmuyor'
                      : isRead
                      ? 'Okunmuş bildiriminiz yok'
                      : 'Yeni bildiriminiz yok',
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      );
    });
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationController.deleteNotification(notification.id);
        Get.snackbar(
          'Silindi',
          'Bildirim silindi',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFF1E3A8A).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : const Color(0xFF1E3A8A).withOpacity(0.2),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or Avatar
                  _buildNotificationIcon(notification),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          child: Text(notification.title),
                        ),
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontFamily: 'Roboto',
                          ),
                          child: Text(notification.message),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontFamily: 'Roboto',
                              ),
                              child: Text(_getTimeAgo(notification.createdAt)),
                            ),
                          ],
                        ),
                        // Action buttons for friend requests
                        if (notification.type ==
                                NotificationType.friendRequest &&
                            !notification.isRead)
                          _buildFriendRequestActions(notification),
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    if (notification.fromUserPhoto != null) {
      return ProfileAvatar(photoUrl: notification.fromUserPhoto, radius: 24);
    }

    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccept:
        icon = Icons.person_add_rounded;
        color = const Color(0xFF1E3A8A);
        break;
      case NotificationType.matchInvite:
        icon = Icons.sports_soccer;
        color = Colors.orange;
        break;
      case NotificationType.teamInvite:
        icon = Icons.groups_rounded;
        color = Colors.purple;
        break;
      case NotificationType.matchUpdate:
        icon = Icons.info_rounded;
        color = Colors.blue;
        break;
      case NotificationType.matchReminder:
        icon = Icons.alarm_rounded;
        color = Colors.green;
        break;
      case NotificationType.groupInvite:
        // TODO: Handle this case.
        throw UnimplementedError();
      case NotificationType.groupMessage:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildFriendRequestActions(AppNotification notification) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                if (notification.fromUserId != null) {
                  await _socialController.acceptFriendRequest(
                    notification.fromUserId!,
                  );
                  await _notificationController.markAsRead(notification.id);
                  Get.snackbar(
                    'Başarılı',
                    'Arkadaşlık kabul edildi',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
                child: Text('Kabul Et'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                if (notification.fromUserId != null) {
                  await _socialController.rejectFriendRequest(
                    notification.fromUserId!,
                  );
                  await _notificationController.markAsRead(notification.id);
                  Get.snackbar(
                    'Reddedildi',
                    'Arkadaşlık isteği reddedildi',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Reddet'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (!notification.isRead) {
      _notificationController.markAsRead(notification.id);
    }

    // Handle navigation based on type
    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccept:
        // Navigate to social/profile screen
        Get.back(); // Close notification screen
        break;
      case NotificationType.matchInvite:
        // Navigate to match invitation detail screen
        if (notification.relatedId != null) {
          Get.toNamed('/match_invitation/${notification.relatedId}');
        }
        break;
      case NotificationType.teamInvite:
        // Navigate to team details
        // TODO: Implement team navigation
        break;
      case NotificationType.matchUpdate:
        if (notification.relatedId != null) {
          // Check if this is a result confirmation request
          final action = notification.data?['action'];
          if (action == 'confirm_result') {
            Get.to(
              () => MatchResultConfirmationScreen(
                matchId: notification.relatedId!,
              ),
            );
          }
        }
        break;
      case NotificationType.matchReminder:
        if (notification.relatedId != null) {
          // Navigate to match details
        }
        break;
      case NotificationType.groupInvite:
        // TODO: Handle this case.
        throw UnimplementedError();
      case NotificationType.groupMessage:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('d MMM', 'tr_TR').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  void _showDeleteAllDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const DefaultTextStyle(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
          child: Text('Tüm Bildirimleri Sil'),
        ),
        content: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Roboto',
          ),
          child: const Text(
            'Tüm bildirimlerinizi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              _notificationController.deleteAllNotifications();
              Get.back();
              Get.snackbar(
                'Silindi',
                'Tüm bildirimler silindi',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
