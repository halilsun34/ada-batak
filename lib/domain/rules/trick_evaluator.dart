import '../models/playing_card.dart';
import '../models/trick.dart';

/// Ortadaki eli (trick) hangi kartın ve oyuncunun kazandığını hesaplar.
/// Kurallar:
/// - Eli kozlar önce alır (birden fazla koz varsa en yüksek koz alır).
/// - Hiç koz atılmamışsa açılan rengin (ledSuit) en büyük kartı alır.
/// - As (14) en büyük karttır.
class TrickEvaluator {
  static PlayedCardEntry evaluateWinner({
    required Trick trick,
    required CardSuit trumpSuit,
  }) {
    if (trick.playedCards.isEmpty) {
      throw StateError('Boş elin kazananı hesaplanamaz');
    }

    var winningEntry = trick.playedCards.first;

    for (var i = 1; i < trick.playedCards.length; i++) {
      final candidate = trick.playedCards[i];
      if (doesBeat(
        currentBest: winningEntry.card,
        challenger: candidate.card,
        ledSuit: trick.ledSuit!,
        trumpSuit: trumpSuit,
      )) {
        winningEntry = candidate;
      }
    }

    return winningEntry;
  }

  /// `challenger` kartı şu ana kadarki `currentBest` kartını geçer mi?
  static bool doesBeat({
    required PlayingCard currentBest,
    required PlayingCard challenger,
    required CardSuit ledSuit,
    required CardSuit trumpSuit,
  }) {
    final bestIsTrump = currentBest.suit == trumpSuit;
    final challengerIsTrump = challenger.suit == trumpSuit;

    if (challengerIsTrump && !bestIsTrump) {
      return true;
    }
    if (!challengerIsTrump && bestIsTrump) {
      return false;
    }
    if (challengerIsTrump && bestIsTrump) {
      return challenger.rank.strength > currentBest.rank.strength;
    }

    // İkisi de koz değilse: yalnızca açılan renkte (ledSuit) olan yükseltebilir
    if (challenger.suit == ledSuit && currentBest.suit == ledSuit) {
      return challenger.rank.strength > currentBest.rank.strength;
    }

    return false;
  }
}
