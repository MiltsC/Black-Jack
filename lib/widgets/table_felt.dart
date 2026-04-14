import 'package:flutter/material.dart';

class TableFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Green felt covers entire screen ---
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.45),
          radius: 1.3,
          colors: const [
            Color(0xFF33873A),
            Color(0xFF24692A),
            Color(0xFF1A5420),
            Color(0xFF123D16),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // --- Subtle top-down lighting ---
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5)),
    );

    // --- Player-side curve (convex, bowing toward the player) ---
    // Edges are higher on screen, center dips down toward player
    final curveEdgeY = h * 0.87;
    final curveCenterY = h * 0.93;

    // Wood rail path (below the curve down to screen bottom)
    final railPath = Path();
    railPath.moveTo(-20, h + 20);
    railPath.lineTo(w + 20, h + 20);
    railPath.lineTo(w + 20, curveEdgeY);
    railPath.quadraticBezierTo(w / 2, curveCenterY, -20, curveEdgeY);
    railPath.close();

    // Wood fill
    canvas.drawPath(
      railPath,
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0xFF5D4037),
            Color(0xFF4E342E),
            Color(0xFF3E2723),
            Color(0xFF2C1E16),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, curveEdgeY, w, h - curveEdgeY)),
    );

    // Wood grain lines following the curve
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 5;
      final grainEdge = curveEdgeY + (h - curveEdgeY) * t;
      final grainCenter = curveCenterY + (h - curveCenterY) * t;
      final grainPath = Path();
      grainPath.moveTo(-10, grainEdge);
      grainPath.quadraticBezierTo(w / 2, grainCenter, w + 10, grainEdge);
      canvas.drawPath(
        grainPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.06 + i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Dark crease at felt-rail junction
    final edgePath = Path();
    edgePath.moveTo(-20, curveEdgeY);
    edgePath.quadraticBezierTo(w / 2, curveCenterY, w + 20, curveEdgeY);
    canvas.drawPath(
      edgePath,
      Paint()
        ..color = const Color(0xFF0A0500).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Light bevel on wood rail top
    final bevelPath = Path();
    final bevelEdge = curveEdgeY + 3;
    final bevelCenter = curveCenterY + 3;
    bevelPath.moveTo(-20, bevelEdge);
    bevelPath.quadraticBezierTo(w / 2, bevelCenter, w + 20, bevelEdge);
    canvas.drawPath(
      bevelPath,
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // --- Gold trim on felt following the curve ---
    final trimEdge = curveEdgeY - 14;
    final trimCenter = curveCenterY - 14;
    final trimPath = Path();
    trimPath.moveTo(-10, trimEdge);
    trimPath.quadraticBezierTo(w / 2, trimCenter, w + 10, trimEdge);
    canvas.drawPath(
      trimPath,
      Paint()
        ..color = const Color(0xFFD4A843).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // --- Edge vignette for depth ---
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.1,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // --- Dealer edge hint at top ---
    canvas.drawLine(
      const Offset(0, 0),
      Offset(w, 0),
      Paint()
        ..color = const Color(0xFF0D3B10).withValues(alpha: 0.4)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
