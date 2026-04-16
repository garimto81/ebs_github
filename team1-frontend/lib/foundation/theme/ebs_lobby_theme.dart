// EBS Lobby dark theme.
//
// Adapted from team4 EbsTheme for desktop web (Lobby + Settings).
// Material 3 dark theme with Lobby-specific surface variants for
// data tables, settings forms, and navigation panels.

import 'package:flutter/material.dart';

class EbsLobbyTheme {
  EbsLobbyTheme._();

  // ── Lobby-specific surface variants ────────────────────────────
  static const surfaceDataTable = Color(0xFF161626); // Slightly darker for table rows
  static const surfaceDataTableHeader = Color(0xFF1E1E34); // Table header background
  static const surfaceSettingsForm = Color(0xFF1A1A2E); // Form panels
  static const surfaceNavPanel = Color(0xFF12121F); // Side navigation
  static const surfaceCard = Color(0xFF1E1E32); // Elevated cards
  static const surfaceDialog = Color(0xFF1E1E34); // Dialogs/modals

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF1E88E5), // Blue 600 — primary actions
      secondary: Color(0xFFFDD835), // Yellow 600 — emphasis/dealer
      error: Color(0xFFE53935), // Red 600 — error
      surface: Color(0xFF1A1A2E), // Dark navy — card table feel
      onSurface: Color(0xFFE0E0E0), // Light gray text
    );

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      cardColor: surfaceCard,
      dividerColor: const Color(0xFF2A2A40),

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),

      // ── Navigation rail / drawer ───────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceNavPanel,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF9E9E9E)),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
      ),

      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: surfaceNavPanel,
      ),

      // ── Buttons ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, 40),
        ),
      ),

      // ── Input fields ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16162A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Data table ─────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceDataTableHeader),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF1E1E36);
          }
          return surfaceDataTable;
        }),
        dividerThickness: 1,
        headingTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB0B0B0),
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
      ),

      // ── Tabs (Settings 6-tab) ──────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── Dialog / Modal ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Chip (filter chips, tags) ──────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A40),
        selectedColor: colorScheme.primary.withValues(alpha: 0.25),
        labelStyle: const TextStyle(fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Tooltip ────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A40),
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Switch / Checkbox (settings toggles) ───────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return const Color(0xFF9E9E9E);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.4);
          }
          return const Color(0xFF2A2A40);
        }),
      ),

      // ── SnackBar (save confirmations) ──────────────────────────
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2A40),
        contentTextStyle: TextStyle(color: Color(0xFFE0E0E0)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
