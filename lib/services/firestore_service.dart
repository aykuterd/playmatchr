import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playmatchr/models/firestore_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new match - returns the created match ID
  Future<String> createMatch(Match match) async {
    final docRef = await _db.collection('matches').add(match.toFirestore());
    return docRef.id;
  }

  // Get matches looking for opponents (for discovery feed)
  Stream<List<Match>> getMatchesLookingForOpponents(
      {List<String>? sportTypes, String? city}) {
    Query query = _db
        .collection('matches')
        .where('lookingForOpponent', isEqualTo: true)
        .where('dateTime', isGreaterThan: DateTime.now());

    // Note: We can't use both whereIn and nested field queries together in Firestore
    // So we'll filter sportTypes first in the query, then filter city in memory
    if (sportTypes != null && sportTypes.isNotEmpty) {
      query = query.where('sportType', whereIn: sportTypes);
    }

    return query
        .orderBy('dateTime')
        .limit(100) // Get more results since we'll filter in memory
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final match = Match.fromFirestore(doc);

              // Filter by city if provided (done in memory to avoid Firestore limitations)
              if (city != null && city.isNotEmpty) {
                if (match.location.city == null ||
                    match.location.city!.toLowerCase() != city.toLowerCase()) {
                  return null;
                }
              }

              // Sadece hala slot'u olan maçları göster
              return match.hasAvailableSlots ? match : null;
            } catch (e) {
              debugPrint('❌ Error parsing match ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Match>()
          .take(50) // Limit final results to 50
          .toList();
    });
  }

  // Get a stream of upcoming matches for a user (created or participating)
  Stream<List<Match>> getUpcomingMatches(String userId) {
    debugPrint('🔍 Getting upcoming matches for user: $userId');
    debugPrint('🕐 Current time: ${DateTime.now()}');

    return _db
        .collection('matches')
        .where('dateTime', isGreaterThan: DateTime.now())
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 Total matches from Firestore (future only): ${snapshot.docs.length}');

      final allMatches = snapshot.docs.map((doc) {
        try {
          final match = Match.fromFirestore(doc);
          debugPrint('   📅 Match ${doc.id}: date=${match.dateTime}, sport=${match.sportType}');
          return match;
        } catch (e) {
          debugPrint('❌ Error parsing match ${doc.id}: $e');
          return null;
        }
      }).whereType<Match>().toList();

      final userMatches = allMatches.where((match) {
        final isCreator = match.createdBy == userId;
        final isInTeam1 = match.team1Players.any((p) => p.userId == userId);
        final isInTeam2 = match.team2Players.any((p) => p.userId == userId);

        debugPrint('🎯 Match ${match.id}: creator=$isCreator, team1=$isInTeam1, team2=$isInTeam2');
        debugPrint('   CreatedBy: ${match.createdBy}');
        debugPrint('   Team1 players: ${match.team1Players.map((p) => '${p.userId}(${p.userName})').toList()}');
        debugPrint('   Team2 players: ${match.team2Players.map((p) => '${p.userId}(${p.userName})').toList()}');

        return isCreator || isInTeam1 || isInTeam2;
      }).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      debugPrint('✅ Filtered user matches: ${userMatches.length}');
      if (userMatches.isEmpty) {
        debugPrint('⚠️  No matches found for user $userId. Check:');
        debugPrint('    - Are there any matches with future dates in Firestore?');
        debugPrint('    - Is the user in team1Players or team2Players arrays?');
        debugPrint('    - Is createdBy field set to user ID?');
      }

      return userMatches;
    });
  }

  // Get a stream of past matches for a user
  Stream<List<Match>> getPastMatches(String userId) {
    return _db
        .collection('matches')
        .where('dateTime', isLessThan: DateTime.now())
        .orderBy('dateTime', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromFirestore(doc))
          .where((match) =>
              match.createdBy == userId ||
              match.team1Players.any((p) => p.userId == userId) ||
              match.team2Players.any((p) => p.userId == userId))
          .toList();
    });
  }

  // Get all matches for a user (for homepage)
  Stream<List<Match>> getAllUserMatches(String userId) {
    return _db
        .collection('matches')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromFirestore(doc))
          .where((match) =>
              match.createdBy == userId ||
              match.team1Players.any((p) => p.userId == userId) ||
              match.team2Players.any((p) => p.userId == userId))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  // Get a stream of invitations for a user
  Stream<List<Invitation>> getInvitations(String userId) {
    return _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Invitation.fromFirestore(doc)).toList());
  }

  // Update the status of an invitation
  Future<void> updateInvitationStatus(String invitationId, String status) {
    return _db.collection('invitations').doc(invitationId).update({'status': status});
  }

  // Update the status of a match
  Future<void> updateMatchStatus(String matchId, String status) {
    return _db.collection('matches').doc(matchId).update({'status': status});
  }

  // Get user's friends
  Future<List<UserProfile>> getFriends(String userId) async {
    try {
      // Önce kullanıcının profil bilgisini al
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      UserProfile currentUser = UserProfile.fromFirestore(userDoc);

      if (currentUser.friends.isEmpty) {
        return [];
      }

      // Arkadaş profillerini al
      List<UserProfile> friends = [];
      for (String friendId in currentUser.friends) {
        DocumentSnapshot friendDoc = await _db.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          friends.add(UserProfile.fromFirestore(friendDoc));
        }
      }

      return friends;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfilePhoto(String userId, String photoUrl) async {
    try {
      await _db.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      debugPrint('Error updating user profile photo: $e');
      rethrow;
    }
  }

  Future<void> updateUserCoverPhoto(String userId, String coverPhotoUrl) async {
    try {
      await _db.collection('users').doc(userId).update({
        'coverPhotoUrl': coverPhotoUrl,
      });
    } catch (e) {
      debugPrint('Error updating user cover photo: $e');
      rethrow;
    }
  }

  // Search users by username
  Future<List<UserProfile>> searchUsersByUsername(String query) async {
    try {
      if (query.isEmpty) return [];

      // Firestore'da username field'ında case-insensitive arama
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      // Gönderen kullanıcının sentFriendRequests listesine ekle
      await _db.collection('users').doc(fromUserId).update({
        'sentFriendRequests': FieldValue.arrayUnion([toUserId])
      });

      // Alıcı kullanıcının pendingFriendRequests listesine ekle
      await _db.collection('users').doc(toUserId).update({
        'pendingFriendRequests': FieldValue.arrayUnion([fromUserId])
      });
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    try {
      // İki kullanıcıyı da birbirinin arkadaş listesine ekle
      await _db.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([friendId]),
        'pendingFriendRequests': FieldValue.arrayRemove([friendId])
      });

      await _db.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([userId]),
        'sentFriendRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String userId, String friendId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'pendingFriendRequests': FieldValue.arrayRemove([friendId])
      });

      await _db.collection('users').doc(friendId).update({
        'sentFriendRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'friends': FieldValue.arrayRemove([friendId])
      });

      await _db.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  // Create team
  Future<String> createTeam(Team team) async {
    try {
      DocumentReference docRef = await _db.collection('teams').add(team.toFirestore());

      // Admin kullanıcının myTeams listesine ekle
      await _db.collection('users').doc(team.adminId).update({
        'myTeams': FieldValue.arrayUnion([docRef.id])
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating team: $e');
      rethrow;
    }
  }

  // Get user's teams
  Future<List<Team>> getUserTeams(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('teams')
          .where('memberIds', arrayContains: userId)
          .get();

      return snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user teams: $e');
      return [];
    }
  }

  // Get team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      DocumentSnapshot doc = await _db.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return Team.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting team: $e');
      return null;
    }
  }

  // Add member to team
  Future<void> addTeamMember(String teamId, String userId) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        'memberIds': FieldValue.arrayUnion([userId])
      });

      await _db.collection('users').doc(userId).update({
        'myTeams': FieldValue.arrayUnion([teamId])
      });
    } catch (e) {
      debugPrint('Error adding team member: $e');
      rethrow;
    }
  }

  // Remove member from team
  Future<void> removeTeamMember(String teamId, String userId) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        'memberIds': FieldValue.arrayRemove([userId])
      });

      await _db.collection('users').doc(userId).update({
        'myTeams': FieldValue.arrayRemove([teamId])
      });
    } catch (e) {
      debugPrint('Error removing team member: $e');
      rethrow;
    }
  }

  // Update team
  Future<void> updateTeam(String teamId, Map<String, dynamic> data) async {
    try {
      await _db.collection('teams').doc(teamId).update(data);
    } catch (e) {
      debugPrint('Error updating team: $e');
      rethrow;
    }
  }

  // Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      // Önce takım bilgilerini al
      Team? team = await getTeam(teamId);
      if (team == null) return;

      // Tüm üyelerden takımı çıkar
      for (String memberId in team.memberIds) {
        await _db.collection('users').doc(memberId).update({
          'myTeams': FieldValue.arrayRemove([teamId])
        });
      }

      // Takımı sil
      await _db.collection('teams').doc(teamId).delete();
    } catch (e) {
      debugPrint('Error deleting team: $e');
      rethrow;
    }
  }

  // =============== GROUP METHODS ===============

  /// Create a new group
  Future<String> createGroup(Group group) async {
    try {
      final docRef = await _db.collection('groups').add(group.toFirestore());
      debugPrint('✅ Group created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      rethrow;
    }
  }

  /// Get a single group by ID
  Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _db.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return Group.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting group: $e');
      return null;
    }
  }

  /// Get all public groups (stream)
  Stream<List<Group>> getPublicGroups() {
    return _db
        .collection('groups')
        .where('type', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc))
            .toList());
  }

  /// Get groups by sport
  Stream<List<Group>> getGroupsBySport(String sport) {
    return _db
        .collection('groups')
        .where('sport', isEqualTo: sport)
        .where('type', isEqualTo: 'public')
        .orderBy('memberCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc))
            .toList());
  }

  /// Get user's groups
  Stream<List<Group>> getUserGroups(String userId) {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc))
            .toList());
  }

  /// Search groups by name or tags
  Future<List<Group>> searchGroups(String query) async {
    try {
      // Firestore doesn't support full-text search, so we'll fetch and filter
      final snapshot = await _db
          .collection('groups')
          .where('type', isEqualTo: 'public')
          .limit(50)
          .get();

      final queryLower = query.toLowerCase();

      return snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(queryLower) ||
              group.description.toLowerCase().contains(queryLower) ||
              group.tags.any((tag) => tag.toLowerCase().contains(queryLower)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      return [];
    }
  }

  /// Join a group
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ User $userId joined group $groupId');
    } catch (e) {
      debugPrint('❌ Error joining group: $e');
      rethrow;
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'moderatorIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ User $userId left group $groupId');
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
      rethrow;
    }
  }

  /// Update group
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db.collection('groups').doc(groupId).update(updates);
      debugPrint('✅ Group $groupId updated');
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      rethrow;
    }
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all messages first
      final messagesSnapshot = await _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the group
      await _db.collection('groups').doc(groupId).delete();
      debugPrint('✅ Group $groupId deleted');
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      rethrow;
    }
  }

  // =============== GROUP MESSAGES METHODS ===============

  /// Send a message to a group
  Future<void> sendGroupMessage(GroupMessage message) async {
    try {
      await _db
          .collection('groups')
          .doc(message.groupId)
          .collection('messages')
          .add(message.toFirestore());

      // Update group's last activity
      await _db.collection('groups').doc(message.groupId).update({
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Message sent to group ${message.groupId}');
    } catch (e) {
      debugPrint('❌ Error sending group message: $e');
      rethrow;
    }
  }

  /// Get group messages stream
  Stream<List<GroupMessage>> getGroupMessages(String groupId, {int limit = 50}) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMessage.fromFirestore(doc))
            .toList()
            .reversed
            .toList()); // Reverse to show oldest first
  }

  /// Delete a group message
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
      debugPrint('✅ Message $messageId deleted from group $groupId');
    } catch (e) {
      debugPrint('❌ Error deleting group message: $e');
      rethrow;
    }
  }

  // =============== TOURNAMENT METHODS ===============

  /// Create a new tournament
  Future<String> createTournament(Tournament tournament) async {
    try {
      final docRef = await _db.collection('tournaments').add(tournament.toFirestore());
      debugPrint('✅ Tournament created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating tournament: $e');
      rethrow;
    }
  }

  /// Get a single tournament by ID
  Future<Tournament?> getTournament(String tournamentId) async {
    try {
      final doc = await _db.collection('tournaments').doc(tournamentId).get();
      if (doc.exists) {
        return Tournament.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting tournament: $e');
      return null;
    }
  }

  /// Get all tournaments (stream)
  Stream<List<Tournament>> getAllTournaments() {
    return _db
        .collection('tournaments')
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromFirestore(doc))
            .toList());
  }

  /// Get tournaments by status
  Stream<List<Tournament>> getTournamentsByStatus(TournamentStatus status) {
    return _db
        .collection('tournaments')
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromFirestore(doc))
            .toList());
  }

  /// Get tournaments by sport
  Stream<List<Tournament>> getTournamentsBySport(String sport) {
    return _db
        .collection('tournaments')
        .where('sport', isEqualTo: sport)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromFirestore(doc))
            .toList());
  }

  /// Get tournaments organized by a user
  Stream<List<Tournament>> getTournamentsByOrganizer(String organizerId) {
    return _db
        .collection('tournaments')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromFirestore(doc))
            .toList());
  }

  /// Update tournament
  Future<void> updateTournament(String tournamentId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db.collection('tournaments').doc(tournamentId).update(updates);
      debugPrint('✅ Tournament $tournamentId updated');
    } catch (e) {
      debugPrint('❌ Error updating tournament: $e');
      rethrow;
    }
  }

  /// Delete tournament
  Future<void> deleteTournament(String tournamentId) async {
    try {
      // Delete all registrations
      final registrationsSnapshot = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('registrations')
          .get();
      for (var doc in registrationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all matches
      final matchesSnapshot = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .get();
      for (var doc in matchesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the tournament
      await _db.collection('tournaments').doc(tournamentId).delete();
      debugPrint('✅ Tournament $tournamentId deleted');
    } catch (e) {
      debugPrint('❌ Error deleting tournament: $e');
      rethrow;
    }
  }

  // =============== TOURNAMENT REGISTRATION METHODS ===============

  /// Register a user for a tournament
  Future<void> registerForTournament(String tournamentId, String userId) async {
    try {
      final registration = TournamentRegistration(
        id: userId, // Using userId as document ID
        tournamentId: tournamentId,
        userId: userId,
        registrationDate: DateTime.now(),
        status: RegistrationStatus.confirmed,
      );

      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('registrations')
          .doc(userId)
          .set(registration.toFirestore());

      // Increment participant count
      await _db.collection('tournaments').doc(tournamentId).update({
        'participantCount': FieldValue.increment(1),
      });

      debugPrint('✅ User $userId registered for tournament $tournamentId');
    } catch (e) {
      debugPrint('❌ Error registering for tournament: $e');
      rethrow;
    }
  }

  /// Unregister a user from a tournament
  Future<void> unregisterFromTournament(String tournamentId, String userId) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('registrations')
          .doc(userId)
          .delete();

      // Decrement participant count
      await _db.collection('tournaments').doc(tournamentId).update({
        'participantCount': FieldValue.increment(-1),
      });

      debugPrint('✅ User $userId unregistered from tournament $tournamentId');
    } catch (e) {
      debugPrint('❌ Error unregistering from tournament: $e');
      rethrow;
    }
  }

  /// Get all registrations for a tournament
  Stream<List<TournamentRegistration>> getTournamentRegistrations(String tournamentId) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('registrations')
        .orderBy('registrationDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentRegistration.fromFirestore(doc))
            .toList());
  }

  /// Get a user's registration for a specific tournament
  Future<TournamentRegistration?> getUserTournamentRegistration(
      String tournamentId, String userId) async {
    try {
      final doc = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('registrations')
          .doc(userId)
          .get();

      if (doc.exists) {
        return TournamentRegistration.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user registration: $e');
      return null;
    }
  }

  /// Get all tournaments a user is registered for
  Future<List<Tournament>> getUserRegisteredTournaments(String userId) async {
    try {
      // This requires a collection group query
      // First get all tournaments
      final tournamentsSnapshot = await _db.collection('tournaments').get();

      List<Tournament> registeredTournaments = [];

      for (var tournamentDoc in tournamentsSnapshot.docs) {
        final registrationDoc = await _db
            .collection('tournaments')
            .doc(tournamentDoc.id)
            .collection('registrations')
            .doc(userId)
            .get();

        if (registrationDoc.exists) {
          registeredTournaments.add(Tournament.fromFirestore(tournamentDoc));
        }
      }

      return registeredTournaments;
    } catch (e) {
      debugPrint('❌ Error getting user registered tournaments: $e');
      return [];
    }
  }

  // =============== TOURNAMENT MATCH METHODS ===============

  /// Create a tournament match
  Future<String> createTournamentMatch(TournamentMatch match) async {
    try {
      final docRef = await _db
          .collection('tournaments')
          .doc(match.tournamentId)
          .collection('matches')
          .add(match.toFirestore());

      debugPrint('✅ Tournament match created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating tournament match: $e');
      rethrow;
    }
  }

  /// Get all matches for a tournament
  Stream<List<TournamentMatch>> getTournamentMatches(String tournamentId) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .orderBy('round', descending: false)
        .orderBy('matchNumberInRound', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentMatch.fromFirestore(doc))
            .toList());
  }

  /// Get matches by round
  Stream<List<TournamentMatch>> getTournamentMatchesByRound(
      String tournamentId, int round) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .where('round', isEqualTo: round)
        .orderBy('matchNumberInRound', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentMatch.fromFirestore(doc))
            .toList());
  }

  /// Get a single tournament match
  Future<TournamentMatch?> getTournamentMatch(
      String tournamentId, String matchId) async {
    try {
      final doc = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .get();

      if (doc.exists) {
        return TournamentMatch.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting tournament match: $e');
      return null;
    }
  }

  /// Update tournament match
  Future<void> updateTournamentMatch(
      String tournamentId, String matchId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .update(updates);

      debugPrint('✅ Tournament match $matchId updated');
    } catch (e) {
      debugPrint('❌ Error updating tournament match: $e');
      rethrow;
    }
  }

  /// Delete tournament match
  Future<void> deleteTournamentMatch(String tournamentId, String matchId) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .delete();

      debugPrint('✅ Tournament match $matchId deleted');
    } catch (e) {
      debugPrint('❌ Error deleting tournament match: $e');
      rethrow;
    }
  }

  // =============== TOURNAMENT TEAM METHODS ===============

  /// Takım oluştur
  Future<String> createTournamentTeam(TournamentTeam team) async {
    try {
      final docRef = await _db
          .collection('tournaments')
          .doc(team.tournamentId)
          .collection('teams')
          .add(team.toFirestore());

      debugPrint('✅ Tournament team created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating tournament team: $e');
      rethrow;
    }
  }

  /// Turnuvadaki takımı getir (captainId ile)
  Future<TournamentTeam?> getTournamentTeamByCaptain(
      String tournamentId, String captainId) async {
    try {
      final snapshot = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .where('captainId', isEqualTo: captainId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return TournamentTeam.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Error getting tournament team: $e');
      return null;
    }
  }

  /// Takım ID ile takım bilgisi getir
  Future<TournamentTeam?> getTournamentTeam(
      String tournamentId, String teamId) async {
    try {
      final doc = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .get();

      if (!doc.exists) return null;

      return TournamentTeam.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error getting tournament team: $e');
      return null;
    }
  }

  /// Turnuvadaki tüm takımları getir
  Stream<List<TournamentTeam>> getTournamentTeams(String tournamentId) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('teams')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentTeam.fromFirestore(doc))
            .toList());
  }

  /// Takım güncelle
  Future<void> updateTournamentTeam(
      String tournamentId, String teamId, Map<String, dynamic> updates) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .update(updates);

      debugPrint('✅ Tournament team $teamId updated');
    } catch (e) {
      debugPrint('❌ Error updating tournament team: $e');
      rethrow;
    }
  }

  /// Takım sil
  Future<void> deleteTournamentTeam(String tournamentId, String teamId) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .delete();

      debugPrint('✅ Tournament team $teamId deleted');
    } catch (e) {
      debugPrint('❌ Error deleting tournament team: $e');
      rethrow;
    }
  }

  // ============================================================
  // FAVORITE USERS (Favori Oyuncular)
  // ============================================================

  /// Bir kullanıcıyı favorilere ekle
  Future<void> addUserToFavorites(String userId, String targetUserId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'favoriteUsers': FieldValue.arrayUnion([targetUserId]),
      });
      debugPrint('✅ User $targetUserId added to favorites');
    } catch (e) {
      debugPrint('❌ Error adding user to favorites: $e');
      rethrow;
    }
  }

  /// Bir kullanıcıyı favorilerden çıkar
  Future<void> removeUserFromFavorites(String userId, String targetUserId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'favoriteUsers': FieldValue.arrayRemove([targetUserId]),
      });
      debugPrint('✅ User $targetUserId removed from favorites');
    } catch (e) {
      debugPrint('❌ Error removing user from favorites: $e');
      rethrow;
    }
  }

  /// Favorilerdeki kullanıcıları getir
  Future<List<UserProfile>> getFavoriteUsers(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final favoriteUserIds = List<String>.from(userDoc.data()?['favoriteUsers'] ?? []);

      if (favoriteUserIds.isEmpty) {
        return [];
      }

      final List<UserProfile> favoriteUsers = [];
      for (final favoriteUserId in favoriteUserIds) {
        final profile = await getUserProfile(favoriteUserId);
        if (profile != null) {
          favoriteUsers.add(profile);
        }
      }

      return favoriteUsers;
    } catch (e) {
      debugPrint('❌ Error getting favorite users: $e');
      return [];
    }
  }

  /// Bir kullanıcının favori olup olmadığını kontrol et
  Future<bool> isUserFavorite(String userId, String targetUserId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final favoriteUserIds = List<String>.from(userDoc.data()?['favoriteUsers'] ?? []);
      return favoriteUserIds.contains(targetUserId);
    } catch (e) {
      debugPrint('❌ Error checking if user is favorite: $e');
      return false;
    }
  }

  // ============================================================
  // ACHIEVEMENTS (Rozetler/Başarımlar)
  // ============================================================

  /// Kullanıcıya rozet ekle
  Future<void> addAchievement(String userId, String achievementType) async {
    try {
      await _db.collection('users').doc(userId).update({
        'achievements': FieldValue.arrayUnion([achievementType]),
      });
      debugPrint('✅ Achievement $achievementType added to user $userId');
    } catch (e) {
      debugPrint('❌ Error adding achievement: $e');
      rethrow;
    }
  }

  /// Kullanıcının rozetlerini getir
  Future<List<String>> getUserAchievements(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      return List<String>.from(userDoc.data()?['achievements'] ?? []);
    } catch (e) {
      debugPrint('❌ Error getting user achievements: $e');
      return [];
    }
  }

  /// Kullanıcının bir rozete sahip olup olmadığını kontrol et
  Future<bool> hasAchievement(String userId, String achievementType) async {
    try {
      final achievements = await getUserAchievements(userId);
      return achievements.contains(achievementType);
    } catch (e) {
      debugPrint('❌ Error checking achievement: $e');
      return false;
    }
  }

  // ============================================================
  // MATCH HISTORY (Maç Geçmişi)
  // ============================================================

  /// Kullanıcının turnuva maçlarını getir
  Future<List<TournamentMatch>> getUserTournamentMatches(String userId) async {
    try {
      final List<TournamentMatch> userMatches = [];

      // Tüm turnuvaları al
      final tournamentsSnapshot = await _db.collection('tournaments').get();

      for (final tournamentDoc in tournamentsSnapshot.docs) {
        final tournamentId = tournamentDoc.id;

        // Bu turnuvanın maçlarını al
        final matchesSnapshot = await _db
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .where('status', isEqualTo: 'completed')
            .get();

        for (final matchDoc in matchesSnapshot.docs) {
          final match = TournamentMatch.fromFirestore(matchDoc);

          // Kullanıcı bu maçta oynuyor mu?
          if (match.player1Id == userId || match.player2Id == userId) {
            userMatches.add(match);
          }
        }
      }

      // Tarihe göre sırala (en yeni en başta)
      userMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return userMatches;
    } catch (e) {
      debugPrint('❌ Error getting user tournament matches: $e');
      return [];
    }
  }

  /// Kullanıcının istatistiklerini güncelle ve rozetleri kontrol et
  Future<void> checkAndAwardAchievements(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return;

      final achievements = <String>[];

      // İlk maç
      if (profile.totalMatchesPlayed >= 1 && !profile.achievements.contains('firstMatch')) {
        achievements.add('firstMatch');
      }

      // İlk galibiyet
      if (profile.matchesWon >= 1 && !profile.achievements.contains('firstWin')) {
        achievements.add('firstWin');
      }

      // 5 galibiyet
      if (profile.matchesWon >= 5 && !profile.achievements.contains('fiveWins')) {
        achievements.add('fiveWins');
      }

      // 10 galibiyet
      if (profile.matchesWon >= 10 && !profile.achievements.contains('tenWins')) {
        achievements.add('tenWins');
      }

      // 20 galibiyet
      if (profile.matchesWon >= 20 && !profile.achievements.contains('twentyWins')) {
        achievements.add('twentyWins');
      }

      // 50 maç
      if (profile.totalMatchesPlayed >= 50 && !profile.achievements.contains('fiftyMatches')) {
        achievements.add('fiftyMatches');
      }

      // 100 maç
      if (profile.totalMatchesPlayed >= 100 && !profile.achievements.contains('hundredMatches')) {
        achievements.add('hundredMatches');
      }

      // Rozetleri ekle
      for (final achievement in achievements) {
        await addAchievement(userId, achievement);
      }

      if (achievements.isNotEmpty) {
        debugPrint('✅ Awarded ${achievements.length} new achievements to user $userId');
      }
    } catch (e) {
      debugPrint('❌ Error checking and awarding achievements: $e');
    }
  }

  /// Yakınımdaki kullanıcıları getir (aynı ilçe veya şehir)
  Future<List<UserProfile>> getNearbyUsers({
    required String currentUserId,
    required String city,
    required String district,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 Fetching nearby users for city: $city, district: $district');

      // Önce aynı ilçedeki kullanıcıları getir
      Query query = _db
          .collection('users')
          .where('preferredCity', isEqualTo: city)
          .where('preferredDistrict', isEqualTo: district)
          .limit(limit);

      final districtSnapshot = await query.get();
      final nearbyUsers = <UserProfile>[];

      // İlçedeki kullanıcıları ekle
      for (var doc in districtSnapshot.docs) {
        if (doc.id != currentUserId) {
          // Kendini hariç tut
          try {
            final user = UserProfile.fromFirestore(doc);
            nearbyUsers.add(user);
          } catch (e) {
            debugPrint('❌ Error parsing user ${doc.id}: $e');
          }
        }
      }

      debugPrint('✅ Found ${nearbyUsers.length} users in same district');

      // Eğer yeterli kullanıcı bulunamadıysa, aynı şehirden de getir
      if (nearbyUsers.length < limit) {
        final remainingLimit = limit - nearbyUsers.length;
        final existingIds = nearbyUsers.map((u) => u.uid).toSet();

        Query cityQuery = _db
            .collection('users')
            .where('preferredCity', isEqualTo: city)
            .limit(remainingLimit + 10); // Biraz fazla getir, filtreleyeceğiz

        final citySnapshot = await cityQuery.get();

        for (var doc in citySnapshot.docs) {
          if (doc.id != currentUserId && !existingIds.contains(doc.id)) {
            try {
              final user = UserProfile.fromFirestore(doc);
              // İlçesi farklı olanları ekle
              if (user.preferredDistrict != district) {
                nearbyUsers.add(user);
                if (nearbyUsers.length >= limit) break;
              }
            } catch (e) {
              debugPrint('❌ Error parsing user ${doc.id}: $e');
            }
          }
        }

        debugPrint('✅ Total ${nearbyUsers.length} nearby users found');
      }

      // Son görülme zamanına göre sırala (aktif olanlar önce)
      nearbyUsers.sort((a, b) {
        if (a.lastSeen == null && b.lastSeen == null) return 0;
        if (a.lastSeen == null) return 1;
        if (b.lastSeen == null) return -1;
        return b.lastSeen!.compareTo(a.lastSeen!); // En son görülenler önce
      });

      return nearbyUsers;
    } catch (e) {
      debugPrint('❌ Error fetching nearby users: $e');
      return [];
    }
  }
}
