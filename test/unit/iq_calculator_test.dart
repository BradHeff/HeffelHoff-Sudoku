import 'package:flutter_test/flutter_test.dart';
import 'package:heffelhoff_sudoku/features/sudoku/application/iq_calculator.dart';
import 'package:heffelhoff_sudoku/features/sudoku/domain/difficulty.dart';

void main() {
  group('IqCalculator', () {
    test('Easy / 5:00 / no mistakes ≈ 104', () {
      final r = IqCalculator.compute(
        difficulty: Difficulty.easy,
        timeSeconds: 300,
        mistakes: 0,
        hintsUsed: 0,
      );
      // Formula: ratio=0.714 → time_component=lerp(12,0,0.714)≈3.43 → iq≈103.
      expect(r.iqScore, inInclusiveRange(100, 106));
      expect(r.einsteinDelta, r.iqScore - 160);
    });

    test('Hard / 18:00 / 2 mistakes ≈ 124', () {
      final r = IqCalculator.compute(
        difficulty: Difficulty.hard,
        timeSeconds: 18 * 60,
        mistakes: 2,
        hintsUsed: 0,
      );
      expect(r.iqScore, inInclusiveRange(120, 126));
    });

    test('Expert / 25:00 / no mistakes ≈ 149', () {
      final r = IqCalculator.compute(
        difficulty: Difficulty.expert,
        timeSeconds: 25 * 60,
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(r.iqScore, inInclusiveRange(146, 152));
    });

    test('Evil / 35:00 / no mistakes beats Einstein', () {
      final r = IqCalculator.compute(
        difficulty: Difficulty.evil,
        timeSeconds: 35 * 60,
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(r.iqScore, greaterThanOrEqualTo(160));
      expect(r.beatEinstein, isTrue);
    });

    test('Evil / 25:00 / no mistakes scores ~172', () {
      final r = IqCalculator.compute(
        difficulty: Difficulty.evil,
        timeSeconds: 25 * 60,
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(r.iqScore, inInclusiveRange(168, 176));
    });

    test('IQ is clamped to [70, 200]', () {
      final low = IqCalculator.compute(
        difficulty: Difficulty.easy,
        timeSeconds: 12 * 3600, // 12h, very slow
        mistakes: 50,
        hintsUsed: 9,
      );
      expect(low.iqScore, IqCalculator.floorIq);

      final high = IqCalculator.compute(
        difficulty: Difficulty.evil,
        timeSeconds: 1, // sub-floor; clamped time_component to bonus_cap
        mistakes: 0,
        hintsUsed: 0,
      );
      // Evil base 160 + bonus_cap 28 = 188 → not at 200 ceiling but
      // still high; mainly testing it doesn't go above 200.
      expect(high.iqScore, lessThanOrEqualTo(IqCalculator.ceilingIq));
    });

    test('einsteinHeadline branches by delta', () {
      expect(IqCalculator.einsteinHeadline(165), contains('beat Einstein'));
      expect(IqCalculator.einsteinHeadline(160), contains('matched'));
      expect(IqCalculator.einsteinHeadline(155), contains('away from Einstein'));
      expect(IqCalculator.einsteinHeadline(140), contains('catch Einstein'));
      expect(IqCalculator.einsteinHeadline(100), contains('still'));
    });
  });
}
