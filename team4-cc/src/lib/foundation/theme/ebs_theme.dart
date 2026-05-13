// EBS Command Center theme — Broadcast Dark Amber OKLCH (v4.3).
//
// Optimized for broadcast environments (12-hour continuous operation).
// Reference: docs/mockups/EBS Command Center/tokens.css (HTML SSOT).
// Spec: docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §13
// PRD: docs/1. Product/Command_Center.md v4.3 Ch.11.5.
//
// Cycle 19 Wave 2 — Token Layer adoption. Previous Material 3 default
// scheme (blue/yellow/red) replaced by OKLCH amber/charcoal palette.

import 'package:flutter/material.dart';

import 'ebs_oklch.dart';
import 'ebs_typography.dart';

class EbsTheme {
  EbsTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: EbsOklch.accent, // broadcast amber
      onPrimary: EbsOklch.fg0,
      secondary: EbsOklch.accentStrong, // amber emphasis
      onSecondary: EbsOklch.fg0,
      error: EbsOklch.err,
      onError: EbsOklch.fg0,
      surface: EbsOklch.bg2, // cards, seats, controls
      onSurface: EbsOklch.fg0,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: EbsOklch.bg0,
      canvasColor: EbsOklch.bg1,
      cardColor: EbsOklch.bg2,
      dividerColor: EbsOklch.line,
      textTheme: EbsTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: EbsOklch.bg1,
        foregroundColor: EbsOklch.fg0,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EbsOklch.accent,
          foregroundColor: EbsOklch.fg0,
          minimumSize: const Size(80, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EbsOklch.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: EbsOklch.bg3,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: EbsOklch.fg0),
      ),
    );
  }
}
