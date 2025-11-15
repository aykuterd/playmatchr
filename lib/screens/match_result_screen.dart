import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/notification_controller.dart';
import 'package:intl/intl.dart';

class MatchResultScreen extends StatefulWidget {
  final String matchId;

  const MatchResultScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  final NotificationController _notificationController = Get.find<NotificationController>();

  bool _isLoading = false;
  Match? _match;
  String? _error;

  // Form state
  String _selectedWinner = ''; // 'team1', 'team2', 'draw'
  final TextEditingController _team1ScoreController = TextEditingController();
  final TextEditingController _team2ScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  @override
  void dispose() {
    _team1ScoreController.dispose();
    _team2ScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final doc = await _firestore.collection('matches').doc(widget.matchId).get();

      if (!doc.exists) {
        setState(() {
          _error = 'Maç bulunamadı';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _match = Match.fromFirestore(doc);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Maç yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitResult() async {
    if (_match == null) return;

    // Validate form
    if (_selectedWinner.isEmpty) {
      Get.snackbar(
        'Hata',
        'Lütfen kazananı seçin',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_team1ScoreController.text.isEmpty || _team2ScoreController.text.isEmpty) {
      Get.snackbar(
        'Hata',
        'Lütfen skorları girin',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final currentUserId = _authController.user.value!.uid;
      final now = DateTime.now();
      final confirmationDeadline = now.add(const Duration(hours: 24));

      // Parse scores
      final team1Score = int.tryParse(_team1ScoreController.text) ?? 0;
      final team2Score = int.tryParse(_team2ScoreController.text) ?? 0;

      // Create score map
      final scoreMap = {
        'team1': team1Score,
        'team2': team2Score,
      };

      // Get all participants who need to confirm (excluding the submitter)
      final allParticipants = <String>[];
      for (var player in _match!.team1Players) {
        if (!allParticipants.contains(player.userId)) {
          allParticipants.add(player.userId);
        }
      }
      for (var player in _match!.team2Players) {
        if (!allParticipants.contains(player.userId)) {
          allParticipants.add(player.userId);
        }
      }

      // Remove current user from participants (they auto-confirm by submitting)
      allParticipants.remove(currentUserId);

      // Update match with result
      await _firestore.collection('matches').doc(widget.matchId).update({
        'resultSubmittedBy': currentUserId,
        'resultSubmittedAt': Timestamp.fromDate(now),
        'winner': _selectedWinner,
        'score': scoreMap,
        'resultConfirmedBy': [currentUserId], // Submitter auto-confirms
        'resultStatus': 'pending_confirmation',
        'resultConfirmationDeadline': Timestamp.fromDate(confirmationDeadline),
        'status': 'finished', // Match is finished, waiting for confirmation
        'updatedAt': Timestamp.fromDate(now),
      });

      // Send confirmation requests to all other participants
      for (final participantId in allParticipants) {
        await _notificationController.createNotification(
          toUserId: participantId,
          type: NotificationType.matchUpdate,
          title: 'Maç Sonucu Girildi',
          message: 'Maç sonucunu onaylamanız bekleniyor',
          relatedId: widget.matchId,
          data: {
            'action': 'confirm_result',
            'deadline': confirmationDeadline.toIso8601String(),
          },
        );
      }

      Get.back();
      Get.snackbar(
        'Başarılı',
        'Maç sonucu gönderildi. Diğer oyuncuların onayı bekleniyor.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error submitting result: $e');
      Get.snackbar(
        'Hata',
        'Sonuç gönderilirken hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _match == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maç Sonucu'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maç Sonucu'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMatchDetails,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_match == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maç Sonucu'),
        ),
        body: const Center(
          child: Text('Maç bilgisi yüklenemedi'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maç Sonucu Gir'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getSportIcon(_match!.sportType),
                          size: 32,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _match!.sportType,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                                    .format(_match!.dateTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _match!.location.venueName ?? _match!.location.address,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Teams display
            Text(
              'Takımlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Team 1
            _buildTeamCard(
              context,
              'Takım 1',
              _match!.team1Players,
              Colors.blue,
              'team1',
            ),
            const SizedBox(height: 16),

            // Team 2
            _buildTeamCard(
              context,
              'Takım 2',
              _match!.team2Players,
              Colors.red,
              'team2',
            ),
            const SizedBox(height: 24),

            // Draw option
            Card(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedWinner = 'draw';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: _selectedWinner == 'draw'
                        ? Border.all(color: Colors.orange, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedWinner == 'draw'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Berabere',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sonucu Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sonucu gönderdikten sonra diğer oyuncuların onayı beklenecek. 24 saat içinde onaylanmazsa otomatik olarak kabul edilir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
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

  Widget _buildTeamCard(
    BuildContext context,
    String teamName,
    List<TeamPlayer> players,
    Color color,
    String teamKey,
  ) {
    final isSelected = _selectedWinner == teamKey;
    final controller = teamKey == 'team1' ? _team1ScoreController : _team2ScoreController;

    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedWinner = teamKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (players.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: players.map((player) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: player.profileImage != null
                                ? NetworkImage(player.profileImage!)
                                : null,
                            child: player.profileImage == null
                                ? const Icon(Icons.person, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            player.userName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'futbol':
      case 'soccer':
      case 'football':
        return Icons.sports_soccer;
      case 'basketbol':
      case 'basketball':
        return Icons.sports_basketball;
      case 'tenis':
      case 'tennis':
        return Icons.sports_tennis;
      case 'voleybol':
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }
}
