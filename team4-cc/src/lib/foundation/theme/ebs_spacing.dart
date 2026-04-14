// EBS Command Center spacing constants.
//
// 8px grid system. All layout dimensions derive from these values.
// Component sizes match BS-05 behavioral spec and UI-02 design.

class EbsSpacing {
  EbsSpacing._();

  // ── Base grid ──────────────────────────────────────────────────
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // ── Seat cell (BS-05-03) ───────────────────────────────────────
  static const seatCellWidth = 120.0;
  static const seatCellHeight = 80.0;

  // ── Action button (BS-05-02) ───────────────────────────────────
  static const actionButtonHeight = 56.0;
  static const actionButtonMinWidth = 80.0;

  // ── Card cell (UI-02: 60x72) ───────────────────────────────────
  static const cardCellWidth = 60.0;
  static const cardCellHeight = 72.0;

  // ── Modal widths ───────────────────────────────────────────────
  static const modalWidthSm = 480.0; // Player Edit (BS-05-09)
  static const modalWidthMd = 600.0; // Game Settings (BS-05-08)

  // ── Fixed-height bars ──────────────────────────────────────────
  static const infoBarHeight = 40.0;
  static const toolbarHeight = 48.0;
  static const actionPanelHeight = 120.0;
}
