import 'package:flutter_test/flutter_test.dart';
import 'package:heffelhoff_sudoku/core/util/seeded_random.dart';
import 'package:heffelhoff_sudoku/features/sudoku/data/sudoku_solver.dart';

void main() {
  group('SudokuSolver', () {
    test('isValid accepts a valid solved grid', () {
      final grid = SudokuSolver.randomFullGrid(SeededRandom(42));
      expect(SudokuSolver.isValid(grid), isTrue);
      expect(grid.where((d) => d == 0), isEmpty);
    });

    test('countSolutions of empty grid stops at limit', () {
      final empty = List<int>.filled(81, 0);
      // The count is far greater than 2; we only need to confirm it caps.
      expect(SudokuSolver.countSolutions(empty, limit: 2), 2);
    });

    test('randomFullGrid is deterministic per seed', () {
      final a = SudokuSolver.randomFullGrid(SeededRandom(123));
      final b = SudokuSolver.randomFullGrid(SeededRandom(123));
      expect(a, equals(b));
    });

    test('randomFullGrid produces different grids for different seeds', () {
      final a = SudokuSolver.randomFullGrid(SeededRandom(1));
      final b = SudokuSolver.randomFullGrid(SeededRandom(2));
      expect(a, isNot(equals(b)));
    });

    test('solveInPlace fills in a solvable puzzle', () {
      final grid = List<int>.filled(81, 0);
      // Very lightly clued — still solvable.
      grid[0] = 5;
      grid[10] = 3;
      grid[20] = 8;
      expect(SudokuSolver.solveInPlace(grid), isTrue);
      expect(SudokuSolver.isValid(grid), isTrue);
      expect(grid.where((d) => d == 0), isEmpty);
    });

    test('isValid rejects a row with duplicates', () {
      final grid = List<int>.filled(81, 0);
      grid[0] = 5;
      grid[1] = 5;
      expect(SudokuSolver.isValid(grid), isFalse);
    });
  });
}
