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
