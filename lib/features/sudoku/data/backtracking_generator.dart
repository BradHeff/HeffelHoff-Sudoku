import '../../../core/util/seeded_random.dart';
import '../domain/difficulty.dart';
import '../domain/puzzle.dart';
import 'sudoku_solver.dart';

/// Deterministic Sudoku puzzle generator. Same (seed, difficulty) always
/// produces the same puzzle within a generator version.
class BacktrackingGenerator {
  static const int generatorVersion = 1;
  static const int maxFailedRemovals = 50;

  static Puzzle generate({
    required int seed,
    required Difficulty difficulty,
  }) {
    final rng = SeededRandom(seed);

    final solution = SudokuSolver.randomFullGrid(rng);

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

      final j = 80 - i;
      final di = puzzle[i];
      final dj = puzzle[j];
      puzzle[i] = 0;
      puzzle[j] = 0;

      final isSelfPair = i == j;
      final solutions = SudokuSolver.countSolutions(puzzle, limit: 2);
      if (solutions == 1) {
        removed += isSelfPair ? 1 : 2;
        consecutiveFails = 0;
      } else {
        puzzle[i] = di;
        puzzle[j] = dj;
        consecutiveFails++;
      }
    }

    return Puzzle(
      seed: seed,
      difficulty: difficulty,
      clues: _digitsToString(puzzle),
      solution: _digitsToString(solution),
      clueCount: puzzle.where((d) => d != 0).length,
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

Puzzle generatePuzzleIsolate(GeneratePuzzleArgs args) =>
    BacktrackingGenerator.generate(seed: args.seed, difficulty: args.difficulty);

class GeneratePuzzleArgs {
  const GeneratePuzzleArgs({required this.seed, required this.difficulty});
  final int seed;
  final Difficulty difficulty;
}
