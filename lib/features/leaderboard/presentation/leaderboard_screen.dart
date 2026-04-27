import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../sudoku/domain/difficulty.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_entry.dart';
import 'widgets/podium_view.dart';

/// Top-100 leaderboard with tier-chip filter, podium for ranks 1–3,
/// and a list for ranks 4+. Uses Realtime so the list reorders live as
/// new bests are submitted from any device.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  Difficulty _tier = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stream = ref.watch(leaderboardStreamProvider(_tier));
    final currentUser = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text('Leaderboard', style: text.headlineSmall),
                  const Spacer(),
                  Icon(Icons.emoji_events_outlined, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _TierChips(
              selected: _tier,
              onSelect: (t) => setState(() => _tier = t),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: stream.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(message: '$e'),
                data: (entries) => _LeaderboardBody(
                  entries: entries,
                  currentUserId: currentUser?.id,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierChips extends StatelessWidget {
  const _TierChips({required this.selected, required this.onSelect});

  final Difficulty selected;
  final ValueChanged<Difficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final t in Difficulty.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t.label),
                selected: selected == t,
                onSelected: (_) => onSelect(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({required this.entries, required this.currentUserId});

  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _EmptyLeaderboard();

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          child: PodiumView(entries: top3, currentUserId: currentUserId),
        ),
        if (rest.isNotEmpty) ...[
          const _ListHeader(),
          for (var i = 0; i < rest.length; i++)
            _RankRow(
              rank: i + 4,
              entry: rest[i],
              isCurrentUser: rest[i].userId == currentUserId,
            ).animate(delay: (40 * i).ms).fadeIn(duration: 200.ms).slideX(begin: 0.05),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              'Player',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'IQ',
              textAlign: TextAlign.right,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'Time',
              textAlign: TextAlign.right,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    final mins = (entry.bestTimeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (entry.bestTimeSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? scheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: scheme.primary.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHigh,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.displayName.isNotEmpty
                  ? entry.displayName[0].toUpperCase()
                  : '?',
              style: text.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${entry.bestIq}',
              textAlign: TextAlign.right,
              style: text.titleSmall?.copyWith(
                color: entry.bestIq >= 160 ? palette.goldFrame.first : scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$mins:$secs',
              textAlign: TextAlign.right,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No-one has scored on this tier yet.',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first — solve a puzzle to claim #1.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              'Could not load the leaderboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
