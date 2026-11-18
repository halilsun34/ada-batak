import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/game_notifier.dart';
import '../../application/game_state.dart';
import '../../application/settings_notifier.dart';
import '../../domain/models/game_settings.dart';
import '../../domain/models/player.dart';
import '../../domain/models/playing_card.dart';
import '../theme/table_theme.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/bury_cards_panel.dart';
import '../widgets/center_trick_area.dart';
import '../widgets/fanned_hand_widget.dart';
import '../widgets/felt_table_background.dart';
import '../widgets/how_to_play_modal.dart';
import '../widgets/scoreboard_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/wooden_player_badge.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _isSettingsOpen = false;
  bool _isHowToPlayOpen = false;

  Future<void> _onModeChangeRequested(GameMode newMode) async {
    final currentSettings = ref.read(settingsProvider);
    if (currentSettings.gameMode == newMode) {
      setState(() => _isSettingsOpen = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF232522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFD59B1A), width: 1.5),
        ),
        title: const Text(
          'Yeni Oyun Başlatılsın mı?',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '${newMode.title} moduna geçildiğinde mevcut oyun sıfırlanacak ve yeni oyun başlatılacaktır.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_mode_change_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'İPTAL',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_mode_change_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'YENİ OYUN BAŞLAT',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(settingsProvider.notifier).setGameMode(newMode);
      ref.read(gameProvider.notifier).startNewGame(modeOverride: newMode);
      setState(() => _isSettingsOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final gameState = ref.watch(gameProvider);
    final tableTheme = TableThemeData.fromType(settings.tableTheme);

    final southPlayer = gameState.playerBySeat(PlayerSeat.south);
    final westPlayer = gameState.playerBySeat(PlayerSeat.west);
    final northPlayer = gameState.playerBySeat(PlayerSeat.north);
    final eastPlayer = gameState.playerBySeat(PlayerSeat.east);

    final playableCards = southPlayer == null
        ? const <PlayingCard>{}
        : gameState.validCardsForPlayer(
            southPlayer,
            mustBreakTrump: settings.mustBreakTrump,
          );

    // Yardım açık ise ve sıra kullanıcıdaysa oynanamayacak kartlar soluklaştırılır
    final Set<PlayingCard>? displayedPlayableSet =
        (settings.playHelpEnabled &&
                gameState.phase == GamePhase.playing &&
                gameState.currentPlayer.seat == PlayerSeat.south &&
                gameState.collectingWinnerSeat == null)
            ? playableCards
            : null;

    return Scaffold(
      body: FeltTableBackground(
        theme: tableTheme,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomDeckHeight = (constraints.maxHeight * 0.28).clamp(
                185.0,
                250.0,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Üst Oyuncu (BORA - 4 kişilik modlarda)
                  if (northPlayer != null)
                    Align(
                      alignment: Alignment.topCenter,
                      child: WoodenPlayerBadge(
                        key: const Key('badge_north'),
                        player: northPlayer,
                        isCurrentTurn:
                            gameState.currentPlayer.seat == PlayerSeat.north,
                        isBidWinner: gameState.bidWinnerIndex == northPlayer.id,
                        statusSubtitle: gameState.badgeSubtitleFor(northPlayer),
                        theme: tableTheme,
                      ),
                    ),

                  // Sol Oyuncu (ALP)
                  if (westPlayer != null)
                    Align(
                      alignment: const Alignment(-1.0, -0.22),
                      child: WoodenPlayerBadge(
                        key: const Key('badge_west'),
                        player: westPlayer,
                        isCurrentTurn:
                            gameState.currentPlayer.seat == PlayerSeat.west,
                        isBidWinner: gameState.bidWinnerIndex == westPlayer.id,
                        statusSubtitle: gameState.badgeSubtitleFor(westPlayer),
                        theme: tableTheme,
                      ),
                    ),

                  // Sağ Oyuncu (DENİZ)
                  if (eastPlayer != null)
                    Align(
                      alignment: const Alignment(1.0, -0.22),
                      child: WoodenPlayerBadge(
                        key: const Key('badge_east'),
                        player: eastPlayer,
                        isCurrentTurn:
                            gameState.currentPlayer.seat == PlayerSeat.east,
                        isBidWinner: gameState.bidWinnerIndex == eastPlayer.id,
                        statusSubtitle: gameState.badgeSubtitleFor(eastPlayer),
                        theme: tableTheme,
                      ),
                    ),

                  // Ortadaki atılan kartlar (AnimatedPositioned ile)
                  if (gameState.phase == GamePhase.playing)
                    Align(
                      alignment: const Alignment(0.0, -0.22),
                      child: CenterTrickArea(
                        currentTrick: gameState.currentTrick,
                        collectingWinnerSeat: gameState.collectingWinnerSeat,
                      ),
                    ),

                  // Orta alan: İhale Paneli
                  if (gameState.phase == GamePhase.bidding)
                    Align(
                      alignment: const Alignment(0.0, -0.26),
                      child: BiddingPanel(
                        currentHighestBid:
                            gameState.biddingSession.highestBid,
                        isUserTurn: !gameState.currentPlayer.isBot,
                        onBidSelected: (amount) {
                          ref
                              .read(gameProvider.notifier)
                              .submitUserBid(amount);
                        },
                        onPassSelected: () {
                          ref.read(gameProvider.notifier).submitUserPass();
                        },
                      ),
                    ),

                  // Orta alan: Koz Seçim Paneli
                  if (gameState.phase == GamePhase.choosingTrump)
                    Align(
                      alignment: const Alignment(0.0, -0.26),
                      child: TrumpPickerPanel(
                        onTrumpSelected: (suit) {
                          ref
                              .read(gameProvider.notifier)
                              .selectTrumpSuit(suit);
                        },
                      ),
                    ),

                  // Orta alan: Gömmeli 3'lü veya 3-5-8 Kart Gömme Paneli
                  if (gameState.phase == GamePhase.buryingCards &&
                      !gameState.currentPlayer.isBot)
                    Align(
                      alignment: const Alignment(0.0, -0.26),
                      child: BuryCardsPanel(
                        selectedToBury: gameState.selectedToBury,
                        onConfirmBury: () {
                          ref
                              .read(gameProvider.notifier)
                              .confirmUserBuryCards();
                        },
                      ),
                    ),

                  // Orta alan: Tur Sonu veya Oyun Sonu Puan Tablosu
                  if (gameState.phase == GamePhase.roundOver ||
                      gameState.phase == GamePhase.gameOver)
                    Align(
                      alignment: const Alignment(0.0, -0.24),
                      child: ScoreboardModal(
                        currentRound: gameState.currentRound,
                        targetRounds: gameState.targetRounds,
                        isGameOver: gameState.phase == GamePhase.gameOver,
                        players: gameState.players,
                        lastRoundBreakdown: gameState.lastRoundBreakdown,
                        onNextRoundOrNewGame: () {
                          ref
                              .read(gameProvider.notifier)
                              .proceedToNextRoundOrNewGame();
                        },
                      ),
                    ),

                  // Durum bilgi şeridi (ör. Herkes pas geçti / İhaleyi kim aldı)
                  if (gameState.statusBanner != null)
                    Positioned(
                      top: 52,
                      left: 44,
                      right: 44,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tableTheme.goldBorderColor
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              gameState.statusBanner!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFF59D),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Sol alt/orta üstü: Tur sayacı rozeti (örn. 1/5)
                  Positioned(
                    left: 14,
                    bottom: bottomDeckHeight + 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC111A22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tableTheme.goldBorderColor
                              .withValues(alpha: 0.70),
                          width: 1.4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.style_rounded,
                            size: 16,
                            color: tableTheme.goldBorderColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            key: const Key('round_counter_text'),
                            '${gameState.currentRound}/${settings.targetRounds}',
                            style: const TextStyle(
                              color: Color(0xFFFFF59D),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sağ alt (el üstü): Ayarlar (dişli) rozet butonu
                  Positioned(
                    right: 14,
                    bottom: bottomDeckHeight + 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('settings_gear_button'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _isSettingsOpen = !_isSettingsOpen;
                            _isHowToPlayOpen = false;
                          });
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xE61E2B38),
                                Color(0xE60F171E),
                              ],
                            ),
                            border: Border.all(
                              color: tableTheme.goldBorderColor
                                  .withValues(alpha: 0.75),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: tableTheme.goldBorderColor,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt Oyuncu (SİZ) etiketi + Ahşap El Yelpazesi Tabanı + "Batak Club" barı
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (southPlayer != null)
                          WoodenPlayerBadge(
                            key: const Key('badge_south'),
                            player: southPlayer,
                            isCurrentTurn:
                                gameState.currentPlayer.seat == PlayerSeat.south,
                            isBidWinner:
                                gameState.bidWinnerIndex == southPlayer.id,
                            statusSubtitle:
                                gameState.badgeSubtitleFor(southPlayer),
                            theme: tableTheme,
                          ),
                        _BottomWoodDeckArea(
                          height: bottomDeckHeight,
                          theme: tableTheme,
                          hand: southPlayer?.hand ?? const [],
                          playableCards: displayedPlayableSet,
                          selectedCards: gameState.selectedToBury.toSet(),
                          equalCardsOrder: settings.equalCardsOrder,
                          onCardTap: (card) {
                            ref
                                .read(gameProvider.notifier)
                                .onUserCardTapped(card);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Açılır Ayarlar Menüsü (Dişli butonuna basıldığında)
                  if (_isSettingsOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _isSettingsOpen = false),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: GestureDetector(
                            onTap: () {}, // İçeri tıklayınca kapanmasın
                            child: SettingsModal(
                              settings: settings,
                              onGameModeSelected: _onModeChangeRequested,
                              onHowToPlayTap: () {
                                setState(() {
                                  _isSettingsOpen = false;
                                  _isHowToPlayOpen = true;
                                });
                              },
                              onTogglePlayHelp: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .togglePlayHelp();
                              },
                              onToggleEqualCardsOrder: () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .toggleEqualCardsOrder();
                                final updated = ref.read(settingsProvider);
                                ref
                                    .read(gameProvider.notifier)
                                    .resortHandsForEqualOrder(
                                      updated.equalCardsOrder,
                                    );
                              },
                              onToggleSound: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .toggleSound();
                              },
                              onCycleTargetRounds: () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .cycleTargetRounds();
                                final updated = ref.read(settingsProvider);
                                ref
                                    .read(gameProvider.notifier)
                                    .syncTargetRounds(updated.targetRounds);
                              },
                              onToggleDifficulty: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .toggleDifficulty();
                              },
                              onToggleTrumpRule: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .toggleTrumpRule();
                              },
                              onSwitchTheme: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .switchTableTheme();
                              },
                              onClose: () =>
                                  setState(() => _isSettingsOpen = false),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // "Nasıl Oynanır" Rehber Ekranı
                  if (_isHowToPlayOpen)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: HowToPlayModal(
                          onClose: () =>
                              setState(() => _isHowToPlayOpen = false),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomWoodDeckArea extends StatelessWidget {
  final double height;
  final TableThemeData theme;
  final List<PlayingCard> hand;
  final Set<PlayingCard>? playableCards;
  final Set<PlayingCard> selectedCards;
  final EqualCardsOrder equalCardsOrder;
  final ValueChanged<PlayingCard>? onCardTap;

  const _BottomWoodDeckArea({
    required this.height,
    required this.theme,
    required this.hand,
    this.playableCards,
    this.selectedCards = const {},
    required this.equalCardsOrder,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _CurvedWoodDeckPainter(theme: theme),
          ),
          // 2 sıralı yelpaze el kartları
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            bottom: 34,
            child: FannedHandWidget(
              key: const Key('south_fanned_hand'),
              cards: hand,
              playableCards: playableCards,
              selectedCards: selectedCards,
              equalCardsOrder: equalCardsOrder,
              onCardTap: onCardTap,
            ),
          ),
          // En altta "Batak Club" oymalı/kabartmalı ahşap bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.woodDarkGrainColor.withValues(alpha: 0.88),
                    const Color(0xFF240C02),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: theme.goldBorderColor.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ada Batak',
                    style: TextStyle(
                      color: theme.goldBorderColor.withValues(alpha: 0.52),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: theme.goldBorderColor.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedWoodDeckPainter extends CustomPainter {
  final TableThemeData theme;

  const _CurvedWoodDeckPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, 14)
      ..quadraticBezierTo(w / 2, -12, w, 14)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(path, Colors.black, 8, false);

    canvas.save();
    canvas.clipPath(path);

    final rect = Offset.zero & size;
    final woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          theme.woodDarkGrainColor,
          theme.woodBaseColor,
          theme.woodHighlightColor,
          theme.woodBaseColor,
          theme.woodDarkGrainColor,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, woodPaint);

    // Dikey ahşap tahta çizgileri
    final plankPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.1;

    for (double x = 0; x < w; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(x + 2, h), plankPaint);
    }

    canvas.restore();

    final topRimPaint = Paint()
      ..color = theme.goldBorderColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final rimPath = Path()
      ..moveTo(0, 14)
      ..quadraticBezierTo(w / 2, -12, w, 14);
    canvas.drawPath(rimPath, topRimPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedWoodDeckPainter oldDelegate) =>
      oldDelegate.theme.type != theme.type;
}
