import 'package:flutter/foundation.dart';

import 'board.dart';
import 'difficulty.dart';
import 'puzzle.dart';

/// Game state — discriminated union via Dart 3 sealed classes (no
/// freezed dependency for Phase 1; convert later if needed).
sealed class GameState {
  const GameState();
}

class GameLoading extends GameState {
  const GameLoading({required this.difficulty});
  final Difficulty difficulty;
}

class GameError extends GameState {
  const GameError(this.message);
  final String message;
}

class GameOngoing extends GameState {
  const GameOngoing({
    required this.puzzle,
    required this.board,
    required this.selected,
    required this.lives,
    required this.maxLives,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsed,
    required this.startedAt,
    required this.pencilMode,
    required this.paused,
    this.lastCompletedDigit,
    this.lastCompletedRow,
    this.lastCompletedCol,
    this.lastCompletedBox,
    this.lastCompletedAt,
    this.highlightedDigit,
  });

  final Puzzle puzzle;
  final Board board;

  /// (row, col) of the currently focused cell, or null.
  final ({int row, int col})? selected;

  final int lives;
  final int maxLives;
  final int mistakes;
  final int hintsUsed;
  final Duration elapsed;
  final DateTime startedAt;
  final bool pencilMode;
  final bool paused;

  /// Set when the player has just placed the 9th correct instance of a
  /// digit, completing it across the board. Cleared by the controller
  /// after the celebration animation finishes (~1500ms).
  final int? lastCompletedDigit;

  /// Set (0..8) when a row was just completed by the placement.
  final int? lastCompletedRow;

  /// Set (0..8) when a column was just completed by the placement.
  final int? lastCompletedCol;

  /// Set (0..8) when a 3×3 box was just completed. Box index runs
  /// left→right, top→bottom: top row of boxes is 0,1,2; middle 3,4,5;
  /// bottom 6,7,8.
  final int? lastCompletedBox;

  /// Monotonic timestamp the celebration was triggered. Shared across
  /// all four `lastCompleted*` fields so a single placement that
  /// completes (e.g.) a digit + a row + a box uses one keying value.
  final DateTime? lastCompletedAt;

  /// The digit currently being highlighted across the board (every cell
  /// with this value gets the same-digit wash). Decoupled from
  /// [selected] so the highlight survives a tap on an empty cell —
  /// users often tap an empty cell *intending* to enter the highlighted
  /// digit there. Cleared when:
  ///   - the user taps a second empty cell without entering a digit
  ///     between the two taps (lost intent), or
  ///   - the user enters a digit (the just-placed digit becomes the
  ///     new highlight).
  final int? highlightedDigit;

  bool get hasAnyCompletion =>
      lastCompletedDigit != null ||
      lastCompletedRow != null ||
      lastCompletedCol != null ||
      lastCompletedBox != null;

  bool get hasLives => lives > 0;
  Difficulty get difficulty => puzzle.difficulty;

  GameOngoing copyWith({
    Board? board,
    ({int row, int col})? selected,
    bool clearSelected = false,
    int? lives,
    int? mistakes,
    int? hintsUsed,
    Duration? elapsed,
    bool? pencilMode,
    bool? paused,
    int? lastCompletedDigit,
    int? lastCompletedRow,
    int? lastCompletedCol,
    int? lastCompletedBox,
    DateTime? lastCompletedAt,
    bool clearLastCompleted = false,
    int? highlightedDigit,
    bool clearHighlight = false,
  }) {
    return GameOngoing(
      puzzle: puzzle,
      board: board ?? this.board,
      selected: clearSelected ? null : (selected ?? this.selected),
      lives: lives ?? this.lives,
      maxLives: maxLives,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsed: elapsed ?? this.elapsed,
      startedAt: startedAt,
      pencilMode: pencilMode ?? this.pencilMode,
      paused: paused ?? this.paused,
      lastCompletedDigit:
          clearLastCompleted ? null : (lastCompletedDigit ?? this.lastCompletedDigit),
      lastCompletedRow:
          clearLastCompleted ? null : (lastCompletedRow ?? this.lastCompletedRow),
      lastCompletedCol:
          clearLastCompleted ? null : (lastCompletedCol ?? this.lastCompletedCol),
      lastCompletedBox:
          clearLastCompleted ? null : (lastCompletedBox ?? this.lastCompletedBox),
      lastCompletedAt:
          clearLastCompleted ? null : (lastCompletedAt ?? this.lastCompletedAt),
      highlightedDigit:
          clearHighlight ? null : (highlightedDigit ?? this.highlightedDigit),
    );
  }
}

class GameWon extends GameState {
  const GameWon({
    required this.puzzle,
    required this.timeSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.livesRemaining,
    required this.iqScore,
    required this.wasUnderTarget,
  });

  final Puzzle puzzle;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final int livesRemaining;

  /// Provisional client-side IQ. Will be overwritten by server on sync.
  final int iqScore;

  /// True when the puzzle was solved in less than the tier's
  /// `target_time_seconds`. Triggers the "GENIUS" enhanced celebration
  /// on the post-game screen — bigger confetti, gold IQ glow,
  /// extended particle storm, longer audio fanfare.
  final bool wasUnderTarget;
}

class GameLost extends GameState {
  const GameLost({
    required this.puzzle,
    required this.timeSeconds,
    required this.mistakes,
  });

  final Puzzle puzzle;
  final int timeSeconds;
  final int mistakes;
}

@immutable
class IqResult {
  const IqResult({
    required this.iqScore,
    required this.timeComponent,
    required this.mistakePenalty,
    required this.hintPenalty,
    required this.einsteinDelta,
  });

  final int iqScore;
  final int timeComponent;
  final int mistakePenalty;
  final int hintPenalty;
  final int einsteinDelta; // iqScore - 160

  bool get beatEinstein => einsteinDelta >= 0;
}
