import 'player.dart';
import 'playing_card.dart';

/// Ortaya atılan tek bir kart ve onu atan oyuncunun bilgisi
class PlayedCardEntry {
  final int playerId;
  final PlayerSeat seat;
  final PlayingCard card;

  const PlayedCardEntry({
    required this.playerId,
    required this.seat,
    required this.card,
  });
}

/// Masanın ortasındaki aktif el (trick)
class Trick {
  final int expectedCardCount;
  final List<PlayedCardEntry> playedCards;

  const Trick({
    this.expectedCardCount = 4,
    this.playedCards = const [],
  });

  bool get isEmpty => playedCards.isEmpty;
  bool get isComplete => playedCards.length >= expectedCardCount;

  /// Eli başlatan ilk kartın rengi (açılan renk)
  CardSuit? get ledSuit =>
      playedCards.isEmpty ? null : playedCards.first.card.suit;

  Trick addCard({
    required int playerId,
    required PlayerSeat seat,
    required PlayingCard card,
  }) {
    return Trick(
      expectedCardCount: expectedCardCount,
      playedCards: [
        ...playedCards,
        PlayedCardEntry(playerId: playerId, seat: seat, card: card),
      ],
    );
  }
}
