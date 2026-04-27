import 'package:flutter/foundation.dart';

import 'cell.dart';

@immutable
class Board {
  Board._(this._cells);

  factory Board.empty() {
    final cells = List<Cell>.generate(
      81,
      (i) => Cell(row: i ~/ 9, col: i % 9),
      growable: false,
    );
    return Board._(cells);
  }

  /// Build a board from an 81-char clues string. '0' = blank, otherwise given.
  factory Board.fromClues(String clues) {
    if (clues.length != 81) {
      throw ArgumentError('clues must be 81 chars, got ${clues.length}');
    }
    final cells = <Cell>[];
    for (var i = 0; i < 81; i++) {
      final c = clues.codeUnitAt(i) - 0x30;
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

  bool get isFull => _cells.every((c) => c.value != 0);

  Board withCell(Cell cell) {
    final i = cell.row * 9 + cell.col;
    final next = List<Cell>.from(_cells);
    next[i] = cell;
    return Board._(List.unmodifiable(next));
  }

  String toDigitString() {
    final buf = StringBuffer();
    for (final c in _cells) {
      buf.writeCharCode(0x30 + c.value);
    }
    return buf.toString();
  }

  int countDigit(int digit) =>
      _cells.where((c) => c.value == digit).length;

  bool rowFull(int row) {
    for (var c = 0; c < 9; c++) {
      final cell = _cells[row * 9 + c];
      if (cell.value == 0 || cell.isWrong) return false;
    }
    return true;
  }

  bool colFull(int col) {
    for (var r = 0; r < 9; r++) {
      final cell = _cells[r * 9 + col];
      if (cell.value == 0 || cell.isWrong) return false;
    }
    return true;
  }

  bool boxFull(int box) {
    final br = (box ~/ 3) * 3;
    final bc = (box % 3) * 3;
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        final cell = _cells[(br + dr) * 9 + bc + dc];
        if (cell.value == 0 || cell.isWrong) return false;
      }
    }
    return true;
  }
}
