/// Oyun modları (Batak varyasyonları)
enum GameMode {
  ihaleli('İHALELİ OYUN', 4),
  ihalesiz('İHALESİZ OYUN', 4),
  esli('EŞLİ OYUN', 4),
  gommeli3lu('GÖMMELİ - 3LÜ OYUN', 3),
  ucBesSekiz('3-5-8 OYUN', 3);

  final String title;
  final int playerCount;
  const GameMode(this.title, this.playerCount);
}

/// Masa teması (en az 2 tema: Yeşil ve Mavi masa)
enum TableThemeType {
  emeraldGreen('Yeşil Masa'),
  royalBlue('Mavi Masa');

  final String label;
  const TableThemeType(this.label);

  TableThemeType get next => this == TableThemeType.emeraldGreen
      ? TableThemeType.royalBlue
      : TableThemeType.emeraldGreen;
}

/// Bot zorluk seviyesi
enum BotDifficulty {
  easy('KOLAY OYUN'),
  hard('ZOR OYUN');

  final String label;
  const BotDifficulty(this.label);

  BotDifficulty get toggled =>
      this == BotDifficulty.hard ? BotDifficulty.easy : BotDifficulty.hard;
}

/// Eş kartların (veya alt/üst el sırasının) dizilim tercihi
enum EqualCardsOrder {
  bottom('EŞ KARTLARI: ALTTA'),
  top('EŞ KARTLARI: ÜSTTE');

  final String label;
  const EqualCardsOrder(this.label);

  EqualCardsOrder get toggled => this == EqualCardsOrder.bottom
      ? EqualCardsOrder.top
      : EqualCardsOrder.bottom;
}

/// Koz seçim kuralı
enum TrumpRule {
  alwaysSpades('KOZ: MAÇA (KLASİK)'),
  bidderChooses('KOZ: İHALEYİ ALAN SEÇER');

  final String label;
  const TrumpRule(this.label);

  TrumpRule get toggled => this == TrumpRule.alwaysSpades
      ? TrumpRule.bidderChooses
      : TrumpRule.alwaysSpades;
}

/// Cihazda shared_preferences ile saklanan tüm oyun ayarları.
class GameSettings {
  final GameMode gameMode;
  final bool playHelpEnabled;
  final EqualCardsOrder equalCardsOrder;
  final bool soundEnabled;
  final int targetRounds;
  final BotDifficulty difficulty;
  final TableThemeType tableTheme;
  final TrumpRule trumpRule;
  final bool mustBreakTrump;

  const GameSettings({
    this.gameMode = GameMode.ihaleli,
    this.playHelpEnabled = true,
    this.equalCardsOrder = EqualCardsOrder.bottom,
    this.soundEnabled = true,
    this.targetRounds = 5,
    this.difficulty = BotDifficulty.hard,
    this.tableTheme = TableThemeType.emeraldGreen,
    this.trumpRule = TrumpRule.alwaysSpades,
    this.mustBreakTrump = true,
  });

  static const List<int> availableTargetRounds = [3, 5, 7, 10, 15];

  int get nextTargetRounds {
    final idx = availableTargetRounds.indexOf(targetRounds);
    if (idx == -1 || idx + 1 >= availableTargetRounds.length) {
      return availableTargetRounds.first;
    }
    return availableTargetRounds[idx + 1];
  }

  GameSettings copyWith({
    GameMode? gameMode,
    bool? playHelpEnabled,
    EqualCardsOrder? equalCardsOrder,
    bool? soundEnabled,
    int? targetRounds,
    BotDifficulty? difficulty,
    TableThemeType? tableTheme,
    TrumpRule? trumpRule,
    bool? mustBreakTrump,
  }) {
    return GameSettings(
      gameMode: gameMode ?? this.gameMode,
      playHelpEnabled: playHelpEnabled ?? this.playHelpEnabled,
      equalCardsOrder: equalCardsOrder ?? this.equalCardsOrder,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      targetRounds: targetRounds ?? this.targetRounds,
      difficulty: difficulty ?? this.difficulty,
      tableTheme: tableTheme ?? this.tableTheme,
      trumpRule: trumpRule ?? this.trumpRule,
      mustBreakTrump: mustBreakTrump ?? this.mustBreakTrump,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettings &&
          runtimeType == other.runtimeType &&
          gameMode == other.gameMode &&
          playHelpEnabled == other.playHelpEnabled &&
          equalCardsOrder == other.equalCardsOrder &&
          soundEnabled == other.soundEnabled &&
          targetRounds == other.targetRounds &&
          difficulty == other.difficulty &&
          tableTheme == other.tableTheme &&
          trumpRule == other.trumpRule &&
          mustBreakTrump == other.mustBreakTrump;

  @override
  int get hashCode => Object.hash(
        gameMode,
        playHelpEnabled,
        equalCardsOrder,
        soundEnabled,
        targetRounds,
        difficulty,
        tableTheme,
        trumpRule,
        mustBreakTrump,
      );
}
