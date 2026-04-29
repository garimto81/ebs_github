// EBS Lobby ThemeData (Light + Dark).
//
// Both modes are anchored to `design_tokens.dart` so the operator console
// stays tonally consistent whether the room lights are on or off. Light is
// the primary mode in the design source (broadcast control room with daylight
// fall-through); Dark is the late-night / dim-room variant.
//
// Public entry points:
//   - [EbsLobbyTheme.lightTheme]  — primary (warm-neutral)
//   - [EbsLobbyTheme.darkTheme]   — dim-room variant
//
// App entry (`app.dart`) currently selects `darkTheme`; switching to light or
// adding a runtime toggle (Tweaks panel) is a B-090 follow-up.

import 'package:flutter/material.dart';

import 'design_tokens.dart';

class EbsLobbyTheme {
  EbsLobbyTheme._();

  // ── Public theme getters ───────────────────────────────────────

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        bg: DesignTokens.lightBg,
        bgAlt: DesignTokens.lightBgAlt,
        bgSunken: DesignTokens.lightBgSunken,
        line: DesignTokens.lightLine,
        lineSoft: DesignTokens.lightLineSoft,
        lineStrong: DesignTokens.lightLineStrong,
        ink: DesignTokens.lightInk,
        ink2: DesignTokens.lightInk2,
        ink3: DesignTokens.lightInk3,
        ink4: DesignTokens.lightInk4,
        featBg: DesignTokens.featBg,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        bg: DesignTokens.darkBg,
        bgAlt: DesignTokens.darkBgAlt,
        bgSunken: DesignTokens.darkBgSunken,
        line: DesignTokens.darkLine,
        lineSoft: DesignTokens.darkLineSoft,
        lineStrong: DesignTokens.darkLineStrong,
        ink: DesignTokens.darkInk,
        ink2: DesignTokens.darkInk2,
        ink3: DesignTokens.darkInk3,
        ink4: DesignTokens.darkInk4,
        featBg: DesignTokens.featBgDark,
      );

  // ── Public surface helpers (for consumers building chrome) ─────

  /// Surface used for sticky data-table headers / breadcrumb bar.
  static const surfaceDataTableHeader = DesignTokens.lightBgAlt;

  /// Surface used for hovered/selected data rows.
  static const surfaceDataTableHover = DesignTokens.lightBgAlt;

  /// Surface used for elevated cards (Series banner cards, modals).
  static const surfaceCard = DesignTokens.lightBg;

  /// Side-rail surfaces (always-dark in both themes).
  static const surfaceNavPanel = DesignTokens.railBg;

  // ── Internal builder ───────────────────────────────────────────

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color bgAlt,
    required Color bgSunken,
    required Color line,
    required Color lineSoft,
    required Color lineStrong,
    required Color ink,
    required Color ink2,
    required Color ink3,
    required Color ink4,
    required Color featBg,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary = ink itself — design source uses dark ink as the primary
      // button fill (`.btn.primary { background: var(--ink) }`).
      primary: ink,
      onPrimary: bg,
      // Secondary = featured-row gold ink.
      secondary: DesignTokens.featInk,
      onSecondary: bg,
      // Error = danger accent.
      error: DesignTokens.dangerBase,
      onError: bg,
      surface: bg,
      onSurface: ink,
      surfaceContainerHighest: bgAlt,
      surfaceContainer: bgSunken,
      outline: lineStrong,
      outlineVariant: lineSoft,
      // Tertiary = live-green for on-air callouts.
      tertiary: DesignTokens.liveBase,
      onTertiary: DesignTokens.liveInk,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      cardColor: bg,
      dividerColor: line,
      canvasColor: bg,

      // Default font family for all components — Inter (UI), see
      // `ebs_typography.dart` for monospace overrides on numerics.
      fontFamily: DesignTokens.fontFamilyUi,

      // ── AppBar ────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.railBg,
        foregroundColor: DesignTokens.railInk,
        elevation: 0,
        toolbarHeight: DesignChrome.topBarHeight,
        titleTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsTab,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.14 * DesignTokens.fsTab,
          color: DesignTokens.railInk,
        ),
      ),

      // ── Navigation rail (collapsible) ─────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: DesignTokens.railBg,
        selectedIconTheme: const IconThemeData(color: DesignTokens.railInk),
        unselectedIconTheme: const IconThemeData(color: DesignTokens.railInkDim),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          color: DesignTokens.railInk,
          fontSize: DesignTokens.fsTab,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          color: DesignTokens.railInkDim,
          fontSize: DesignTokens.fsTab,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: DesignTokens.liveBase.withValues(alpha: 0.15),
      ),

      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: DesignTokens.railBg,
      ),

      // ── Buttons ───────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: bg,
          minimumSize: const Size(64, 28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamilyUi,
            fontSize: DesignTokens.fsTab,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: bg,
          elevation: 0,
          minimumSize: const Size(64, 28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink2,
          backgroundColor: bg,
          side: BorderSide(color: lineStrong),
          minimumSize: const Size(64, 28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink2,
          minimumSize: const Size(48, 24),
        ),
      ),

      // ── Input fields ──────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          borderSide: BorderSide(color: lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          borderSide: BorderSide(color: lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignChrome.buttonBorderRadius),
          borderSide: BorderSide(color: ink, width: 1.5),
        ),
        labelStyle: TextStyle(color: ink4),
      ),

      // ── Data table ────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(bg),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.selected)) {
            return bgAlt;
          }
          return bg;
        }),
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 38,
        horizontalMargin: 16,
        columnSpacing: 16,
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08 * 10,
          color: ink4,
        ),
        dataTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsBase,
          fontWeight: FontWeight.w400,
          color: ink2,
        ),
      ),

      // ── Tabs ──────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: ink3,
        indicatorColor: ink,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsTab,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsTab,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Dialog / Modal ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignChrome.sheetBorderRadius),
          side: BorderSide(color: lineStrong),
        ),
        titleTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsTitle,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),

      // ── Chip (filter chips, badges) ───────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: bgSunken,
        selectedColor: featBg,
        labelStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02 * 10.5,
          color: ink2,
        ),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      ),

      // ── Tooltip ───────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(3),
        ),
        textStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 11,
          color: bg,
        ),
      ),

      // ── Switch ────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ink;
          }
          return ink4;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ink.withValues(alpha: 0.4);
          }
          return line;
        }),
      ),

      // ── Checkbox ──────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ink;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(bg),
        side: BorderSide(color: lineStrong, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: DesignTokens.fsBase,
          color: bg,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
