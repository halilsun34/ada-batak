import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_notifier.dart';

enum GameSoundEffect {
  cardPlay('sounds/card_play.wav'),
  trickWin('sounds/trick_win.wav'),
  bidClick('sounds/bid_click.wav'),
  roundWin('sounds/round_win.wav');

  final String assetPath;
  const GameSoundEffect(this.assetPath);
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  final Ref _ref;
  AudioPlayer? _player;

  AudioService(this._ref);

  Future<void> play(GameSoundEffect effect) async {
    final soundEnabled = _ref.read(settingsProvider).soundEnabled;
    if (!soundEnabled) return;

    // Widget test ortamında platform kanal hatası vermemesi için güvenli sarmalayıcı
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource(effect.assetPath));
    } catch (e) {
      debugPrint('Audio playback skipped: $e');
    }
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }
}
