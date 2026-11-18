import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bot/bot_bidding_logic.dart';
import '../domain/bot/bot_play_strategy.dart';
import '../domain/models/bid.dart';
import '../domain/models/deck.dart';
import '../domain/models/game_settings.dart';
import '../domain/models/playing_card.dart';
import '../domain/models/trick.dart';
import '../domain/rules/move_validator.dart';
import '../domain/rules/score_calculator.dart';
import '../domain/rules/trick_evaluator.dart';
import 'audio_service.dart';
import 'game_state.dart';
import 'settings_notifier.dart';

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

class GameNotifier extends Notifier<GameState> {
  final Random _random = Random();
  Timer? _botTimer;
  Timer? _trickCollectTimer;

  @override
  GameState build() {
    ref.onDispose(() {
      _botTimer?.cancel();
      _trickCollectTimer?.cancel();
    });
    final settings = ref.read(settingsProvider);
    final initial = GameState.initial(
      targetRounds: settings.targetRounds,
      gameMode: settings.gameMode,
      equalCardsOrder: settings.equalCardsOrder,
    );
    Future.microtask(_scheduleBotTurnIfNeeded);
    return initial;
  }

  /// Yeni bir oyun başlatır (tüm puanları sıfırlar ve 1. turdan başlar)
  void startNewGame({GameMode? modeOverride}) {
    _botTimer?.cancel();
    _trickCollectTimer?.cancel();
    final settings = ref.read(settingsProvider);
    final activeMode = modeOverride ?? settings.gameMode;
    state = GameState.initial(
      targetRounds: settings.targetRounds,
      gameMode: activeMode,
      equalCardsOrder: settings.equalCardsOrder,
    );
    _scheduleBotTurnIfNeeded();
  }

  /// El sıralama tercihi (Eş Kartları: Altta/Üstte) değiştiğinde mevcut elleri anında yeniden sıralar
  void resortHandsForEqualOrder(EqualCardsOrder order) {
    final updatedPlayers = state.players.map((p) {
      return p.copyWith(hand: Deck.sortHand(p.hand, order: order));
    }).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  /// Hedef tur sayısı değiştiğinde state'i günceller
  void syncTargetRounds(int newTargetRounds) {
    state = state.copyWith(targetRounds: newTargetRounds);
  }

  /// Tur sonu ekranından bir sonraki tura geçer veya oyun bittiyse yeni oyun başlatır
  void proceedToNextRoundOrNewGame() {
    if (state.phase == GamePhase.gameOver) {
      startNewGame();
      return;
    }
    if (state.phase != GamePhase.roundOver) return;

    _botTimer?.cancel();
    _trickCollectTimer?.cancel();
    final settings = ref.read(settingsProvider);
    final nextRound = state.currentRound + 1;
    final nextStarter = nextRound - 1;
    final scores = state.players.map((p) => p.totalScore).toList();

    state = GameState.initial(
      targetRounds: settings.targetRounds,
      gameMode: state.gameMode,
      equalCardsOrder: settings.equalCardsOrder,
      startingPlayerIndex: nextStarter,
      currentRound: nextRound,
      existingTotalScores: scores,
    );
    _scheduleBotTurnIfNeeded();
  }

  /// Kullanıcının ihale teklifi vermesi
  void submitUserBid(int amount) {
    if (state.phase != GamePhase.bidding) return;
    if (state.currentPlayer.isBot) return;
    if (!state.biddingSession.canBid(amount)) return;

    ref.read(audioServiceProvider).play(GameSoundEffect.bidClick);
    _applyBidAction(BidAction.bid(state.currentTurnIndex, amount));
  }

  /// Kullanıcının PAS geçmesi
  void submitUserPass() {
    if (state.phase != GamePhase.bidding) return;
    if (state.currentPlayer.isBot) return;

    ref.read(audioServiceProvider).play(GameSoundEffect.bidClick);
    _applyBidAction(BidAction.pass(state.currentTurnIndex));
  }

  /// İhaleyi kazanan kullanıcının koz seçmesi
  void selectTrumpSuit(CardSuit suit) {
    if (state.phase != GamePhase.choosingTrump) return;
    final winnerIdx = state.bidWinnerIndex ?? 0;

    ref.read(audioServiceProvider).play(GameSoundEffect.bidClick);
    if (state.gameMode == GameMode.gommeli3lu ||
        state.gameMode == GameMode.ucBesSekiz) {
      _transitionToBuryingCards(winnerIdx, suit);
      return;
    }

    state = state.copyWith(
      trumpSuit: suit,
      phase: GamePhase.playing,
      currentTurnIndex: winnerIdx,
      statusBanner:
          'İhale: ${state.players[winnerIdx].name} (${state.winningBid}) • Koz: ${suit.symbol}',
    );
    _scheduleBotTurnIfNeeded();
  }

  /// Gömmeli oyunda kullanıcının gömmek için kart seçmesi / seçimi kaldırması
  void toggleCardToBury(PlayingCard card) {
    if (state.phase != GamePhase.buryingCards) return;
    if (state.currentPlayer.isBot) return;

    final currentSelected = List<PlayingCard>.from(state.selectedToBury);
    if (currentSelected.contains(card)) {
      currentSelected.remove(card);
    } else if (currentSelected.length < 4) {
      currentSelected.add(card);
    }
    state = state.copyWith(selectedToBury: currentSelected);
  }

  /// Kullanıcının seçtiği 4 kartı gömerek oyunu başlatması
  void confirmUserBuryCards() {
    if (state.phase != GamePhase.buryingCards) return;
    if (state.selectedToBury.length != 4) return;

    final playerIdx = state.currentTurnIndex;
    _completeBuryingCards(playerIdx, state.selectedToBury);
  }

  /// Kullanıcının elinden bir karta dokunması (Gömme aşamasında seçer, Oynama aşamasında atar)
  void onUserCardTapped(PlayingCard card) {
    if (state.phase == GamePhase.buryingCards) {
      toggleCardToBury(card);
      return;
    }
    playUserCard(card);
  }

  /// Kullanıcının elinden bir karta dokunarak ortaya atması
  void playUserCard(PlayingCard card) {
    if (state.phase != GamePhase.playing) return;
    if (state.collectingWinnerSeat != null) return;
    final player = state.currentPlayer;
    if (player.isBot) return;

    final settings = ref.read(settingsProvider);
    final isAllowed = MoveValidator.isCardPlayable(
      card: card,
      hand: player.hand,
      currentTrick: state.currentTrick,
      trumpSuit: state.trumpSuit,
      isTrumpBroken: state.isTrumpBroken,
      mustBreakTrump: settings.mustBreakTrump,
    );

    if (!isAllowed) return;
    _playCardInternal(player.id, card);
  }

  void _playCardInternal(int playerIndex, PlayingCard card) {
    ref.read(audioServiceProvider).play(GameSoundEffect.cardPlay);
    final player = state.players[playerIndex];
    final nextHand = List<PlayingCard>.from(player.hand)..remove(card);

    final updatedPlayers = [...state.players];
    updatedPlayers[playerIndex] = player.copyWith(hand: nextHand);

    final nextTrick = state.currentTrick.addCard(
      playerId: player.id,
      seat: player.seat,
      card: card,
    );

    final nextTrumpBroken =
        state.isTrumpBroken || (card.suit == state.trumpSuit);
    final nextPlayedSet = {...state.playedCardsInRound, card};

    if (nextTrick.isComplete) {
      final winningEntry = TrickEvaluator.evaluateWinner(
        trick: nextTrick,
        trumpSuit: state.trumpSuit,
      );

      state = state.copyWith(
        players: updatedPlayers,
        currentTrick: nextTrick,
        isTrumpBroken: nextTrumpBroken,
        playedCardsInRound: nextPlayedSet,
      );

      _trickCollectTimer?.cancel();
      _trickCollectTimer = Timer(const Duration(milliseconds: 620), () {
        ref.read(audioServiceProvider).play(GameSoundEffect.trickWin);
        state = state.copyWith(collectingWinnerSeat: winningEntry.seat);
        _trickCollectTimer = Timer(const Duration(milliseconds: 280), () {
          _completeTrickCollection(winningEntry.playerId);
        });
      });
      return;
    }

    final nextTurn = (playerIndex + 1) % state.players.length;
    state = state.copyWith(
      players: updatedPlayers,
      currentTrick: nextTrick,
      currentTurnIndex: nextTurn,
      isTrumpBroken: nextTrumpBroken,
      playedCardsInRound: nextPlayedSet,
    );

    _scheduleBotTurnIfNeeded();
  }

  void _completeTrickCollection(int winnerPlayerId) {
    final updatedPlayers = [...state.players];
    final winner = updatedPlayers[winnerPlayerId];
    updatedPlayers[winnerPlayerId] = winner.copyWith(
      tricksWon: winner.tricksWon + 1,
    );

    final allHandsEmpty = updatedPlayers.every((p) => p.hand.isEmpty);

    if (allHandsEmpty) {
      ref.read(audioServiceProvider).play(GameSoundEffect.roundWin);
      final breakdown = ScoreCalculator.calculateRoundScores(
        players: updatedPlayers,
        gameMode: state.gameMode,
        bidWinnerIndex: state.bidWinnerIndex,
        winningBid: state.winningBid,
      );

      final scoredPlayers = List.generate(updatedPlayers.length, (i) {
        final b = breakdown[i];
        return updatedPlayers[i].copyWith(totalScore: b.newTotalScore);
      });

      final isGameOver = state.currentRound >= state.targetRounds;

      state = state.copyWith(
        players: scoredPlayers,
        currentTrick: Trick(expectedCardCount: state.players.length),
        clearCollectingWinner: true,
        lastRoundBreakdown: breakdown,
        phase: isGameOver ? GamePhase.gameOver : GamePhase.roundOver,
        statusBanner: isGameOver ? 'Oyun Bitti!' : '${state.currentRound}. Tur Tamamlandı!',
      );
      return;
    }

    state = state.copyWith(
      players: updatedPlayers,
      currentTrick: Trick(expectedCardCount: state.players.length),
      clearCollectingWinner: true,
      currentTurnIndex: winnerPlayerId,
    );

    _scheduleBotTurnIfNeeded();
  }

  void _applyBidAction(BidAction action) {
    final updatedPlayers = [...state.players];
    final p = updatedPlayers[action.playerId];
    if (action.isPass) {
      updatedPlayers[action.playerId] = p.copyWith(
        hasPassedBid: true,
        clearCurrentBid: true,
      );
    } else {
      updatedPlayers[action.playerId] = p.copyWith(
        currentBid: action.amount,
        hasPassedBid: false,
      );
    }

    final nextSession = state.biddingSession.recordAction(action);

    if (nextSession.isComplete) {
      if (nextSession.allPassed) {
        _redealAfterAllPass();
        return;
      }

      final winnerIdx = nextSession.highestBidderIndex!;
      final winningAmount = nextSession.highestBid!;
      final settings = ref.read(settingsProvider);
      final winner = updatedPlayers[winnerIdx];

      state = state.copyWith(
        players: updatedPlayers,
        biddingSession: nextSession,
        bidWinnerIndex: winnerIdx,
        winningBid: winningAmount,
        currentTurnIndex: winnerIdx,
      );

      if (settings.trumpRule == TrumpRule.bidderChooses) {
        if (winner.isBot) {
          final chosenTrump = BotBiddingLogic.chooseBestTrump(winner.hand);
          if (state.gameMode == GameMode.gommeli3lu) {
            _transitionToBuryingCards(winnerIdx, chosenTrump);
          } else {
            state = state.copyWith(
              trumpSuit: chosenTrump,
              phase: GamePhase.playing,
              statusBanner:
                  '${winner.name} ihaleyi $winningAmount ile aldı (${chosenTrump.symbol})',
            );
            _scheduleBotTurnIfNeeded();
          }
        } else {
          state = state.copyWith(
            phase: GamePhase.choosingTrump,
            statusBanner: 'İhaleyi $winningAmount ile aldınız! Koz seçin.',
          );
        }
      } else {
        if (state.gameMode == GameMode.gommeli3lu) {
          _transitionToBuryingCards(winnerIdx, CardSuit.spades);
        } else {
          state = state.copyWith(
            trumpSuit: CardSuit.spades,
            phase: GamePhase.playing,
            statusBanner:
                '${winner.name} ihaleyi $winningAmount ile aldı • Koz: ♠ Maça',
          );
          _scheduleBotTurnIfNeeded();
        }
      }
      return;
    }

    state = state.copyWith(
      players: updatedPlayers,
      biddingSession: nextSession,
      currentTurnIndex: nextSession.currentTurnIndex,
      clearStatusBanner: true,
    );

    _scheduleBotTurnIfNeeded();
  }

  void _transitionToBuryingCards(int winnerIdx, CardSuit trumpSuit) {
    final settings = ref.read(settingsProvider);
    final updatedPlayers = [...state.players];
    final winner = updatedPlayers[winnerIdx];

    final mergedHand = Deck.sortHand(
      [...winner.hand, ...state.kitty],
      order: settings.equalCardsOrder,
    );
    updatedPlayers[winnerIdx] = winner.copyWith(hand: mergedHand);

    state = state.copyWith(
      players: updatedPlayers,
      trumpSuit: trumpSuit,
      currentTurnIndex: winnerIdx,
      selectedToBury: const [],
      phase: GamePhase.buryingCards,
      statusBanner: winner.isBot
          ? '${winner.name} yerdeki 4 kartı aldı ve 4 kart gömüyor...'
          : 'Yerdeki 4 kart elinize eklendi. Gömmek için 4 kart seçin!',
    );

    _scheduleBotTurnIfNeeded();
  }

  void _completeBuryingCards(int playerIdx, List<PlayingCard> cardsToBury) {
    final settings = ref.read(settingsProvider);
    final updatedPlayers = [...state.players];
    final player = updatedPlayers[playerIdx];
    final nextHand = List<PlayingCard>.from(player.hand)
      ..removeWhere((c) => cardsToBury.contains(c));

    updatedPlayers[playerIdx] = player.copyWith(
      hand: Deck.sortHand(nextHand, order: settings.equalCardsOrder),
    );

    state = state.copyWith(
      players: updatedPlayers,
      kitty: cardsToBury,
      selectedToBury: const [],
      phase: GamePhase.playing,
      currentTurnIndex: playerIdx,
      statusBanner:
          '${player.name} 4 kart gömdü • Koz: ${state.trumpSuit.symbol} ${state.trumpSuit.turkishName}',
    );

    _scheduleBotTurnIfNeeded();
  }

  void _redealAfterAllPass() {
    final settings = ref.read(settingsProvider);
    final nextStarter =
        (state.biddingSession.startingPlayerIndex + 1) % state.players.length;
    final scores = state.players.map((p) => p.totalScore).toList();

    state = GameState.initial(
      targetRounds: settings.targetRounds,
      gameMode: state.gameMode,
      equalCardsOrder: settings.equalCardsOrder,
      startingPlayerIndex: nextStarter,
      currentRound: state.currentRound,
      existingTotalScores: scores,
    ).copyWith(
      statusBanner: 'Herkes PAS geçti, el yeniden dağıtıldı!',
    );

    _scheduleBotTurnIfNeeded();
  }

  void _scheduleBotTurnIfNeeded() {
    _botTimer?.cancel();
    if (!state.currentPlayer.isBot) return;
    if (state.collectingWinnerSeat != null) return;

    // Botun düşünme süresi 0.5 - 1.2 sn arası rastgele
    final delayMs = 500 + _random.nextInt(701);

    if (state.phase == GamePhase.bidding) {
      _botTimer = Timer(Duration(milliseconds: delayMs), _executeBotBid);
    } else if (state.phase == GamePhase.buryingCards) {
      _botTimer = Timer(Duration(milliseconds: delayMs), _executeBotBury);
    } else if (state.phase == GamePhase.playing) {
      _botTimer = Timer(Duration(milliseconds: delayMs), _executeBotPlayCard);
    }
  }

  void _executeBotBid() {
    if (state.phase != GamePhase.bidding) return;
    final bot = state.currentPlayer;
    if (!bot.isBot) return;

    final settings = ref.read(settingsProvider);
    final minBid = state.biddingSession.minAllowedBid;
    final maxBid = state.biddingSession.maxAllowedBid;

    final int? proposedBid = settings.difficulty == BotDifficulty.hard
        ? BotBiddingLogic.decideBidHard(
            hand: bot.hand,
            currentHighestBid: state.biddingSession.highestBid,
            minBid: minBid,
            maxBid: maxBid,
          )
        : BotBiddingLogic.decideBidEasy(
            hand: bot.hand,
            currentHighestBid: state.biddingSession.highestBid,
            minBid: minBid,
            maxBid: maxBid,
          );

    if (proposedBid != null && state.biddingSession.canBid(proposedBid)) {
      _applyBidAction(BidAction.bid(bot.id, proposedBid));
    } else {
      _applyBidAction(BidAction.pass(bot.id));
    }
  }

  void _executeBotBury() {
    if (state.phase != GamePhase.buryingCards) return;
    final bot = state.currentPlayer;
    if (!bot.isBot) return;

    final chosenTrump = state.gameMode == GameMode.ucBesSekiz
        ? BotBiddingLogic.chooseBestTrump(bot.hand)
        : state.trumpSuit;

    state = state.copyWith(trumpSuit: chosenTrump);
    final toBury = BotBiddingLogic.pickCardsToBury(
      hand20: bot.hand,
      trumpSuit: chosenTrump,
    );
    _completeBuryingCards(bot.id, toBury);
  }

  void _executeBotPlayCard() {
    if (state.phase != GamePhase.playing) return;
    if (state.collectingWinnerSeat != null) return;
    final bot = state.currentPlayer;
    if (!bot.isBot || bot.hand.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final isEsli = state.gameMode == GameMode.esli;
    final partnerId = isEsli && state.players.length == 4
        ? (bot.id + 2) % 4
        : null;

    final chosen = BotPlayStrategy.chooseCardToPlay(
      botId: bot.id,
      hand: bot.hand,
      currentTrick: state.currentTrick,
      trumpSuit: state.trumpSuit,
      isTrumpBroken: state.isTrumpBroken,
      mustBreakTrump: settings.mustBreakTrump,
      difficulty: settings.difficulty,
      playedCardsInRound: state.playedCardsInRound,
      isPartnershipMode: isEsli,
      partnerId: partnerId,
    );

    _playCardInternal(bot.id, chosen);
  }
}
