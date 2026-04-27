import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/cell.dart';

/// A single Sudoku cell. The widget is dumb — all state-machine logic
/// (selected, peer-highlighted, same-digit) is computed by the parent
/// and passed in as flags.
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

  /// True when this cell's value matches the digit the player just
  /// completed across the whole board. Triggers a one-shot golden
  /// shimmer pulse re-keyed on [celebrateKey].
  final bool celebrate;
  final Object? celebrateKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    if (cell.isWrong) {
      background = scheme.errorContainer;
    } else if (isSelected) {
      background = scheme.secondaryContainer;
    } else if (isSameDigitHighlighted) {
      background = scheme.tertiaryContainer.withValues(alpha: 0.45);
    } else if (isPeerHighlighted) {
      background = scheme.surfaceContainerLow;
    } else if (cell.isGiven) {
      background = scheme.surfaceContainerHigh;
    } else {
      background = scheme.surface;
    }

    final Color digitColor;
    final bool digitBold;
    if (cell.isWrong) {
      digitColor = scheme.onErrorContainer;
      digitBold = true;
    } else if (cell.isGiven) {
      digitColor = scheme.onSurface;
      digitBold = true;
    } else {
      digitColor = scheme.primary;
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
          right: BorderSide(color: scheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
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

    // Digit-complete celebration: golden tint sweep + scale bounce.
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
    final style = TextStyle(fontSize: 9, color: color);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          for (var d = 1; d <= 9; d++)
            Center(
              child: (mask >> (d - 1)) & 1 == 1
                  ? Text('$d', style: style)
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
