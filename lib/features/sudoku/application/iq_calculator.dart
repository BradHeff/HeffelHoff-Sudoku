import '../domain/difficulty.dart';
import '../domain/game_state.dart';

/// Per-puzzle IQ from time, mistakes, hints, and tier. Mirrors the
/// Postgres compute_iq() function and docs/PLAN.md — keep in sync.
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
      timeComponent = _lerp(difficulty.timeBonusCap.toDouble(), 0, ratio);
    } else {
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

  /// Headline copy for the post-game Einstein-comparison bar.
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
