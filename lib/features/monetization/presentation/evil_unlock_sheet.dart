import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/monetization_service.dart';
import '../data/rewarded_economy_service.dart';

/// Pending flag the home screen drains on mount. Set by GameController
/// after a Medium or Hard win when Evil hasn't been unlocked yet.
final pendingEvilUnlockOfferProvider = StateProvider<bool>((_) => false);

/// Slide-up sheet offering the user a chance to unlock the Evil tier
/// by watching a rewarded ad. Cleanly dismissible (X / outside tap /
/// "No thanks").
Future<void> showEvilUnlockSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _EvilUnlockSheet(),
  );
}

class _EvilUnlockSheet extends ConsumerStatefulWidget {
  const _EvilUnlockSheet();

  @override
  ConsumerState<_EvilUnlockSheet> createState() => _EvilUnlockSheetState();
}

class _EvilUnlockSheetState extends ConsumerState<_EvilUnlockSheet> {
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
    await notifier.unlockEvil();
    final milestone = await notifier.recordAdWatched();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          milestone
              ? 'Evil unlocked — and you hit a loyalty bonus! Check Profile.'
              : 'Evil tier unlocked. Brace yourself.',
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
            color: const Color(0xFFE91E63).withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.25),
              blurRadius: 28,
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
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFE91E63)],
                  ).createShader(rect),
                  child: const Icon(Icons.local_fire_department,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFE91E63)],
                        ).createShader(rect),
                        child: Text(
                          'UNLOCK EVIL',
                          style: iqDisplayStyle(
                            context,
                            size: 24,
                            color: Colors.white,
                          ).copyWith(letterSpacing: 3, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        'Watch a quick ad — Evil tier is yours.',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: palette.iqGenius.first, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evil is the hardest tier — base IQ 160, target time 45 minutes. Beating it on a clean run beats Einstein outright.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _watchAd,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFFE91E63),
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
                _busy ? 'Loading ad…' : 'Watch ad to unlock',
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
