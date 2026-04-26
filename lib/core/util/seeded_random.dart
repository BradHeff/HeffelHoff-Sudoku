import 'dart:math';

/// Deterministic PRNG wrapper. Uses dart:math `Random` with an explicit
/// seed so puzzle generation is reproducible — same seed + same difficulty
/// + same generator_version always produces the same puzzle, which is
/// what lets the server verify a submitted solution by recomputing.
class SeededRandom {
  SeededRandom(int seed) : _r = Random(seed), _seed = seed;

  final Random _r;
  final int _seed;

  int get seed => _seed;

  int nextInt(int max) => _r.nextInt(max);
  double nextDouble() => _r.nextDouble();
  bool nextBool() => _r.nextBool();

  /// Fisher-Yates shuffle in place. Stable for a given seed.
  List<T> shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _r.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  /// Returns a copy of the input shuffled with this PRNG.
  List<T> shuffled<T>(Iterable<T> source) => shuffle(source.toList());
}
