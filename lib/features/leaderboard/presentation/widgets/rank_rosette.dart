import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A scalloped circular badge stamped with a rank number — visual
/// echo of the Sudoku Master inspiration list. The rosette has 12
/// petals, a primary fill colour, a darker stroke, and a centred
/// rank number.
class RankRosette extends StatelessWidget {
  const RankRosette({
    super.key,
    required this.rank,
    required this.color,
    this.borderColor,
    this.size = 36,
    this.highlight = false,
  });

  final int rank;
  final Color color;
  final Color? borderColor;
  final double size;

  /// True when this is the current user's rosette — adds a soft
  /// outer glow + slightly thicker stroke.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RosettePainter(
          color: color,
          borderColor: borderColor ?? color,
          highlight: highlight,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              color: highlight ? Colors.white : scheme.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.42,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }
}

class _RosettePainter extends CustomPainter {
  _RosettePainter({
    required this.color,
    required this.borderColor,
    required this.highlight,
  });

  final Color color;
  final Color borderColor;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centre = Offset(cx, cy);
    final r = math.min(cx, cy) - 1;

    // Soft outer glow on the highlighted rosette (current user).
    if (highlight) {
      canvas.drawCircle(
        centre,
        r * 1.05,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Build the scalloped petal path. 12 petals — alternating between
    // outer R (petal tip) and an inner R (notch between petals).
    const petals = 12;
    final outerR = r;
    final innerR = r * 0.86;
    final path = Path();
    for (var i = 0; i < petals * 2; i++) {
      final radius = i.isEven ? outerR : innerR;
      final theta = (math.pi * 2) * (i / (petals * 2)) - math.pi / 2;
      final p = centre + Offset(math.cos(theta), math.sin(theta)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [color, _darken(color, highlight ? 0.15 : 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 1.8 : 1.0
        ..color = highlight ? Colors.white.withValues(alpha: 0.85) : borderColor,
    );
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _RosettePainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.highlight != highlight;
}
