import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/group_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/create_group_screen.dart';
import 'package:playmatchr/screens/group_detail_screen.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String? _selectedSportFilter;
  String _sortBy = 'newest'; // newest, popular, name

  @override
  Widget build(BuildContext context) {
    final GroupController controller = Get.put(GroupController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kulüpler & Gruplar'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.explore_rounded), text: 'Keşfet'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Gruplarım'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => _showSearchScreen(context, controller),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filtrele & Sırala',
              onSelected: (value) {
                if (value.startsWith('sport_')) {
                  setState(() {
                    _selectedSportFilter = value.substring(6);
                  });
                } else if (value == 'clear_filter') {
                  setState(() {
                    _selectedSportFilter = null;
                  });
                } else {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'newest',
                  child: Row(
                    children: [
                      Icon(Icons.new_releases_rounded),
                      SizedBox(width: 8),
                      Text('En Yeni'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'popular',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded),
                      SizedBox(width: 8),
                      Text('En Popüler'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha_rounded),
                      SizedBox(width: 8),
                      Text('A-Z'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'Spor Dalı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                if (_selectedSportFilter != null) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_filter',
                    child: Text(
                      'Filtreyi Temizle',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildExploreTab(controller),
            _buildMyGroupsTab(controller),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const CreateGroupScreen()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Grup Oluştur'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildExploreTab(GroupController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtreleme ve sıralama
      var groups = controller.publicGroups.toList();

      // Spor dalına göre filtrele
      if (_selectedSportFilter != null) {
        groups = groups.where((g) => g.sport == _selectedSportFilter).toList();
      }

      // Sırala
      if (_sortBy == 'popular') {
        groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      } else if (_sortBy == 'name') {
        groups.sort((a, b) => a.name.compareTo(b.name));
      } else {
        // newest (default)
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (groups.isEmpty) {
        return _buildEmptyState(
          icon: Icons.groups_outlined,
          title: _selectedSportFilter != null
              ? '$_selectedSportFilter için grup yok'
              : 'Henüz Grup Yok',
          subtitle: _selectedSportFilter != null
              ? 'Filtreyi değiştirin veya yeni grup oluşturun'
              : 'İlk grubu siz oluşturun!',
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.loadGroups(),
        child: Column(
          children: [
            // Filter indicator
            if (_selectedSportFilter != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtre: $_selectedSportFilter',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${groups.length} grup',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupCard(group, controller);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMyGroupsTab(GroupController controller) {
    return Obx(() {
      if (controller.myGroups.isEmpty) {
        return _buildEmptyState(
          icon: Icons.group_add_rounded,
          title: 'Hiç Grubunuz Yok',
          subtitle: 'Bir gruba katılın veya yeni bir grup oluşturun',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: controller.myGroups.length,
        itemBuilder: (context, index) {
          final group = controller.myGroups[index];
          return _buildGroupCard(group, controller);
        },
      );
    });
  }

  Widget _buildGroupCard(Group group, GroupController controller) {
    final isMember = controller.isMember(group);
    final isAdmin = controller.isAdmin(group);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => GroupDetailScreen(groupId: group.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getGroupIcon(group.sport),
                      color: Colors.white,
                      size: 28,
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
                                group.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAdmin)
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
                                  'Admin',
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
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount} üye',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (group.sport != null) ...[
                              const SizedBox(width: 12),
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
                                  group.sport!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                group.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags
              if (group.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: group.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Action button
              if (!isMember)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: group.isFull
                        ? null
                        : () => controller.joinGroup(group.id),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(group.isFull ? 'Dolu' : 'Katıl'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchScreen(BuildContext context, GroupController controller) {
    showSearch(context: context, delegate: GroupSearchDelegate(controller));
  }

  IconData _getGroupIcon(String? sport) {
    if (sport == null) return Icons.groups_rounded;
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
        return Icons.sports_rounded;
    }
  }
}

// Search Delegate for Groups
class GroupSearchDelegate extends SearchDelegate<Group?> {
  final GroupController controller;

  GroupSearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Grup ara...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Bir şeyler yazarak arama yapın'));
    }

    // Aramayı tetikle
    controller.searchGroups(query);

    return Obx(() {
      if (controller.isSearching.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final results = controller.searchResults;

      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$query" için grup bulunamadı',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final group = results[index];
          final isMember = controller.isMember(group);

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getGroupIcon(group.sport),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount} üye',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (group.sport != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            group.sport!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: isMember
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                close(context, null);
                Get.to(() => GroupDetailScreen(groupId: group.id));
              },
            ),
          );
        },
      );
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Grup ara',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grup adı, açıklama veya etiket ile arama yapın',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Canlı arama için buildResults'u kullan
    return buildResults(context);
  }

  IconData _getGroupIcon(String? sport) {
    if (sport == null) return Icons.groups_rounded;
    switch (sport.toLowerCase() ?? '') {
      case 'futbol':
        return Icons.sports_soccer_rounded;
      case 'basketbol':
        return Icons.sports_basketball_rounded;
      case 'tenis':
        return Icons.sports_tennis_rounded;
      case 'voleybol':
        return Icons.sports_volleyball_rounded;
      default:
        return Icons.sports_rounded;
    }
  }
}
