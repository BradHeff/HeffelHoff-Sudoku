import 'package:flutter/foundation.dart';

@immutable
class Cell {
  const Cell({
    required this.row,
    required this.col,
    this.value = 0,
    this.isGiven = false,
    this.pencilMarks = 0,
    this.isWrong = false,
  });

  final int row;
  final int col;
  final int value;
  final bool isGiven;
  final int pencilMarks;
  final bool isWrong;

  bool get isEmpty => value == 0;
  bool get isUserFilled => !isGiven && value != 0;
  int get box => (row ~/ 3) * 3 + (col ~/ 3);

  bool hasPencil(int digit) => (pencilMarks >> (digit - 1)) & 1 == 1;

  Cell copyWith({
    int? value,
    bool? isGiven,
    int? pencilMarks,
    bool? isWrong,
  }) {
    return Cell(
      row: row,
      col: col,
      value: value ?? this.value,
      isGiven: isGiven ?? this.isGiven,
      pencilMarks: pencilMarks ?? this.pencilMarks,
      isWrong: isWrong ?? this.isWrong,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          row == other.row &&
          col == other.col &&
          value == other.value &&
          isGiven == other.isGiven &&
          pencilMarks == other.pencilMarks &&
          isWrong == other.isWrong;

  @override
  int get hashCode => Object.hash(row, col, value, isGiven, pencilMarks, isWrong);
}
