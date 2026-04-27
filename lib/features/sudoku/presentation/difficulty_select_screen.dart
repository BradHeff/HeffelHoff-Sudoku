import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_sheet.dart';
import '../domain/difficulty.dart';

class DifficultySelectScreen extends ConsumerWidget {
  const DifficultySelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Brand logo + wordmark hero block.
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
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
                      children: [
                        Text(
                          'HEFFELHOFF',
                          style: iqDisplayStyle(
                            context,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ).copyWith(letterSpacing: 4, fontWeight: FontWeight.w400),
                        ),
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: palette.iqGenius,
                          ).createShader(rect),
                          child: Text(
                            'SUDOKU',
                            style: iqDisplayStyle(context, size: 40, color: Colors.white)
                                .copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
                  const _AccountAvatarButton(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pick your difficulty.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: Difficulty.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final tier = Difficulty.values[i];
                    return _DifficultyCard(
                      tier: tier,
                      onTap: () => context.go('/game/${tier.id}'),
                    ).animate(delay: (80 * i).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Phase 1 — offline single-player. Sign-in & leaderboard land in Phase 2/3.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.tier, required this.onTap});

  final Difficulty tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  tier.label[0],
                  style: text.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.label, style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Base IQ ${tier.baseIQ} · target ${_fmt(tier.targetTimeSeconds)}',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
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
