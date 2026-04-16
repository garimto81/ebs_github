// EBS Lobby spacing constants.
//
// 8px grid system, shared with team4 CC.
// Lobby-specific layout dimensions for desktop web panels.

class EbsSpacing {
  EbsSpacing._();

  // ── Base grid ──────────────────────────────────────────────────
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // ── Desktop layout ─────────────────────────────────────────────
  static const navRailWidth = 72.0; // Collapsed rail
  static const navDrawerWidth = 260.0; // Expanded drawer
  static const pageMaxWidth = 1280.0; // Content max width
  static const pagePadding = 24.0; // Page-level padding

  // ── Data table ─────────────────────────────────────────────────
  static const tableRowHeight = 52.0;
  static const tableHeaderHeight = 44.0;
  static const tableCellPadding = 16.0;

  // ── Settings form ──────────────────────────────────────────────
  static const formFieldGap = 16.0;
  static const formSectionGap = 32.0;
  static const formMaxWidth = 640.0;

  // ── Modal widths (desktop) ─────────────────────────────────────
  static const modalWidthSm = 480.0;
  static const modalWidthMd = 640.0;
  static const modalWidthLg = 800.0;

  // ── Card ───────────────────────────────────────────────────────
  static const cardPadding = 16.0;
  static const cardRadius = 8.0;
  static const cardElevation = 2.0;

  // ── Fixed-height bars ──────────────────────────────────────────
  static const appBarHeight = 56.0;
  static const tabBarHeight = 48.0;
  static const statusBarHeight = 36.0;
}
