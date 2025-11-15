import 'package:flutter/material.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = match.dateTime.isBefore(now);
    final daysUntil = match.dateTime.difference(now).inDays;
    final hoursUntil = match.dateTime.difference(now).inHours;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(match.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: sport icon, name, and status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getSportColor(match.sportType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSportIcon(match.sportType),
                      color: _getSportColor(match.sportType),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.sportType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildLevelBadge(),
                            _buildModeBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4),
                  _buildStatusBadge(),
                ],
              ),

              SizedBox(height: 10),
              const Divider(height: 1),
              SizedBox(height: 10),

              // Date and time with countdown
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(match.dateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (!isPast && daysUntil >= 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCountdownColor(daysUntil).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCountdownColor(daysUntil).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getCountdownText(daysUntil, hoursUntil),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getCountdownColor(daysUntil),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(
                    match.location.isIndoor
                        ? Icons.home_rounded
                        : Icons.park_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.location.venueName ?? match.location.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Players info
              Row(
                children: [
                  Icon(
                    match.matchType == MatchType.team
                        ? Icons.groups_rounded
                        : Icons.person_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getPlayersText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (match.costPerPerson != null && match.costPerPerson! > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${match.costPerPerson!.toStringAsFixed(0)} ₺',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Gender preference and duration
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: _getGenderIcon(match.genderPreference),
                    label: _getGenderText(match.genderPreference),
                    color: Colors.purple,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.timer_rounded,
                    label: '${match.durationMinutes} dk',
                    color: Colors.orange,
                  ),
                  if (match.isRecurring) ...[
                    SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.repeat_rounded,
                      label: _getRecurringText(match.recurringPattern),
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    final levelData = _getLevelData(match.level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: levelData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        levelData['text'],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: levelData['color'],
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    final isCompetitive = match.mode == MatchMode.competitive;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isCompetitive ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompetitive ? Icons.emoji_events_rounded : Icons.favorite_rounded,
            size: 10,
            color: isCompetitive ? Colors.red[700] : Colors.green[700],
          ),
          SizedBox(width: 3),
          Text(
            isCompetitive ? 'Puanlı' : 'Dostane',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCompetitive ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusData = _getStatusData(match.status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusData['color'].withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusData['icon'],
            size: 12,
            color: statusData['color'],
          ),
          SizedBox(width: 3),
          Text(
            statusData['text'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusData['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    // Daha koyu bir ton için Color.lerp kullanıyoruz
    final darkColor = Color.lerp(color, Colors.black, 0.3)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: darkColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlayersText() {
    final totalPlayers = match.team1Players.length + match.team2Players.length;
    if (match.maxPlayersPerTeam != null) {
      final maxTotal = match.maxPlayersPerTeam! * 2;
      return '$totalPlayers/$maxTotal Oyuncu';
    }
    return '$totalPlayers Oyuncu';
  }

  String _getCountdownText(int days, int hours) {
    if (days > 0) {
      return '$days gün';
    } else if (hours > 0) {
      return '$hours saat';
    } else {
      return 'Bugün';
    }
  }

  Color _getCountdownColor(int days) {
    if (days == 0) return Colors.red;
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber;
    return Colors.green;
  }

  IconData _getSportIcon(String sportType) {
    final sport = sportType.toLowerCase();
    if (sport.contains('futbol') || sport.contains('football')) {
      return Icons.sports_soccer_rounded;
    } else if (sport.contains('basketbol') || sport.contains('basketball')) {
      return Icons.sports_basketball_rounded;
    } else if (sport.contains('tenis') || sport.contains('tennis')) {
      return Icons.sports_tennis_rounded;
    } else if (sport.contains('voleybol') || sport.contains('volleyball')) {
      return Icons.sports_volleyball_rounded;
    } else if (sport.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    } else if (sport.contains('golf')) {
      return Icons.golf_course_rounded;
    } else if (sport.contains('beyzbol') || sport.contains('baseball')) {
      return Icons.sports_baseball_rounded;
    }
    return Icons.sports_rounded;
  }

  Color _getSportColor(String sportType) {
    final sport = sportType.toLowerCase();
    if (sport.contains('futbol')) return Color(0xFF00897B);
    if (sport.contains('basketbol')) return Color(0xFFFF6F00);
    if (sport.contains('tenis')) return Color(0xFF43A047);
    if (sport.contains('voleybol')) return Color(0xFF5E35B1);
    if (sport.contains('badminton')) return Color(0xFFE91E63);
    return Color(0xFF00ACC1);
  }

  Map<String, dynamic> _getLevelData(MatchLevel level) {
    switch (level) {
      case MatchLevel.beginner:
        return {'text': 'Başlangıç', 'color': Colors.green};
      case MatchLevel.intermediate:
        return {'text': 'Orta', 'color': Colors.blue};
      case MatchLevel.advanced:
        return {'text': 'İleri', 'color': Colors.orange};
      case MatchLevel.professional:
        return {'text': 'Profesyonel', 'color': Colors.red};
    }
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'text': 'Onaylandı',
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
        };
      case 'pending':
        return {
          'text': 'Bekliyor',
          'color': Colors.orange,
          'icon': Icons.pending_rounded,
        };
      case 'cancelled':
        return {
          'text': 'İptal',
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
        };
      case 'completed':
        return {
          'text': 'Tamamlandı',
          'color': Colors.blue,
          'icon': Icons.done_all_rounded,
        };
      case 'finished':
        // Check result status for finished matches
        if (match.resultStatus == 'pending_confirmation') {
          return {
            'text': 'Onay Bekliyor',
            'color': Colors.amber,
            'icon': Icons.hourglass_empty_rounded,
          };
        } else if (match.resultStatus == 'disputed') {
          return {
            'text': 'Anlaşmazlık',
            'color': Colors.red,
            'icon': Icons.warning_rounded,
          };
        } else if (match.resultStatus == 'confirmed') {
          return {
            'text': 'Sonuçlandı',
            'color': Colors.blue,
            'icon': Icons.done_all_rounded,
          };
        } else {
          return {
            'text': 'Bitti',
            'color': Colors.purple,
            'icon': Icons.flag_rounded,
          };
        }
      default:
        return {
          'text': status,
          'color': Colors.grey,
          'icon': Icons.info_rounded,
        };
    }
  }

  Color _getStatusColor(String status) {
    return _getStatusData(status)['color'];
  }

  IconData _getGenderIcon(GenderPreference gender) {
    switch (gender) {
      case GenderPreference.male:
        return Icons.male_rounded;
      case GenderPreference.female:
        return Icons.female_rounded;
      case GenderPreference.mixed:
        return Icons.wc_rounded;
      case GenderPreference.any:
        return Icons.groups_rounded;
    }
  }

  String _getGenderText(GenderPreference gender) {
    switch (gender) {
      case GenderPreference.male:
        return 'Erkek';
      case GenderPreference.female:
        return 'Kadın';
      case GenderPreference.mixed:
        return 'Karma';
      case GenderPreference.any:
        return 'Farketmez';
    }
  }

  String _getRecurringText(String? pattern) {
    if (pattern == null) return 'Tekrar';
    switch (pattern) {
      case 'weekly':
        return 'Haftalık';
      case 'biweekly':
        return '2 Haftada';
      case 'monthly':
        return 'Aylık';
      default:
        return 'Tekrar';
    }
  }
}
