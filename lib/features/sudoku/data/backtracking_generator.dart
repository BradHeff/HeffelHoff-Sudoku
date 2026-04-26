import '../../../core/util/seeded_random.dart';
import '../domain/difficulty.dart';
import '../domain/puzzle.dart';
import 'sudoku_solver.dart';

/// Generates a Sudoku puzzle deterministically from a (seed, difficulty)
/// pair. Algorithm:
///
///   1. Build a fully-solved random valid grid (seeded backtracking).
///   2. Iterate over all 81 cells in a seed-shuffled order. For each
///      cell + its 180°-rotational symmetric partner, blank the pair
///      and verify the puzzle still has a unique solution. Restore if
///      not unique.
///   3. Stop when the remaining clue count hits the tier's lower bound,
///      or after [maxFailedRemovals] consecutive failed removals.
///
/// Pure Dart, safe to run in an isolate via `compute()`.
class BacktrackingGenerator {
  static const int generatorVersion = 1;
  static const int maxFailedRemovals = 50;

  /// Generates a puzzle. The same `(seed, difficulty)` always produces
  /// the same puzzle (within a [generatorVersion]).
  static Puzzle generate({
    required int seed,
    required Difficulty difficulty,
  }) {
    final rng = SeededRandom(seed);

    // 1) Full solved grid.
    final solution = SudokuSolver.randomFullGrid(rng);

    // 2) Symmetric clue removal.
    final puzzle = List<int>.from(solution);
    final order = List<int>.generate(81, (i) => i);
    rng.shuffle(order);

    var removed = 0;
    var consecutiveFails = 0;
    final targetClueCount = difficulty.minClues +
        rng.nextInt(difficulty.maxClues - difficulty.minClues + 1);
    final cellsToRemove = 81 - targetClueCount;

    for (final i in order) {
      if (removed >= cellsToRemove) break;
      if (consecutiveFails >= maxFailedRemovals) break;
      if (puzzle[i] == 0) continue;

      final j = 80 - i; // 180° rotational partner
      final di = puzzle[i];
      final dj = puzzle[j];
      puzzle[i] = 0;
      puzzle[j] = 0;

      final isSelfPair = i == j;

      // Uniqueness check — count up to 2 solutions; ≥2 means non-unique.
      final solutions = SudokuSolver.countSolutions(puzzle, limit: 2);
      if (solutions == 1) {
        removed += isSelfPair ? 1 : 2;
        consecutiveFails = 0;
      } else {
        // Restore.
        puzzle[i] = di;
        puzzle[j] = dj;
        consecutiveFails++;
      }
    }

    final cluesString = _digitsToString(puzzle);
    final solutionString = _digitsToString(solution);
    final clueCount = puzzle.where((d) => d != 0).length;

    return Puzzle(
      seed: seed,
      difficulty: difficulty,
      clues: cluesString,
      solution: solutionString,
      clueCount: clueCount,
      generatorVersion: generatorVersion,
    );
  }

  static String _digitsToString(List<int> grid) {
    final buf = StringBuffer();
    for (final d in grid) {
      buf.writeCharCode(0x30 + d);
    }
    return buf.toString();
  }
}

/// Top-level function for `compute(generatePuzzleIsolate, args)`. Flutter's
/// isolate helpers require a top-level or static function reference.
Puzzle generatePuzzleIsolate(GeneratePuzzleArgs args) =>
    BacktrackingGenerator.generate(seed: args.seed, difficulty: args.difficulty);

class GeneratePuzzleArgs {
  const GeneratePuzzleArgs({required this.seed, required this.difficulty});
  final int seed;
  final Difficulty difficulty;
}
