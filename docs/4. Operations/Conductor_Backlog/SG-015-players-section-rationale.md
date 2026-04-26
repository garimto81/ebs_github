---
id: SG-015
title: "Lobby Players 섹션 유지 근거 미문서화"
type: spec_gap
sub_type: ia_missing
status: PENDING
owner: team1  # decision_owner
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃 (Players 섹션)
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §3
  - SG-012 (sibling)
---

# SG-015 — Lobby Players 섹션 유지 근거 미문서화

## 공백 서술

사용자 제안 5탭 (lobby/staff/settings/gfx/reports) 에 Players 섹션이 빠져 있으나, 현 SSOT (UI.md §공통 레이아웃) 에는 Players 가 독립 섹션으로 존재. 유지 근거가 어디에도 명문화되지 않아 "왜 5탭이 아닌가?" 질문에 답할 수 없다.

WSOP LIVE Confluence 의 Player Management 섹션 (원칙 1 정렬 대상) 과 매핑이 필요하다.

## 발견 경위

- 2026-04-21 사용자 5탭 제안 vs SSOT 대조 중 발견
- Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §3 의 "(빠짐) Players" 행

## 영향받는 챕터 / 구현

- `Lobby/UI.md §공통 레이아웃` line 412~414: `■ Players → Create Player / Player Verification` (구현 존재)
- `Lobby/Overview.md`: Players 섹션 정의 및 비즈니스 가치 미서술
- WSOP LIVE Confluence "Player Management" 페이지와 매핑 부재

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. Players 섹션 유지 + Lobby/Overview.md 에 비즈니스 가치 명시 | 원칙 1 정렬, 기존 구현 보존 | 5탭 제안과 다름 | ✅ Player Management 매핑 |
| 2. Players → Staff/Tournaments 흡수 | UI 단순화 | Player 가 Event 독립 엔티티인 점 위배 | ✗ 패턴 위반 |
| 3. Players 폐기 후 별도 앱으로 분리 | 책임 분리 | 진입점 혼란 ↑ | ✗ |

## 결정 (decision_owner team1 판정 시 기입)

- **default 권고**: 대안 1 (Players 섹션 유지 + 근거 명문화)
- 이유: WSOP LIVE Player Management 정렬 + 기존 구현 보존
- 영향: Lobby/Overview.md 에 Players 섹션 추가

## 후속 작업

- [ ] team1: Lobby/Overview.md `### Players` 섹션 신설 (Event 독립 엔티티 근거 + Create / Verification 흐름)
- [ ] team1: WSOP LIVE Player Management 페이지 매핑 cross-ref
- [ ] team1: 사용자 제안 5탭 → 5+1탭 (Players 추가) 정정 안내

## 관련 SG

- SG-012 — Lobby 사이드바 SSOT
