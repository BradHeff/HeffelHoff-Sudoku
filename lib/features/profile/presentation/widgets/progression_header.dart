import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../sudoku/application/iq_calculator.dart';
import '../../data/best_iq_repository.dart';

/// Compact home-screen header that shows the player's best IQ across all
/// tiers, animated against the Einstein 160 reference line.
///
/// Three states:
///   • loading — pulsing skeleton at the same height as the loaded layout
///   • empty   — "Solve a puzzle to start your journey" CTA
///   • loaded  — IQ number, tier label, progression bar with Einstein
///               tick, and a delta line ("+12 above Einstein!")
class ProgressionHeader extends ConsumerWidget {
  const ProgressionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntry = ref.watch(userBestIqProvider);
    return asyncEntry.when(
      loading: () => const _LoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entry) => entry == null
          ? const _EmptyState()
          : _Loaded(entry: entry),
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
  const _Loaded({required this.entry});

  final BestIqEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final iq = entry.iq;
    final delta = iq - IqCalculator.einsteinIq;
    final beat = delta >= 0;

    final gradient = beat
        ? palette.iqGenius
        : [scheme.primary, scheme.tertiary];

    return Container(
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
          color: (beat ? palette.iqGenius.first : scheme.primary)
              .withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (beat ? palette.iqGenius.first : scheme.primary)
                .withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -4,
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
                      'Best IQ on ${entry.tier.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
  }
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
