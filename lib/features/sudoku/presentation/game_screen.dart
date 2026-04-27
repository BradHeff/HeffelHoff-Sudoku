import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../application/game_controller.dart';
import '../domain/difficulty.dart';
import '../domain/game_state.dart';
import 'post_game_iq_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/digit_complete_overlay.dart';
import 'widgets/lives_row.dart';
import 'widgets/number_pad.dart';
import 'widgets/peer_solve_banner.dart';
import 'widgets/structure_complete_toast.dart';
import 'widgets/timer_chip.dart';

const int kHintCapFree = 3;

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerArgs = (difficulty: difficulty, seed: null);
    final state = ref.watch(gameControllerProvider(providerArgs));
    final controller = ref.read(gameControllerProvider(providerArgs).notifier);

    void replay() {
      ref.invalidate(gameControllerProvider(providerArgs));
    }

    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          GameLoading() => const _LoadingView(),
          GameError(:final message) => _ErrorView(message: message),
          final GameOngoing s => _OngoingView(state: s, controller: controller),
          final GameWon w => PostGameIqScreen(
              puzzle: w.puzzle,
              timeSeconds: w.timeSeconds,
              mistakes: w.mistakes,
              hintsUsed: w.hintsUsed,
              iqScore: w.iqScore,
              won: true,
              wasUnderTarget: w.wasUnderTarget,
              onPlayAgain: replay,
              onBackToStart: () => context.go('/'),
              onNext: () {
                final user = ref.read(authStateProvider).asData?.value;
                if (user == null) {
                  context.go('/leaderboard');
                  return;
                }
                context.go(
                  '/leaderboard',
                  extra: LeaderboardArrival(
                    tier: w.puzzle.difficulty,
                    userId: user.id,
                    previousIq: 0,
                    newIq: w.iqScore,
                  ),
                );
              },
            ),
          final GameLost l => PostGameIqScreen(
              puzzle: l.puzzle,
              timeSeconds: l.timeSeconds,
              mistakes: l.mistakes,
              hintsUsed: 0,
              iqScore: 0,
              won: false,
              wasUnderTarget: false,
              onPlayAgain: replay,
              onBackToStart: () => context.go('/'),
            ),
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Shuffling tiles…',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => GoRouter.of(context).go('/'),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingView extends StatefulWidget {
  const _OngoingView({required this.state, required this.controller});

  final GameOngoing state;
  final GameController controller;

  @override
  State<_OngoingView> createState() => _OngoingViewState();
}

class _OngoingViewState extends State<_OngoingView> {
  DateTime? _lastFiredCelebration;

  @override
  void didUpdateWidget(covariant _OngoingView old) {
    super.didUpdateWidget(old);
    final at = widget.state.lastCompletedAt;
    if (at != null && at != _lastFiredCelebration) {
      _lastFiredCelebration = at;
      HapticFeedback.heavyImpact();
      Future<void>.delayed(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final hintsRemaining = (kHintCapFree - state.hintsUsed).clamp(0, kHintCapFree);
    final celebrateDigit = state.lastCompletedDigit;
    final celebrateRow = state.lastCompletedRow;
    final celebrateCol = state.lastCompletedCol;
    final celebrateBox = state.lastCompletedBox;
    final celebrateKey = state.lastCompletedAt;
    final hasStructureToast = celebrateRow != null ||
        celebrateCol != null ||
        celebrateBox != null ||
        celebrateDigit != null;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            children: [
              _Header(
                difficulty: state.difficulty,
                onPause: () => controller.setPaused(!state.paused),
                paused: state.paused,
              ),
              const SizedBox(height: 8),
              _StatsRow(
                lives: state.lives,
                maxLives: state.maxLives,
                mistakes: state.mistakes,
                elapsed: state.elapsed,
                paused: state.paused,
              ),
              const SizedBox(height: 12),
              PeerSolveBanner(puzzleSeed: state.puzzle.seed),
              const SizedBox(height: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BoardWidget(
                    board: state.board,
                    selected: state.selected,
                    highlightedDigit: state.highlightedDigit,
                    celebrateDigit: celebrateDigit,
                    celebrateRow: celebrateRow,
                    celebrateCol: celebrateCol,
                    celebrateBox: celebrateBox,
                    celebrateKey: celebrateKey,
                    onCellTap: (r, c) {
                      HapticFeedback.selectionClick();
                      controller.selectCell(r, c);
                    },
                  ),
                  if (hasStructureToast && celebrateKey != null)
                    Positioned(
                      top: -56,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: StructureCompleteToast(
                          completedRow: celebrateRow,
                          completedCol: celebrateCol,
                          completedBox: celebrateBox,
                          completedDigit: celebrateDigit,
                          triggeredAt: celebrateKey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _ToolsRow(
                pencilOn: state.pencilMode,
                hintsRemaining: hintsRemaining,
                onErase: () {
                  HapticFeedback.lightImpact();
                  controller.erase();
                },
                onPencil: () {
                  HapticFeedback.selectionClick();
                  controller.togglePencil();
                },
                onHint: hintsRemaining > 0
                    ? () {
                        HapticFeedback.mediumImpact();
                        controller.useHint();
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              NumberPad(
                board: state.board,
                disabled: state.paused,
                celebrateDigit: celebrateDigit,
                celebrateKey: celebrateKey,
                onDigit: (d) async {
                  final ok = controller.enterDigit(d);
                  if (ok) {
                    await HapticFeedback.mediumImpact();
                  } else {
                    await HapticFeedback.heavyImpact();
                  }
                },
              ),
            ],
          ),
        ),
        if (celebrateDigit != null && celebrateKey != null)
          Positioned.fill(
            child: DigitCompleteOverlay(
              digit: celebrateDigit,
              triggeredAt: celebrateKey,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.difficulty,
    required this.onPause,
    required this.paused,
  });

  final Difficulty difficulty;
  final VoidCallback onPause;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => GoRouter.of(context).go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 16, color: scheme.tertiary),
              const SizedBox(width: 4),
              Text('Streak 0', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
        const Spacer(),
        Text(difficulty.label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        IconButton(
          onPressed: onPause,
          icon: Icon(paused ? Icons.play_circle : Icons.pause_circle),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.lives,
    required this.maxLives,
    required this.mistakes,
    required this.elapsed,
    required this.paused,
  });

  final int lives;
  final int maxLives;
  final int mistakes;
  final Duration elapsed;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LivesRow(lives: lives, maxLives: maxLives),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('$mistakes', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        TimerChip(elapsed: elapsed, paused: paused),
      ],
    );
  }
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow({
    required this.pencilOn,
    required this.hintsRemaining,
    required this.onErase,
    required this.onPencil,
    required this.onHint,
  });

  final bool pencilOn;
  final int hintsRemaining;
  final VoidCallback onErase;
  final VoidCallback onPencil;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToolButton(
          icon: Icons.backspace_outlined,
          label: 'Erase',
          onTap: onErase,
        ),
        _ToolButton(
          icon: Icons.edit_outlined,
          label: 'Notes',
          badge: pencilOn ? 'ON' : 'OFF',
          badgeOn: pencilOn,
          onTap: onPencil,
        ),
        _ToolButton(
          icon: Icons.lightbulb_outline,
          label: 'Hint',
          badge: '$hintsRemaining',
          badgeOn: hintsRemaining > 0,
          onTap: onHint,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeOn = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final bool badgeOn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final color = disabled ? scheme.onSurfaceVariant.withValues(alpha: 0.4) : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: color),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeOn ? scheme.primary : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeOn ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    ).animate(target: badgeOn ? 1 : 0).scaleXY(end: 1.05, duration: 120.ms);
  }
}
