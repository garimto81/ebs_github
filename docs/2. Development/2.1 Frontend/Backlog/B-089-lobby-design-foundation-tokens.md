---
id: B-089
title: "Lobby Design — Foundation visual system 이식 (Phase 1)"
backlog-status: in-progress
created: 2026-04-29
updated: 2026-04-29
owner: team1
source: Anthropic Design API handoff (skI1cZio_-fe4N4Hgcr0Tw, EBS Lobby.html)
mirror: none
---

# B-089 — Lobby Design Phase 1: Foundation Visual System

## 배경

2026-04-29 사용자가 Anthropic Design API 핸드오프 번들 (`api.anthropic.com/v1/design/h/skI1cZio_-fe4N4Hgcr0Tw`) 의 EBS Lobby.html 디자인을 EBS team1-frontend 에 구현 요청.

번들 위치 (read-only 분석용): `.scratch/design-fetch/`

디자인 의도 (chat1.md 발췌):
- Broadcast operations console — Bloomberg-terminal 같은 dense, monochrome, data-forward
- Inter UI + JetBrains Mono numerics
- warm-neutral background (oklch 0.985 0.003 80) + deep ink + tonal scale
- 두 functional accents: live-green (oklch 0.66 0.16 145) + amber (oklch 0.78 0.14 75)
- 5-screen drilldown: Series → Events → Flights → Tables → Players

## 범위 — 본 PR 한정

Phase 1 은 **시각적 토대 (visual foundation)** 만 이식. 화면 구조는 그대로 유지.

| # | 변경 파일 | 종류 | 내용 |
|---|----------|------|------|
| 1 | `lib/foundation/theme/design_tokens.dart` | 신규 | oklch→sRGB 변환된 EBS Lobby color/density tokens (단일 SSOT) |
| 2 | `lib/foundation/theme/lobby_colors.dart` | 갱신 | Material MD 색상 → design tokens 기반 semantic 매핑 |
| 3 | `lib/foundation/theme/ebs_typography.dart` | 갱신 | Inter UI / JetBrains Mono numerics, 13px base, FontFeature.tabularFigures |
| 4 | `lib/foundation/theme/ebs_spacing.dart` | 갱신 | density tokens (compact 26 / default 32 / cozy 38) + page chrome 측정값 |
| 5 | `lib/foundation/theme/ebs_lobby_theme.dart` | 갱신 | Light theme 신규 + dark theme 톤 재조정 (warm-neutral 베이스) |
| 6 | `lib/foundation/widgets/lobby_top_bar.dart` | 신규 | 44px brand+cluster+CC pill+clock+user TopBar |
| 7 | `lib/foundation/widgets/lobby_side_rail.dart` | 신규 | 240/56px collapsible rail with section/item/badge |
| 8 | `lib/foundation/widgets/lobby_breadcrumb.dart` | 신규 | sticky breadcrumb bar with ⌘K hint |

라우터 / providers / 5-screen drilldown 은 Phase 2 (B-090) 분리.

## 참조

- 디자인 핸드오프 번들: `.scratch/design-fetch/` (read-only)
- 핵심 토큰 정의: `.scratch/design-fetch/project/styles.css` (`:root` 블록)
- 5-screen 컴포넌트 트리: `.scratch/design-fetch/project/screens.jsx` + `shell.jsx`
- 기존 Lobby chrome: `lib/features/lobby/screens/lobby_dashboard_screen.dart`

## 수락 기준

- [ ] `design_tokens.dart` 가 oklch 디자인 값 → sRGB 변환된 색을 단일 SSOT 로 노출
- [ ] `lobby_colors.dart` / `ebs_typography.dart` / `ebs_spacing.dart` / `ebs_lobby_theme.dart` 가 design_tokens 만 참조 (Material MD 직접 색 0건)
- [ ] `lobby_top_bar.dart` / `lobby_side_rail.dart` / `lobby_breadcrumb.dart` 가 디자인 레이아웃과 1:1 매칭 (44px / 240px / sticky)
- [ ] `flutter analyze` 0 error
- [ ] 기존 `lobby_dashboard_screen.dart` 빌드 깨지지 않음 (Phase 2 까지는 chrome 미적용 OK)

## Phase 2 후속 (B-090)

5-screen drilldown 재구조화. 별도 Backlog 등재.

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-04-29 | 최초 작성 (Phase 1 분리, design fetch 컨텍스트 기록) |
