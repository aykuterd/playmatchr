import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:playmatchr/controllers/tournament_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';
import 'package:playmatchr/widgets/tournament_bracket_widget.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final TournamentController _controller = Get.find<TournamentController>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tournament?>(
      future: _firestoreService.getTournament(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Turnuva')),
            body: const Center(child: Text('Turnuva bulunamadı')),
          );
        }

        final tournament = snapshot.data!;
        final isAdmin = _controller.isUserAdmin(tournament);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(tournament.name),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.info_outline), text: 'Bilgi'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Katılımcılar'),
                  Tab(icon: Icon(Icons.sports_score), text: 'Maçlar'),
                ],
              ),
              actions: [
                if (isAdmin)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: const [
                            Icon(Icons.edit_rounded),
                            SizedBox(width: 8),
                            Text('Durumu Değiştir'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'status') {
                        _showStatusChangeDialog(tournament);
                      } else if (value == 'delete') {
                        _confirmDelete(tournament);
                      }
                    },
                  ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildInfoTab(tournament),
                _buildParticipantsTab(tournament),
                _buildMatchesTab(tournament),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(tournament),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          if (tournament.bannerImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                tournament.bannerImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Status Badge
          _buildStatusBadge(tournament.status),

          const SizedBox(height: AppSpacing.lg),

          // Description
          _buildInfoSection(
            'Açıklama',
            Icons.description_outlined,
            tournament.description,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Sport
          _buildInfoRow(Icons.sports_rounded, 'Spor Dalı', tournament.sport),

          // Type
          _buildInfoRow(
            Icons.account_tree_rounded,
            'Turnuva Tipi',
            _getTournamentTypeText(tournament.type),
          ),

          // Dates
          _buildInfoRow(
            Icons.calendar_today,
            'Başlangıç Tarihi',
            DateFormat('dd MMMM yyyy, HH:mm').format(tournament.startDate),
          ),

          if (tournament.endDate != null)
            _buildInfoRow(
              Icons.event_rounded,
              'Bitiş Tarihi',
              DateFormat('dd MMMM yyyy, HH:mm').format(tournament.endDate!),
            ),

          // Location
          _buildInfoRow(
            Icons.location_on_outlined,
            'Konum',
            tournament.location.address,
          ),

          // Participants
          _buildInfoRow(
            Icons.people_outline,
            'Katılımcılar',
            '${tournament.participantCount} / ${tournament.maxParticipants}',
          ),

          // Entry Fee
          if (tournament.entryFee != null && tournament.entryFee! > 0)
            _buildInfoRow(
              Icons.attach_money,
              'Katılım Ücreti',
              '${tournament.entryFee!.toStringAsFixed(0)} TL',
            ),

          const SizedBox(height: AppSpacing.lg),

          // Organizer info (placeholder - you can enhance this later)
          _buildInfoSection(
            'Organizatör',
            Icons.person_outline,
            'ID: ${tournament.organizerId}',
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(Tournament tournament) {
    return StreamBuilder<List<TournamentRegistration>>(
      stream: _firestoreService.getTournamentRegistrations(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final registrations = snapshot.data ?? [];

        if (registrations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Henüz Katılımcı Yok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'İlk katılan siz olun!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: registrations.length,
          itemBuilder: (context, index) {
            final registration = registrations[index];
            return _buildParticipantCard(registration, index + 1);
          },
        );
      },
    );
  }

  Widget _buildMatchesTab(Tournament tournament) {
    return TournamentBracketWidget(
      tournamentId: tournament.id,
      tournament: tournament,
    );
  }

  Widget _buildParticipantCard(TournamentRegistration registration, int rank) {
    return FutureBuilder<UserProfile?>(
      future: _firestoreService.getUserProfile(registration.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user?.displayName ?? 'Yükleniyor...';
        final userPhoto = user?.photoUrl;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.amber : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar
                CircleAvatar(
                  backgroundImage: userPhoto != null
                      ? NetworkImage(userPhoto)
                      : null,
                  child: userPhoto == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        )
                      : null,
                ),
              ],
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Kayıt: ${DateFormat('dd MMM yyyy').format(registration.registrationDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: _buildRegistrationStatusBadge(registration.status),
          ),
        );
      },
    );
  }

  Widget _buildRoundSection(int round, List<TournamentMatch> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'Tur $round',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...matches.map((match) => _buildMatchCard(match)).toList(),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Player 1
                Expanded(
                  child: FutureBuilder<UserProfile?>(
                    future: match.player1Id != null
                        ? _firestoreService.getUserProfile(match.player1Id!)
                        : null,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.displayName ?? 'TBD',
                        style: TextStyle(
                          fontWeight: match.winnerId == match.player1Id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.start,
                      );
                    },
                  ),
                ),
                // Score / VS
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    match.isCompleted ? '-' : 'vs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Player 2
                Expanded(
                  child: FutureBuilder<UserProfile?>(
                    future: match.player2Id != null
                        ? _firestoreService.getUserProfile(match.player2Id!)
                        : null,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.displayName ?? 'TBD',
                        style: TextStyle(
                          fontWeight: match.winnerId == match.player2Id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.end,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMatchStatusBadge(match.status),
                if (match.scheduledDate != null)
                  Text(
                    DateFormat('dd MMM, HH:mm').format(match.scheduledDate!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Tournament tournament) {
    final isAdmin = _controller.isUserAdmin(tournament);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: FutureBuilder<bool>(
          future: _controller.isUserRegistered(widget.tournamentId),
          builder: (context, registrationSnapshot) {
            if (!registrationSnapshot.hasData) {
              return const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final isRegistered = registrationSnapshot.data!;

            return StreamBuilder<List<TournamentMatch>>(
              stream: _firestoreService.getTournamentMatches(
                widget.tournamentId,
              ),
              builder: (context, matchesSnapshot) {
                // Hata varsa veya veri yoksa boş liste kullan
                final matches = matchesSnapshot.data ?? [];

                final canRegister = tournament.canRegister && !isRegistered;
                final canUnregister =
                    isRegistered &&
                    (tournament.status == TournamentStatus.registrationOpen);

                final canGenerateBracket =
                    isAdmin &&
                    tournament.status == TournamentStatus.registrationClosed &&
                    matches.isEmpty;

                // Eğer gösterilecek bir buton yoksa, boşluk bırak
                if (!canRegister && !canUnregister && !canGenerateBracket) {
                  return const SizedBox.shrink();
                }

                // Spor kategorisini belirle
                final sportCategory = getSportCategory(tournament.sport);
                final isTeamSport = sportCategory == MatchType.team;

                // Buton metni
                String buttonText;
                if (canGenerateBracket) {
                  buttonText = 'Fikstürü Oluştur';
                } else if (isRegistered) {
                  buttonText = isTeamSport
                      ? 'Takım Kaydını İptal Et'
                      : 'Kaydı İptal Et';
                } else {
                  buttonText = isTeamSport
                      ? 'Takımla Katıl'
                      : 'Turnuvaya Katıl';
                }

                return ElevatedButton(
                  onPressed: () async {
                    if (canGenerateBracket) {
                      _confirmGenerateBracket(tournament);
                    } else if (isRegistered) {
                      final confirmed = await _confirmUnregister();
                      if (confirmed) {
                        await _controller.unregisterFromTournament(
                          widget.tournamentId,
                        );
                        setState(() {}); // Rebuild to update button state
                      }
                    } else {
                      // Takım sporu ise, takım kayıt formunu aç
                      if (isTeamSport) {
                        _showTeamRegistrationDialog(tournament);
                      } else {
                        await _controller.registerForTournament(
                          widget.tournamentId,
                        );
                        setState(() {}); // Rebuild to update button state
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canGenerateBracket
                        ? Colors.green
                        : (isRegistered ? Colors.orange : AppColors.primary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmGenerateBracket(Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fikstürü Oluştur'),
        content: Text(
          '${tournament.participantCount} katılımcı için fikstür oluşturulacak. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        // Call the cloud function
        final HttpsCallable callable = FirebaseFunctions.instanceFor(
          region: 'us-central1',
        ).httpsCallable('generateBracket');
        final result = await callable.call({
          'tournamentId': widget.tournamentId,
        });

        Get.back(); // Dismiss loading dialog

        if (result.data['success'] == true) {
          Get.snackbar(
            'Başarılı',
            'Fikstür başarıyla oluşturuldu!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // The matches tab will update automatically thanks to the stream
        } else {
          throw Exception(
            result.data['message'] ?? 'Bilinmeyen bir hata oluştu.',
          );
        }
      } catch (e) {
        Get.back(); // Dismiss loading dialog
        Get.snackbar(
          'Hata',
          'Fikstür oluşturulurken bir hata oluştu: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Widget _buildInfoSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationStatusBadge(RegistrationStatus status) {
    Color color;
    String text;

    switch (status) {
      case RegistrationStatus.confirmed:
        color = Colors.green;
        text = 'Onaylandı';
        break;
      case RegistrationStatus.pendingPayment:
        color = Colors.orange;
        text = 'Ödeme Bekliyor';
        break;
      case RegistrationStatus.waitlisted:
        color = Colors.grey;
        text = 'Yedek';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMatchStatusBadge(TournamentMatchStatus status) {
    Color color;
    String text;

    switch (status) {
      case TournamentMatchStatus.scheduled:
        color = Colors.blue;
        text = 'Planlandı';
        break;
      case TournamentMatchStatus.inProgress:
        color = Colors.orange;
        text = 'Devam Ediyor';
        break;
      case TournamentMatchStatus.completed:
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case TournamentMatchStatus.disputed:
        color = Colors.red;
        text = 'Anlaşmazlık';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getTournamentTypeText(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Eleme Usulü';
      case TournamentType.roundRobin:
        return 'Lig Usulü (Herkes Herkesle)';
      case TournamentType.league:
        return 'Lig Sistemi';
    }
  }

  Future<bool> _confirmUnregister() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kaydı İptal Et'),
            content: const Text(
              'Turnuva kaydınızı iptal etmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('İptal Et'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmDelete(Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turnuvayı Sil'),
        content: const Text(
          'Bu turnuvayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteTournament(widget.tournamentId);
      if (success) {
        // Turnuva başarıyla silindi, ana listeye geri dön
        if (mounted) {
          Navigator.of(context).pop(); // Pop detail screen
        }
      }
    }
  }

  Future<void> _showTeamRegistrationDialog(Tournament tournament) async {
    final teamNameController = TextEditingController();
    Color primaryColor = const Color(0xFFFF5733); // Kırmızı
    Color secondaryColor = const Color(0xFFFFC300); // Sarı

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.groups, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Takım Bilgileri'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Takımınızı kaydetmek için bilgileri girin:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Takım Adı *',
                    hintText: 'Örn: Galatasaray, Fenerbahçe',
                    prefixIcon: Icon(Icons.shield),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                // Ana Renk Seçici
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ana Renk',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        Color tempColor = primaryColor;
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Ana Renk Seç'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: primaryColor,
                                onColorChanged: (color) => tempColor = color,
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, tempColor),
                                child: const Text('Seç'),
                              ),
                            ],
                          ),
                        );
                        if (picked != null) {
                          setState(() => primaryColor = picked);
                        }
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.palette, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // İkincil Renk Seçici
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İkincil Renk',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        Color tempColor = secondaryColor;
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('İkincil Renk Seç'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: secondaryColor,
                                onColorChanged: (color) => tempColor = color,
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, tempColor),
                                child: const Text('Seç'),
                              ),
                            ],
                          ),
                        );
                        if (picked != null) {
                          setState(() => secondaryColor = picked);
                        }
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.palette_outlined, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logo daha sonra profil ayarlarından ekleyebilirsiniz.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Takımı Kaydet'),
          ),
        ],
      ),
      ),
    );

    if (confirmed == true && teamNameController.text.isNotEmpty) {
      try {
        // Önce takım oluştur
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          Get.snackbar('Hata', 'Giriş yapmalısınız');
          return;
        }

        // Color'ları hex string'e çevir
        String colorToHex(Color color) {
          return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
        }

        final team = TournamentTeam(
          id: '',
          tournamentId: widget.tournamentId,
          teamName: teamNameController.text.trim(),
          captainId: userId,
          primaryColor: colorToHex(primaryColor),
          secondaryColor: colorToHex(secondaryColor),
          createdAt: DateTime.now(),
        );

        final teamId = await _firestoreService.createTournamentTeam(team);

        // Sonra turnuvaya kayıt yap (team ID'sini userId olarak kullan)
        await _controller.registerForTournament(widget.tournamentId);

        Get.snackbar(
          'Başarılı',
          'Takımınız "${teamNameController.text}" başarıyla kaydedildi!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        setState(() {});
      } catch (e) {
        Get.snackbar(
          'Hata',
          'Takım kaydı sırasında hata oluştu: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

    teamNameController.dispose();
  }

  /// Geçerli durum geçişlerini döndürür
  List<TournamentStatus> _getAvailableStatusTransitions(
    TournamentStatus currentStatus,
  ) {
    switch (currentStatus) {
      case TournamentStatus.draft:
        return [TournamentStatus.registrationOpen, TournamentStatus.cancelled];
      case TournamentStatus.registrationOpen:
        return [
          TournamentStatus.registrationClosed,
          TournamentStatus.cancelled,
        ];
      case TournamentStatus.registrationClosed:
        return [
          TournamentStatus.registrationOpen,
          TournamentStatus.active,
          TournamentStatus.cancelled,
        ];
      case TournamentStatus.active:
        return [TournamentStatus.completed, TournamentStatus.cancelled];
      case TournamentStatus.completed:
        return []; // Son durum, değiştirilemez
      case TournamentStatus.cancelled:
        return [TournamentStatus.draft]; // İptalden sadece taslağa dönülebilir
    }
  }

  Future<void> _showStatusChangeDialog(Tournament tournament) async {
    final availableStatuses = _getAvailableStatusTransitions(tournament.status);

    if (availableStatuses.isEmpty) {
      Get.snackbar(
        'Bilgi',
        'Bu durumdan başka bir duruma geçiş yapılamaz.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final newStatus = await showDialog<TournamentStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turnuva Durumunu Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mevcut durum göstergesi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Şu Anki Durum:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(tournament.status),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Geçilebilecek Durumlar:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...availableStatuses.map((status) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  title: Text(
                    _getStatusText(status),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _getStatusDescription(status),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  onTap: () => Navigator.pop(context, status),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != tournament.status) {
      await _controller.updateTournamentStatus(widget.tournamentId, newStatus);
      setState(() {});
    }
  }

  IconData _getStatusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return Icons.edit_note;
      case TournamentStatus.registrationOpen:
        return Icons.how_to_reg;
      case TournamentStatus.registrationClosed:
        return Icons.lock;
      case TournamentStatus.active:
        return Icons.play_arrow;
      case TournamentStatus.completed:
        return Icons.check_circle;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return Colors.grey;
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.active:
        return Colors.blue;
      case TournamentStatus.completed:
        return Colors.purple;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusDescription(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'Turnuva henüz yayınlanmamış, düzenlenebilir.';
      case TournamentStatus.registrationOpen:
        return 'Kullanıcılar turnuvaya kayıt olabilir.';
      case TournamentStatus.registrationClosed:
        return 'Kayıtlar kapandı, fikstür oluşturulabilir.';
      case TournamentStatus.active:
        return 'Turnuva başladı, maçlar oynanıyor.';
      case TournamentStatus.completed:
        return 'Turnuva tamamlandı, kazanan belli oldu.';
      case TournamentStatus.cancelled:
        return 'Turnuva iptal edildi.';
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
