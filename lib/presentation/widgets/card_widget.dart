import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/playing_card.dart';

/// Ada Batak'a özgü altın iç çerçeveli, krem-fildişi zeminli ve
/// özel geometrik madalyon figürlü oyun kartı widget'ı.
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final bool isPlayable;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 74,
    this.height = 104,
    this.isPlayable = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final suitColor = card.isRed
        ? const Color(0xFFC62828)
        : const Color(0xFF161B22);

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        transform: isSelected
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF9),
              Color(0xFFF3EFE6),
            ],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB300)
                : const Color(0xFFC8B89A),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x70000000),
              blurRadius: 6,
              offset: Offset(-1.5, 2.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Kart iç altın filigran çerçevesi ve sembol/madalyon çizimi
              CustomPaint(
                painter: _AdaCardFacePainter(
                  card: card,
                  suitColor: suitColor,
                ),
              ),

              // Sol üst köşe: Rakam/Harf + Sembol
              Positioned(
                top: 4,
                left: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      card.rank.label,
                      style: TextStyle(
                        color: suitColor,
                        fontSize: width * 0.31,
                        height: 0.96,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    SizedBox(
                      width: width * 0.20,
                      height: width * 0.20,
                      child: CustomPaint(
                        painter: _SuitPipPainter(
                          suit: card.suit,
                          color: suitColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Yardım açıkken oynanamayan kartlar için koyu/soluk filtre
              if (!isPlayable)
                Container(
                  color: const Color(0x8C10151A),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaCardFacePainter extends CustomPainter {
  final PlayingCard card;
  final Color suitColor;

  const _AdaCardFacePainter({
    required this.card,
    required this.suitColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // İnce altın iç filigran çizgisi (Ada Batak imza detayı)
    final innerFrame = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 3.5, w - 7, h - 7),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(
      innerFrame,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    if (card.rank.isFaceCard) {
      _drawOriginalAdaCourtMedallion(canvas, size);
      return;
    }

    if (card.rank == CardRank.ace) {
      // As kartları için ortada altın hareli büyük sembol
      final center = Offset(w * 0.60, h * 0.56);
      canvas.drawCircle(
        center,
        w * 0.27,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        w * 0.27,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      _drawPipAt(canvas, center, w * 0.40);
    } else {
      // Sayı kartları için temiz simetrik diyagonal sembol yerleşimi
      _drawPipAt(canvas, Offset(w * 0.63, h * 0.42), w * 0.29);
      _drawPipAt(canvas, Offset(w * 0.63, h * 0.77), w * 0.26);
    }
  }

  void _drawPipAt(Canvas canvas, Offset center, double pipSize) {
    canvas.save();
    canvas.translate(center.dx - pipSize / 2, center.dy - pipSize / 2);
    _SuitPipPainter(suit: card.suit, color: suitColor)
        .paint(canvas, Size(pipSize, pipSize));
    canvas.restore();
  }

  /// J, Q, K için özgün Ada Batak Kraliyet Arması / Madalyonu
  void _drawOriginalAdaCourtMedallion(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final boxRect = Rect.fromLTWH(w * 0.31, h * 0.20, w * 0.57, h * 0.70);
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(6));

    // Koyu altın/fildişi rozet zemini
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          suitColor.withValues(alpha: 0.12),
          const Color(0xFFE5B84B).withValues(alpha: 0.26),
        ],
      ).createShader(boxRect);
    canvas.drawRRect(rrect, bgPaint);

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFC59B27)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final center = boxRect.center;
    final radius = boxRect.width * 0.36;

    // Madalyon halkası
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFF8E7),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = suitColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Üstte kraliyet tacı (J: 3 uçlu, Q: yuvarlak taç, K: 5 uçlu altın taç)
    final crownCenter = Offset(center.dx, boxRect.top + boxRect.height * 0.22);
    final crownW = boxRect.width * 0.54;
    final crownH = boxRect.height * 0.18;

    final crownPath = Path()
      ..moveTo(crownCenter.dx - crownW / 2, crownCenter.dy + crownH / 2)
      ..lineTo(crownCenter.dx - crownW * 0.42, crownCenter.dy - crownH / 2)
      ..lineTo(crownCenter.dx - crownW * 0.15, crownCenter.dy + crownH * 0.1)
      ..lineTo(crownCenter.dx, crownCenter.dy - crownH * 0.65)
      ..lineTo(crownCenter.dx + crownW * 0.15, crownCenter.dy + crownH * 0.1)
      ..lineTo(crownCenter.dx + crownW * 0.42, crownCenter.dy - crownH / 2)
      ..lineTo(crownCenter.dx + crownW / 2, crownCenter.dy + crownH / 2)
      ..close();

    canvas.drawPath(
      crownPath,
      Paint()
        ..color = card.rank == CardRank.king
            ? const Color(0xFFFFB300)
            : (card.rank == CardRank.queen
                ? const Color(0xFFEC407A)
                : const Color(0xFF26A69A)),
    );

    // Madalyon ortasında renk sembolü
    _drawPipAt(canvas, center, w * 0.26);

    // Altta kurdele şeridi
    final ribbonRect = Rect.fromCenter(
      center: Offset(center.dx, boxRect.bottom - boxRect.height * 0.15),
      width: boxRect.width * 0.72,
      height: boxRect.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ribbonRect, const Radius.circular(3)),
      Paint()..color = suitColor.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _AdaCardFacePainter oldDelegate) =>
      oldDelegate.card != card || oldDelegate.suitColor != suitColor;
}

class _SuitPipPainter extends CustomPainter {
  final CardSuit suit;
  final Color color;

  const _SuitPipPainter({
    required this.suit,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    switch (suit) {
      case CardSuit.hearts:
        final path = Path()
          ..moveTo(w * 0.5, h * 0.92)
          ..cubicTo(w * 0.08, h * 0.62, 0.0, h * 0.25, w * 0.26, h * 0.10)
          ..cubicTo(w * 0.42, h * 0.02, w * 0.5, h * 0.18, w * 0.5, h * 0.26)
          ..cubicTo(w * 0.5, h * 0.18, w * 0.58, h * 0.02, w * 0.74, h * 0.10)
          ..cubicTo(w, h * 0.25, w * 0.92, h * 0.62, w * 0.5, h * 0.92)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case CardSuit.diamonds:
        final path = Path()
          ..moveTo(w * 0.5, h * 0.04)
          ..quadraticBezierTo(w * 0.68, h * 0.34, w * 0.92, h * 0.5)
          ..quadraticBezierTo(w * 0.68, h * 0.66, w * 0.5, h * 0.96)
          ..quadraticBezierTo(w * 0.32, h * 0.66, w * 0.08, h * 0.5)
          ..quadraticBezierTo(w * 0.32, h * 0.34, w * 0.5, h * 0.04)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case CardSuit.spades:
        final topPath = Path()
          ..moveTo(w * 0.5, h * 0.05)
          ..cubicTo(w * 0.92, h * 0.36, w * 0.98, h * 0.68, w * 0.72, h * 0.75)
          ..cubicTo(w * 0.58, h * 0.78, w * 0.52, h * 0.68, w * 0.5, h * 0.64)
          ..cubicTo(w * 0.48, h * 0.68, w * 0.42, h * 0.78, w * 0.28, h * 0.75)
          ..cubicTo(w * 0.02, h * 0.68, w * 0.08, h * 0.36, w * 0.5, h * 0.05)
          ..close();
        canvas.drawPath(topPath, paint);

        final stemPath = Path()
          ..moveTo(w * 0.45, h * 0.62)
          ..lineTo(w * 0.55, h * 0.62)
          ..lineTo(w * 0.66, h * 0.94)
          ..lineTo(w * 0.34, h * 0.94)
          ..close();
        canvas.drawPath(stemPath, paint);
        break;

      case CardSuit.clubs:
        final r = math.min(w, h) * 0.23;
        canvas.drawCircle(Offset(w * 0.5, h * 0.27), r, paint);
        canvas.drawCircle(Offset(w * 0.27, h * 0.55), r, paint);
        canvas.drawCircle(Offset(w * 0.73, h * 0.55), r, paint);

        final centerFill = Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.48),
          width: r * 1.1,
          height: r * 1.1,
        );
        canvas.drawOval(centerFill, paint);

        final stemPath = Path()
          ..moveTo(w * 0.45, h * 0.52)
          ..lineTo(w * 0.55, h * 0.52)
          ..lineTo(w * 0.67, h * 0.94)
          ..lineTo(w * 0.33, h * 0.94)
          ..close();
        canvas.drawPath(stemPath, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SuitPipPainter oldDelegate) =>
      oldDelegate.suit != suit || oldDelegate.color != color;
}
