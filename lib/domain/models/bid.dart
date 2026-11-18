/// Bir oyuncunun ihale aşamasındaki aksiyonu (teklif veya pas)
class BidAction {
  final int playerId;
  final bool isPass;
  final int? amount;

  const BidAction._({
    required this.playerId,
    required this.isPass,
    this.amount,
  });

  factory BidAction.pass(int playerId) =>
      BidAction._(playerId: playerId, isPass: true);

  factory BidAction.bid(int playerId, int amount) {
    assert(amount >= 5 && amount <= 16, 'İhale 5 ile 16 arasında olmalıdır');
    return BidAction._(playerId: playerId, isPass: false, amount: amount);
  }
}

/// İhale oturumu ve kuralları (saf Dart)
class BiddingSession {
  final int playerCount;
  final int startingPlayerIndex;
  final int minAllowedBid;
  final int maxAllowedBid;
  final List<BidAction> history;
  final int? highestBidderIndex;
  final int? highestBid;

  const BiddingSession({
    this.playerCount = 4,
    this.startingPlayerIndex = 0,
    this.minAllowedBid = 5,
    this.maxAllowedBid = 13,
    this.history = const [],
    this.highestBidderIndex,
    this.highestBid,
  });

  /// Sıradaki oyuncunun indeksi
  int get currentTurnIndex =>
      (startingPlayerIndex + history.length) % playerCount;

  /// Tüm oyuncular (4 oyuncu) konuşmasını tamamladı mı?
  /// Veya biri 13 dediyse ihale anında biter.
  bool get isComplete =>
      history.length >= playerCount || highestBid == maxAllowedBid;

  /// Herkes pas mı geçti?
  bool get allPassed => isComplete && highestBidderIndex == null;

  /// Belirli bir teklif sayısı şu an seçilebilir mi?
  bool canBid(int amount) {
    if (isComplete) return false;
    if (amount < minAllowedBid || amount > maxAllowedBid) return false;
    if (highestBid == null) return true;
    return amount > highestBid!;
  }

  /// Yeni bir teklif veya pas kaydeder.
  BiddingSession recordAction(BidAction action) {
    if (isComplete) return this;

    if (action.isPass) {
      return BiddingSession(
        playerCount: playerCount,
        startingPlayerIndex: startingPlayerIndex,
        minAllowedBid: minAllowedBid,
        maxAllowedBid: maxAllowedBid,
        history: [...history, action],
        highestBidderIndex: highestBidderIndex,
        highestBid: highestBid,
      );
    }

    final bidAmount = action.amount!;
    if (!canBid(bidAmount)) {
      throw ArgumentError('Geçersiz ihale teklifi: $bidAmount');
    }

    return BiddingSession(
      playerCount: playerCount,
      startingPlayerIndex: startingPlayerIndex,
      minAllowedBid: minAllowedBid,
      maxAllowedBid: maxAllowedBid,
      history: [...history, action],
      highestBidderIndex: action.playerId,
      highestBid: bidAmount,
    );
  }
}
