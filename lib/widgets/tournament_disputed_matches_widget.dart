import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/services/match_result_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

/// Widget to display disputed tournament matches for admin review
class TournamentDisputedMatchesWidget extends StatefulWidget {
  final String tournamentId;

  const TournamentDisputedMatchesWidget({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDisputedMatchesWidget> createState() =>
      _TournamentDisputedMatchesWidgetState();
}

class _TournamentDisputedMatchesWidgetState
    extends State<TournamentDisputedMatchesWidget> {
  final MatchResultService _matchResultService = MatchResultService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _resolveDispute(
    Map<String, dynamic> disputedMatch,
    String resolution,
  ) async {
    final matchId = disputedMatch['matchId'] as String;
    final match = disputedMatch['match'] as TournamentMatch;

    // Confirm dialog
    final confirm = await _showConfirmDialog(
      resolution == 'confirm'
          ? 'Sonucu onayla'
          : 'Sonucu reddet ve maçı yeniden oynat',
    );

    if (confirm != true) return;

    try {
      await _matchResultService.resolveDisputedTournamentMatch(
        tournamentId: widget.tournamentId,
        matchId: matchId,
        resolution: resolution,
        adminNotes: 'Admin tarafından çözüldü',
      );

      Get.snackbar(
        'Başarılı',
        resolution == 'confirm'
            ? 'Maç sonucu onaylandı'
            : 'Maç sonucu reddedildi ve maç yeniden oynanabilir',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      setState(() {}); // Refresh the list
    } catch (e) {
      debugPrint('Error resolving dispute: $e');
      Get.snackbar(
        'Hata',
        'Anlaşmazlık çözülürken hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _matchResultService.getDisputedTournamentMatches(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Anlaşmazlık olan maç yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tüm maçlar sorunsuz bir şekilde tamamlandı',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final disputedMatches = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: disputedMatches.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final disputedMatch = disputedMatches[index];
            return _buildDisputedMatchCard(disputedMatch);
          },
        );
      },
    );
  }

  Widget _buildDisputedMatchCard(Map<String, dynamic> disputedMatch) {
    final match = disputedMatch['match'] as TournamentMatch;
    final disputeReason = disputedMatch['disputeReason'] as String?;
    final disputedBy = disputedMatch['disputedBy'] as String?;
    final disputedAt = disputedMatch['disputedAt'] as Timestamp?;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ANLAŞMAZLIK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Tur ${match.round}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Players
            FutureBuilder<List<UserProfile?>>(
              future: Future.wait([
                match.player1Id != null
                    ? _firestoreService.getUserProfile(match.player1Id!)
                    : Future.value(null),
                match.player2Id != null
                    ? _firestoreService.getUserProfile(match.player2Id!)
                    : Future.value(null),
              ]),
              builder: (context, snapshot) {
                final player1 = snapshot.data?[0];
                final player2 = snapshot.data?[1];

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: player1?.photoUrl != null
                                ? NetworkImage(player1!.photoUrl!)
                                : null,
                            child: player1?.photoUrl == null
                                ? Text(player1?.displayName[0].toUpperCase() ?? 'O')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            player1?.displayName ?? 'Oyuncu 1',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: player2?.photoUrl != null
                                ? NetworkImage(player2!.photoUrl!)
                                : null,
                            child: player2?.photoUrl == null
                                ? Text(player2?.displayName[0].toUpperCase() ?? 'O')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            player2?.displayName ?? 'Oyuncu 2',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(height: AppSpacing.xl),

            // Score
            if (match.player1Score != null && match.player2Score != null) ...[
              const Text(
                'Bildirilen Skor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...match.player1Score!.entries.map((entry) {
                final setNumber = entry.key;
                final p1Score = entry.value;
                final p2Score = match.player2Score![setNumber] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        setNumber.replaceAll('set', 'Set '),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '$p1Score - $p2Score',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: AppSpacing.xl),
            ],

            // Dispute info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.orange, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'İtiraz Nedeni',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _getDisputeReasonText(disputeReason),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (disputedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'İtiraz zamanı: ${DateFormat('dd MMM yyyy, HH:mm').format(disputedAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveDispute(disputedMatch, 'reject'),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveDispute(disputedMatch, 'confirm'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDisputeReasonText(String? reason) {
    switch (reason) {
      case 'wrong_score':
        return 'Skor yanlış girilmiş';
      case 'different_result':
        return 'Maç farklı bitti';
      case 'match_not_played':
        return 'Maç oynanmadı';
      case 'other':
        return 'Diğer';
      default:
        return reason ?? 'Belirtilmemiş';
    }
  }
}
