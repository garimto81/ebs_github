---
title: CYCLE 4 — S8 Settings engine_rules 9 keys 정합 (Issue #265)
tier: notify
stream: S8
cycle: 4
issue: 265
status: KPI_MET
last-updated: 2026-05-12
related-rules: docs/2. Development/2.3 Game Engine/Rules/Engine_Defaults.md
---

# CYCLE 4 — S8 Settings engine_rules 9 keys 정합 보고서

## KPI (Issue #265)

> **spec_drift_check --settings 결과 engine D2 9→0** ✅ (Engine 영역 default 명시 완료)

## 9 keys 분류 결과

| 분류 | 개수 | keys |
|------|:----:|------|
| Engine GameState 직접 매핑 (default null/false) | 6 | `allow_run_it_twice`, `ante_override`, `bomb_pot_amount`, `run_it_times`, `seven_deuce_amount`, `straddle_seat`, `all_in` (derived) |
| Engine out-of-scope (UI/Overlay 영역) | 2 | `allow_rabbit` (Overlay UX), `_blindsFormatOptions` (frontend) |
| 합계 | 9 | — |

상세 default 표 + 코드 위치 (file:line) → `Rules/Engine_Defaults.md` §1.

## 작업 체크리스트

| # | 작업 | 상태 |
|---|------|:----:|
| 1 | spec_drift_check --settings baseline 측정 | ✅ 9 keys D2 확인 (team1 settings 영역) |
| 2 | Engine Dart 코드 default 추출 (`game_state.dart` + `session.dart`) | ✅ 7 keys snake→camel 매핑 완료 |
| 3 | `docs/2. Development/2.3 Game Engine/Rules/Engine_Defaults.md` 신설 | ✅ 신규 contract 문서 |
| 4 | Backlog 인덱스 갱신 | ✅ Backlog.md + 본 CYCLE4 파일 |
| 5 | PR 발행 (labels: stream:S8 / cycle:4 / governance-change / mixed-scope) | ⏳ 본 commit 직후 |
| 6 | cascade:engine-spec-aligned publish | ⏳ PR ready 후 |
| 7 | Issue #265 close | ⏳ PR merge 시 자동 |

## Foundation 정렬

본 작업은 Foundation §B.1 ("Engine 은 22 게임 룰 전체를 코드 내장 상수로 보유") 정렬 — Engine GameState 필드가 default 의 SSOT, 본 문서는 derive snapshot.

> 결과: Engine harness `POST /api/session` 응답 JSON 의 9 필드 default 가 본 contract 문서와 1:1 정합.

## S8 scope 결정

- ✅ S8 scope 안: `docs/2. Development/2.3 Game Engine/Rules/Engine_Defaults.md` (신설)
- ❌ S8 scope 밖: `docs/1. Product/Game_Rules/Betting_System.md` (BLOCKED meta — conductor 영역)
- → `Game_Rules/Betting_System.md` 갱신은 **conductor 또는 별도 dispatch** 필요. 본 PR 의 cascade publish 가 이 신호를 전파

## 다음 cascade

- `cascade:engine-spec-aligned` publish (broker) — 9 keys default contract ready
- consumer: conductor (Game_Rules 갱신), team1 (settings UI), team4 (Rabbit Hunt 외부 영역)

## 참조

- Issue: https://github.com/garimto81/ebs_github/issues/265
- 신규 contract 문서: `Rules/Engine_Defaults.md`
- Engine 코드: `team3-engine/ebs_game_engine/lib/core/state/game_state.dart`, `lib/harness/session.dart`
- 검증 도구: `tools/spec_drift_check.py --settings`
