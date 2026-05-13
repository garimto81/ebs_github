---
id: SG-009
title: "Spec Drift: TableFSM / SeatFSM display label vs serialized value case"
type: spec_gap
sub_type: spec_drift
status: DONE  # 2026-04-21 §3.1 + §3.3 직렬화 규약 note 추가 + enums.py canonical 선언 + scanner fsm D4 23/23
owner: conductor  # decision_owner (공통 계약)
created: 2026-04-20
resolved: 2026-04-21
affects_chapter:
  - docs/2. Development/2.5 Shared/BS_Overview.md §3.1, §3.3
  - docs/2. Development/2.2 Backend/Database/Schema.md
  - team2-backend/src/db/init.sql
  - team2-backend/src/db/enums.py  # 2026-04-21 canonical FSM enum
  - team2-backend/src/services/table_service.py
protocol: Spec_Gap_Triage §7 (Type D1)
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "status=DONE — §3.1 직렬화 규약 note (2026-04-20) + §3.3 동일 note (2026-04-21) + src/db/enums.py canonical FSM 선언 (2026-04-21). spec_drift_check.py --fsm D4=23/23."
---
# SG-009 — TableFSM / SeatFSM display label vs serialized value case

## 공백 서술

`BS_Overview.md §3.1 Table 상태`, `§3.3 Seat 상태` 는 UPPERCASE label (`EMPTY`, `SETUP`, `LIVE`, `PAUSED`, `CLOSED`) 을 정의하지만, `team2-backend/src/db/init.sql` 과 services 는 **lowercase 값**(`'empty'`, `'setup'`, `'live'`, ...) 으로 직렬화한다.

실측 (2026-04-20):
- `init.sql L328`: `status TEXT NOT NULL DEFAULT 'empty'`
- `init.sql L376`: `CHECK (status IN ('empty','new','playing','moved','busted','reserved'))`
- `table_service.py L106`: `t.status = "live"`
- `services/clock_service.py`: `'running'`, `'paused'`, etc.

## 발견 경위

- 2026-04-20 `spec_drift_check.py --fsm` D1 감지
- 구현은 lowercase 로 3개월 이상 유지 (migration 여러 번). code-as-truth 판정 가능

## 결정 방안 후보

| 대안 | 장점 | 단점 |
|------|------|------|
| 1. 문서에 직렬화 규약 (UPPERCASE display, lowercase wire) 명시 | 코드 불변 유지 | 두 형식 유지 필요 |
| 2. 문서를 lowercase 로 정정 | SSOT 단일 형식 | display label 상실 |
| 3. 코드를 UPPERCASE 로 migration | display 와 일치 | 광범위 migration 필요, 브레이킹 |

## 채택

- **대안 1** (이번 커밋): `BS_Overview.md §3.1` 표에 `직렬화 값 (DB / API)` 컬럼 추가 + 규약 note
- 이유: 코드가 안정적으로 lowercase 를 쓰고 있으며, display label 은 운영 UI 에 유용

## 남은 작업

- [x] §3.3 Seat 상태 표에도 동일 직렬화 규약 note 추가 (2026-04-21)
- [x] canonical enum 선언: `team2-backend/src/db/enums.py` (2026-04-21) — TableFSM / HandFSM / SeatFSM / PlayerStatus / DeckFSM / EventFSM / ClockFSM 7종
- [ ] Schema.md 와 Backend_HTTP.md 에 직렬화 규약 cross-ref (후속)
- [ ] HandFSM §3.2 game_phase 의 enum (IDLE=0, SETUP_HAND=1, ...) 과 engine 코드 (Street.preflop 등) 간 매핑 보강 (후속)

## 2026-04-21 진전 (Agent Y)

1. `BS_Overview.md §3.3` 에 §3.1 동일 직렬화 규약 note 추가 (SeatFSM UPPERCASE display / lowercase wire)
2. `team2-backend/src/db/enums.py` 신규 작성 — BS_Overview §3 의 7종 FSM 을 `str, Enum` 으로 canonical 선언. 직렬화 규약 lowercase wire 값 준수
3. `tools/spec_drift_check.py --fsm` 정밀화:
   - single-quote (SQL) + double-quote (Python) 둘 다 매칭
   - scan 범위 확장: routers + services + models + db
   - HandFSM 에서 Dart 의 underscore-removed 형식 (`preflop`, `handcomplete`) alias 허용
   - engine scan 범위 `lib/core/state` → `lib` 전체로 확장 (engine.dart, rules/street_machine.dart 포함)
   - BS_Overview §3.1 직렬화 규약 note 감지 시 D1 case-mismatch 자동 억제
4. 실측: fsm D1=1 / D2=7 / D4=16 → **D1=0 / D2=0 / D4=23** (2026-04-21 scan)

## 후속 (scope 제외)

SG-010 (`--schema`, `--settings`, `--websocket` 정밀화) 는 별도 backlog 로 유지. SG-009 는 `--fsm` 및 TableFSM/SeatFSM 직렬화 규약 정의에 한정.
