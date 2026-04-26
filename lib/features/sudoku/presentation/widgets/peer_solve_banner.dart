import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Slide-in banner shown briefly at puzzle start: "X.XX% of players have
/// solved this puzzle". Inspired by Sudoku Master. Phase 1 shows a
/// placeholder; Phase 5 wires the real win-rate from `puzzle_stats`.
///
/// Pass `solveRatePercent == null` to render a "—%" placeholder.
class PeerSolveBanner extends StatelessWidget {
  const PeerSolveBanner({
    super.key,
    required this.solveRatePercent,
  });

  final double? solveRatePercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pct = solveRatePercent == null
        ? '—'
        : solveRatePercent!.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: text.headlineMedium?.copyWith(
              color: scheme.tertiary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            solveRatePercent == null
                ? 'Be one of the first to solve this puzzle'
                : 'of players have solved this puzzle',
            style: text.bodyMedium?.copyWith(color: scheme.onPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.4, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 250.ms)
        .then(delay: 1800.ms)
        .fadeOut(duration: 350.ms)
        .slideY(begin: 0, end: -0.2, duration: 350.ms);
  }
}
