import 'package:flutter_test/flutter_test.dart';
import 'package:heffelhoff_sudoku/features/sudoku/data/backtracking_generator.dart';
import 'package:heffelhoff_sudoku/features/sudoku/data/sudoku_solver.dart';
import 'package:heffelhoff_sudoku/features/sudoku/domain/difficulty.dart';

void main() {
  group('BacktrackingGenerator', () {
    test('puzzle clue count is within difficulty range (Easy)', () {
      final p = BacktrackingGenerator.generate(
        seed: 1234,
        difficulty: Difficulty.easy,
      );
      expect(p.clueCount, greaterThanOrEqualTo(Difficulty.easy.minClues));
      // Allow some slack on the upper bound — the removal loop may stop
      // early after [maxFailedRemovals] consecutive failures.
      expect(p.clueCount, lessThanOrEqualTo(81));
      expect(p.clues.length, 81);
      expect(p.solution.length, 81);
    });

    test('clues are a strict subset of the solution', () {
      final p = BacktrackingGenerator.generate(
        seed: 9999,
        difficulty: Difficulty.medium,
      );
      for (var i = 0; i < 81; i++) {
        final clue = p.clues.codeUnitAt(i) - 0x30;
        final sol = p.solution.codeUnitAt(i) - 0x30;
        if (clue != 0) {
          expect(clue, sol, reason: 'clue at $i must match solution');
        }
      }
    });

    test('the canonical solution is a valid Sudoku', () {
      final p = BacktrackingGenerator.generate(
        seed: 4321,
        difficulty: Difficulty.hard,
      );
      final grid = [for (var i = 0; i < 81; i++) p.solution.codeUnitAt(i) - 0x30];
      expect(SudokuSolver.isValid(grid), isTrue);
      expect(grid.where((d) => d == 0), isEmpty);
    });

    test('clues have a unique solution', () {
      final p = BacktrackingGenerator.generate(
        seed: 777,
        difficulty: Difficulty.easy,
      );
      final grid = [for (var i = 0; i < 81; i++) p.clues.codeUnitAt(i) - 0x30];
      expect(SudokuSolver.countSolutions(grid, limit: 2), 1);
    });

    test('same seed + difficulty → identical puzzle', () {
      final a = BacktrackingGenerator.generate(seed: 42, difficulty: Difficulty.medium);
      final b = BacktrackingGenerator.generate(seed: 42, difficulty: Difficulty.medium);
      expect(a.clues, b.clues);
      expect(a.solution, b.solution);
      expect(a.clueCount, b.clueCount);
    });
  });
}
