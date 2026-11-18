import '../models/playing_card.dart';

/// Bir botun ihale aşamasında el gücüne göre teklif hesaplaması.
class BotBiddingLogic {
  /// Kolay bot ihale hesabı:
  /// Elindeki As, Papaz ve Koz (Maça) sayısına göre basit tahmin yapar.
  static int? decideBidEasy({
    required List<PlayingCard> hand,
    required int? currentHighestBid,
    int minBid = 5,
    int maxBid = 13,
  }) {
    double estimatedTricks = 0;

    final spades = hand.where((c) => c.suit == CardSuit.spades).toList();
    estimatedTricks += spades.length * 0.65;

    for (final card in hand) {
      if (card.suit != CardSuit.spades) {
        if (card.rank == CardRank.ace) {
          estimatedTricks += 0.95;
        } else if (card.rank == CardRank.king) {
          estimatedTricks += 0.55;
        }
      } else {
        if (card.rank.strength >= CardRank.jack.strength) {
          estimatedTricks += 0.45;
        }
      }
    }

    final targetBid = estimatedTricks.round().clamp(0, maxBid);
    final minimumNeeded =
        currentHighestBid == null ? minBid : currentHighestBid + 1;

    if (targetBid >= minimumNeeded && minimumNeeded <= maxBid) {
      return minimumNeeded; // Gereksiz risk almadan bir üstünü veya gücünü teklif eder
    }
    return null; // PAS
  }

  /// Zor bot ihale hesabı:
  /// As/Papaz/Kız kombinasyonlarını, koz uzunluğunu ve yan renklerdeki
  /// çakma (void/singleton) fırsatlarını değerlendirir.
  static int? decideBidHard({
    required List<PlayingCard> hand,
    required int? currentHighestBid,
    int minBid = 5,
    int maxBid = 13,
    CardSuit preferredTrump = CardSuit.spades,
  }) {
    double tricks = 0;

    final bySuit = <CardSuit, List<PlayingCard>>{
      for (final s in CardSuit.values) s: [],
    };
    for (final c in hand) {
      bySuit[c.suit]!.add(c);
    }

    final trumps = bySuit[preferredTrump]!;
    final trumpCount = trumps.length;

    // Yüksek kozlar
    for (final c in trumps) {
      if (c.rank == CardRank.ace) {
        tricks += 1.0;
      } else if (c.rank == CardRank.king && trumpCount >= 2) {
        tricks += 0.9;
      } else if (c.rank == CardRank.queen && trumpCount >= 3) {
        tricks += 0.75;
      } else if (c.rank == CardRank.jack && trumpCount >= 4) {
        tricks += 0.65;
      }
    }

    // Uzun koz bonusu (4'ten sonraki her koz neredeyse garanti eldir)
    if (trumpCount > 4) {
      tricks += (trumpCount - 4) * 0.85;
    }

    // Yan renklerin analizi
    for (final suit in CardSuit.values) {
      if (suit == preferredTrump) continue;
      final cards = bySuit[suit]!;
      final hasAce = cards.any((c) => c.rank == CardRank.ace);
      final hasKing = cards.any((c) => c.rank == CardRank.king);
      final hasQueen = cards.any((c) => c.rank == CardRank.queen);

      if (hasAce) tricks += 0.95;
      if (hasKing && cards.length >= 2 && cards.length <= 5) {
        tricks += hasAce ? 0.80 : 0.55;
      }
      if (hasQueen && hasAce && hasKing && cards.length <= 4) {
        tricks += 0.50;
      }

      // Kısa yan renk varsa ve elde yeterli koz varsa çakarak el alır
      if (cards.isEmpty && trumpCount >= 4) {
        tricks += 0.75;
      } else if (cards.length == 1 && trumpCount >= 4) {
        tricks += 0.45;
      }
    }

    final maxSafeBid = tricks.floor().clamp(0, maxBid);
    final minimumNeeded =
        currentHighestBid == null ? minBid : currentHighestBid + 1;

    if (maxSafeBid >= minimumNeeded && minimumNeeded <= maxBid) {
      // Güçlü eli varsa doğrudan makul teklifi verir
      return minimumNeeded;
    }
    return null; // PAS
  }

  /// İhaleyi alan bot koz seçme hakkına sahipse en güçlü olduğu rengi seçer.
  static CardSuit chooseBestTrump(List<PlayingCard> hand) {
    CardSuit bestSuit = CardSuit.spades;
    double bestScore = -1;

    for (final suit in CardSuit.values) {
      final suitCards = hand.where((c) => c.suit == suit).toList();
      double score = suitCards.length * 10.0;
      for (final c in suitCards) {
        score += c.rank.strength;
      }
      if (score > bestScore) {
        bestScore = score;
        bestSuit = suit;
      }
    }
    return bestSuit;
  }

  /// Gömmeli 3'lü veya 3-5-8 oyununda botun elindeki 20 karttan
  /// gömmesi gereken en zayıf 4 kartı seçer (koz olmayan düşük kartlar).
  static List<PlayingCard> pickCardsToBury({
    required List<PlayingCard> hand20,
    required CardSuit trumpSuit,
  }) {
    final candidates = List<PlayingCard>.from(hand20);
    candidates.sort((a, b) {
      final aIsTrump = a.suit == trumpSuit ? 1 : 0;
      final bIsTrump = b.suit == trumpSuit ? 1 : 0;
      if (aIsTrump != bIsTrump) return aIsTrump.compareTo(bIsTrump);
      return a.rank.strength.compareTo(b.rank.strength);
    });
    return candidates.take(4).toList();
  }
}
