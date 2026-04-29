import 'package:flutter/material.dart';

/// Confirmation dialog for the in-puzzle "earn an extra hint by
/// watching a rewarded ad" flow. Returns true iff the user wants to
/// watch the ad. Originally a paid IAP — switched to rewarded-ad-only
/// alongside the rest of the monetization rework.
Future<bool> showPurchaseHintDialog(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.lightbulb_outline, color: scheme.primary, size: 36),
      title: const Text('Earn 1 extra hint?'),
      content: const Text(
        "You've used your free hint. Watch a quick ad to earn one more.",
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.play_circle_outline, size: 16),
          label: const Text('Watch ad'),
        ),
      ],
    ),
  );
  return result ?? false;
}
