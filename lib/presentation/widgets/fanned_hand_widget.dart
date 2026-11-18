import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/deck.dart';
import '../../domain/models/game_settings.dart';
import '../../domain/models/playing_card.dart';
import 'card_widget.dart';

/// Kullanıcının ("SİZ") elindeki kartları iki sıra halinde yelpaze (fan)
/// şeklinde dizen ve dokunma etkileşimini yöneten widget.
class FannedHandWidget extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<PlayingCard>? playableCards;
  final Set<PlayingCard> selectedCards;
  final EqualCardsOrder equalCardsOrder;
  final ValueChanged<PlayingCard>? onCardTap;

  const FannedHandWidget({
    super.key,
    required this.cards,
    this.playableCards,
    this.selectedCards = const {},
    this.equalCardsOrder = EqualCardsOrder.bottom,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final split = Deck.splitHandIntoTwoRows(cards, order: equalCardsOrder);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final cardWidth = (maxWidth * 0.215).clamp(68.0, 92.0);
        final cardHeight = cardWidth * 1.40;

        return SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Üst sıra yelpaze (6 kart)
              if (split.topRow.isNotEmpty)
                Positioned(
                  top: 2,
                  left: 0,
                  right: 0,
                  height: cardHeight + 18,
                  child: _buildFanRow(
                    rowCards: split.topRow,
                    maxWidth: maxWidth,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    rowKeyPrefix: 'top_row',
                  ),
                ),

              // Alt sıra yelpaze (7 kart, üst sıranın alt kısmını hafif örter)
              if (split.bottomRow.isNotEmpty)
                Positioned(
                  top: split.topRow.isNotEmpty ? cardHeight * 0.56 : 16,
                  left: 0,
                  right: 0,
                  height: cardHeight + 22,
                  child: _buildFanRow(
                    rowCards: split.bottomRow,
                    maxWidth: maxWidth,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    rowKeyPrefix: 'bottom_row',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFanRow({
    required List<PlayingCard> rowCards,
    required double maxWidth,
    required double cardWidth,
    required double cardHeight,
    required String rowKeyPrefix,
  }) {
    final count = rowCards.length;
    if (count == 0) return const SizedBox.shrink();

    final horizontalPadding = 12.0;
    final availableWidth = maxWidth - horizontalPadding * 2;

    // Kartların birbirinin üstüne binme adımı
    final maxStep = cardWidth * 0.66;
    final step = count == 1
        ? 0.0
        : math.min(maxStep, (availableWidth - cardWidth) / (count - 1));

    final totalRowWidth = cardWidth + step * (count - 1);
    final startX = (maxWidth - totalRowWidth) / 2;

    // Yelpaze açısı (-0.11 rad .. +0.11 rad arası hafif yay)
    const maxAngle = 0.11;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(count, (index) {
        final card = rowCards[index];
        final normalized = count == 1 ? 0.0 : (index / (count - 1)) * 2 - 1;
        final angle = normalized * maxAngle;
        final archOffset = (normalized * normalized) * 8.5; // Ortadaki kartlar biraz daha yukarıda

        final isPlayable =
            playableCards == null || playableCards!.contains(card);
        final isSelected = selectedCards.contains(card);

        return Positioned(
          left: startX + index * step,
          top: archOffset,
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: PlayingCardWidget(
              key: Key('hand_card_${card.id}'),
              card: card,
              width: cardWidth,
              height: cardHeight,
              isPlayable: isPlayable,
              isSelected: isSelected,
              onTap: onCardTap != null ? () => onCardTap!(card) : null,
            ),
          ),
        );
      }),
    );
  }
}
