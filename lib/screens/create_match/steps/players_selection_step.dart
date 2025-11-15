import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/create_match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class PlayersSelectionStep extends StatefulWidget {
  const PlayersSelectionStep({super.key});

  @override
  State<PlayersSelectionStep> createState() => _PlayersSelectionStepState();
}

class _PlayersSelectionStepState extends State<PlayersSelectionStep> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserProfile> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final friends = await _firestoreService.getFriends(currentUserId);
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateMatchController>();

    return Obx(() {
      final isTeamMatch = controller.selectedMatchType.value == MatchType.team;

      return SingleChildScrollView(
        padding: AppSpacing.paddingXXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              isTeamMatch ? 'Takımları Oluştur' : 'Rakibini Seç',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isTeamMatch
                  ? 'Arkadaşlarınızı takımlara ekleyin'
                  : 'Maç yapacağınız arkadaşınızı seçin',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Rakip Arıyor Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rakip Arıyor musun?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu maçı tercihlerine göre diğer kullanıcılara öner',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => SwitchListTile(
                        value: controller.lookingForOpponent.value,
                        onChanged: (value) {
                          controller.lookingForOpponent.value = value;
                          if (!value) {
                            controller.requiredOpponentCount.value = null;
                          }
                        },
                        title: Text(
                          controller.lookingForOpponent.value
                              ? 'Evet, rakip arıyorum ✓'
                              : 'Hayır, sadece arkadaşlarımla',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                  Obx(() {
                    if (!controller.lookingForOpponent.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Kaç rakip arıyorsun? (Opsiyonel)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Rakip Sayısı',
                            hintText: 'Örn: 1 (boş = sınırsız)',
                            helperText: 'Boş bırakırsan sınırsız sayıda katılabilir',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            controller.requiredOpponentCount.value =
                                value.isEmpty ? null : int.tryParse(value);
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Eğer rakip arıyorsa, arkadaş seçmek opsiyonel
            Obx(() {
              if (controller.lookingForOpponent.value) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arkadaş seçmeden devam edebilirsin',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: AppSpacing.xl),

            // Loading
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_friends.isEmpty)
              _buildEmptyState()
            else ...[
              // Takım Sporları için iki takım göster
              if (isTeamMatch) ...[
                _buildTeamSection(
                  context,
                  controller,
                  'Takımım (${controller.team1Players.length})',
                  controller.team1Players,
                  isTeam1: true,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildTeamSection(
                  context,
                  controller,
                  'Rakip Takım (${controller.team2Players.length})',
                  controller.team2Players,
                  isTeam1: false,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // Arkadaş Listesi
              _buildFriendsList(context, controller, isTeamMatch),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz arkadaşınız yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Profil bölümünden arkadaş ekleyebilirsiniz',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    CreateMatchController controller,
    String title,
    List<TeamPlayer> players, {
    required bool isTeam1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isTeam1
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.accent.withOpacity(0.05),
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: isTeam1 ? AppColors.primary : AppColors.accent,
          width: 2,
        ),
      ),
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTeam1 ? Icons.sports : Icons.sports_handball,
                color: isTeam1 ? AppColors.primary : AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isTeam1 ? AppColors.primary : AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Oyuncular
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Henüz oyuncu eklenmedi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return _buildPlayerCard(
                  player,
                  onRemove: () {
                    if (isTeam1) {
                      controller.team1Players.remove(player);
                    } else {
                      controller.team2Players.remove(player);
                    }
                  },
                  teamColor: isTeam1 ? AppColors.primary : AppColors.accent,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    TeamPlayer player, {
    required VoidCallback onRemove,
    required Color teamColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: teamColor.withOpacity(0.15),
          foregroundColor: teamColor,
          child: Text(
            player.userName[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          player.userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
          onPressed: onRemove,
          iconSize: 20,
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    CreateMatchController controller,
    bool isTeamMatch,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Arkadaşlarınız',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Arkadaş kartları
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index];
            return _buildFriendCard(context, controller, friend, isTeamMatch);
          },
        ),
      ],
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    CreateMatchController controller,
    UserProfile friend,
    bool isTeamMatch,
  ) {
    return Obx(() {
      // Arkadaş zaten seçilmiş mi kontrol et
      final isInTeam1 = controller.team1Players
          .any((p) => p.userId == friend.uid);
      final isInTeam2 = controller.team2Players
          .any((p) => p.userId == friend.uid);
      final isSelected = isInTeam1 || isInTeam2;

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? (isInTeam1 ? AppColors.primary : AppColors.accent).withOpacity(0.08)
              : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLG,
          border: Border.all(
            color: isSelected
                ? (isInTeam1 ? AppColors.primary : AppColors.accent)
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: isSelected
                ? (isInTeam1 ? AppColors.primary : AppColors.accent)
                : AppColors.surfaceVariant,
            foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
            child: Text(
              friend.displayName[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            friend.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: friend.favoriteSports.isNotEmpty
              ? Text(
                  friend.favoriteSports.join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          trailing: isTeamMatch
              ? _buildTeamButtons(controller, friend, isInTeam1, isInTeam2)
              : _buildSinglePlayerButton(
                  controller,
                  friend,
                  isSelected,
                ),
        ),
      );
    });
  }

  Widget _buildTeamButtons(
    CreateMatchController controller,
    UserProfile friend,
    bool isInTeam1,
    bool isInTeam2,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Takımıma ekle
        IconButton(
          onPressed: isInTeam1
              ? null
              : () {
                  // Eğer rakip takımdaysa önce oradan çıkar
                  if (isInTeam2) {
                    controller.team2Players.removeWhere((p) => p.userId == friend.uid);
                  }
                  controller.team1Players.add(TeamPlayer(
                    userId: friend.uid,
                    userName: friend.displayName,
                    profileImage: friend.photoUrl,
                  ));
                },
          icon: Icon(
            isInTeam1 ? Icons.check_circle : Icons.add_circle_outline,
            color: isInTeam1 ? AppColors.primary : AppColors.primary,
          ),
          tooltip: 'Takımıma Ekle',
        ),
        const SizedBox(width: AppSpacing.xs),
        // Rakip takıma ekle
        IconButton(
          onPressed: isInTeam2
              ? null
              : () {
                  // Eğer kendi takımındaysa önce oradan çıkar
                  if (isInTeam1) {
                    controller.team1Players.removeWhere((p) => p.userId == friend.uid);
                  }
                  controller.team2Players.add(TeamPlayer(
                    userId: friend.uid,
                    userName: friend.displayName,
                    profileImage: friend.photoUrl,
                  ));
                },
          icon: Icon(
            isInTeam2 ? Icons.check_circle : Icons.add_circle_outline,
            color: isInTeam2 ? AppColors.accent : AppColors.accent,
          ),
          tooltip: 'Rakip Takıma Ekle',
        ),
      ],
    );
  }

  Widget _buildSinglePlayerButton(
    CreateMatchController controller,
    UserProfile friend,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: isSelected
          ? () {
              // Kaldır
              controller.team2Players.removeWhere((p) => p.userId == friend.uid);
            }
          : () {
              // Rakip olarak ekle (1v1)
              controller.team2Players.clear();
              controller.team2Players.add(TeamPlayer(
                userId: friend.uid,
                userName: friend.displayName,
                profileImage: friend.photoUrl,
              ));
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.error : AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Text(isSelected ? 'Kaldır' : 'Seç'),
    );
  }
}
