// EBS Command Center dark theme.
//
// Optimized for broadcast environments (6+ hour continuous operation).
// Material 3 dark theme with custom color scheme for poker table aesthetics.

import 'package:flutter/material.dart';

class EbsTheme {
  EbsTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF1E88E5), // Blue 600 — primary actions
      secondary: Color(0xFFFDD835), // Yellow 600 — emphasis/dealer
      error: Color(0xFFE53935), // Red 600 — error/fold
      surface: Color(0xFF1A1A2E), // Dark navy — card table feel
      onSurface: Color(0xFFE0E0E0), // Light gray text
    );

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      cardColor: colorScheme.surface,
      dividerColor: const Color(0xFF2A2A40),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(80, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A40),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
