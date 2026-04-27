import 'package:flutter/material.dart';

import '../domain/products.dart';

Future<bool> showPurchaseHintDialog(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final product = MonetizationProduct.extraHint;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.lightbulb_outline, color: scheme.primary, size: 36),
      title: const Text('Buy 1 extra hint?'),
      content: Text(
        'You\'ve used your free hint. One more hint for ${product.formattedPrice}.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
          label: Text('Buy ${product.formattedPrice}'),
        ),
      ],
    ),
  );
  return result ?? false;
}
