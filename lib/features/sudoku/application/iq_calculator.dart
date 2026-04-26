import '../domain/difficulty.dart';
import '../domain/game_state.dart';

/// Computes a per-puzzle IQ score from time, mistakes, hints, and tier.
///
/// Formula (matches `docs/PLAN.md` and the Postgres `compute_iq`
/// function — keep all three implementations in sync):
///
///   ratio = time_seconds / target_time_for_tier
///   if ratio <= 1.0:
///     time_component = lerp(time_bonus_cap, 0, ratio)
///   else:
///     over = min(ratio - 1.0, 2.0)
///     time_component = -lerp(0, time_penalty_cap, over / 2.0)
///   iq = clamp(round(base + time_component
///                    - 4*mistakes - 6*hints_used), 70, 200)
class IqCalculator {
  static const int einsteinIq = 160;
  static const int floorIq = 70;
  static const int ceilingIq = 200;
  static const int mistakePenaltyPerError = 4;
  static const int hintPenaltyPerHint = 6;

  static IqResult compute({
    required Difficulty difficulty,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
  }) {
    final target = difficulty.targetTimeSeconds;
    final ratio = timeSeconds / target;

    double timeComponent;
    if (ratio <= 1.0) {
      // Faster than target → bonus, scaling linearly from +cap (ratio 0)
      // to 0 (ratio 1.0).
      timeComponent = _lerp(difficulty.timeBonusCap.toDouble(), 0, ratio);
    } else {
      // Slower than target → penalty, capped at -timePenaltyCap when
      // the user takes 3× the target time.
      final over = (ratio - 1.0).clamp(0.0, 2.0);
      timeComponent = -_lerp(0, difficulty.timePenaltyCap.toDouble(), over / 2.0);
    }

    final mistakePenalty = mistakes * mistakePenaltyPerError;
    final hintPenalty = hintsUsed * hintPenaltyPerHint;

    final raw = difficulty.baseIQ + timeComponent - mistakePenalty - hintPenalty;
    final iqScore = raw.round().clamp(floorIq, ceilingIq);

    return IqResult(
      iqScore: iqScore,
      timeComponent: timeComponent.round(),
      mistakePenalty: mistakePenalty,
      hintPenalty: hintPenalty,
      einsteinDelta: iqScore - einsteinIq,
    );
  }

  /// UI headline for the post-game Einstein-comparison bar.
  static String einsteinHeadline(int iqScore) {
    final delta = iqScore - einsteinIq;
    if (delta >= 0) {
      return delta == 0
          ? "You matched Einstein's IQ!"
          : 'You beat Einstein by $delta IQ!';
    }
    final abs = -delta;
    if (abs <= 10) return 'Just $abs points away from Einstein.';
    if (abs <= 25) return '$abs IQ points to catch Einstein. Keep grinding.';
    return "Einstein's still $abs ahead. Climb the tiers.";
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
