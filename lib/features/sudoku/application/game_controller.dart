import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
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
  GameController({
    required Difficulty difficulty,
    required SoundService sound,
    int? seed,
    int maxLives = 3,
  })  : _maxLives = maxLives,
        _sound = sound,
        super(GameLoading(difficulty: difficulty)) {
    _start(difficulty: difficulty, seed: seed);
  }

  final int _maxLives;
  final SoundService _sound;
  Timer? _ticker;
  Timer? _digitCelebrationTimer;

  /// How long the digit-complete celebration stays on screen before
  /// being cleared.
  static const Duration kDigitCelebrationDuration = Duration(milliseconds: 1500);

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

  /// Tap-to-select. Highlight rules per docs:
  ///   - Tap a filled cell → highlight that digit.
  ///   - Tap an empty cell while a highlight is active → keep it
  ///     (user is *intending* to enter that digit there).
  ///   - Tap a *second* empty cell without entering anything between
  ///     them → clear the highlight (lost intent).
  void selectCell(int row, int col) {
    final s = state;
    if (s is! GameOngoing) return;

    final newCell = s.board.at(row, col);
    final prev = s.selected;
    final prevCell = prev != null ? s.board.at(prev.row, prev.col) : null;
    final prevWasFilled = prevCell != null && prevCell.value != 0 && !prevCell.isWrong;

    int? nextHighlight;
    var clearHighlight = false;
    if (newCell.value != 0 && !newCell.isWrong) {
      // Filled cell tapped — highlight that digit.
      nextHighlight = newCell.value;
    } else if (prevWasFilled && s.highlightedDigit != null) {
      // First empty-cell tap after a filled-cell tap — keep the highlight.
      nextHighlight = s.highlightedDigit;
    } else {
      // Empty → empty (or no prior selection) — clear.
      clearHighlight = true;
    }

    state = s.copyWith(
      selected: (row: row, col: col),
      highlightedDigit: nextHighlight,
      clearHighlight: clearHighlight,
    );
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
      // Successful placement → make the just-placed digit the new
      // highlight so chain entries flow naturally.
      _sound.play(SoundEvent.placeCorrect);
      _afterPlacement(
        s.copyWith(highlightedDigit: digit),
        next,
        placedDigit: digit,
        placedRow: sel.row,
        placedCol: sel.col,
      );
      return true;
    }

    // Wrong: place visibly, mark wrong, decrement lives.
    _sound.play(SoundEvent.placeWrong);
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
  ///
  /// If no cell is currently selected, OR the selected cell is already
  /// filled correctly / is a given clue, the hint walks the board left-
  /// to-right, top-to-bottom and uses the first empty (or wrong-flagged)
  /// cell. This matches mainstream Sudoku UX — Hint always *does
  /// something*.
  void useHint() {
    final s = state;
    if (s is! GameOngoing) return;

    var sel = s.selected;

    bool needsRetarget(({int row, int col}) target) {
      final c = s.board.at(target.row, target.col);
      // Need a new target if the current one is given OR already
      // filled with the correct value (no work to do).
      return c.isGiven ||
          (c.value != 0 && !c.isWrong && c.value == s.puzzle.digitAt(target.row, target.col));
    }

    if (sel == null || needsRetarget(sel)) {
      sel = null;
      for (var i = 0; i < 81; i++) {
        final r = i ~/ 9;
        final c = i % 9;
        final cell = s.board.at(r, c);
        if (cell.isGiven) continue;
        final correct = s.puzzle.digitAt(r, c);
        if (cell.value != correct || cell.isWrong) {
          sel = (row: r, col: c);
          break;
        }
      }
      if (sel == null) return; // Nothing to reveal.
    }

    final cell = s.board.at(sel.row, sel.col);
    final correct = s.puzzle.digitAt(sel.row, sel.col);
    final next = s.board.withCell(
      cell.copyWith(value: correct, pencilMarks: 0, isWrong: false),
    );
    _afterPlacement(
      s.copyWith(hintsUsed: s.hintsUsed + 1, selected: sel, highlightedDigit: correct),
      next,
      placedDigit: correct,
      placedRow: sel.row,
      placedCol: sel.col,
    );
  }

  /// Called after a *correct* placement on [next]. Detects 8→9 transitions
  /// for the placed digit, the row, the column, and the 3×3 box that the
  /// placement falls in, and fires a celebration covering whichever
  /// structures completed (any combination, including all four — a quad
  /// combo is rare but possible).
  void _afterPlacement(
    GameOngoing s,
    Board next, {
    required int placedDigit,
    required int placedRow,
    required int placedCol,
  }) {
    if (next.isFull) {
      _stopTicker();
      final time = s.elapsed.inSeconds;
      final iq = IqCalculator.compute(
        difficulty: s.difficulty,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
      );
      final wasUnderTarget = time < s.difficulty.targetTimeSeconds;
      _sound.play(
        wasUnderTarget ? SoundEvent.puzzleCompleteGenius : SoundEvent.puzzleComplete,
      );
      state = GameWon(
        puzzle: s.puzzle,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
        livesRemaining: s.lives,
        iqScore: iq.iqScore,
        wasUnderTarget: wasUnderTarget,
      );
      return;
    }

    // Detect 8 → 9 transitions for the four structure types.
    final placedBox = (placedRow ~/ 3) * 3 + (placedCol ~/ 3);

    final completedDigit = (s.board.countDigit(placedDigit) != 9 &&
            next.countDigit(placedDigit) == 9)
        ? placedDigit
        : null;
    final completedRow = (!s.board.rowFull(placedRow) && next.rowFull(placedRow))
        ? placedRow
        : null;
    final completedCol = (!s.board.colFull(placedCol) && next.colFull(placedCol))
        ? placedCol
        : null;
    final completedBox = (!s.board.boxFull(placedBox) && next.boxFull(placedBox))
        ? placedBox
        : null;

    final anyCompletion = completedDigit != null ||
        completedRow != null ||
        completedCol != null ||
        completedBox != null;

    if (anyCompletion) {
      _digitCelebrationTimer?.cancel();
      final at = DateTime.now();

      // Sound: pick the most "exciting" event that fired. Digit-complete
      // (rarest, highest impact) wins over structure-complete; combos
      // upgrade to a louder cue.
      final structureCount = [completedRow, completedCol, completedBox]
          .where((e) => e != null)
          .length;
      if (completedDigit != null) {
        _sound.play(SoundEvent.digitComplete);
      } else if (structureCount >= 3) {
        _sound.play(SoundEvent.comboTriple);
      } else if (structureCount == 2) {
        _sound.play(SoundEvent.comboDouble);
      } else {
        _sound.play(SoundEvent.structureComplete);
      }

      state = s.copyWith(
        board: next,
        lastCompletedDigit: completedDigit,
        lastCompletedRow: completedRow,
        lastCompletedCol: completedCol,
        lastCompletedBox: completedBox,
        lastCompletedAt: at,
      );
      _digitCelebrationTimer = Timer(kDigitCelebrationDuration, () {
        final cur = state;
        if (cur is GameOngoing && cur.lastCompletedAt == at) {
          state = cur.copyWith(clearLastCompleted: true);
        }
      });
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
    _digitCelebrationTimer?.cancel();
    super.dispose();
  }
}

/// Family provider — keyed by difficulty + optional seed. Pass a seed
/// for testability; pass null to use the wall clock.
final gameControllerProvider = StateNotifierProvider.autoDispose
    .family<GameController, GameState, ({Difficulty difficulty, int? seed})>(
  (ref, args) => GameController(
    difficulty: args.difficulty,
    seed: args.seed,
    sound: ref.watch(soundServiceProvider),
  ),
);
