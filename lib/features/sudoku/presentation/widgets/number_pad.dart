import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/board.dart';

/// Number pad 1–9 with a remaining-count subscript under each digit.
/// Tap selects + places that digit at the currently-selected cell.
/// A digit with `remaining == 0` (all 9 already on the board) is shown
/// muted and is non-interactive.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.board,
    required this.onDigit,
    this.disabled = false,
  });

  final Board board;
  final void Function(int digit) onDigit;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var d = 1; d <= 9; d++)
          Expanded(
            child: _DigitButton(
              digit: d,
              remaining: 9 - board.countDigit(d),
              onTap: disabled ? null : () => onDigit(d),
            ),
          ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.digit,
    required this.remaining,
    required this.onTap,
  });

  final int digit;
  final int remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exhausted = remaining <= 0;
    final disabled = onTap == null || exhausted;
    final color = disabled ? scheme.onSurfaceVariant.withValues(alpha: 0.4) : scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Material(
        color: disabled ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$digit',
                  style: cellDigitStyle(context, color: color, bold: true).copyWith(fontSize: 26),
                ),
                const SizedBox(height: 2),
                Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 10,
                    color: disabled
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
