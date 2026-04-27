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
    this.celebrateDigit,
    this.celebrateKey,
  });

  final Board board;
  final ({int row, int col})? selected;
  final void Function(int row, int col) onCellTap;

  /// Set during a digit-complete celebration. Cells matching this digit
  /// play a one-shot shimmer keyed on [celebrateKey].
  final int? celebrateDigit;
  final Object? celebrateKey;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final selectedDigit = selected == null
        ? 0
        : board.at(selected!.row, selected!.col).value;
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
                            celebrate: celebrateDigit != null &&
                                board.at(r, c).value == celebrateDigit,
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
