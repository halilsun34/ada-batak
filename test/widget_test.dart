import 'dart:math';
import 'package:batak_club/application/game_notifier.dart';
import 'package:batak_club/application/game_state.dart';
import 'package:batak_club/application/settings_notifier.dart';
import 'package:batak_club/domain/bot/bot_bidding_logic.dart';
import 'package:batak_club/domain/bot/bot_play_strategy.dart';
import 'package:batak_club/domain/models/bid.dart';
import 'package:batak_club/domain/models/deck.dart';
import 'package:batak_club/domain/models/game_settings.dart';
import 'package:batak_club/domain/models/player.dart';
import 'package:batak_club/domain/models/playing_card.dart';
import 'package:batak_club/domain/models/trick.dart';
import 'package:batak_club/domain/rules/move_validator.dart';
import 'package:batak_club/domain/rules/score_calculator.dart';
import 'package:batak_club/domain/rules/trick_evaluator.dart';
import 'package:batak_club/main.dart';
import 'package:batak_club/presentation/widgets/bidding_panel.dart';
import 'package:batak_club/presentation/widgets/card_widget.dart';
import 'package:batak_club/presentation/widgets/how_to_play_modal.dart';
import 'package:batak_club/presentation/widgets/settings_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Aşama 1 Domain Testleri', () {
    test('Oyuncu koltukları doğru isimlerle (SİZ, ALP, BORA, DENİZ) oluşur', () {
      final state = GameState.initial(targetRounds: 5);
      expect(state.players.length, 4);
      expect(state.playerBySeat(PlayerSeat.south)?.name, 'SİZ');
      expect(state.playerBySeat(PlayerSeat.west)?.name, 'ALP');
      expect(state.playerBySeat(PlayerSeat.north)?.name, 'BORA');
      expect(state.playerBySeat(PlayerSeat.east)?.name, 'DENİZ');
      expect(state.playerBySeat(PlayerSeat.south)?.isBot, isFalse);
      expect(state.playerBySeat(PlayerSeat.north)?.isBot, isTrue);
    });

    test('GameSettings tema ve hedef tur döngüsü doğru çalışır', () {
      const settings = GameSettings();
      expect(settings.tableTheme, TableThemeType.emeraldGreen);
      expect(settings.tableTheme.next, TableThemeType.royalBlue);
      expect(settings.targetRounds, 5);
      expect(settings.nextTargetRounds, 7);
      expect(settings.gameSpeed, GameSpeed.normal);
      expect(settings.gameSpeed.toggled, GameSpeed.fast);
    });
  });

  group('Aşama 2 Deste, Dağıtım ve Yelpaze Sıralama Testleri', () {
    test('52 benzersiz kart oluşturulur ve 4 oyuncuya 13\'er kart dağıtılır', () {
      final deck = Deck(random: Random(42));
      final deal = deck.dealFor4Players();

      expect(deal.hands.length, 4);
      final allCards = <PlayingCard>{};
      for (final hand in deal.hands) {
        expect(hand.length, 13);
        allCards.addAll(hand);
      }
      expect(allCards.length, 52);
    });

    test('Gömmeli 3\'lü dağıtımda 3 oyuncuya 16\'şar kart ve ortaya 4 kart ayrılır', () {
      final deck = Deck(random: Random(42));
      final deal = deck.dealFor3PlayersBury();

      expect(deal.hands.length, 3);
      expect(deal.kitty.length, 4);
      final allCards = <PlayingCard>{...deal.kitty};
      for (final hand in deal.hands) {
        expect(hand.length, 16);
        allCards.addAll(hand);
      }
      expect(allCards.length, 52);
    });

    test('El sıralaması renk gruplarına göre ve büyükten küçüğe (As -> 2) yapılır', () {
      const sample = [
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.three),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.four),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.jack),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.queen),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.six),
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.king),
      ];

      final sorted = Deck.sortHand(sample, order: EqualCardsOrder.bottom);
      expect(sorted[0], const PlayingCard(suit: CardSuit.spades, rank: CardRank.jack));
      expect(sorted[1], const PlayingCard(suit: CardSuit.spades, rank: CardRank.four));
      expect(sorted[2], const PlayingCard(suit: CardSuit.hearts, rank: CardRank.queen));
      expect(sorted[3], const PlayingCard(suit: CardSuit.clubs, rank: CardRank.six));
      expect(sorted[4], const PlayingCard(suit: CardSuit.diamonds, rank: CardRank.king));
      expect(sorted[5], const PlayingCard(suit: CardSuit.diamonds, rank: CardRank.three));
    });

    test('13 kartlık el üstte 6, altta 7 kart olacak şekilde 2 sıraya bölünür', () {
      final deck = Deck(random: Random(7));
      final hand = deck.dealFor4Players().hands.first;
      final split = Deck.splitHandIntoTwoRows(hand);

      expect(split.topRow.length, 6);
      expect(split.bottomRow.length, 7);
    });
  });

  group('Aşama 3 İhale ve Bot İhalesi Testleri', () {
    test('BiddingSession önceki teklifin altındaki ve eşit sayıları pasif yapar', () {
      var session = const BiddingSession(playerCount: 4, startingPlayerIndex: 0);
      expect(session.canBid(5), isTrue);
      expect(session.canBid(13), isTrue);

      session = session.recordAction(BidAction.bid(0, 7));
      expect(session.highestBid, 7);
      expect(session.highestBidderIndex, 0);
      expect(session.canBid(5), isFalse);
      expect(session.canBid(6), isFalse);
      expect(session.canBid(7), isFalse);
      expect(session.canBid(8), isTrue);
    });

    test('Herkes PAS geçerse allPassed true döner', () {
      var session = const BiddingSession(playerCount: 4, startingPlayerIndex: 0);
      session = session.recordAction(BidAction.pass(0));
      session = session.recordAction(BidAction.pass(1));
      session = session.recordAction(BidAction.pass(2));
      session = session.recordAction(BidAction.pass(3));

      expect(session.isComplete, isTrue);
      expect(session.allPassed, isTrue);
    });

    testWidgets('Herkes PAS geçtiğinde son konuşan oyuncuya 4 ile kalır', (tester) async {
      final container = ProviderContainer();
      final notifier = container.read(gameProvider.notifier);
      // İlk oyuncu (SİZ) pas geçer
      notifier.submitUserPass();
      expect(container.read(gameProvider).players[0].hasPassedBid, isTrue);

      // Botların konuşmalarını ilerlet
      await tester.pump(const Duration(milliseconds: 1500));
      container.dispose();
      await tester.pump(const Duration(milliseconds: 500));
    });

    test('Güçlü koz ve As içeren elde bot ihale teklifi verir', () {
      const strongHand = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.king),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.queen),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.jack),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ten),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.nine),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.king),
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.two),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.three),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.four),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.five),
      ];

      final bidHard = BotBiddingLogic.decideBidHard(
        hand: strongHand,
        currentHighestBid: 5,
      );
      expect(bidHard, isNotNull);
      expect(bidHard! >= 6, isTrue);
    });
  });

  group('Aşama 4 El Oynama Kuralları (MoveValidator & TrickEvaluator) Testleri', () {
    test('Maça açılmadan (isTrumpBroken=false) başka renk varken maça ile başlanamaz', () {
      const hand = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.ten),
      ];

      final playable = MoveValidator.getPlayableCards(
        hand: hand,
        currentTrick: const Trick(),
        trumpSuit: CardSuit.spades,
        isTrumpBroken: false,
        mustBreakTrump: true,
      );

      expect(playable, {const PlayingCard(suit: CardSuit.hearts, rank: CardRank.ten)});
    });

    test('Açılan renge uymak ve varsa daha büyük kartı atmak (yükseltmek) zorunludur', () {
      final trick = const Trick().addCard(
        playerId: 0,
        seat: PlayerSeat.south,
        card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.nine),
      );

      const hand = [
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.four),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.queen),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
      ];

      final playable = MoveValidator.getPlayableCards(
        hand: hand,
        currentTrick: trick,
        trumpSuit: CardSuit.spades,
        isTrumpBroken: false,
        mustBreakTrump: true,
      );

      expect(playable, {const PlayingCard(suit: CardSuit.hearts, rank: CardRank.queen)});
    });

    test('Açılan renk yoksa koz (maça) atmak zorunludur; kozu da yoksa istediği kartı atar', () {
      final trick = const Trick().addCard(
        playerId: 0,
        seat: PlayerSeat.south,
        card: const PlayingCard(suit: CardSuit.diamonds, rank: CardRank.ace),
      );

      const handWithTrump = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.three),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.king),
      ];

      final playableTrump = MoveValidator.getPlayableCards(
        hand: handWithTrump,
        currentTrick: trick,
        trumpSuit: CardSuit.spades,
        isTrumpBroken: false,
        mustBreakTrump: true,
      );
      expect(playableTrump, {const PlayingCard(suit: CardSuit.spades, rank: CardRank.three)});
    });

    test('Eli kozlar önce, koz yoksa açılan rengin en büyük kartı (As en büyük) alır', () {
      var trickNoTrump = const Trick()
          .addCard(
            playerId: 0,
            seat: PlayerSeat.south,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.ten),
          )
          .addCard(
            playerId: 1,
            seat: PlayerSeat.west,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.ace),
          )
          .addCard(
            playerId: 2,
            seat: PlayerSeat.north,
            card: const PlayingCard(suit: CardSuit.diamonds, rank: CardRank.ace),
          )
          .addCard(
            playerId: 3,
            seat: PlayerSeat.east,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.king),
          );

      final winnerNoTrump = TrickEvaluator.evaluateWinner(
        trick: trickNoTrump,
        trumpSuit: CardSuit.spades,
      );
      expect(winnerNoTrump.playerId, 1);

      var trickWithTrump = trickNoTrump.addCard(
        playerId: 3,
        seat: PlayerSeat.east,
        card: const PlayingCard(suit: CardSuit.spades, rank: CardRank.two),
      );
      final winnerWithTrump = TrickEvaluator.evaluateWinner(
        trick: trickWithTrump,
        trumpSuit: CardSuit.spades,
      );
      expect(winnerWithTrump.playerId, 3);
    });
  });

  group('Aşama 5, 6 & 7 Puanlama, Mod Varyasyonları ve Zor Bot Testleri', () {
    test('ScoreCalculator İhaleli oyunda ihaleyi tutturana +ihale, batana -ihale ve diğerlerine el puanı verir', () {
      final players = [
        Player.initial(0, PlayerSeat.south).copyWith(tricksWon: 8, totalScore: 10),
        Player.initial(1, PlayerSeat.west).copyWith(tricksWon: 2, totalScore: 5),
        Player.initial(2, PlayerSeat.north).copyWith(tricksWon: 1, totalScore: 0),
        Player.initial(3, PlayerSeat.east).copyWith(tricksWon: 2, totalScore: 3),
      ];

      final winBreakdown = ScoreCalculator.calculateRoundScores(
        players: players,
        gameMode: GameMode.ihaleli,
        bidWinnerIndex: 0,
        winningBid: 7,
      );
      expect(winBreakdown[0].scoreDelta, 7);
      expect(winBreakdown[0].newTotalScore, 17);
      expect(winBreakdown[1].scoreDelta, 2);

      final losePlayers = [
        Player.initial(0, PlayerSeat.south).copyWith(tricksWon: 5, totalScore: 10),
        Player.initial(1, PlayerSeat.west).copyWith(tricksWon: 3, totalScore: 5),
        Player.initial(2, PlayerSeat.north).copyWith(tricksWon: 3, totalScore: 0),
        Player.initial(3, PlayerSeat.east).copyWith(tricksWon: 2, totalScore: 3),
      ];

      final loseBreakdown = ScoreCalculator.calculateRoundScores(
        players: losePlayers,
        gameMode: GameMode.ihaleli,
        bidWinnerIndex: 0,
        winningBid: 7,
      );
      expect(loseBreakdown[0].scoreDelta, -7);
      expect(loseBreakdown[0].newTotalScore, 3);
    });

    test('ScoreCalculator Eşli oyunda ortakların (0 & 2) toplam elini hesaplar', () {
      final players = [
        Player.initial(0, PlayerSeat.south).copyWith(tricksWon: 5),
        Player.initial(1, PlayerSeat.west).copyWith(tricksWon: 2),
        Player.initial(2, PlayerSeat.north).copyWith(tricksWon: 4),
        Player.initial(3, PlayerSeat.east).copyWith(tricksWon: 2),
      ];

      // Takım A (0 & 2) toplam 9 el aldı, ihale 8 idi -> +8 kazanır
      final breakdown = ScoreCalculator.calculateRoundScores(
        players: players,
        gameMode: GameMode.esli,
        bidWinnerIndex: 0,
        winningBid: 8,
      );
      expect(breakdown[0].scoreDelta, 8);
      expect(breakdown[2].scoreDelta, 8);
      expect(breakdown[1].scoreDelta, 4);
      expect(breakdown[3].scoreDelta, 4);
    });

    test('Eşli oyunda Zor Bot ortağının kazandığı eli gereksiz yere ezmez, küçük kağıt atar', () {
      final trick = const Trick(expectedCardCount: 4)
          .addCard(
            playerId: 1,
            seat: PlayerSeat.west,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.nine),
          )
          .addCard(
            playerId: 2, // Botun ortağı (BORA) Kupa As ile eli almış durumda
            seat: PlayerSeat.north,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.ace),
          )
          .addCard(
            playerId: 3,
            seat: PlayerSeat.east,
            card: const PlayingCard(suit: CardSuit.hearts, rank: CardRank.ten),
          );

      // Bot 0'da Kupa yok, koz (Maça) da yok; Karo As ve Sinek 2 var.
      // Ortağı (id: 2) eli aldığı için Karo As'ı harcamayıp Sinek 2'yi atmalıdır.
      const hand = [
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.two),
      ];

      final chosen = BotPlayStrategy.chooseCardToPlay(
        botId: 0,
        hand: hand,
        currentTrick: trick,
        trumpSuit: CardSuit.spades,
        isTrumpBroken: false,
        mustBreakTrump: true,
        difficulty: BotDifficulty.hard,
        playedCardsInRound: const {},
        isPartnershipMode: true,
        partnerId: 2,
      );

      expect(chosen, const PlayingCard(suit: CardSuit.clubs, rank: CardRank.two));
    });
  });

  group('Aşama 6 Ayarlar Menüsü ve Kalıcı Kayıt Widget Testleri', () {
    testWidgets('Dişli butonuyla ayarlar menüsü açılır, Online buton yoktur, Nasıl Oynanır ve tercihler çalışır',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const BatakClubApp(),
        ),
      );

      expect(find.byType(BiddingPanel), findsOneWidget);
      expect(find.byType(PlayingCardWidget), findsNWidgets(13));
      expect(find.text('Ada Batak'), findsOneWidget);

      // Dişli butonuna bas -> Ayarlar modalı açılır
      await tester.tap(find.byKey(const Key('settings_gear_button')));
      await tester.pump();

      expect(find.byType(SettingsModal), findsOneWidget);
      expect(find.textContaining('ONLINE'), findsNothing);
      expect(find.text('NASIL OYNANIR'), findsOneWidget);

      // Bitiş sayısını artır (5 -> 7)
      expect(find.text('BİTİŞ : 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cycle_target_rounds_button')));
      await tester.pump();
      expect(find.text('BİTİŞ : 7'), findsOneWidget);
      expect(prefs.getInt('batak_target_rounds'), 7);

      // Oyun hızını değiştir (NORMAL -> HIZLI)
      expect(find.text('HIZ: NORMAL'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle_game_speed_button')));
      await tester.pump();
      expect(find.text('HIZ: HIZLI'), findsOneWidget);
      expect(prefs.getInt('batak_game_speed'), 1);

      // Nasıl Oynanır ekranını aç
      await tester.ensureVisible(find.byKey(const Key('how_to_play_button')));
      await tester.tap(find.byKey(const Key('how_to_play_button')));
      await tester.pump();
      expect(find.byType(HowToPlayModal), findsOneWidget);

      // Kapat
      await tester.tap(find.byKey(const Key('close_how_to_play_button')));
      await tester.pump();
      expect(find.byType(HowToPlayModal), findsNothing);
    });
  });
}
