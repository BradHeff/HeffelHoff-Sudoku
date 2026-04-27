import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/iq_calculator.dart';
import '../domain/puzzle.dart';

/// Post-game screen. On a win, shows the IQ count-up + Einstein
/// comparison bar with a confetti burst. On a loss, shows the failed
/// state with a "Try Again" CTA.
///
/// When [wasUnderTarget] is true (puzzle solved faster than the tier's
/// target time), the celebration is dialled up: bigger confetti volume,
/// extra particle storm, gold "GENIUS PERFORMANCE" header, and a
/// pulsing gold glow ring around the IQ number — the "ultimate
/// dopamine hit" moment.
class PostGameIqScreen extends StatefulWidget {
  const PostGameIqScreen({
    super.key,
    required this.puzzle,
    required this.timeSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.iqScore,
    required this.won,
    required this.wasUnderTarget,
    required this.onPlayAgain,
    required this.onBackToStart,
  });

  final Puzzle puzzle;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final int iqScore;
  final bool won;
  final bool wasUnderTarget;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToStart;

  @override
  State<PostGameIqScreen> createState() => _PostGameIqScreenState();
}

class _PostGameIqScreenState extends State<PostGameIqScreen> {
  late final ConfettiController _confetti;
  ConfettiController? _geniusBurst;

  @override
  void initState() {
    super.initState();
    final confettiDuration = widget.wasUnderTarget
        ? const Duration(seconds: 4)
        : const Duration(seconds: 2);
    _confetti = ConfettiController(duration: confettiDuration);
    if (widget.wasUnderTarget) {
      _geniusBurst = ConfettiController(duration: const Duration(milliseconds: 1200));
    }
    if (widget.won) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confetti.play();
        _geniusBurst?.play();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _geniusBurst?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;

    if (!widget.won) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.heart_broken, size: 72, color: palette.lifeRed),
              const SizedBox(height: 16),
              Text('Out of lives', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${widget.mistakes} mistakes. No IQ awarded.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: widget.onPlayAgain, child: const Text('Try again')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onBackToStart,
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
      );
    }

    final headline = IqCalculator.einsteinHeadline(widget.iqScore);
    final mins = (widget.timeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (widget.timeSeconds % 60).toString().padLeft(2, '0');
    final genius = widget.wasUnderTarget;
    final iqGradient = (widget.iqScore >= IqCalculator.einsteinIq || genius)
        ? palette.iqGenius
        : [scheme.primary, scheme.tertiary];

    final headlineText = genius
        ? 'GENIUS PERFORMANCE'
        : (widget.iqScore >= IqCalculator.einsteinIq ? 'GENIUS' : 'PUZZLE COMPLETE');
    final headlineColor = genius
        ? palette.goldFrame.first
        : (widget.iqScore >= IqCalculator.einsteinIq
            ? palette.goldFrame.first
            : scheme.onSurfaceVariant);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                headlineText,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  color: headlineColor,
                  letterSpacing: 4,
                  fontWeight: genius ? FontWeight.w900 : FontWeight.w600,
                ),
              ).animate().fadeIn(duration: 400.ms),
              if (genius)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Solved under target time',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                ),
              const SizedBox(height: 8),
              // Big IQ number — count-up animation, with optional gold
              // pulsing glow ring on genius runs.
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (genius)
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.goldFrame.first.withValues(alpha: 0.45),
                              palette.goldFrame.first.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(end: 1.08, duration: 1100.ms, curve: Curves.easeInOut),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.iqScore.toDouble()),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        value.round().toString(),
                        style: iqDisplayStyle(context, size: genius ? 112 : 96).copyWith(
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: iqGradient,
                            ).createShader(const Rect.fromLTWH(0, 0, 240, 120)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('IQ', textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: 24),
              _EinsteinBar(iqScore: widget.iqScore, palette: palette, gradient: iqGradient),
              const SizedBox(height: 16),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ).animate(delay: 1200.ms).fadeIn(),
              const SizedBox(height: 32),
              _StatTile(label: 'Time', value: '$mins:$secs'),
              _StatTile(
                label: 'Target',
                value: _fmtTarget(widget.puzzle.difficulty.targetTimeSeconds),
              ),
              _StatTile(label: 'Mistakes', value: '${widget.mistakes}'),
              _StatTile(label: 'Hints used', value: '${widget.hintsUsed}'),
              _StatTile(label: 'Difficulty', value: widget.puzzle.difficulty.label),
              const Spacer(),
              FilledButton(onPressed: widget.onPlayAgain, child: const Text('Play again')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onBackToStart,
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: 1.5708, // straight down
            shouldLoop: false,
            colors: genius
                ? [...palette.particleTints, ...palette.goldFrame, ...palette.goldFrame]
                : palette.particleTints,
            numberOfParticles: genius ? 60 : 24,
            emissionFrequency: genius ? 0.08 : 0.05,
            gravity: 0.2,
          ),
        ),
        if (_geniusBurst != null)
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _geniusBurst!,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [...palette.goldFrame, palette.iqGenius.first],
              numberOfParticles: 50,
              emissionFrequency: 0.04,
              gravity: 0.18,
              minBlastForce: 6,
              maxBlastForce: 18,
            ),
          ),
      ],
    );
  }

  static String _fmtTarget(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0
        ? '${m.toString().padLeft(2, '0')}:00'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _EinsteinBar extends StatelessWidget {
  const _EinsteinBar({
    required this.iqScore,
    required this.palette,
    required this.gradient,
  });

  final int iqScore;
  final AppPalette palette;
  final List<Color> gradient;

  static const _min = IqCalculator.floorIq;
  static const _max = IqCalculator.ceilingIq;

  double _ratio(int v) => ((v - _min) / (_max - _min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final einsteinX = width * _ratio(IqCalculator.einsteinIq);
        return SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 24),
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: 0,
                top: 24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: width * _ratio(iqScore)),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, w, _) => Container(
                    width: w,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: einsteinX - 1,
                top: 16,
                child: Column(
                  children: [
                    Text('Einstein', style: Theme.of(context).textTheme.labelSmall),
                    Container(width: 2, height: 24, color: scheme.outline),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
