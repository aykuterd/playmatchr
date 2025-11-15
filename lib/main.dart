import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/screens/create_match/create_match_screen.dart';
import 'package:playmatchr/screens/invitations_screen.dart';
import 'package:playmatchr/screens/main_screen.dart';
import 'package:playmatchr/screens/match_invitation_detail_screen.dart';
import 'package:playmatchr/screens/new_match_screen.dart';
import 'package:playmatchr/screens/profile_screen.dart';
import 'package:playmatchr/screens/profile_setup_screen.dart';
import 'package:playmatchr/screens/signin_screen.dart';
import 'package:playmatchr/screens/signup_screen.dart';
import 'package:playmatchr/screens/social/social_screen.dart';
import 'package:playmatchr/screens/splash_screen.dart';
import 'package:playmatchr/screens/welcome_screen.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/services/push_notification_service.dart';
import 'package:playmatchr/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Türkçe tarih formatı için locale başlat
  await initializeDateFormatting('tr', null);

  // Push notification servisini güvenli bir şekilde başlat
  // iOS simulator'da çalışmazsa da uygulama crash etmez
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Push notification initialization failed: $e');
    debugPrint(
      'This is expected on iOS simulator. App will continue without push notifications.',
    );
  }

  // Sadece AuthController'ı başlat (diğerleri lazy load)
  Get.put(AuthController());
  Get.put(FirestoreService());

  runApp(const MyApp());
}

// ... (rest of the imports)

// ... (main function)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PlayMatchr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/signup', page: () => const SignUpScreen()),
        GetPage(name: '/signin', page: () => const SignInScreen()),
        GetPage(name: '/profile_setup', page: () => const ProfileSetupScreen()),
        GetPage(name: '/main_screen', page: () => const MainScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/new_match', page: () => const NewMatchScreen()),
        GetPage(name: '/create_match', page: () => const CreateMatchScreen()),
        GetPage(name: '/invitations', page: () => const InvitationsScreen()),
        GetPage(name: '/social', page: () => const SocialScreen()),
        GetPage(
          name: '/match_invitation/:matchId',
          page: () =>
              MatchInvitationDetailScreen(matchId: Get.parameters['matchId']!),
        ),
      ],
    );
  }
}
