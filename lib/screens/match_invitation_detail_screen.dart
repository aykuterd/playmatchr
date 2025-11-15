import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class MatchInvitationDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchInvitationDetailScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchInvitationDetailScreen> createState() => _MatchInvitationDetailScreenState();
}

class _MatchInvitationDetailScreenState extends State<MatchInvitationDetailScreen> {
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

  Future<void> _acceptInvitation() async {
    if (_match == null) return;

    try {
      setState(() => _isLoading = true);

      final currentUserId = _authController.user.value!.uid;
      final userProfile = _authController.userProfile.value;

      // Check if user is already in the match
      final isInTeam1 = _match!.team1Players.any((p) => p.userId == currentUserId);
      final isInTeam2 = _match!.team2Players.any((p) => p.userId == currentUserId);

      debugPrint('🔍 Duplicate check: team1=$isInTeam1, team2=$isInTeam2, userId=$currentUserId');
      debugPrint('   Team1 players: ${_match!.team1Players.map((p) => p.userId).toList()}');
      debugPrint('   Team2 players: ${_match!.team2Players.map((p) => p.userId).toList()}');

      if (isInTeam1 || isInTeam2) {
        Get.snackbar(
          'Bilgi',
          'Zaten bu maça katıldınız!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        // Navigate back to main screen since user is already in match
        Get.offAllNamed('/main_screen');
        return;
      }

      // Add user to team2
      final newPlayer = TeamPlayer(
        userId: currentUserId,
        userName: userProfile?.displayName ?? 'Oyuncu',
        profileImage: userProfile?.photoUrl,
        isReserve: false,
      );

      await _firestore.collection('matches').doc(widget.matchId).update({
        'team2Players': FieldValue.arrayUnion([newPlayer.toMap()]),
        'status': 'confirmed', // Status'ü pending'den confirmed'a güncelle
      });

      debugPrint('✅ User added to team2 and match status updated to confirmed');

      // Navigate to main screen and show success message
      Get.offAllNamed('/main_screen');

      // Wait a bit for navigation then show snackbar
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Başarılı',
          'Maç davetini kabul ettiniz! Ana sayfanızda görünecek.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Davet kabul edilirken hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _declineInvitation() async {
    try {
      setState(() => _isLoading = true);

      // Optionally, you can delete the notification here
      // For now, just close the screen

      Get.back();
      Get.snackbar(
        'Reddedildi',
        'Maç davetini reddettiniz',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Maç Daveti'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _match == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Geri Dön'),
                      ),
                    ],
                  ),
                )
              : _match == null
                  ? const Center(child: Text('Maç bulunamadı'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header section with sport icon
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF1E3A8A),
                                  Color(0xFF2563EB),
                                ],
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    // Sport Icon
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 3,
                                        ),
                                      ),
                                      child: Icon(
                                        _getSportIcon(_match!.sportType),
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _match!.sportType,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getMatchTypeText(_match!.matchType),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Match details card
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Date and Time
                                      _buildDetailRow(
                                        icon: Icons.calendar_today,
                                        title: 'Tarih ve Saat',
                                        value: DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                                            .format(_match!.dateTime),
                                      ),
                                      const Divider(height: 24),

                                      // Duration
                                      _buildDetailRow(
                                        icon: Icons.timer_outlined,
                                        title: 'Süre',
                                        value: '${_match!.durationMinutes} dakika',
                                      ),
                                      const Divider(height: 24),

                                      // Location
                                      _buildDetailRow(
                                        icon: Icons.location_on_outlined,
                                        title: 'Konum',
                                        value: _match!.location.address.isNotEmpty
                                            ? _match!.location.address
                                            : 'Harita üzerinde gösterildi',
                                      ),
                                      const Divider(height: 24),

                                      // Level
                                      _buildDetailRow(
                                        icon: Icons.signal_cellular_alt,
                                        title: 'Seviye',
                                        value: _getLevelText(_match!.level),
                                      ),
                                      const Divider(height: 24),

                                      // Mode
                                      _buildDetailRow(
                                        icon: Icons.sports_score,
                                        title: 'Mod',
                                        value: _getModeText(_match!.mode),
                                      ),

                                      if (_match!.maxPlayersPerTeam != null) ...[
                                        const Divider(height: 24),
                                        _buildDetailRow(
                                          icon: Icons.groups_outlined,
                                          title: 'Takım Başına Oyuncu',
                                          value: '${_match!.maxPlayersPerTeam} kişi',
                                        ),
                                      ],

                                      if (_match!.costPerPerson != null) ...[
                                        const Divider(height: 24),
                                        _buildDetailRow(
                                          icon: Icons.payments_outlined,
                                          title: 'Kişi Başı Ücret',
                                          value: '${_match!.costPerPerson!.toStringAsFixed(0)} ₺',
                                        ),
                                      ],

                                      if (_match!.notes != null && _match!.notes!.isNotEmpty) ...[
                                        const Divider(height: 24),
                                        const Text(
                                          'Notlar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _match!.notes!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Players section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Oyuncular',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Team 1
                                if (_match!.team1Players.isNotEmpty) ...[
                                  _buildTeamCard(
                                    'Takım 1',
                                    _match!.team1Players,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Team 2
                                if (_match!.team2Players.isNotEmpty) ...[
                                  _buildTeamCard(
                                    'Takım 2',
                                    _match!.team2Players,
                                    Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 100), // Space for bottom buttons
                        ],
                      ),
                    ),
      bottomNavigationBar: _match == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _declineInvitation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Reddet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptInvitation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kabul Et',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E3A8A),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(String teamName, List<TeamPlayer> players, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${players.length} oyuncu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...players.map((player) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: player.profileImage != null
                            ? NetworkImage(player.profileImage!)
                            : null,
                        backgroundColor: color.withOpacity(0.2),
                        child: player.profileImage == null
                            ? Text(
                                player.userName[0].toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        player.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (player.isReserve) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Yedek',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
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

  String _getMatchTypeText(MatchType type) {
    switch (type) {
      case MatchType.individual:
        return 'Bireysel';
      case MatchType.team:
        return 'Takım';
    }
  }

  String _getLevelText(MatchLevel level) {
    switch (level) {
      case MatchLevel.beginner:
        return 'Başlangıç';
      case MatchLevel.intermediate:
        return 'Orta';
      case MatchLevel.advanced:
        return 'İleri';
      case MatchLevel.professional:
        return 'Profesyonel';
    }
  }

  String _getModeText(MatchMode mode) {
    switch (mode) {
      case MatchMode.friendly:
        return 'Dostluk Maçı';
      case MatchMode.competitive:
        return 'Rekabetçi';
    }
  }
}
