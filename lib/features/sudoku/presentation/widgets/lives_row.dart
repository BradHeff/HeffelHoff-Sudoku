import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Three-heart lives row with crumble animation on damage.
class LivesRow extends StatelessWidget {
  const LivesRow({super.key, required this.lives, required this.maxLives});

  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxLives; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _Heart(
              filled: i < lives,
              key: ValueKey('heart-$i-${i < lives}'),
              filledColor: palette.lifeRed,
              emptyColor: palette.lifeRedFaded,
            ),
          ),
      ],
    );
  }
}

class _Heart extends StatelessWidget {
  const _Heart({
    super.key,
    required this.filled,
    required this.filledColor,
    required this.emptyColor,
  });

  final bool filled;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.favorite : Icons.favorite_border,
      color: filled ? filledColor : emptyColor,
      size: 22,
    );
    if (filled) return icon;

    return icon
        .animate()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 250.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 100.ms)
        .then(delay: 50.ms)
        .rotate(begin: -0.05, end: 0.0, duration: 200.ms);
  }
}
