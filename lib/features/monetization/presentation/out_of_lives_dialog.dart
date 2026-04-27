import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/products.dart';

enum OutOfLivesChoice { watchAd, purchase, giveUp }

Future<OutOfLivesChoice> showOutOfLivesDialog(BuildContext context) async {
  final palette = Theme.of(context).extension<AppPalette>()!;
  final scheme = Theme.of(context).colorScheme;
  final product = MonetizationProduct.extraLife;

  final result = await showDialog<OutOfLivesChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.heart_broken, color: palette.lifeRed, size: 44),
      title: const Text('Out of lives'),
      content: const Text(
        'Keep going? Watch a quick ad or buy a life — you can do '
        'this once per puzzle.',
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(OutOfLivesChoice.purchase),
            icon: const Icon(Icons.shopping_cart_outlined, size: 16),
            label: Text('Buy 1 life ${product.formattedPrice}'),
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
