---
id: SG-017
title: "Settings \"글로벌 단위\" Overview 모순 (vs Series/Event/Table 분리)"
type: spec_gap
sub_type: scope_inconsistency
status: DONE
resolved: 2026-05-03
resolved-by: conductor (Mode A 자율 — memory 역전 판정 권한, V9.4 정합)
owner: conductor
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Settings/Overview.md §개요
  - docs/4. Operations/Conductor_Backlog/SG-003-settings-6tabs-schema.md (4-level scope)
  - memory: feedback_settings_global.md (2026-04-15 역전: WSOP LIVE 정렬 우선)
protocol: Spec_Gap_Triage §2 Type C (memory 역전 ↔ 본문 모순)
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §10 #5
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "Conductor 자율 결정 완료 (2026-05-03). 대안 1 채택: 4-level scope (Global/Series/Event/Table/User) 우선, Settings/Overview.md §개요 본문은 재작성 cascade. 원칙 1 + memory 역전 + 구현 정합. SG-003 cross-ref 명시. 외부 개발팀 인계 가능 SSOT 확정"
---
# SG-017 — Settings "글로벌 단위" Overview 모순

## 공백 서술

`Settings/Overview.md §개요` 는 "여기서 변경한 사항은 방송 중인 모든 테이블에 일괄적으로 똑같이 적용됩니다" 라고 명시 — **글로벌 단일 스코프** 가정.

그러나 MEMORY `feedback_settings_global.md` 는 2026-04-15 역전 판정: "Settings 는 WSOP LIVE 와 동일한 Series/Event/Table 스코프 분리 (원칙 1 우선)".

또한 SG-003 은 4-level scope (Global/Series/Event/Table/User) 명시. **3개 SSOT 모순**.

## 발견 경위

- 2026-04-21 critic 보고 §10 #5 — Settings Overview 본문 vs MEMORY 역전 vs SG-003 모순 식별
- Type C (기획 모순) — 동일 대상에 다른 값 명시

## 영향받는 챕터 / 구현

- `Settings/Overview.md §개요` (line ~10-20): "모든 테이블에 일괄 적용" — 단일 스코프
- MEMORY `feedback_settings_global.md`: Series/Event/Table 분리
- `SG-003 settings-6tabs-schema.md`: 4-level scope (Global/Series/Event/Table/User)
- `team1-frontend/lib/features/settings/providers/settings_scope_provider.dart`: 4-level override 구현

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. Overview.md 본문을 4-level scope 로 정정 (SG-003 / MEMORY 우선) | 원칙 1 정렬 + 구현 일치 | Overview 재작성 | ✅ 일치 |
| 2. Overview.md 본문 유지 (글로벌 단일) + SG-003/구현 롤백 | Overview 유지 | 원칙 1 위반 + 구현 폐기 | ✗ 위반 |
| 3. 양립 (탭별 scope 다름) | 실제 의도 반영 가능 | 모호성 ↑ | △ |

## 결정 (Conductor Mode A 자율 — 2026-05-03 채택)

> ✅ **DONE** — V9.4 AI-Centric Mode A 자율 진행. 사용자 도메인 질문 0회 (memory 역전 판정 권한 = conductor 자체).

**채택**: 대안 1 — 4-level scope (Global/Series/Event/Table/User) 우선

**이유**:
- 원칙 1 (WSOP LIVE Confluence 정렬) 정합
- 2026-04-15 MEMORY `feedback_settings_global.md` 역전 결정 존중
- SG-003 4-level scope 정의 정합
- team1-frontend `settings_scope_provider.dart` 4-level override 구현 일치

**탭별 default scope 결정** (publisher cascade 권고):

| 탭 | Default scope | 근거 |
|----|---------------|------|
| Outputs | Global | 출력 채널 (NDI/SDI/RTMP) — 시스템 전역 |
| Graphics | Event | overlay 스킨 — Event 단위 (예: WSOP Main Event 별도 skin) |
| Display | Series | 화면 layout — Series 일관성 (브랜드 통일) |
| Rules | Event | 게임 규칙 변형 — Event 별 (예: 하이/로우) |
| Stats | Series | 통계 집계 단위 — Series scope |
| Preferences | User | 사용자별 (theme, locale) |

**영향 (publisher cascade 권고)**:
- `Settings/Overview.md §개요`: "모든 테이블 일괄 적용" 문장 → 4-level scope 명시 + 위 표 cross-ref
- `Foundation.md §5.2 Settings`: 4-level scope 동기화
- `BS_Overview §1`: scope 정의 등재 (Global/Series/Event/Table/User)

## 후속 작업

- [ ] conductor: Settings/Overview.md §개요 재작성 — 4-level scope 명시 + SG-003 cross-ref
- [ ] conductor: 탭별 default scope 표 추가 (Outputs=Global / Graphics=Event / Display=Series / Rules=Event / Stats=Series)
- [ ] team1: settings_scope_provider.dart override priority 와 일치 확인
- [ ] conductor: Foundation §5.2 Settings 설명도 동기화

## 관련 SG

- SG-003 — Settings 6탭 스키마 (4-level scope)
- 원칙 1 (CLAUDE.md)
