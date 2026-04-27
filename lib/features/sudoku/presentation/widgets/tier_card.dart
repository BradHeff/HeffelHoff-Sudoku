import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/difficulty.dart';

/// Visual styling per tier — escalates from a calm cyan card (Easy) to
/// a gold/violet glowing animated frame with particle aura (Evil) so
/// the difficulty ladder *feels* like it's getting more elite.
///
/// Static config (icon, label, gradient stops) is paired with an
/// `intensity` 0..4 that drives runtime animation hooks (icon pulse,
/// border hue rotation, particle aura, shimmer sweep).
class _TierStyle {
  const _TierStyle({
    required this.rankLabel,
    required this.icon,
    required this.accent,
    required this.intensity,
  });

  /// e.g. "BEGINNER", "NOVICE", "ADEPT", "MASTER", "ELITE"
  final String rankLabel;
  final IconData icon;

  /// Border / icon-glow gradient. 2 colours — start + end.
  final List<Color> accent;

  /// 0 = static card, 4 = full glow + particle aura + shimmer.
  final int intensity;

  static const Map<Difficulty, _TierStyle> values = {
    Difficulty.easy: _TierStyle(
      rankLabel: 'BEGINNER',
      icon: Icons.school_outlined,
      accent: [Color(0xFF36A8FA), Color(0xFF1948E0)],
      intensity: 0,
    ),
    Difficulty.medium: _TierStyle(
      rankLabel: 'NOVICE',
      icon: Icons.psychology_outlined,
      accent: [Color(0xFF36A8FA), Color(0xFFA35DF4)],
      intensity: 1,
    ),
    Difficulty.hard: _TierStyle(
      rankLabel: 'ADEPT',
      icon: Icons.auto_awesome,
      accent: [Color(0xFFA35DF4), Color(0xFF36A8FA)],
      intensity: 2,
    ),
    Difficulty.expert: _TierStyle(
      rankLabel: 'MASTER',
      icon: Icons.bolt,
      accent: [Color(0xFFFFA500), Color(0xFFA35DF4)],
      intensity: 3,
    ),
    Difficulty.evil: _TierStyle(
      rankLabel: 'ELITE',
      icon: Icons.local_fire_department,
      accent: [Color(0xFFFFD700), Color(0xFFE91E63)],
      intensity: 4,
    ),
  };
}

/// A single difficulty tile. Layered architecture:
///   Layer 0 — base card surface
///   Layer 1 — animated gradient border (intensity ≥ 2)
///   Layer 2 — particle aura overlay (intensity ≥ 3)
///   Layer 3 — content (icon + label block + chevron)
///   Layer 4 — shimmer sweep (intensity = 4)
class TierCard extends StatefulWidget {
  const TierCard({
    super.key,
    required this.tier,
    required this.onTap,
  });

  final Difficulty tier;
  final VoidCallback onTap;

  @override
  State<TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<TierCard> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    final style = _TierStyle.values[widget.tier]!;
    if (style.intensity >= 2) _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _TierStyle.values[widget.tier]!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;

    final cardHeight = 92.0 + (style.intensity * 6);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 1: animated gradient border (intensity ≥ 2).
            if (style.intensity >= 2)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (context, _) => CustomPaint(
                    painter: _GradientBorderPainter(
                      colors: style.accent,
                      intensity: style.intensity,
                      t: _spin.value,
                    ),
                  ),
                ),
              ),

            // Layer 0 + 3 (base card + content)
            Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: style.intensity < 2
                      ? Border.all(
                          color: style.accent.first.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                  boxShadow: style.intensity >= 1
                      ? [
                          BoxShadow(
                            color: style.accent.first.withValues(
                              alpha: 0.18 + style.intensity * 0.06,
                            ),
                            blurRadius: 12 + style.intensity * 4.0,
                            spreadRadius: style.intensity * 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Layer 2: particle aura
                    if (style.intensity >= 3)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _spin,
                          builder: (context, _) => CustomPaint(
                            painter: _ParticleAuraPainter(
                              colors: style.accent,
                              t: _spin.value,
                              count: 5 + style.intensity * 2,
                            ),
                          ),
                        ),
                      ),

                    // Layer 4: shimmer sweep (Evil only)
                    if (style.intensity >= 4)
                      Positioned.fill(
                        child: const _ShimmerSweep(),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          _TierIcon(style: style, palette: palette),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.tier.label,
                                      style: text.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _RankBadge(style: style),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Base IQ ${widget.tier.baseIQ} · target ${_fmtTime(widget.tier.targetTimeSeconds)}',
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: style.intensity >= 3
                                ? style.accent.first
                                : scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _TierIcon extends StatelessWidget {
  const _TierIcon({required this.style, required this.palette});
  final _TierStyle style;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget icon = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            style.accent.first.withValues(alpha: 0.18),
            style.accent.last.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: style.accent.first.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(colors: style.accent).createShader(rect),
        child: Icon(style.icon, color: Colors.white, size: 28),
      ),
    );

    // Pulse on intensity ≥ 1.
    if (style.intensity >= 1) {
      icon = icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.0 + 0.04 * style.intensity,
            duration: (1500 - 150 * style.intensity).ms,
            curve: Curves.easeInOut,
          );
    }
    // Decorative orbiting dot for Master+ (intensity ≥ 3).
    if (style.intensity >= 3) {
      icon = SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            icon,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.accent.first,
                  boxShadow: [
                    BoxShadow(color: style.accent.first.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(end: 1.4, duration: 800.ms, curve: Curves.easeInOut)
                  .fade(begin: 1.0, end: 0.4, duration: 800.ms),
            ),
          ],
        ),
      );
    }
    // Suppress unused field hint; gold glow could be intensified here.
    if (palette.goldFrame.isEmpty) return icon;
    return icon;
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.style});
  final _TierStyle style;

  @override
  Widget build(BuildContext context) {
    final isElite = style.intensity >= 3;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: isElite ? LinearGradient(colors: style.accent) : null,
        color: isElite ? null : style.accent.first.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: isElite
            ? null
            : Border.all(color: style.accent.first.withValues(alpha: 0.55)),
      ),
      child: Text(
        style.rankLabel,
        style: TextStyle(
          color: isElite ? Colors.black.withValues(alpha: 0.85) : style.accent.first,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
    if (style.intensity >= 4) {
      // Final badge subtly throbs.
      return pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
    }
    return pill;
  }
}

/// Animated gradient border. Repaints with a hue-rotated gradient angle
/// using `t` ∈ [0, 1) as the rotation phase.
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.colors,
    required this.intensity,
    required this.t,
  });

  final List<Color> colors;
  final int intensity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = const Radius.circular(20);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    final angle = t * 2 * math.pi;
    final gradient = SweepGradient(
      colors: [
        colors.first,
        colors.last,
        colors.first,
        colors.last,
        colors.first,
      ],
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + intensity * 0.4;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.t != t || old.intensity != intensity;
}

/// Floating particle dots that drift inside the card. Pure decoration.
class _ParticleAuraPainter extends CustomPainter {
  _ParticleAuraPainter({
    required this.colors,
    required this.t,
    required this.count,
  });

  final List<Color> colors;
  final double t;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      // Each particle has a stable per-i phase; they orbit elliptically.
      final phase = (i / count + t) * 2 * math.pi;
      final cx = size.width * (0.1 + 0.8 * (i / count));
      final cy = size.height / 2 + math.sin(phase) * (size.height * 0.25);
      final radius = 2.0 + (math.sin(phase * 1.7) + 1) * 1.2;
      final color = colors[i % colors.length].withValues(alpha: 0.55);
      // Halo
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleAuraPainter old) => old.t != t;
}

class _ShimmerSweep extends StatelessWidget {
  const _ShimmerSweep();

  @override
  Widget build(BuildContext context) {
    // Diagonal white sheen sweeps L→R, then pauses.
    return IgnorePointer(
      child: Container(color: Colors.transparent)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 2400.ms,
            color: Colors.white.withValues(alpha: 0.18),
            angle: 0.3,
          ),
    );
  }
}
