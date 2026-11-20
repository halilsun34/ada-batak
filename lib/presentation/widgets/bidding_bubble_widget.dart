import 'package:flutter/material.dart';
import '../../domain/models/player.dart';

/// İhale aşamasında botların veya kullanıcının verdiği teklifi ya da
/// "PAS" kararını oyuncu rozetinin hemen yanında şık bir konuşma balonuyla gösterir.
class BiddingBubbleWidget extends StatelessWidget {
  final Player player;

  const BiddingBubbleWidget({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    if (!player.hasPassedBid && player.currentBid == null) {
      return const SizedBox.shrink();
    }

    final isPass = player.hasPassedBid;
    final text = isPass ? 'PAS' : '${player.currentBid}';

    final bgColor = isPass
        ? const Color(0xE63E1818)
        : const Color(0xE62A1F06);

    final borderColor = isPass
        ? const Color(0xFFE57373)
        : const Color(0xFFFFD54F);

    final textColor = isPass
        ? const Color(0xFFFFCDD2)
        : const Color(0xFFFFF9C4);

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: 1.0,
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPass) ...[
              const Icon(
                Icons.gavel_rounded,
                size: 11,
                color: Color(0xFFFFD54F),
              ),
              const SizedBox(width: 3.5),
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
