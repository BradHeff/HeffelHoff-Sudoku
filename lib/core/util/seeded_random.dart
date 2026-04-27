import 'dart:math';

class SeededRandom {
  SeededRandom(int seed) : _r = Random(seed), _seed = seed;

  final Random _r;
  final int _seed;

  int get seed => _seed;

  int nextInt(int max) => _r.nextInt(max);
  double nextDouble() => _r.nextDouble();
  bool nextBool() => _r.nextBool();

  List<T> shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _r.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  List<T> shuffled<T>(Iterable<T> source) => shuffle(source.toList());
}
