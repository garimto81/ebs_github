// EBS Lobby typography scale.
//
// Aligned with the Anthropic Design API handoff (`EBS Lobby.html` / styles.css):
// Inter for UI text, JetBrains Mono for numerics / IDs / timecodes / blinds.
// 13px base mirrors `body { font-size: 13px }` from the design source.
//
// Tabular figures (`tnum`) is enabled on monospace styles so chip stacks,
// timestamps, and blind levels align column-wise. Until `google_fonts` (or a
// bundled .ttf asset) is wired up via B-090, the families fall back to the
// platform default sans / mono — but the FontFeature settings still apply
// to whatever family resolves.

import 'package:flutter/material.dart';

import 'design_tokens.dart';

class EbsTypography {
  EbsTypography._();

  // Tabular figures — keeps numeric columns aligned (KPI strip, blinds, IDs).
  static const _tabular = [FontFeature.tabularFigures()];

  // ── Page titles (Lobby sections) ───────────────────────────────
  static const pageTitle = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.005 * 18, // mirror -0.005em on .scard-name
  );

  // ── Section headers ────────────────────────────────────────────
  static const sectionHeader = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTitle,
    fontWeight: FontWeight.w600,
  );

  // ── Toolbar / AppBar title ─────────────────────────────────────
  static const toolbarTitle = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTitle,
    fontWeight: FontWeight.w600,
  );

  // ── Data table header ──────────────────────────────────────────
  // 10px uppercase tracked label — mirrors `.dtable th`.
  static const tableHeader = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.08 * 10,
    color: DesignTokens.lightInk4,
  );

  // ── Data table cell ────────────────────────────────────────────
  static const tableCell = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsBase,
    fontWeight: FontWeight.w400,
  );

  // ── Numeric values in tables (monospace for digit alignment) ───
  static const tableNumeric = TextStyle(
    fontFamily: DesignTokens.fontFamilyMono,
    fontSize: DesignTokens.fsBase,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  // ── Body text ──────────────────────────────────────────────────
  static const body = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsBase,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Form label (uppercase tracked) ─────────────────────────────
  static const formLabel = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsLabel,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.10 * DesignTokens.fsLabel,
    color: DesignTokens.lightInk4,
  );

  // ── Form input ─────────────────────────────────────────────────
  static const formInput = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsBase,
    fontWeight: FontWeight.w400,
  );

  // ── Navigation rail item ───────────────────────────────────────
  static const navItem = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTab,
    fontWeight: FontWeight.w500,
  );

  // ── Status badge (capitalized small caps) ──────────────────────
  static const statusBadge = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02 * 10.5,
  );

  // ── Caption / hint text ────────────────────────────────────────
  static const caption = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsSmall,
    fontWeight: FontWeight.w400,
    color: DesignTokens.lightInk3,
  );

  // ── Modal / sheet title ────────────────────────────────────────
  static const modalTitle = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTitle,
    fontWeight: FontWeight.w600,
  );

  // ── Tab label ──────────────────────────────────────────────────
  static const tabLabel = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTab,
    fontWeight: FontWeight.w600,
  );

  // ── Pot / stack amount (large mono) ────────────────────────────
  static const amountLarge = TextStyle(
    fontFamily: DesignTokens.fontFamilyMono,
    fontSize: DesignTokens.fsKpiValue,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * DesignTokens.fsKpiValue,
    fontFeatures: _tabular,
  );

  // ── Small monospace (hand #, seat #, deck count) ───────────────
  static const monoSmall = TextStyle(
    fontFamily: DesignTokens.fontFamilyMono,
    fontSize: DesignTokens.fsBase,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  // ── KPI label (uppercase tracked, tiny) ────────────────────────
  static const kpiLabel = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsKpiLabel,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10 * DesignTokens.fsKpiLabel,
    color: DesignTokens.lightInk4,
  );

  // ── KPI value (large numeric) ──────────────────────────────────
  static const kpiValue = TextStyle(
    fontFamily: DesignTokens.fontFamilyMono,
    fontSize: DesignTokens.fsKpiValue,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * DesignTokens.fsKpiValue,
    fontFeatures: _tabular,
  );

  // ── Levels strip countdown clock ───────────────────────────────
  static const levelClock = TextStyle(
    fontFamily: DesignTokens.fontFamilyMono,
    fontSize: DesignTokens.fsLevelClock,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.04 * DesignTokens.fsLevelClock,
    fontFeatures: _tabular,
  );

  // ── Year band caption (UPPERCASE tracked) — Series screen ──────
  static const yearBand = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsSmall,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.16 * DesignTokens.fsSmall,
    color: DesignTokens.lightInk4,
  );

  // ── Brand mark wordmark — uppercase tracked ────────────────────
  static const brandMark = TextStyle(
    fontFamily: DesignTokens.fontFamilyUi,
    fontSize: DesignTokens.fsTab,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14 * DesignTokens.fsTab,
  );
}
