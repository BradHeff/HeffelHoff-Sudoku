import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/leaderboard_entry.dart';

/// Top-3 podium. #1 in the center is taller and idle-bobs; #2 left,
/// #3 right. Each card frames its rank colour (gold/silver/bronze)
/// with a glowing border and a halo under the avatar circle.
class PodiumView extends StatelessWidget {
  const PodiumView({
    super.key,
    required this.entries,
    required this.currentUserId,
  });

  /// Up to 3 entries, in rank order (index 0 = #1).
  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;

    LeaderboardEntry? at(int i) => i < entries.length ? entries[i] : null;

    final first = at(0);
    final second = at(1);
    final third = at(2);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumCard(
              entry: second,
              rank: 2,
              frame: palette.silverFrame,
              isCurrentUser: second?.userId == currentUserId,
              height: 170,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: _PodiumCard(
              entry: first,
              rank: 1,
              frame: palette.goldFrame,
              isCurrentUser: first?.userId == currentUserId,
              height: 220,
              showCrown: true,
              bob: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumCard(
              entry: third,
              rank: 3,
              frame: palette.bronzeFrame,
              isCurrentUser: third?.userId == currentUserId,
              height: 150,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.rank,
    required this.frame,
    required this.isCurrentUser,
    required this.height,
    this.showCrown = false,
    this.bob = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final List<Color> frame;
  final bool isCurrentUser;
  final double height;
  final bool showCrown;
  final bool bob;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final empty = entry == null;

    Widget card = Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: empty ? scheme.outlineVariant : frame.first,
          width: empty ? 1 : 2,
        ),
        boxShadow: empty
            ? null
            : [
                BoxShadow(
                  color: frame.first.withValues(alpha: 0.4),
                  blurRadius: 18,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: empty ? null : LinearGradient(colors: frame),
              color: empty ? scheme.surfaceContainerHigh : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '#$rank',
              style: text.titleSmall?.copyWith(
                color: empty ? scheme.onSurfaceVariant : const Color(0xFF21140A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '—',
                style: text.headlineMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                boxShadow: [
                  BoxShadow(color: frame.first.withValues(alpha: 0.5), blurRadius: 14),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                entry!.displayName.isNotEmpty
                    ? entry!.displayName[0].toUpperCase()
                    : '?',
                style: text.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              entry!.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(colors: frame).createShader(rect),
              child: Text(
                '${entry!.bestIq}',
                style: iqDisplayStyle(context, size: 28, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );

    if (showCrown && !empty) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.emoji_events,
                color: frame.first,
                size: 28,
                shadows: [
                  Shadow(color: frame.first.withValues(alpha: 0.7), blurRadius: 14),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (bob) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -4, duration: 2400.ms, curve: Curves.easeInOut);
    }

    return card;
  }
}
