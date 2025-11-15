import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/tournament_match_confirmation_screen.dart';
import 'package:playmatchr/screens/tournament_match_result_screen.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class TournamentBracketWidget extends StatelessWidget {
  final String tournamentId;
  final Tournament tournament;
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  TournamentBracketWidget({
    super.key,
    required this.tournamentId,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentMatch>>(
      stream: _firestoreService.getTournamentMatches(tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.sports_score, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Fikstür henüz oluşturulmadı.'),
              ],
            ),
          );
        }

        final matches = snapshot.data!;
        final matchesByRound = <int, List<TournamentMatch>>{};
        int maxRound = 0;

        for (var match in matches) {
          matchesByRound.putIfAbsent(match.round, () => []).add(match);
          if (match.round > maxRound) {
            maxRound = match.round;
          }
        }

        // Ensure all rounds have sorted matches
        matchesByRound.forEach((round, matchList) {
          matchList.sort(
            (a, b) => a.matchNumberInRound.compareTo(b.matchNumberInRound),
          );
        });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(maxRound, (index) {
              final round = index + 1;
              final roundMatches = matchesByRound[round] ?? [];
              return _buildRoundColumn(context, round, roundMatches, maxRound);
            }),
          ),
        );
      },
    );
  }

  Widget _buildRoundColumn(
    BuildContext context,
    int round,
    List<TournamentMatch> matches,
    int maxRound,
  ) {
    // Add spacing between rounds, but not after the final round
    final isFinalRound = round == maxRound;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: matches.map((match) {
          return _buildMatchCard(context, match, isFinalRound);
        }).toList(),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    TournamentMatch match,
    bool isFinal,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isParticipant =
        match.player1Id == userId || match.player2Id == userId;

    // Sonuç girilmemiş mi?
    final canEnterResult =
        isParticipant &&
        match.status == TournamentMatchStatus.scheduled &&
        match.player1Id != null &&
        match.player2Id != null &&
        match.resultStatus == 'no_result';

    // Onay bekliyor mu ve kullanıcı henüz onaylamamış mı?
    final needsConfirmation =
        isParticipant &&
        match.resultStatus == 'pending_confirmation' &&
        !match.resultConfirmedBy.contains(userId);

    final isClickable = canEnterResult || needsConfirmation;

    return InkWell(
      onTap: isClickable
          ? () {
              if (canEnterResult) {
                Get.to(
                  () => TournamentMatchResultScreen(
                    tournamentId: tournamentId,
                    matchId: match.id,
                  ),
                );
              } else if (needsConfirmation) {
                Get.to(
                  () => TournamentMatchConfirmationScreen(
                    tournamentId: tournamentId,
                    matchId: match.id,
                  ),
                );
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isClickable
              ? Border.all(
                  color: needsConfirmation
                      ? Colors.orange.withOpacity(0.7)
                      : Colors.green.withOpacity(0.5),
                  width: 2,
                )
              : match.resultStatus == 'confirmed'
              ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildPlayerTile(
              match.player1Id,
              match.winnerId,
              match.player1Score,
            ),
            const Divider(height: 1),
            _buildPlayerTile(
              match.player2Id,
              match.winnerId,
              match.player2Score,
            ),

            // Sonuç gir butonu
            if (canEnterResult)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Sonuç Gir',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Onay bekliyor
            if (needsConfirmation)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Onayla',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Beklemede
            if (match.status == TournamentMatchStatus.inProgress)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Beklemede',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Onaylandı
            if (match.resultStatus == 'confirmed')
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Tamamlandı',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
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

  Widget _buildPlayerTile(
    String? playerId,
    String? winnerId,
    Map<String, dynamic>? score,
  ) {
    final isWinner = playerId != null && playerId == winnerId;
    final isTeamSport = getSportCategory(tournament.sport) == MatchType.team;

    // Takım sporu için takım bilgilerini çek
    if (isTeamSport && playerId != null) {
      return FutureBuilder<TournamentTeam?>(
        future: _firestoreService.getTournamentTeamByCaptain(
          tournamentId,
          playerId,
        ),
        builder: (context, snapshot) {
          final team = snapshot.data;

          // Skoru göster
          String? scoreText;
          if (score != null) {
            if (score.containsKey('score')) {
              scoreText = score['score'].toString();
            } else if (score.containsKey('sets')) {
              final sets = score['sets'] as List;
              scoreText = sets.join(' ');
            }
          }

          // Takım rengini parse et
          Color? teamColor;
          if (team?.primaryColor != null) {
            try {
              teamColor = Color(
                int.parse(team!.primaryColor!.replaceFirst('#', '0xFF')),
              );
            } catch (e) {
              teamColor = null;
            }
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isWinner
                  ? (teamColor ?? Colors.green).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Takım renk göstergesi
                if (teamColor != null)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: teamColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (teamColor != null) const SizedBox(width: 8),
                // Takım ismi
                Expanded(
                  child: Text(
                    team?.teamName ?? 'Takım',
                    style: TextStyle(
                      fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
                      color: isWinner ? (teamColor ?? Colors.green.shade800) : null,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (scoreText != null)
                  Text(
                    scoreText,
                    style: TextStyle(
                      fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      color: isWinner ? (teamColor ?? Colors.green.shade800) : null,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    // Bireysel sporlar için eski kod
    return FutureBuilder<UserProfile?>(
      future: playerId != null
          ? _firestoreService.getUserProfile(playerId)
          : null,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Skoru göster
        String? scoreText;
        if (score != null) {
          if (score.containsKey('score')) {
            // Simple score (futbol, basketbol)
            scoreText = score['score'].toString();
          } else if (score.containsKey('sets')) {
            // Set-based score (tenis, voleybol)
            final sets = score['sets'] as List;
            scoreText = sets.join(' ');
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isWinner
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  user?.displayName ?? (playerId != null ? 'Oyuncu' : 'TBD'),
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner ? Colors.green.shade800 : null,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (scoreText != null)
                Text(
                  scoreText,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner ? Colors.green.shade800 : null,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
