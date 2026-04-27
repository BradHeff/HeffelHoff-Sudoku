import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/cell.dart';

/// A single Sudoku cell.
class CellWidget extends StatelessWidget {
  const CellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isPeerHighlighted,
    required this.isSameDigitHighlighted,
    required this.onTap,
    this.celebrate = false,
    this.celebrateKey,
  });

  final Cell cell;
  final bool isSelected;
  final bool isPeerHighlighted;
  final bool isSameDigitHighlighted;
  final VoidCallback onTap;

  final bool celebrate;
  final Object? celebrateKey;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    if (cell.isWrong) {
      background = palette.cellWrong;
    } else if (isSelected) {
      background = palette.cellSelected;
    } else if (isSameDigitHighlighted) {
      background = palette.cellSameDigit;
    } else if (isPeerHighlighted) {
      background = palette.cellPeer;
    } else {
      background = palette.cellSurface;
    }

    final Color digitColor;
    final bool digitBold;
    if (cell.isWrong) {
      digitColor = palette.cellWrongFg;
      digitBold = true;
    } else if (isSelected && cell.value != 0) {
      digitColor = palette.cellSelectedFg;
      digitBold = true;
    } else if (isSameDigitHighlighted) {
      digitColor = palette.cellSameDigitFg;
      digitBold = true;
    } else if (cell.isGiven) {
      digitColor = palette.cellGivenDigit;
      digitBold = true;
    } else {
      digitColor = palette.cellUserDigit;
      digitBold = false;
    }

    Widget content;
    if (cell.isEmpty && cell.pencilMarks != 0) {
      content = _PencilGrid(mask: cell.pencilMarks, color: scheme.onSurfaceVariant);
    } else if (cell.value != 0) {
      content = Text(
        '${cell.value}',
        style: cellDigitStyle(context, color: digitColor, bold: digitBold),
      );
    } else {
      content = const SizedBox.shrink();
    }

    Widget cellBox = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: BorderSide(color: palette.boardLine, width: 0.5),
          bottom: BorderSide(color: palette.boardLine, width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: content,
    );

    if (cell.isWrong) {
      cellBox = cellBox
          .animate(key: ValueKey('wrong-${cell.row}-${cell.col}-${cell.value}'))
          .shake(hz: 6, curve: Curves.elasticOut, duration: 280.ms, offset: const Offset(8, 0))
          .then()
          .tint(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.18), duration: 220.ms);
    }

    if (celebrate && !cell.isWrong) {
      cellBox = cellBox
          .animate(key: ValueKey('celebrate-${cell.row}-${cell.col}-$celebrateKey'))
          .tint(
            color: const Color(0xFFFFD700).withValues(alpha: 0.55),
            duration: 220.ms,
            curve: Curves.easeOut,
          )
          .scaleXY(end: 1.12, duration: 220.ms, curve: Curves.easeOutBack)
          .then()
          .tint(color: Colors.transparent, duration: 350.ms)
          .scaleXY(end: 1.0, duration: 350.ms, curve: Curves.easeIn);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cellBox,
    );
  }
}

class _PencilGrid extends StatelessWidget {
  const _PencilGrid({required this.mask, required this.color});

  final int mask;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: color,
      height: 1.0,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: Center(
                        child: (mask >> (row * 3 + col)) & 1 == 1
                            ? Text('${row * 3 + col + 1}', style: style)
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
