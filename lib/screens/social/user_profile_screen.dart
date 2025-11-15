import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:playmatchr/controllers/social_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/utils/time_helper.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfile user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int matchCount = 0;
  List<Match> recentMatches = [];
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final favorite = await _firestoreService.isUserFavorite(
        currentUserId,
        widget.user.uid,
      );
      setState(() => isFavorite = favorite);
    }
  }

  Future<void> _loadUserStats() async {
    setState(() => isLoading = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Load matches where user is a participant
      final matchesSnapshot = await firestore
          .collection('matches')
          .where('status', whereIn: ['pending', 'confirmed', 'completed'])
          .get();

      final userMatches = <Match>[];

      for (var doc in matchesSnapshot.docs) {
        try {
          final match = Match.fromFirestore(doc);

          // Check if user is in team1 or team2
          final isInTeam1 = match.team1Players.any((p) => p.userId == widget.user.uid);
          final isInTeam2 = match.team2Players.any((p) => p.userId == widget.user.uid);

          if (isInTeam1 || isInTeam2) {
            userMatches.add(match);
          }
        } catch (e) {
          print('Error parsing match ${doc.id}: $e');
        }
      }

      // Sort by date (most recent first)
      userMatches.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        matchCount = userMatches.length;
        recentMatches = userMatches.take(5).toList();
        isLoading = false;
      });

      print('═══════════════════════════════════════');
      print('📊 USER PROFILE STATS');
      print('───────────────────────────────────────');
      print('👤 Kullanıcı: ${widget.user.displayName} (@${widget.user.username})');
      print('👥 Arkadaş Sayısı: ${widget.user.friends.length}');
      print('⚽ Takım Sayısı: ${widget.user.myTeams.length}');
      print('🏆 Maç Sayısı: $matchCount');
      print('📅 Son Aktiviteler: ${recentMatches.length} maç');
      if (recentMatches.isNotEmpty) {
        print('   └─ Son maç: ${recentMatches.first.sportType} (${_formatDate(recentMatches.first.dateTime)})');
      }
      print('═══════════════════════════════════════');
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final SocialController socialController = Get.find<SocialController>();

    // Spor dallarına göre gradient renkleri
    final sportGradient = _getSportGradient(user.favoriteSports.isNotEmpty
        ? user.favoriteSports.first
        : 'default');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Compact Header with Wave Design
          SliverAppBar(
            expandedHeight: 140,
            pinned: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Stack(
              children: [
                // Wave Header
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(gradient: sportGradient),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        // User info
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 30,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DefaultTextStyle(
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                                child: Text(user.displayName),
                              ),
                              const SizedBox(height: 4),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'Roboto',
                                ),
                                child: Text('@${user.username}'),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TimeHelper.getOnlineIndicator(user.lastSeen, size: 10),
                                  const SizedBox(width: 6),
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Roboto',
                                    ),
                                    child: Text(TimeHelper.getLastSeenText(user.lastSeen)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.white,
                      ),
                      onPressed: () async {
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        if (currentUserId != null) {
                          try {
                            if (isFavorite) {
                              await _firestoreService.removeUserFromFavorites(
                                currentUserId,
                                widget.user.uid,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Favorilerden çıkarıldı')),
                              );
                            } else {
                              await _firestoreService.addUserToFavorites(
                                currentUserId,
                                widget.user.uid,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Favorilere eklendi ⭐')),
                              );
                            }
                            _checkIfFavorite();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                // More button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showMoreOptions(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Image - overlapping the wave
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 50),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: sportGradient,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: sportGradient,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                // Bio
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.4,
                              fontFamily: 'Roboto',
                            ),
                            child: Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    children: [
                      // Action Button
                      Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Obx(() {
                      final isFriend = socialController.isFriend(user.uid);
                      final hasSentRequest = socialController.hasSentRequest(user.uid);
                      final hasReceivedRequest = socialController.hasReceivedRequest(user.uid);

                      if (hasReceivedRequest) {
                        // Show accept/reject buttons
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => socialController.acceptFriendRequest(user.uid),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded),
                                label: const DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Roboto',
                                  ),
                                  child: Text('Kabul Et'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => socialController.rejectFriendRequest(user.uid),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded),
                                label: DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                    fontFamily: 'Roboto',
                                  ),
                                  child: const Text('Reddet'),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isFriend) {
                              _showRemoveFriendDialog(context, socialController, user);
                            } else if (hasSentRequest) {
                              socialController.cancelFriendRequest(user.uid);
                            } else {
                              socialController.sendFriendRequest(user.uid);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFriend
                                ? Colors.grey[200]
                                : hasSentRequest
                                    ? Colors.grey[100]
                                    : const Color(0xFF1E3A8A),
                            foregroundColor: isFriend || hasSentRequest
                                ? Colors.grey[700]
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: isFriend || hasSentRequest ? 0 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isFriend || hasSentRequest
                                  ? BorderSide(color: Colors.grey[300]!)
                                  : BorderSide.none,
                            ),
                          ),
                          icon: Icon(
                            isFriend
                                ? Icons.check_rounded
                                : hasSentRequest
                                    ? Icons.schedule_rounded
                                    : Icons.person_add_rounded,
                          ),
                          label: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isFriend || hasSentRequest
                                  ? Colors.grey[700]
                                  : Colors.white,
                              fontFamily: 'Roboto',
                            ),
                            child: Text(
                              isFriend
                                  ? 'Arkadaş'
                                  : hasSentRequest
                                      ? 'İstek Gönderildi'
                                      : 'Arkadaş Ekle',
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people_rounded,
                            count: user.friends.length,
                            label: 'Arkadaş',
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.sports_soccer_rounded,
                            count: user.myTeams.length,
                            label: 'Takım',
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isLoading
                              ? _buildStatCard(
                                  icon: Icons.emoji_events_rounded,
                                  count: 0,
                                  label: 'Maç',
                                  color: const Color(0xFF10B981),
                                )
                              : _buildStatCard(
                                  icon: Icons.emoji_events_rounded,
                                  count: matchCount,
                                  label: 'Maç',
                                  color: const Color(0xFF10B981),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Favorite Sports Section
                  if (user.favoriteSports.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          child: const Text('Favori Sporlar'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.favoriteSports.map((sport) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: _getSportGradient(sport),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getSportGradient(sport).colors.first.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSportIcon(sport),
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Roboto',
                                  ),
                                  child: Text(sport),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Recent Activity Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                        ),
                        child: const Text('Son Aktiviteler'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : recentMatches.isEmpty
                            ? _buildEmptyActivity()
                            : _buildRecentMatches(),
                  ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Roboto',
            ),
            child: Text(count.toString()),
          ),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontFamily: 'Roboto',
            ),
            child: const Text('Henüz aktivite yok'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatches() {
    return Column(
      children: recentMatches.map((match) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Sport Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getSportGradient(match.sportType).colors.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getSportIcon(match.sportType),
                  color: _getSportGradient(match.sportType).colors.first,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Match Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                      child: Text(match.sportType),
                    ),
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Roboto',
                      ),
                      child: Text(
                        '${_formatDate(match.dateTime)} • ${match.location.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(match.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(match.status),
                    fontFamily: 'Roboto',
                  ),
                  child: Text(_getStatusText(match.status)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} hafta önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'confirmed':
        return const Color(0xFF1E3A8A);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'confirmed':
        return 'Onaylandı';
      case 'cancelled':
        return 'İptal';
      default:
        return 'Bekliyor';
    }
  }

  LinearGradient _getSportGradient(String sport) {
    final sportLower = sport.toLowerCase();
    if (sportLower.contains('futbol') || sportLower.contains('football')) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (sportLower.contains('basketbol') || sportLower.contains('basketball')) {
      return const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFE55A2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (sportLower.contains('voleybol') || sportLower.contains('volleyball')) {
      return const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (sportLower.contains('tenis') || sportLower.contains('tennis')) {
      return const LinearGradient(
        colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (sportLower.contains('badminton')) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (sportLower.contains('masa tenisi') || sportLower.contains('table tennis')) {
      return const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  IconData _getSportIcon(String sport) {
    final sportLower = sport.toLowerCase();
    if (sportLower.contains('futbol') || sportLower.contains('football')) {
      return Icons.sports_soccer_rounded;
    } else if (sportLower.contains('basketbol') || sportLower.contains('basketball')) {
      return Icons.sports_basketball_rounded;
    } else if (sportLower.contains('voleybol') || sportLower.contains('volleyball')) {
      return Icons.sports_volleyball_rounded;
    } else if (sportLower.contains('tenis') || sportLower.contains('tennis')) {
      return Icons.sports_tennis_rounded;
    } else if (sportLower.contains('badminton')) {
      return Icons.sports_kabaddi_rounded;
    } else {
      return Icons.sports_rounded;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Favorilere Ekle/Çıkar
              ListTile(
                leading: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey[700],
                ),
                title: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800]!,
                    fontFamily: 'Roboto',
                  ),
                  child: Text(isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle'),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUserId != null) {
                    try {
                      if (isFavorite) {
                        await _firestoreService.removeUserFromFavorites(
                          currentUserId,
                          widget.user.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favorilerden çıkarıldı')),
                        );
                      } else {
                        await _firestoreService.addUserToFavorites(
                          currentUserId,
                          widget.user.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favorilere eklendi ⭐')),
                        );
                      }
                      _checkIfFavorite(); // Durumu güncelle
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.red),
                title: const DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontFamily: 'Roboto',
                  ),
                  child: Text('Engelle'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement block user
                },
              ),
              ListTile(
                leading: Icon(Icons.report_rounded, color: Colors.grey[700]),
                title: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontFamily: 'Roboto',
                  ),
                  child: const Text('Şikayet Et'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement report user
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(BuildContext context, SocialController controller, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const DefaultTextStyle(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
          child: Text('Arkadaşlıktan Çıkar'),
        ),
        content: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Roboto',
          ),
          child: Text(
            '${user.displayName} kişisini arkadaş listenizden çıkarmak istediğinize emin misiniz?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeFriend(user.uid);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }
}

// Wave Clipper for modern curved header
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    // Create wave effect
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    final secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
