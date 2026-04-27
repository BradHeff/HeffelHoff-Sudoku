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

            // Three crowns row
            Row(
              children: [
                Expanded(
                  child: _Crown(
                    rank: 2,
                    size: 64,
                    colors: palette.silverFrame,
                    animation: _controller,
                    rotateRange: 0.07,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _Crown(
                    rank: 1,
                    size: 96,
                    colors: palette.goldFrame,
                    animation: _controller,
                    bob: true,
                  ),
                ),
                Expanded(
                  child: _Crown(
                    rank: 3,
                    size: 60,
                    colors: palette.bronzeFrame,
                    animation: _controller,
                    rotateRange: -0.07,
                  ),
                ),
              ],
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

/// Stylised crown silhouette — gradient body, gem at the top, jewel
/// dots on the band.
class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.rank, required this.colors});

  final int rank;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body shape
    final body = Path()
      // bottom-left → bottom-right of band
      ..moveTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.92, h * 0.78)
      // up to right peak
      ..lineTo(w * 0.86, h * 0.30)
      // dip
      ..lineTo(w * 0.66, h * 0.55)
      // centre peak
      ..lineTo(w * 0.50, h * 0.10)
      // dip
      ..lineTo(w * 0.34, h * 0.55)
      // left peak
      ..lineTo(w * 0.14, h * 0.30)
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [colors.first, colors.last],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(body, bodyPaint);

    // Subtle inner highlight stroke
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.3),
    );

    // Band line across the bottom
    canvas.drawLine(
      Offset(w * 0.10, h * 0.78),
      Offset(w * 0.90, h * 0.78),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 2,
    );

    // Three gems along the band
    for (var i = 0; i < 3; i++) {
      final cx = w * (0.30 + 0.20 * i);
      canvas.drawCircle(
        Offset(cx, h * 0.85),
        w * 0.045,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        Offset(cx, h * 0.85),
        w * 0.025,
        Paint()..color = colors.last,
      );
    }

    // Center jewel on the top peak
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.06),
      w * 0.06,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, colors.first],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.06), radius: w * 0.06)),
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) =>
      old.rank != rank || old.colors != colors;
}

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
