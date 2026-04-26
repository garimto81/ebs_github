---
id: SG-017
title: "Settings \"글로벌 단위\" Overview 모순 (vs Series/Event/Table 분리)"
type: spec_gap
sub_type: scope_inconsistency
status: PENDING
owner: conductor  # decision_owner (memory 역전 판정)
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Settings/Overview.md §개요
  - docs/4. Operations/Conductor_Backlog/SG-003-settings-6tabs-schema.md (4-level scope)
  - memory: feedback_settings_global.md (2026-04-15 역전: WSOP LIVE 정렬 우선)
protocol: Spec_Gap_Triage §2 Type C (memory 역전 ↔ 본문 모순)
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §10 #5
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

## 결정 (decision_owner conductor 판정 시 기입)

- **default 권고**: 대안 1 (Overview.md 정정, SG-003 + MEMORY 우선)
- 이유: 원칙 1 정렬 + 구현 일치 + 2026-04-15 MEMORY 역전 결정 존중
- 영향: Settings/Overview.md §개요 재작성

## 후속 작업

- [ ] conductor: Settings/Overview.md §개요 재작성 — 4-level scope 명시 + SG-003 cross-ref
- [ ] conductor: 탭별 default scope 표 추가 (Outputs=Global / Graphics=Event / Display=Series / Rules=Event / Stats=Series)
- [ ] team1: settings_scope_provider.dart override priority 와 일치 확인
- [ ] conductor: Foundation §5.2 Settings 설명도 동기화

## 관련 SG

- SG-003 — Settings 6탭 스키마 (4-level scope)
- 원칙 1 (CLAUDE.md)
