import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Centered "wow moment" overlay shown when the player completes all 9
/// instances of a digit on the board. Fires a confetti burst from the
/// center, animates the digit in big gold letters with a sparkle aura,
/// and fades out after [duration].
///
/// Drives off a non-null [digit] + [triggeredAt] pair: when the keying
/// timestamp changes, the animation re-fires, even if the digit value
/// is the same as a previous celebration.
class DigitCompleteOverlay extends StatefulWidget {
  const DigitCompleteOverlay({
    super.key,
    required this.digit,
    required this.triggeredAt,
    this.duration = const Duration(milliseconds: 1500),
  });

  final int digit;
  final DateTime triggeredAt;
  final Duration duration;

  @override
  State<DigitCompleteOverlay> createState() => _DigitCompleteOverlayState();
}

class _DigitCompleteOverlayState extends State<DigitCompleteOverlay> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
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

    final key = ValueKey('digit-complete-${widget.digit}-${widget.triggeredAt.microsecondsSinceEpoch}');

    return IgnorePointer(
      key: key,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Backdrop dim — subtle, doesn't block the board.
          Positioned.fill(
            child: Container(color: scheme.scrim.withValues(alpha: 0.18))
                .animate()
                .fadeIn(duration: 120.ms)
                .then(delay: widget.duration - const Duration(milliseconds: 350))
                .fadeOut(duration: 350.ms),
          ),
          // Soft radial sparkle aura behind the digit.
          _SparkleAura(palette: palette).animate().fadeIn(duration: 200.ms).scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          // The big digit.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: palette.goldFrame,
                ).createShader(rect),
                child: Text(
                  '${widget.digit}',
                  style: text.displayLarge?.copyWith(
                    fontSize: 180,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: palette.goldFrame.first.withValues(alpha: 0.6),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shake(hz: 4, duration: 250.ms, offset: const Offset(2, 0))
                  .then(delay: widget.duration - const Duration(milliseconds: 1100))
                  .fadeOut(duration: 350.ms)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 350.ms,
                    curve: Curves.easeIn,
                  ),
              const SizedBox(height: 4),
              Text(
                'COMPLETE',
                style: text.titleMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                  color: palette.goldFrame.first,
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.3, end: 0)
                  .then(delay: widget.duration - const Duration(milliseconds: 850))
                  .fadeOut(duration: 250.ms),
            ],
          ),
          // Confetti burst from the center, blasting outward in all directions.
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: palette.particleTints,
            numberOfParticles: 32,
            emissionFrequency: 0.02,
            gravity: 0.18,
            minBlastForce: 4,
            maxBlastForce: 14,
          ),
        ],
      ),
    );
  }
}

/// A simple radial gradient "sparkle aura" rendered behind the digit.
/// Cheaper than spawning many CustomPainter particles for a one-shot.
class _SparkleAura extends StatelessWidget {
  const _SparkleAura({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: CustomPaint(painter: _SparkleAuraPainter(palette: palette)),
    );
  }
}

class _SparkleAuraPainter extends CustomPainter {
  _SparkleAuraPainter({required this.palette});
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Halo: radial gradient from gold center to transparent edge.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.goldFrame.first.withValues(alpha: 0.55),
          palette.goldFrame.last.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, haloPaint);

    // Light rays (8-spoke star).
    final rayPaint = Paint()
      ..color = palette.goldFrame.first.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final theta = (math.pi / 4) * i;
      final inner = center + Offset(math.cos(theta), math.sin(theta)) * (radius * 0.22);
      final outer = center + Offset(math.cos(theta), math.sin(theta)) * (radius * 0.96);
      canvas.drawLine(inner, outer, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleAuraPainter old) => false;
}
