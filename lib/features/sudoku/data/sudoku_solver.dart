import '../../../core/util/seeded_random.dart';

/// Sudoku solver. Operates on flat 81-length List<int> grids (0 = blank).
class SudokuSolver {
  static const int boardSize = 81;

  /// True if the grid breaks no Sudoku constraints.
  static bool isValid(List<int> grid) {
    for (var i = 0; i < 9; i++) {
      var rowMask = 0, colMask = 0, boxMask = 0;
      for (var j = 0; j < 9; j++) {
        final r = grid[i * 9 + j];
        final c = grid[j * 9 + i];
        final br = (i ~/ 3) * 3 + (j ~/ 3);
        final bc = (i % 3) * 3 + (j % 3);
        final b = grid[br * 9 + bc];
        if (r != 0) {
          final bit = 1 << r;
          if (rowMask & bit != 0) return false;
          rowMask |= bit;
        }
        if (c != 0) {
          final bit = 1 << c;
          if (colMask & bit != 0) return false;
          colMask |= bit;
        }
        if (b != 0) {
          final bit = 1 << b;
          if (boxMask & bit != 0) return false;
          boxMask |= bit;
        }
      }
    }
    return true;
  }

  /// Counts solutions, capping at [limit]. Used to verify uniqueness.
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final work = List<int>.from(grid);
    return _countSolutionsImpl(work, limit, 0);
  }

  static int _countSolutionsImpl(List<int> grid, int limit, int found) {
    final idx = _findMostConstrainedEmpty(grid);
    if (idx < 0) return found + 1;

    final row = idx ~/ 9;
    final col = idx % 9;
    final candidates = _candidates(grid, row, col);

    for (var d = 1; d <= 9; d++) {
      if ((candidates >> d) & 1 == 0) continue;
      grid[idx] = d;
      found = _countSolutionsImpl(grid, limit, found);
      if (found >= limit) {
        grid[idx] = 0;
        return found;
      }
    }
    grid[idx] = 0;
    return found;
  }

  /// Solve in-place via backtracking.
  static bool solveInPlace(List<int> grid) {
    final idx = _findMostConstrainedEmpty(grid);
    if (idx < 0) return true;
    final row = idx ~/ 9;
    final col = idx % 9;
    final candidates = _candidates(grid, row, col);
    for (var d = 1; d <= 9; d++) {
      if ((candidates >> d) & 1 == 0) continue;
      grid[idx] = d;
      if (solveInPlace(grid)) return true;
    }
    grid[idx] = 0;
    return false;
  }

  /// Build a fully-solved valid grid, with the candidate order shuffled
  /// per-cell from [rng] so the same seed reproduces the same grid.
  static List<int> randomFullGrid(SeededRandom rng) {
    final grid = List<int>.filled(81, 0);
    _fill(grid, 0, rng);
    return grid;
  }

  static bool _fill(List<int> grid, int idx, SeededRandom rng) {
    if (idx == 81) return true;
    if (grid[idx] != 0) return _fill(grid, idx + 1, rng);

    final row = idx ~/ 9;
    final col = idx % 9;
    final candidates = _candidates(grid, row, col);
    final order = <int>[];
    for (var d = 1; d <= 9; d++) {
      if ((candidates >> d) & 1 == 1) order.add(d);
    }
    rng.shuffle(order);

    for (final d in order) {
      grid[idx] = d;
      if (_fill(grid, idx + 1, rng)) return true;
    }
    grid[idx] = 0;
    return false;
  }

  /// 10-bit mask: bit d (1..9) = digit d is a legal candidate at (row,col).
  static int _candidates(List<int> grid, int row, int col) {
    var used = 0;
    for (var i = 0; i < 9; i++) {
      used |= 1 << grid[row * 9 + i];
      used |= 1 << grid[i * 9 + col];
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        used |= 1 << grid[(br + dr) * 9 + bc + dc];
      }
    }
    return ~used & 0x3FE;
  }

  /// Index of the empty cell with the fewest candidates (MRV), or -1.
  static int _findMostConstrainedEmpty(List<int> grid) {
    var best = -1;
    var bestCount = 10;
    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      final row = i ~/ 9;
      final col = i % 9;
      final mask = _candidates(grid, row, col);
      final count = _popcount(mask);
      if (count < bestCount) {
        bestCount = count;
        best = i;
        if (count <= 1) return i;
      }
    }
    return best;
  }

  static int _popcount(int x) {
    var count = 0;
    while (x != 0) {
      count += x & 1;
      x >>= 1;
    }
    return count;
  }
}
