import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/table_theme.dart';

/// Ada Batak'a özgü elmas/baklava dokulu ve ortasında zarif kulüp rozeti
/// bulunan masa arka planı widget'ı.
class FeltTableBackground extends StatelessWidget {
  final TableThemeData theme;
  final Widget child;

  const FeltTableBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FeltTablePainter(theme: theme),
      child: child,
    );
  }
}

class _FeltTablePainter extends CustomPainter {
  final TableThemeData theme;

  const _FeltTablePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Zengin radyal masa çuhası gradyanı
    final bgGradient = RadialGradient(
      center: const Alignment(0.0, -0.15),
      radius: 0.98,
      colors: [
        theme.feltCenterColor,
        theme.feltEdgeColor,
      ],
      stops: const [0.0, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // 2. Özgün ince geometrik elmas (argyle/diamond) masa dokusu
    final patternPaint = Paint()
      ..color = theme.feltTextureLineColor.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double gridStep = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += gridStep) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.7, size.height),
        patternPaint,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * 0.7, size.height),
        patternPaint,
      );
    }

    // 3. Masa ortasında zarif "ADA BATAK" çift halkalı altın su izi (watermark)
    final tableCenter = Offset(size.width / 2, size.height * 0.39);
    final ringRadius = math.min(size.width, size.height) * 0.29;

    final outerRingPaint = Paint()
      ..color = theme.goldBorderColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final innerRingPaint = Paint()
      ..color = theme.goldBorderColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(tableCenter, ringRadius, outerRingPaint);
    canvas.drawCircle(tableCenter, ringRadius - 8, innerRingPaint);

    // Sekiz köşeli zarif yıldız/pusula motifi (Ada simgesi)
    final starPath = Path();
    for (int i = 0; i < 8; i++) {
      final outerAngle = i * math.pi / 4;
      final innerAngle = outerAngle + math.pi / 8;
      final rOut = ringRadius * 0.34;
      final rIn = ringRadius * 0.14;

      final pOut = Offset(
        tableCenter.dx + math.cos(outerAngle) * rOut,
        tableCenter.dy + math.sin(outerAngle) * rOut,
      );
      final pIn = Offset(
        tableCenter.dx + math.cos(innerAngle) * rIn,
        tableCenter.dy + math.sin(innerAngle) * rIn,
      );
      if (i == 0) {
        starPath.moveTo(pOut.dx, pOut.dy);
      } else {
        starPath.lineTo(pOut.dx, pOut.dy);
      }
      starPath.lineTo(pIn.dx, pIn.dy);
    }
    starPath.close();
    canvas.drawPath(
      starPath,
      Paint()
        ..color = theme.goldBorderColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // 4. Köşe vinyet gölgesi
    final vignetteGradient = RadialGradient(
      center: const Alignment(0.0, -0.1),
      radius: 0.90,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.42),
      ],
      stops: const [0.62, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = vignetteGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _FeltTablePainter oldDelegate) {
    return oldDelegate.theme.type != theme.type;
  }
}
