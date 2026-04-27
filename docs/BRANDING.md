# HeffelHoff Sudoku — Branding Guidelines

The HeffelHoff brand is **neon-circuit cerebral** — a brain-shaped tangle of glowing wires inside a sleek dark frame, lit in cyan and electric blue with violet/magenta accents. It signals intelligence, precision, and a touch of arcade flair. Use it consistently across icons, splash, in-app surfaces, store listings, and marketing.

---

## 1. Logo assets

Two canonical logo files live in `assets/branding/`. Both are 1254×1254 PNG with sRGB color.

| File | Use for | Notes |
|---|---|---|
| `playstore_icon.png` | Android launcher icon, iOS app icon, Play Store / App Store listing icon, marketing thumbnails, any *square framed* context | Includes the dark navy backdrop, the swooping shield/blade frame, and the HH brain |
| `logo.png` | In-app branding (splash, headers), social cards on solid dark backgrounds, watermarks, favicons over dark surfaces | Transparent background, brain-only mark — no frame, no backdrop |

### Generation

Run after touching either source PNG:

```bash
dart run flutter_launcher_icons          # writes android/app/src/main/res/mipmap-*/ic_launcher.png + iOS AppIcon.appiconset
dart run flutter_native_splash:create     # writes the OS-level splash drawable + iOS LaunchImage
```

### Don'ts

- **Don't** crop the icon's frame — the curving shield is part of the mark.
- **Don't** apply additional drop shadows when the icon is over the deep-navy brand background — it already glows.
- **Don't** colorize Logo.png. The neon ramp inside the brain is fixed.
- **Don't** use the playstore icon over white or light backgrounds — it loses the glow effect. Use Logo.png on dark only; on light surfaces, fall back to a wordmark.
- **Don't** stretch — always preserve the 1:1 aspect ratio.

---

## 2. Color palette

All hex codes also live in `lib/core/theme/app_colors.dart` (`AppPalette.dark`) and the seed in `lib/core/theme/app_theme.dart`.

### Brand core (extracted from `playstore_icon.png`)

| Token | Hex | Role |
|---|---|---|
| Deep Navy | `#01072D` | App background, splash, board outer frame |
| Dark Navy | `#030D4E` | Surface (cards, sheets) |
| Mid Navy | `#05166F` | Elevated surface, header chips |
| Electric Blue | `#1948E0` | Secondary accent — peer wash on board, info |
| **Cyan Glow** | **`#36A8FA`** | **PRIMARY brand colour** — selected cell, focus ring, primary button, "%" headline number, brand wordmark gradient |
| Royal Violet | `#A35DF4` | Tertiary accent — HH letterform, achievement glow, IQ-genius gradient stop |
| Pale Ice | `#E4EDFC` | Foreground text on dark surfaces |

### Game state colors (cell hierarchy on the Sudoku board)

Picked for clear visual hierarchy. Priority on conflict: **wrong > selected > sameDigit > peer > base**.

| Token | Hex | When |
|---|---|---|
| `cellSurface` | `#0A1230` | Default cell (both empty and given) |
| `cellPeer` | `#152459` | Same row / column / 3×3 box as selected |
| `cellSameDigit` | `#1948E0` | Cell value matches the selected cell's value |
| `cellSelected` | `#36A8FA` | Currently focused cell |
| `cellSelectedFg` | `#01072D` | Digit color on `cellSelected` (dark on cyan for contrast) |
| `cellWrong` | `#4A1430` | Player just placed an incorrect digit |
| `cellWrongFg` | `#FFB0C4` | Digit color on `cellWrong` |
| `cellGivenDigit` | `#E4EDFC` | Original puzzle clues — bold, brightest white |
| `cellUserDigit` | `#36A8FA` | Player-placed correct digits |
| `boardLine` | `#1A2454` | Thin lines between adjacent cells |
| `boardLineThick` | `#36A8FA` | Lines between 3×3 boxes (cyan to echo brand) |

### Achievement & podium accents

Reserved for celebration moments. Don't use elsewhere.

| Token | Hex | Use |
|---|---|---|
| Gold gradient | `#FFD700` → `#FFA500` | #1 podium frame, "Beat Einstein" achievement, digit-complete overlay |
| Silver gradient | `#C0C0C0` → `#E5E4E2` | #2 podium |
| Bronze gradient | `#CD7F32` → `#B87333` | #3 podium |
| Life red | `#FF5470` | Lives heart icon (filled) |
| Life red faded | `#FF5470` @ 20% | Lives heart icon (lost) |

### Particle palette

Used by sparkle layers, confetti, and the persistent twinkling field around the IQ result and podium.

```
#36A8FA  Cyan glow
#A35DF4  Royal violet
#1948E0  Electric blue
#E4EDFC  Pale ice
#FFD700  Gold (achievement)
#FFFFFF  White
```

---

## 3. Typography

| Role | Family | Weight | Use |
|---|---|---|---|
| Display & numerals | **Outfit** | 700–900 | "SUDOKU" wordmark, big IQ number, Sudoku digit, podium IQs |
| UI labels & body | **Inter** | 400–600 | Buttons, body, list items |

Both pulled at runtime via `google_fonts` — no bundled .ttf needed for now. The `Outfit` numerals have generous, readable curves at small sizes (the 9×9 grid digits) and remain striking at 96pt+ (the IQ result).

### Tracking

- Wordmark "SUDOKU": **+8 letter-spacing**, weight 900
- Section labels (e.g. "HEFFELHOFF" above wordmark): **+4 letter-spacing**, weight 300–400, color `onSurfaceVariant`
- "COMPLETE" caption (digit-complete overlay): **+8 letter-spacing**, weight 800, gold gradient

---

## 4. Icon design principles

When designing in-app iconography (achievements, tier badges, custom Lottie):

1. **Stroke, don't fill.** The brand mark is line-art. Match it: thin neon strokes (1.5–2px at 24pt size) over dark surfaces, glow blur 4–8px.
2. **Cyan first, violet second, magenta as a highlight.** Don't introduce yellows/oranges except for achievement gold.
3. **Round corners (14–24px) on cards**, fully rounded (999px) on chips.
4. **Glow over shadow.** On the dark theme, depth comes from emissive halos (`BoxShadow` with the accent color at 20–45% alpha and a 16–24px blur), not drop-shadows.
5. **No skeuomorphism.** No bevels, no embossed text, no faux-leather. The brain mark is the only "physical" object; everything else is flat with light.
6. **Adaptive icon safe zone** = central 264×264 of the 432×432 canvas. The playstore icon's brain-shield core is centered and fits.

---

## 5. Animation principles

The brand reads as *animated by default*. Static is a fallback, not a goal.

- **Neon pulse**: a 1.2–2.4s sine bob on opacity (0.7 → 1.0 → 0.7) for any element meant to feel "alive" — the HH logo on splash, podium #1.
- **Particle twinkle**: subtle sparkle layer (60 particles, sin-wave drift, alpha twinkle) behind hero numbers. Color from the particle palette.
- **Count-up**: numbers (IQ score, leaderboard score) tween from 0 to value over 1.0–1.4s with `Curves.easeOutCubic`.
- **Slide + fade entries**: list items slide 10% from the right and fade in, staggered by 80ms per row.
- **Elastic appear**: hero elements (logo on splash, achievement card) scale 0.6 → 1.0 over 500ms with `Curves.elasticOut`.
- **Confetti** for milestone moments only (puzzle solve, digit complete, achievement unlock). Don't spam it for routine actions.
- **Haptics complement visual celebrations.** Light on cell select, medium on placement, heavy on wrong entry, success pattern (heavy → 120ms → medium) on a wow moment.

---

## 6. Voice & tone

- **Confident, not boastful.** "You beat Einstein by 6 IQ!" not "OMG amazing job!!1"
- **Concise.** Status lines under 8 words: "Pending sync", "Streak 4", "Just 3 points away from Einstein."
- **Numbers are heroes.** Display them big, in Outfit, in cyan or gold.
- **No emoji in product copy** (UI strings, in-game text). They're fine in marketing channels.

---

## 7. Quick-reference Dart constants

```dart
// AppTheme (lib/core/theme/app_theme.dart)
AppTheme.seedDefault     == Color(0xFF36A8FA)   // cyan glow — primary
AppTheme.brandBackground == Color(0xFF01072D)   // deep navy

// AppPalette.dark (lib/core/theme/app_colors.dart)
palette.cellSelected     == Color(0xFF36A8FA)
palette.cellSameDigit    == Color(0xFF1948E0)
palette.cellPeer         == Color(0xFF152459)
palette.iqGenius         == [0xFF36A8FA, 0xFFA35DF4, 0xFFE4EDFC]
palette.particleTints    == [..6 colors..]
```

When in doubt, **read from the palette extension, not the ColorScheme** for any cell-state or game-celebration colour. The ColorScheme handles button/chrome/snackbar tokens; AppPalette handles the gameplay surface.
