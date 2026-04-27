import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Top-3 rank decoration. Three intensities matching the tier-card
/// system on the home screen:
///
///   rank 3 — Master    (bronze)  — sweep border + particle aura
///   rank 2 — Epic      (silver)  — sweep border + denser aura + halo
///   rank 1 — Legendary (gold)    — sweep border + densest aura +
///                                   shimmer sweep + crown
///
/// All three render the rosette base (12-petal scalloped circle with
/// the rank numeral centred) underneath the decorations so the badge
/// still reads as a rank at a glance.
class LegendaryRosette extends StatefulWidget {
  const LegendaryRosette({
    super.key,
    required this.rank,
    required this.gradient,
    this.size = 56,
    this.isCurrentUser = false,
  });

  /// 1, 2 or 3 — chooses the decoration intensity.
  final int rank;

  /// Frame gradient: gold/silver/bronze.
  final List<Color> gradient;

  /// Side length in dp.
  final double size;

  final bool isCurrentUser;

  /// "LEGENDARY" / "EPIC" / "MASTER" label paired with this rank.
  static String tierLabel(int rank) => switch (rank) {
        1 => 'LEGENDARY',
        2 => 'EPIC',
        3 => 'MASTER',
        _ => '',
      };

  @override
  State<LegendaryRosette> createState() => _LegendaryRosetteState();
}

class _LegendaryRosetteState extends State<LegendaryRosette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  // Higher rank = higher decoration intensity (1 = max).
  int get _intensity => switch (widget.rank) {
        1 => 4,
        2 => 3,
        3 => 2,
        _ => 1,
      };

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final auraSize = s + 16;

    Widget badge = SizedBox(
      width: auraSize,
      height: auraSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Outer halo (intensity ≥ 3)
          if (_intensity >= 3)
            Container(
              width: auraSize,
              height: auraSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.gradient.first.withValues(alpha: 0.32),
                    widget.gradient.first.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

          // Particle aura
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => CustomPaint(
              size: Size(auraSize, auraSize),
              painter: _AuraPainter(
                t: _spin.value,
                count: 4 + _intensity * 2,
                colors: widget.gradient,
              ),
            ),
          ),

          // Animated SweepGradient border
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => CustomPaint(
              size: Size(s, s),
              painter: _SweepRingPainter(
                t: _spin.value,
                colors: widget.gradient,
                strokeWidth: 1.6 + _intensity * 0.4,
              ),
            ),
          ),

          // Rosette body + rank numeral
          SizedBox(
            width: s,
            height: s,
            child: CustomPaint(
              painter: _RosettePainter(colors: widget.gradient),
              child: Center(
                child: Text(
                  '${widget.rank}',
                  style: TextStyle(
                    color: const Color(0xFF21140A),
                    fontWeight: FontWeight.w900,
                    fontSize: s * 0.42,
                    height: 1.0,
                    letterSpacing: -1.5,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Crown for Legendary (rank 1) only
          if (widget.rank == 1)
            Positioned(
              top: -6,
              child: Icon(
                Icons.emoji_events,
                size: 20,
                color: widget.gradient.first,
                shadows: [
                  Shadow(
                    color: widget.gradient.first.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 1100.ms, curve: Curves.easeInOut),
        ],
      ),
    );

    // Shimmer sweep on Legendary
    if (widget.rank == 1) {
      badge = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          badge,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipOval(
                child: Container(color: Colors.transparent)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2200.ms,
                      color: Colors.white.withValues(alpha: 0.22),
                      angle: 0.4,
                    ),
              ),
            ),
          ),
        ],
      );
    }

    return badge;
  }
}

/// Scalloped 12-petal rosette body (alternating outer + inner radii).
class _RosettePainter extends CustomPainter {
  _RosettePainter({required this.colors});
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centre = Offset(cx, cy);
    final r = math.min(cx, cy) - 2;

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

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.first, colors.last],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );

    // Inner highlight arc (top-left shine)
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r * 0.7),
      -math.pi * 0.85,
      math.pi * 0.55,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RosettePainter old) => old.colors != colors;
}

/// Rotating SweepGradient ring around the rosette body.
class _SweepRingPainter extends CustomPainter {
  _SweepRingPainter({
    required this.t,
    required this.colors,
    required this.strokeWidth,
  });
  final double t;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centre = Offset(cx, cy);
    final r = math.min(cx, cy) - strokeWidth / 2;

    final angle = t * 2 * math.pi;
    final shader = SweepGradient(
      colors: [
        colors.first,
        colors.last,
        colors.first,
        colors.last,
        colors.first,
      ],
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
    ).createShader(Rect.fromCircle(center: centre, radius: r));

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _SweepRingPainter old) =>
      old.t != t || old.colors != colors || old.strokeWidth != strokeWidth;
}

/// Particle dots orbiting outside the rosette.
class _AuraPainter extends CustomPainter {
  _AuraPainter({required this.t, required this.count, required this.colors});
  final double t;
  final int count;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centre = Offset(cx, cy);
    final r = math.min(cx, cy);

    for (var i = 0; i < count; i++) {
      final phase = (i / count) * 2 * math.pi + t * 2 * math.pi;
      final orbitR = r * (0.85 + 0.10 * math.sin(phase * 1.3 + i));
      final pos = centre + Offset(math.cos(phase), math.sin(phase)) * orbitR;
      final twinkle = (math.sin(t * 6 * math.pi + i * 1.7) + 1) / 2;
      final color = colors[i % colors.length];

      canvas.drawCircle(
        pos,
        2.4 + twinkle * 1.2,
        Paint()
          ..color = color.withValues(alpha: 0.22 + twinkle * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        pos,
        1.0 + twinkle * 0.6,
        Paint()..color = Colors.white.withValues(alpha: 0.55 + twinkle * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) => old.t != t;
}
