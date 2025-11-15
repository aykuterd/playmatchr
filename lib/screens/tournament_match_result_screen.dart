import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/score_inputs/simple_score_input.dart';
import 'package:playmatchr/widgets/score_inputs/set_based_score_input.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Turnuva maçı için sonuç giriş ekranı (Sport-Agnostic)
/// Sport tipine göre otomatik olarak doğru input widget'ını gösterir
class TournamentMatchResultScreen extends StatefulWidget {
  final String tournamentId;
  final String matchId;

  const TournamentMatchResultScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  State<TournamentMatchResultScreen> createState() =>
      _TournamentMatchResultScreenState();
}

class _TournamentMatchResultScreenState
    extends State<TournamentMatchResultScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Simple score için
  final TextEditingController _simplePlayer1Controller = TextEditingController();
  final TextEditingController _simplePlayer2Controller = TextEditingController();

  // Set-based score için
  final List<TextEditingController> _player1SetControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> _player2SetControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isSubmitting = false;
  String? _calculatedWinner;

  // Widget keys for accessing methods
  final GlobalKey<SetBasedScoreInputState> _setBasedKey = GlobalKey();

  @override
  void dispose() {
    _simplePlayer1Controller.dispose();
    _simplePlayer2Controller.dispose();
    for (var controller in _player1SetControllers) {
      controller.dispose();
    }
    for (var controller in _player2SetControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Sport tipine göre set-based mi basit mi belirle
  bool _isSetBasedSport(String sport) {
    final setBasedSports = ['tenis', 'voleybol', 'badminton', 'masa tenisi'];
    return setBasedSports.contains(sport.toLowerCase());
  }

  /// Kazananı hesapla
  void _calculateWinner(TournamentMatch match, Tournament tournament) {
    if (_isSetBasedSport(tournament.sport)) {
      // Set-based calculation
      final setWidget = _setBasedKey.currentState;
      if (setWidget != null) {
        setState(() {
          _calculatedWinner = setWidget.calculateWinner(
            match.player1Id,
            match.player2Id,
          );
        });
      }
    } else {
      // Simple score calculation
      final p1Score = int.tryParse(_simplePlayer1Controller.text);
      final p2Score = int.tryParse(_simplePlayer2Controller.text);

      setState(() {
        if (p1Score != null && p2Score != null) {
          if (p1Score > p2Score) {
            _calculatedWinner = match.player1Id;
          } else if (p2Score > p1Score) {
            _calculatedWinner = match.player2Id;
          } else {
            _calculatedWinner = null; // Beraberlik
          }
        } else {
          _calculatedWinner = null;
        }
      });
    }
  }

  /// Sonucu gönder
  Future<void> _submitResult(TournamentMatch match, Tournament tournament) async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('Hata', 'Lütfen geçerli skorlar girin');
      return;
    }

    if (_calculatedWinner == null) {
      Get.snackbar('Hata', 'Kazanan belirlenemiyor. Lütfen skorları kontrol edin');
      return;
    }

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

    setState(() {
      _isSubmitting = true;
    });

    try {
      Map<String, dynamic> player1Score;
      Map<String, dynamic> player2Score;

      if (_isSetBasedSport(tournament.sport)) {
        // Set-based skorları al
        final setWidget = _setBasedKey.currentState;
        if (setWidget != null) {
          final scoreData = setWidget.getScoreData();
          player1Score = scoreData['player1Score'] as Map<String, dynamic>;
          player2Score = scoreData['player2Score'] as Map<String, dynamic>;
        } else {
          throw Exception('Set widget not found');
        }
      } else {
        // Simple skorları al
        player1Score = {
          'score': int.parse(_simplePlayer1Controller.text),
        };
        player2Score = {
          'score': int.parse(_simplePlayer2Controller.text),
        };
      }

      // 24 saat sonrası için deadline belirle
      final confirmationDeadline = DateTime.now().add(const Duration(hours: 24));

      // Maçı güncelle
      await _firestoreService.updateTournamentMatch(
        widget.tournamentId,
        widget.matchId,
        {
          'player1Score': player1Score,
          'player2Score': player2Score,
          'winnerId': _calculatedWinner,
          'status': 'completed',
          'resultSubmittedBy': userId,
          'resultSubmittedAt': DateTime.now(),
          'resultStatus': 'pending_confirmation',
          'resultConfirmationDeadline': confirmationDeadline,
          'resultConfirmedBy': [userId], // İlk onay
        },
      );

      Get.snackbar(
        'Başarılı',
        'Maç sonucu gönderildi. Rakibinizin onayı bekleniyor.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Ekranı kapat
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error submitting result: $e');
      Get.snackbar(
        'Hata',
        'Sonuç gönderilirken hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _firestoreService.getTournamentMatch(widget.tournamentId, widget.matchId),
        _firestoreService.getTournament(widget.tournamentId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data![0] == null || snapshot.data![1] == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Maç Sonucu')),
            body: const Center(child: Text('Maç veya turnuva bulunamadı')),
          );
        }

        final match = snapshot.data![0] as TournamentMatch;
        final tournament = snapshot.data![1] as Tournament;

        return Scaffold(
          appBar: AppBar(
            title: Text('${tournament.sport} - Maç Sonucu'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMatchInfo(match),
                  const SizedBox(height: AppSpacing.xl),
                  _buildScoreInput(match, tournament),
                  const SizedBox(height: AppSpacing.xl),
                  _buildWinnerInfo(match),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSubmitButton(match, tournament),
                ],
              ),
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

  Widget _buildScoreInput(TournamentMatch match, Tournament tournament) {
    final isTeamSport = getSportCategory(tournament.sport) == MatchType.team;

    if (isTeamSport) {
      // Takım sporları için takım isimlerini al
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
          final team1Name = team1?.teamName ?? 'Takım 1';
          final team2Name = team2?.teamName ?? 'Takım 2';

          if (_isSetBasedSport(tournament.sport)) {
            // Set-based input (Tenis, Voleybol, Badminton)
            return SetBasedScoreInput(
              key: _setBasedKey,
              player1SetControllers: _player1SetControllers,
              player2SetControllers: _player2SetControllers,
              player1Name: team1Name,
              player2Name: team2Name,
              onChanged: (value) => _calculateWinner(match, tournament),
            );
          } else {
            // Simple score input (Futbol, Basketbol, vs.)
            return SimpleScoreInput(
              player1Controller: _simplePlayer1Controller,
              player2Controller: _simplePlayer2Controller,
              player1Name: team1Name,
              player2Name: team2Name,
              onChanged: (value) => _calculateWinner(match, tournament),
            );
          }
        },
      );
    }

    // Bireysel sporlar için oyuncu isimlerini al
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
        final player1Name = player1?.displayName ?? 'Oyuncu 1';
        final player2Name = player2?.displayName ?? 'Oyuncu 2';

        if (_isSetBasedSport(tournament.sport)) {
          // Set-based input (Tenis, Voleybol, Badminton)
          return SetBasedScoreInput(
            key: _setBasedKey,
            player1SetControllers: _player1SetControllers,
            player2SetControllers: _player2SetControllers,
            player1Name: player1Name,
            player2Name: player2Name,
            onChanged: (value) => _calculateWinner(match, tournament),
          );
        } else {
          // Simple score input (Futbol, Basketbol, vs.)
          return SimpleScoreInput(
            player1Controller: _simplePlayer1Controller,
            player2Controller: _simplePlayer2Controller,
            player1Name: player1Name,
            player2Name: player2Name,
            onChanged: (value) => _calculateWinner(match, tournament),
          );
        }
      },
    );
  }

  Widget _buildWinnerInfo(TournamentMatch match) {
    if (_calculatedWinner == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Tournament?>(
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
            future: _calculatedWinner != null
                ? _firestoreService.getTournamentTeamByCaptain(
                    widget.tournamentId, _calculatedWinner!)
                : Future.value(null),
            builder: (context, snapshot) {
              final team = snapshot.data;

              // Takım rengini parse et
              Color? teamColor;
              if (team?.primaryColor != null) {
                try {
                  teamColor = Color(int.parse(team!.primaryColor!.replaceFirst('#', '0xFF')));
                } catch (e) {
                  teamColor = Colors.green;
                }
              } else {
                teamColor = Colors.green;
              }

              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: teamColor, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: teamColor,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kazanan Takım',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team?.teamName ?? 'Takım',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: teamColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Bireysel sporlar için oyuncu ismini göster
        return FutureBuilder<UserProfile?>(
          future: _calculatedWinner != null
              ? _firestoreService.getUserProfile(_calculatedWinner!)
              : Future.value(null),
          builder: (context, snapshot) {
            final winner = snapshot.data;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kazanan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          winner?.displayName ?? 'Oyuncu',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(TournamentMatch match, Tournament tournament) {
    return ElevatedButton(
      onPressed: _isSubmitting || _calculatedWinner == null
          ? null
          : () => _submitResult(match, tournament),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Sonucu Gönder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
