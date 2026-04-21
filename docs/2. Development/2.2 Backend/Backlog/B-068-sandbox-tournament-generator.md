---
id: B-068
title: "Sandbox Tournament Generator 구현"
status: PENDING
source: docs/2. Development/2.2 Backend/Engineering/Sandbox_Tournament_Generator.md
---

# [B-068] Sandbox Tournament Generator 구현

- **날짜**: 2026-04-21
- **teams**: [team2]
- **관련 기획**: `Engineering/Sandbox_Tournament_Generator.md` v0.2 (critic 반영)

## 설명

매일 무작위로 sandbox 토너먼트를 생성하는 generator + 명확한 ON/OFF 토글 + FK 안전 teardown + API 격리 middleware 구현.

## 하위 작업 체크리스트

### Phase A — Schema / Config (migration)
- [ ] Alembic migration 0007: `competitions` 테이블 `id=99, name='Sandbox Competition'` 시드 삽입
- [ ] `settings_kv` 에 `sandbox.enabled` (기본 `"false"`, scope=global) 시드
- [ ] `series.source` / `events.source` / `event_flights.source` / `tables.source` CHECK 제약에 `'sandbox'` 추가 (기존 `'manual'`/`'wsop'`/`'api'` 유지)
- [ ] 인덱스 `idx_series_source`, `idx_events_source`, `idx_flights_source` 추가

### Phase B — Generator Core
- [ ] `src/services/sandbox/generator.py` — `generate_daily_sandbox(date, seed, n_series)` (§3 pseudocode)
- [ ] `src/services/sandbox/templates.py` — Event lineup template (§2.4) + VENUES 리스트
- [ ] `src/services/sandbox/math.py` — `compute_table_counts(day1, total_days, rng)` 동적 ratio (§2.6)
- [ ] invariant 검증 함수 `assert_main_event_last(series)` (§2.2)
- [ ] 재현성 테스트 — 동일 seed 2회 실행 후 field content diff empty (A7)

### Phase C — Enable/Disable 토글 (§1.1.1)
- [ ] `src/services/sandbox/config.py` — `is_enabled()` helper (env > DB 우선순위)
- [ ] `src/routers/sandbox.py`:
  - `GET /api/v1/sandbox/status` → `{enabled, generator_running}`
  - `POST /api/v1/sandbox/enable` (Admin only)
  - `POST /api/v1/sandbox/disable` (Admin only)
  - `POST /api/v1/sandbox/generate` (Admin only, on-demand, §Q6)
  - `POST /api/v1/sandbox/reset` (Admin only, 전체 정리 + 재생성)
- [ ] audit_events `sandbox.toggle.on` / `sandbox.toggle.off` 기록

### Phase D — Scheduler / Ticker
- [ ] `src/services/sandbox/scheduler.py` — daily cron (APScheduler 00:00 KST)
- [ ] `src/services/sandbox/ticker.py` — 5분 간격 status 전이 (§5.2)
- [ ] App-level mutex (§5.5) — `sandbox_generator_lock`, `sandbox_ticker_lock`
- [ ] OFF 상태 시 generator/ticker **스킵**, teardown 은 계속 실행

### Phase E — Teardown
- [ ] `src/services/sandbox/teardown.py` — §5.3 SQL 4단계 트랜잭션
- [ ] D-3 초과 sandbox series hard delete (tables → flights → events → series)
- [ ] audit_events `sandbox.*` D-3 초과 soft archive

### Phase F — API 격리 middleware (§4.1)
- [ ] `src/dependencies/sandbox_filter.py` — FastAPI dependency `sandbox_filter(include_sandbox: bool = False)`
- [ ] Repository 레이어에 `exclude_sandbox` 플래그 반영 (series/events/flights/tables repo 4개)
- [ ] `GET /api/v1/{series,events,flights,tables}` 에 `?include_sandbox=true` 쿼리 파라미터 지원
- [ ] WebSocket publisher payload 에 `source` 필드 포함

### Phase G — Tests
- [ ] `tests/test_sandbox_generator.py` — 3 series/day, 10+ events, Main Event 규칙, Final Table 도달
- [ ] `tests/test_sandbox_toggle.py` — ON/OFF 토글 상태 전이, RBAC (Admin only)
- [ ] `tests/test_sandbox_isolation.py` — default GET 에 sandbox 제외, `?include_sandbox=true` 시 포함
- [ ] `tests/test_sandbox_teardown.py` — FK cascade 순서, 트랜잭션 rollback
- [ ] `tests/test_sandbox_reproducible.py` — seed 재현성 (id/timestamp 제외 diff empty)

## 수락 기준

§6 (Sandbox_Tournament_Generator.md) A1~A10 전부 + 다음 추가:
- [ ] `POST /api/v1/sandbox/enable` 호출 → DB 값 즉시 반영 → 다음 cron tick 에서 series 생성
- [ ] `POST /api/v1/sandbox/disable` 호출 → 이후 cron tick 에서 generator 스킵 (ticker 도 스킵)
- [ ] `GET /api/v1/series` (default) 에 sandbox 제외됨 (A6)
- [ ] Admin 이외 role 의 enable/disable 호출 시 403

## 종속성

- **Blocks**: 없음 (독립)
- **Blocked by**:
  - B-013 `settings_kv` DB session 교체 (현재 in-memory) — `sandbox.enabled` DB 영속화 전제
  - NOTIFY-team1-sandbox-toggle-ui (team1 UI 협의 완료)

## 관련 PRD / 문서

- `Engineering/Sandbox_Tournament_Generator.md` v0.2 (기획 SSOT)
- `APIs/Backend_HTTP.md` §1 (source enum 'sandbox' 추가 완료)
- `Database/Schema.md` §1 대회 계층 (series/events/event_flights/tables)

## Phase 분할 권장

A → B → C → D → E → F → G 순서. Phase F 이후 team1 UI 연동 가능.
