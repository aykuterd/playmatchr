import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/widgets/match_card.dart';
import 'package:playmatchr/screens/match_result_screen.dart';
import 'package:playmatchr/screens/match_result_confirmation_screen.dart';
import 'package:playmatchr/screens/rate_match_screen.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/utils/time_helper.dart';
import 'package:playmatchr/screens/social/user_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final MatchController matchController = Get.find<MatchController>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Modern Wave Header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                ClipPath(
                  clipper: _HomeWaveClipper(),
                  child: Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1E3A8A),
                          Color(0xFF1E40AF),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
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
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Icons decoration
                        Positioned(
                          top: 40,
                          right: 50,
                          child: Icon(
                            Icons.sports_soccer,
                            size: 30,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: 60,
                          child: Icon(
                            Icons.sports_basketball,
                            size: 25,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Obx(
                        () => DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            letterSpacing: -0.5,
                          ),
                          child: Text(
                            'Merhaba, ${authController.userProfile.value?.displayName ?? authController.user.value?.email?.split('@')[0] ?? 'Oyuncu'}!',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Roboto',
                        ),
                        child: const Text(
                          'Bugün hangi maça katılmak istersin?',
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quick action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.add_circle_outline,
                              label: 'Maç Oluştur',
                              onTap: () {
                                // Navigate to create match screen
                                Get.toNamed('/create_match');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.search_rounded,
                              label: 'Maç Ara',
                              onTap: () {
                                // TODO: Navigate to search screen
                                Get.snackbar(
                                  'Yakında',
                                  'Maç arama özelliği yakında eklenecek',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Obx(() {
                final upcoming = matchController.upcomingMatches.value.length;
                final past = matchController.pastMatches.value.length;
                final invites = matchController.invitations.value.length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.event_available_rounded,
                        count: upcoming,
                        label: 'Yaklaşan',
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.history_rounded,
                        count: past,
                        label: 'Geçmiş',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.mail_rounded,
                        count: invites,
                        label: 'Davet',
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Nearby Players Section
          SliverToBoxAdapter(
            child: _buildNearbyPlayersSection(authController),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Discovery matches section (Personalized recommendations)
          Obx(() {
            final discoveryMatches = matchController.discoveryMatches.value;

            if (discoveryMatches.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Color(0xFF00897B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Roboto',
                            ),
                            child: Text(
                              'Sana Özel Maçlar',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to explore tab
                            Get.find<MatchController>().fetchDiscoveryMatches();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00897B),
                              fontFamily: 'Roboto',
                            ),
                            child: Text('Tümü'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      itemCount: discoveryMatches.take(5).length,
                      itemBuilder: (context, index) {
                        final match = discoveryMatches[index];
                        return SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: MatchCard(
                            match: match,
                            onTap: () {
                              _showMatchDetails(context, match);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),

          // Upcoming matches section
          Obx(() {
            final upcomingMatches = matchController.upcomingMatches.value;

            if (upcomingMatches.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontFamily: 'Roboto',
                        ),
                        child: const Text(
                          'Yaklaşan Maç Yok',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontFamily: 'Roboto',
                        ),
                        child: const Text(
                          'Yeni bir maç oluştur veya mevcut maçlara katıl',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          child: Text('Yaklaşan Maçlar'),
                        ),
                        const Spacer(),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                          ),
                          child: Text('${upcomingMatches.length}'),
                        ),
                      ],
                    ),
                  );
                }

                final match = upcomingMatches[index - 1];
                return MatchCard(
                  match: match,
                  onTap: () {
                    _showMatchDetails(context, match);
                  },
                );
              }, childCount: upcomingMatches.length + 1),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Past matches section
          Obx(() {
            final pastMatches = matchController.pastMatches.value;

            if (pastMatches.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          child: Text('Geçmiş Maçlar'),
                        ),
                      ],
                    ),
                  );
                }

                final match = pastMatches[index - 1];
                return Opacity(
                  opacity: 0.7,
                  child: MatchCard(
                    match: match,
                    onTap: () {
                      _showMatchDetails(context, match);
                    },
                  ),
                );
              }, childCount: pastMatches.length + 1),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

  void _showMatchDetails(BuildContext context, Match match) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'tr_TR');
    final AuthController authController = Get.find<AuthController>();

    // Debug logs
    final now = DateTime.now();
    final matchEndTime = match.dateTime.add(Duration(minutes: match.durationMinutes));
    debugPrint('📅 Match Details Debug:');
    debugPrint('   Current time: $now');
    debugPrint('   Match date: ${match.dateTime}');
    debugPrint('   Match duration: ${match.durationMinutes} minutes');
    debugPrint('   Match end time: $matchEndTime');
    debugPrint('   Is finished: ${_isMatchFinished(match)}');
    debugPrint('   Current user: ${authController.user.value?.uid}');
    debugPrint('   Team1 players: ${match.team1Players.map((p) => p.userId).toList()}');
    debugPrint('   Team2 players: ${match.team2Players.map((p) => p.userId).toList()}');
    debugPrint('   Result status: ${match.resultStatus}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Sport Type Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getSportIcon(match.sportType),
                            color: const Color(0xFF1E3A8A),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DefaultTextStyle(
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                ),
                                child: Text(match.sportType),
                              ),
                              const SizedBox(height: 4),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Roboto',
                                ),
                                child: Text(_getStatusText(match.status)),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(match.status),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date & Time
                    _buildInfoCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Tarih & Saat',
                      content: dateFormat.format(match.dateTime),
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      title: 'Konum',
                      content: match.location.venueName ?? match.location.address,
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(height: 12),

                    // Players Count
                    _buildInfoCard(
                      icon: Icons.people_rounded,
                      title: 'Oyuncular',
                      content: match.maxPlayersPerTeam != null
                          ? '${match.team1Players.length + match.team2Players.length} / ${match.maxPlayersPerTeam! * 2}'
                          : '${match.team1Players.length + match.team2Players.length}',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 24),

                    // Team 1
                    const DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                      child: Text('Takım 1'),
                    ),
                    const SizedBox(height: 12),
                    if (match.team1Players.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                          ),
                          child: const Text('Henüz oyuncu yok'),
                        ),
                      )
                    else
                      ...match.team1Players.map(
                        (player) => _buildPlayerTile(player),
                      ),
                    const SizedBox(height: 16),

                    // Team 2
                    const DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                      child: Text('Takım 2'),
                    ),
                    const SizedBox(height: 12),
                    if (match.team2Players.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                          ),
                          child: const Text('Henüz oyuncu yok'),
                        ),
                      )
                    else
                      ...match.team2Players.map(
                        (player) => _buildPlayerTile(player),
                      ),
                    const SizedBox(height: 24),

                    // Check if match has ended
                    if (_isMatchFinished(match)) ...[
                      // Result Action Button (if match is finished)
                      if (_shouldShowResultButton(match, authController.user.value!.uid)) ...[
                        _buildResultActionButton(match, authController.user.value!.uid),
                      ] else ...[
                        // Match is finished but user is not participant or result already handled
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto',
                                  ),
                                  child: const Text(
                                    'Bu maç tamamlanmış.',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // Action Buttons (only for upcoming matches)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: match.createdBy == authController.user.value?.uid
                                  ? null // Disabled for match creator
                                  : () {
                                      // TODO: Join match
                                      Get.snackbar(
                                        'Başarılı',
                                        'Maça katılma özelliği yakında eklenecek',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                              icon: Icon(
                                match.createdBy == authController.user.value?.uid
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                              ),
                              label: DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: match.createdBy == authController.user.value?.uid
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                                child: Text(
                                  match.createdBy == authController.user.value?.uid
                                      ? 'Kendi Maçınız'
                                      : 'Katıl',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: match.createdBy == authController.user.value?.uid
                                    ? Colors.grey
                                    : const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey,
                                disabledForegroundColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Share match
                              Get.snackbar(
                                'Paylaş',
                                'Paylaşma özelliği yakında eklenecek',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            icon: const Icon(Icons.share_outlined),
                            label: const DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                              child: Text('Paylaş'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                  child: Text(title),
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Roboto',
                  ),
                  child: Text(content),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(TeamPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF1E3A8A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Roboto',
              ),
              child: Text(player.userName),
            ),
          ),
          if (player.isReserve)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                  fontFamily: 'Roboto',
                ),
                child: Text('Yedek'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                  fontFamily: 'Roboto',
                ),
                child: Text('Ana Kadro'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Bekliyor';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'Onaylandı';
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Tamamlandı';
        icon = Icons.flag;
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'İptal';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Roboto',
            ),
            child: Text(text),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'futbol':
        return Icons.sports_soccer;
      case 'basketbol':
        return Icons.sports_basketball;
      case 'voleybol':
        return Icons.sports_volleyball;
      case 'tenis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Oyuncu bekleniyor';
      case 'confirmed':
        return 'Maç onaylandı';
      case 'completed':
        return 'Maç tamamlandı';
      case 'cancelled':
        return 'Maç iptal edildi';
      default:
        return status;
    }
  }

  bool _isMatchFinished(Match match) {
    final now = DateTime.now();
    final matchEndTime = match.dateTime.add(Duration(minutes: match.durationMinutes));
    final isFinished = matchEndTime.isBefore(now);

    debugPrint('🏁 _isMatchFinished Check:');
    debugPrint('   Now: $now');
    debugPrint('   Match date: ${match.dateTime}');
    debugPrint('   Duration: ${match.durationMinutes} min');
    debugPrint('   Match end: $matchEndTime');
    debugPrint('   Is finished: $isFinished');

    return isFinished;
  }

  bool _shouldShowResultButton(Match match, String userId) {
    final now = DateTime.now();
    final matchEndTime = match.dateTime.add(Duration(minutes: match.durationMinutes));

    // Only show if match has ended
    if (matchEndTime.isAfter(now)) return false;

    // Check if user is a participant
    final isParticipant = match.team1Players.any((p) => p.userId == userId) ||
        match.team2Players.any((p) => p.userId == userId);

    if (!isParticipant) return false;

    // Show button if:
    // 1. No result submitted yet (can submit)
    // 2. Result submitted but user hasn't confirmed yet (can confirm)
    // 3. Result is disputed (show status)
    // 4. Result is confirmed (can rate)

    return match.resultStatus == 'no_result' ||
           match.resultStatus == 'pending_confirmation' ||
           match.resultStatus == 'confirmed' ||
           match.resultStatus == 'disputed';
  }

  Widget _buildResultActionButton(Match match, String userId) {
    final bool hasUserRated =
        match.playerRatings.any((rating) => rating['raterId'] == userId);

    if (match.resultStatus == 'no_result') {
      // User can submit result
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.back(); // Close bottom sheet
            Get.to(() => MatchResultScreen(matchId: match.id));
          },
          icon: const Icon(Icons.sports_score),
          label: const DefaultTextStyle(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
            child: Text('Maç Sonucunu Gir'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (match.resultStatus == 'pending_confirmation') {
      // Check if user has already confirmed
      if (match.resultConfirmedBy.contains(userId)) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  child: const Text(
                    'Sonucu onayladınız. Diğer oyuncuların onayı bekleniyor.',
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // User needs to confirm
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.back(); // Close bottom sheet
              Get.to(() => MatchResultConfirmationScreen(matchId: match.id));
            },
            icon: const Icon(Icons.check_circle),
            label: const DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
              child: Text('Maç Sonucunu Onayla'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    } else if (match.resultStatus == 'confirmed') {
      if (hasUserRated) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  child: const Text(
                    'Oyuncuları zaten değerlendirdiniz. Teşekkürler!',
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.back(); // Close bottom sheet
              Get.to(() => RateMatchScreen(match: match));
            },
            icon: const Icon(Icons.star_rate_rounded),
            label: const DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
              child: Text('Oyuncuları Değerlendir'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    } else if (match.resultStatus == 'disputed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
                child: const Text(
                  'Maç sonucunda anlaşmazlık var. Bu maç için puan işlemi yapılmayacak.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNearbyPlayersSection(AuthController authController) {
    final FirestoreService firestoreService = FirestoreService();
    final user = authController.userProfile.value;

    if (user == null || user.preferredCity == null || user.preferredDistrict == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<UserProfile>>(
      future: firestoreService.getNearbyUsers(
        currentUserId: user.uid,
        city: user.preferredCity!,
        district: user.preferredDistrict!,
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final nearbyUsers = snapshot.data ?? [];

        if (nearbyUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFFF6B35),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          child: Text('Yakınımdaki Sporcular'),
                        ),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                          ),
                          child: Text('${user.preferredDistrict}, ${user.preferredCity}'),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.snackbar(
                        'Yakında',
                        'Tüm kullanıcıları göster özelliği yakında eklenecek',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: const DefaultTextStyle(
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                      child: Text('Tümü →'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: nearbyUsers.length,
                itemBuilder: (context, index) {
                  return _buildNearbyUserCard(nearbyUsers[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildNearbyUserCard(UserProfile user) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.to(() => UserProfileScreen(user: user));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: TimeHelper.getOnlineIndicator(user.lastSeen, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        user.preferredDistrict ?? user.preferredCity ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick action button
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.toNamed('/create_match', arguments: {'suggestedOpponent': user});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Maç Öner',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Wave Clipper for Home Header
class _HomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 10);
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
