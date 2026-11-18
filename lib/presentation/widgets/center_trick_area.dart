import 'package:flutter/material.dart';
import '../../domain/models/player.dart';
import '../../domain/models/trick.dart';
import 'card_widget.dart';

/// Ortaya atılan kartları oyuncunun yönünden merkeze doğru
/// `AnimatedPositioned` ile kaydırarak gösteren ve el bittiğinde
/// kazanan oyuncunun yönüne doğru toplayan widget.
class CenterTrickArea extends StatelessWidget {
  final Trick currentTrick;
  final PlayerSeat? collectingWinnerSeat;

  const CenterTrickArea({
    super.key,
    required this.currentTrick,
    this.collectingWinnerSeat,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTrick.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      key: const Key('center_trick_area'),
      width: 250,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: currentTrick.playedCards.map((entry) {
          return _AnimatedPlayedCardItem(
            key: ValueKey('trick_card_${entry.card.id}'),
            entry: entry,
            collectingWinnerSeat: collectingWinnerSeat,
          );
        }).toList(),
      ),
    );
  }
}

class _AnimatedPlayedCardItem extends StatefulWidget {
  final PlayedCardEntry entry;
  final PlayerSeat? collectingWinnerSeat;

  const _AnimatedPlayedCardItem({
    super.key,
    required this.entry,
    required this.collectingWinnerSeat,
  });

  @override
  State<_AnimatedPlayedCardItem> createState() =>
      _AnimatedPlayedCardItemState();
}

class _AnimatedPlayedCardItemState extends State<_AnimatedPlayedCardItem> {
  bool _hasArrivedAtCenter = false;

  @override
  void initState() {
    super.initState();
    // İlk frame'de oyuncunun oturduğu kenardan başlayıp hemen merkeze uçması için:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasArrivedAtCenter = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double cardW = 70.0;
    const double cardH = 98.0;
    const double areaW = 250.0;
    const double areaH = 230.0;

    final centerLeft = (areaW - cardW) / 2;
    final centerTop = (areaH - cardH) / 2;

    final startOffset = _originOffsetForSeat(widget.entry.seat);
    final restOffset = _restingOffsetForSeat(widget.entry.seat);

    Offset targetOffset;
    double scale = 1.0;

    if (widget.collectingWinnerSeat != null) {
      // Eli kazanan oyuncuya doğru toplama animasyonu
      targetOffset = _originOffsetForSeat(widget.collectingWinnerSeat!) * 1.15;
      scale = 0.72;
    } else if (_hasArrivedAtCenter) {
      targetOffset = restOffset;
    } else {
      targetOffset = startOffset;
    }

    final rotation = _rotationForSeat(widget.entry.seat);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: centerLeft + targetOffset.dx,
      top: centerTop + targetOffset.dy,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: scale,
        child: Transform.rotate(
          angle: rotation,
          child: PlayingCardWidget(
            card: widget.entry.card,
            width: cardW,
            height: cardH,
          ),
        ),
      ),
    );
  }

  Offset _originOffsetForSeat(PlayerSeat seat) {
    switch (seat) {
      case PlayerSeat.south:
        return const Offset(0, 120);
      case PlayerSeat.north:
        return const Offset(0, -120);
      case PlayerSeat.west:
        return const Offset(-120, 0);
      case PlayerSeat.east:
        return const Offset(120, 0);
    }
  }

  Offset _restingOffsetForSeat(PlayerSeat seat) {
    switch (seat) {
      case PlayerSeat.south:
        return const Offset(0, 34);
      case PlayerSeat.north:
        return const Offset(0, -34);
      case PlayerSeat.west:
        return const Offset(-42, 0);
      case PlayerSeat.east:
        return const Offset(42, 0);
    }
  }

  double _rotationForSeat(PlayerSeat seat) {
    switch (seat) {
      case PlayerSeat.south:
        return 0.03;
      case PlayerSeat.north:
        return -0.04;
      case PlayerSeat.west:
        return -0.09;
      case PlayerSeat.east:
        return 0.09;
    }
  }
}
