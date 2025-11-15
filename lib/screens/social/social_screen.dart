import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/social_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/social/user_profile_screen.dart';
import 'package:playmatchr/widgets/profile_avatar.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialController _socialController = Get.put(SocialController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern Wave Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Stack(
              children: [
                // Wave Background
                ClipPath(
                  clipper: _SocialWaveClipper(),
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1E3A8A),
                          Color(0xFF1E40AF),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 100,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        // Icons decoration
                        Positioned(
                          top: 60,
                          right: 40,
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 30,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        Positioned(
                          top: 90,
                          left: 50,
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 25,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        // Title
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.people_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Roboto',
                                      letterSpacing: -0.5,
                                    ),
                                    child: Text('Sosyal'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'Roboto',
                                ),
                                child: const Text('Arkadaşlarını bul ve bağlantı kur'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _socialController.searchUsers(value),
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final friendsCount = _socialController.friends.length;
                final requestsCount = _socialController.friendRequests.length;
                final sentCount = _socialController.sentRequests.length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people_rounded,
                        count: friendsCount,
                        label: 'Arkadaşlar',
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.mail_rounded,
                        count: requestsCount,
                        label: 'İstekler',
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.send_rounded,
                        count: sentCount,
                        label: 'Gönderilen',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E3A8A),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1E3A8A),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'Kullanıcılar'),
                  Tab(text: 'Arkadaşlar'),
                  Tab(text: 'İstekler'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Roboto',
            ),
            child: Text(count.toString()),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Obx(() {
      if (_socialController.isSearching.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = _searchController.text.isEmpty
          ? _socialController.suggestedUsers
          : _socialController.searchResults;

      if (users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Kullanıcı Bulunamadı'),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Farklı bir arama yapın'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(users[index]);
        },
      );
    });
  }

  Widget _buildFriendsTab() {
    return Obx(() {
      final friends = _socialController.friends;

      if (friends.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Henüz Arkadaşın Yok'),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Kullanıcılar sekmesinden arkadaş ekle'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return _buildFriendCard(friends[index]);
        },
      );
    });
  }

  Widget _buildRequestsTab() {
    return Obx(() {
      final requests = _socialController.friendRequests;

      if (requests.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontFamily: 'Roboto',
                  ),
                  child: const Text('Arkadaşlık İsteği Yok'),
                ),
                const SizedBox(height: 8),
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontFamily: 'Roboto',
                  ),
                  child: const Text('Yeni istekler burada görünecek'),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index]);
        },
      );
    });
  }

  // ... other imports

  // ... inside _SocialScreenState class

  Widget _buildUserCard(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserProfile(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image using the new widget
                ProfileAvatar(photoUrl: user.photoUrl, radius: 28),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                        ),
                        child: Text(user.displayName),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                        child: Text('@${user.username}'),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'Roboto',
                          ),
                          child: Text(
                            user.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Button
                Obx(() {
                  final isFriend = _socialController.isFriend(user.uid);
                  final hasSentRequest = _socialController.hasSentRequest(
                    user.uid,
                  );

                  return ElevatedButton(
                    onPressed: () {
                      if (isFriend) {
                        _socialController.removeFriend(user.uid);
                      } else if (hasSentRequest) {
                        _socialController.cancelFriendRequest(user.uid);
                      } else {
                        _socialController.sendFriendRequest(user.uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFriend
                          ? Colors.grey[300]
                          : hasSentRequest
                          ? Colors.grey[200]
                          : const Color(0xFF1E3A8A),
                      foregroundColor: isFriend || hasSentRequest
                          ? Colors.grey[700]
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFriend
                          ? 'Arkadaş'
                          : hasSentRequest
                          ? 'Gönderildi'
                          : 'Ekle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(UserProfile friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserProfile(friend),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                ProfileAvatar(photoUrl: friend.photoUrl, radius: 28),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                        ),
                        child: Text(friend.displayName),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                        child: Text('@${friend.username}'),
                      ),
                    ],
                  ),
                ),
                // Message Button
                IconButton(
                  onPressed: () {
                    // TODO: Open message screen
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  color: const Color(0xFF1E3A8A),
                ),
                // More Options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'remove') {
                      _showRemoveFriendDialog(friend);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Arkadaşlıktan Çıkar',
                            style: TextStyle(color: Colors.red),
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
      ),
    );
  }

  Widget _buildRequestCard(UserProfile requester) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image
            ProfileAvatar(photoUrl: requester.photoUrl, radius: 28),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                    child: Text(requester.displayName),
                  ),
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'Roboto',
                    ),
                    child: Text('@${requester.username}'),
                  ),
                ],
              ),
            ),
            // Accept Button
            ElevatedButton(
              onPressed: () =>
                  _socialController.acceptFriendRequest(requester.uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
                child: Text('Kabul Et'),
              ),
            ),
            const SizedBox(width: 8),
            // Reject Button
            OutlinedButton(
              onPressed: () =>
                  _socialController.rejectFriendRequest(requester.uid),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                ),
                child: const Text('Reddet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(UserProfile user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
    );
  }

  void _showRemoveFriendDialog(UserProfile friend) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
          child: const Text('Arkadaşlıktan Çıkar'),
        ),
        content: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Roboto',
          ),
          child: Text(
            '${friend.displayName} kişisini arkadaş listenizden çıkarmak istediğinize emin misiniz?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              _socialController.removeFriend(friend.uid);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }
}

// Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.grey[50], child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Wave Clipper for Social Header
class _SocialWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
