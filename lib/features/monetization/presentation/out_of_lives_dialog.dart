import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Two outcomes only — purchase path was removed when Pro / paid IAPs
/// gave way to the rewarded-ad economy.
enum OutOfLivesChoice { watchAd, giveUp }

Future<OutOfLivesChoice> showOutOfLivesDialog(BuildContext context) async {
  final palette = Theme.of(context).extension<AppPalette>()!;
  final scheme = Theme.of(context).colorScheme;

  final result = await showDialog<OutOfLivesChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.heart_broken, color: palette.lifeRed, size: 44),
      title: const Text('Out of lives'),
      content: const Text(
        'Keep going? Watch a quick ad to earn one more life — you can '
        'do this once per puzzle.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(OutOfLivesChoice.watchAd),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Watch ad — 1 life'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(OutOfLivesChoice.giveUp),
          style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
          child: const Text('Give up'),
        ),
      ],
    ),
  );
  return result ?? OutOfLivesChoice.giveUp;
}
