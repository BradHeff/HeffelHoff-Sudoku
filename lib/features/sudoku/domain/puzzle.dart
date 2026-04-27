import 'package:flutter/foundation.dart';

import 'difficulty.dart';

@immutable
class Puzzle {
  const Puzzle({
    required this.seed,
    required this.difficulty,
    required this.clues,
    required this.solution,
    required this.clueCount,
    this.generatorVersion = 1,
  });

  final int seed;
  final Difficulty difficulty;
  final String clues;
  final String solution;
  final int clueCount;
  final int generatorVersion;

  int digitAt(int row, int col) => solution.codeUnitAt(row * 9 + col) - 0x30;

  bool isCorrect({required int row, required int col, required int value}) =>
      digitAt(row, col) == value;
}
