import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/profile_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserProfile> _members = [];
  List<UserProfile> _availableFriends = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _loadMembers();
  }

  void _checkAdmin() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _isAdmin = currentUserId == widget.team.adminId;
    });
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      // Takım üyelerini yükle
      List<UserProfile> members = [];
      for (String memberId in widget.team.memberIds) {
        final member = await _firestoreService.getUserProfile(memberId);
        if (member != null) {
          members.add(member);
        }
      }

      // Eğer admin ise, eklenebilecek arkadaşları da yükle
      List<UserProfile> available = [];
      if (_isAdmin) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          final allFriends = await _firestoreService.getFriends(currentUserId);
          // Takımda olmayan arkadaşları filtrele
          available = allFriends
              .where((friend) => !widget.team.memberIds.contains(friend.uid))
              .toList();
        }
      }

      setState(() {
        _members = members;
        _availableFriends = available;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() => _isLoading = false);
      Get.snackbar('Hata', 'Üyeler yüklenirken hata oluştu');
    }
  }

  Future<void> _addMember(String userId) async {
    try {
      await _firestoreService.addTeamMember(widget.team.id, userId);
      Get.snackbar('Başarılı', 'Üye eklendi');

      // Listeyi yenile
      await _loadMembers();

      // Profil controller'ı da güncelle
      final profileController = Get.find<ProfileController>();
      await profileController.loadTeams();
    } catch (e) {
      debugPrint('Error adding member: $e');
      Get.snackbar('Hata', 'Üye eklenemedi');
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      // Admin kendini çıkaramaz
      if (userId == widget.team.adminId) {
        Get.snackbar('Uyarı', 'Takım admini kendini çıkaramaz');
        return;
      }

      await _firestoreService.removeTeamMember(widget.team.id, userId);
      Get.snackbar('Başarılı', 'Üye çıkarıldı');

      // Listeyi yenile
      await _loadMembers();

      // Profil controller'ı da güncelle
      final profileController = Get.find<ProfileController>();
      await profileController.loadTeams();
    } catch (e) {
      debugPrint('Error removing member: $e');
      Get.snackbar('Hata', 'Üye çıkarılamadı');
    }
  }

  Future<void> _editTeam() async {
    final nameController = TextEditingController(text: widget.team.name);
    final sloganController = TextEditingController(text: widget.team.slogan ?? '');
    final descController = TextEditingController(text: widget.team.description ?? '');

    await Get.defaultDialog(
      title: 'Takımı Düzenle',
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Takım Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sloganController,
              decoration: const InputDecoration(
                labelText: 'Slogan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      textCancel: 'İptal',
      textConfirm: 'Kaydet',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          await _firestoreService.updateTeam(widget.team.id, {
            'name': nameController.text.trim(),
            'slogan': sloganController.text.trim().isEmpty
                ? null
                : sloganController.text.trim(),
            'description': descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
          });

          Get.back();
          Get.back(); // Takım detay ekranını da kapat
          Get.snackbar('Başarılı', 'Takım güncellendi');

          // Profil controller'ı güncelle
          final profileController = Get.find<ProfileController>();
          await profileController.loadTeams();
        } catch (e) {
          debugPrint('Error updating team: $e');
          Get.snackbar('Hata', 'Takım güncellenemedi');
        }
      },
    );
  }

  Future<void> _deleteTeam() async {
    await Get.defaultDialog(
      title: 'Takımı Sil',
      middleText: 'Bu takımı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      textCancel: 'İptal',
      textConfirm: 'Sil',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        try {
          await _firestoreService.deleteTeam(widget.team.id);

          Get.back(); // Dialog
          Get.back(); // Team detail screen
          Get.snackbar('Başarılı', 'Takım silindi');

          // Profil controller'ı güncelle
          final profileController = Get.find<ProfileController>();
          await profileController.loadTeams();
        } catch (e) {
          debugPrint('Error deleting team: $e');
          Get.snackbar('Hata', 'Takım silinemedi');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editTeam,
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteTeam,
                  tooltip: 'Sil',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Takım Bilgileri
                    _buildTeamInfo(),

                    const SizedBox(height: AppSpacing.xl),

                    // Üyeler
                    _buildMembersSection(),

                    // Admin ise üye ekleme bölümü
                    if (_isAdmin && _availableFriends.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildAddMembersSection(),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeamInfo() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXXL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          // Logo/Icon
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.groups,
              size: 50,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Takım Adı
          Text(
            widget.team.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Spor Dalı
          Chip(
            label: Text(widget.team.sport),
            backgroundColor: Colors.white.withOpacity(0.2),
            labelStyle: const TextStyle(color: Colors.white),
          ),

          // Slogan
          if (widget.team.slogan != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '"${widget.team.slogan}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          // Açıklama
          if (widget.team.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.team.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // İstatistik
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${_members.length} Üye',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.paddingLG,
          child: Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Takım Üyeleri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.paddingLG,
          itemCount: _members.length,
          itemBuilder: (context, index) {
            final member = _members[index];
            final isAdmin = member.uid == widget.team.adminId;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusLG,
                border: Border.all(
                  color: isAdmin ? AppColors.accent : AppColors.border,
                  width: isAdmin ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: AppSpacing.paddingMD,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('@${member.username}'),
                trailing: _isAdmin && !isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.error),
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Üyeyi Çıkar',
                            middleText:
                                '${member.displayName} takımdan çıkarılsın mı?',
                            textCancel: 'İptal',
                            textConfirm: 'Çıkar',
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              _removeMember(member.uid);
                              Get.back();
                            },
                          );
                        },
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.paddingLG,
          child: Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Üye Ekle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.paddingLG,
          itemCount: _availableFriends.length,
          itemBuilder: (context, index) {
            final friend = _availableFriends[index];

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusLG,
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: AppSpacing.paddingMD,
                leading: CircleAvatar(
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  foregroundColor: AppColors.accent,
                  child: Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  friend.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('@${friend.username}'),
                trailing: ElevatedButton.icon(
                  onPressed: () => _addMember(friend.uid),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ekle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
