---
id: SG-016
title: "Hand History 사이드바 섹션 공식화 (25개 분산 참조 통합)"
type: spec_gap
sub_type: ia_missing
status: PENDING
owner: team1  # decision_owner
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md
  - docs/2. Development/2.2 Backend/Database/Schema.md (hands / hand_actions)
  - docs/2. Development/2.5 Shared/Authentication.md (HandStarted event)
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §7.1-7.2
  - docs/4. Operations/Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md
  - SG-012 (sibling)
---

# SG-016 — Hand History 사이드바 섹션 공식화

## 공백 서술

EBS 고유 기능 "Hand History" 가 `hands` 테이블, `hand_actions` 테이블, `HandStarted` event, mockup 등 **25개 분산 참조** 로만 존재. 사용자 진입점 (사이드바 섹션) 이 공식화되지 않음.

revision 1 (2026-04-21): 사용자 추가 지시로 Insights 섹션 제거 + Hand History 섹션 승격 결정.

## 발견 경위

- 2026-04-21 사용자 ultrathink critic mode revision 1
- Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §7.1-7.2 + Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md

## 영향받는 챕터 / 구현

- `Lobby/UI.md §공통 레이아웃`: 신규 `■ Hand History` 섹션 추가 필요
- `Lobby/Overview.md`: Hand History 비즈니스 가치 + 데이터 출처 명시
- `Schema.md`: `hands` / `hand_actions` 테이블 cross-ref
- `Behavioral_Specs/HandStarted` event ↔ Hand History 화면 연동

## Migration Plan 요약 (Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md)

1. 25개 분산 참조를 **단일 SSOT 섹션** (Lobby/Hand_History/) 으로 통합
2. UI.md 에 사이드바 섹션 추가
3. Overview.md 에 비즈니스 가치 + DB 출처 명시
4. Schema.md cross-ref 보강

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. Hand History 독립 섹션 + 통합 SSOT 폴더 | 25개 참조 통일, 진입점 명확 | 마이그레이션 비용 | △ EBS 고유 기능 |
| 2. History 섹션 (Staff Action) 에 흡수 | UI 단순 | Hand vs Audit 결합 의존 (5NF 위반) | ✗ |
| 3. Reports 섹션에 통합 | 보고서로 분류 | Reports = 집계, History = 원본 — 의미 혼동 | ✗ |

## 결정 (decision_owner team1 판정 시 기입)

- **default 권고**: 대안 1 (Hand History 독립 섹션)
- 이유: revision 1 사용자 지시 + 5NF 정합 + EBS 고유 기능 명시
- decision_owner: team1

## 후속 작업

- [ ] team1: Lobby/Hand_History/Overview.md + UI.md + QA.md 신설 (Plans 마이그레이션 적용)
- [ ] team1: UI.md §공통 레이아웃 `■ Hand History` 행 추가
- [ ] team1: 25개 분산 참조를 신규 SSOT 폴더로 cross-ref 갱신
- [ ] conductor: Schema.md `hands` / `hand_actions` 테이블 ↔ Hand History UI 연결 확인

## 관련 SG

- SG-012 — Lobby 사이드바 SSOT
- SG-018 — 5NF 메타모델
