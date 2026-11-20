import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/player.dart';
import '../theme/table_theme.dart';

/// Rakiplerin (BORA, ALP, DENİZ) kapalı el kartlarını ve kalan kart sayısını
/// gösteren özgün Ada Batak kart destesi widget'ı.
class OpponentCardsWidget extends StatelessWidget {
  final Player player;
  final TableThemeData theme;

  const OpponentCardsWidget({
    super.key,
    required this.player,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final count = player.hand.length;
    if (count <= 0) return const SizedBox.shrink();

    switch (player.seat) {
      case PlayerSeat.north:
        return _buildNorthCards(count);
      case PlayerSeat.west:
        return _buildSideCards(count, isLeft: true);
      case PlayerSeat.east:
        return _buildSideCards(count, isLeft: false);
      case PlayerSeat.south:
        return const SizedBox.shrink();
    }
  }

  /// Üst oyuncu (BORA) için yatay mini kart yelpazesi ve sayı rozeti
  Widget _buildNorthCards(int count) {
    // Görsel kart sayısı (maksimum 6 mini kartla şık bir yelpaze)
    final visualCards = math.min(count, 5);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mini yelpaze
          SizedBox(
            width: 24.0 + (visualCards - 1) * 8.0,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(visualCards, (index) {
                final angle = (index - (visualCards - 1) / 2) * 0.08;
                return Positioned(
                  left: index * 8.0,
                  top: 0,
                  child: Transform.rotate(
                    angle: angle,
                    child: const MiniCardBackWidget(width: 20, height: 28),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          // Kalan kart sayısı sayacı
          _buildCountBadge(count),
        ],
      ),
    );
  }

  /// Yan oyuncular (ALP solda, DENİZ sağda) için dikey mini kart destesi
  Widget _buildSideCards(int count, {required bool isLeft}) {
    final visualCards = math.min(count, 4);

    final stackWidget = SizedBox(
      width: 28,
      height: 22.0 + (visualCards - 1) * 6.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(visualCards, (index) {
          return Positioned(
            left: index * 2.0,
            top: index * 6.0,
            child: const MiniCardBackWidget(width: 22, height: 20),
          );
        }),
      ),
    );

    return Container(
      margin: EdgeInsets.only(
        left: isLeft ? 4 : 0,
        right: isLeft ? 0 : 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          stackWidget,
          const SizedBox(height: 4),
          _buildCountBadge(count),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xE6141D24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD59B1A).withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 3,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Ada Batak'a özgü altın çerçeveli ve pusula işlemeli minyatür kart sırtı
class MiniCardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const MiniCardBackWidget({
    super.key,
    this.width = 22,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2836),
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: const Color(0xFFD59B1A),
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MiniCardBackPainter(),
      ),
    );
  }
}

class _MiniCardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0x66FFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // İç süsleme dikdörtgeni
    final innerRect = Rect.fromLTWH(
      2.0,
      2.0,
      size.width - 4.0,
      size.height - 4.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2)),
      borderPaint,
    );

    // Merkezde minik Ada pusula baklavası
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path()
      ..moveTo(cx, cy - 3.5)
      ..lineTo(cx + 2.5, cy)
      ..lineTo(cx, cy + 3.5)
      ..lineTo(cx - 2.5, cy)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0xAAFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
