// EBS Lobby spacing constants.
//
// 8-px grid for general layout, density-driven row heights for the dense data
// tables (Series / Events / Flights / Tables / Players). Density tokens are
// available via [LobbyDensityX.rowHeight] / [LobbyDensityX.cellPadX] in
// `design_tokens.dart`.
//
// Page chrome dimensions (TopBar / Rail / Breadcrumb / Waitlist) live in
// [DesignChrome] in `design_tokens.dart`.

import 'design_tokens.dart';

class EbsSpacing {
  EbsSpacing._();

  // ── Base 8-px grid ─────────────────────────────────────────────
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // ── Desktop layout (chrome) ────────────────────────────────────
  // Re-exported from DesignChrome so existing call sites keep working.
  static const navRailWidth = DesignChrome.railWidthCollapsed; // 56
  static const navDrawerWidth = DesignChrome.railWidthExpanded; // 240
  static const pageMaxWidth = 1280.0;
  static const pagePadding = 20.0; // mirrors `.bc-bar { padding: 10px 20px }`

  static const appBarHeight = DesignChrome.topBarHeight; // 44
  static const tabBarHeight = 40.0; // mirrors `.tab { padding: 10px 14px }`
  static const statusBarHeight = DesignChrome.breadcrumbHeight; // 44
  static const waitlistWidth = DesignChrome.waitlistWidth; // 240

  // ── Data table — density driven ────────────────────────────────
  //
  // Default row height (32px) mirrors `:root { --row-h: 32px }`. Use
  // [LobbyDensity] from `design_tokens.dart` to switch to compact (26) or
  // cozy (38) at runtime.
  static const tableRowHeight = 32.0;
  static const tableHeaderHeight = 36.0; // sticky `.dtable th` row
  static const tableCellPadding = 16.0;
  static const tableCellPaddingCompact = 12.0;
  static const tableCellPaddingCozy = 20.0;

  // ── Settings form ──────────────────────────────────────────────
  static const formFieldGap = 12.0;
  static const formSectionGap = 24.0;
  static const formMaxWidth = 640.0;

  // ── Modal / sheet widths ───────────────────────────────────────
  // .sheet { width: 480px } in styles.css.
  static const modalWidthSm = 480.0;
  static const modalWidthMd = 640.0;
  static const modalWidthLg = 800.0;

  // ── Card (Series banner cards) ─────────────────────────────────
  static const cardPadding = 14.0; // mirrors `.scard-body`
  static const cardRadius = DesignChrome.cardBorderRadius; // 6
  static const cardElevation = 0.0; // flat, border-only

  // ── KPI strip ──────────────────────────────────────────────────
  static const kpiPadX = DesignChrome.kpiPadX; // 24
  static const kpiPadY = DesignChrome.kpiPadY; // 14
  static const kpiMinWidth = DesignChrome.kpiMinWidth; // 130
}
