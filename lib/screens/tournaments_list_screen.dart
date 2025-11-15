import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:playmatchr/controllers/tournament_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/create_tournament_screen.dart';
import 'package:playmatchr/screens/tournament_detail_screen.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  String? _selectedSportFilter;
  TournamentStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final TournamentController controller = Get.put(TournamentController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Turnuvalar'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.explore_rounded), text: 'Tümü'),
              Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Kayıtlılarım'),
              Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Düzenlediğim'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filtrele',
              onSelected: (value) {
                if (value.startsWith('sport_')) {
                  setState(() {
                    _selectedSportFilter = value.substring(6);
                  });
                } else if (value.startsWith('status_')) {
                  final statusStr = value.substring(7);
                  setState(() {
                    _selectedStatusFilter = TournamentStatus.values.firstWhere(
                      (e) => e.toString().split('.').last == statusStr,
                    );
                  });
                } else if (value == 'clear_filter') {
                  setState(() {
                    _selectedSportFilter = null;
                    _selectedStatusFilter = null;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  enabled: false,
                  child: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const PopupMenuItem(
                  value: 'status_registrationOpen',
                  child: Text('📝 Kayıtlar Açık'),
                ),
                const PopupMenuItem(
                  value: 'status_active',
                  child: Text('▶️ Devam Eden'),
                ),
                const PopupMenuItem(
                  value: 'status_completed',
                  child: Text('✅ Tamamlanan'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  child: Text('Spor Dalı', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const PopupMenuItem(
                  value: 'sport_Futbol',
                  child: Text('⚽ Futbol'),
                ),
                const PopupMenuItem(
                  value: 'sport_Basketbol',
                  child: Text('🏀 Basketbol'),
                ),
                const PopupMenuItem(
                  value: 'sport_Tenis',
                  child: Text('🎾 Tenis'),
                ),
                const PopupMenuItem(
                  value: 'sport_Voleybol',
                  child: Text('🏐 Voleybol'),
                ),
                if (_selectedSportFilter != null || _selectedStatusFilter != null) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_filter',
                    child: Text('Filtreyi Temizle', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAllTournamentsTab(controller),
            _buildRegisteredTournamentsTab(controller),
            _buildMyTournamentsTab(controller),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const CreateTournamentScreen()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Turnuva Oluştur'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAllTournamentsTab(TournamentController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtreleme
      var tournaments = controller.allTournaments.toList();

      // Spor dalına göre filtrele
      if (_selectedSportFilter != null) {
        tournaments = tournaments.where((t) => t.sport == _selectedSportFilter).toList();
      }

      // Duruma göre filtrele
      if (_selectedStatusFilter != null) {
        tournaments = tournaments.where((t) => t.status == _selectedStatusFilter).toList();
      }

      if (tournaments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Henüz Turnuva Yok',
          subtitle: 'İlk turnuvayı siz oluşturun!',
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.loadTournaments(),
        child: Column(
          children: [
            // Filter indicator
            if (_selectedSportFilter != null || _selectedStatusFilter != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          if (_selectedSportFilter != null) _selectedSportFilter!,
                          if (_selectedStatusFilter != null) _getStatusText(_selectedStatusFilter!),
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${tournaments.length} turnuva',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final tournament = tournaments[index];
                  return _buildTournamentCard(tournament, controller);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRegisteredTournamentsTab(TournamentController controller) {
    return Obx(() {
      if (controller.registeredTournaments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.how_to_reg_outlined,
          title: 'Kayıtlı Turnuva Yok',
          subtitle: 'Bir turnuvaya kaydolun ve mücadele edin!',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: controller.registeredTournaments.length,
        itemBuilder: (context, index) {
          final tournament = controller.registeredTournaments[index];
          return _buildTournamentCard(tournament, controller);
        },
      );
    });
  }

  Widget _buildMyTournamentsTab(TournamentController controller) {
    return Obx(() {
      if (controller.myTournaments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Henüz Turnuva Düzenlemediniz',
          subtitle: 'İlk turnuvanızı oluşturun ve oyuncuları bir araya getirin!',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: controller.myTournaments.length,
        itemBuilder: (context, index) {
          final tournament = controller.myTournaments[index];
          return _buildTournamentCard(tournament, controller);
        },
      );
    });
  }

  Widget _buildTournamentCard(Tournament tournament, TournamentController controller) {
    final isOrganizer = controller.isUserAdmin(tournament);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => TournamentDetailScreen(tournamentId: tournament.id)),
        child: Column(
          children: [
            // Banner image
            if (tournament.bannerImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  tournament.bannerImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.emoji_events, size: 64, color: Colors.white),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getSportIcon(tournament.sport),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tournament.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOrganizer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Organizatör',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _buildStatusBadge(tournament.status),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    tournament.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Info row
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(tournament.startDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.participantCount}/${tournament.maxParticipants}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.sport,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Entry fee
                  if (tournament.entryFee != null && tournament.entryFee! > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Katılım Ücreti: ${tournament.entryFee!.toStringAsFixed(0)} TL',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case TournamentStatus.draft:
        bgColor = Colors.grey;
        textColor = Colors.white;
        text = 'Taslak';
        icon = Icons.edit_note;
        break;
      case TournamentStatus.registrationOpen:
        bgColor = Colors.green;
        textColor = Colors.white;
        text = 'Kayıtlar Açık';
        icon = Icons.how_to_reg;
        break;
      case TournamentStatus.registrationClosed:
        bgColor = Colors.orange;
        textColor = Colors.white;
        text = 'Kayıtlar Kapandı';
        icon = Icons.lock;
        break;
      case TournamentStatus.active:
        bgColor = Colors.blue;
        textColor = Colors.white;
        text = 'Devam Ediyor';
        icon = Icons.play_arrow;
        break;
      case TournamentStatus.completed:
        bgColor = Colors.purple;
        textColor = Colors.white;
        text = 'Tamamlandı';
        icon = Icons.check_circle;
        break;
      case TournamentStatus.cancelled:
        bgColor = Colors.red;
        textColor = Colors.white;
        text = 'İptal Edildi';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'futbol':
      case 'soccer':
        return Icons.sports_soccer_rounded;
      case 'basketbol':
      case 'basketball':
        return Icons.sports_basketball_rounded;
      case 'tenis':
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'voleybol':
      case 'volleyball':
        return Icons.sports_volleyball_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  String _getStatusText(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'Taslak';
      case TournamentStatus.registrationOpen:
        return 'Kayıtlar Açık';
      case TournamentStatus.registrationClosed:
        return 'Kayıtlar Kapandı';
      case TournamentStatus.active:
        return 'Devam Ediyor';
      case TournamentStatus.completed:
        return 'Tamamlandı';
      case TournamentStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}
