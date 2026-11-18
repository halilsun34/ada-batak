import 'playing_card.dart';

/// Masadaki oyuncu konumları
enum PlayerSeat {
  south, // Siz (Altta)
  west,  // Alp (Solda)
  north, // Bora (Üstte)
  east;  // Deniz (Sağda)

  String get defaultName {
    switch (this) {
      case PlayerSeat.south:
        return 'SİZ';
      case PlayerSeat.west:
        return 'ALP';
      case PlayerSeat.north:
        return 'BORA';
      case PlayerSeat.east:
        return 'DENİZ';
    }
  }

  bool get isHuman => this == PlayerSeat.south;
}

/// Oyuncu domain modeli
class Player {
  final int id;
  final String name;
  final PlayerSeat seat;
  final bool isBot;
  final List<PlayingCard> hand;
  final int totalScore;
  final int tricksWon;
  final int? currentBid;
  final bool hasPassedBid;
  final int? targetQuota; // 3-5-8 modu için (3, 5 veya 8)

  const Player({
    required this.id,
    required this.name,
    required this.seat,
    required this.isBot,
    this.hand = const [],
    this.totalScore = 0,
    this.tricksWon = 0,
    this.currentBid,
    this.hasPassedBid = false,
    this.targetQuota,
  });

  factory Player.initial(
    int id,
    PlayerSeat seat, {
    List<PlayingCard> hand = const [],
  }) {
    return Player(
      id: id,
      name: seat.defaultName,
      seat: seat,
      isBot: !seat.isHuman,
      hand: hand,
    );
  }

  Player copyWith({
    String? name,
    List<PlayingCard>? hand,
    int? totalScore,
    int? tricksWon,
    int? currentBid,
    bool clearCurrentBid = false,
    bool? hasPassedBid,
    int? targetQuota,
    bool clearTargetQuota = false,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      seat: seat,
      isBot: isBot,
      hand: hand ?? this.hand,
      totalScore: totalScore ?? this.totalScore,
      tricksWon: tricksWon ?? this.tricksWon,
      currentBid: clearCurrentBid ? null : (currentBid ?? this.currentBid),
      hasPassedBid: hasPassedBid ?? this.hasPassedBid,
      targetQuota: clearTargetQuota ? null : (targetQuota ?? this.targetQuota),
    );
  }

  /// Etikette görünecek metin (örn: "BORA  0" veya "SİZ  0")
  String get badgeLabel => '$name  $totalScore';
}
