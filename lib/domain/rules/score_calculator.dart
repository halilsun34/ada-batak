import '../models/game_settings.dart';
import '../models/player.dart';

/// Tek bir tur sonunda her oyuncunun puan değişimi ve yeni toplam puanı
class RoundScoreBreakdown {
  final int playerId;
  final String playerName;
  final int tricksWon;
  final int? bidOrTarget;
  final int scoreDelta;
  final int newTotalScore;
  final bool succeeded;

  const RoundScoreBreakdown({
    required this.playerId,
    required this.playerName,
    required this.tricksWon,
    required this.bidOrTarget,
    required this.scoreDelta,
    required this.newTotalScore,
    required this.succeeded,
  });
}

/// Batak puanlama kuralları (saf Dart):
/// - İhaleli Oyun & Gömmeli 3'lü Oyun:
///   - İhaleyi alan, ihalesindeki sayıda veya daha fazla el alırsa aldığı el
///     (veya ihalesi; Batak'ta aldığı el >= ihale ise aldığı el kadar, örn 7 diyip 7 alırsa +7,
///     8 alırsa +8; kullanıcı kuralında: "ihalesindeki sayıda veya daha fazla el alırsa ihale kadar puan kazanır,
///     alamazsa ihale kadar puan kaybeder. Diğer oyuncular aldıkları el kadar puan alır.")
///   - Bu kurala birebir sadık kalarak:
///     - İhaleyi alan `tricksWon >= winningBid` ise `+winningBid` puan kazanır,
///       `tricksWon < winningBid` ise `-winningBid` puan kaybeder.
///     - Diğer oyuncular aldıkları el (`tricksWon`) kadar puan alır.
/// - İhalesiz Oyun:
///   - Her oyuncu aldığı el (`tricksWon`) kadar puan alır.
/// - Eşli Oyun (Karşı karşıya oturan ortaklar: 0 & 2 bir takım, 1 & 3 bir takım):
///   - İhaleyi alan takımın toplam eli (`teamTricks >= winningBid`) ise takım üyelerine `+winningBid`,
///     alamazsa `-winningBid` yazılır.
///   - Rakip takım üyelerine aldıkları toplam el (`otherTeamTricks`) yazılır.
/// - 3-5-8 Oyunu:
///   - Her oyuncunun o turdaki hedefi (`targetQuota`: 3, 5 veya 8) vardır.
///   - Hedefini tutturursa veya geçerse `+tricksWon` (veya `+targetQuota + (tricksWon - targetQuota)` = `tricksWon`),
///     tutturamazsa `-(targetQuota - tricksWon)` (veya `-targetQuota`) puan alır.
class ScoreCalculator {
  static List<RoundScoreBreakdown> calculateRoundScores({
    required List<Player> players,
    required GameMode gameMode,
    required int? bidWinnerIndex,
    required int? winningBid,
  }) {
    switch (gameMode) {
      case GameMode.ihaleli:
      case GameMode.gommeli3lu:
        return _calculateBiddingScores(
          players: players,
          bidWinnerIndex: bidWinnerIndex,
          winningBid: winningBid,
        );
      case GameMode.ihalesiz:
        return _calculateNoBidScores(players);
      case GameMode.esli:
        return _calculatePartnershipScores(
          players: players,
          bidWinnerIndex: bidWinnerIndex,
          winningBid: winningBid,
        );
      case GameMode.ucBesSekiz:
        return _calculate358Scores(players);
    }
  }

  static List<RoundScoreBreakdown> _calculateBiddingScores({
    required List<Player> players,
    required int? bidWinnerIndex,
    required int? winningBid,
  }) {
    final results = <RoundScoreBreakdown>[];

    for (final player in players) {
      final isBidder =
          bidWinnerIndex != null && player.id == bidWinnerIndex && winningBid != null;

      int delta;
      bool succeeded;
      int? target;

      if (isBidder) {
        target = winningBid;
        if (player.tricksWon >= winningBid) {
          delta = winningBid;
          succeeded = true;
        } else {
          delta = -winningBid;
          succeeded = false;
        }
      } else {
        target = null;
        delta = player.tricksWon;
        succeeded = true;
      }

      results.add(
        RoundScoreBreakdown(
          playerId: player.id,
          playerName: player.name,
          tricksWon: player.tricksWon,
          bidOrTarget: target,
          scoreDelta: delta,
          newTotalScore: player.totalScore + delta,
          succeeded: succeeded,
        ),
      );
    }

    return results;
  }

  static List<RoundScoreBreakdown> _calculateNoBidScores(
    List<Player> players,
  ) {
    return players.map((player) {
      final delta = player.tricksWon;
      return RoundScoreBreakdown(
        playerId: player.id,
        playerName: player.name,
        tricksWon: player.tricksWon,
        bidOrTarget: null,
        scoreDelta: delta,
        newTotalScore: player.totalScore + delta,
        succeeded: true,
      );
    }).toList();
  }

  static List<RoundScoreBreakdown> _calculatePartnershipScores({
    required List<Player> players,
    required int? bidWinnerIndex,
    required int? winningBid,
  }) {
    if (players.length < 4 || bidWinnerIndex == null || winningBid == null) {
      return _calculateNoBidScores(players);
    }

    // Takım A: 0 (SİZ) & 2 (BORA), Takım B: 1 (ALP) & 3 (DENİZ)
    final teamATricks = players[0].tricksWon + players[2].tricksWon;
    final teamBTricks = players[1].tricksWon + players[3].tricksWon;
    final bidderIsTeamA = bidWinnerIndex == 0 || bidWinnerIndex == 2;

    final results = <RoundScoreBreakdown>[];
    for (final player in players) {
      final isTeamA = player.id == 0 || player.id == 2;
      final teamTricks = isTeamA ? teamATricks : teamBTricks;
      final isBidderTeam =
          (isTeamA && bidderIsTeamA) || (!isTeamA && !bidderIsTeamA);

      int delta;
      bool succeeded;
      int? target;

      if (isBidderTeam) {
        target = winningBid;
        if (teamTricks >= winningBid) {
          delta = winningBid;
          succeeded = true;
        } else {
          delta = -winningBid;
          succeeded = false;
        }
      } else {
        target = null;
        delta = teamTricks;
        succeeded = true;
      }

      results.add(
        RoundScoreBreakdown(
          playerId: player.id,
          playerName: player.name,
          tricksWon: teamTricks,
          bidOrTarget: target,
          scoreDelta: delta,
          newTotalScore: player.totalScore + delta,
          succeeded: succeeded,
        ),
      );
    }

    return results;
  }

  static List<RoundScoreBreakdown> _calculate358Scores(
    List<Player> players,
  ) {
    return players.map((player) {
      final quota = player.targetQuota ?? 5;
      final diff = player.tricksWon - quota;
      final succeeded = diff >= 0;
      final delta = succeeded ? player.tricksWon : diff;

      return RoundScoreBreakdown(
        playerId: player.id,
        playerName: player.name,
        tricksWon: player.tricksWon,
        bidOrTarget: quota,
        scoreDelta: delta,
        newTotalScore: player.totalScore + delta,
        succeeded: succeeded,
      );
    }).toList();
  }

  /// Oyun sonunda oyuncuları yüksek puandan düşüğe sıralar.
  static List<Player> rankPlayersByScore(List<Player> players) {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }
}
