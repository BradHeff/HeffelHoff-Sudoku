import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_sheet.dart';
import '../domain/difficulty.dart';
import 'widgets/tier_card.dart';

class DifficultySelectScreen extends ConsumerWidget {
  const DifficultySelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand logo + wordmark hero block.
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/branding/logo.png'),
                  ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HEFFELHOFF',
                          style: iqDisplayStyle(
                            context,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ).copyWith(letterSpacing: 3, fontWeight: FontWeight.w400),
                        ),
                        // FittedBox ensures the wordmark scales down to
                        // fit the available width and never wraps.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              colors: palette.iqGenius,
                            ).createShader(rect),
                            child: Text(
                              'SUDOKU',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: iqDisplayStyle(context, size: 36, color: Colors.white)
                                  .copyWith(letterSpacing: 3, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/leaderboard'),
                    icon: const Icon(Icons.emoji_events_outlined),
                    tooltip: 'Leaderboard',
                  ),
                  const _AccountAvatarButton(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pick your difficulty.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const tiers = Difficulty.values;
                    const separator = 10.0;
                    final totalSeparators = separator * (tiers.length - 1);
                    final totalMinHeight = tiers
                            .map(TierCard.minHeightFor)
                            .reduce((a, b) => a + b)
                            .toDouble() +
                        totalSeparators;
                    final available = constraints.maxHeight;

                    // If the screen can't fit even the minimum heights,
                    // fall back to a scrollable list at the per-tier
                    // minimums.
                    if (available <= totalMinHeight) {
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: tiers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: separator),
                        itemBuilder: (context, i) {
                          final tier = tiers[i];
                          return TierCard(
                            tier: tier,
                            onTap: () => context.go('/game/${tier.id}'),
                          )
                              .animate(delay: (80 * i).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.1);
                        },
                      );
                    }

                    // Otherwise scale every card proportionally so the
                    // five cards (plus fixed separators) exactly fill
                    // the available height.
                    final scale =
                        (available - totalSeparators) / (totalMinHeight - totalSeparators);
                    return Column(
                      children: [
                        for (var i = 0; i < tiers.length; i++) ...[
                          TierCard(
                            tier: tiers[i],
                            onTap: () => context.go('/game/${tiers[i].id}'),
                            height: TierCard.minHeightFor(tiers[i]) * scale,
                          )
                              .animate(delay: (80 * i).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.1),
                          if (i < tiers.length - 1)
                            const SizedBox(height: separator),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Avatar button on the home screen header. Shows the first letter of
/// the signed-in user's email (or a person icon if anonymous / not
/// signed in) and opens the [showAccountSheet] modal on tap.
class _AccountAvatarButton extends ConsumerWidget {
  const _AccountAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final scheme = Theme.of(context).colorScheme;

    final user = auth.asData?.value;
    final email = user?.email ?? '';
    final isAnonymous = user?.isAnonymous == true;
    final hasInitial = !isAnonymous && email.isNotEmpty;

    return Material(
      color: scheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => showAccountSheet(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: user != null
                  ? scheme.primary.withValues(alpha: 0.7)
                  : scheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: hasInitial
              ? Text(
                  email[0].toUpperCase(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                )
              : Icon(
                  Icons.person_outline,
                  color: user != null ? scheme.primary : scheme.onSurfaceVariant,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
