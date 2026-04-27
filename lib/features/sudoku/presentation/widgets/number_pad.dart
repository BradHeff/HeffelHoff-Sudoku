import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/board.dart';

/// Number pad 1–9 with a remaining-count subscript under each digit.
/// Tap selects + places that digit at the currently-selected cell.
/// A digit with `remaining == 0` (all 9 already on the board) is shown
/// with a gold checkmark badge instead of the count.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.board,
    required this.onDigit,
    this.disabled = false,
    this.celebrateDigit,
    this.celebrateKey,
  });

  final Board board;
  final void Function(int digit) onDigit;
  final bool disabled;

  /// When set, the matching digit button plays a one-shot glow + scale
  /// pulse keyed on [celebrateKey].
  final int? celebrateDigit;
  final Object? celebrateKey;

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
              celebrate: celebrateDigit == d,
              celebrateKey: celebrateKey,
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
    this.celebrate = false,
    this.celebrateKey,
  });

  final int digit;
  final int remaining;
  final VoidCallback? onTap;
  final bool celebrate;
  final Object? celebrateKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final exhausted = remaining <= 0;
    final disabled = onTap == null || exhausted;

    // When exhausted, render the digit in gold (achievement style)
    // rather than greyed-out. The checkmark below makes it obvious.
    final Color color;
    if (exhausted) {
      color = palette.goldFrame.first;
    } else if (disabled) {
      color = scheme.onSurfaceVariant.withValues(alpha: 0.4);
    } else {
      color = scheme.primary;
    }

    final Widget subscript = exhausted
        ? Icon(Icons.check_circle, size: 12, color: palette.goldFrame.first)
        : Text(
            '$remaining',
            style: TextStyle(
              fontSize: 10,
              color: disabled
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
                  : scheme.onSurfaceVariant,
            ),
          );

    Widget button = Material(
      color: exhausted
          ? palette.goldFrame.first.withValues(alpha: 0.12)
          : (disabled ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: exhausted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.goldFrame.first.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$digit',
                style: cellDigitStyle(context, color: color, bold: true).copyWith(fontSize: 26),
              ),
              const SizedBox(height: 2),
              subscript,
            ],
          ),
        ),
      ),
    );

    if (celebrate) {
      button = button
          .animate(key: ValueKey('digit-glow-$digit-$celebrateKey'))
          .scaleXY(end: 1.18, duration: 220.ms, curve: Curves.easeOutBack)
          .tint(color: palette.goldFrame.first.withValues(alpha: 0.4), duration: 220.ms)
          .then()
          .scaleXY(end: 1.0, duration: 320.ms, curve: Curves.easeIn)
          .tint(color: Colors.transparent, duration: 320.ms);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: button,
    );
  }
}
