---
id: SG-009
title: "Spec Drift: TableFSM / SeatFSM display label vs serialized value case"
type: spec_gap
sub_type: spec_drift
status: IN_PROGRESS  # 이번 커밋에서 BS_Overview §3.1 에 직렬화 규약 note 추가
owner: conductor  # decision_owner (공통 계약)
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.5 Shared/BS_Overview.md §3.1, §3.3
  - docs/2. Development/2.2 Backend/Database/Schema.md
  - team2-backend/src/db/init.sql
  - team2-backend/src/services/table_service.py
protocol: Spec_Gap_Triage §7 (Type D1)
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=IN_PROGRESS, BS_Overview 직렬화 규약 note 추가 중"
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

- [ ] §3.3 Seat 상태 표에도 동일 직렬화 컬럼 추가 (후속 커밋)
- [ ] Schema.md 와 Backend_HTTP.md 에 직렬화 규약 cross-ref
- [ ] HandFSM §3.2 game_phase 의 enum (IDLE=0, SETUP_HAND=1, ...) 과 engine 코드 (lowerCamelCase) 간 매핑 보강
