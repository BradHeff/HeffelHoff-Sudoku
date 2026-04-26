import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/iq_calculator.dart';
import '../domain/puzzle.dart';

/// Post-game screen. On a win, shows the IQ count-up + Einstein
/// comparison bar with a confetti burst. On a loss, shows the failed
/// state with a "Try Again" CTA. Phase 4 layers in the full particle
/// storm + Lottie achievement burst.
class PostGameIqScreen extends StatefulWidget {
  const PostGameIqScreen({
    super.key,
    required this.puzzle,
    required this.timeSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.iqScore,
    required this.won,
    required this.onReplay,
  });

  final Puzzle puzzle;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final int iqScore;
  final bool won;
  final VoidCallback onReplay;

  @override
  State<PostGameIqScreen> createState() => _PostGameIqScreenState();
}

class _PostGameIqScreenState extends State<PostGameIqScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.won) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
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
              FilledButton(onPressed: widget.onReplay, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final headline = IqCalculator.einsteinHeadline(widget.iqScore);
    final mins = (widget.timeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (widget.timeSeconds % 60).toString().padLeft(2, '0');

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                widget.iqScore >= IqCalculator.einsteinIq ? '🧠 GENIUS' : 'PUZZLE COMPLETE',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              // Big IQ number — count-up animation.
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.iqScore.toDouble()),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    value.round().toString(),
                    style: iqDisplayStyle(context, size: 96).copyWith(
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: widget.iqScore >= IqCalculator.einsteinIq
                              ? palette.iqGenius
                              : [scheme.primary, scheme.tertiary],
                        ).createShader(const Rect.fromLTWH(0, 0, 240, 100)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('IQ', textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: 24),
              _EinsteinBar(iqScore: widget.iqScore, palette: palette),
              const SizedBox(height: 16),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ).animate(delay: 1200.ms).fadeIn(),
              const SizedBox(height: 32),
              _StatTile(label: 'Time', value: '$mins:$secs'),
              _StatTile(label: 'Mistakes', value: '${widget.mistakes}'),
              _StatTile(label: 'Hints used', value: '${widget.hintsUsed}'),
              _StatTile(label: 'Difficulty', value: widget.puzzle.difficulty.label),
              const Spacer(),
              FilledButton(onPressed: widget.onReplay, child: const Text('Play again')),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: 1.5708, // straight down
            shouldLoop: false,
            colors: palette.particleTints,
            numberOfParticles: 24,
            emissionFrequency: 0.05,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EinsteinBar extends StatelessWidget {
  const _EinsteinBar({required this.iqScore, required this.palette});

  final int iqScore;
  final AppPalette palette;

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
              // Track
              Container(
                margin: const EdgeInsets.only(top: 24),
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // User fill, animated
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
                      gradient: LinearGradient(
                        colors: iqScore >= IqCalculator.einsteinIq
                            ? palette.iqGenius
                            : [scheme.primary, scheme.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              // Einstein tick
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
