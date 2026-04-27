import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Slide-in banner shown briefly at puzzle start: "X.XX% of players have
/// solved this puzzle". Inspired by Sudoku Master. Phase 5 wires the
/// real win-rate from `puzzle_stats`; until then we synthesise a
/// **deterministic** value in [20.00, 40.00] from the puzzle seed so
/// the number stays believable AND stable across rebuilds for the
/// same puzzle.
///
/// Pass `solveRatePercent` for real data; pass `puzzleSeed` to fall
/// back to the deterministic synthetic value.
class PeerSolveBanner extends StatelessWidget {
  const PeerSolveBanner({
    super.key,
    this.solveRatePercent,
    this.puzzleSeed,
  });

  final double? solveRatePercent;
  final int? puzzleSeed;

  /// Synthetic peer-solve % derived from a puzzle seed. Range
  /// [20.00, 40.00], two decimal places. Same seed → same value, so
  /// the banner doesn't flicker on rebuild.
  static double syntheticPercent(int seed) {
    // Mix the seed into a 32-bit hash, take the low 14 bits, scale to
    // [0, 1), then map to [20.00, 40.00].
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
        // Stay visible long enough to actually read at puzzle start.
        .then(delay: 10000.ms)
        .fadeOut(duration: 400.ms)
        .slideY(begin: 0, end: -0.2, duration: 400.ms);
  }
}
