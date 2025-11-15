import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/notification_controller.dart';
import 'package:playmatchr/screens/create_match/create_match_screen.dart';
import 'package:playmatchr/screens/home/home_screen.dart';
import 'package:playmatchr/screens/notifications/notification_screen.dart';
import 'package:playmatchr/screens/profile_screen.dart';
import 'package:playmatchr/screens/social/social_screen.dart';
import 'package:playmatchr/screens/community_screen.dart';
import 'package:playmatchr/widgets/profile_avatar.dart';

import '../controllers/match_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _controllersInitialized = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SocialScreen(),
    const CommunityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;

    try {
      // Lazy load controllers - sadece giriş yapıldıktan sonra
      Get.put(NotificationController(), permanent: true);
      Get.put(MatchController(), permanent: true);
      _controllersInitialized = true;
      debugPrint('Controllers initialized successfully');
    } catch (e) {
      debugPrint('Error initializing controllers: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      // Maç Oluştur butonuna basıldı - Modal olarak aç
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateMatchScreen(),
          fullscreenDialog: true,
        ),
      );
    } else {
      // Ana Sayfa (0), Sosyal (1), Topluluk (2)
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final NotificationController notificationController =
        Get.find<NotificationController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Notification Icon with Badge
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Badge
                Obx(() {
                  final unreadCount = notificationController.unreadCount.value;
                  if (unreadCount == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Profile Avatar
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: GestureDetector(
              onTap: () {
                // Profil sayfasına git
                Get.to(() => const ProfileScreen());
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() {
                  final user = authController.userProfile.value;
                  return ProfileAvatar(photoUrl: user?.photoUrl, radius: 18);
                }),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Sosyal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Topluluk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Oluştur',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
      ),
    );
  }
}
