import 'dart:math';
import 'package:flutter/material.dart';

class WinShimmer extends StatefulWidget {
  const WinShimmer({super.key});

  @override
  State<WinShimmer> createState() => _WinShimmerState();
}

class _WinShimmerState extends State<WinShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _controller.value * 3, -0.5),
                end: Alignment(-0.5 + _controller.value * 3, 0.5),
                colors: [
                  Colors.transparent,
                  Colors.amber.withValues(alpha: 0.12 * (1 - _controller.value)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LossFlash extends StatefulWidget {
  const LossFlash({super.key});

  @override
  State<LossFlash> createState() => _LossFlashState();
}

class _LossFlashState extends State<LossFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Container(
            color: Colors.red.withValues(alpha: 0.1 * (1 - _controller.value)),
          ),
        );
      },
    );
  }
}

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _pieces = List.generate(40, (_) => _ConfettiPiece(rng));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(_pieces, _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double speed;
  final double size;
  final double wobble;
  final Color color;

  _ConfettiPiece(Random rng)
      : x = rng.nextDouble(),
        speed = 0.3 + rng.nextDouble() * 0.7,
        size = 4 + rng.nextDouble() * 6,
        wobble = rng.nextDouble() * 2 * pi,
        color = [
          Colors.amber,
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.white,
        ][rng.nextInt(8)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final px = p.x * size.width + sin(progress * 6 + p.wobble) * 20;
      final py = -20 + t * (size.height + 40);
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(progress * 4 + p.wobble);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color.withValues(alpha: opacity * 0.8),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => progress != old.progress;
}
