import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Stacked "ROW/COL/BOX COMPLETE" pills shown above the board on a
/// structure-completion event, with a combo badge for 2+ structures.
class StructureCompleteToast extends StatelessWidget {
  const StructureCompleteToast({
    super.key,
    required this.completedRow,
    required this.completedCol,
    required this.completedBox,
    required this.completedDigit,
    required this.triggeredAt,
    this.duration = const Duration(milliseconds: 1500),
  });

  final int? completedRow;
  final int? completedCol;
  final int? completedBox;
  final int? completedDigit;
  final DateTime triggeredAt;
  final Duration duration;

  int get _comboCount => [completedRow, completedCol, completedBox, completedDigit]
      .where((e) => e != null)
      .length;

  String? get _comboLabel => switch (_comboCount) {
        2 => 'DOUBLE',
        3 => 'TRIPLE',
        4 => 'QUAD',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final pills = <Widget>[];

    if (_comboLabel != null) {
      pills.add(_ComboBadge(label: _comboLabel!, palette: palette));
    }
    if (completedRow != null) {
      pills.add(_StructurePill(
        label: 'ROW ${completedRow! + 1} COMPLETE',
        palette: palette,
      ));
    }
    if (completedCol != null) {
      pills.add(_StructurePill(
        label: 'COL ${completedCol! + 1} COMPLETE',
        palette: palette,
      ));
    }
    if (completedBox != null) {
      pills.add(_StructurePill(
        label: 'BOX ${completedBox! + 1} COMPLETE',
        palette: palette,
      ));
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      key: ValueKey('structure-toast-${triggeredAt.microsecondsSinceEpoch}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pills.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: pills[i]
                  .animate(delay: (80 * i).ms)
                  .slideY(begin: -0.6, end: 0, duration: 320.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 240.ms)
                  .then(delay: duration - const Duration(milliseconds: 600))
                  .fadeOut(duration: 280.ms)
                  .slideY(begin: 0, end: -0.3, duration: 280.ms),
            ),
        ],
      ),
    );
  }
}

class _StructurePill extends StatelessWidget {
  const _StructurePill({required this.label, required this.palette});
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette.goldFrame),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: palette.goldFrame.first.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF21140A),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.label, required this.palette});
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.iqGenius.first, palette.iqGenius[1]],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: palette.iqGenius[1].withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        '$label COMBO',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 14,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.06, duration: 600.ms, curve: Curves.easeInOut);
  }
}
