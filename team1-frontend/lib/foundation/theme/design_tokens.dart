// EBS Lobby — design tokens (single SSOT).
//
// Origin: Anthropic Design API handoff `skI1cZio_-fe4N4Hgcr0Tw` / `EBS Lobby.html`
// Bundle (read-only analysis copy): `.scratch/design-fetch/project/styles.css`
//
// Aesthetic: Bloomberg-terminal broadcast operations console.
// Warm-neutral background (oklch ~80° hue), deep ink foreground, single tonal scale,
// two functional accents (live-green / amber) tied to the same chroma 0.13–0.16.
//
// All values originate as `oklch(L C H)` in the design source. Flutter's [Color]
// only takes sRGB integers, so the values below are oklch→sRGB conversions
// performed once and pinned. Hue (warmth) and relative chroma are preserved;
// out-of-gamut hues (e.g. high-chroma greens) are clipped to the nearest sRGB
// representation. The chat transcript that produced the design is intact at
// `.scratch/design-fetch/chats/chat1.md`.

import 'package:flutter/material.dart';

/// Density preset — toggles row height and horizontal padding for the dense
/// data tables across Series / Events / Flights / Tables / Players screens.
///
/// Default mirrors `:root { --row-h: 32px; --pad-x: 16px; }` from styles.css.
enum LobbyDensity {
  compact, // --row-h: 26px, --pad-x: 12px
  standard, // --row-h: 32px, --pad-x: 16px
  cozy, // --row-h: 38px, --pad-x: 20px
}

extension LobbyDensityX on LobbyDensity {
  double get rowHeight {
    switch (this) {
      case LobbyDensity.compact:
        return 26.0;
      case LobbyDensity.standard:
        return 32.0;
      case LobbyDensity.cozy:
        return 38.0;
    }
  }

  double get cellPadX {
    switch (this) {
      case LobbyDensity.compact:
        return 12.0;
      case LobbyDensity.standard:
        return 16.0;
      case LobbyDensity.cozy:
        return 20.0;
    }
  }
}

/// Light + Dark warm-neutral palette + functional accents.
///
/// Field naming mirrors the CSS custom-property names so that the design
/// source can be cross-referenced 1:1.
class DesignTokens {
  DesignTokens._();

  // ── Light theme — warm-neutral surfaces ────────────────────────
  // oklch(0.985 0.003 80) → ~#FBFAF7 (slightly warm white)
  static const lightBg = Color(0xFFFBFAF7);
  // oklch(0.965 0.004 80)
  static const lightBgAlt = Color(0xFFF4F1EC);
  // oklch(0.945 0.005 80)
  static const lightBgSunken = Color(0xFFEDE9E3);
  // oklch(0.90 0.005 80)
  static const lightLine = Color(0xFFDEDAD3);
  // oklch(0.94 0.004 80)
  static const lightLineSoft = Color(0xFFEBE7E1);
  // oklch(0.78 0.006 80)
  static const lightLineStrong = Color(0xFFBCB7B0);

  // ── Light theme — ink (foreground) tonal scale ─────────────────
  // oklch(0.18 0.01 80) → near-black warm ink
  static const lightInk = Color(0xFF25221C);
  // oklch(0.32 0.008 80)
  static const lightInk2 = Color(0xFF423F38);
  // oklch(0.50 0.006 80)
  static const lightInk3 = Color(0xFF706C66);
  // oklch(0.65 0.005 80)
  static const lightInk4 = Color(0xFF9C9892);
  // oklch(0.78 0.004 80)
  static const lightInk5 = Color(0xFFBCB8B2);

  // ── Dark theme — surfaces ──────────────────────────────────────
  // oklch(0.16 0.005 80)
  static const darkBg = Color(0xFF1F1D17);
  // oklch(0.20 0.006 80)
  static const darkBgAlt = Color(0xFF29261F);
  // oklch(0.13 0.005 80)
  static const darkBgSunken = Color(0xFF1A1812);
  // oklch(0.30 0.006 80)
  static const darkLine = Color(0xFF3F3C35);
  // oklch(0.24 0.005 80)
  static const darkLineSoft = Color(0xFF322E28);
  // oklch(0.42 0.008 80)
  static const darkLineStrong = Color(0xFF5C584F);

  // ── Dark theme — ink ───────────────────────────────────────────
  // oklch(0.95 0.004 80)
  static const darkInk = Color(0xFFEFECE6);
  // oklch(0.82 0.005 80)
  static const darkInk2 = Color(0xFFC7C2BC);
  // oklch(0.65 0.005 80)
  static const darkInk3 = Color(0xFF9C9892);
  // oklch(0.50 0.005 80)
  static const darkInk4 = Color(0xFF706C66);
  // oklch(0.38 0.005 80)
  static const darkInk5 = Color(0xFF54514B);

  // ── Rail (always-dark, used in both themes) ────────────────────
  // oklch(0.16 0.01 80)
  static const railBg = Color(0xFF211E18);
  // oklch(0.95 0.004 80)
  static const railInk = Color(0xFFEFECE6);
  // oklch(0.62 0.005 80)
  static const railInkDim = Color(0xFF948F89);
  // oklch(0.26 0.008 80)
  static const railLine = Color(0xFF38342D);
  // oklch(0.20 0.006 80) — hover/active row
  static const railHover = Color(0xFF29261F);
  // oklch(0.10 0.005 80) — collapsed/foot
  static const railSunken = Color(0xFF15130E);

  // ── Functional accents — live (broadcast on-air) ───────────────
  // oklch(0.66 0.16 145) — chroma 0.16 mid green
  static const liveBase = Color(0xFF28A867);
  // oklch(0.94 0.04 145)
  static const liveBg = Color(0xFFDBEFE0);
  // oklch(0.34 0.10 145)
  static const liveInk = Color(0xFF225338);

  // ── Functional accents — warn (registering / waiting) ──────────
  // oklch(0.78 0.14 75)
  static const warnBase = Color(0xFFDBA34D);
  // oklch(0.95 0.05 75)
  static const warnBg = Color(0xFFF2E1C2);
  // oklch(0.42 0.09 75)
  static const warnInk = Color(0xFF7B5A22);

  // ── Functional accents — danger (error / RFID failure) ─────────
  // oklch(0.60 0.18 28)
  static const dangerBase = Color(0xFFC5462C);
  // oklch(0.94 0.04 28)
  static const dangerBg = Color(0xFFF2DED5);
  // oklch(0.42 0.13 28)
  static const dangerInk = Color(0xFF7E3725);

  // ── Functional accents — info (announced) ──────────────────────
  // oklch(0.58 0.13 250)
  static const infoBase = Color(0xFF4F71BC);
  // oklch(0.94 0.04 250)
  static const infoBg = Color(0xFFDBE0EC);
  // oklch(0.38 0.10 250)
  static const infoInk = Color(0xFF3D4A78);

  // ── Featured row tint (gold) ───────────────────────────────────
  // oklch(0.97 0.04 95)
  static const featBg = Color(0xFFF1ECCC);
  // oklch(0.50 0.10 80)
  static const featInk = Color(0xFF7C6920);
  // oklch(0.24 0.05 80) — dark-theme variant of featBg
  static const featBgDark = Color(0xFF392E16);

  // ── Sheet / modal backdrop ─────────────────────────────────────
  // oklch(0.10 0.01 80 / 0.42)
  static const sheetScrim = Color(0x6B181712);

  // ── Typography families ────────────────────────────────────────
  //
  // Inter for UI body / labels, JetBrains Mono for numerics, IDs, timecodes.
  // The strings here match the family names registered in `pubspec.yaml`
  // (or fall through to system sans / mono until the fonts are bundled
  // via `google_fonts` or asset declaration — see B-090 for the follow-up).
  static const fontFamilyUi = 'Inter';
  static const fontFamilyMono = 'JetBrainsMono';

  // ── Type scale (px → logical) ──────────────────────────────────
  //
  // Mirrors styles.css `body { font-size: 13px }` baseline. All values are
  // in logical pixels (Flutter's coordinate system).
  static const fsBase = 13.0; // body
  static const fsSmall = 11.0; // toolbars, secondary
  static const fsXs = 10.0; // labels, status-strip
  static const fsLabel = 10.5; // form labels (uppercase, tracked)
  static const fsTab = 12.0; // tab title
  static const fsKpiLabel = 10.0; // KPI label cap
  static const fsKpiValue = 18.0; // KPI numeric value
  static const fsTitle = 14.0; // sheet/card title
  static const fsScreenH = 18.0; // login/auth headline
  static const fsLevelClock = 22.0; // levels-strip countdown
}

/// Density-related layout constants (chrome heights) — see styles.css.
class DesignChrome {
  DesignChrome._();

  static const topBarHeight = 44.0;
  // HTML mockup: `.bc-bar { padding: 6px 16px }` → ~28px total height
  static const breadcrumbHeight = 28.0;
  static const railWidthExpanded = 240.0;
  static const railWidthCollapsed = 56.0;
  static const railItemPadX = 14.0;
  static const railItemPadY = 8.0;

  // HTML mockup: summary bar padding: 6px 16px
  static const kpiPadX = 16.0;
  static const kpiPadY = 6.0;
  static const kpiMinWidth = 80.0;

  // HTML mockup: cards have NO border-radius (border: 1px solid #e0e0e0)
  static const cardBorderRadius = 0.0;
  static const buttonBorderRadius = 4.0;
  static const sheetBorderRadius = 8.0;

  // Series card grid: HTML `gap: 8px`, banner `height: 52px`
  static const cardGridGap = 8.0;
  static const cardGridMin = 260.0;
  static const cardBannerHeight = 52.0;

  // Waitlist drawer
  static const waitlistWidth = 240.0;
}
