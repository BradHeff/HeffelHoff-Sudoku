import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../sudoku/domain/difficulty.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_entry.dart';
import 'widgets/leaderboard_header.dart';
import 'widgets/legendary_rosette.dart';
import 'widgets/rank_rosette.dart';

/// Payload for the leaderboard climb animation after a puzzle win.
class LeaderboardArrival {
  const LeaderboardArrival({
    required this.tier,
    required this.userId,
    required this.previousIq,
    required this.newIq,
  });

  final Difficulty tier;
  final String userId;
  final int previousIq;
  final int newIq;
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, this.arrival});

  final LeaderboardArrival? arrival;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late Difficulty _tier;

  @override
  void initState() {
    super.initState();
    _tier = widget.arrival?.tier ?? Difficulty.easy;
  }

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
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(leaderboardStreamProvider(_tier));
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                },
                child: stream.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      _ErrorView(message: '$e'),
                    ],
                  ),
                  data: (entries) => _LeaderboardBody(
                    entries: entries,
                    currentUserId: currentUser?.id,
                    arrival: widget.arrival?.tier == _tier ? widget.arrival : null,
                  ),
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
  const _LeaderboardBody({
    required this.entries,
    required this.currentUserId,
    required this.arrival,
  });

  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final LeaderboardArrival? arrival;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: LeaderboardHeader(),
        ),
        if (entries.isEmpty)
          const _EmptyLeaderboard()
        else ...[
          const _ListHeader(),
          for (var i = 0; i < entries.length; i++)
            _RankRow(
              rank: i + 1,
              entry: entries[i],
              isCurrentUser: entries[i].userId == currentUserId,
              arrival: entries[i].userId == arrival?.userId ? arrival : null,
            ).animate(delay: (35 * i).ms).fadeIn(duration: 200.ms).slideX(begin: 0.05),
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
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
    required this.arrival,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final LeaderboardArrival? arrival;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    final mins = (entry.bestTimeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (entry.bestTimeSeconds % 60).toString().padLeft(2, '0');

    final isTopThree = rank <= 3;
    final List<Color> topGradient = switch (rank) {
      1 => palette.goldFrame,
      2 => palette.silverFrame,
      3 => palette.bronzeFrame,
      _ => [scheme.primary, scheme.primary],
    };
    final Color rosetteColor =
        isCurrentUser ? scheme.primary : scheme.surfaceContainerHigh;

    Widget iqText;
    if (arrival != null) {
      iqText = TweenAnimationBuilder<double>(
        tween: Tween(
          begin: arrival!.previousIq.toDouble(),
          end: arrival!.newIq.toDouble(),
        ),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Text(
          '${value.round()}',
          textAlign: TextAlign.right,
          style: text.titleSmall?.copyWith(
            color: entry.bestIq >= 160 ? palette.goldFrame.first : scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    } else {
      iqText = Text(
        '${entry.bestIq}',
        textAlign: TextAlign.right,
        style: text.titleSmall?.copyWith(
          color: entry.bestIq >= 160 ? palette.goldFrame.first : scheme.primary,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    Widget row = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isTopThree ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? scheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: scheme.primary.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: isTopThree ? 72 : 40,
            child: Center(
              child: isTopThree
                  ? LegendaryRosette(
                      rank: rank,
                      gradient: topGradient,
                      size: 56,
                      isCurrentUser: isCurrentUser,
                    )
                  : RankRosette(
                      rank: rank,
                      size: 32,
                      color: rosetteColor,
                      highlight: isCurrentUser,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTopThree)
                  _TierLabelPill(
                    label: LegendaryRosette.tierLabel(rank),
                    gradient: topGradient,
                  ),
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: isCurrentUser || isTopThree
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 60, child: iqText),
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

    if (arrival != null) {
      row = row
          .animate()
          .fadeIn(duration: 300.ms)
          .then(delay: 100.ms)
          .scaleXY(end: 1.04, duration: 600.ms, curve: Curves.easeOutBack)
          .then()
          .scaleXY(end: 1.0, duration: 400.ms);
    }

    return row;
  }
}

class _TierLabelPill extends StatelessWidget {
  const _TierLabelPill({required this.label, required this.gradient});

  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF21140A),
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 1.5,
        ),
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

  ({String title, String body, IconData icon}) get _humanised {
    final lower = message.toLowerCase();

    if (lower.contains('pgrst205') ||
        (lower.contains('schema cache') && lower.contains('leaderboard'))) {
      return (
        title: 'Schema cache not ready',
        body: 'Either the leaderboard migrations haven\'t been '
            'pushed yet, or PostgREST is still refreshing its '
            'schema cache after a recent push. Run "supabase db '
            'push" if you haven\'t, then go to the SQL editor and '
            "run: NOTIFY pgrst, 'reload schema';  This usually "
            'clears in a few minutes on its own. Pull to retry.',
        icon: Icons.cloud_off_outlined,
      );
    }

    if (lower.contains('pgrst200') ||
        lower.contains('could not find a relationship')) {
      return (
        title: 'Schema relationship missing',
        body: 'PostgREST can\'t find the FK between leaderboard '
            'entries and profiles. Run "supabase db push" to apply '
            '0004_leaderboard_profiles_fk.sql, then NOTIFY pgrst.',
        icon: Icons.link_off_outlined,
      );
    }

    if (lower.contains('jwt') || lower.contains('not authenticated')) {
      return (
        title: 'Not signed in',
        body: 'Tap the avatar on the home screen to sign in or '
            'continue as guest before viewing the leaderboard.',
        icon: Icons.lock_outline,
      );
    }

    if (lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('socketexception')) {
      return (
        title: 'No connection',
        body: 'The leaderboard needs an internet connection. Check '
            'your network and try again.',
        icon: Icons.wifi_off_outlined,
      );
    }

    return (
      title: 'Could not load the leaderboard',
      body: message,
      icon: Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = _humanised;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(h.icon, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              h.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              h.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
