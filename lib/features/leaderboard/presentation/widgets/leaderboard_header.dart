import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Purely decorative banner above the leaderboard. Three crowns
/// (legendary/epic/master, gold/silver/bronze) sit on a navy backdrop
/// shared with the splash screen — dotted grid lines, drifting
/// particles, sparks orbiting each crown. No entry data is bound to
/// the header: it's tone-setting, not user-data.
///
/// Animations:
///   - Background grid: static
///   - Particle field: 18 sparkles drift on sin-wave paths, alpha-twinkle
///   - Center (gold) crown: slow up/down sine bob (4dp / 2.4s)
///   - Side crowns: alternating slight rotation back and forth
///   - Per-crown sparkle ring: 12 sparks orbit each crown on a slow
///     rotation
class LeaderboardHeader extends StatefulWidget {
  const LeaderboardHeader({super.key, this.height = 200});

  final double height;

  @override
  State<LeaderboardHeader> createState() => _LeaderboardHeaderState();
}

class _LeaderboardHeaderState extends State<LeaderboardHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Brand backdrop
            const ColoredBox(color: Color(0xFF01072D)),
            const Positioned.fill(child: _GridBackdrop()),

            // Drifting particle field across the whole header
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ParticleFieldPainter(
                  t: _controller.value,
                  tints: palette.particleTints,
                ),
              ),
            ),

            // Three crowns close-packed in a Stack so the side crowns
            // tuck behind the centre by ~3% of their width, giving a
            // layered/podium look. Centre drawn last → on top.
            Center(
              child: SizedBox(
                width: 230,
                height: widget.height - 24,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Silver (epic, left) — tucked behind centre
                    Positioned(
                      left: 8,
                      top: 28,
                      child: _Crown(
                        rank: 2,
                        size: 70,
                        colors: palette.silverFrame,
                        animation: _controller,
                        rotateRange: 0.07,
                      ),
                    ),
                    // Bronze (master, right) — tucked behind centre
                    Positioned(
                      right: 8,
                      top: 32,
                      child: _Crown(
                        rank: 3,
                        size: 64,
                        colors: palette.bronzeFrame,
                        animation: _controller,
                        rotateRange: -0.07,
                      ),
                    ),
                    // Gold (legendary, centre) — drawn last → in front,
                    // overlaps the side crowns by ~3%.
                    _Crown(
                      rank: 1,
                      size: 104,
                      colors: palette.goldFrame,
                      animation: _controller,
                      bob: true,
                    ),
                  ],
                ),
              ),
            ),

            // Subtle bottom fade so the header blends into the list
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0001072D), Color(0xFF01072D)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Crown extends StatelessWidget {
  const _Crown({
    required this.rank,
    required this.size,
    required this.colors,
    required this.animation,
    this.bob = false,
    this.rotateRange = 0.0,
  });

  final int rank;
  final double size;
  final List<Color> colors;
  final Animation<double> animation;

  /// Vertical bob (only the centre crown).
  final bool bob;

  /// Side crowns: max +/- rotation in radians (0 = no rotation).
  final double rotateRange;

  @override
  Widget build(BuildContext context) {
    Widget crown = SizedBox(
      width: size + 24,
      height: size + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo + orbiting sparks
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) => CustomPaint(
              size: Size(size + 24, size + 24),
              painter: _CrownAuraPainter(
                t: animation.value,
                colors: colors,
              ),
            ),
          ),
          // Crown shape
          CustomPaint(
            size: Size(size, size),
            painter: _CrownPainter(rank: rank, colors: colors),
          ),
        ],
      ),
    );

    if (bob) {
      crown = crown
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Curves.easeInOut);
    } else if (rotateRange != 0.0) {
      // Slight back-and-forth rotation, asymmetric per crown via sign of range.
      crown = AnimatedBuilder(
        animation: animation,
        child: crown,
        builder: (context, child) {
          final theta = math.sin(animation.value * 2 * math.pi) * rotateRange;
          return Transform.rotate(angle: theta, child: child);
        },
      );
    }

    return Center(child: crown);
  }
}

/// Detailed crown silhouette. Layered render order:
///   1. Drop-shadow under the band
///   2. Base + arches body fill (vertical metal gradient)
///   3. Vertical groove lines (engraving)
///   4. Inner shadow stroke (lower band) for depth
///   5. Highlight stroke along the upper edges
///   6. Band rectangle fill with horizontal gradient + edge highlights
///   7. Five rim gems along the band (alternating diamond + round)
///   8. Pearl row above the band
///   9. Top-peak jewel (faceted) with star-shine
class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.rank, required this.colors});

  final int rank;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mid = colors.first;
    final dark = colors.last;
    final highlight = Color.lerp(mid, Colors.white, 0.55)!;
    final shadow = Color.lerp(dark, Colors.black, 0.4)!;

    // Drop-shadow under the crown band
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.96),
        width: w * 0.78,
        height: h * 0.10,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 1) Three-peak body (the arches above the band)
    final body = Path()
      ..moveTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.08, h * 0.62)
      // left peak
      ..lineTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.20, h * 0.32)
      // dip towards centre peak
      ..quadraticBezierTo(w * 0.30, h * 0.62, w * 0.36, h * 0.55)
      // centre peak
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.64, h * 0.55)
      // dip towards right peak
      ..quadraticBezierTo(w * 0.70, h * 0.62, w * 0.80, h * 0.32)
      // right peak
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.92, h * 0.62)
      ..lineTo(w * 0.92, h * 0.78)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [highlight, mid, dark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2) Vertical engraved grooves down the body (subtle dark lines)
    final groovePaint = Paint()
      ..color = shadow.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final x = w * (0.36 + 0.14 * i);
      canvas.drawLine(Offset(x, h * 0.30), Offset(x, h * 0.60), groovePaint);
    }
    // Plus a groove down each arch edge
    canvas.drawLine(Offset(w * 0.18, h * 0.32), Offset(w * 0.18, h * 0.60), groovePaint);
    canvas.drawLine(Offset(w * 0.82, h * 0.32), Offset(w * 0.82, h * 0.60), groovePaint);

    // 3) Inner-shadow stroke along the lower band edge
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = shadow.withValues(alpha: 0.5),
    );

    // 4) Highlight along the upper-left ridges (catching the light)
    final highlightPath = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.18, h * 0.30, w * 0.20, h * 0.30)
      ..moveTo(w * 0.36, h * 0.55)
      ..quadraticBezierTo(w * 0.42, h * 0.30, w * 0.50, h * 0.10);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeCap = StrokeCap.round,
    );

    // 5) Crown band rectangle (the encircling ring at the bottom)
    final bandRect = Rect.fromLTWH(w * 0.04, h * 0.74, w * 0.92, h * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(w * 0.02)),
      Paint()
        ..shader = LinearGradient(
          colors: [shadow, mid, highlight, mid, shadow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bandRect),
    );
    // Band outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(w * 0.02)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    // Top + bottom band edge highlight lines
    canvas.drawLine(
      Offset(bandRect.left + w * 0.02, bandRect.top + 2),
      Offset(bandRect.right - w * 0.02, bandRect.top + 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(bandRect.left + w * 0.02, bandRect.bottom - 2),
      Offset(bandRect.right - w * 0.02, bandRect.bottom - 2),
      Paint()
        ..color = shadow.withValues(alpha: 0.55)
        ..strokeWidth = 1.0,
    );

    // 6) Pearl row above the band (small white circles)
    for (var i = 0; i < 7; i++) {
      final x = w * (0.16 + 0.12 * i);
      _drawPearl(canvas, Offset(x, h * 0.72), w * 0.022);
    }

    // 7) Five band gems — alternating diamond + round
    final gemY = h * 0.83;
    final gemSpec = [
      (0.18, _GemShape.round, Color(0xFFE91E63)),  // ruby
      (0.32, _GemShape.diamond, Color(0xFF1948E0)), // sapphire
      (0.50, _GemShape.round, Color(0xFF36A8FA)),   // aquamarine (centre)
      (0.68, _GemShape.diamond, Color(0xFF1948E0)), // sapphire
      (0.82, _GemShape.round, Color(0xFFE91E63)),   // ruby
    ];
    for (final (x, shape, gemColor) in gemSpec) {
      _drawGem(canvas, Offset(w * x, gemY), w * 0.04, gemColor, shape);
    }

    // 8) Top-peak jewel (a faceted point gem with shine star)
    _drawTopJewel(canvas, Offset(w * 0.50, h * 0.06), w * 0.07, mid);
  }

  void _drawPearl(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFEFEAE0));
    // Highlight dot
    canvas.drawCircle(
      c.translate(-r * 0.3, -r * 0.3),
      r * 0.4,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawGem(Canvas canvas, Offset c, double r, Color color, _GemShape shape) {
    // Gem fill with radial highlight
    final gemPaint = Paint()
      ..shader = RadialGradient(
        colors: [Color.lerp(color, Colors.white, 0.6)!, color],
        center: const Alignment(-0.3, -0.4),
      ).createShader(Rect.fromCircle(center: c, radius: r));

    if (shape == _GemShape.diamond) {
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r * 0.85, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r * 0.85, c.dy)
        ..close();
      canvas.drawPath(path, gemPaint);
      // Facet line
      canvas.drawLine(
        Offset(c.dx - r * 0.6, c.dy * 1.0),
        Offset(c.dx + r * 0.6, c.dy * 1.0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 0.8,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black.withValues(alpha: 0.35),
      );
    } else {
      canvas.drawCircle(c, r, gemPaint);
      // Sheen
      canvas.drawCircle(
        c.translate(-r * 0.35, -r * 0.35),
        r * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black.withValues(alpha: 0.35),
      );
    }
  }

  void _drawTopJewel(Canvas canvas, Offset c, double r, Color metal) {
    // Faceted point gem (vertical kite)
    final gem = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.7, c.dy - r * 0.1)
      ..lineTo(c.dx, c.dy + r * 0.85)
      ..lineTo(c.dx - r * 0.7, c.dy - r * 0.1)
      ..close();
    canvas.drawPath(
      gem,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, metal],
          center: const Alignment(-0.2, -0.4),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Facet seam
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy + r * 0.85),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 0.8,
    );
    canvas.drawPath(
      gem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.black.withValues(alpha: 0.4),
    );
    // Star-shine cross above the jewel
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - r * 1.05, c.dy - r * 0.6),
      Offset(c.dx + r * 1.05, c.dy - r * 0.6),
      shinePaint,
    );
    canvas.drawLine(
      Offset(c.dx, c.dy - r * 1.5),
      Offset(c.dx, c.dy + r * 0.3),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) =>
      old.rank != rank || old.colors != colors;
}

enum _GemShape { round, diamond }

/// Halo + 12-spark ring orbiting each crown.
class _CrownAuraPainter extends CustomPainter {
  _CrownAuraPainter({required this.t, required this.colors});
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    // Soft halo
    canvas.drawCircle(
      centre,
      r * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.first.withValues(alpha: 0.30),
            colors.first.withValues(alpha: 0.0),
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: r * 0.65)),
    );

    // Orbiting sparks
    const count = 12;
    final angle = t * 2 * math.pi;
    for (var i = 0; i < count; i++) {
      final theta = angle + (math.pi * 2 * i / count);
      final pos = centre + Offset(math.cos(theta), math.sin(theta)) * (r * 0.85);
      final twinkle = (math.sin(t * 6 * math.pi + i) + 1) / 2;
      // Glow
      canvas.drawCircle(
        pos,
        2.4 + twinkle * 1.4,
        Paint()
          ..color = colors.first.withValues(alpha: 0.30 + twinkle * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(
        pos,
        1.2 + twinkle * 0.6,
        Paint()..color = Colors.white.withValues(alpha: 0.6 + twinkle * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrownAuraPainter old) => old.t != t;
}

/// Subtle dotted-grid backdrop, matching the splash screen.
class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1948E0).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

/// 18 ambient sparkles drifting on sin-wave paths across the whole
/// header.
class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({required this.t, required this.tints});
  final double t;
  final List<Color> tints;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 18;
    for (var i = 0; i < count; i++) {
      final phase = (i / count) * 2 * math.pi + t * 2 * math.pi;
      final cx = ((i * 0.13 + t) % 1.0) * size.width;
      final cy = size.height * 0.5 +
          math.sin(phase) * size.height * 0.32 +
          math.cos(phase * 1.7 + i) * 6;
      final twinkle = (math.sin(t * 4 * math.pi + i * 0.7) + 1) / 2;
      final color = tints[i % tints.length];
      // Halo
      canvas.drawCircle(
        Offset(cx, cy),
        2.2 + twinkle * 1.6,
        Paint()
          ..color = color.withValues(alpha: 0.18 + twinkle * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(
        Offset(cx, cy),
        1.0 + twinkle * 0.5,
        Paint()..color = color.withValues(alpha: 0.55 + twinkle * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter old) => old.t != t;
}
