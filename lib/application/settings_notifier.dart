import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/game_settings.dart';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final settingsProvider =
    NotifierProvider<SettingsNotifier, GameSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<GameSettings> {
  static const _kGameMode = 'batak_game_mode';
  static const _kPlayHelp = 'batak_play_help';
  static const _kEqualCards = 'batak_equal_cards';
  static const _kSound = 'batak_sound';
  static const _kTargetRounds = 'batak_target_rounds';
  static const _kDifficulty = 'batak_difficulty';
  static const _kTableTheme = 'batak_table_theme';
  static const _kTrumpRule = 'batak_trump_rule';
  static const _kMustBreakTrump = 'batak_must_break_trump';

  @override
  GameSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) {
      return const GameSettings();
    }

    final modeIdx = prefs.getInt(_kGameMode) ?? 0;
    final equalIdx = prefs.getInt(_kEqualCards) ?? 0;
    final diffIdx = prefs.getInt(_kDifficulty) ?? 1;
    final themeIdx = prefs.getInt(_kTableTheme) ?? 0;
    final trumpIdx = prefs.getInt(_kTrumpRule) ?? 0;

    return GameSettings(
      gameMode: GameMode.values[modeIdx.clamp(0, GameMode.values.length - 1)],
      playHelpEnabled: prefs.getBool(_kPlayHelp) ?? true,
      equalCardsOrder: EqualCardsOrder
          .values[equalIdx.clamp(0, EqualCardsOrder.values.length - 1)],
      soundEnabled: prefs.getBool(_kSound) ?? true,
      targetRounds: prefs.getInt(_kTargetRounds) ?? 5,
      difficulty:
          BotDifficulty.values[diffIdx.clamp(0, BotDifficulty.values.length - 1)],
      tableTheme:
          TableThemeType.values[themeIdx.clamp(0, TableThemeType.values.length - 1)],
      trumpRule:
          TrumpRule.values[trumpIdx.clamp(0, TrumpRule.values.length - 1)],
      mustBreakTrump: prefs.getBool(_kMustBreakTrump) ?? true,
    );
  }

  Future<void> _save(GameSettings next) async {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;
    await prefs.setInt(_kGameMode, next.gameMode.index);
    await prefs.setBool(_kPlayHelp, next.playHelpEnabled);
    await prefs.setInt(_kEqualCards, next.equalCardsOrder.index);
    await prefs.setBool(_kSound, next.soundEnabled);
    await prefs.setInt(_kTargetRounds, next.targetRounds);
    await prefs.setInt(_kDifficulty, next.difficulty.index);
    await prefs.setInt(_kTableTheme, next.tableTheme.index);
    await prefs.setInt(_kTrumpRule, next.trumpRule.index);
    await prefs.setBool(_kMustBreakTrump, next.mustBreakTrump);
  }

  Future<void> setGameMode(GameMode mode) =>
      _save(state.copyWith(gameMode: mode));

  Future<void> togglePlayHelp() =>
      _save(state.copyWith(playHelpEnabled: !state.playHelpEnabled));

  Future<void> toggleEqualCardsOrder() =>
      _save(state.copyWith(equalCardsOrder: state.equalCardsOrder.toggled));

  Future<void> toggleSound() =>
      _save(state.copyWith(soundEnabled: !state.soundEnabled));

  Future<void> cycleTargetRounds() =>
      _save(state.copyWith(targetRounds: state.nextTargetRounds));

  Future<void> toggleDifficulty() =>
      _save(state.copyWith(difficulty: state.difficulty.toggled));

  Future<void> switchTableTheme() =>
      _save(state.copyWith(tableTheme: state.tableTheme.next));

  Future<void> toggleTrumpRule() =>
      _save(state.copyWith(trumpRule: state.trumpRule.toggled));

  Future<void> toggleMustBreakTrump() =>
      _save(state.copyWith(mustBreakTrump: !state.mustBreakTrump));
}
