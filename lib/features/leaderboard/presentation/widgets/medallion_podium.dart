import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/leaderboard_entry.dart';

/// Horizontal three-coin podium for the top three leaderboard entries.
/// Center coin (gold, #1) is larger and idle-bobs; silver (#2) sits to
/// its left, bronze (#3) to its right. Each coin is painted as a
/// gradient circle with a laurel-wreath ring + crown + rank stamp.
class MedallionPodium extends StatelessWidget {
  const MedallionPodium({
    super.key,
    required this.entries,
    required this.currentUserId,
  });

  /// Up to 3 entries in rank order (index 0 = #1).
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _MedallionColumn(
              entry: second,
              rank: 2,
              size: 110,
              colors: palette.silverFrame,
              isCurrentUser: second?.userId == currentUserId,
            ),
          ),
          Expanded(
            flex: 5,
            child: _MedallionColumn(
              entry: first,
              rank: 1,
              size: 144,
              colors: palette.goldFrame,
              isCurrentUser: first?.userId == currentUserId,
              hero: true,
            ),
          ),
          Expanded(
            child: _MedallionColumn(
              entry: third,
              rank: 3,
              size: 100,
              colors: palette.bronzeFrame,
              isCurrentUser: third?.userId == currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedallionColumn extends StatelessWidget {
  const _MedallionColumn({
    required this.entry,
    required this.rank,
    required this.size,
    required this.colors,
    required this.isCurrentUser,
    this.hero = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double size;
  final List<Color> colors;
  final bool isCurrentUser;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget coin = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedallionPainter(rank: rank, colors: colors),
      ),
    );

    if (hero) {
      coin = coin
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Curves.easeInOut);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        coin,
        const SizedBox(height: 8),
        if (entry == null)
          Text(
            '—',
            style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else ...[
          Text(
            entry!.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelLarge?.copyWith(
              fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w600,
              color: isCurrentUser ? colors.first : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(colors: colors).createShader(rect),
            child: Text(
              '${entry!.bestIq}',
              style: iqDisplayStyle(context, size: hero ? 28 : 22, color: Colors.white)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom-painted medal coin — gradient body, laurel-ring etched
/// border, crown notch at top, rank number stamped in the centre,
/// year band at the bottom.
class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.rank, required this.colors});

  final int rank;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);
    final centre = Offset(cx, cy);

    // Outer drop-shadow halo
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..color = colors.first.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Laurel ring (outer)
    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [colors.first, colors.last],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: centre, radius: r));
    canvas.drawCircle(centre, r * 0.96, ringPaint);

    // Inner coin face
    canvas.drawCircle(
      centre,
      r * 0.78,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.first, colors.last],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: centre, radius: r * 0.78)),
    );

    // Subtle highlight arc on the upper-left for shine
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r * 0.7),
      -math.pi * 0.85,
      math.pi * 0.55,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // Laurel notches around the rim — 24 short ticks
    final tickPaint = Paint()
      ..color = colors.last.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final theta = (math.pi * 2) * i / 24;
      final inner = centre + Offset(math.cos(theta), math.sin(theta)) * (r * 0.82);
      final outer = centre + Offset(math.cos(theta), math.sin(theta)) * (r * 0.92);
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Crown silhouette at the top
    _drawCrown(canvas, Offset(cx, cy - r * 0.32), r * 0.32);

    // Big rank number (centred)
    final rankText = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: TextStyle(
          color: const Color(0xFF21140A),
          fontWeight: FontWeight.w900,
          fontSize: r * 0.78,
          height: 1.0,
          letterSpacing: -2,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.45),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    rankText.paint(
      canvas,
      Offset(cx - rankText.width / 2, cy - rankText.height / 2 + r * 0.04),
    );

    // Year stamp ribbon at the bottom
    final yearText = TextPainter(
      text: TextSpan(
        text: '2026',
        style: TextStyle(
          color: const Color(0xFF21140A).withValues(alpha: 0.65),
          fontWeight: FontWeight.w800,
          fontSize: r * 0.18,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yearText.paint(
      canvas,
      Offset(cx - yearText.width / 2, cy + r * 0.46),
    );
  }

  void _drawCrown(Canvas canvas, Offset c, double size) {
    final paint = Paint()
      ..color = const Color(0xFF21140A).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(c.dx - size * 0.6, c.dy + size * 0.15)
      // Three peaks
      ..lineTo(c.dx - size * 0.6, c.dy - size * 0.15)
      ..lineTo(c.dx - size * 0.3, c.dy + size * 0.05)
      ..lineTo(c.dx, c.dy - size * 0.3)
      ..lineTo(c.dx + size * 0.3, c.dy + size * 0.05)
      ..lineTo(c.dx + size * 0.6, c.dy - size * 0.15)
      ..lineTo(c.dx + size * 0.6, c.dy + size * 0.15)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) =>
      old.rank != rank || old.colors != colors;
}
