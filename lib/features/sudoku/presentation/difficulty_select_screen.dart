import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
              const SizedBox(height: 24),
              Text(
                'HeffelHoff',
                style: iqDisplayStyle(context, size: 36, color: scheme.onSurfaceVariant),
              ),
              Text(
                'SUDOKU',
                style: iqDisplayStyle(context, size: 64).copyWith(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: palette.iqGenius,
                    ).createShader(const Rect.fromLTWH(0, 0, 360, 80)),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'Pick your difficulty.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
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
