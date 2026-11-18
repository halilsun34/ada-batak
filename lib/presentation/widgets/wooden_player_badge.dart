import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/player.dart';
import '../theme/table_theme.dart';

/// Ada Batak'a özgü pirinç perçinli, maun ahşap dokulu ve skor rozetli
/// oyuncu bilgi plakası.
class WoodenPlayerBadge extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final bool isBidWinner;
  final TableThemeData theme;
  final String? statusSubtitle;

  const WoodenPlayerBadge({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.isBidWinner = false,
    required this.theme,
    this.statusSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    switch (player.seat) {
      case PlayerSeat.north:
        return _buildHorizontalPlaque(isTop: true);
      case PlayerSeat.south:
        return _buildHorizontalPlaque(isTop: false);
      case PlayerSeat.west:
        return _buildVerticalSidePlaque(isLeft: true);
      case PlayerSeat.east:
        return _buildVerticalSidePlaque(isLeft: false);
    }
  }

  Widget _buildHorizontalPlaque({required bool isTop}) {
    final width = isTop ? 214.0 : 244.0;
    final height = isTop ? 44.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isTop && isCurrentTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _GlowingDiamondPointer(color: theme.activeTurnGlowColor),
          ),
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _OrnateWoodPlaquePainter(
              isCurrentTurn: isCurrentTurn,
              theme: theme,
              isVertical: false,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBidWinner) ...[
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0x33FFD54F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        size: 15,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      _formatDisplayLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTurn
                            ? const Color(0xFFFFF59D)
                            : const Color(0xFFF3ECE3),
                        fontWeight: FontWeight.w800,
                        fontSize: 14.2,
                        letterSpacing: 0.7,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isTop && isCurrentTurn)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _GlowingDiamondPointer(color: theme.activeTurnGlowColor),
          ),
      ],
    );
  }

  Widget _buildVerticalSidePlaque({required bool isLeft}) {
    const double width = 42.0;
    const double height = 188.0;

    final plaque = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _OrnateWoodPlaquePainter(
          isCurrentTurn: isCurrentTurn,
          theme: theme,
          isVertical: true,
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: isLeft ? 3 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBidWinner) ...[
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      _formatDisplayLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTurn
                            ? const Color(0xFFFFF59D)
                            : const Color(0xFFF3ECE3),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.8,
                        letterSpacing: 0.7,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLeft && isCurrentTurn)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _GlowingDiamondPointer(color: theme.activeTurnGlowColor),
          ),
        plaque,
        if (isLeft && isCurrentTurn)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _GlowingDiamondPointer(color: theme.activeTurnGlowColor),
          ),
      ],
    );
  }

  String _formatDisplayLabel() {
    if (statusSubtitle != null && statusSubtitle!.isNotEmpty) {
      return '${player.name}  ${player.totalScore} • $statusSubtitle';
    }
    return '${player.name}  ${player.totalScore}';
  }
}

class _GlowingDiamondPointer extends StatelessWidget {
  final Color color;

  const _GlowingDiamondPointer({required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.75),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrnateWoodPlaquePainter extends CustomPainter {
  final bool isCurrentTurn;
  final TableThemeData theme;
  final bool isVertical;

  const _OrnateWoodPlaquePainter({
    required this.isCurrentTurn,
    required this.theme,
    required this.isVertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cut = 10.0;

    // Sekizgen pahlı (chamfered) özgün ahşap tabela formu
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();

    canvas.save();
    canvas.drawShadow(
      path,
      isCurrentTurn ? theme.activeTurnGlowColor : Colors.black87,
      isCurrentTurn ? 9 : 5,
      false,
    );

    canvas.clipPath(path);

    // Maun ahşap gövde
    final rect = Offset.zero & size;
    final woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.woodDarkGrainColor,
          theme.woodBaseColor,
          theme.woodHighlightColor,
          theme.woodBaseColor,
          theme.woodDarkGrainColor,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, woodPaint);

    // Ahşap damar dokusu
    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..strokeWidth = 1.1;

    for (double i = 0; i < w + h; i += 7) {
      if (!isVertical) {
        canvas.drawLine(Offset(i, 0), Offset(i + 5, h), grainPaint);
      } else {
        canvas.drawLine(Offset(0, i), Offset(w, i + 5), grainPaint);
      }
    }

    canvas.restore();

    // Altın/Pirinç çerçeve
    final borderPaint = Paint()
      ..color = isCurrentTurn
          ? theme.activeTurnGlowColor
          : theme.goldBorderColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrentTurn ? 2.6 : 1.8;
    canvas.drawPath(path, borderPaint);

    // Köşelerde 4 adet pirinç perçin (rivet) noktası
    final rivetPaint = Paint()
      ..color = theme.goldBorderColor
      ..style = PaintingStyle.fill;
    const rOffset = 7.5;
    for (final pt in [
      const Offset(rOffset, rOffset),
      Offset(w - rOffset, rOffset),
      Offset(rOffset, h - rOffset),
      Offset(w - rOffset, h - rOffset),
    ]) {
      canvas.drawCircle(pt, 2.0, rivetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnateWoodPlaquePainter oldDelegate) =>
      oldDelegate.isCurrentTurn != isCurrentTurn ||
      oldDelegate.isVertical != isVertical ||
      oldDelegate.theme.type != theme.type;
}
