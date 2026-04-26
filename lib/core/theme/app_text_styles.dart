import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Outfit for display + numerals (the IQ score), Inter for body. Both via
/// google_fonts at runtime; no bundled .ttf needed for now.
TextTheme buildTextTheme(ColorScheme scheme) {
  final base = ThemeData(brightness: scheme.brightness).textTheme;

  final body = GoogleFonts.interTextTheme(base).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  final outfit = GoogleFonts.outfitTextTheme(base);

  return body.copyWith(
    displayLarge: outfit.displayLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      color: scheme.onSurface,
    ),
    displayMedium: outfit.displayMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    ),
    displaySmall: outfit.displaySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    headlineLarge: outfit.headlineLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    headlineMedium: outfit.headlineMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    headlineSmall: outfit.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    titleLarge: outfit.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
  );
}

/// Big, bold, monospaced-feeling number style for the IQ result and
/// podium IQ scores. Outfit Bold at 56pt with tight tracking.
TextStyle iqDisplayStyle(BuildContext context, {Color? color, double size = 56}) {
  final scheme = Theme.of(context).colorScheme;
  return GoogleFonts.outfit(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: color ?? scheme.onSurface,
    height: 1.0,
  );
}

/// In-cell digit style for the Sudoku board.
TextStyle cellDigitStyle(BuildContext context, {required Color color, bool bold = false}) {
  return GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    color: color,
    height: 1.0,
  );
}
