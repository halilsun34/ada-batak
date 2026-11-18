import '../models/playing_card.dart';
import '../models/trick.dart';
import 'trick_evaluator.dart';

/// Batak el oynama kuralları doğrulayıcısı (saf Dart):
/// 1. İlk kart atılıyorsa (el başı):
///    - `mustBreakTrump` açıksa ve koz henüz çıkmamışsa (`isTrumpBroken == false`),
///      oyuncunun elinde koz dışında başka kart varsa koz ile başlayamaz.
///      Elinde sadece koz varsa koz atabilir.
/// 2. Ortada açılmış bir renk (`ledSuit`) varsa:
///    - Elde açılan renkten kart varsa o renge uymak ZORUNLUDUR.
///      - Eğer masaya henüz koz çakılmamışsa (veya açılan renk zaten koz ise) ve
///        oyuncunun elinde masadaki en büyük `ledSuit` kartından daha büyük bir
///        `ledSuit` kartı varsa büyütmek (yükseltmek) ZORUNLUDUR.
///      - Eğer masaya başka bir oyuncu koz çakmışsa (açılan renk koz değilken),
///        açılan renkten istediği kartı atabilir (bazı varyasyonlarda yine yükseltme aranmaz,
///        ancak burada açılan renkten herhangi birini atabilir).
///    - Elde açılan renkten kart YOKSA:
///      - Elde koz (`trumpSuit`) varsa koz atmak ZORUNLUDUR.
///      - Masada zaten koz varsa ve oyuncunun elinde masadaki en büyük kozdan
///        daha büyük koz varsa, kozu büyütmek ZORUNLUDUR; daha büyük kozu yoksa
///        elindeki herhangi bir kozu atmak zorundadır.
///    - Elde ne açılan renk ne de koz varsa istediği kartı atabilir.
class MoveValidator {
  static Set<PlayingCard> getPlayableCards({
    required List<PlayingCard> hand,
    required Trick currentTrick,
    required CardSuit trumpSuit,
    required bool isTrumpBroken,
    required bool mustBreakTrump,
  }) {
    if (hand.isEmpty) return const {};

    // 1. Eli ilk başlatan oyuncu
    if (currentTrick.isEmpty) {
      if (!mustBreakTrump || isTrumpBroken) {
        return hand.toSet();
      }
      final nonTrumpCards = hand.where((c) => c.suit != trumpSuit).toSet();
      if (nonTrumpCards.isNotEmpty) {
        return nonTrumpCards;
      }
      // Elde sadece koz kalmışsa kozla başlayabilir
      return hand.toSet();
    }

    final ledSuit = currentTrick.ledSuit!;
    final sameSuitCards = hand.where((c) => c.suit == ledSuit).toList();

    // 2. Elde açılan renkten kart varsa: Renge uymak zorunlu
    if (sameSuitCards.isNotEmpty) {
      final anyTrumpPlayedOnNonTrumpLead = ledSuit != trumpSuit &&
          currentTrick.playedCards.any((e) => e.card.suit == trumpSuit);

      if (!anyTrumpPlayedOnNonTrumpLead) {
        // Masadaki açılan rengin en büyük kartını bul
        final highestLedRank = currentTrick.playedCards
            .where((e) => e.card.suit == ledSuit)
            .map((e) => e.card.rank.strength)
            .reduce((a, b) => a > b ? a : b);

        final higherSameSuit = sameSuitCards
            .where((c) => c.rank.strength > highestLedRank)
            .toSet();

        if (higherSameSuit.isNotEmpty) {
          return higherSameSuit;
        }
      }
      return sameSuitCards.toSet();
    }

    // 3. Elde açılan renkten kart yoksa: Koz varsa koz atmak zorunlu
    final trumpCards = hand.where((c) => c.suit == trumpSuit).toList();
    if (trumpCards.isNotEmpty) {
      final playedTrumps = currentTrick.playedCards
          .where((e) => e.card.suit == trumpSuit)
          .toList();

      if (playedTrumps.isNotEmpty) {
        final highestPlayedTrump = playedTrumps
            .map((e) => e.card.rank.strength)
            .reduce((a, b) => a > b ? a : b);

        final higherTrumps = trumpCards
            .where((c) => c.rank.strength > highestPlayedTrump)
            .toSet();

        if (higherTrumps.isNotEmpty) {
          return higherTrumps;
        }
      }
      return trumpCards.toSet();
    }

    // 4. Ne açılan renk ne de koz varsa: İstediği kartı atabilir
    return hand.toSet();
  }

  /// Yardımcı metod: Seçilen kart kurallara göre geçerli mi?
  static bool isCardPlayable({
    required PlayingCard card,
    required List<PlayingCard> hand,
    required Trick currentTrick,
    required CardSuit trumpSuit,
    required bool isTrumpBroken,
    required bool mustBreakTrump,
  }) {
    final validSet = getPlayableCards(
      hand: hand,
      currentTrick: currentTrick,
      trumpSuit: trumpSuit,
      isTrumpBroken: isTrumpBroken,
      mustBreakTrump: mustBreakTrump,
    );
    return validSet.contains(card);
  }

  /// Masadaki anlık kazanan kartı döner
  static PlayedCardEntry? currentWinningEntry(
    Trick trick,
    CardSuit trumpSuit,
  ) {
    if (trick.isEmpty) return null;
    return TrickEvaluator.evaluateWinner(trick: trick, trumpSuit: trumpSuit);
  }
}
