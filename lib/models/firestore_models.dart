import 'package:cloud_firestore/cloud_firestore.dart';

/// Maç türü enum'u
enum MatchType {
  individual, // 1v1 maçlar (Tenis, Badminton vb.)
  team, // Takım maçları (Futbol, Basketbol, Voleybol vb.)
}

/// Maç seviyesi
enum MatchLevel {
  beginner, // Başlangıç
  intermediate, // Orta
  advanced, // İleri
  professional, // Profesyonel
}

/// Maç tipi (puanlı/dostane)
enum MatchMode {
  friendly, // Dostane
  competitive, // Puanlı/Rekabetçi
}

/// Cinsiyet tercihi
enum GenderPreference {
  male, // Erkek
  female, // Kadın
  mixed, // Karma
  any, // Farketmez
}

/// Konum bilgisi
class MatchLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? venueName; // Tesis adı (opsiyonel)
  final bool isIndoor; // Kapalı/Açık alan

  MatchLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.venueName,
    required this.isIndoor,
  });

  factory MatchLocation.fromMap(Map<String, dynamic> data) {
    return MatchLocation(
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      address: data['address'] ?? '',
      city: data['city'],
      venueName: data['venueName'],
      isIndoor: data['isIndoor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'venueName': venueName,
      'isIndoor': isIndoor,
    };
  }
}

/// Takım/Oyuncu bilgisi
class TeamPlayer {
  final String userId;
  final String userName;
  final String? profileImage;
  final bool isReserve; // Yedek oyuncu mu?

  TeamPlayer({
    required this.userId,
    required this.userName,
    this.profileImage,
    this.isReserve = false,
  });

  factory TeamPlayer.fromMap(Map<String, dynamic> data) {
    return TeamPlayer(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      profileImage: data['profileImage'],
      isReserve: data['isReserve'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'profileImage': profileImage,
      'isReserve': isReserve,
    };
  }
}

/// Gelişmiş Match modeli
class Match {
  final String id;
  final String createdBy;
  final String sportType; // Tenis, Futbol, Basketbol vb.
  final MatchType matchType; // individual veya team
  final MatchLevel level;
  final MatchMode mode;

  // Tarih ve süre
  final DateTime dateTime;
  final int durationMinutes; // Maç süresi (dakika)

  // Konum
  final MatchLocation location;

  // Oyuncular
  final List<TeamPlayer> team1Players; // Ev sahibi takım/oyuncu
  final List<TeamPlayer> team2Players; // Rakip takım/oyuncu
  final int? maxPlayersPerTeam; // Takım başına max oyuncu (null ise sınırsız)

  // Ek bilgiler
  final GenderPreference genderPreference;
  final int? minAge; // Minimum yaş
  final int? maxAge; // Maximum yaş
  final double? costPerPerson; // Kişi başı maliyet (TL)
  final String? notes; // Ek notlar

  // Tekrarlama
  final bool isRecurring; // Tekrarlayan maç mı?
  final String? recurringPattern; // weekly, biweekly, monthly

  // Durum
  final String status; // pending, confirmed, cancelled, completed, finished
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Rakip Arama Sistemi
  final bool lookingForOpponent; // Rakip arıyor mu?
  final int? requiredOpponentCount; // Kaç rakip arıyor (null ise sınırsız)

  // Maç Sonucu ve Onay Sistemi
  final String? resultSubmittedBy; // Sonucu ilk giren kullanıcı ID
  final DateTime? resultSubmittedAt; // Sonuç girilme zamanı
  final String? winner; // 'team1', 'team2', 'draw', null
  final Map<String, dynamic>? score; // Skor bilgisi (sport-specific)
  final List<String> resultConfirmedBy; // Sonucu onaylayan kullanıcılar
  final String resultStatus; // no_result, pending_confirmation, confirmed, disputed
  final String? disputeReason; // Anlaşmazlık nedeni
  final DateTime? resultConfirmationDeadline; // Onay için son tarih
  final List<Map<String, dynamic>> playerRatings; // Oyuncu puanlamaları

  Match({
    required this.id,
    required this.createdBy,
    required this.sportType,
    required this.matchType,
    required this.level,
    required this.mode,
    required this.dateTime,
    required this.durationMinutes,
    required this.location,
    required this.team1Players,
    required this.team2Players,
    this.maxPlayersPerTeam,
    required this.genderPreference,
    this.minAge,
    this.maxAge,
    this.costPerPerson,
    this.notes,
    this.isRecurring = false,
    this.recurringPattern,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.lookingForOpponent = false,
    this.requiredOpponentCount,
    this.resultSubmittedBy,
    this.resultSubmittedAt,
    this.winner,
    this.score,
    this.resultConfirmedBy = const [],
    this.resultStatus = 'no_result',
    this.disputeReason,
    this.resultConfirmationDeadline,
    this.playerRatings = const [],
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      createdBy: data['createdBy'] ?? '',
      sportType: data['sportType'] ?? '',
      matchType: MatchType.values.firstWhere(
        (e) => e.toString() == 'MatchType.${data['matchType']}',
        orElse: () => MatchType.individual,
      ),
      level: MatchLevel.values.firstWhere(
        (e) => e.toString() == 'MatchLevel.${data['level']}',
        orElse: () => MatchLevel.intermediate,
      ),
      mode: MatchMode.values.firstWhere(
        (e) => e.toString() == 'MatchMode.${data['mode']}',
        orElse: () => MatchMode.friendly,
      ),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
      location: MatchLocation.fromMap(data['location'] ?? {}),
      team1Players: (data['team1Players'] as List?)
              ?.map((p) => TeamPlayer.fromMap(p))
              .toList() ??
          [],
      team2Players: (data['team2Players'] as List?)
              ?.map((p) => TeamPlayer.fromMap(p))
              .toList() ??
          [],
      maxPlayersPerTeam: data['maxPlayersPerTeam'],
      genderPreference: GenderPreference.values.firstWhere(
        (e) => e.toString() == 'GenderPreference.${data['genderPreference']}',
        orElse: () => GenderPreference.any,
      ),
      minAge: data['minAge'],
      maxAge: data['maxAge'],
      costPerPerson: data['costPerPerson']?.toDouble(),
      notes: data['notes'],
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      lookingForOpponent: data['lookingForOpponent'] ?? false,
      requiredOpponentCount: data['requiredOpponentCount'],
      resultSubmittedBy: data['resultSubmittedBy'],
      resultSubmittedAt: data['resultSubmittedAt'] != null
          ? (data['resultSubmittedAt'] as Timestamp).toDate()
          : null,
      winner: data['winner'],
      score: data['score'] != null
          ? Map<String, dynamic>.from(data['score'])
          : null,
      resultConfirmedBy: data['resultConfirmedBy'] != null
          ? List<String>.from(data['resultConfirmedBy'])
          : [],
      resultStatus: data['resultStatus'] ?? 'no_result',
      disputeReason: data['disputeReason'],
      resultConfirmationDeadline: data['resultConfirmationDeadline'] != null
          ? (data['resultConfirmationDeadline'] as Timestamp).toDate()
          : null,
      playerRatings: data['playerRatings'] != null
          ? List<Map<String, dynamic>>.from(data['playerRatings'])
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    // Tüm katılımcıların user ID'lerini topla (Rules için)
    final participantUserIds = <String>{
      ...team1Players.map((p) => p.userId),
      ...team2Players.map((p) => p.userId),
    }.toList();

    return {
      'createdBy': createdBy,
      'sportType': sportType,
      'matchType': matchType.toString().split('.').last,
      'level': level.toString().split('.').last,
      'mode': mode.toString().split('.').last,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'location': location.toMap(),
      'team1Players': team1Players.map((p) => p.toMap()).toList(),
      'team2Players': team2Players.map((p) => p.toMap()).toList(),
      'participantUserIds': participantUserIds, // Security Rules için
      'maxPlayersPerTeam': maxPlayersPerTeam,
      'genderPreference': genderPreference.toString().split('.').last,
      'minAge': minAge,
      'maxAge': maxAge,
      'costPerPerson': costPerPerson,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lookingForOpponent': lookingForOpponent,
      'requiredOpponentCount': requiredOpponentCount,
      'resultSubmittedBy': resultSubmittedBy,
      'resultSubmittedAt': resultSubmittedAt != null
          ? Timestamp.fromDate(resultSubmittedAt!)
          : null,
      'winner': winner,
      'score': score,
      'resultConfirmedBy': resultConfirmedBy,
      'resultStatus': resultStatus,
      'disputeReason': disputeReason,
      'resultConfirmationDeadline': resultConfirmationDeadline != null
          ? Timestamp.fromDate(resultConfirmationDeadline!)
          : null,
      'playerRatings': playerRatings,
    };
  }

  // Helper metodlar
  bool get isTeamMatch => matchType == MatchType.team;
  bool get isIndividualMatch => matchType == MatchType.individual;
  bool get isFull =>
      maxPlayersPerTeam != null &&
      (team1Players.length >= maxPlayersPerTeam! ||
          team2Players.length >= maxPlayersPerTeam!);
  int get remainingSlots =>
      maxPlayersPerTeam != null
          ? (maxPlayersPerTeam! * 2) -
              (team1Players.length + team2Players.length)
          : 999;

  // Rakip arama helper'ları
  bool get hasAvailableSlots {
    if (!lookingForOpponent) return false;
    if (requiredOpponentCount == null) return true;
    final currentOpponents = team2Players.length;
    return currentOpponents < requiredOpponentCount!;
  }

  int get availableOpponentSlots {
    if (!lookingForOpponent) return 0;
    if (requiredOpponentCount == null) return 999;
    return requiredOpponentCount! - team2Players.length;
  }
}

class Invitation {
  final String id;
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String status; // pending, accepted, declined

  Invitation({
    required this.id,
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
  });

  factory Invitation.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Invitation(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status,
    };
  }
}

/// Kullanıcı profil modeli
class UserProfile {
  final String uid;
  final String username; // Unique kullanıcı adı (Instagram gibi)
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? coverPhotoUrl; // Kapak fotoğrafı
  final String? bio; // Kısa biyografi
  final List<String> friends; // Arkadaş user ID'leri
  final List<String> pendingFriendRequests; // Gelen arkadaşlık istekleri
  final List<String> sentFriendRequests; // Gönderilen arkadaşlık istekleri
  final List<String> favoriteSports; // Favori sporlar
  final List<String> myTeams; // Üye olduğu takım ID'leri
  final List<String> favoriteUsers; // Favori oyuncular (tek yönlü)
  final List<String> achievements; // Kazanılan rozetler/başarımlar
  final DateTime createdAt;

  // Player Stats & Ratings
  final int eloRating;
  final int totalMatchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int noShows;
  final double sportsmanshipScore; // Ortalama sportmenlik puanı

  // Kullanıcı Tercihleri - Rakip Bulma için
  final List<String> preferredSports; // Tercih edilen spor dalları
  final String? preferredCity; // Tercih edilen şehir
  final String? preferredDistrict; // Tercih edilen ilçe
  final DateTime? lastSeen; // Son görülme zamanı

  UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.coverPhotoUrl,
    this.bio,
    required this.friends,
    required this.pendingFriendRequests,
    required this.sentFriendRequests,
    required this.favoriteSports,
    required this.myTeams,
    required this.favoriteUsers,
    required this.achievements,
    required this.createdAt,
    this.eloRating = 1200,
    this.totalMatchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.noShows = 0,
    this.sportsmanshipScore = 5.0,
    this.preferredSports = const [],
    this.preferredCity,
    this.preferredDistrict,
    this.lastSeen,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle both 'name' and 'displayName' fields
    final displayName = data['displayName'] ?? data['name'] ?? data['email']?.split('@')[0] ?? 'Kullanıcı';

    // Handle username - create from email if not exists
    var username = data['username'] ?? '';
    if (username.isEmpty) {
      final email = data['email'] ?? '';
      username = email.isNotEmpty ? email.split('@')[0].toLowerCase() : 'user_${doc.id.substring(0, 8)}';
    }

    return UserProfile(
      uid: doc.id,
      username: username,
      displayName: displayName,
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      coverPhotoUrl: data['coverPhotoUrl'],
      bio: data['bio'],
      friends: List<String>.from(data['friends'] ?? []),
      pendingFriendRequests: List<String>.from(data['pendingFriendRequests'] ?? []),
      sentFriendRequests: List<String>.from(data['sentFriendRequests'] ?? []),
      favoriteSports: List<String>.from(data['favoriteSports'] ?? []),
      myTeams: List<String>.from(data['myTeams'] ?? []),
      favoriteUsers: List<String>.from(data['favoriteUsers'] ?? []),
      achievements: List<String>.from(data['achievements'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      eloRating: data['eloRating'] ?? 1200,
      totalMatchesPlayed: data['totalMatchesPlayed'] ?? 0,
      matchesWon: data['matchesWon'] ?? 0,
      matchesLost: data['matchesLost'] ?? 0,
      noShows: data['noShows'] ?? 0,
      sportsmanshipScore: (data['sportsmanshipScore'] ?? 5.0).toDouble(),
      preferredSports: List<String>.from(data['preferredSports'] ?? []),
      preferredCity: data['preferredCity'],
      preferredDistrict: data['preferredDistrict'],
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'bio': bio,
      'friends': friends,
      'pendingFriendRequests': pendingFriendRequests,
      'sentFriendRequests': sentFriendRequests,
      'favoriteSports': favoriteSports,
      'myTeams': myTeams,
      'favoriteUsers': favoriteUsers,
      'achievements': achievements,
      'createdAt': Timestamp.fromDate(createdAt),
      'eloRating': eloRating,
      'totalMatchesPlayed': totalMatchesPlayed,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'noShows': noShows,
      'sportsmanshipScore': sportsmanshipScore,
      'preferredSports': preferredSports,
      'preferredCity': preferredCity,
      'preferredDistrict': preferredDistrict,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  /// Profil tamamlanma yüzdesini hesapla
  int getProfileCompletionPercentage() {
    int total = 0;

    // Profil fotoğrafı - %20
    if (photoUrl != null && photoUrl!.isNotEmpty) total += 20;

    // Kapak fotoğrafı - %15
    if (coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty) total += 15;

    // Bio - %20
    if (bio != null && bio!.isNotEmpty) total += 20;

    // Şehir - %15
    if (preferredCity != null && preferredCity!.isNotEmpty) total += 15;

    // İlçe - %10
    if (preferredDistrict != null && preferredDistrict!.isNotEmpty) total += 10;

    // En az 1 spor - %20
    if (favoriteSports.isNotEmpty) total += 20;

    return total;
  }

  /// Hangi alanlar eksik?
  List<String> getMissingProfileFields() {
    List<String> missing = [];

    if (photoUrl == null || photoUrl!.isEmpty) missing.add('Profil fotoğrafı');
    if (coverPhotoUrl == null || coverPhotoUrl!.isEmpty) missing.add('Kapak fotoğrafı');
    if (bio == null || bio!.isEmpty) missing.add('Hakkında');
    if (preferredCity == null || preferredCity!.isEmpty) missing.add('Şehir');
    if (preferredDistrict == null || preferredDistrict!.isEmpty) missing.add('İlçe');
    if (favoriteSports.isEmpty) missing.add('Favori spor');

    return missing;
  }
}

/// Takım modeli
class Team {
  final String id;
  final String name; // Takım adı
  final String sport; // Spor dalı
  final String? logoUrl; // Logo URL
  final String? slogan; // Slogan/Motto
  final String adminId; // Takım admini
  final List<String> memberIds; // Takım üyeleri
  final String? description; // Açıklama
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.sport,
    this.logoUrl,
    this.slogan,
    required this.adminId,
    required this.memberIds,
    this.description,
    required this.createdAt,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      sport: data['sport'] ?? '',
      logoUrl: data['logoUrl'],
      slogan: data['slogan'],
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sport': sport,
      'logoUrl': logoUrl,
      'slogan': slogan,
      'adminId': adminId,
      'memberIds': memberIds,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Grup tipi enum
enum GroupType {
  public, // Herkese açık
  private, // Özel (davetiye ile)
}

/// Grup üyelik rolü enum
enum GroupMemberRole {
  admin, // Yönetici
  moderator, // Moderatör
  member, // Üye
}

/// Sosyal Grup/Kulüp modeli
class Group {
  final String id;
  final String name;
  final String description;
  final String? sport; // Opsiyonel - multi-sport gruplar olabilir
  final String adminId;
  final List<String> memberIds;
  final List<String> moderatorIds;
  final GroupType type;
  final String? logoUrl;
  final List<String> tags; // Arama için etiketler
  final String? city; // Şehir
  final String? district; // İlçe
  final int? maxMembers; // Max üye sayısı
  final DateTime createdAt;
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.sport,
    required this.adminId,
    required this.memberIds,
    this.moderatorIds = const [],
    required this.type,
    this.logoUrl,
    this.tags = const [],
    this.city,
    this.district,
    this.maxMembers,
    required this.createdAt,
    this.updatedAt,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sport: data['sport'],
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      type: GroupType.values.firstWhere(
        (e) => e.toString() == 'GroupType.${data['type']}',
        orElse: () => GroupType.public,
      ),
      logoUrl: data['logoUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      city: data['city'],
      district: data['district'],
      maxMembers: data['maxMembers'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'sport': sport,
      'adminId': adminId,
      'memberIds': memberIds,
      'moderatorIds': moderatorIds,
      'type': type.toString().split('.').last,
      'logoUrl': logoUrl,
      'tags': tags,
      'city': city,
      'district': district,
      'maxMembers': maxMembers,
      'memberCount': memberIds.length, // Denormalized for queries
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Helper methods
  bool get isFull => maxMembers != null && memberIds.length >= maxMembers!;
  bool get isAdmin => memberIds.isNotEmpty;
  int get memberCount => memberIds.length;
}

/// Grup mesajı modeli
class GroupMessage {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String message;
  final String type; // text, announcement, system
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.message,
    this.type = 'text',
    required this.createdAt,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhoto: data['userPhoto'],
      message: data['message'] ?? '',
      type: data['type'] ?? 'text',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Bildirim tipi enum
enum NotificationType {
  friendRequest, // Arkadaşlık daveti
  friendAccept, // Arkadaşlık kabul edildi
  matchInvite, // Maç daveti
  teamInvite, // Takım daveti
  matchUpdate, // Maç güncelleme (iptal, tarih değişikliği)
  matchReminder, // Maç hatırlatması
  groupInvite, // Grup daveti
  groupMessage, // Grup mesajı
}

/// Bildirim modeli
class AppNotification {
  final String id;
  final String userId; // Bildirimi alan kullanıcı
  final NotificationType type;
  final String title;
  final String message;
  final String? fromUserId; // Bildirimi gönderen kullanıcı (varsa)
  final String? fromUserName; // Gönderen kullanıcı adı
  final String? fromUserPhoto; // Gönderen profil fotoğrafı
  final String? relatedId; // İlgili maç/takım ID'si
  final Map<String, dynamic>? data; // Ekstra veri
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.fromUserId,
    this.fromUserName,
    this.fromUserPhoto,
    this.relatedId,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.friendRequest,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      fromUserPhoto: data['fromUserPhoto'],
      relatedId: data['relatedId'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhoto': fromUserPhoto,
      'relatedId': relatedId,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper metod
  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      relatedId: relatedId,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

// =============== TOURNAMENT MODELS ===============

/// Turnuva tipi enum
enum TournamentType {
  singleElimination, // Eleme usulü
  roundRobin, // Lig usulü (herkes herkesle)
  league, // Lig sistemi
}

/// Turnuva durumu enum
enum TournamentStatus {
  draft, // Taslak
  registrationOpen, // Kayıtlar açık
  registrationClosed, // Kayıtlar kapandı
  active, // Aktif/Devam ediyor
  completed, // Tamamlandı
  cancelled, // İptal edildi
}

/// Kayıt durumu enum
enum RegistrationStatus {
  pendingPayment, // Ödeme bekliyor
  confirmed, // Onaylandı
  waitlisted, // Yedek listede
}

/// Turnuva maç durumu enum
enum TournamentMatchStatus {
  scheduled, // Planlandı
  inProgress, // Devam ediyor
  completed, // Tamamlandı
  disputed, // Anlaşmazlık var
}

/// Turnuva modeli
class Tournament {
  final String id;
  final String name;
  final String description;
  final String organizerId; // Düzenleyen kullanıcı ID
  final List<String> admins; // Yönetici kullanıcı ID'leri
  final String sport; // Spor dalı
  final TournamentType type;
  final TournamentStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final MatchLocation location;
  final double? entryFee; // Katılım ücreti
  final int maxParticipants;
  final int participantCount;
  final String? bannerImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.organizerId,
    this.admins = const [],
    required this.sport,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.location,
    this.entryFee,
    required this.maxParticipants,
    this.participantCount = 0,
    this.bannerImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      admins: List<String>.from(data['admins'] ?? []),
      sport: data['sport'] ?? '',
      type: TournamentType.values.firstWhere(
        (e) => e.toString() == 'TournamentType.${data['type']}',
        orElse: () => TournamentType.singleElimination,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.toString() == 'TournamentStatus.${data['status']}',
        orElse: () => TournamentStatus.draft,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      location: MatchLocation.fromMap(data['location'] ?? {}),
      entryFee: data['entryFee']?.toDouble(),
      maxParticipants: data['maxParticipants'] ?? 0,
      participantCount: data['participantCount'] ?? 0,
      bannerImageUrl: data['bannerImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'organizerId': organizerId,
      'admins': admins,
      'sport': sport,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location.toMap(),
      'entryFee': entryFee,
      'maxParticipants': maxParticipants,
      'participantCount': participantCount,
      'bannerImageUrl': bannerImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Helper methods
  bool get isFull => participantCount >= maxParticipants;
  bool get canRegister => status == TournamentStatus.registrationOpen && !isFull;
  bool get isUserOrganizer => organizerId.isNotEmpty;
  bool isUserAdmin(String userId) => organizerId == userId || admins.contains(userId);
}

/// Turnuva kayıt modeli
class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String userId;
  final DateTime registrationDate;
  final RegistrationStatus status;
  final int? seed; // Sıralama

  TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.registrationDate,
    required this.status,
    this.seed,
  });

  factory TournamentRegistration.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentRegistration(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      userId: data['userId'] ?? '',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      status: RegistrationStatus.values.firstWhere(
        (e) => e.toString() == 'RegistrationStatus.${data['status']}',
        orElse: () => RegistrationStatus.confirmed,
      ),
      seed: data['seed'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'userId': userId,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'status': status.toString().split('.').last,
      'seed': seed,
    };
  }
}

/// Turnuva maç modeli
class TournamentMatch {
  final String id;
  final String tournamentId;
  final int round; // Hangi tur
  final int matchNumberInRound; // Tur içindeki kaçıncı maç
  final String? player1Id;
  final String? player2Id;
  final Map<String, dynamic>? player1Score; // Set skorları
  final Map<String, dynamic>? player2Score;
  final String? winnerId;
  final TournamentMatchStatus status;
  final String? nextMatchId; // Galip gidecek maç
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Result confirmation fields
  final String? resultSubmittedBy; // Sonucu ilk giren kullanıcı ID
  final DateTime? resultSubmittedAt; // Sonuç girilme zamanı
  final String resultStatus; // 'no_result', 'pending_confirmation', 'confirmed', 'disputed'
  final List<String> resultConfirmedBy; // Sonucu onaylayan kullanıcılar
  final DateTime? resultConfirmationDeadline; // Onay için son tarih
  final String? disputeReason; // Anlaşmazlık nedeni
  final String? disputedBy; // İtiraz eden kullanıcı ID
  final DateTime? disputedAt; // İtiraz zamanı

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.matchNumberInRound,
    this.player1Id,
    this.player2Id,
    this.player1Score,
    this.player2Score,
    this.winnerId,
    required this.status,
    this.nextMatchId,
    this.scheduledDate,
    required this.createdAt,
    this.updatedAt,
    this.resultSubmittedBy,
    this.resultSubmittedAt,
    this.resultStatus = 'no_result',
    this.resultConfirmedBy = const [],
    this.resultConfirmationDeadline,
    this.disputeReason,
    this.disputedBy,
    this.disputedAt,
  });

  factory TournamentMatch.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentMatch(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      round: data['round'] ?? 0,
      matchNumberInRound: data['matchNumberInRound'] ?? 0,
      player1Id: data['player1Id'],
      player2Id: data['player2Id'],
      player1Score: data['player1Score'] != null
          ? Map<String, dynamic>.from(data['player1Score'])
          : null,
      player2Score: data['player2Score'] != null
          ? Map<String, dynamic>.from(data['player2Score'])
          : null,
      winnerId: data['winnerId'],
      status: TournamentMatchStatus.values.firstWhere(
        (e) => e.toString() == 'TournamentMatchStatus.${data['status']}',
        orElse: () => TournamentMatchStatus.scheduled,
      ),
      nextMatchId: data['nextMatchId'],
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      resultSubmittedBy: data['resultSubmittedBy'],
      resultSubmittedAt: data['resultSubmittedAt'] != null
          ? (data['resultSubmittedAt'] as Timestamp).toDate()
          : null,
      resultStatus: data['resultStatus'] ?? 'no_result',
      resultConfirmedBy: data['resultConfirmedBy'] != null
          ? List<String>.from(data['resultConfirmedBy'])
          : [],
      resultConfirmationDeadline: data['resultConfirmationDeadline'] != null
          ? (data['resultConfirmationDeadline'] as Timestamp).toDate()
          : null,
      disputeReason: data['disputeReason'],
      disputedBy: data['disputedBy'],
      disputedAt: data['disputedAt'] != null
          ? (data['disputedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'round': round,
      'matchNumberInRound': matchNumberInRound,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'winnerId': winnerId,
      'status': status.toString().split('.').last,
      'nextMatchId': nextMatchId,
      'scheduledDate': scheduledDate != null
          ? Timestamp.fromDate(scheduledDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resultSubmittedBy': resultSubmittedBy,
      'resultSubmittedAt': resultSubmittedAt != null
          ? Timestamp.fromDate(resultSubmittedAt!)
          : null,
      'resultStatus': resultStatus,
      'resultConfirmedBy': resultConfirmedBy,
      'resultConfirmationDeadline': resultConfirmationDeadline != null
          ? Timestamp.fromDate(resultConfirmationDeadline!)
          : null,
      'disputeReason': disputeReason,
      'disputedBy': disputedBy,
      'disputedAt': disputedAt != null ? Timestamp.fromDate(disputedAt!) : null,
    };
  }

  // Helper methods
  bool get isReady => player1Id != null && player2Id != null;
  bool get isCompleted => status == TournamentMatchStatus.completed;
  bool get hasWinner => winnerId != null;
}

// =============== SPORT CATEGORY HELPERS ===============

/// Sporun bireysel mi takım sporu mu olduğunu belirler
MatchType getSportCategory(String sport) {
  final teamSports = [
    'futbol',
    'football',
    'soccer',
    'halı saha',
    'halısaha',
    'basketbol',
    'basketball',
    'voleybol',
    'volleyball',
  ];

  return teamSports.contains(sport.toLowerCase())
      ? MatchType.team
      : MatchType.individual;
}

/// Sporun önerilen oyuncu sayısını döndürür (takım başına)
int getSuggestedPlayersPerTeam(String sport) {
  switch (sport.toLowerCase()) {
    case 'futbol':
    case 'football':
    case 'soccer':
      return 11;
    case 'halı saha':
    case 'halısaha':
      return 5;
    case 'basketbol':
    case 'basketball':
      return 5;
    case 'voleybol':
    case 'volleyball':
      return 6;
    default:
      return 1; // Bireysel sporlar
  }
}

// =============== TOURNAMENT TEAM MODEL ===============

/// Turnuva takımı modeli
class TournamentTeam {
  final String id;
  final String tournamentId;
  final String teamName;
  final String captainId; // Takım kaptanı (kayıt yaptıran kişi)
  final String? logoUrl; // Takım logosu/flaması
  final String? primaryColor; // Ana renk (hex format: #FF5733)
  final String? secondaryColor; // İkincil renk
  final DateTime createdAt;

  TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.teamName,
    required this.captainId,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    required this.createdAt,
  });

  factory TournamentTeam.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentTeam(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      teamName: data['teamName'] ?? '',
      captainId: data['captainId'] ?? '',
      logoUrl: data['logoUrl'],
      primaryColor: data['primaryColor'],
      secondaryColor: data['secondaryColor'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'teamName': teamName,
      'captainId': captainId,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Rozet/Başarım türleri
enum AchievementType {
  firstMatch, // İlk maç
  firstWin, // İlk galibiyet
  firstTournament, // İlk turnuva katılımı
  tournamentWinner, // Turnuva şampiyonu
  fiveWins, // 5 galibiyet
  tenWins, // 10 galibiyet
  twentyWins, // 20 galibiyet
  fiftyMatches, // 50 maç oynama
  hundredMatches, // 100 maç oynama
  socialButterfly, // 10 farklı kişiyle oynama
  earlyBird, // İlk maçını sabah 8'den önce oynama
  nightOwl, // İlk maçını gece 10'dan sonra oynama
}

/// Rozet/Başarım modeli
class Achievement {
  final AchievementType type;
  final String name;
  final String description;
  final String icon;
  final String color; // Hex renk kodu

  const Achievement({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Tüm mevcut rozetler
class Achievements {
  static const Map<AchievementType, Achievement> all = {
    AchievementType.firstMatch: Achievement(
      type: AchievementType.firstMatch,
      name: 'İlk Adım',
      description: 'İlk maçını oynadın!',
      icon: '🎾',
      color: '#4CAF50',
    ),
    AchievementType.firstWin: Achievement(
      type: AchievementType.firstWin,
      name: 'İlk Zafer',
      description: 'İlk galibiyetini aldın!',
      icon: '🏆',
      color: '#FFD700',
    ),
    AchievementType.firstTournament: Achievement(
      type: AchievementType.firstTournament,
      name: 'Turnuva Oyuncusu',
      description: 'İlk turnuvana katıldın!',
      icon: '🎖️',
      color: '#FF9800',
    ),
    AchievementType.tournamentWinner: Achievement(
      type: AchievementType.tournamentWinner,
      name: 'Şampiyon',
      description: 'Bir turnuvayı kazandın!',
      icon: '👑',
      color: '#9C27B0',
    ),
    AchievementType.fiveWins: Achievement(
      type: AchievementType.fiveWins,
      name: 'Yükselen Yıldız',
      description: '5 maç kazandın!',
      icon: '⭐',
      color: '#2196F3',
    ),
    AchievementType.tenWins: Achievement(
      type: AchievementType.tenWins,
      name: 'Usta Oyuncu',
      description: '10 maç kazandın!',
      icon: '🌟',
      color: '#3F51B5',
    ),
    AchievementType.twentyWins: Achievement(
      type: AchievementType.twentyWins,
      name: 'Efsane',
      description: '20 maç kazandın!',
      icon: '💫',
      color: '#673AB7',
    ),
    AchievementType.fiftyMatches: Achievement(
      type: AchievementType.fiftyMatches,
      name: 'Sadık Oyuncu',
      description: '50 maç oynadın!',
      icon: '🎯',
      color: '#00BCD4',
    ),
    AchievementType.hundredMatches: Achievement(
      type: AchievementType.hundredMatches,
      name: 'Veteran',
      description: '100 maç oynadın!',
      icon: '🔥',
      color: '#F44336',
    ),
    AchievementType.socialButterfly: Achievement(
      type: AchievementType.socialButterfly,
      name: 'Sosyal Kelebek',
      description: '10 farklı kişiyle oynadın!',
      icon: '🦋',
      color: '#E91E63',
    ),
    AchievementType.earlyBird: Achievement(
      type: AchievementType.earlyBird,
      name: 'Erken Kalkan',
      description: 'Sabahın köründe maç oynadın!',
      icon: '🌅',
      color: '#FF5722',
    ),
    AchievementType.nightOwl: Achievement(
      type: AchievementType.nightOwl,
      name: 'Gece Kuşu',
      description: 'Gece geç saatlerde maç oynadın!',
      icon: '🦉',
      color: '#607D8B',
    ),
  };

  /// Rozet string'inden Achievement nesnesine dönüşüm
  static Achievement? fromString(String achievementStr) {
    try {
      final type = AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.$achievementStr',
      );
      return all[type];
    } catch (e) {
      return null;
    }
  }

  /// Achievement type'ından string'e dönüşüm
  static String typeToString(AchievementType type) {
    return type.toString().split('.').last;
  }
}
