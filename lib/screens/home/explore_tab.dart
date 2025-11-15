import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/match_result_confirmation_screen.dart';
import 'package:playmatchr/screens/match_result_screen.dart';
import 'package:playmatchr/screens/rate_match_screen.dart';
import 'package:playmatchr/widgets/match_card.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchController matchController = Get.find<MatchController>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xFF00897B),
          flexibleSpace: FlexibleSpaceBar(
            title: const DefaultTextStyle(
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Roboto',
              ),
              child: Text(
                'Keşfet',
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF00897B),
                    Color(0xFF00796B),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(() {
          final discoveryMatches = matchController.discoveryMatches.value;

          if (discoveryMatches.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.explore_off_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 32),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontFamily: 'Roboto',
                      ),
                      child: const Text(
                        'Hiç Maç Bulunamadı',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Roboto',
                      ),
                      child: const Text(
                        'Tercihlerinize uygun maç bulunamadı. Lütfen daha sonra tekrar deneyin.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final match = discoveryMatches[index];
                return MatchCard(
                  match: match,
                  onTap: () {
                    _showMatchDetails(context, match);
                  },
                );
              },
              childCount: discoveryMatches.length,
            ),
          );
        }),
      ],
    );
  }

  void _showMatchDetails(BuildContext context, Match match) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'tr_TR');
    final AuthController authController = Get.find<AuthController>();

    // Debug logs
    final now = DateTime.now();
    final matchEndTime =
        match.dateTime.add(Duration(minutes: match.durationMinutes));
    debugPrint('📅 Match Details Debug:');
    debugPrint('   Current time: $now');
    debugPrint('   Match date: ${match.dateTime}');
    debugPrint('   Match duration: ${match.durationMinutes} minutes');
    debugPrint('   Match end time: $matchEndTime');
    debugPrint('   Is finished: ${_isMatchFinished(match)}');
    debugPrint('   Current user: ${authController.user.value?.uid}');
    debugPrint(
        '   Team1 players: ${match.team1Players.map((p) => p.userId).toList()}');
    debugPrint(
        '   Team2 players: ${match.team2Players.map((p) => p.userId).toList()}');
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
                      content:
                          match.location.venueName ?? match.location.address,
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
                      if (_shouldShowResultButton(
                          match, authController.user.value!.uid)) ...[
                        _buildResultActionButton(
                            match, authController.user.value!.uid),
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
                              Icon(Icons.info_outline,
                                  color: Colors.grey[600]),
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
                              onPressed: () {
                                // TODO: Join match
                                Get.snackbar(
                                  'Başarılı',
                                  'Maça katılma özelliği yakında eklenecek',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                                child: Text('Katıl'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
    final matchEndTime =
        match.dateTime.add(Duration(minutes: match.durationMinutes));
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
    final matchEndTime =
        match.dateTime.add(Duration(minutes: match.durationMinutes));

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
}
