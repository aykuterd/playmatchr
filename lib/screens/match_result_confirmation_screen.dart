import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class MatchResultConfirmationScreen extends StatefulWidget {
  final String matchId;

  const MatchResultConfirmationScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchResultConfirmationScreen> createState() => _MatchResultConfirmationScreenState();
}

class _MatchResultConfirmationScreenState extends State<MatchResultConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  bool _isLoading = false;
  Match? _match;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
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

  Future<void> _confirmResult() async {
    if (_match == null) return;

    try {
      setState(() => _isLoading = true);

      final currentUserId = _authController.user.value!.uid;

      // Add current user to confirmed list
      await _firestore.collection('matches').doc(widget.matchId).update({
        'resultConfirmedBy': FieldValue.arrayUnion([currentUserId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Check if all participants have confirmed
      final updatedDoc = await _firestore.collection('matches').doc(widget.matchId).get();
      final updatedMatch = Match.fromFirestore(updatedDoc);

      // Get all unique participant IDs
      final allParticipants = <String>{};
      for (var player in updatedMatch.team1Players) {
        allParticipants.add(player.userId);
      }
      for (var player in updatedMatch.team2Players) {
        allParticipants.add(player.userId);
      }

      // Check if everyone confirmed
      if (updatedMatch.resultConfirmedBy.toSet().containsAll(allParticipants)) {
        await _firestore.collection('matches').doc(widget.matchId).update({
          'resultStatus': 'confirmed',
          'status': 'completed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      Get.back();
      Get.snackbar(
        'Başarılı',
        'Maç sonucunu onayladınız',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error confirming result: $e');
      Get.snackbar(
        'Hata',
        'Onaylama sırasında hata oluştu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disputeResult() async {
    if (_match == null) return;

    // Show dialog to get dispute reason
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _DisputeReasonDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      await _firestore.collection('matches').doc(widget.matchId).update({
        'resultStatus': 'disputed',
        'disputeReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Get.back();
      Get.snackbar(
        'İtiraz Kaydedildi',
        'Maç sonucuna itiraz ettiniz. Bu maç için puan işlemi yapılmayacak.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error disputing result: $e');
      Get.snackbar(
        'Hata',
        'İtiraz kaydedilirken hata oluştu: $e',
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

    final currentUserId = _authController.user.value!.uid;
    final hasConfirmed = _match!.resultConfirmedBy.contains(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maç Sonucu'),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Result display
            Text(
              'Maç Sonucu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Team 1
                    _buildTeamResult(
                      context,
                      'Takım 1',
                      _match!.team1Players,
                      _match!.score?['team1']?.toString() ?? '0',
                      _match!.winner == 'team1',
                      Colors.blue,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 2,
                            color: Colors.grey[300],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _match!.winner == 'draw' ? 'BERABERE' : 'VS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 2,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),

                    // Team 2
                    _buildTeamResult(
                      context,
                      'Takım 2',
                      _match!.team2Players,
                      _match!.score?['team2']?.toString() ?? '0',
                      _match!.winner == 'team2',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirmation status
            if (_match!.resultConfirmationDeadline != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Son onay tarihi: ${DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(_match!.resultConfirmationDeadline!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Confirmation list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onay Durumu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildConfirmationList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (!hasConfirmed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                          'Sonucu Onayla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _disputeResult,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'İtiraz Et',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Sonucu onayladınız',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      'Sonucu onayladığınızda ELO puanınız güncellenecek. İtiraz ettiğinizde ise bu maç için puan işlemi yapılmayacak.',
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

  Widget _buildTeamResult(
    BuildContext context,
    String teamName,
    List<TeamPlayer> players,
    String score,
    bool isWinner,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: players.map((player) {
                      return Text(
                        player.userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'KAZANAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  score,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? color : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildConfirmationList() {
    final allParticipants = <String, String>{};

    // Collect all participants
    for (var player in _match!.team1Players) {
      allParticipants[player.userId] = player.userName;
    }
    for (var player in _match!.team2Players) {
      allParticipants[player.userId] = player.userName;
    }

    return allParticipants.entries.map((entry) {
      final hasConfirmed = _match!.resultConfirmedBy.contains(entry.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              hasConfirmed ? Icons.check_circle : Icons.schedule,
              color: hasConfirmed ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              hasConfirmed ? 'Onaylandı' : 'Bekliyor',
              style: TextStyle(
                fontSize: 12,
                color: hasConfirmed ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
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

class _DisputeReasonDialog extends StatefulWidget {
  @override
  State<_DisputeReasonDialog> createState() => _DisputeReasonDialogState();
}

class _DisputeReasonDialogState extends State<_DisputeReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İtiraz Nedeni'),
      content: TextField(
        controller: _reasonController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'İtiraz nedeninizi yazın...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_reasonController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text(
            'İtiraz Et',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
