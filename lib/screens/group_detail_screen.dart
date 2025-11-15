import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/group_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:intl/intl.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupController _controller = Get.find<GroupController>();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Group?>(
      future: _firestoreService.getGroup(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Grup')),
            body: const Center(child: Text('Grup bulunamadı')),
          );
        }

        final group = snapshot.data!;
        final isMember = _controller.isMember(group);
        final isAdmin = _controller.isAdmin(group);

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              if (isAdmin)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(group);
                    }
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Group info header
              _buildGroupHeader(group, isMember, isAdmin),

              // Messages section (only for members)
              if (isMember) ...[
                const Divider(height: 1),
                Expanded(child: _buildMessagesSection()),
                _buildMessageInput(),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Bu grubun sohbetini görmek için\ngruba katılmanız gerekiyor',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(Group group, bool isMember, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getGroupIcon(group.sport),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} üye',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (group.sport != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              group.sport!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            group.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: group.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Action buttons
          Row(
            children: [
              if (!isMember)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: group.isFull
                        ? null
                        : () => _joinGroup(group.id),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(group.isFull ? 'Dolu' : 'Katıl'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else if (!isAdmin)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLeave(group),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Ayrıl'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    return StreamBuilder<List<GroupMessage>>(
      stream: _firestoreService.getGroupMessages(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Henüz mesaj yok\nİlk mesajı siz gönderin!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(GroupMessage message) {
    final isMe = message.userId ==
        Get.find<GroupController>().isAdmin(Group(
              id: widget.groupId,
              name: '',
              description: '',
              adminId: message.userId,
              memberIds: [],
              type: GroupType.public,
              createdAt: DateTime.now(),
            ));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                message.userName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mesaj yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _controller.sendMessage(widget.groupId, text);
    _messageController.clear();
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Hata', 'Giriş yapmanız gerekiyor');
        return;
      }

      await _firestoreService.joinGroup(groupId, userId);

      // Sayfayı yenile
      setState(() {});

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

  void _confirmLeave(Group group) {
    Get.defaultDialog(
      title: 'Gruptan Ayrıl',
      middleText: 'Bu gruptan ayrılmak istediğinize emin misiniz?',
      textCancel: 'İptal',
      textConfirm: 'Ayrıl',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        _controller.leaveGroup(group.id);
        Get.back(); // Close dialog
        Get.back(); // Close detail screen
      },
    );
  }

  void _confirmDelete(Group group) {
    Get.defaultDialog(
      title: 'Grubu Sil',
      middleText:
          'Bu grubu silmek istediğinize emin misiniz? Bu işlem geri alınamaz!',
      textCancel: 'İptal',
      textConfirm: 'Sil',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        _controller.deleteGroup(group.id);
        Get.back(); // Close dialog
      },
    );
  }

  IconData _getGroupIcon(String? sport) {
    if (sport == null) return Icons.groups_rounded;
    switch (sport.toLowerCase()) {
      case 'futbol':
      case 'soccer':
        return Icons.sports_soccer_rounded;
      case 'basketbol':
      case 'basketball':
        return Icons.sports_basketball_rounded;
      case 'tenis':
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'voleybol':
      case 'volleyball':
        return Icons.sports_volleyball_rounded;
      default:
        return Icons.sports_rounded;
    }
  }
}
