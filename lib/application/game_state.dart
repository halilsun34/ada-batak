import '../domain/models/bid.dart';
import '../domain/models/deck.dart';
import '../domain/models/game_settings.dart';
import '../domain/models/player.dart';
import '../domain/models/playing_card.dart';
import '../domain/models/trick.dart';
import '../domain/rules/move_validator.dart';
import '../domain/rules/score_calculator.dart';

enum GamePhase {
  dealing,
  bidding,
  choosingTrump,
  buryingCards,
  playing,
  roundOver,
  gameOver,
}

class GameState {
  final int currentRound;
  final int targetRounds;
  final GameMode gameMode;
  final List<Player> players;
  final List<PlayingCard> kitty;
  final List<PlayingCard> selectedToBury;
  final int currentTurnIndex;
  final GamePhase phase;
  final BiddingSession biddingSession;
  final int? bidWinnerIndex;
  final int? winningBid;
  final CardSuit trumpSuit;
  final Trick currentTrick;
  final bool isTrumpBroken;
  final Set<PlayingCard> playedCardsInRound;
  final PlayerSeat? collectingWinnerSeat;
  final List<RoundScoreBreakdown> lastRoundBreakdown;
  final String? statusBanner;

  const GameState({
    required this.currentRound,
    required this.targetRounds,
    this.gameMode = GameMode.ihaleli,
    required this.players,
    this.kitty = const [],
    this.selectedToBury = const [],
    required this.currentTurnIndex,
    required this.phase,
    required this.biddingSession,
    this.bidWinnerIndex,
    this.winningBid,
    this.trumpSuit = CardSuit.spades,
    this.currentTrick = const Trick(),
    this.isTrumpBroken = false,
    this.playedCardsInRound = const {},
    this.collectingWinnerSeat,
    this.lastRoundBreakdown = const [],
    this.statusBanner,
  });

  factory GameState.initial({
    int targetRounds = 5,
    GameMode gameMode = GameMode.ihaleli,
    EqualCardsOrder equalCardsOrder = EqualCardsOrder.bottom,
    int startingPlayerIndex = 0,
    int currentRound = 1,
    List<int>? existingTotalScores,
    Deck? deck,
  }) {
    final activeDeck = deck ?? Deck();

    if (gameMode == GameMode.gommeli3lu || gameMode == GameMode.ucBesSekiz) {
      final deal = activeDeck.dealFor3PlayersBury(order: equalCardsOrder);
      const quotas = [8, 5, 3];
      final players = [
        Player.initial(0, PlayerSeat.south, hand: deal.hands[0]).copyWith(
          totalScore: existingTotalScores != null && existingTotalScores.isNotEmpty
              ? existingTotalScores[0]
              : 0,
          targetQuota: gameMode == GameMode.ucBesSekiz
              ? quotas[(0 + currentRound - 1) % 3]
              : null,
        ),
        Player.initial(1, PlayerSeat.west, hand: deal.hands[1]).copyWith(
          totalScore: existingTotalScores != null && existingTotalScores.length > 1
              ? existingTotalScores[1]
              : 0,
          targetQuota: gameMode == GameMode.ucBesSekiz
              ? quotas[(1 + currentRound - 1) % 3]
              : null,
        ),
        Player.initial(2, PlayerSeat.east, hand: deal.hands[2]).copyWith(
          totalScore: existingTotalScores != null && existingTotalScores.length > 2
              ? existingTotalScores[2]
              : 0,
          targetQuota: gameMode == GameMode.ucBesSekiz
              ? quotas[(2 + currentRound - 1) % 3]
              : null,
        ),
      ];

      if (gameMode == GameMode.ucBesSekiz) {
        final eightIdx = players.indexWhere((p) => p.targetQuota == 8);
        final activeIdx = eightIdx >= 0 ? eightIdx : 0;
        // 8 hedefi olan oyuncu yerdeki 4 kartı eline alır ve 4 kart gömer
        final mergedHand = Deck.sortHand(
          [...players[activeIdx].hand, ...deal.kitty],
          order: equalCardsOrder,
        );
        players[activeIdx] = players[activeIdx].copyWith(hand: mergedHand);

        return GameState(
          currentRound: currentRound,
          targetRounds: targetRounds,
          gameMode: gameMode,
          players: players,
          kitty: deal.kitty,
          currentTurnIndex: activeIdx,
          phase: GamePhase.buryingCards,
          biddingSession: BiddingSession(
            playerCount: 3,
            startingPlayerIndex: activeIdx,
          ),
          bidWinnerIndex: activeIdx,
          winningBid: 8,
          trumpSuit: CardSuit.spades,
          currentTrick: const Trick(expectedCardCount: 3),
          statusBanner:
              '3-5-8 Oyunu • ${players[activeIdx].name} (Hedef: 8) 4 kart gömüyor',
        );
      }

      return GameState(
        currentRound: currentRound,
        targetRounds: targetRounds,
        gameMode: gameMode,
        players: players,
        kitty: deal.kitty,
        currentTurnIndex: startingPlayerIndex % 3,
        phase: GamePhase.bidding,
        biddingSession: BiddingSession(
          playerCount: 3,
          startingPlayerIndex: startingPlayerIndex % 3,
          minAllowedBid: 6,
          maxAllowedBid: 16,
        ),
        trumpSuit: CardSuit.spades,
        currentTrick: const Trick(expectedCardCount: 3),
      );
    }

    // 4 oyunculu modlar: İhaleli, İhalesiz, Eşli
    final deal = activeDeck.dealFor4Players(order: equalCardsOrder);
    final players = [
      Player.initial(0, PlayerSeat.south, hand: deal.hands[0]).copyWith(
        totalScore: existingTotalScores != null && existingTotalScores.isNotEmpty
            ? existingTotalScores[0]
            : 0,
      ),
      Player.initial(1, PlayerSeat.west, hand: deal.hands[1]).copyWith(
        totalScore: existingTotalScores != null && existingTotalScores.length > 1
            ? existingTotalScores[1]
            : 0,
      ),
      Player.initial(2, PlayerSeat.north, hand: deal.hands[2]).copyWith(
        totalScore: existingTotalScores != null && existingTotalScores.length > 2
            ? existingTotalScores[2]
            : 0,
      ),
      Player.initial(3, PlayerSeat.east, hand: deal.hands[3]).copyWith(
        totalScore: existingTotalScores != null && existingTotalScores.length > 3
            ? existingTotalScores[3]
            : 0,
      ),
    ];

    if (gameMode == GameMode.ihalesiz) {
      return GameState(
        currentRound: currentRound,
        targetRounds: targetRounds,
        gameMode: gameMode,
        players: players,
        currentTurnIndex: startingPlayerIndex % 4,
        phase: GamePhase.playing,
        biddingSession: BiddingSession(
          playerCount: 4,
          startingPlayerIndex: startingPlayerIndex % 4,
        ),
        trumpSuit: CardSuit.spades,
        currentTrick: const Trick(expectedCardCount: 4),
        statusBanner: 'İhalesiz Oyun • Koz: ♠ Maça',
      );
    }

    return GameState(
      currentRound: currentRound,
      targetRounds: targetRounds,
      gameMode: gameMode,
      players: players,
      kitty: deal.kitty,
      currentTurnIndex: startingPlayerIndex % 4,
      phase: GamePhase.bidding,
      biddingSession: BiddingSession(
        playerCount: 4,
        startingPlayerIndex: startingPlayerIndex % 4,
      ),
      trumpSuit: CardSuit.spades,
      currentTrick: const Trick(expectedCardCount: 4),
    );
  }

  Player get currentPlayer => players[currentTurnIndex];

  Player? playerBySeat(PlayerSeat seat) {
    for (final p in players) {
      if (p.seat == seat) return p;
    }
    return null;
  }

  /// Kullanıcının (SİZ) şu an elinde kurallara göre oynayabileceği kartlar
  Set<PlayingCard> validCardsForPlayer(
    Player player, {
    required bool mustBreakTrump,
  }) {
    if (phase == GamePhase.buryingCards && currentPlayer.id == player.id) {
      return player.hand.toSet();
    }
    if (phase != GamePhase.playing ||
        collectingWinnerSeat != null ||
        currentPlayer.id != player.id) {
      return player.hand.toSet();
    }
    return MoveValidator.getPlayableCards(
      hand: player.hand,
      currentTrick: currentTrick,
      trumpSuit: trumpSuit,
      isTrumpBroken: isTrumpBroken,
      mustBreakTrump: mustBreakTrump,
    );
  }

  /// Etikette oyuncunun ihale veya el durumunu özetleyen kısa alt metin
  String? badgeSubtitleFor(Player player) {
    if (phase == GamePhase.bidding || phase == GamePhase.choosingTrump) {
      if (player.hasPassedBid) return 'PAS';
      if (player.currentBid != null) return 'İhale: ${player.currentBid}';
      return null;
    }
    if (phase == GamePhase.playing ||
        phase == GamePhase.buryingCards ||
        phase == GamePhase.roundOver) {
      if (player.targetQuota != null) {
        return '${player.tricksWon}/${player.targetQuota}';
      }
      if (bidWinnerIndex == player.id && winningBid != null) {
        return '${player.tricksWon}/$winningBid';
      }
      return 'El: ${player.tricksWon}';
    }
    return null;
  }

  GameState copyWith({
    int? currentRound,
    int? targetRounds,
    GameMode? gameMode,
    List<Player>? players,
    List<PlayingCard>? kitty,
    List<PlayingCard>? selectedToBury,
    int? currentTurnIndex,
    GamePhase? phase,
    BiddingSession? biddingSession,
    int? bidWinnerIndex,
    bool clearBidWinner = false,
    int? winningBid,
    bool clearWinningBid = false,
    CardSuit? trumpSuit,
    Trick? currentTrick,
    bool? isTrumpBroken,
    Set<PlayingCard>? playedCardsInRound,
    PlayerSeat? collectingWinnerSeat,
    bool clearCollectingWinner = false,
    List<RoundScoreBreakdown>? lastRoundBreakdown,
    String? statusBanner,
    bool clearStatusBanner = false,
  }) {
    return GameState(
      currentRound: currentRound ?? this.currentRound,
      targetRounds: targetRounds ?? this.targetRounds,
      gameMode: gameMode ?? this.gameMode,
      players: players ?? this.players,
      kitty: kitty ?? this.kitty,
      selectedToBury: selectedToBury ?? this.selectedToBury,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      phase: phase ?? this.phase,
      biddingSession: biddingSession ?? this.biddingSession,
      bidWinnerIndex:
          clearBidWinner ? null : (bidWinnerIndex ?? this.bidWinnerIndex),
      winningBid: clearWinningBid ? null : (winningBid ?? this.winningBid),
      trumpSuit: trumpSuit ?? this.trumpSuit,
      currentTrick: currentTrick ?? this.currentTrick,
      isTrumpBroken: isTrumpBroken ?? this.isTrumpBroken,
      playedCardsInRound: playedCardsInRound ?? this.playedCardsInRound,
      collectingWinnerSeat: clearCollectingWinner
          ? null
          : (collectingWinnerSeat ?? this.collectingWinnerSeat),
      lastRoundBreakdown: lastRoundBreakdown ?? this.lastRoundBreakdown,
      statusBanner:
          clearStatusBanner ? null : (statusBanner ?? this.statusBanner),
    );
  }
}
