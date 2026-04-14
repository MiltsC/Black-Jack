import 'dart:math';
import 'package:flutter/material.dart';
import '../models/playing_card.dart';

class PlayingCardWidget extends StatefulWidget {
  final PlayingCard card;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 80,
    this.height = 120,
  });

  @override
  State<PlayingCardWidget> createState() => _PlayingCardWidgetState();
}

class _PlayingCardWidgetState extends State<PlayingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late bool _wasFaceUp;

  double get _scale => widget.width / 80.0;

  @override
  void initState() {
    super.initState();
    _wasFaceUp = widget.card.faceUp;
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    if (_wasFaceUp) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PlayingCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_wasFaceUp && widget.card.faceUp) {
      _flipController.forward(from: 0.0);
      _wasFaceUp = true;
    } else if (_wasFaceUp && !widget.card.faceUp) {
      _flipController.reverse(from: 1.0);
      _wasFaceUp = false;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, _) {
        final angle = _flipController.value * pi;
        final showFront = _flipController.value >= 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildCardFront(),
                )
              : _buildCardBack(),
        );
      },
    );
  }

  Widget _buildCardFront() {
    final color = widget.card.isRed ? Colors.red.shade700 : Colors.black87;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * _scale),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4 * _scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.card.rankLabel}${widget.card.suitSymbol}',
              style: TextStyle(
                fontSize: 12 * _scale,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  widget.card.suitSymbol,
                  style: TextStyle(fontSize: 28 * _scale, color: color),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${widget.card.rankLabel}${widget.card.suitSymbol}',
                style: TextStyle(
                  fontSize: 12 * _scale,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * _scale),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width - 12 * _scale,
          height: widget.height - 12 * _scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4 * _scale),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Center(
            child: Text(
              '\u2660\u2665\n\u2666\u2663',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * _scale,
                color: Colors.white38,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
