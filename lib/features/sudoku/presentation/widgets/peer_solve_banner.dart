import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "X.XX% of players have solved this puzzle" banner shown at start.
class PeerSolveBanner extends StatelessWidget {
  const PeerSolveBanner({
    super.key,
    this.solveRatePercent,
    this.puzzleSeed,
  });

  final double? solveRatePercent;
  final int? puzzleSeed;

  /// Synthetic peer-solve % from a puzzle seed (range [20.00, 40.00]).
  static double syntheticPercent(int seed) {
    final mixed = (seed.abs() ^ 0x9E3779B9) * 2654435761;
    final fraction = (mixed.abs() & 0x3FFF) / 0x4000;
    final pct = 20.0 + fraction * 20.0;
    return double.parse(pct.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final effectivePct = solveRatePercent ??
        (puzzleSeed != null ? syntheticPercent(puzzleSeed!) : null);
    final pct = effectivePct == null ? '—' : effectivePct.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: text.headlineMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            effectivePct == null
                ? 'Be one of the first to solve this puzzle'
                : 'of players have solved this puzzle',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.4, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 250.ms)
        .then(delay: 10000.ms)
        .fadeOut(duration: 400.ms)
        .slideY(begin: 0, end: -0.2, duration: 400.ms);
  }
}
