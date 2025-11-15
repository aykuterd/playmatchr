import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/profile_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/create_team_screen.dart';
import 'package:playmatchr/screens/search_users_screen.dart';
import 'package:playmatchr/screens/team_detail_screen.dart';
import 'package:playmatchr/screens/social/user_profile_screen.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/profile_avatar.dart';
import 'package:playmatchr/constants/turkey_cities.dart';
import 'package:playmatchr/utils/time_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.signOut(),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Obx(() {
        final user = authController.userProfile.value;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.currentUser.value?.uid != user.uid) {
          controller.loadProfile();
        }

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(context, user, controller),
                const SizedBox(height: 180), // Space for the overlapping content
                _buildProfileCompletion(context, user),
                const SizedBox(height: AppSpacing.md),
                _buildStats(context, controller),
                const SizedBox(height: AppSpacing.lg),
                _buildActions(context),
                const SizedBox(height: AppSpacing.xl),
                if (controller.pendingRequests.isNotEmpty) ...[
                  _buildPendingRequests(context, controller),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _buildAchievementsSection(context, user),
                const SizedBox(height: AppSpacing.lg),
                _buildMatchHistory(context, user),
                const SizedBox(height: AppSpacing.lg),
                _buildFavoritesList(context, user),
                const SizedBox(height: AppSpacing.lg),
                _buildFriendsList(context, controller),
                const SizedBox(height: AppSpacing.lg),
                _buildTeamsList(context, controller),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserProfile user,
    ProfileController controller,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover/Header Area
        Stack(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: user.coverPhotoUrl == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                          AppColors.accent,
                        ],
                      )
                    : null,
              ),
              child: user.coverPhotoUrl != null
                  ? Stack(
                      children: [
                        _buildCoverImage(user.coverPhotoUrl!),
                        // Add a subtle overlay for better text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            // Edit cover photo button
            Positioned(
              top: 8,
              right: 8,
              child: Obx(
                () => GestureDetector(
                  onTap: controller.isUploading.value
                      ? null
                      : controller.pickAndUploadCoverPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: controller.isUploading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Content positioned below header
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Avatar with shadow and border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ProfileAvatar(photoUrl: user.photoUrl, radius: 56),
                    ),
                    // Camera button overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Obx(
                        () => GestureDetector(
                          onTap: controller.isUploading.value
                              ? null
                              : controller.pickAndUploadProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: controller.isUploading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name and username
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '@${user.username}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Bio if exists
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  // ... (rest of the widgets remain the same)

  Widget _buildStats(BuildContext context, ProfileController controller) {
    final user = controller.currentUser.value;
    if (user == null) return const SizedBox.shrink();

    // Güvenilirlik oranını hesapla
    final totalMatches = user.totalMatchesPlayed;
    final noShows = user.noShows;
    final reliabilityRate = totalMatches > 0
        ? ((totalMatches - noShows) / totalMatches) * 100
        : 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Top stats cards - 2x2 grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  user.eloRating.toString(),
                  'ELO Puanı',
                  Icons.star_rounded,
                  [Colors.amber.shade400, Colors.orange.shade600],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  context,
                  user.sportsmanshipScore.toStringAsFixed(1),
                  'Sportmenlik',
                  Icons.handshake_rounded,
                  [Colors.green.shade400, Colors.teal.shade600],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '${reliabilityRate.toStringAsFixed(0)}%',
                  'Güvenilirlik',
                  Icons.shield_rounded,
                  [Colors.blue.shade400, Colors.indigo.shade600],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  context,
                  user.totalMatchesPlayed.toString(),
                  'Toplam Maç',
                  Icons.sports_tennis_rounded,
                  [Colors.purple.shade400, Colors.deepPurple.shade600],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Win/Loss bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: user.matchesWon,
                  child: _buildWinLossStat(
                    context,
                    user.matchesWon.toString(),
                    'Galibiyet',
                    Colors.green.shade400,
                    Icons.emoji_events_rounded,
                  ),
                ),
                if (user.matchesWon > 0 && user.matchesLost > 0)
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    color: Colors.grey.shade300,
                  ),
                Expanded(
                  flex: user.matchesLost > 0 ? user.matchesLost : 1,
                  child: _buildWinLossStat(
                    context,
                    user.matchesLost.toString(),
                    'Mağlubiyet',
                    Colors.red.shade400,
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinLossStat(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Arkadaş Ekle',
                  Icons.person_add_rounded,
                  AppColors.primary,
                  () => Get.to(() => const SearchUsersScreen()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Takım Oluştur',
                  Icons.groups_rounded,
                  AppColors.accent,
                  () => Get.to(() => const CreateTeamScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionButton(
            context,
            'Profili Düzenle',
            Icons.edit_rounded,
            const Color(0xFF00897B),
            () => _showPreferencesDialog(context),
          ),
        ],
      ),
    );
  }

  void _showPreferencesDialog(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final user = controller.currentUser.value;
    if (user == null) return;

    // Reactive variables for dropdowns
    final selectedCity = (user.preferredCity ?? '').obs;
    final selectedDistrict = (user.preferredDistrict ?? '').obs;
    final selectedSports = <String>[...user.preferredSports].obs;
    final bioController = TextEditingController(text: user.bio ?? '');

    final List<String> availableSports = ['Futbol', 'Basketbol', 'Tenis', 'Voleybol', 'Koşu', 'Fitness'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bio Field
              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Hakkında',
                  hintText: 'Kendinden bahset...',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // City Dropdown
              Obx(() => DropdownButtonFormField<String>(
                    value: selectedCity.value.isEmpty ? null : selectedCity.value,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      hintText: 'Şehir seçin',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    items: TurkeyCities.cityNames.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedCity.value = value ?? '';
                      selectedDistrict.value = ''; // Reset district when city changes
                    },
                    isExpanded: true,
                  )),
              const SizedBox(height: 16),
              // District Dropdown
              Obx(() {
                if (selectedCity.value.isEmpty) {
                  return const SizedBox.shrink();
                }

                final districts = TurkeyCities.getDistricts(selectedCity.value);

                return DropdownButtonFormField<String>(
                  value: selectedDistrict.value.isEmpty ? null : selectedDistrict.value,
                  decoration: const InputDecoration(
                    labelText: 'İlçe (Opsiyonel)',
                    hintText: 'İlçe seçin',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Seçiniz (opsiyonel)'),
                    ),
                    ...districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    selectedDistrict.value = value ?? '';
                  },
                  isExpanded: true,
                );
              }),
              const SizedBox(height: 24),
              const Text(
                'Favori Sporlar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSports.map((sport) {
                  final isSelected = selectedSports.contains(sport);
                  return ChoiceChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedSports.add(sport);
                      } else {
                        selectedSports.remove(sport);
                      }
                    },
                  );
                }).toList(),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save preferences
              await controller.updateProfile(
                bio: bioController.text.trim(),
                city: selectedCity.value,
                district: selectedDistrict.value,
                sports: selectedSports.toList(),
              );
              Navigator.pop(context);
              Get.snackbar(
                'Başarılı',
                'Profiliniz güncellendi',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests(
    BuildContext context,
    ProfileController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_active_rounded,
                  color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Arkadaşlık İstekleri',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: controller.pendingRequests.length,
            itemBuilder: (context, index) {
              final request = controller.pendingRequests[index];
              return _buildPendingRequestCard(context, request, controller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestCard(
    BuildContext context,
    dynamic request,
    ProfileController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withOpacity(0.2),
          foregroundColor: AppColors.accent,
          child: Text(
            request.displayName.isNotEmpty
                ? request.displayName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          request.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('@${request.username}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              onPressed: () => controller.acceptFriendRequest(request.uid),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              onPressed: () => controller.rejectFriendRequest(request.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_rounded,
                  color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Arkadaşlar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.friends.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          if (controller.friends.isEmpty) {
            return Padding(
              padding: AppSpacing.paddingXXL,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Henüz arkadaşınız yok',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: controller.friends.length,
            itemBuilder: (context, index) {
              final friend = controller.friends[index];
              return _buildFriendCard(context, friend, controller);
            },
          );
        }),
      ],
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    dynamic friend,
    ProfileController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              foregroundColor: AppColors.primary,
              child: Text(
                friend.displayName.isNotEmpty
                    ? friend.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: TimeHelper.getOnlineIndicator(friend.lastSeen, size: 12),
            ),
          ],
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text('@${friend.username}'),
            const SizedBox(width: 8),
            Text(
              '• ${TimeHelper.getLastSeenShort(friend.lastSeen)}',
              style: TextStyle(
                fontSize: 12,
                color: TimeHelper.getLastSeenColor(friend.lastSeen),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
          onPressed: () {
            Get.defaultDialog(
              title: 'Arkadaş Çıkar',
              middleText:
                  '${friend.displayName} arkadaş listenizden çıkarılsın mı?',
              textCancel: 'İptal',
              textConfirm: 'Çıkar',
              confirmTextColor: Colors.white,
              onConfirm: () {
                controller.removeFriend(friend.uid);
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamsList(BuildContext context, ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.groups_rounded,
                  color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Takımlarım',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.myTeams.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          if (controller.myTeams.isEmpty) {
            return Padding(
              padding: AppSpacing.paddingXXL,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 60,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Henüz takımınız yok',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: controller.myTeams.length,
            itemBuilder: (context, index) {
              final team = controller.myTeams[index];
              return _buildTeamCard(context, team);
            },
          );
        }),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, dynamic team) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.groups, size: 28),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.sport),
            if (team.slogan != null)
              Text(
                team.slogan!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${team.memberIds.length} üye'),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Get.to(() => TeamDetailScreen(team: team));
        },
      ),
    );
  }

  /// Rozetler bölümü
  Widget _buildAchievementsSection(BuildContext context, UserProfile user) {
    if (user.achievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade100, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.grey.shade400, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Henüz rozet kazanmadın',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maç oyna ve başarılarını topla!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade50,
              Colors.orange.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Rozetler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user.achievements.length}/${Achievements.all.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: user.achievements.map((achievementStr) {
                final achievement = Achievements.fromString(achievementStr);
                if (achievement == null) return const SizedBox.shrink();
                return _buildAchievementBadge(achievement);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Tek bir rozet badge'i
  Widget _buildAchievementBadge(Achievement achievement) {
    final color = Color(int.parse(achievement.color.replaceFirst('#', '0xFF')));

    return Tooltip(
      message: '${achievement.name}\n${achievement.description}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              achievement.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maç geçmişi bölümü
  Widget _buildMatchHistory(BuildContext context, UserProfile user) {
    final FirestoreService firestoreService = FirestoreService();

    return FutureBuilder<List<TournamentMatch>>(
      future: firestoreService.getUserTournamentMatches(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Maç Geçmişi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (matches.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${matches.length}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports_tennis, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Henüz maç geçmişin yok',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Turnuvalara katıl ve maçlarını tamamla',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...matches.take(5).map((match) => _buildMatchCard(context, match, user.uid)),
            if (matches.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextButton(
                  onPressed: () {
                    // TODO: Tüm maçları göster
                  },
                  child: Text('Tümünü Gör (${matches.length})'),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Tek bir maç kartı
  Widget _buildMatchCard(BuildContext context, TournamentMatch match, String userId) {
    final isWinner = match.winnerId == userId;
    final opponentId = match.player1Id == userId ? match.player2Id : match.player1Id;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isWinner ? Colors.green.shade200 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sonuç badge'i
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isWinner ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWinner ? Icons.emoji_events : Icons.close,
                          size: 16,
                          color: isWinner ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isWinner ? 'Kazandın' : 'Kaybettin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWinner ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tur bilgisi
                  Text(
                    'Tur ${match.round}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Skor
              if (match.player1Score != null && match.player2Score != null)
                FutureBuilder<UserProfile?>(
                  future: opponentId != null
                      ? FirestoreService().getUserProfile(opponentId)
                      : Future.value(null),
                  builder: (context, opponentSnapshot) {
                    final opponent = opponentSnapshot.data;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'vs ${opponent?.displayName ?? 'Rakip'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Favori oyuncular listesi
  Widget _buildFavoritesList(BuildContext context, UserProfile user) {
    final FirestoreService firestoreService = FirestoreService();

    return FutureBuilder<List<UserProfile>>(
      future: firestoreService.getFavoriteUsers(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Favori Oyuncular',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (favorites.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${favorites.length}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Henüz favori oyuncun yok',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Bir kullanıcının profiline git ve ⭐ butonuna tıkla',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...favorites.map((favorite) => _buildFavoriteCard(context, favorite)),
          ],
        );
      },
    );
  }

  /// Tek bir favori kart
  Widget _buildFavoriteCard(BuildContext context, UserProfile favorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: favorite.photoUrl != null
                ? NetworkImage(favorite.photoUrl!)
                : null,
            child: favorite.photoUrl == null
                ? Text(
                    favorite.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            favorite.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('@${favorite.username}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
          onTap: () {
            Get.to(() => UserProfileScreen(user: favorite));
          },
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverPhotoUrl) {
    // Check if it's a base64 image or a URL
    if (coverPhotoUrl.startsWith('data:image')) {
      // Base64 image - extract and decode
      try {
        final base64String = coverPhotoUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildGradientFallback();
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return _buildGradientFallback();
      }
    } else {
      // Network URL
      return Image.network(
        coverPhotoUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGradientFallback();
        },
      );
    }
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.accent,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletion(BuildContext context, UserProfile user) {
    final completion = user.getProfileCompletionPercentage();
    final missing = user.getMissingProfileFields();

    if (completion == 100) {
      return const SizedBox.shrink(); // Profil %100 tamamsa gösterme
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil Tamamlama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '%$completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: completion >= 80
                      ? Colors.green
                      : completion >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80
                    ? Colors.green
                    : completion >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Eksik: ${missing.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
