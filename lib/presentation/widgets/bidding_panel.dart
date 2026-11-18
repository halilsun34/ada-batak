import 'package:flutter/material.dart';
import '../../domain/models/playing_card.dart';

/// Ada Batak'a özgü başlıklı, altın çerçeveli, elmas dokulu koyu ihale paneli.
/// 5'ten 13'e kadar kehribar/bakır kademeli butonlar ve altında geniş PAS butonu içerir.
class BiddingPanel extends StatelessWidget {
  final int? currentHighestBid;
  final bool isUserTurn;
  final ValueChanged<int> onBidSelected;
  final VoidCallback onPassSelected;

  const BiddingPanel({
    super.key,
    required this.currentHighestBid,
    required this.isUserTurn,
    required this.onBidSelected,
    required this.onPassSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bidding_panel_container'),
      width: 268,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF2141E28),
            Color(0xF20B1117),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5B84B).withValues(alpha: 0.75),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Özgün Ada Batak İhale Başlığı ve En Yüksek Teklif Rozeti
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: Color(0xFFE5B84B),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'İHALE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE5B84B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x26E5B84B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x66E5B84B),
                  ),
                ),
                child: Text(
                  currentHighestBid != null
                      ? 'TEKLİF: $currentHighestBid'
                      : 'EN AZ: 5',
                  style: const TextStyle(
                    color: Color(0xFFFFF59D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: const Color(0xFFE5B84B).withValues(alpha: 0.22),
            height: 1,
          ),
          const SizedBox(height: 12),

          // 3x3 (5..13) Kehribar/Altın İhale Butonları
          for (int row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int col = 0; col < 3; col++)
                  _buildNumberButton(5 + row * 3 + col),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Geniş PAS Butonu
          _AmberClubButton(
            key: const Key('bid_pass_button'),
            width: double.infinity,
            height: 48,
            label: 'PAS GEÇ',
            fontSize: 17,
            isPassButton: true,
            enabled: isUserTurn,
            onTap: onPassSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isHigherThanPrevious =
        currentHighestBid == null || number > currentHighestBid!;
    final isEnabled = isUserTurn && isHigherThanPrevious;

    return _AmberClubButton(
      key: Key('bid_button_$number'),
      width: 70,
      height: 48,
      label: '$number',
      fontSize: 21,
      enabled: isEnabled,
      dimmed: !isHigherThanPrevious,
      onTap: () => onBidSelected(number),
    );
  }
}

/// İhaleyi kazanan oyuncu koz seçme modundaysa gösterilen koz seçim paneli.
class TrumpPickerPanel extends StatelessWidget {
  final ValueChanged<CardSuit> onTrumpSelected;

  const TrumpPickerPanel({
    super.key,
    required this.onTrumpSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('trump_picker_panel'),
      width: 268,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF2141E28),
            Color(0xF20B1117),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5B84B), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'KOZ RENGİNİ SEÇİN',
            style: TextStyle(
              color: Color(0xFFE5B84B),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: CardSuit.values.map((suit) {
              return InkWell(
                key: Key('trump_suit_${suit.name}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTrumpSelected(suit),
                child: Container(
                  width: 108,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5B84B),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${suit.symbol} ${suit.turkishName}',
                    style: TextStyle(
                      color: suit.isRed
                          ? const Color(0xFFC62828)
                          : const Color(0xFF1A212B),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AmberClubButton extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final double fontSize;
  final bool enabled;
  final bool dimmed;
  final bool isPassButton;
  final VoidCallback onTap;

  const _AmberClubButton({
    super.key,
    required this.width,
    required this.height,
    required this.label,
    required this.fontSize,
    required this.enabled,
    this.dimmed = false,
    this.isPassButton = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors;
    final Color borderColor;
    final Color textColor;

    if (dimmed) {
      gradientColors = const [Color(0xFF283038), Color(0xFF1B2127)];
      borderColor = Colors.white12;
      textColor = Colors.white30;
    } else if (isPassButton) {
      gradientColors = const [Color(0xFFE65100), Color(0xFFBF360C)];
      borderColor = const Color(0xFFFFAB40);
      textColor = Colors.white;
    } else {
      gradientColors = const [Color(0xFFFFB74D), Color(0xFFE67E22)];
      borderColor = const Color(0xFFFFE082);
      textColor = const Color(0xFF1F1300);
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: dimmed ? 0.45 : (enabled ? 1.0 : 0.78),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            border: Border.all(
              color: borderColor,
              width: 1.3,
            ),
            boxShadow: dimmed
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
