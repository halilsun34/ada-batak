import 'package:flutter/material.dart';
import '../../domain/models/player.dart';
import '../../domain/rules/score_calculator.dart';

/// Tur sonu veya Oyun sonu sıralama ve puan tablosu ekranı/panel widget'ı.
class ScoreboardModal extends StatelessWidget {
  final int currentRound;
  final int targetRounds;
  final bool isGameOver;
  final List<Player> players;
  final List<RoundScoreBreakdown> lastRoundBreakdown;
  final VoidCallback onNextRoundOrNewGame;

  const ScoreboardModal({
    super.key,
    required this.currentRound,
    required this.targetRounds,
    required this.isGameOver,
    required this.players,
    required this.lastRoundBreakdown,
    required this.onNextRoundOrNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = ScoreCalculator.rankPlayersByScore(players);

    return Container(
      key: const Key('scoreboard_modal'),
      width: 310,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xEC1B1D1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD59B1A),
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGameOver ? Icons.emoji_events : Icons.leaderboard,
                color: const Color(0xFFFFD54F),
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                isGameOver
                    ? 'OYUN SONU SIRALAMASI'
                    : '$currentRound. TUR SONUCU ($currentRound/$targetRounds)',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          // Sıralama Tablosu Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'OYUNCU',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 66,
                  child: Text(
                    'BU EL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    'TOPLAM',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          ...List.generate(rankedPlayers.length, (index) {
            final player = rankedPlayers[index];
            final breakdown = lastRoundBreakdown
                .where((b) => b.playerId == player.id)
                .firstOrNull;
            final delta = breakdown?.scoreDelta ?? 0;
            final deltaText = delta >= 0 ? '+$delta' : '$delta';
            final isTopWinner = index == 0 && isGameOver;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isTopWinner
                    ? const Color(0x33FFB300)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: isTopWinner
                    ? Border.all(color: const Color(0xFFFFCA28), width: 1.4)
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: index == 0
                            ? const Color(0xFFFFD54F)
                            : Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (breakdown != null)
                          Text(
                            breakdown.bidOrTarget != null
                                ? 'İhale: ${breakdown.bidOrTarget} • Alınan: ${breakdown.tricksWon}'
                                : 'Alınan El: ${breakdown.tricksWon}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 66,
                    child: Text(
                      deltaText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: delta >= 0
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF5252),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${player.totalScore}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFFFF59D),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('scoreboard_continue_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: onNextRoundOrNewGame,
              child: Text(
                isGameOver ? 'YENİ OYUN BAŞLAT' : 'SONRAKİ EL',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
