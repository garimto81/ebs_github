// EBS Lobby HTML mockup tokens (별도 layer, 2026-05-12 cycle 11).
//
// SSOT: docs/mockups/ebs-lobby-{00-login,01-series,02-events,03-flights,04-tables}.html
//
// 기존 design_tokens.dart 의 Bloomberg-style oklch warm-neutral palette 와는
// 별개의 "mockup 정합 전용" tokens. mockup CSS 의 정확한 hex 값을 그대로 옮김.
//
// 사용 원칙: mockup 정합이 필요한 5 화면 chrome (header / breadcrumb / badges /
// table rows / status dots) 에만 사용. design_tokens 와 혼용 가능하나 mockup
// 출처 hex 는 본 파일에서 단일 SSOT.

import 'package:flutter/material.dart';

class LobbyMockupTokens {
  LobbyMockupTokens._();

  // ── Surfaces ─────────────────────────────────────────────────
  /// dark header background (`.hdr { background: #1a1a1a }`)
  static const headerBg = Color(0xFF1A1A1A);
  static const headerInk = Color(0xFFFFFFFF);
  static const headerUserInk = Color(0xFF999999);
  static const headerCcBg = Color(0xFF333333);

  /// body background (`body { background: #fff }`)
  static const bg = Color(0xFFFFFFFF);
  static const bgAlt = Color(0xFFFAFAFA); // hover / ebs col tint

  // ── Lines (3 단계) ───────────────────────────────────────────
  static const line = Color(0xFFE0E0E0); // card / login-box border
  static const lineLight = Color(0xFFEEEEEE); // section divider
  static const lineLightest = Color(0xFFF0F0F0); // table row divider
  static const lineEbs = Color(0xFFF5F5F5); // ebs-col header bg
  static const lineDeep = Color(0xFFDDDDDD); // table th bottom border

  // ── Inks ─────────────────────────────────────────────────────
  static const ink = Color(0xFF111111); // body / strong text
  static const inkSecondary = Color(0xFF555555); // links
  static const inkMuted = Color(0xFF666666); // labels (forgot link)
  static const inkSubdued = Color(0xFF888888); // breadcrumb / hint
  static const inkDim = Color(0xFF999999); // section-title / count
  static const inkPlaceholder = Color(0xFFAAAAAA);
  static const inkSoft = Color(0xFFBBBBBB);
  static const inkSofter = Color(0xFFCCCCCC);

  // ── Action buttons (mockup CSS hex) ─────────────────────────
  static const btnPrimary = Color(0xFF1A1A1A); // login button (black)
  static const btnPrimaryInk = Color(0xFFFFFFFF);
  static const btnNew = Color(0xFF28A745); // green action
  static const btnNewInk = Color(0xFFFFFFFF);
  static const btnDanger = Color(0xFFDC3545);
  static const btnEntraIcon = Color(0xFF0078D4);

  // ── Status badges (.b-* in mockup CSS) ──────────────────────
  static const badgeCreatedBg = Color(0xFFF0F0F0);
  static const badgeCreatedInk = Color(0xFF666666);
  static const badgeAnnouncedBg = Color(0xFFCCE5FF);
  static const badgeAnnouncedInk = Color(0xFF004085);
  static const badgeRegisteringBg = Color(0xFFFFF3CD);
  static const badgeRegisteringInk = Color(0xFF856404);
  static const badgeRunningBg = Color(0xFFD4EDDA);
  static const badgeRunningInk = Color(0xFF155724);
  static const badgeCompletedBg = Color(0xFFF0F0F0);
  static const badgeCompletedInk = Color(0xFF666666);

  // ── Seat states (.seat.s-* in mockup CSS) ───────────────────
  static const seatActiveBg = Color(0xFFC3E6CB);
  static const seatActiveInk = Color(0xFF155724);
  static const seatEmptyBg = Color(0xFFF0F0F0);
  static const seatEmptyInk = Color(0xFFBBBBBB);
  static const seatEliminatedBg = Color(0xFFF5C6CB);
  static const seatEliminatedInk = Color(0xFF721C24);
  static const seatDealerBg = Color(0xFFD6D8DB);
  static const seatDealerInk = Color(0xFF383D41);
  static const seatWaitingBg = Color(0xFFFFF3CD);
  static const seatWaitingInk = Color(0xFF856404);

  // ── EBS-specific columns highlight ──────────────────────────
  static const ebsColBg = Color(0xFFFAFAFA);
  static const ebsHeaderBg = Color(0xFFF5F5F5);
  static const ebsHeaderInk = Color(0xFFB8860B); // dark gold

  // ── Featured row (gold tint) ────────────────────────────────
  static const featBg = Color(0xFFFFFEF5);
  static const featBgHover = Color(0xFFFFFDE0);
  static const featInk = Color(0xFFB8860B);

  // ── CC pill colors ──────────────────────────────────────────
  static const ccLive = Color(0xFF28A745);
  static const ccIdle = Color(0xFF999999);
  static const ccErr = Color(0xFFDC3545);

  // ── Status dots (1 px diameter dots) ────────────────────────
  static const dotGreen = Color(0xFF28A745);
  static const dotYellow = Color(0xFFFFC107);
  static const dotRed = Color(0xFFDC3545);
  static const dotGray = Color(0xFFCCCCCC);

  // ── Level box backgrounds (Tables screen) ───────────────────
  static const levelActive = Color(0xFFDC3545);
  static const levelNext = Color(0xFF28A745);
  static const levelFuture = Color(0xFF007BFF);

  // ── Type sizes (mockup CSS px → logical) ────────────────────
  /// 11px body — mockup `body { font-size: 11px }`
  static const fsBase = 11.0;
  static const fsSmall = 10.0;
  static const fsXs = 9.0;
  static const fsLabel = 8.0;
  static const fsTitle = 18.0; // login title
  static const fsHeader = 10.0; // top bar text
  static const fsHeaderLogo = 11.0; // EBS LOBBY label
  static const fsCardName = 10.0;
  static const fsCardMeta = 9.0;
  static const fsTabActive = 10.0;
  static const fsBigCount = 12.0;

  // ── Letter-spacing (mockup tracking) ────────────────────────
  static const letterSpacingHeader = 1.0;
  static const letterSpacingLabel = 0.8;
  static const letterSpacingBtn = 0.5;

  // ── Font families (mockup CSS) ──────────────────────────────
  // Mockup CSS: 'Suisse Intl', 'Helvetica Neue', sans-serif
  // Flutter: 시스템 sans-serif fallback (Inter 도 호환). Suisse Intl 가
  // 번들되어 있지 않으므로 default sans-serif 로 fallback (mockup 의도와
  // 시각적으로 ~85% 일치).
  static const fontFamilyPrimary = 'HelveticaNeue';
  static const fontFamilyMono = 'JetBrainsMono';
}
