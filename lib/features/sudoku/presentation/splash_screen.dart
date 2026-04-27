import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';

/// In-app splash with animated brain logo + spark ring.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2200),
  });

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    Future<void>.delayed(widget.duration, () {
      if (!mounted) return;
      context.go('/');
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF01072D),
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _GridBackdrop()),

          AnimatedBuilder(
            animation: _ringController,
            builder: (context, _) => CustomPaint(
              size: const Size(360, 360),
              painter: _SparkRingPainter(t: _ringController.value),
            ),
          ),

          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x6636A8FA), Color(0x0036A8FA)],
                stops: [0, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF36A8FA).withValues(alpha: 0.45),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/branding/logo.png'),
            ),
          )
              .animate()
              .scaleXY(begin: 0.6, end: 1.0, duration: 700.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 600.ms)
              .then(delay: 100.ms)
              .shimmer(
                duration: 1200.ms,
                color: const Color(0xFF36A8FA),
                size: 0.7,
              ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'HEFFELHOFF',
                  style: iqDisplayStyle(
                    context,
                    size: 22,
                    color: const Color(0xFFE4EDFC).withValues(alpha: 0.85),
                  ).copyWith(letterSpacing: 6, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ).animate(delay: 600.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFF36A8FA), Color(0xFFA35DF4)],
                  ).createShader(rect),
                  child: Text(
                    'SUDOKU',
                    style: iqDisplayStyle(context, size: 48, color: Colors.white)
                        .copyWith(letterSpacing: 8, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1948E0).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

class _SparkRingPainter extends CustomPainter {
  _SparkRingPainter({required this.t});
  final double t;

  static const _palette = [
    Color(0xFF36A8FA),
    Color(0xFFA35DF4),
    Color(0xFFE4EDFC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const count = 14;
    for (var i = 0; i < count; i++) {
      final theta = (math.pi * 2) * (i / count) + t * math.pi * 2;
      final pos = center + Offset(math.cos(theta), math.sin(theta)) * radius;
      final color = _palette[i % _palette.length];
      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(pos, 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkRingPainter old) => old.t != t;
}
