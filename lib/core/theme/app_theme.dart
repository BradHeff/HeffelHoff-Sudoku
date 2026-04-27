import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 themes. The default seed is HeffelHoff brand cyan
/// (#36A8FA) — extracted from assets/branding/playstore_icon.png and
/// documented in docs/BRANDING.md. A retro-violet alternate
/// (#7C4DFF) ships in Phase 4 via settings.
class AppTheme {
  /// HeffelHoff brand cyan. Use for primary actions, headlines, focus.
  static const Color seedDefault = Color(0xFF36A8FA);

  /// Alternate retro-violet seed (Phase 4 settings toggle).
  static const Color seedNeon = Color(0xFF7C4DFF);

  /// Brand background — deep navy that matches the icon's grid backdrop.
  static const Color brandBackground = Color(0xFF01072D);

  static ThemeData light({Color seed = seedDefault}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    return _build(scheme, AppPalette.light);
  }

  static ThemeData dark({Color seed = seedDefault}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    return _build(scheme, AppPalette.dark);
  }

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final textTheme = buildTextTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? brandBackground : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? brandBackground : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
