import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:playmatchr/controllers/notification_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';

class CreateMatchController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  late final NotificationController _notificationController;

  // Adım kontrolü
  var currentStep = 0.obs;
  final int totalSteps = 5;

  // 1. Adım: Spor Seçimi
  var selectedSport = Rx<String?>(null);
  var selectedMatchType = Rx<MatchType?>(null);

  // 2. Adım: Maç Detayları
  var selectedLevel = MatchLevel.intermediate.obs;
  var selectedMode = MatchMode.friendly.obs;
  var selectedDateTime = Rx<DateTime?>(null);
  var durationMinutes = 60.obs;
  var maxPlayersPerTeam = Rx<int?>(null);

  // 3. Adım: Konum
  var selectedLocation = Rx<MatchLocation?>(null);
  var isIndoor = false.obs;
  var venueName = ''.obs;

  // 4. Adım: Oyuncu/Takım Ayarları
  var team1Players = <TeamPlayer>[].obs;
  var team2Players = <TeamPlayer>[].obs;
  var genderPreference = GenderPreference.any.obs;
  var minAge = Rx<int?>(null);
  var maxAge = Rx<int?>(null);

  // 5. Adım: Ek Bilgiler
  var costPerPerson = Rx<double?>(null);
  var notes = ''.obs;
  var isRecurring = false.obs;
  var recurringPattern = Rx<String?>(null);

  // Rakip Arama Sistemi
  var lookingForOpponent = false.obs;
  var requiredOpponentCount = Rx<int?>(null);

  // Loading state
  var isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _notificationController = Get.find<NotificationController>();
    } catch (e) {
      debugPrint(
        'NotificationController not found, will be initialized later: $e',
      );
    }
    // Ev sahibi oyuncuyu otomatik ekle
    _addCurrentUserToTeam1();
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

  void _addCurrentUserToTeam1() {
    final user = _authController.user.value;
    if (user != null) {
      team1Players.add(
        TeamPlayer(
          userId: user.uid,
          userName: user.displayName ?? 'Ben',
          profileImage: user.photoURL,
          isReserve: false,
        ),
      );
    }
  }

  // Adım ileri
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      if (_validateCurrentStep()) {
        currentStep.value++;
      }
    } else {
      // Son adım, maçı oluştur
      createMatch();
    }
  }

  // Adım geri
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  // Mevcut adımı doğrula
  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0: // Spor seçimi
        if (selectedSport.value == null) {
          Get.snackbar('Hata', 'Lütfen bir spor seçin');
          return false;
        }
        if (selectedMatchType.value == null) {
          Get.snackbar('Hata', 'Lütfen maç türünü seçin');
          return false;
        }
        return true;

      case 1: // Maç detayları
        if (selectedDateTime.value == null) {
          Get.snackbar('Hata', 'Lütfen tarih ve saat seçin');
          return false;
        }
        if (selectedDateTime.value!.isBefore(DateTime.now())) {
          Get.snackbar('Hata', 'Geçmiş bir tarih seçemezsiniz');
          return false;
        }
        if (selectedMatchType.value == MatchType.team &&
            maxPlayersPerTeam.value == null) {
          Get.snackbar('Hata', 'Takım başına oyuncu sayısı belirtin');
          return false;
        }
        return true;

      case 2: // Konum
        if (selectedLocation.value == null) {
          Get.snackbar('Hata', 'Lütfen maç konumu seçin');
          return false;
        }
        return true;

      case 3: // Oyuncu/Takım
        // Eğer "Rakip Arıyor" işaretliyse, oyuncu seçmeden geçebilir
        if (lookingForOpponent.value) {
          return true;
        }

        // Eğer "Rakip Arıyor" işaretli değilse, oyuncu gerekli
        if (selectedMatchType.value == MatchType.individual &&
            team2Players.isEmpty) {
          Get.snackbar(
            'Hata',
            'Lütfen en az bir rakip ekleyin veya "Rakip Arıyor" işaretleyin',
          );
          return false;
        }
        return true;

      case 4: // Ek bilgiler (opsiyonel)
        return true;

      default:
        return true;
    }
  }

  // Spor seç
  void selectSport(String sport, MatchType type) {
    selectedSport.value = sport;
    selectedMatchType.value = type;

    // Spor türüne göre varsayılan değerleri ayarla
    if (type == MatchType.team) {
      // Takım sporları için varsayılan oyuncu sayısı
      if (sport == 'Futbol') {
        maxPlayersPerTeam.value = 11;
      } else if (sport == 'Basketbol') {
        maxPlayersPerTeam.value = 5;
      } else if (sport == 'Voleybol') {
        maxPlayersPerTeam.value = 6;
      }
    } else {
      maxPlayersPerTeam.value = 1;
    }
  }

  // Oyuncu ekle/çıkar
  void addPlayerToTeam1(TeamPlayer player) {
    if (maxPlayersPerTeam.value != null &&
        team1Players.length >= maxPlayersPerTeam.value!) {
      Get.snackbar('Uyarı', 'Takım dolu');
      return;
    }
    team1Players.add(player);
  }

  void addPlayerToTeam2(TeamPlayer player) {
    if (maxPlayersPerTeam.value != null &&
        team2Players.length >= maxPlayersPerTeam.value!) {
      Get.snackbar('Uyarı', 'Takım dolu');
      return;
    }
    team2Players.add(player);
  }

  void removePlayerFromTeam1(String userId) {
    team1Players.removeWhere((p) => p.userId == userId);
  }

  void removePlayerFromTeam2(String userId) {
    team2Players.removeWhere((p) => p.userId == userId);
  }

  // Maç oluştur
  Future<void> createMatch() async {
    if (!_validateCurrentStep()) return;

    isCreating.value = true;

    try {
      final match = Match(
        id: '', // Firestore otomatik oluşturacak
        createdBy: _authController.user.value!.uid,
        sportType: selectedSport.value!,
        matchType: selectedMatchType.value!,
        level: selectedLevel.value,
        mode: selectedMode.value,
        dateTime: selectedDateTime.value!,
        durationMinutes: durationMinutes.value,
        location: MatchLocation(
          latitude: selectedLocation.value!.latitude,
          longitude: selectedLocation.value!.longitude,
          address: selectedLocation.value!.address,
          venueName: selectedLocation.value!.venueName,
          isIndoor: selectedLocation.value!.isIndoor,
          city: () {
            final city = _extractCityFromAddress(
              selectedLocation.value!.address,
            );
            debugPrint('🏙️ Extracted city from address: $city');
            debugPrint('   Address: ${selectedLocation.value!.address}');
            return city;
          }(),
        ),
        team1Players: team1Players.toList(),
        team2Players: team2Players.toList(),
        maxPlayersPerTeam: maxPlayersPerTeam.value,
        genderPreference: genderPreference.value,
        minAge: minAge.value,
        maxAge: maxAge.value,
        costPerPerson: costPerPerson.value,
        notes: notes.value.isEmpty ? null : notes.value,
        isRecurring: isRecurring.value,
        recurringPattern: recurringPattern.value,
        status: 'pending',
        createdAt: DateTime.now(),
        lookingForOpponent: lookingForOpponent.value,
        requiredOpponentCount: requiredOpponentCount.value,
      );

      // Maçı oluştur ve ID'sini al
      final matchId = await _firestoreService.createMatch(match);

      // Team2'deki oyunculara maç daveti notification'ı gönder
      if (team2Players.isNotEmpty) {
        for (final player in team2Players) {
          try {
            await notificationController.sendMatchInviteNotification(
              toUserId: player.userId,
              matchId: matchId,
              sportType: selectedSport.value!,
              matchDate: selectedDateTime.value!,
            );
            debugPrint('Match invite notification sent to ${player.userId}');
          } catch (e) {
            debugPrint('Failed to send notification to ${player.userId}: $e');
          }
        }
        debugPrint('Sent match invites to ${team2Players.length} players');
      }

      Get.back(); // Form ekranını kapat
      Get.snackbar(
        'Başarılı',
        team2Players.isEmpty
            ? 'Maç başarıyla oluşturuldu!'
            : 'Maç oluşturuldu ve ${team2Players.length} oyuncuya davet gönderildi!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Create match error: $e');
      Get.snackbar(
        'Hata',
        'Maç oluşturulurken bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCreating.value = false;
    }
  }

  // Progress yüzdesi
  double get progress => (currentStep.value + 1) / totalSteps;

  // Adım başlığı
  String get currentStepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Spor Seçimi';
      case 1:
        return 'Maç Detayları';
      case 2:
        return 'Konum';
      case 3:
        return 'Oyuncular';
      case 4:
        return 'Ek Bilgiler';
      default:
        return '';
    }
  }

  // Reset
  // Extract city name from Google Maps address
  String? _extractCityFromAddress(String address) {
    try {
      // Address format: "Venue, District, City, Country"
      // Examples:
      // "Çankaya, Ankara, Turkey"
      // "Kadıköy, İstanbul"
      // "Beşiktaş, Istanbul, Türkiye"

      final parts = address.split(',').map((e) => e.trim()).toList();

      if (parts.isEmpty) return null;

      // If last part is country, take the one before it
      final lastPart = parts.last.toLowerCase();
      if (lastPart.contains('turkey') || lastPart.contains('türkiye')) {
        if (parts.length >= 2) {
          return parts[parts.length - 2];
        }
      }

      // Otherwise, take the second-to-last part (usually the city)
      if (parts.length >= 2) {
        return parts[parts.length - 2];
      }

      // Fallback: take the last part
      return parts.last;
    } catch (e) {
      debugPrint('⚠️ Error extracting city from address: $e');
      return null;
    }
  }

  void reset() {
    currentStep.value = 0;
    selectedSport.value = null;
    selectedMatchType.value = null;
    selectedLevel.value = MatchLevel.intermediate;
    selectedMode.value = MatchMode.friendly;
    selectedDateTime.value = null;
    durationMinutes.value = 60;
    maxPlayersPerTeam.value = null;
    selectedLocation.value = null;
    isIndoor.value = false;
    venueName.value = '';
    team1Players.clear();
    team2Players.clear();
    genderPreference.value = GenderPreference.any;
    minAge.value = null;
    maxAge.value = null;
    costPerPerson.value = null;
    notes.value = '';
    isRecurring.value = false;
    recurringPattern.value = null;
    _addCurrentUserToTeam1();
  }
}
