import 'package:flutter/foundation.dart';

import 'difficulty.dart';

/// A generated Sudoku puzzle: clues string (with blanks), the solution,
/// the seed it was generated from, and the difficulty tier. Stored in
/// the Supabase `puzzles` table on first server submission so the seed
/// can be replayed/verified.
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

  /// 81-char string. '0' = blank cell, '1'..'9' = given clue.
  final String clues;

  /// 81-char string. The unique solution.
  final String solution;

  final int clueCount;
  final int generatorVersion;

  int digitAt(int row, int col) => solution.codeUnitAt(row * 9 + col) - 0x30;

  /// Returns true if [value] at (row,col) matches the canonical solution.
  bool isCorrect({required int row, required int col, required int value}) =>
      digitAt(row, col) == value;
}
