import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Turnuva maçı sonucu onay ekranı
/// Rakip oyuncu gönderilen sonucu onaylar veya itiraz eder
class TournamentMatchConfirmationScreen extends StatefulWidget {
  final String tournamentId;
  final String matchId;

  const TournamentMatchConfirmationScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  State<TournamentMatchConfirmationScreen> createState() =>
      _TournamentMatchConfirmationScreenState();
}

class _TournamentMatchConfirmationScreenState
    extends State<TournamentMatchConfirmationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessing = false;
  String? _disputeReason;

  /// Sonucu onayla
  Future<void> _confirmResult(TournamentMatch match) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Hata', 'Giriş yapmalısınız');
      return;
    }

    // Kullanıcının bu maçın katılımcısı olup olmadığını kontrol et
    if (match.player1Id != userId && match.player2Id != userId) {
      Get.snackbar('Hata', 'Bu maçın katılımcısı değilsiniz');
      return;
    }

    // Zaten onaylamış mı kontrol et
    final resultConfirmedBy = match.toFirestore()['resultConfirmedBy'] as List? ?? [];
    if (resultConfirmedBy.contains(userId)) {
      Get.snackbar('Bilgi', 'Bu sonucu zaten onayladınız');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Onay listesine ekle
      final updatedConfirmedBy = List<String>.from(resultConfirmedBy)..add(userId);

      // Tüm katılımcılar onayladıysa durumu 'confirmed' yap
      final allPlayersConfirmed = match.player1Id != null &&
          match.player2Id != null &&
          updatedConfirmedBy.contains(match.player1Id) &&
          updatedConfirmedBy.contains(match.player2Id);

      await _firestoreService.updateTournamentMatch(
        widget.tournamentId,
        widget.matchId,
        {
          'resultConfirmedBy': updatedConfirmedBy,
          'resultStatus': allPlayersConfirmed ? 'confirmed' : 'pending_confirmation',
        },
      );

      Get.snackbar(
        'Başarılı',
        allPlayersConfirmed
            ? 'Maç sonucu onaylandı!'
            : 'Onayınız alındı. Diğer oyuncunun onayı bekleniyor.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Eğer tamamlandıysa bir sonraki tura geç (Cloud Function veya burada yapılabilir)
      if (allPlayersConfirmed && match.nextMatchId != null) {
        await _advanceWinner(match);
      }

      // Rozetleri kontrol et ve ver
      if (allPlayersConfirmed) {
        // Her iki oyuncuya da rozet kontrolü yap
        if (match.player1Id != null) {
          await _firestoreService.checkAndAwardAchievements(match.player1Id!);
        }
        if (match.player2Id != null) {
          await _firestoreService.checkAndAwardAchievements(match.player2Id!);
        }
      }

      // Ekranı kapat
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error confirming result: $e');
      Get.snackbar(
        'Hata',
        'Onay sırasında hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Sonuca itiraz et
  Future<void> _disputeResult(TournamentMatch match) async {
    // İtiraz nedeni dialogu göster
    final reason = await _showDisputeReasonDialog();

    if (reason == null || reason.isEmpty) {
      return; // Kullanıcı iptal etti
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Hata', 'Giriş yapmalısınız');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Maçın durumunu 'disputed' yap
      await _firestoreService.updateTournamentMatch(
        widget.tournamentId,
        widget.matchId,
        {
          'resultStatus': 'disputed',
          'disputeReason': reason,
          'disputedBy': userId,
          'disputedAt': DateTime.now(),
        },
      );

      Get.snackbar(
        'İtiraz Kaydedildi',
        'Maç sonucuna itiraz edildi. Turnuva yöneticisi inceleyecektir.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Ekranı kapat
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error disputing result: $e');
      Get.snackbar(
        'Hata',
        'İtiraz sırasında hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// İtiraz nedeni dialog'u göster
  Future<String?> _showDisputeReasonDialog() async {
    final controller = TextEditingController();
    String? selectedReason;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İtiraz Nedeni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lütfen itiraz nedeninizi seçin:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            ...ListTile.divideTiles(
              context: context,
              tiles: [
                RadioListTile<String>(
                  title: const Text('Skor yanlış girilmiş'),
                  value: 'wrong_score',
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Maç farklı bitti'),
                  value: 'different_result',
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Maç oynanmadı'),
                  value: 'match_not_played',
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                    Navigator.of(context).pop(value);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Diğer'),
                  value: 'other',
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                    Navigator.of(context).pop(value);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  /// Kazananı bir sonraki tura geçir
  Future<void> _advanceWinner(TournamentMatch match) async {
    if (match.winnerId == null || match.nextMatchId == null) {
      return;
    }

    try {
      // Bir sonraki maçı al
      final nextMatch = await _firestoreService.getTournamentMatch(
        widget.tournamentId,
        match.nextMatchId!,
      );

      if (nextMatch == null) {
        debugPrint('Next match not found: ${match.nextMatchId}');
        return;
      }

      // Kazananı bir sonraki maça ekle
      final Map<String, dynamic> updates = {};

      if (nextMatch.player1Id == null) {
        updates['player1Id'] = match.winnerId;
      } else if (nextMatch.player2Id == null) {
        updates['player2Id'] = match.winnerId;
      } else {
        debugPrint('Next match already has both players');
        return;
      }

      // Eğer her iki oyuncu da belli olduysa maçı 'scheduled' yap
      final bothPlayersSet = (nextMatch.player1Id != null || updates['player1Id'] != null) &&
          (nextMatch.player2Id != null || updates['player2Id'] != null);

      if (bothPlayersSet) {
        updates['status'] = 'scheduled';
      }

      await _firestoreService.updateTournamentMatch(
        widget.tournamentId,
        match.nextMatchId!,
        updates,
      );

      debugPrint('✅ Winner ${match.winnerId} advanced to match ${match.nextMatchId}');
    } catch (e) {
      debugPrint('❌ Error advancing winner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TournamentMatch?>(
      future: _firestoreService.getTournamentMatch(
        widget.tournamentId,
        widget.matchId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Maç Onayı')),
            body: const Center(child: Text('Maç bulunamadı')),
          );
        }

        final match = snapshot.data!;
        final userId = FirebaseAuth.instance.currentUser?.uid;

        // Kullanıcı zaten onayladıysa
        final resultConfirmedBy = match.toFirestore()['resultConfirmedBy'] as List? ?? [];
        final alreadyConfirmed = resultConfirmedBy.contains(userId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Maç Sonucunu Onayla'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMatchInfo(match),
                const SizedBox(height: AppSpacing.xl),
                _buildScoreDisplay(match),
                const SizedBox(height: AppSpacing.xl),
                _buildDeadlineInfo(match),
                const SizedBox(height: AppSpacing.xxl),
                if (!alreadyConfirmed) ...[
                  _buildActionButtons(match),
                ] else ...[
                  _buildAlreadyConfirmedMessage(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchInfo(TournamentMatch match) {
    return FutureBuilder<Tournament?>(
      future: _firestoreService.getTournament(widget.tournamentId),
      builder: (context, tournamentSnapshot) {
        if (!tournamentSnapshot.hasData) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final tournament = tournamentSnapshot.data!;
        final isTeamSport = getSportCategory(tournament.sport) == MatchType.team;

        if (isTeamSport) {
          // Takım sporları için takım bilgilerini göster
          return FutureBuilder<List<TournamentTeam?>>(
            future: Future.wait([
              match.player1Id != null
                  ? _firestoreService.getTournamentTeamByCaptain(
                      widget.tournamentId, match.player1Id!)
                  : Future.value(null),
              match.player2Id != null
                  ? _firestoreService.getTournamentTeamByCaptain(
                      widget.tournamentId, match.player2Id!)
                  : Future.value(null),
            ]),
            builder: (context, snapshot) {
              final team1 = snapshot.data?[0];
              final team2 = snapshot.data?[1];

              // Takım renklerini parse et
              Color? team1Color;
              Color? team2Color;
              if (team1?.primaryColor != null) {
                try {
                  team1Color = Color(int.parse(team1!.primaryColor!.replaceFirst('#', '0xFF')));
                } catch (e) {
                  team1Color = null;
                }
              }
              if (team2?.primaryColor != null) {
                try {
                  team2Color = Color(int.parse(team2!.primaryColor!.replaceFirst('#', '0xFF')));
                } catch (e) {
                  team2Color = null;
                }
              }

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'Tur ${match.round}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: team1Color ?? Colors.grey.shade300,
                                  child: Icon(
                                    Icons.groups,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  team1?.teamName ?? 'Takım 1',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: team1Color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: team2Color ?? Colors.grey.shade300,
                                  child: Icon(
                                    Icons.groups,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  team2?.teamName ?? 'Takım 2',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: team2Color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Bireysel sporlar için oyuncu bilgilerini göster
        return FutureBuilder<List<UserProfile?>>(
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

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Tur ${match.round}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: player1?.photoUrl != null
                                    ? NetworkImage(player1!.photoUrl!)
                                    : null,
                                child: player1?.photoUrl == null
                                    ? Text(
                                        player1?.displayName[0].toUpperCase() ?? 'O',
                                        style: const TextStyle(fontSize: 24),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                player1?.displayName ?? 'Oyuncu 1',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: player2?.photoUrl != null
                                    ? NetworkImage(player2!.photoUrl!)
                                    : null,
                                child: player2?.photoUrl == null
                                    ? Text(
                                        player2?.displayName[0].toUpperCase() ?? 'O',
                                        style: const TextStyle(fontSize: 24),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                player2?.displayName ?? 'Oyuncu 2',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScoreDisplay(TournamentMatch match) {
    final player1Score = match.player1Score ?? {};
    final player2Score = match.player2Score ?? {};

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirilen Skor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...player1Score.entries.map((entry) {
              final setNumber = entry.key;
              final p1Score = entry.value;
              final p2Score = player2Score[setNumber] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      setNumber.replaceAll('set', 'Set '),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Text(
                      '$p1Score - $p2Score',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: AppSpacing.xl),
            FutureBuilder<Tournament?>(
              future: _firestoreService.getTournament(widget.tournamentId),
              builder: (context, tournamentSnapshot) {
                if (!tournamentSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final tournament = tournamentSnapshot.data!;
                final isTeamSport = getSportCategory(tournament.sport) == MatchType.team;

                if (isTeamSport) {
                  // Takım sporları için takım ismini göster
                  return FutureBuilder<TournamentTeam?>(
                    future: match.winnerId != null
                        ? _firestoreService.getTournamentTeamByCaptain(
                            widget.tournamentId, match.winnerId!)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      final team = snapshot.data;

                      // Takım rengini parse et
                      Color teamColor = Colors.amber;
                      if (team?.primaryColor != null) {
                        try {
                          teamColor = Color(int.parse(team!.primaryColor!.replaceFirst('#', '0xFF')));
                        } catch (e) {
                          teamColor = Colors.amber;
                        }
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, color: teamColor, size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Kazanan: ${team?.teamName ?? 'Bilinmiyor'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: teamColor,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }

                // Bireysel sporlar için oyuncu ismini göster
                return FutureBuilder<UserProfile?>(
                  future: match.winnerId != null
                      ? _firestoreService.getUserProfile(match.winnerId!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    final winner = snapshot.data;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Kazanan: ${winner?.displayName ?? 'Bilinmiyor'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineInfo(TournamentMatch match) {
    final deadline = match.toFirestore()['resultConfirmationDeadline'];

    if (deadline == null) {
      return const SizedBox.shrink();
    }

    final deadlineDate = (deadline as Timestamp).toDate();
    final now = DateTime.now();
    final remaining = deadlineDate.difference(now);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: remaining.inHours <= 6 ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: remaining.inHours <= 6 ? Colors.orange : Colors.blue,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: remaining.inHours <= 6 ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining.isNegative
                      ? 'Süre doldu - Otomatik onaylandı'
                      : 'Onay için kalan süre',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining.isNegative
                      ? DateFormat('dd MMM yyyy, HH:mm').format(deadlineDate)
                      : '${remaining.inHours} saat ${remaining.inMinutes % 60} dakika',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: remaining.inHours <= 6 ? Colors.orange : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TournamentMatch match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _confirmResult(match),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Sonucu Onayla'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : () => _disputeResult(match),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('İtiraz Et'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyConfirmedMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onaylandı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bu maç sonucunu zaten onayladınız.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
