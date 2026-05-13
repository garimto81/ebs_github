// EBS Command Center typography — Inter + JetBrains Mono (OKLCH v4.3).
//
// SSOT: `docs/mockups/EBS Command Center/tokens.css` (`--font-ui`, `--font-mono`)
// Spec: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13.2
//
// Cycle 19 Wave 2 — Typography re-source.
//
// Fonts:
//   - UI: Inter (400 / 500 / 600 / 700 weights)
//   - Mono: JetBrains Mono (tabular-nums for stacks / pots / equity)
//
// The static `const TextStyle` fields below preserve compatibility with
// existing `const Text(... style: EbsTypography.toolbarTitle)` call sites.
// Font loading happens via `google_fonts` package — when `textTheme` is
// applied to the `MaterialApp` (via `EbsTheme.dark`), GoogleFonts.config
// resolves the `fontFamily` strings to downloaded font assets.
//
// Important: The `fontFamily: 'Inter'` strings below match the Google Fonts
// family identifier. When `EbsTypography.textTheme` is wired into the app's
// ThemeData (see `ebs_theme.dart`), every Text widget inherits the
// runtime-resolved Inter / JetBrains Mono font fallbacks.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EbsTypography {
  EbsTypography._();

  // ─── Font family identifiers (Google Fonts catalog names) ─────────
  static const String _ui = 'Inter';
  static const String _mono = 'JetBrains Mono';

  // ─── Widget-level text styles (compile-time const) ────────────────
  // Preserve existing call-site API — these are referenced as
  // `const Text(style: EbsTypography.foo)` across the codebase.

  /// Action button label — large, bold, slightly-spaced (BS-05-02).
  static const actionButton = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  /// Seat player name (BS-05-03).
  static const playerName = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Stack amount — mono, tabular-nums alignment (BS-05-03).
  static const stackAmount = TextStyle(
    fontFamily: _mono,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Pot display — largest numeric text (BS-05-03 status panel).
  static const potAmount = TextStyle(
    fontFamily: _mono,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Info bar — small, regular weight (blind level, hand number).
  static const infoBar = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Toolbar title — section heading (BS-05-01).
  static const toolbarTitle = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Card rank / suit label — heavy, large (UI-02 card cell).
  static const cardLabel = TextStyle(
    fontFamily: _ui,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  /// Modal title — dialog headers (BS-05-08, BS-05-09).
  static const modalTitle = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// Equity percentage — mono, tabular-nums (BS-07-01 overlay parity).
  static const equity = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Keyboard shortcut hint — small, low-emphasis.
  static const shortcutHint = TextStyle(
    fontFamily: _ui,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9E9E9E),
  );

  // ─── Material 3 TextTheme — applied via ThemeData ─────────────────
  // Runtime-resolved via google_fonts. Returns a TextTheme that inherits
  // Inter for prose and falls back to Inter for numerics; mono is opt-in
  // per-widget via `stackAmount` / `potAmount` / `equity`.

  /// Helper — build an Inter-based TextStyle with tabular-nums opt-out.
  static TextStyle _ui_(double size, FontWeight weight) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, height: 1.4);

  /// Material 3 TextTheme (Inter base, applied via ThemeData.textTheme).
  static TextTheme get textTheme => TextTheme(
        displayLarge: _ui_(48, FontWeight.w700),
        displayMedium: _ui_(36, FontWeight.w700),
        displaySmall: _ui_(28, FontWeight.w600),
        headlineLarge: _ui_(22, FontWeight.w600),
        headlineMedium: _ui_(18, FontWeight.w600),
        headlineSmall: _ui_(16, FontWeight.w600),
        titleLarge: _ui_(15, FontWeight.w600),
        titleMedium: _ui_(14, FontWeight.w500),
        titleSmall: _ui_(13, FontWeight.w500),
        bodyLarge: _ui_(14, FontWeight.w400),
        bodyMedium: _ui_(13, FontWeight.w400),
        bodySmall: _ui_(12, FontWeight.w400),
        labelLarge: _ui_(13, FontWeight.w500),
        labelMedium: _ui_(12, FontWeight.w500),
        labelSmall: _ui_(11, FontWeight.w500),
      );
}
