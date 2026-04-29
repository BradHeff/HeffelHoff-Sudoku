import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/monetization_service.dart';
import '../data/rewarded_economy_service.dart';

/// Pending flag the home screen drains on mount. Set by GameController
/// after a loss so the user is offered a +2 lives / +1 hint boost for
/// their next attempt.
final pendingBoostOfferProvider = StateProvider<bool>((_) => false);

Future<void> showBoostOfferSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _BoostOfferSheet(),
  );
}

class _BoostOfferSheet extends ConsumerStatefulWidget {
  const _BoostOfferSheet();

  @override
  ConsumerState<_BoostOfferSheet> createState() => _BoostOfferSheetState();
}

class _BoostOfferSheetState extends ConsumerState<_BoostOfferSheet> {
  bool _busy = false;

  Future<void> _watchAd() async {
    setState(() => _busy = true);
    final ok = await ref.read(monetizationServiceProvider).showRewardedAd();
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad unavailable. Try again in a moment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final notifier = ref.read(rewardedEconomyProvider.notifier);
    await notifier.grantBoostNextPuzzle();
    final milestone = await notifier.recordAdWatched();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          milestone
              ? 'Boost ready + loyalty milestone! Bonus lives added to your pool.'
              : 'Next puzzle: 5 lives, 2 hints. Good luck.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHigh,
              scheme.surfaceContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: palette.iqGenius.first.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.iqGenius.first.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4, bottom: 14),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (rect) =>
                      LinearGradient(colors: palette.iqGenius).createShader(rect),
                  child: const Icon(Icons.bolt, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) =>
                            LinearGradient(colors: palette.iqGenius).createShader(rect),
                        child: Text(
                          'NEXT PUZZLE BOOST',
                          style: iqDisplayStyle(
                            context,
                            size: 22,
                            color: Colors.white,
                          ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        'Watch a 3-min ad — supercharge your next attempt.',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Perk(
              icon: Icons.favorite,
              label: '5 lives',
              detail: '+2 over the usual 3 — more room to recover.',
            ),
            const SizedBox(height: 8),
            const _Perk(
              icon: Icons.lightbulb,
              label: '2 hints',
              detail: '+1 over the usual 1 — break through tough cells.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _watchAd,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: palette.iqGenius.first,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline),
              label: Text(
                _busy ? 'Loading ad…' : 'Watch ad — claim boost',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(
                'No thanks',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: 0.2, end: 0, duration: 280.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 260.ms),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label, required this.detail});

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.iqGenius.first.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: palette.iqGenius.first, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                detail,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
