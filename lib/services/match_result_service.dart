import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:playmatchr/models/firestore_models.dart';

/// Service for handling match results, confirmations, and timeout logic
class MatchResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for matches with expired confirmation deadlines and auto-confirm them
  /// This should be called periodically (e.g., on app start, when viewing matches)
  Future<void> processExpiredConfirmations() async {
    try {
      final now = DateTime.now();

      // Query matches that are pending confirmation and past deadline
      final querySnapshot = await _firestore
          .collection('matches')
          .where('resultStatus', isEqualTo: 'pending_confirmation')
          .where('resultConfirmationDeadline', isLessThan: Timestamp.fromDate(now))
          .limit(50)
          .get();

      debugPrint('🕐 Processing ${querySnapshot.docs.length} expired confirmations');

      for (var doc in querySnapshot.docs) {
        try {
          final match = Match.fromFirestore(doc);

          debugPrint('⏰ Auto-confirming match ${match.id} (deadline expired)');

          // Auto-confirm the result (timeout reached)
          await _firestore.collection('matches').doc(match.id).update({
            'resultStatus': 'confirmed',
            'status': 'completed',
            'updatedAt': Timestamp.fromDate(now),
          });

          debugPrint('✅ Match ${match.id} auto-confirmed successfully');
        } catch (e) {
          debugPrint('❌ Error auto-confirming match ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing expired confirmations: $e');
    }
  }

  /// Check if current user needs to confirm a match result
  Future<bool> needsConfirmation(String matchId, String userId) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();

      if (!doc.exists) return false;

      final match = Match.fromFirestore(doc);

      // Check if match has a pending result
      if (match.resultStatus != 'pending_confirmation') return false;

      // Check if user is a participant
      final isParticipant = match.team1Players.any((p) => p.userId == userId) ||
          match.team2Players.any((p) => p.userId == userId);

      if (!isParticipant) return false;

      // Check if user has already confirmed
      if (match.resultConfirmedBy.contains(userId)) return false;

      return true;
    } catch (e) {
      debugPrint('Error checking confirmation need: $e');
      return false;
    }
  }

  /// Get list of matches awaiting confirmation from user
  Future<List<Match>> getPendingConfirmations(String userId) async {
    try {
      // Get matches where result is pending confirmation
      final querySnapshot = await _firestore
          .collection('matches')
          .where('resultStatus', isEqualTo: 'pending_confirmation')
          .orderBy('resultSubmittedAt', descending: true)
          .limit(50)
          .get();

      final matches = <Match>[];

      for (var doc in querySnapshot.docs) {
        try {
          final match = Match.fromFirestore(doc);

          // Check if user is a participant and hasn't confirmed
          final isParticipant = match.team1Players.any((p) => p.userId == userId) ||
              match.team2Players.any((p) => p.userId == userId);

          if (isParticipant && !match.resultConfirmedBy.contains(userId)) {
            matches.add(match);
          }
        } catch (e) {
          debugPrint('Error parsing match ${doc.id}: $e');
        }
      }

      return matches;
    } catch (e) {
      debugPrint('Error getting pending confirmations: $e');
      return [];
    }
  }

  /// Check if user is eligible to submit result for a match
  bool canSubmitResult(Match match, String userId) {
    // Can only submit if:
    // 1. Match is finished (dateTime has passed)
    // 2. User is a participant
    // 3. Result hasn't been submitted yet

    final now = DateTime.now();
    final matchHasEnded = match.dateTime
        .add(Duration(minutes: match.durationMinutes))
        .isBefore(now);

    if (!matchHasEnded) return false;

    final isParticipant = match.team1Players.any((p) => p.userId == userId) ||
        match.team2Players.any((p) => p.userId == userId);

    if (!isParticipant) return false;

    // Check if result already submitted
    if (match.resultStatus != 'no_result') return false;

    return true;
  }

  /// Get match result summary
  Map<String, dynamic> getResultSummary(Match match) {
    return {
      'hasResult': match.resultStatus != 'no_result',
      'isConfirmed': match.resultStatus == 'confirmed',
      'isPending': match.resultStatus == 'pending_confirmation',
      'isDisputed': match.resultStatus == 'disputed',
      'winner': match.winner,
      'score': match.score,
      'submittedBy': match.resultSubmittedBy,
      'submittedAt': match.resultSubmittedAt,
      'confirmationCount': match.resultConfirmedBy.length,
      'deadline': match.resultConfirmationDeadline,
      'disputeReason': match.disputeReason,
    };
  }

  /// Send reminders to users who haven't confirmed yet
  /// This could be called by a scheduled job or manually
  Future<void> sendConfirmationReminders() async {
    try {
      final now = DateTime.now();
      final reminderThreshold = now.add(const Duration(hours: 6));

      // Get matches with deadline approaching (within 6 hours)
      final querySnapshot = await _firestore
          .collection('matches')
          .where('resultStatus', isEqualTo: 'pending_confirmation')
          .where('resultConfirmationDeadline', isLessThan: Timestamp.fromDate(reminderThreshold))
          .where('resultConfirmationDeadline', isGreaterThan: Timestamp.fromDate(now))
          .limit(50)
          .get();

      debugPrint('📢 Sending reminders for ${querySnapshot.docs.length} matches');

      for (var doc in querySnapshot.docs) {
        try {
          final match = Match.fromFirestore(doc);

          // Get all participants who haven't confirmed
          final allParticipants = <String>{};
          for (var player in match.team1Players) {
            allParticipants.add(player.userId);
          }
          for (var player in match.team2Players) {
            allParticipants.add(player.userId);
          }

          final pendingUsers = allParticipants
              .where((userId) => !match.resultConfirmedBy.contains(userId))
              .toList();

          debugPrint('   Match ${match.id}: ${pendingUsers.length} users need reminder');

          // Note: Actual notification sending would happen here
          // For now, we just log the intent
          // In production, this would integrate with NotificationController
        } catch (e) {
          debugPrint('❌ Error sending reminder for match ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending confirmation reminders: $e');
    }
  }

  /// Calculate statistics for dispute tracking
  Future<Map<String, dynamic>> getUserDisputeStats(String userId) async {
    try {
      // Get all completed matches for user
      final matches = await _firestore
          .collection('matches')
          .where('status', whereIn: ['completed', 'finished'])
          .orderBy('dateTime', descending: true)
          .limit(100)
          .get();

      int totalMatches = 0;
      int confirmedMatches = 0;
      int disputedMatches = 0;
      int userInitiatedDisputes = 0;

      for (var doc in matches.docs) {
        try {
          final data = doc.data();
          final team1Players = (data['team1Players'] as List?) ?? [];
          final team2Players = (data['team2Players'] as List?) ?? [];

          final isParticipant = team1Players.any((p) => p['userId'] == userId) ||
              team2Players.any((p) => p['userId'] == userId);

          if (!isParticipant) continue;

          totalMatches++;

          final resultStatus = data['resultStatus'] ?? 'no_result';

          if (resultStatus == 'confirmed') {
            confirmedMatches++;
          } else if (resultStatus == 'disputed') {
            disputedMatches++;

            // Check if this user was the one who disputed
            final confirmedBy = List<String>.from(data['resultConfirmedBy'] ?? []);
            if (!confirmedBy.contains(userId)) {
              userInitiatedDisputes++;
            }
          }
        } catch (e) {
          debugPrint('Error processing match stats: $e');
        }
      }

      final disputeRate = totalMatches > 0
          ? (disputedMatches / totalMatches * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'totalMatches': totalMatches,
        'confirmedMatches': confirmedMatches,
        'disputedMatches': disputedMatches,
        'userInitiatedDisputes': userInitiatedDisputes,
        'disputeRate': disputeRate,
        'reliabilityScore': totalMatches > 0
            ? ((confirmedMatches / totalMatches) * 100).toStringAsFixed(1)
            : '100.0',
      };
    } catch (e) {
      debugPrint('Error calculating dispute stats: $e');
      return {
        'totalMatches': 0,
        'confirmedMatches': 0,
        'disputedMatches': 0,
        'userInitiatedDisputes': 0,
        'disputeRate': '0.0',
        'reliabilityScore': '100.0',
      };
    }
  }

  // =============== TOURNAMENT MATCH RESULT METHODS ===============

  /// Check if current user needs to confirm a tournament match result
  Future<bool> needsTournamentConfirmation(
      String tournamentId, String matchId, String userId) async {
    try {
      final doc = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .get();

      if (!doc.exists) return false;

      final match = TournamentMatch.fromFirestore(doc);

      // Check if match has a pending result
      final resultStatus = doc.data()?['resultStatus'] ?? 'no_result';
      if (resultStatus != 'pending_confirmation') return false;

      // Check if user is a participant
      final isParticipant = match.player1Id == userId || match.player2Id == userId;
      if (!isParticipant) return false;

      // Check if user has already confirmed
      final resultConfirmedBy = List<String>.from(doc.data()?['resultConfirmedBy'] ?? []);
      if (resultConfirmedBy.contains(userId)) return false;

      return true;
    } catch (e) {
      debugPrint('Error checking tournament confirmation need: $e');
      return false;
    }
  }

  /// Get list of tournament matches awaiting confirmation from user
  Future<List<Map<String, dynamic>>> getPendingTournamentConfirmations(
      String userId) async {
    try {
      // Get all tournaments
      final tournamentsSnapshot = await _firestore.collection('tournaments').get();

      final pendingMatches = <Map<String, dynamic>>[];

      for (var tournamentDoc in tournamentsSnapshot.docs) {
        // Get matches for this tournament
        final matchesSnapshot = await _firestore
            .collection('tournaments')
            .doc(tournamentDoc.id)
            .collection('matches')
            .where('resultStatus', isEqualTo: 'pending_confirmation')
            .get();

        for (var matchDoc in matchesSnapshot.docs) {
          try {
            final match = TournamentMatch.fromFirestore(matchDoc);

            // Check if user is a participant and hasn't confirmed
            final isParticipant = match.player1Id == userId || match.player2Id == userId;
            final resultConfirmedBy = List<String>.from(matchDoc.data()['resultConfirmedBy'] ?? []);

            if (isParticipant && !resultConfirmedBy.contains(userId)) {
              pendingMatches.add({
                'tournamentId': tournamentDoc.id,
                'match': match,
              });
            }
          } catch (e) {
            debugPrint('Error parsing tournament match ${matchDoc.id}: $e');
          }
        }
      }

      return pendingMatches;
    } catch (e) {
      debugPrint('Error getting pending tournament confirmations: $e');
      return [];
    }
  }

  /// Check if user is eligible to submit result for a tournament match
  bool canSubmitTournamentResult(TournamentMatch match, String userId) {
    // Can only submit if:
    // 1. User is a participant
    // 2. Result hasn't been submitted yet
    // 3. Match status is not already completed

    final isParticipant = match.player1Id == userId || match.player2Id == userId;
    if (!isParticipant) return false;

    // Check if result already submitted
    final resultStatus = match.toFirestore()['resultStatus'] ?? 'no_result';
    if (resultStatus != 'no_result') return false;

    return true;
  }

  /// Process expired tournament match confirmations
  Future<void> processTournamentExpiredConfirmations() async {
    try {
      final now = DateTime.now();

      // Get all tournaments
      final tournamentsSnapshot = await _firestore.collection('tournaments').get();

      int processedCount = 0;

      for (var tournamentDoc in tournamentsSnapshot.docs) {
        // Get matches with expired deadlines
        final matchesSnapshot = await _firestore
            .collection('tournaments')
            .doc(tournamentDoc.id)
            .collection('matches')
            .where('resultStatus', isEqualTo: 'pending_confirmation')
            .get();

        for (var matchDoc in matchesSnapshot.docs) {
          try {
            final data = matchDoc.data();
            final deadline = data['resultConfirmationDeadline'] as Timestamp?;

            if (deadline != null && deadline.toDate().isBefore(now)) {
              debugPrint('⏰ Auto-confirming tournament match ${matchDoc.id} (deadline expired)');

              // Auto-confirm the result
              await _firestore
                  .collection('tournaments')
                  .doc(tournamentDoc.id)
                  .collection('matches')
                  .doc(matchDoc.id)
                  .update({
                'resultStatus': 'confirmed',
                'status': 'completed',
                'updatedAt': Timestamp.fromDate(now),
              });

              processedCount++;

              // Try to advance winner to next round
              final match = TournamentMatch.fromFirestore(matchDoc);
              if (match.winnerId != null && match.nextMatchId != null) {
                await _advanceTournamentWinner(
                  tournamentDoc.id,
                  match.winnerId!,
                  match.nextMatchId!,
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Error auto-confirming tournament match ${matchDoc.id}: $e');
          }
        }
      }

      debugPrint('🕐 Processed $processedCount expired tournament match confirmations');
    } catch (e) {
      debugPrint('❌ Error processing expired tournament confirmations: $e');
    }
  }

  /// Advance winner to next tournament round
  Future<void> _advanceTournamentWinner(
      String tournamentId, String winnerId, String nextMatchId) async {
    try {
      final nextMatchDoc = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(nextMatchId)
          .get();

      if (!nextMatchDoc.exists) {
        debugPrint('Next match not found: $nextMatchId');
        return;
      }

      final nextMatch = TournamentMatch.fromFirestore(nextMatchDoc);

      // Determine which slot to fill
      final Map<String, dynamic> updates = {};

      if (nextMatch.player1Id == null) {
        updates['player1Id'] = winnerId;
      } else if (nextMatch.player2Id == null) {
        updates['player2Id'] = winnerId;
      } else {
        debugPrint('Both players already set in match $nextMatchId');
        return;
      }

      // If both players are now set, mark as scheduled
      final bothPlayersSet = (nextMatch.player1Id != null || updates.containsKey('player1Id')) &&
          (nextMatch.player2Id != null || updates.containsKey('player2Id'));

      if (bothPlayersSet) {
        updates['status'] = 'scheduled';
      }

      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(nextMatchId)
          .update(updates);

      debugPrint('✅ Winner $winnerId advanced to match $nextMatchId');
    } catch (e) {
      debugPrint('❌ Error advancing tournament winner: $e');
    }
  }

  /// Get disputed tournament matches for admin review
  Future<List<Map<String, dynamic>>> getDisputedTournamentMatches(
      String tournamentId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .where('resultStatus', isEqualTo: 'disputed')
          .get();

      return matchesSnapshot.docs.map((doc) {
        return {
          'tournamentId': tournamentId,
          'matchId': doc.id,
          'match': TournamentMatch.fromFirestore(doc),
          'disputeReason': doc.data()['disputeReason'],
          'disputedBy': doc.data()['disputedBy'],
          'disputedAt': doc.data()['disputedAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting disputed tournament matches: $e');
      return [];
    }
  }

  /// Admin resolves a disputed tournament match
  Future<void> resolveDisputedTournamentMatch({
    required String tournamentId,
    required String matchId,
    required String resolution, // 'confirm' or 'reject'
    String? adminNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'resultStatus': resolution == 'confirm' ? 'confirmed' : 'no_result',
        'status': resolution == 'confirm' ? 'completed' : 'scheduled',
        'adminResolution': resolution,
        'adminNotes': adminNotes,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .update(updates);

      // If confirmed, advance winner
      if (resolution == 'confirm') {
        final matchDoc = await _firestore
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(matchId)
            .get();

        if (matchDoc.exists) {
          final match = TournamentMatch.fromFirestore(matchDoc);
          if (match.winnerId != null && match.nextMatchId != null) {
            await _advanceTournamentWinner(
              tournamentId,
              match.winnerId!,
              match.nextMatchId!,
            );
          }
        }
      }

      debugPrint('✅ Tournament match dispute resolved: $resolution');
    } catch (e) {
      debugPrint('❌ Error resolving tournament match dispute: $e');
      rethrow;
    }
  }
}
