import 'package:flutter/material.dart';

/// Custom theme extension for game-specific tokens that don't map cleanly
/// to a Material 3 ColorScheme role: podium frames, life heart, IQ-genius
/// gradient, and the persistent particle layer's tint palette.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.goldFrame,
    required this.silverFrame,
    required this.bronzeFrame,
    required this.lifeRed,
    required this.lifeRedFaded,
    required this.iqGenius,
    required this.particleTints,
  });

  final List<Color> goldFrame;
  final List<Color> silverFrame;
  final List<Color> bronzeFrame;
  final Color lifeRed;
  final Color lifeRedFaded;
  final List<Color> iqGenius;
  final List<Color> particleTints;

  static const dark = AppPalette(
    goldFrame: [Color(0xFFFFD700), Color(0xFFFFA500)],
    silverFrame: [Color(0xFFC0C0C0), Color(0xFFE5E4E2)],
    bronzeFrame: [Color(0xFFCD7F32), Color(0xFFB87333)],
    lifeRed: Color(0xFFFF5470),
    lifeRedFaded: Color(0x33FF5470),
    iqGenius: [Color(0xFFB388FF), Color(0xFF7C4DFF), Color(0xFF536DFE)],
    particleTints: [
      Color(0xFFFFD700),
      Color(0xFFB388FF),
      Color(0xFF80DEEA),
      Color(0xFFFF80AB),
      Color(0xFFFFFFFF),
      Color(0xFF00E5FF),
    ],
  );

  static const light = AppPalette(
    goldFrame: [Color(0xFFFFC400), Color(0xFFFF8F00)],
    silverFrame: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
    bronzeFrame: [Color(0xFFA0522D), Color(0xFF8B4513)],
    lifeRed: Color(0xFFE91E63),
    lifeRedFaded: Color(0x33E91E63),
    iqGenius: [Color(0xFF6750A4), Color(0xFF7C4DFF), Color(0xFF3F51B5)],
    particleTints: [
      Color(0xFFFFB300),
      Color(0xFF6750A4),
      Color(0xFF00ACC1),
      Color(0xFFEC407A),
      Color(0xFFFFFFFF),
      Color(0xFF00BCD4),
    ],
  );

  @override
  AppPalette copyWith({
    List<Color>? goldFrame,
    List<Color>? silverFrame,
    List<Color>? bronzeFrame,
    Color? lifeRed,
    Color? lifeRedFaded,
    List<Color>? iqGenius,
    List<Color>? particleTints,
  }) {
    return AppPalette(
      goldFrame: goldFrame ?? this.goldFrame,
      silverFrame: silverFrame ?? this.silverFrame,
      bronzeFrame: bronzeFrame ?? this.bronzeFrame,
      lifeRed: lifeRed ?? this.lifeRed,
      lifeRedFaded: lifeRedFaded ?? this.lifeRedFaded,
      iqGenius: iqGenius ?? this.iqGenius,
      particleTints: particleTints ?? this.particleTints,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      goldFrame: _lerpList(goldFrame, other.goldFrame, t),
      silverFrame: _lerpList(silverFrame, other.silverFrame, t),
      bronzeFrame: _lerpList(bronzeFrame, other.bronzeFrame, t),
      lifeRed: Color.lerp(lifeRed, other.lifeRed, t)!,
      lifeRedFaded: Color.lerp(lifeRedFaded, other.lifeRedFaded, t)!,
      iqGenius: _lerpList(iqGenius, other.iqGenius, t),
      particleTints: _lerpList(particleTints, other.particleTints, t),
    );
  }

  static List<Color> _lerpList(List<Color> a, List<Color> b, double t) {
    final n = a.length < b.length ? a.length : b.length;
    return [for (var i = 0; i < n; i++) Color.lerp(a[i], b[i], t)!];
  }
}
