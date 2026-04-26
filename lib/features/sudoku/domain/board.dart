import 'package:flutter/foundation.dart';

import 'cell.dart';

/// Immutable 9x9 Sudoku board.
///
/// Internally stores cells in a flat 81-length list (row-major). The
/// board is constructed once from a generator output and then evolves
/// through [withCell] copy-with-replace updates from the controller.
@immutable
class Board {
  Board._(this._cells);

  /// Empty board (all zeros, none given).
  factory Board.empty() {
    final cells = List<Cell>.generate(
      81,
      (i) => Cell(row: i ~/ 9, col: i % 9),
      growable: false,
    );
    return Board._(cells);
  }

  /// Build a board from an 81-char clues string + 81-char solution string.
  /// `'0'` = blank; everything non-zero is treated as a given clue.
  factory Board.fromClues(String clues) {
    if (clues.length != 81) {
      throw ArgumentError('clues must be 81 chars, got ${clues.length}');
    }
    final cells = <Cell>[];
    for (var i = 0; i < 81; i++) {
      final c = clues.codeUnitAt(i) - 0x30; // '0' = 48
      cells.add(
        Cell(
          row: i ~/ 9,
          col: i % 9,
          value: c,
          isGiven: c != 0,
        ),
      );
    }
    return Board._(List.unmodifiable(cells));
  }

  final List<Cell> _cells;

  Cell at(int row, int col) => _cells[row * 9 + col];
  Cell atIndex(int i) => _cells[i];
  Iterable<Cell> get cells => _cells;
  int get length => _cells.length;

  /// True when every cell has a non-zero value.
  bool get isFull => _cells.every((c) => c.value != 0);

  /// Returns a copy of the board with the given cell replaced.
  Board withCell(Cell cell) {
    final i = cell.row * 9 + cell.col;
    final next = List<Cell>.from(_cells);
    next[i] = cell;
    return Board._(List.unmodifiable(next));
  }

  /// Serialize to an 81-char digit string, '0' for blanks.
  String toDigitString() {
    final buf = StringBuffer();
    for (final c in _cells) {
      buf.writeCharCode(0x30 + c.value);
    }
    return buf.toString();
  }

  /// Returns the number of currently-placed (correct or otherwise) digits
  /// of [digit] across the board. Useful for the number-pad remaining
  /// counter.
  int countDigit(int digit) =>
      _cells.where((c) => c.value == digit).length;
}
