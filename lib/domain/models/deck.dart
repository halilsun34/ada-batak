import 'dart:math';
import 'game_settings.dart';
import 'playing_card.dart';

/// Dağıtım sonucu (oyuncu elleri ve varsa ortaya gömülen kartlar)
class DealResult {
  final List<List<PlayingCard>> hands;
  final List<PlayingCard> kitty; // Gömmeli 3'lü oyunda ortaya ayrılan 4 kart

  const DealResult({
    required this.hands,
    this.kitty = const [],
  });
}

/// 52 kartlık standart deste oluşturma, karıştırma, dağıtma ve el sıralama
class Deck {
  final Random _random;

  Deck({Random? random}) : _random = random ?? Random();

  /// 52 kartlık tam deste üretir.
  static List<PlayingCard> createStandard52() {
    final cards = <PlayingCard>[];
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return cards;
  }

  /// Karıştırılmış 52 kart döner.
  List<PlayingCard> createShuffled() {
    final cards = createStandard52();
    cards.shuffle(_random);
    return cards;
  }

  /// 4 oyunculu klasik/ihaleli/ihalesiz/eşli mod için:
  /// Her oyuncuya 13 kart dağıtır ve her eli sıralar.
  DealResult dealFor4Players({
    EqualCardsOrder order = EqualCardsOrder.bottom,
  }) {
    final cards = createShuffled();
    final hands = List.generate(4, (i) {
      final slice = cards.sublist(i * 13, (i + 1) * 13);
      return sortHand(slice, order: order);
    });
    return DealResult(hands: hands);
  }

  /// 3 oyunculu Gömmeli Batak için:
  /// 3 oyuncuya 16'şar kart, ortaya (kitty) 4 kart dağıtır.
  DealResult dealFor3PlayersBury({
    EqualCardsOrder order = EqualCardsOrder.bottom,
  }) {
    final cards = createShuffled();
    final hands = List.generate(3, (i) {
      final slice = cards.sublist(i * 16, (i + 1) * 16);
      return sortHand(slice, order: order);
    });
    final kitty = cards.sublist(48, 52);
    return DealResult(hands: hands, kitty: kitty);
  }

  /// 3 oyunculu 3-5-8 modu için:
  /// 52 karttan Sinek 2, Karo 2, Kupa 2, Maça 2 dışarı çıkarılmaz,
  /// veya 3-5-8'de 16-16-16 + 4 kart gömme / ya da 17-17-17 (51 kart, Sinek 2 hariç)
  /// Batak Club'da 3-5-8 modunda 8'i çeken oyuncu 4 kart gömer (16 el oynanır) veya 16'şar kart dağıtılır.
  DealResult dealFor358({
    EqualCardsOrder order = EqualCardsOrder.bottom,
  }) {
    return dealFor3PlayersBury(order: order);
  }

  /// Eldeki kartları Maça, Kupa, Karo, Sinek gruplu ve büyükten küçüğe sıralar.
  static List<PlayingCard> sortHand(
    List<PlayingCard> cards, {
    EqualCardsOrder order = EqualCardsOrder.bottom,
  }) {
    final sorted = List<PlayingCard>.from(cards);
    // EqualCardsOrder.bottom: Maça, Kupa üst sırada; Sinek, Karo alt sırada (görseldeki gibi)
    // EqualCardsOrder.top: Sinek, Karo üstte; Maça, Kupa altta (veya büyük renk grupları altta/üstte)
    final suitOrderMap = order == EqualCardsOrder.bottom
        ? const {
            CardSuit.spades: 0,
            CardSuit.hearts: 1,
            CardSuit.clubs: 2,
            CardSuit.diamonds: 3,
          }
        : const {
            CardSuit.clubs: 0,
            CardSuit.diamonds: 1,
            CardSuit.hearts: 2,
            CardSuit.spades: 3,
          };

    sorted.sort((a, b) {
      final suitComp = suitOrderMap[a.suit]!.compareTo(suitOrderMap[b.suit]!);
      if (suitComp != 0) return suitComp;
      return b.rank.strength.compareTo(a.rank.strength);
    });
    return sorted;
  }

  /// Eldeki kartları iki sıraya (üst sıra ve alt sıra) böler.
  /// 13 kartlık elde üst sırada 6 kart, alt sırada 7 kart (görseldeki gibi) bulunur.
  static ({List<PlayingCard> topRow, List<PlayingCard> bottomRow})
      splitHandIntoTwoRows(
    List<PlayingCard> hand, {
    EqualCardsOrder order = EqualCardsOrder.bottom,
  }) {
    final sorted = sortHand(hand, order: order);
    if (sorted.isEmpty) {
      return (topRow: const [], bottomRow: const []);
    }
    if (sorted.length <= 6) {
      return (topRow: const [], bottomRow: sorted);
    }
    final topCount = sorted.length ~/ 2; // 13 -> 6 üstte, 7 altta
    return (
      topRow: sorted.sublist(0, topCount),
      bottomRow: sorted.sublist(topCount),
    );
  }
}
