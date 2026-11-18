import '../models/game_settings.dart';
import '../models/playing_card.dart';
import '../models/trick.dart';
import '../rules/move_validator.dart';
import '../rules/trick_evaluator.dart';

/// Kolay ve Zor botlar için kural tabanlı kart atma stratejisi (saf Dart)
class BotPlayStrategy {
  /// Geçerli (`playableCards`) kartlar arasından en uygun kartı seçer.
  static PlayingCard chooseCardToPlay({
    required int botId,
    required List<PlayingCard> hand,
    required Trick currentTrick,
    required CardSuit trumpSuit,
    required bool isTrumpBroken,
    required bool mustBreakTrump,
    required BotDifficulty difficulty,
    required Set<PlayingCard> playedCardsInRound,
    required bool isPartnershipMode,
    int? partnerId,
  }) {
    final validSet = MoveValidator.getPlayableCards(
      hand: hand,
      currentTrick: currentTrick,
      trumpSuit: trumpSuit,
      isTrumpBroken: isTrumpBroken,
      mustBreakTrump: mustBreakTrump,
    );

    final validCards = validSet.toList();
    if (validCards.length == 1) {
      return validCards.first;
    }

    if (difficulty == BotDifficulty.easy) {
      return _chooseCardEasy(
        validCards: validCards,
        currentTrick: currentTrick,
        trumpSuit: trumpSuit,
      );
    }

    return _chooseCardHard(
      botId: botId,
      validCards: validCards,
      currentTrick: currentTrick,
      trumpSuit: trumpSuit,
      playedCardsInRound: playedCardsInRound,
      isPartnershipMode: isPartnershipMode,
      partnerId: partnerId,
    );
  }

  /// Kolay Bot:
  /// - Eli başlatıyorsa en yüksek yan kağıdını veya orta kağıdını atar.
  /// - Yükseltebiliyorsa en küçük yükselten kağıdı atar, yükseltemiyorsa en küçüğünü atar.
  static PlayingCard _chooseCardEasy({
    required List<PlayingCard> validCards,
    required Trick currentTrick,
    required CardSuit trumpSuit,
  }) {
    validCards.sort((a, b) => a.rank.strength.compareTo(b.rank.strength));

    if (currentTrick.isEmpty) {
      final nonTrumps = validCards.where((c) => c.suit != trumpSuit).toList();
      if (nonTrumps.isNotEmpty) {
        return nonTrumps.last;
      }
      return validCards.first;
    }

    final currentBest = TrickEvaluator.evaluateWinner(
      trick: currentTrick,
      trumpSuit: trumpSuit,
    );

    // Geçerli kartlar zaten MoveValidator tarafından filtrelendiği için:
    // Eğer geçerli kartlardan biri şu anki en iyiyi geçiyorsa en ekonomik (en küçük) kazananı at.
    for (final card in validCards) {
      if (TrickEvaluator.doesBeat(
        currentBest: currentBest.card,
        challenger: card,
        ledSuit: currentTrick.ledSuit!,
        trumpSuit: trumpSuit,
      )) {
        return card;
      }
    }

    // Kazanamıyorsa en düşük değerli kartı at
    return validCards.first;
  }

  /// Zor Bot:
  /// - Oynanan kartları (`playedCardsInRound`) sayar ve kalan en yüksek kartları (boss card) bilir.
  /// - Eşli oyunda (`isPartnershipMode`) ortağı (`partnerId`) şu an eli kazanıyorsa ve
  ///   ortağının kartı kalan kartlara göre sağlamsa (veya son oyuncusuysa) ortağını ezmez,
  ///   en küçük kağıdı (veya zorunlu yükseltmenin en küçüğünü) atar.
  /// - Eli başlatırken dışarıda daha büyüğü kalmamış sağlam (As / boss) kağıtlarını çeker.
  static PlayingCard _chooseCardHard({
    required int botId,
    required List<PlayingCard> validCards,
    required Trick currentTrick,
    required CardSuit trumpSuit,
    required Set<PlayingCard> playedCardsInRound,
    required bool isPartnershipMode,
    int? partnerId,
  }) {
    // Küçükten büyüğe sırala
    validCards.sort((a, b) => a.rank.strength.compareTo(b.rank.strength));

    // 1. Eli başlatıyorsa (Lead)
    if (currentTrick.isEmpty) {
      // Yan renklerde dışarıda daha büyüğü kalmamış "boss" kağıt var mı?
      final nonTrumps = validCards.where((c) => c.suit != trumpSuit).toList();
      for (final card in nonTrumps.reversed) {
        if (_isBossCardInSuit(card, validCards, playedCardsInRound)) {
          return card;
        }
      }

      // Boss kağıt yoksa en kısa yan rengin en küçük kağıdını çıkarak el gelişimini kolla
      if (nonTrumps.isNotEmpty) {
        return nonTrumps.first;
      }

      // Sadece koz varsa boss kozu veya en küçük kozu oyna
      for (final card in validCards.reversed) {
        if (_isBossCardInSuit(card, validCards, playedCardsInRound)) {
          return card;
        }
      }
      return validCards.first;
    }

    final ledSuit = currentTrick.ledSuit!;
    final currentWinner = TrickEvaluator.evaluateWinner(
      trick: currentTrick,
      trumpSuit: trumpSuit,
    );
    final isLastToPlay =
        currentTrick.playedCards.length + 1 >= currentTrick.expectedCardCount;

    // 2. Eşli oyunda ortak şu an eli alıyorsa:
    final partnerWinning = isPartnershipMode &&
        partnerId != null &&
        currentWinner.playerId == partnerId;

    if (partnerWinning) {
      // Ortak alıyorsa ve kural izin veriyorsa en küçük kartı at (ortağa el kazandır)
      return _pickLowestValueDiscard(validCards, trumpSuit);
    }

    // 3. Rakip şu an eli alıyorsa:
    final winningCandidates = validCards
        .where(
          (c) => TrickEvaluator.doesBeat(
            currentBest: currentWinner.card,
            challenger: c,
            ledSuit: ledSuit,
            trumpSuit: trumpSuit,
          ),
        )
        .toList();

    if (winningCandidates.isNotEmpty) {
      // Son konuşan oyuncuysak, eli alacak en ekonomik (en küçük) kart yeterli!
      if (isLastToPlay) {
        return winningCandidates.first;
      }

      // Henüz arkamızda konuşacak oyuncu varsa, dışarıda daha büyüğü olmayan boss kart varsa onu at,
      // yoksa en ekonomik kazananı at.
      for (final c in winningCandidates.reversed) {
        if (_isBossCardInSuit(c, validCards, playedCardsInRound)) {
          return c;
        }
      }
      return winningCandidates.first;
    }

    // 4. Eli alma şansı yoksa en değersiz kağıdı (koz olmayan en küçük kağıdı) at
    return _pickLowestValueDiscard(validCards, trumpSuit);
  }

  /// Bir karttan daha büyük olan aynı renkteki tüm kartlar ya oynanmışsa ya da botun kendi elindeyse true döner.
  static bool _isBossCardInSuit(
    PlayingCard candidate,
    List<PlayingCard> ownValidCards,
    Set<PlayingCard> playedCardsInRound,
  ) {
    for (final rank in CardRank.values) {
      if (rank.strength <= candidate.rank.strength) continue;
      final higherCard = PlayingCard(suit: candidate.suit, rank: rank);
      final alreadyPlayed = playedCardsInRound.contains(higherCard);
      final inOwnHand = ownValidCards.contains(higherCard);
      if (!alreadyPlayed && !inOwnHand) {
        return false;
      }
    }
    return true;
  }

  /// Kağıt kaçarken (discard) koz olmayan en küçük kağıdı tercih eder.
  static PlayingCard _pickLowestValueDiscard(
    List<PlayingCard> validCards,
    CardSuit trumpSuit,
  ) {
    final nonTrumps = validCards.where((c) => c.suit != trumpSuit).toList();
    if (nonTrumps.isNotEmpty) {
      nonTrumps.sort((a, b) => a.rank.strength.compareTo(b.rank.strength));
      return nonTrumps.first;
    }
    validCards.sort((a, b) => a.rank.strength.compareTo(b.rank.strength));
    return validCards.first;
  }
}
