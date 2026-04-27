import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/board.dart';
import 'cell_widget.dart';

/// 9×9 board. Computes peer-highlight (same row/col/box) and same-digit
/// highlight masks once per build and passes them down to each cell.
/// Renders thick borders between 3×3 boxes.
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.board,
    required this.selected,
    required this.onCellTap,
    this.highlightedDigit,
    this.celebrateDigit,
    this.celebrateRow,
    this.celebrateCol,
    this.celebrateBox,
    this.celebrateKey,
  });

  final Board board;
  final ({int row, int col})? selected;
  final void Function(int row, int col) onCellTap;

  /// Digit being highlighted across the whole board (every matching cell
  /// gets the same-digit wash). When non-null, overrides the
  /// derive-from-selection behavior.
  final int? highlightedDigit;

  /// Cells matching any of these structures play a one-shot golden
  /// shimmer keyed on [celebrateKey]. A single placement can fire any
  /// combination of the four (e.g. row+col+box on a corner cell that
  /// also happened to be the 9th instance of its digit).
  final int? celebrateDigit;
  final int? celebrateRow;
  final int? celebrateCol;
  final int? celebrateBox;
  final Object? celebrateKey;

  bool _shouldCelebrate(int r, int c, int value) {
    if (celebrateDigit != null && value == celebrateDigit) return true;
    if (celebrateRow != null && r == celebrateRow) return true;
    if (celebrateCol != null && c == celebrateCol) return true;
    if (celebrateBox != null && (r ~/ 3) * 3 + (c ~/ 3) == celebrateBox) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    // Highlight digit: caller-provided takes priority (persists through
    // empty-cell taps). Fall back to the value of the selected cell.
    final selectedDigit = highlightedDigit ??
        (selected == null ? 0 : board.at(selected!.row, selected!.col).value);
    final selBox = selected == null
        ? -1
        : (selected!.row ~/ 3) * 3 + (selected!.col ~/ 3);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: palette.cellSurface,
          border: Border.all(color: palette.boardLineThick, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var r = 0; r < 9; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < 9; c++)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: c == 2 || c == 5
                                  ? BorderSide(color: palette.boardLineThick, width: 1.5)
                                  : BorderSide.none,
                              bottom: r == 2 || r == 5
                                  ? BorderSide(color: palette.boardLineThick, width: 1.5)
                                  : BorderSide.none,
                            ),
                          ),
                          child: CellWidget(
                            cell: board.at(r, c),
                            isSelected:
                                selected != null && selected!.row == r && selected!.col == c,
                            isPeerHighlighted: selected != null &&
                                (selected!.row == r ||
                                    selected!.col == c ||
                                    selBox == (r ~/ 3) * 3 + (c ~/ 3)),
                            isSameDigitHighlighted: selectedDigit != 0 &&
                                board.at(r, c).value == selectedDigit &&
                                !(selected != null &&
                                    selected!.row == r &&
                                    selected!.col == c),
                            celebrate: _shouldCelebrate(r, c, board.at(r, c).value),
                            celebrateKey: celebrateKey,
                            onTap: () => onCellTap(r, c),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
