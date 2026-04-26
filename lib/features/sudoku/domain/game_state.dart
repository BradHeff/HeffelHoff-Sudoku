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
  });

  final Puzzle puzzle;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final int livesRemaining;

  /// Provisional client-side IQ. Will be overwritten by server on sync.
  final int iqScore;
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
