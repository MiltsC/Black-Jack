import 'dart:math';
import 'package:flutter/material.dart';

class CasinoChip extends StatelessWidget {
  final double size;
  final Color chipColor;
  final String label;
  final bool enabled;

  const CasinoChip({
    super.key,
    required this.size,
    required this.chipColor,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = enabled ? chipColor : Colors.grey.shade700;

    return SizedBox(
      width: size,
      height: size + 2,
      child: CustomPaint(
        painter: _ChipPainter(chipColor: displayColor, enabled: enabled),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.21,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.white : Colors.white30,
                height: 1.1,
                shadows: enabled
                    ? const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  final Color chipColor;
  final bool enabled;

  _ChipPainter({required this.chipColor, required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Drop shadow
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Main body
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = chipColor,
    );

    // Outer ring (white border)
    canvas.drawCircle(
      center,
      radius - 1.5,
      Paint()
        ..color = Colors.white.withValues(alpha: enabled ? 0.25 : 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Edge spots (8 dashes around the perimeter)
    final spotColor = Colors.white.withValues(alpha: enabled ? 0.65 : 0.15);
    final spotPaint = Paint()..color = spotColor;
    for (int i = 0; i < 8; i++) {
      final angle = (2 * pi * i / 8);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final spotW = radius * 0.3;
      final spotH = radius * 0.15;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -radius + spotH / 2 + 2),
          width: spotW,
          height: spotH,
        ),
        Radius.circular(spotH / 3),
      );
      canvas.drawRRect(rrect, spotPaint);
      canvas.restore();
    }

    // Secondary inner ring
    canvas.drawCircle(
      center,
      radius * 0.65,
      Paint()
        ..color = Colors.white.withValues(alpha: enabled ? 0.18 : 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner filled circle (slightly lighter for depth)
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          chipColor,
          Color.lerp(chipColor, Colors.black, 0.15)!,
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: radius * 0.58));
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    // Top-left highlight for 3D look
    if (enabled) {
      final hlRect = Rect.fromLTWH(
        center.dx - radius * 0.5,
        center.dy - radius * 0.85,
        radius * 1.0,
        radius * 0.6,
      );
      canvas.drawOval(
        hlRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(hlRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChipPainter old) =>
      chipColor != old.chipColor || enabled != old.enabled;
}
