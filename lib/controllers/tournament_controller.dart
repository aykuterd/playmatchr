import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';

class TournamentController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // Observable lists
  var allTournaments = <Tournament>[].obs;
  var registeredTournaments = <Tournament>[].obs;
  var myTournaments = <Tournament>[].obs;
  var isLoading = true.obs;

  // Stream subscriptions
  StreamSubscription<List<Tournament>>? _allTournamentsSubscription;
  StreamSubscription<List<Tournament>>? _myTournamentsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadTournaments();
  }

  @override
  void onClose() {
    _allTournamentsSubscription?.cancel();
    _myTournamentsSubscription?.cancel();
    super.onClose();
  }

  /// Load all tournaments
  void loadTournaments() {
    try {
      isLoading.value = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Load all tournaments
      _allTournamentsSubscription = _firestoreService
          .getAllTournaments()
          .listen((tournaments) {
        allTournaments.value = tournaments;
        debugPrint('✅ Loaded ${tournaments.length} tournaments');
      }, onError: (error) {
        debugPrint('❌ Error loading tournaments: $error');
      });

      // Load user's organized tournaments if logged in
      if (userId != null) {
        _myTournamentsSubscription = _firestoreService
            .getTournamentsByOrganizer(userId)
            .listen((tournaments) {
          myTournaments.value = tournaments;
          debugPrint('✅ Loaded ${tournaments.length} user tournaments');
        }, onError: (error) {
          debugPrint('❌ Error loading user tournaments: $error');
        });

        // Load user's registered tournaments
        _loadRegisteredTournaments(userId);
      }
    } catch (e) {
      debugPrint('❌ Error in loadTournaments: $e');
      Get.snackbar('Hata', 'Turnuvalar yüklenirken hata oluştu');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load tournaments user is registered for
  Future<void> _loadRegisteredTournaments(String userId) async {
    try {
      final tournaments = await _firestoreService.getUserRegisteredTournaments(userId);
      registeredTournaments.value = tournaments;
      debugPrint('✅ Loaded ${tournaments.length} registered tournaments');
    } catch (e) {
      debugPrint('❌ Error loading registered tournaments: $e');
    }
  }

  /// Get tournaments by status
  Stream<List<Tournament>> getTournamentsByStatus(TournamentStatus status) {
    return _firestoreService.getTournamentsByStatus(status);
  }

  /// Register for a tournament
  Future<bool> registerForTournament(String tournamentId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Hata', 'Kayıt olmak için giriş yapmalısınız');
        return false;
      }

      // Check if already registered
      final existingRegistration = await _firestoreService
          .getUserTournamentRegistration(tournamentId, userId);

      if (existingRegistration != null) {
        Get.snackbar('Bilgi', 'Bu turnuvaya zaten kayıtlısınız');
        return false;
      }

      await _firestoreService.registerForTournament(tournamentId, userId);

      // Reload registered tournaments
      await _loadRegisteredTournaments(userId);

      Get.snackbar(
        'Başarılı',
        'Turnuvaya başarıyla kaydoldunuz!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error registering for tournament: $e');
      Get.snackbar('Hata', 'Kayıt sırasında hata oluştu: $e');
      return false;
    }
  }

  /// Unregister from a tournament
  Future<bool> unregisterFromTournament(String tournamentId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      await _firestoreService.unregisterFromTournament(tournamentId, userId);

      // Reload registered tournaments
      await _loadRegisteredTournaments(userId);

      Get.snackbar(
        'Başarılı',
        'Turnuva kaydınız iptal edildi',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error unregistering from tournament: $e');
      Get.snackbar('Hata', 'Kayıt iptal edilirken hata oluştu');
      return false;
    }
  }

  /// Check if user is registered for a tournament
  Future<bool> isUserRegistered(String tournamentId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final registration = await _firestoreService
        .getUserTournamentRegistration(tournamentId, userId);

    return registration != null;
  }

  /// Check if user is tournament organizer or admin
  bool isUserAdmin(Tournament tournament) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    return tournament.isUserAdmin(userId);
  }

  /// Get tournament by ID
  Future<Tournament?> getTournament(String tournamentId) async {
    return await _firestoreService.getTournament(tournamentId);
  }

  /// Get tournament registrations
  Stream<List<TournamentRegistration>> getTournamentRegistrations(String tournamentId) {
    return _firestoreService.getTournamentRegistrations(tournamentId);
  }

  /// Get tournament matches
  Stream<List<TournamentMatch>> getTournamentMatches(String tournamentId) {
    return _firestoreService.getTournamentMatches(tournamentId);
  }

  /// Update tournament status
  Future<bool> updateTournamentStatus(String tournamentId, TournamentStatus status) async {
    try {
      await _firestoreService.updateTournament(tournamentId, {
        'status': status.toString().split('.').last,
      });

      Get.snackbar('Başarılı', 'Turnuva durumu güncellendi');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating tournament status: $e');
      Get.snackbar('Hata', 'Durum güncellenirken hata oluştu');
      return false;
    }
  }

  /// Delete tournament
  Future<bool> deleteTournament(String tournamentId) async {
    try {
      await _firestoreService.deleteTournament(tournamentId);
      Get.snackbar(
        'Başarılı',
        'Turnuva silindi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting tournament: $e');
      Get.snackbar('Hata', 'Turnuva silinirken hata oluştu');
      return false;
    }
  }

  /// Create a new tournament
  Future<bool> createTournament({
    required String name,
    required String description,
    required String sport,
    required TournamentType type,
    required DateTime startDate,
    DateTime? endDate,
    required MatchLocation location,
    required int maxParticipants,
    double? entryFee,
    String? bannerImageUrl,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Hata', 'Turnuva oluşturmak için giriş yapmalısınız');
        return false;
      }

      final tournament = Tournament(
        id: '', // Will be generated by Firestore
        name: name,
        description: description,
        organizerId: userId,
        admins: [],
        sport: sport,
        type: type,
        status: TournamentStatus.draft,
        startDate: startDate,
        endDate: endDate,
        location: location,
        maxParticipants: maxParticipants,
        entryFee: entryFee,
        bannerImageUrl: bannerImageUrl,
        createdAt: DateTime.now(),
      );

      final tournamentId = await _firestoreService.createTournament(tournament);

      Get.snackbar(
        'Başarılı',
        'Turnuva oluşturuldu! Şimdi durumunu "Kayıtlar Açık" yapabilirsiniz.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      debugPrint('✅ Tournament created with ID: $tournamentId');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating tournament: $e');
      Get.snackbar('Hata', 'Turnuva oluşturulurken hata oluştu: $e');
      return false;
    }
  }
}
