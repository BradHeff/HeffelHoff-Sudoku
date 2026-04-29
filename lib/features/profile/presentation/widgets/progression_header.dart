import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../sudoku/application/iq_calculator.dart';
import '../../../sudoku/domain/difficulty.dart';
import '../../data/best_iq_repository.dart';

/// IQ threshold above which the header sprouts a corner crown. 130 is
/// the Hard-tier base IQ and the rough "above-average" IQ marker — high
/// enough to feel earned but achievable without a perfect run.
const int _crownIqThreshold = 130;

/// Compact home-screen header that shows the player's best IQ across all
/// tiers, animated against the Einstein 160 reference line.
///
/// Three states:
///   • loading — pulsing skeleton at the same height as the loaded layout
///   • empty   — "Solve a puzzle to start your journey" CTA
///   • loaded  — IQ number, tier label, progression bar with Einstein
///               tick, and a delta line ("+12 above Einstein!"). Sprouts
///               a corner crown when IQ >= 130 or when the user holds
///               the #1 spot on any tier.
class ProgressionHeader extends ConsumerWidget {
  const ProgressionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntry = ref.watch(userBestIqProvider);
    final topRanks =
        ref.watch(userTopRanksProvider).asData?.value ?? const TopRankInfo(tiers: []);
    return asyncEntry.when(
      loading: () => const _LoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entry) => entry == null
          ? const _EmptyState()
          : _Loaded(entry: entry, topRanks: topRanks),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 116,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeOut(duration: 800.ms, begin: 1, curve: Curves.easeInOut);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.tertiary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: palette.iqGenius.first, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR PROGRESSION',
                  style: iqDisplayStyle(context, size: 11, color: scheme.onSurfaceVariant)
                      .copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solve your first puzzle to start the climb to Einstein.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.entry, required this.topRanks});

  final BestIqEntry entry;
  final TopRankInfo topRanks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final iq = entry.iq;
    final delta = iq - IqCalculator.einsteinIq;
    final beat = delta >= 0;
    final isHighIq = iq >= _crownIqThreshold;
    final hasTopRank = topRanks.hasAny;

    // Top-rank wins styling priority over the Einstein-beat gradient —
    // holding #1 anywhere is rarer than scoring 160+.
    final List<Color> gradient;
    final Color accent;
    if (hasTopRank) {
      gradient = palette.goldFrame;
      accent = palette.goldFrame.first;
    } else if (beat) {
      gradient = palette.iqGenius;
      accent = palette.iqGenius.first;
    } else if (isHighIq) {
      gradient = palette.goldFrame;
      accent = palette.goldFrame.last;
    } else {
      gradient = [scheme.primary, scheme.tertiary];
      accent = scheme.primary;
    }

    final card = Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLow,
            scheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: hasTopRank ? 0.85 : 0.55),
          width: hasTopRank ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: hasTopRank ? 0.32 : 0.18),
            blurRadius: hasTopRank ? 28 : 20,
            spreadRadius: hasTopRank ? -2 : -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YOUR PROGRESSION',
                      style: iqDisplayStyle(context, size: 11, color: scheme.onSurfaceVariant)
                          .copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTopRank
                          ? '#1 on ${_tiersLabel(topRanks.tiers)}'
                          : 'Best IQ on ${entry.tier.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasTopRank ? accent : scheme.onSurfaceVariant,
                            fontWeight: hasTopRank ? FontWeight.w800 : null,
                          ),
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (rect) =>
                    LinearGradient(colors: gradient).createShader(rect),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: iq.toDouble()),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    v.round().toString(),
                    style: iqDisplayStyle(context, size: 44, color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressionBar(iq: iq, gradient: gradient),
          const SizedBox(height: 8),
          Text(
            IqCalculator.einsteinHeadline(iq),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: beat ? palette.iqGenius.first : scheme.onSurfaceVariant,
                  fontWeight: beat ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.1);

    if (!hasTopRank && !isHighIq) return card;

    // Crown perches on the top-right corner, tilted +45° so it reads
    // like a corner ribbon — its body sits mostly outside the card's
    // bounds and the angle carries the eye away from the IQ number on
    // the right side of the header row.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -22,
          right: -22,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: _CrownBadge(
              colors: gradient,
              isLegendary: hasTopRank,
            ),
          ),
        ),
      ],
    );
  }

  static String _tiersLabel(List<Difficulty> tiers) {
    if (tiers.length == 1) return tiers.first.label;
    if (tiers.length == 2) return '${tiers[0].label} & ${tiers[1].label}';
    return '${tiers.length} tiers';
  }
}

/// Hand-painted crown emblem. Idle state shows a static gold crown for
/// IQ >= 130; legendary state (top rank) adds a slow pulse + shimmer to
/// draw the eye.
class _CrownBadge extends StatelessWidget {
  const _CrownBadge({required this.colors, required this.isLegendary});

  final List<Color> colors;
  final bool isLegendary;

  @override
  Widget build(BuildContext context) {
    final size = isLegendary ? 44.0 : 36.0;
    final crown = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft halo behind the crown so it pops on dark backgrounds.
          Container(
            width: size + 12,
            height: size + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: isLegendary ? 0.55 : 0.35),
                  blurRadius: isLegendary ? 18 : 12,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _CrownPainter(gradient: colors),
          ),
        ],
      ),
    );

    if (!isLegendary) {
      return crown
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -2, duration: 1600.ms, curve: Curves.easeInOut);
    }
    return crown
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2400.ms, color: Colors.white.withValues(alpha: 0.85))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.08, duration: 1400.ms, curve: Curves.easeInOut);
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.gradient});

  final List<Color> gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..isAntiAlias = true;
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    // Three-spike crown silhouette. Bottom band sits across the lower
    // ~25% of the bounds; spikes peak at top.
    final path = Path()
      ..moveTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.08, h * 0.46)
      ..lineTo(w * 0.20, h * 0.78)
      ..lineTo(w * 0.30, h * 0.18)
      ..lineTo(w * 0.42, h * 0.62)
      ..lineTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.58, h * 0.62)
      ..lineTo(w * 0.70, h * 0.18)
      ..lineTo(w * 0.80, h * 0.78)
      ..lineTo(w * 0.92, h * 0.46)
      ..lineTo(w * 0.92, h * 0.78)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    // Bottom band rectangle.
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.06, h * 0.72, w * 0.94, h * 0.92),
      const Radius.circular(2),
    );
    canvas.drawRRect(band, fill);
    canvas.drawRRect(band, outline);

    // Jewels on the three spike tips.
    final jewel = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.30, h * 0.28), w * 0.05, jewel);
    canvas.drawCircle(Offset(w * 0.50, h * 0.16), w * 0.06, jewel);
    canvas.drawCircle(Offset(w * 0.70, h * 0.28), w * 0.05, jewel);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => old.gradient != gradient;
}

class _ProgressionBar extends StatelessWidget {
  const _ProgressionBar({required this.iq, required this.gradient});

  final int iq;
  final List<Color> gradient;

  static const _min = IqCalculator.floorIq;
  static const _max = IqCalculator.ceilingIq;

  double _ratio(int v) => ((v - _min) / (_max - _min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final einsteinX = width * _ratio(IqCalculator.einsteinIq);
        return SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: 0,
                top: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: width * _ratio(iq)),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, w, _) => Container(
                    width: w,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: einsteinX - 1,
                top: 4,
                child: Container(width: 2, height: 22, color: scheme.outline),
              ),
              Positioned(
                left: einsteinX - 24,
                top: 0,
                child: Text(
                  'Einstein',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
