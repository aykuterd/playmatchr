import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/services/match_result_service.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/notification_controller.dart';

class MatchController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final MatchResultService _matchResultService = MatchResultService();
  final AuthController _authController = Get.find<AuthController>();
  late final NotificationController _notificationController;

  final Rx<List<Match>> upcomingMatches = Rx<List<Match>>([]);
  final Rx<List<Match>> pastMatches = Rx<List<Match>>([]);
  final Rx<List<Match>> discoveryMatches = Rx<List<Match>>([]);
  final Rx<List<Invitation>> invitations = Rx<List<Invitation>>([]);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🎮 MatchController.onInit() called');

    try {
      _notificationController = Get.find<NotificationController>();
    } catch (e) {
      debugPrint('NotificationController not found, will be initialized later: $e');
    }

    // The 'ever' worker listens for changes in the user stream.
    // This is the correct, reactive way to handle this dependency.
    ever(_authController.user, (User? user) {
      debugPrint('🎮 MatchController: User changed to: ${user?.uid}');

      if (user != null) {
        // If the user is logged in, bind the streams to listen for data.
        debugPrint('🎮 MatchController: Binding streams for user ${user.uid}');
        isLoading.value = true;

        upcomingMatches.bindStream(_firestoreService.getUpcomingMatches(user.uid));
        pastMatches.bindStream(_firestoreService.getPastMatches(user.uid));
        invitations.bindStream(_firestoreService.getInvitations(user.uid));
        fetchDiscoveryMatches();

        // Process expired match result confirmations
        _matchResultService.processExpiredConfirmations();

        isLoading.value = false;
        debugPrint('🎮 MatchController: Streams bound successfully');
      } else {
        // If the user is logged out, clear the lists to avoid showing old data.
        debugPrint('🎮 MatchController: User logged out, clearing matches');
        upcomingMatches.value = [];
        pastMatches.value = [];
        invitations.value = [];
        discoveryMatches.value = [];
      }
    });

    // Listen for userProfile changes to refresh discovery matches
    ever(_authController.userProfile, (profile) {
      if (profile != null && _authController.user.value != null) {
        debugPrint('🎮 MatchController: User profile changed, refreshing discovery matches');
        fetchDiscoveryMatches();
      }
    });

    // Also bind immediately if user is already logged in
    final currentUser = _authController.user.value;
    if (currentUser != null) {
      debugPrint('🎮 MatchController: User already logged in, binding streams immediately');
      isLoading.value = true;
      upcomingMatches.bindStream(_firestoreService.getUpcomingMatches(currentUser.uid));
      pastMatches.bindStream(_firestoreService.getPastMatches(currentUser.uid));
      invitations.bindStream(_firestoreService.getInvitations(currentUser.uid));
      fetchDiscoveryMatches();

      // Process expired match result confirmations
      _matchResultService.processExpiredConfirmations();

      isLoading.value = false;
    }
  }

  void fetchDiscoveryMatches() {
    final userProfile = _authController.userProfile.value;
    if (userProfile != null) {
      // Use preferredSports if available, otherwise fall back to favoriteSports
      final sportsToUse = userProfile.preferredSports.isNotEmpty
          ? userProfile.preferredSports
          : userProfile.favoriteSports;

      discoveryMatches.bindStream(_firestoreService.getMatchesLookingForOpponents(
        sportTypes: sportsToUse,
        city: userProfile.preferredCity,
      ));

      debugPrint('🔍 Fetching discovery matches with preferences:');
      debugPrint('   Sports: $sportsToUse');
      debugPrint('   City: ${userProfile.preferredCity}');
    } else {
      debugPrint('⚠️  Cannot fetch discovery matches: User profile is null');
    }
  }

  // Lazy getter for notification controller
  NotificationController get notificationController {
    try {
      return _notificationController;
    } catch (e) {
      _notificationController = Get.find<NotificationController>();
      return _notificationController;
    }
  }

  Future<void> createMatch(Match match) {
    return _firestoreService.createMatch(match);
  }

  Future<void> acceptInvitation(Invitation invitation) async {
    await _firestoreService.updateInvitationStatus(invitation.id, 'accepted');
    await _firestoreService.updateMatchStatus(invitation.matchId, 'accepted');
  }

  Future<void> declineInvitation(Invitation invitation) async {
    await _firestoreService.updateInvitationStatus(invitation.id, 'declined');
    await _firestoreService.updateMatchStatus(invitation.matchId, 'declined');
  }

  /// Arkadaşlara maç daveti gönder
  Future<void> inviteFriendsToMatch({
    required String matchId,
    required List<String> friendIds,
    required String sportType,
    required DateTime matchDate,
  }) async {
    try {
      for (final friendId in friendIds) {
        // Send notification
        await notificationController.sendMatchInviteNotification(
          toUserId: friendId,
          matchId: matchId,
          sportType: sportType,
          matchDate: matchDate,
        );
      }

      Get.snackbar(
        'Başarılı',
        '${friendIds.length} arkadaşınıza maç daveti gönderildi',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error inviting friends to match: $e');
      Get.snackbar(
        'Hata',
        'Maç daveti gönderilemedi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Rastgele kullanıcılara maç daveti gönder
  Future<void> inviteRandomUsersToMatch({
    required String matchId,
    required String sportType,
    required DateTime matchDate,
    int count = 10,
  }) async {
    try {
      // TODO: Implement logic to find random users based on:
      // - Sport preference
      // - Skill level
      // - Location proximity
      // - Active users

      debugPrint('Searching for random users to invite...');
      Get.snackbar(
        'Bilgi',
        'Rastgele kullanıcı daveti özelliği yakında eklenecek',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error inviting random users: $e');
    }
  }
}
