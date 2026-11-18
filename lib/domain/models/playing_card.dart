/// Kart renkleri (Maça, Kupa, Karo, Sinek)
enum CardSuit {
  spades('♠', 'Maça', false, 0),
  hearts('♥', 'Kupa', true, 1),
  diamonds('♦', 'Karo', true, 2),
  clubs('♣', 'Sinek', false, 3);

  final String symbol;
  final String turkishName;
  final bool isRed;
  final int sortOrder;

  const CardSuit(this.symbol, this.turkishName, this.isRed, this.sortOrder);
}

/// Kart değerleri (2'den As'a kadar, As en büyüktür)
enum CardRank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K'),
  ace(14, 'A');

  final int strength;
  final String label;

  const CardRank(this.strength, this.label);

  bool get isFaceCard =>
      this == CardRank.jack || this == CardRank.queen || this == CardRank.king;
}

/// Tek bir oyun kartını temsil eden saf Dart modeli
class PlayingCard implements Comparable<PlayingCard> {
  final CardSuit suit;
  final CardRank rank;

  const PlayingCard({
    required this.suit,
    required this.rank,
  });

  String get id => '${suit.name}_${rank.label}';

  bool get isRed => suit.isRed;

  /// Aynı renkte veya sıralamada büyüklük karşılaştırması:
  /// Önce renk grubu (Maça, Kupa, Karo, Sinek), aynı renkte büyükten küçüğe (As -> 2).
  @override
  int compareTo(PlayingCard other) {
    final suitComp = suit.sortOrder.compareTo(other.suit.sortOrder);
    if (suitComp != 0) return suitComp;
    return other.rank.strength.compareTo(rank.strength);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${suit.symbol}${rank.label}';
}
