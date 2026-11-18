import 'package:flutter/material.dart';
import '../../domain/models/playing_card.dart';

/// Gömmeli 3'lü veya 3-5-8 oyununda ihaleyi (veya 8 hedefini) alan
/// kullanıcının yerdeki 4 kartı eline kattıktan sonra 4 kart seçip
/// gömmesini sağlayan orta panel widget'ı.
class BuryCardsPanel extends StatelessWidget {
  final List<PlayingCard> selectedToBury;
  final VoidCallback onConfirmBury;

  const BuryCardsPanel({
    super.key,
    required this.selectedToBury,
    required this.onConfirmBury,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = 4 - selectedToBury.length;
    final canConfirm = selectedToBury.length == 4;

    return Container(
      key: const Key('bury_cards_panel'),
      width: 274,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xEA1E201D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD59B1A),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '4 KART GÖMÜN',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canConfirm
                ? 'Seçilen 4 kart gömülmeye hazır!'
                : 'Elinizden gömmek için $remaining kart daha seçin.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(4, (idx) {
              final hasCard = idx < selectedToBury.length;
              final card = hasCard ? selectedToBury[idx] : null;
              return Container(
                width: 48,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasCard
                      ? const Color(0xFFF5F5F7)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasCard
                        ? const Color(0xFFFFB300)
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: card == null
                    ? const Text(
                        '?',
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : Text(
                        '${card.suit.symbol}${card.rank.label}',
                        style: TextStyle(
                          color: card.isRed
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF1E2229),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              );
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              key: const Key('confirm_bury_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canConfirm
                    ? const Color(0xFF00C853)
                    : Colors.grey.shade700,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: canConfirm ? onConfirmBury : null,
              child: const Text(
                'SEÇİLENLERİ GÖM VE BAŞLA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
