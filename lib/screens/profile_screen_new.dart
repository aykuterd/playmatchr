import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_spacing.dart';

/// Modern ve şık profil ekranı
class ProfileScreenNew extends StatefulWidget {
  const ProfileScreenNew({super.key});

  @override
  State<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends State<ProfileScreenNew> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final profile = await _firestoreService.getUserProfile(userId);
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Profil yüklenemedi'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(context),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildProfileHeader(context),
                            _buildStatsCards(context),
                            _buildAchievementsSection(context),
                            const SizedBox(height: AppSpacing.xl),
                            _buildTabSection(context),
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildMatchHistoryTab(context),
                                  _buildFavoritesTab(context),
                                  _buildAboutTab(context),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Modern SliverAppBar
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Ayarlar ekranına git
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }

  /// Profil başlığı (Avatar + İsim + Bio)
  Widget _buildProfileHeader(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _userProfile!.photoUrl != null
                  ? NetworkImage(_userProfile!.photoUrl!)
                  : null,
              child: _userProfile!.photoUrl == null
                  ? Text(
                      _userProfile!.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // İsim
          Text(
            _userProfile!.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Username
          Text(
            '@${_userProfile!.username}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _userProfile!.bio!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// İstatistik kartları (Grid)
  Widget _buildStatsCards(BuildContext context) {
    final stats = [
      _StatCard(
        icon: Icons.sports_tennis,
        label: 'Toplam Maç',
        value: '${_userProfile!.totalMatchesPlayed}',
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.emoji_events,
        label: 'Galibiyet',
        value: '${_userProfile!.matchesWon}',
        color: Colors.green,
      ),
      _StatCard(
        icon: Icons.trending_down,
        label: 'Mağlubiyet',
        value: '${_userProfile!.matchesLost}',
        color: Colors.red,
      ),
      _StatCard(
        icon: Icons.percent,
        label: 'Kazanma Oranı',
        value: _userProfile!.totalMatchesPlayed > 0
            ? '${((_userProfile!.matchesWon / _userProfile!.totalMatchesPlayed) * 100).toStringAsFixed(0)}%'
            : '0%',
        color: Colors.orange,
      ),
      _StatCard(
        icon: Icons.star,
        label: 'ELO Puanı',
        value: '${_userProfile!.eloRating}',
        color: Colors.purple,
      ),
      _StatCard(
        icon: Icons.sentiment_satisfied_alt,
        label: 'Sportmenlik',
        value: _userProfile!.sportsmanshipScore.toStringAsFixed(1),
        color: Colors.teal,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(
            context,
            icon: stat.icon,
            label: stat.label,
            value: stat.value,
            color: stat.color,
          );
        },
      ),
    );
  }

  /// Tek bir istatistik kartı
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Rozetler bölümü
  Widget _buildAchievementsSection(BuildContext context) {
    if (_userProfile!.achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade100,
            Colors.orange.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rozetler (${_userProfile!.achievements.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _userProfile!.achievements.map((achievementStr) {
              final achievement = Achievements.fromString(achievementStr);
              if (achievement == null) return const SizedBox.shrink();

              return _buildAchievementBadge(achievement);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Rozet badge'i
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
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sekmeler (Tabs)
  Widget _buildTabSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: const [
          Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
          Tab(icon: Icon(Icons.star), text: 'Favoriler'),
          Tab(icon: Icon(Icons.info), text: 'Hakkında'),
        ],
      ),
    );
  }

  /// Maç geçmişi sekmesi
  Widget _buildMatchHistoryTab(BuildContext context) {
    return const Center(
      child: Text('Maç geçmişi yakında eklenecek'),
    );
  }

  /// Favoriler sekmesi
  Widget _buildFavoritesTab(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: _firestoreService.getFavoriteUsers(_userProfile!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Henüz favori oyuncun yok'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text('@${user.username}'),
                trailing: IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () async {
                    await _firestoreService.removeUserFromFavorites(
                      _userProfile!.uid,
                      user.uid,
                    );
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hakkında sekmesi
  Widget _buildAboutTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email, 'E-posta', _userProfile!.email),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(Icons.calendar_today, 'Üyelik',
              '${_userProfile!.createdAt.day}/${_userProfile!.createdAt.month}/${_userProfile!.createdAt.year}'),
          if (_userProfile!.favoriteSports.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow(
              Icons.sports,
              'Favori Sporlar',
              _userProfile!.favoriteSports.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

/// İstatistik kartı veri modeli
class _StatCard {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
