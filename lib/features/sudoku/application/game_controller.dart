import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backtracking_generator.dart';
import '../domain/board.dart';
import '../domain/difficulty.dart';
import '../domain/game_state.dart';
import '../domain/puzzle.dart';
import 'iq_calculator.dart';

/// State notifier driving an active Sudoku game. Owns the timer, lives,
/// mistake counter, pencil mode, and validation against the canonical
/// solution. Lives default to 3 (free) — Phase 6 wires Pro to bump to 5.
class GameController extends StateNotifier<GameState> {
  GameController({required Difficulty difficulty, int? seed, int maxLives = 3})
      : _maxLives = maxLives,
        super(GameLoading(difficulty: difficulty)) {
    _start(difficulty: difficulty, seed: seed);
  }

  final int _maxLives;
  Timer? _ticker;

  Future<void> _start({required Difficulty difficulty, int? seed}) async {
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    try {
      // Phase 1: run on the main isolate; Phase 1+ swap to compute() once
      // perf testing on real devices proves it's needed.
      final puzzle = await _generate(seed: s, difficulty: difficulty);
      final board = Board.fromClues(puzzle.clues);
      state = GameOngoing(
        puzzle: puzzle,
        board: board,
        selected: null,
        lives: _maxLives,
        maxLives: _maxLives,
        mistakes: 0,
        hintsUsed: 0,
        elapsed: Duration.zero,
        startedAt: DateTime.now(),
        pencilMode: false,
        paused: false,
      );
      _startTicker();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Generator failed: $e\n$st');
      }
      state = const GameError('Could not generate a puzzle. Please try again.');
    }
  }

  Future<Puzzle> _generate({required int seed, required Difficulty difficulty}) async {
    return BacktrackingGenerator.generate(seed: seed, difficulty: difficulty);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s is GameOngoing && !s.paused) {
        state = s.copyWith(elapsed: s.elapsed + const Duration(seconds: 1));
      }
    });
  }

  void selectCell(int row, int col) {
    final s = state;
    if (s is! GameOngoing) return;
    state = s.copyWith(selected: (row: row, col: col));
  }

  void togglePencil() {
    final s = state;
    if (s is! GameOngoing) return;
    state = s.copyWith(pencilMode: !s.pencilMode);
  }

  void setPaused(bool paused) {
    final s = state;
    if (s is! GameOngoing) return;
    state = s.copyWith(paused: paused);
  }

  /// User taps a digit on the number pad. Returns true if the entry was
  /// accepted (correct or pencil), false if it was a wrong placement.
  bool enterDigit(int digit) {
    final s = state;
    if (s is! GameOngoing) return false;
    final sel = s.selected;
    if (sel == null) return false;
    final cell = s.board.at(sel.row, sel.col);
    if (cell.isGiven) return false;

    // Pencil mode: toggle the candidate bit, no validation, no life loss.
    if (s.pencilMode && cell.isEmpty) {
      final mask = cell.pencilMarks ^ (1 << (digit - 1));
      state = s.copyWith(board: s.board.withCell(cell.copyWith(pencilMarks: mask)));
      return true;
    }

    // Same digit re-tapped on a filled cell → erase.
    if (cell.value == digit) {
      state = s.copyWith(
        board: s.board.withCell(cell.copyWith(value: 0, pencilMarks: 0, isWrong: false)),
      );
      return true;
    }

    final correct = s.puzzle.isCorrect(row: sel.row, col: sel.col, value: digit);
    if (correct) {
      final next = s.board.withCell(cell.copyWith(value: digit, pencilMarks: 0, isWrong: false));
      _afterPlacement(s, next);
      return true;
    }

    // Wrong: place visibly, mark wrong, decrement lives.
    final wrongCell = cell.copyWith(value: digit, pencilMarks: 0, isWrong: true);
    final lives = s.lives - 1;
    final mistakes = s.mistakes + 1;
    final boardWithWrong = s.board.withCell(wrongCell);
    state = s.copyWith(board: boardWithWrong, lives: lives, mistakes: mistakes);

    // Auto-clear the wrong entry after a brief delay so the player can retry.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      final cur = state;
      if (cur is GameOngoing) {
        final c = cur.board.at(sel.row, sel.col);
        if (c.isWrong) {
          state = cur.copyWith(
            board: cur.board.withCell(c.copyWith(value: 0, isWrong: false)),
          );
        }
      }
    });

    if (lives <= 0) {
      _stopTicker();
      state = GameLost(
        puzzle: s.puzzle,
        timeSeconds: s.elapsed.inSeconds,
        mistakes: mistakes,
      );
    }
    return false;
  }

  void erase() {
    final s = state;
    if (s is! GameOngoing) return;
    final sel = s.selected;
    if (sel == null) return;
    final cell = s.board.at(sel.row, sel.col);
    if (cell.isGiven || cell.isEmpty) return;
    state = s.copyWith(
      board: s.board.withCell(cell.copyWith(value: 0, pencilMarks: 0, isWrong: false)),
    );
  }

  /// Reveal the correct digit at the selected cell. Counts as a hint
  /// and incurs the hint IQ penalty.
  void useHint() {
    final s = state;
    if (s is! GameOngoing) return;
    final sel = s.selected;
    if (sel == null) return;
    final cell = s.board.at(sel.row, sel.col);
    if (cell.isGiven) return;
    final correct = s.puzzle.digitAt(sel.row, sel.col);
    final next = s.board.withCell(
      cell.copyWith(value: correct, pencilMarks: 0, isWrong: false),
    );
    _afterPlacement(s.copyWith(hintsUsed: s.hintsUsed + 1), next);
  }

  void _afterPlacement(GameOngoing s, Board next) {
    if (next.isFull) {
      _stopTicker();
      final time = s.elapsed.inSeconds;
      final iq = IqCalculator.compute(
        difficulty: s.difficulty,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
      );
      state = GameWon(
        puzzle: s.puzzle,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
        livesRemaining: s.lives,
        iqScore: iq.iqScore,
      );
    } else {
      state = s.copyWith(board: next);
    }
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

/// Family provider — keyed by difficulty + optional seed. Pass a seed
/// for testability; pass null to use the wall clock.
final gameControllerProvider = StateNotifierProvider.autoDispose
    .family<GameController, GameState, ({Difficulty difficulty, int? seed})>(
  (ref, args) => GameController(difficulty: args.difficulty, seed: args.seed),
);
