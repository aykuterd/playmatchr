const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Bir maçın sonucu 'confirmed' olarak güncellendiğinde tetiklenir.
 * ELO, Sportmenlik, Güvenilirlik ve diğer tüm istatistikleri günceller.
 */
exports.updatePlayerStatsOnMatchConfirmed = onDocumentUpdated("matches/{matchId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const matchId = event.params.matchId;

  // Fonksiyonun sadece maç sonucu ilk kez 'confirmed' olduğunda çalışmasını sağla
  if (beforeData.resultStatus === "confirmed" || afterData.resultStatus !== "confirmed") {
    return null;
  }

  logger.log(`Match ${matchId} confirmed. Processing all player stats.`);

  const allPlayers = [...afterData.team1Players, ...afterData.team2Players];
  const playerIds = allPlayers.map((p) => p.userId);

  // Tüm katılımcıların profillerini tek seferde çek
  const playerDocs = await Promise.all(
      playerIds.map((id) => db.collection("users").doc(id).get()),
  );

  const batch = db.batch();

  // Her oyuncu için yapılacak güncellemeleri tutan bir harita
  const playerUpdates = new Map();
  playerDocs.forEach((doc) => {
    if (doc.exists) {
      playerUpdates.set(doc.id, {...doc.data()});
    }
  });

  // --- 1. Sportmenlik ve Güvenilirlik Puanlarını İşle ---
  if (afterData.playerRatings && afterData.playerRatings.length > 0) {
    afterData.playerRatings.forEach((rating) => {
      const ratedUserId = rating.ratedUserId;
      const ratedPlayerProfile = playerUpdates.get(ratedUserId);

      if (ratedPlayerProfile) {
        // Güvenilirlik (noShows) güncellemesi
        if (rating.punctuality === "gelmedi") {
          ratedPlayerProfile.noShows = (ratedPlayerProfile.noShows || 0) + 1;
        }

        // Sportmenlik puanı güncellemesi (yeni ortalama hesaplama)
        const currentScore = ratedPlayerProfile.sportsmanshipScore || 5.0;
        const totalMatches = ratedPlayerProfile.totalMatchesPlayed || 0;
        const newRating = rating.sportsmanship;

        // Yeni ortalamayı hesapla
        const newAverageScore = ((currentScore * totalMatches) + newRating) / (totalMatches + 1);
        ratedPlayerProfile.sportsmanshipScore = parseFloat(newAverageScore.toFixed(2)); // 2 ondalık basamağa yuvarla
      }
    });
  }

  // --- 2. Maç Sonu İstatistiklerini ve ELO'yu İşle ---
  const winnerTeam = afterData.winner;

  // Önce tüm oyuncuların oynadığı maç sayısını artır
  playerIds.forEach((id) => {
    const player = playerUpdates.get(id);
    if (player) {
      player.totalMatchesPlayed = (player.totalMatchesPlayed || 0) + 1;
    }
  });

  // Eğer berabere değilse, ELO ve Galibiyet/Mağlubiyet güncelle
  if (winnerTeam && winnerTeam !== "draw" && afterData.team1Players.length === 1 && afterData.team2Players.length === 1) {
    const winnerId = (winnerTeam === "team1") ? afterData.team1Players[0].userId : afterData.team2Players[0].userId;
    const loserId = (winnerTeam === "team1") ? afterData.team2Players[0].userId : afterData.team1Players[0].userId;

    const winnerProfile = playerUpdates.get(winnerId);
    const loserProfile = playerUpdates.get(loserId);

    if (winnerProfile && loserProfile) {
      // Galibiyet/Mağlubiyet sayılarını güncelle
      winnerProfile.matchesWon = (winnerProfile.matchesWon || 0) + 1;
      loserProfile.matchesLost = (loserProfile.matchesLost || 0) + 1;

      // ELO Hesaplaması
      const kFactor = 32;
      const winnerElo = winnerProfile.eloRating || 1200;
      const loserElo = loserProfile.eloRating || 1200;

      const expectedWinnerScore = 1 / (1 + Math.pow(10, (loserElo - winnerElo) / 400));
      const expectedLoserScore = 1 / (1 + Math.pow(10, (winnerElo - loserElo) / 400));

      winnerProfile.eloRating = Math.round(winnerElo + kFactor * (1 - expectedWinnerScore));
      loserProfile.eloRating = Math.round(loserElo + kFactor * (0 - expectedLoserScore));

      logger.log(`ELO updated for ${winnerId} and ${loserId}`);
    }
  } else {
    logger.log("Match is a draw or not 1v1. Skipping ELO update.");
  }

  // --- 3. Tüm Güncellemeleri Veritabanına Yaz ---
  playerUpdates.forEach((updatedProfile, userId) => {
    const userDocRef = db.collection("users").doc(userId);
    batch.update(userDocRef, updatedProfile);
  });

  try {
    await batch.commit();
    logger.log(`Successfully updated stats for all ${playerIds.length} players in match ${matchId}.`);
  } catch (error) {
    logger.error("Error committing batch updates for player stats:", error);
  }

  return null;
});

// --- TOURNAMENT FUNCTIONS ---

const {onDocumentCreated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

/**
 * Bir turnuvaya yeni bir kayıt eklendiğinde veya silindiğinde
 * ana turnuva belgesindeki participantCount'ı günceller.
 */
exports.onTournamentRegistrationChange = onDocumentCreated("tournaments/{tournamentId}/registrations/{userId}", async (event) => {
  const tournamentRef = db.collection("tournaments").doc(event.params.tournamentId);
  try {
    await tournamentRef.update({
      participantCount: admin.firestore.FieldValue.increment(1),
    });
    logger.log(`Incremented participant count for tournament ${event.params.tournamentId}`);
  } catch (error) {
    logger.error("Failed to increment participant count:", error);
  }
});

exports.onTournamentRegistrationDelete = onDocumentDeleted("tournaments/{tournamentId}/registrations/{userId}", async (event) => {
  const tournamentRef = db.collection("tournaments").doc(event.params.tournamentId);
  try {
    await tournamentRef.update({
      participantCount: admin.firestore.FieldValue.increment(-1),
    });
    logger.log(`Decremented participant count for tournament ${event.params.tournamentId}`);
  } catch (error) {
    logger.error("Failed to decrement participant count:", error);
  }
});


/**
 * Bir maç sonucu 'confirmed' olarak güncellendiğinde, kazananı bir sonraki
 * tura ilerletir.
 */
exports.advanceWinner = onDocumentUpdated("tournaments/{tournamentId}/matches/{matchId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const {tournamentId, matchId} = event.params;

  // Sadece maç sonucu ilk kez 'confirmed' olduğunda çalış
  if (beforeData.resultStatus === "confirmed" || afterData.resultStatus !== "confirmed") {
    logger.log(`Match ${matchId} status did not change to confirmed. Skipping advanceWinner.`);
    return null;
  }

  const winnerId = afterData.winnerId;
  const nextMatchId = afterData.nextMatchId;

  // Kazanan veya sonraki maç yoksa işlemi bitir
  if (!winnerId || !nextMatchId) {
    logger.log(`Match ${matchId} has no winner or next match. Nothing to advance.`);
    return null;
  }

  logger.log(`Advancing winner ${winnerId} from match ${matchId} to next match ${nextMatchId}.`);

  const nextMatchRef = db.collection("tournaments").doc(tournamentId).collection("matches").doc(nextMatchId);

  try {
    await db.runTransaction(async (transaction) => {
      const nextMatchDoc = await transaction.get(nextMatchRef);
      if (!nextMatchDoc.exists) {
        throw new Error(`Next match ${nextMatchId} not found!`);
      }

      const nextMatchData = nextMatchDoc.data();
      const updateData = {};

      // Kazananı boş olan ilk oyuncu slotuna yerleştir
      if (!nextMatchData.player1Id) {
        updateData.player1Id = winnerId;
      } else if (!nextMatchData.player2Id) {
        updateData.player2Id = winnerId;
      } else {
        // Bu durum normalde olmamalı, ama olursa logla ve çık
        logger.warn(`Next match ${nextMatchId} already has two players.`);
        return;
      }

      // Eğer bu güncellemeyle birlikte her iki oyuncu da belli olduysa,
      // maçın durumunu 'scheduled' yap.
      const player1Exists = nextMatchData.player1Id || updateData.player1Id;
      const player2Exists = nextMatchData.player2Id || updateData.player2Id;

      if (player1Exists && player2Exists) {
        updateData.status = "scheduled";
        logger.log(`Match ${nextMatchId} is now scheduled between ${player1Exists} and ${player2Exists}.`);
      }

      transaction.update(nextMatchRef, updateData);
    });
    logger.log("Successfully advanced winner.");
  } catch (error) {
    logger.error(`Error advancing winner for match ${matchId}:`, error);
  }
  return null;
});


/**
 * HTTP ile çağrılarak bir turnuvanın fikstürünü (bracket) oluşturur.
 * Sadece turnuva organizatörü veya adminleri tarafından çağrılabilir.
 */
exports.generateBracket = onCall(async (request) => {
  const tournamentId = request.data.tournamentId;
  const uid = request.auth.uid;

  if (!tournamentId) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'tournamentId'.");
  }
  if (!uid) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const tournamentRef = db.collection("tournaments").doc(tournamentId);
  const tournamentDoc = await tournamentRef.get();

  if (!tournamentDoc.exists) {
    throw new HttpsError("not-found", `Tournament with ID ${tournamentId} not found.`);
  }

  const tournamentData = tournamentDoc.data();

  // Güvenlik: Sadece organizatör veya adminler fikstürü oluşturabilir
  const isAdmin = tournamentData.admins && tournamentData.admins.includes(uid);
  if (tournamentData.organizerId !== uid && !isAdmin) {
    throw new HttpsError("permission-denied", "You do not have permission to generate the bracket for this tournament.");
  }

  // Kayıtları çek
  const registrationsSnapshot = await tournamentRef.collection("registrations").get();
  const participants = registrationsSnapshot.docs.map((doc) => doc.id);

  if (participants.length < 2) {
    throw new HttpsError("failed-precondition", "At least two participants are required to generate a bracket.");
  }

  // Oyuncuları karıştır (basit seeding)
  for (let i = participants.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [participants[i], participants[j]] = [participants[j], participants[i]];
  }

  const batch = db.batch();
  const totalRounds = Math.ceil(Math.log2(participants.length));
  let matchesInCurrentRound = Math.pow(2, totalRounds - 1);
  const totalMatches = participants.length - 1;

  const matchIds = Array.from({length: totalMatches}, (_, i) => db.collection("tmp").doc().id);
  let matchCounter = 0;

  // Tüm tur maçları için placeholder oluştur
  for (let round = 1; round <= totalRounds; round++) {
    const matchesInThisRound = Math.pow(2, totalRounds - round);
    for (let i = 0; i < matchesInThisRound; i++) {
      const matchId = matchIds[matchCounter];
      const nextMatchIndex = Math.floor(matchCounter / 2) + matchesInCurrentRound;
      const nextMatchId = (round < totalRounds) ? matchIds[nextMatchIndex] : null;

      const matchData = {
        tournamentId: tournamentId,
        round: round,
        matchNumberInRound: i + 1,
        status: "pending", // İlk tur maçları hariç hepsi pending
        player1Id: null,
        player2Id: null,
        winnerId: null,
        nextMatchId: nextMatchId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        resultStatus: "no_result",
        resultConfirmedBy: [],
      };
      batch.set(tournamentRef.collection("matches").doc(matchId), matchData);
      matchCounter++;
    }
  }

  // İlk tur maçlarına oyuncuları ata
  let firstRoundMatchIndex = 0;
  for (let i = 0; i < participants.length; i += 2) {
    const matchId = matchIds[firstRoundMatchIndex];
    const updateData = {
      player1Id: participants[i],
      player2Id: (i + 1 < participants.length) ? participants[i+1] : null,
      status: "scheduled",
    };
    // Eğer tek sayıda oyuncu varsa, son oyuncu turu atlar (bye)
    if (!updateData.player2Id) {
      updateData.status = "completed";
      updateData.winnerId = updateData.player1Id;
    }
    batch.update(tournamentRef.collection("matches").doc(matchId), updateData);
    firstRoundMatchIndex++;
  }

  // Turnuva durumunu 'active' yap
  batch.update(tournamentRef, {status: "active"});

  try {
    await batch.commit();
    logger.log(`Bracket generated for tournament ${tournamentId} with ${participants.length} participants.`);
    // Bye olan oyuncuları otomatik olarak ilerlet
    const byeMatches = await tournamentRef.collection("matches")
        .where("round", "==", 1)
        .where("status", "==", "completed")
        .get();

    for (const doc of byeMatches.docs) {
      await exports.advanceWinner({
        params: {tournamentId, matchId: doc.id},
        data: {
          before: {data: () => ({resultStatus: "pending"})},
          after: {data: () => doc.data()},
        },
      });
    }

    return {success: true, message: "Bracket generated successfully."};
  } catch (error) {
    logger.error(`Error generating bracket for tournament ${tournamentId}:`, error);
    throw new HttpsError("internal", "An error occurred while generating the bracket.");
  }
});
