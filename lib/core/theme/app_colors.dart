import 'package:flutter/material.dart';

/// Custom theme extension for game-specific tokens that don't map cleanly
/// to a Material 3 ColorScheme role: podium frames, life heart, IQ-genius
/// gradient, the persistent particle palette, and — most importantly —
/// hand-tuned Sudoku cell-state surface + foreground colors.
///
/// We deliberately bypass `ColorScheme.surfaceContainerLow/High/...` for
/// cell states because the auto-generated tonal palette is too subtle on
/// dark themes — selected/peer/same-digit shades all collapse into
/// near-identical greys. The tokens below are picked manually for clear
/// visual hierarchy:
///
///   wrong > selected  >  sameDigit  >  peer  >  surface
///
/// Givens and empty cells share the same surface (distinguished only by
/// font weight) to avoid a "checkerboard" speckle effect on the board.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.goldFrame,
    required this.silverFrame,
    required this.bronzeFrame,
    required this.lifeRed,
    required this.lifeRedFaded,
    required this.iqGenius,
    required this.particleTints,
    required this.cellSurface,
    required this.cellPeer,
    required this.cellSameDigit,
    required this.cellSelected,
    required this.cellSelectedFg,
    required this.cellWrong,
    required this.cellWrongFg,
    required this.cellGivenDigit,
    required this.cellUserDigit,
    required this.cellSameDigitFg,
    required this.boardLine,
    required this.boardLineThick,
  });

  final List<Color> goldFrame;
  final List<Color> silverFrame;
  final List<Color> bronzeFrame;
  final Color lifeRed;
  final Color lifeRedFaded;
  final List<Color> iqGenius;
  final List<Color> particleTints;

  /// Default board cell background (used for both empty and given cells).
  final Color cellSurface;

  /// Wash applied to all cells in the same row, column, or 3×3 box as
  /// the selected cell. Subtle but visibly different from [cellSurface].
  final Color cellPeer;

  /// Background for cells whose value matches the selected cell's value.
  /// Stronger than [cellPeer], a different hue from [cellSelected] so
  /// the two states are unambiguously distinct.
  final Color cellSameDigit;

  /// The currently-focused cell. Loudest non-error state.
  final Color cellSelected;

  /// Digit colour on a [cellSelected] background.
  final Color cellSelectedFg;

  /// Wrong-entry cell.
  final Color cellWrong;
  final Color cellWrongFg;

  /// Original puzzle clues (immutable, bold).
  final Color cellGivenDigit;

  /// Player-placed correct digits.
  final Color cellUserDigit;

  /// Digit colour when the cell is part of the same-digit highlight.
  final Color cellSameDigitFg;

  /// Thin lines between cells.
  final Color boardLine;

  /// Thick lines between 3×3 boxes.
  final Color boardLineThick;

  // ---------------------------------------------------------------------
  // Brand palette extracted from assets/branding/playstore_icon.png:
  //   #01072D deep navy   — base background
  //   #030D4E dark navy   — surface
  //   #05166F mid navy    — elevated surface
  //   #1948E0 electric    — secondary accent (peer wash, info)
  //   #36A8FA cyan glow   — PRIMARY brand accent (selected, headlines)
  //   #A35DF4 violet      — tertiary accent (HH letterform, achievements)
  //   #E4EDFC pale ice    — foreground text on dark surfaces
  // See docs/BRANDING.md for the canonical guide.
  // ---------------------------------------------------------------------
  static const dark = AppPalette(
    goldFrame: [Color(0xFFFFD700), Color(0xFFFFA500)],
    silverFrame: [Color(0xFFC0C0C0), Color(0xFFE5E4E2)],
    bronzeFrame: [Color(0xFFCD7F32), Color(0xFFB87333)],
    lifeRed: Color(0xFFFF5470),
    lifeRedFaded: Color(0x33FF5470),
    iqGenius: [Color(0xFF36A8FA), Color(0xFFA35DF4), Color(0xFFE4EDFC)],
    particleTints: [
      Color(0xFF36A8FA),
      Color(0xFFA35DF4),
      Color(0xFF1948E0),
      Color(0xFFE4EDFC),
      Color(0xFFFFD700),
      Color(0xFFFFFFFF),
    ],
    cellSurface: Color(0xFF0A1230),
    cellPeer: Color(0xFF152459),
    cellSameDigit: Color(0xFF1948E0),
    cellSelected: Color(0xFF36A8FA),
    cellSelectedFg: Color(0xFF01072D),
    cellWrong: Color(0xFF4A1430),
    cellWrongFg: Color(0xFFFFB0C4),
    cellGivenDigit: Color(0xFFE4EDFC),
    cellUserDigit: Color(0xFF36A8FA),
    cellSameDigitFg: Color(0xFFE4EDFC),
    boardLine: Color(0xFF1A2454),
    boardLineThick: Color(0xFF36A8FA),
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
    cellSurface: Color(0xFFFBFAFF),
    cellPeer: Color(0xFFEDE6FA),
    cellSameDigit: Color(0xFFC9B5F2),
    cellSelected: Color(0xFF6750A4),
    cellSelectedFg: Color(0xFFFFFFFF),
    cellWrong: Color(0xFFFFD8E0),
    cellWrongFg: Color(0xFF8B0028),
    cellGivenDigit: Color(0xFF1A1A2E),
    cellUserDigit: Color(0xFF6750A4),
    cellSameDigitFg: Color(0xFF1A1A2E),
    boardLine: Color(0xFFD8D2E8),
    boardLineThick: Color(0xFF7B6FA0),
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
    Color? cellSurface,
    Color? cellPeer,
    Color? cellSameDigit,
    Color? cellSelected,
    Color? cellSelectedFg,
    Color? cellWrong,
    Color? cellWrongFg,
    Color? cellGivenDigit,
    Color? cellUserDigit,
    Color? cellSameDigitFg,
    Color? boardLine,
    Color? boardLineThick,
  }) {
    return AppPalette(
      goldFrame: goldFrame ?? this.goldFrame,
      silverFrame: silverFrame ?? this.silverFrame,
      bronzeFrame: bronzeFrame ?? this.bronzeFrame,
      lifeRed: lifeRed ?? this.lifeRed,
      lifeRedFaded: lifeRedFaded ?? this.lifeRedFaded,
      iqGenius: iqGenius ?? this.iqGenius,
      particleTints: particleTints ?? this.particleTints,
      cellSurface: cellSurface ?? this.cellSurface,
      cellPeer: cellPeer ?? this.cellPeer,
      cellSameDigit: cellSameDigit ?? this.cellSameDigit,
      cellSelected: cellSelected ?? this.cellSelected,
      cellSelectedFg: cellSelectedFg ?? this.cellSelectedFg,
      cellWrong: cellWrong ?? this.cellWrong,
      cellWrongFg: cellWrongFg ?? this.cellWrongFg,
      cellGivenDigit: cellGivenDigit ?? this.cellGivenDigit,
      cellUserDigit: cellUserDigit ?? this.cellUserDigit,
      cellSameDigitFg: cellSameDigitFg ?? this.cellSameDigitFg,
      boardLine: boardLine ?? this.boardLine,
      boardLineThick: boardLineThick ?? this.boardLineThick,
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
      cellSurface: Color.lerp(cellSurface, other.cellSurface, t)!,
      cellPeer: Color.lerp(cellPeer, other.cellPeer, t)!,
      cellSameDigit: Color.lerp(cellSameDigit, other.cellSameDigit, t)!,
      cellSelected: Color.lerp(cellSelected, other.cellSelected, t)!,
      cellSelectedFg: Color.lerp(cellSelectedFg, other.cellSelectedFg, t)!,
      cellWrong: Color.lerp(cellWrong, other.cellWrong, t)!,
      cellWrongFg: Color.lerp(cellWrongFg, other.cellWrongFg, t)!,
      cellGivenDigit: Color.lerp(cellGivenDigit, other.cellGivenDigit, t)!,
      cellUserDigit: Color.lerp(cellUserDigit, other.cellUserDigit, t)!,
      cellSameDigitFg: Color.lerp(cellSameDigitFg, other.cellSameDigitFg, t)!,
      boardLine: Color.lerp(boardLine, other.boardLine, t)!,
      boardLineThick: Color.lerp(boardLineThick, other.boardLineThick, t)!,
    );
  }

  static List<Color> _lerpList(List<Color> a, List<Color> b, double t) {
    final n = a.length < b.length ? a.length : b.length;
    return [for (var i = 0; i < n; i++) Color.lerp(a[i], b[i], t)!];
  }
}
