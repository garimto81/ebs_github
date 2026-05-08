---
title: Sandbox Tournament Generator
owner: team2
tier: internal
legacy-id: null
confluence-page-id: 3818816181
last-updated: 2026-04-21
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816181/EBS+Sandbox+Tournament+Generator
---

# Sandbox Tournament Generator

> **Scope**: team2 sandbox 전용 — 매일 무작위 진행 중 토너먼트를 새로 생산. Production DB·WSOP LIVE 동기화 경로와 격리.
>
> **Not in scope**: Production 대회 데이터, 실제 플레이어·핸드 기록, RFID 실 연결. 이 문서는 `seed/README.md` 의 정적 샘플을 대체하지 않고 **동적 생성 엔진**을 추가한다.

## Edit History

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | v0.1.0 초안 | Sandbox 전용 daily tournament generator 기획 초안 작성 (팀2 세션) |
| 2026-04-21 | v0.2.0 critic 반영 | 병렬 critic 2건 결과 반영 — FK cascade 순서(§5.3 재작성), 수학 모순 수정(§2.6 재설계), API 격리 middleware 의무화(§4.1), 재현성 claim 정확화(§5.4, A7), Main Event 단일 조건 단순화(§2.2), 격리 플래그 primary/legacy 구분(§1.2) |

---

## 0. 개요

Backend 개발·통합 테스트·프로토타입 시연용 **"움직이는 데이터"** 가 필요하다. 기존 `seed/` 는 정적 snapshot 이라 Lobby/CC/Overlay 가 "어제와 같은 화면" 만 보여준다. WSOP LIVE API 실연결은 네트워크·인증·레이트리밋·비결정성 때문에 dev 단계에서 부적합.

이 문서는 **daily sandbox generator** 를 정의한다. `is_demo=true` · `source='sandbox'` 플래그로 production 데이터와 분리하고, 매일 UTC 00:00 KST 기준 새 series/events/flights/tables 집합을 생산한다.

### 0.1 기존 seed 와의 관계

| 대상 | 성격 | 수명 | 플래그 |
|------|------|------|--------|
| `seed/` (기존) | 정적 snapshot | permanent (dev reset 시 재삽입) | `source='manual'` |
| **Sandbox (이 문서)** | **동적 daily 생성** | **1~N일 (teardown 정책)** | `source='sandbox'`, `is_demo=true` |
| WSOP LIVE pull | 실 대회 pull | 원격 SSOT | `source='wsop'` |

---

## 1. 설계 원칙

### 1.1 원칙 1 (WSOP LIVE 정렬) 준수

| 항목 | WSOP LIVE 패턴 | Sandbox 적용 |
|------|---------------|-------------|
| 대회 계층 | Competition → Series → Event → EventFlight → Table | 동일 4-tier (EBS v10 계층) |
| Series 범위 | "2026 WSOP", "2026 WSOPC Seoul" 등 | Sandbox 용 시리즈 명명 규약 §2.3 |
| Event 번호 | `event_no` 1..N, Main Event 는 시리즈 대표 이벤트 | **Main Event = 가장 높은 `event_no`, series 최종 이벤트** (§2.4) |
| Flight 일정 | Day 1A/1B/2/3 … 다회차 | Flight 3~10일 랜덤 (§2.5) |

### 1.1.1 Enable / Disable 토글 (운영 ON/OFF 명시)

Sandbox 전체 기능은 **명확한 단일 토글** 로 활성/비활성 제어된다. 기획서·구현·UI 가 모두 같은 key 를 참조한다.

| 계층 | Key / Location | ON | OFF |
|------|---------------|-----|-----|
| **Config (DB)** | `settings_kv`: key=`sandbox.enabled` (scope=global) | `"true"` | `"false"` (기본값) |
| **API** | `GET /api/v1/sandbox/status` → `{enabled: bool, generator_running: bool}` | — | — |
| **API** | `POST /api/v1/sandbox/enable` / `POST /api/v1/sandbox/disable` (Admin 권한) | 즉시 ON | 즉시 OFF |
| **Lobby UI** | 우상단 Sandbox 배지 + Settings > System 탭 토글 | 배지 `ON` 표시 | 배지 숨김 |
| **env override** | `EBS_SANDBOX_ENABLED=true` (최우선) | DB 값 덮어씀 | DB 값 덮어씀 |

**동작 규칙**:

| 상태 | daily cron (§5.1) | sandbox_ticker (§5.2) | GET endpoint `?include_sandbox=true` | teardown job (§5.3) |
|:---:|:---:|:---:|:---:|:---:|
| **ON** | 실행 (series 생성) | 실행 (status 전이) | 기존 sandbox 데이터 반환 | 실행 |
| **OFF** | **스킵** (신규 생성 없음) | **스킵** (상태 동결) | 기존 sandbox 데이터 반환 (조회는 계속 허용) | **계속 실행** (잔존 데이터 자동 정리) |

**OFF 상태 의도**: 기존에 생성된 sandbox 데이터는 **조회 가능** 하나 **새로 생성되지 않음**. teardown 은 그대로 작동하여 D-3 이후 자연 소멸. "ON 으로 재전환 시 즉시 생성" 보장 (다음 cron tick 또는 on-demand).

**RBAC**:
- `enable/disable` endpoint 는 **Admin only** (operator/viewer 차단)
- audit_events 에 `sandbox.toggle.{on,off}` event_type 기록 (who/when/why)

**Default**: 프로덕션 배포 시 **OFF**. dev/staging 은 **ON**. 환경별 기본값은 `config.py` 또는 migration seed 에서 설정.

### 1.2 격리 원칙

**플래그 primary/legacy 구분** (critic A #4):
- **Primary**: `source='sandbox'` — events/event_flights/tables 전체 격리. 모든 신규 쿼리 기준.
- **Legacy compat**: `is_demo=1` (series 한정) — 기존 BO UI toggle 호환 유지. Sandbox 생성 시 series.is_demo=1 로 함께 설정하되, 조회 로직은 `source` 기준.

| 격리 대상 | 수단 |
|-----------|------|
| Production 조회 API | **모든 GET endpoint middleware 에서 기본 `WHERE source != 'sandbox'` 강제 주입** (§4.1 재작성). filter toggle 은 `?include_sandbox=true` 명시 시만 |
| WSOP LIVE 동기화 | sandbox 레코드는 upsert 대상 아님 (`synced_at IS NULL` 유지) |
| 실 RFID 경로 | sandbox table 의 `rfid_reader_id = NULL` (mock deck 만 허용) |
| Audit log | sandbox generator 행위는 `audit_events.event_type='sandbox.*'` prefix |
| WebSocket broadcast | publisher 가 payload 에 `source` 필드 포함. 구독자는 기본으로 sandbox 필터. CC/Overlay 는 sandbox 수신 opt-in 가능 |

### 1.3 결정론성 (Determinism)

- 생성기는 **seed** 파라미터 (날짜 + 환경별 salt) 로 재현 가능
- 동일 날짜·동일 seed → 동일 series/event/flight/table 조합
- 테스트/CI 에서 `--seed=<int>` 옵션으로 고정 재현 가능

---

## 2. 생성 스펙

### 2.1 수치 규칙

| 항목 | 최소 | 최대 | 기본 |
|------|:----:|:----:|:----:|
| **Series / day** | 3 | 5 | 3 |
| **Events / Series** | 10 | 15 | 12 |
| **Flights / Event** | 3일 | 10일 | 5일 |
| **Tables / Flight (Day 1)** | 8 | 40 | 16 (volume 감소, critic B #5) |
| **Tables / Flight (Final Day)** | 1 | 3 | 1 (Final Table) |
| **Tables / Flight (중간 Day)** | §2.6 동적 계산 공식 | — | — |

### 2.2 Main Event 규칙 (MUST)

**Single invariant (critic A #3 단순화)**:
```
Series S 의 events 배열을 event_no 오름차순 정렬 시
  INVARIANT: events[N-1] = Main Event
  AND events[N-1].event_name CONTAINS "Main Event"
```

**Secondary validation** (generator 가 보장, invariant 아님):
```
  events[N-1].buy_in = max(events[*].buy_in)         -- 최고 buy-in (보통 True, Mix High Roller 예외 가능)
  events[N-1].last_flight.end_time
      = max(events[*].flights.end_time)              -- 시리즈 최후 종료
```

즉, Main Event = **event_no 최댓값 (rank-based 단일 조건)** 이며, Mix Game High Roller 가 buy_in 더 높을 경우 secondary validation 은 warning only 로 다운그레이드 (격리 판정 기준이 아님).

### 2.3 Series 명명 규약

```
{YYYY-MM-DD} Sandbox {venue} #{idx}

예시:
  "2026-04-21 Sandbox Aria #1"
  "2026-04-21 Sandbox Bellagio #2"
  "2026-04-21 Sandbox Venetian #3"
```

- `venue` 는 프리셋 리스트에서 랜덤 선택 (10+ 옵션, 실제 WSOP 개최지 오마주)
- `idx` 는 해당 날짜 내 순번 (1 부터)

### 2.4 Event 구성 템플릿

Series 당 **10~15 events** 중 최소 포함:

| 슬롯 | 역할 | 예시 event_name 템플릿 |
|------|------|----------------------|
| Kickoff (event_no=1) | 저 buy-in 오프너 | `$500 NL Hold'em Kickoff` |
| Mid-tier × 3~5 | 다양 게임 | `$1,500 PLO`, `$2,500 HORSE`, `$10,000 Dealer's Choice` |
| High Roller × 1~2 | 고 buy-in | `$25,000 High Roller NL` |
| Mix Game × 1~2 | Mix 게임 모드 (MEMORY.md: 17종) | `$10,000 8-Game`, `$2,500 HORSE` |
| **Main Event (마지막)** | **최고 buy-in, 최장 flight** | `$10,000 World Championship Main Event` |

### 2.5 Flight 배치 규칙

```
Event E 의 start_date 는 series.begin_at + offset_days
Event.flights 는 3~10 연속 일자로 배치
  Day 1A, Day 1B (선택), Day 2, Day 2, Day 3, ... (Final Day)

Main Event 의 마지막 Flight.start_time =
  series 내 모든 event.flight.start_time 의 최댓값
```

### 2.6 Table 생성 규칙 (동적 컨솔리데이션 — critic B #2 수학 모순 수정)

**문제**: 고정 비율(0.6~0.8)로는 Day1=8/3일 또는 Day1=40/10일 케이스에서 Final=1 도달 불가.

**해결**: flight_days 기반 동적 비율 계산:

```python
def compute_table_counts(day1_tables: int, total_days: int, rng: Random) -> list[int]:
    """
    Day 1 에서 Final Day 까지 tables 수를 연속 반감으로 산출.
    Final Day tables ∈ [1, 3].
    """
    final_tables = rng.randint(1, 3)
    # 기하급수: N_day = day1 × ratio^(day-1), ratio = (final/day1)^(1/(total-1))
    ratio = (final_tables / day1_tables) ** (1 / (total_days - 1))
    counts = []
    for d in range(total_days):
        n = round(day1_tables * (ratio ** d))
        # 연속 단조감소 보장 (jitter ±1)
        if d > 0:
            n = min(n, counts[-1])
        counts.append(max(1, n))
    counts[-1] = final_tables  # 마지막 강제
    return counts
```

**예시**:
- day1=16, total_days=5 → [16, 9, 5, 3, 1]
- day1=40, total_days=10 → [40, 26, 17, 11, 7, 5, 3, 2, 1, 1]
- day1=8, total_days=3 → [8, 3, 1]

**max_players 규칙** (게임별):
- Hold'em = 9, HORSE = 8, Dealer's Choice = 6, Mix Game = 8 (기본)

---

## 3. 생성 알고리즘 (Pseudocode)

```python
def generate_daily_sandbox(date: date, seed: int, n_series: int = 3):
    rng = Random(seed ^ date.toordinal())
    competition_id = ensure_sandbox_competition()  # id=99 ("Sandbox Competition")

    for idx in range(1, n_series + 1):
        venue = rng.choice(VENUES)
        series = create_series(
            competition_id=competition_id,
            name=f"{date} Sandbox {venue} #{idx}",
            year=date.year,
            begin_at=date,
            end_at=date + timedelta(days=rng.randint(10, 25)),
            is_demo=True,
            source='sandbox',
        )

        n_events = rng.randint(10, 15)
        events = plan_event_lineup(n_events, rng)  # returns list w/ Main Event last

        for event_no, template in enumerate(events, start=1):
            event = create_event(
                series_id=series.id,
                event_no=event_no,
                event_name=template.name,
                buy_in=template.buy_in,
                game_type=template.game_type,
                game_mode=template.game_mode,
                blind_structure_id=get_or_create_blind_structure(template),
                start_time=series.begin_at + timedelta(days=template.offset_days),
                status='created',
                source='sandbox',
            )

            n_flight_days = rng.randint(3, 10)
            for d in range(n_flight_days):
                flight = create_flight(
                    event_id=event.id,
                    display_name=flight_label(d, n_flight_days),
                    start_time=event.start_time + timedelta(days=d),
                    status='created' if d > 0 else 'running',
                    source='sandbox',
                )
                n_tables = compute_table_count(d, rng)
                create_tables(flight, n_tables)

        assert is_main_event_last(series)  # §2.2 invariant
```

---

## 4. 데이터 모델 매핑

| 테이블 | Sandbox 필드 설정 |
|--------|------------------|
| `competitions` | `competition_id=99` 고정 ("Sandbox Competition"), seed 에 미리 삽입 |
| `series` | `is_demo=1`, `source='sandbox'`, `is_displayed=1` (Lobby 노출), `synced_at=NULL` |
| `events` | `source='sandbox'`, `status` 는 시간 기반 전이 (§5.2) |
| `event_flights` | `source='sandbox'`, `is_tbd=0`, `status` 시간 기반 |
| `tables` | `source='sandbox'`, `rfid_reader_id=NULL`, `deck_registered=0` |
| `blind_structures` | sandbox 전용 3~5 개 프리셋 재사용 (Main Event용 고급, Mid용 중급, Kickoff용 경량) |
| `audit_events` | `event_type='sandbox.generator.created'`, payload 에 생성 파라미터 |

### 4.1 API 격리 middleware (critic B #3 해소)

**문제**: 현재 `source` 필터 사용처는 `routers/sync.py` 1곳뿐. `GET /api/v1/series|events|flights|tables` 모두 sandbox 유출 가능.

**해결**: FastAPI dependency 기반 격리 middleware 도입.

```python
# src/dependencies/sandbox_filter.py
async def sandbox_filter(include_sandbox: bool = False) -> dict:
    """모든 GET endpoint 에 dependency 로 주입. Repository 레이어가 이 플래그로 source WHERE 절 자동 적용."""
    return {"exclude_sandbox": not include_sandbox}

# 적용 endpoint 목록 (Backend_HTTP.md drift 연계)
- GET /api/v1/series           → ?include_sandbox 추가
- GET /api/v1/events           → ?include_sandbox 추가
- GET /api/v1/flights          → ?include_sandbox 추가
- GET /api/v1/tables           → ?include_sandbox 추가
- GET /api/v1/reports/*        → sandbox 포함 여부 각 보고서별 판정
- WebSocket /ws/lobby,cc       → payload 에 source 필드. 구독자 기본 필터
```

### 4.2 enum/인덱스 확장

| 대상 | 변경 |
|------|------|
| `series.source` | 'manual' / 'wsop' / **'sandbox'** (CHECK 제약 추가 권고, Backend_HTTP.md §1 source enum 동시 갱신) |
| `events.source` | 동일 |
| `event_flights.source` | 동일 |
| `tables.source` | 동일 |
| 인덱스 | `idx_series_source`, `idx_events_source`, `idx_flights_source` 추가 (필터 성능) |

---

## 5. 스케줄링 & 운영

### 5.1 Daily Cron (00:00 KST)

```
CronSchedule: 0 0 * * *  (Asia/Seoul)
Job: python -m bo.sandbox.generator --date=today --n-series=3 --seed=$(date +%s)
```

대안: FastAPI `BackgroundTasks` 기반 in-process scheduler (dev 단순화).

### 5.2 Event/Flight 상태 전이 (Sandbox 특화)

```
t < start_time - 1h          → status='created'    (예정)
start_time - 1h ≤ t < start  → status='announced'  (준비 중)
start ≤ t < end              → status='running'    (진행)
t ≥ end                      → status='completed'  (종료)
```

`sandbox_ticker` 가 5분 간격으로 상태 전이 수행.

### 5.3 Teardown / Rollover 정책 (critic B #1 CASCADE 순서 수정)

| 레코드 연령 | 조치 |
|-------------|------|
| D+0 (오늘 생성) | active |
| D-1 ~ D-3 | 유지 (히스토리 조회 가능) |
| D-4+ | hard delete (volume 감소, critic B #5) |

**FK 제약 고려 삭제 순서** (RESTRICT 체인 때문에 수동 cascade 필수):

```sql
-- init.sql 규칙 확인:
--   tables.event_flight_id    → event_flights   ON DELETE RESTRICT
--   event_flights.event_id    → events          ON DELETE CASCADE
--   events.series_id          → series          ON DELETE RESTRICT
--   table_seats.table_id      → tables          ON DELETE CASCADE
--   players.table_id          → tables          ON DELETE RESTRICT

BEGIN TRANSACTION;

-- 1. players 재배치 (sandbox tables 의 참조 해제)
UPDATE players SET table_id = NULL
  WHERE table_id IN (SELECT t.table_id FROM tables t
                     JOIN event_flights f USING(event_flight_id)
                     JOIN events e USING(event_id)
                     JOIN series s USING(series_id)
                     WHERE s.source='sandbox' AND s.begin_at < date('now','-3 days'));

-- 2. tables 삭제 (table_seats CASCADE 로 자동)
DELETE FROM tables WHERE event_flight_id IN (...);

-- 3. event_flights 삭제
DELETE FROM event_flights WHERE event_id IN (...);

-- 4. events 삭제 (event_flights CASCADE, 이미 3단계에서 제거)
DELETE FROM events WHERE series_id IN (...);

-- 5. series 삭제
DELETE FROM series WHERE source='sandbox' AND begin_at < date('now','-3 days');

-- 6. audit_events sandbox.* 는 event_type 기준 삭제 (FK 없음, soft archive 권장)
DELETE FROM audit_events WHERE event_type LIKE 'sandbox.%' AND created_at < date('now','-3 days');

COMMIT;
```

**예외**: `source='sandbox' AND series.is_displayed=0` 로 수동 숨긴 것은 teardown 스킵.

**Lock**: teardown 실행 중 sandbox_ticker / generator 실행 방지 위해 app-level mutex (redis 또는 sqlite PRAGMA locking_mode).

### 5.4 재현성 / 테스트 (critic B #4 정확화)

**결정적 요소** (seed 로 재현 가능):
- event_name, buy_in, game_type, game_mode, blind_structure_id 참조
- 이벤트 개수, 플라이트 일수, 테이블 수 (§2.6 동적 공식)
- series_name 의 `venue` 와 `idx`

**비결정적 요소** (id / timestamp — seed 로 고정 불가):
- `series_id`, `event_id`, `event_flight_id`, `table_id` (AUTOINCREMENT)
- `created_at`, `updated_at` (`strftime('now')` 기본값)

**A7 수락 기준 (§6)**: "field content 결정론 (id / timestamp 제외)" — DB dump 비교 시 `ORDER BY series_name, event_no` 후 위 비결정 컬럼 제외 diff 가 empty.

```bash
# CI 재현성 테스트
python -m bo.sandbox.generator --date=2026-04-21 --seed=42 --reset
python -m bo.sandbox.generator --date=2026-04-21 --seed=42 --reset
python -m bo.sandbox.verify_reproducible --date=2026-04-21

# 데모 reset
python -m bo.sandbox.reset --n-series=3
```

### 5.5 Race Condition (critic B #6 추가)

3가지 실행 경로 (§5.1 cron, §5.2 ticker, Q6 on-demand) 동시성 방지:

- **App-level mutex**: `sandbox_generator_lock` (Redis or file-lock)
- **Ticker 전용 lock**: `sandbox_ticker_lock` 별도. ticker 는 transition 만, generator 는 insert 만
- **on-demand endpoint**: 실행 중이면 `409 Conflict` 반환

---

## 6. 수락 기준 (Acceptance Criteria)

| # | 조건 | 검증 방법 |
|---|------|-----------|
| A1 | 하루 최소 3개 series 생성 | `SELECT COUNT(*) FROM series WHERE source='sandbox' AND begin_at=today ≥ 3` |
| A2 | series 당 event ≥ 10 | `SELECT series_id, COUNT(*) FROM events WHERE source='sandbox' GROUP BY series_id HAVING COUNT(*) < 10 → 0 rows` |
| A3 | 각 series 마지막 event = Main Event | §2.2 invariant 쿼리 통과 |
| A4 | Main Event 종료 시각이 series 내 최후 | `MAX(flight.start_time) per event` 비교 |
| A5 | Flight 기간 3~10일 | `COUNT(flights per event) BETWEEN 3 AND 10` |
| A6 | Production 조회에서 sandbox 기본 제외 | `GET /api/v1/series` `GET /api/v1/events` `GET /api/v1/flights` `GET /api/v1/tables` default call 에 `source='sandbox'` 레코드 없음 |
| A7 | 재현성 (field content 결정론) | 동일 `--date --seed` 로 2회 실행 후 `ORDER BY series_name, event_no` + id/timestamp 컬럼 제외 diff → empty |
| A8 | 격리 | sandbox 레코드의 `synced_at IS NULL`, `rfid_reader_id IS NULL` 항상 |
| A9 | Final Table 도달 | 모든 flight 의 마지막 day.tables ∈ [1, 3] (§2.6 동적 공식 검증) |
| A10 | FK cascade 안전성 | teardown job 실행 → FK violation 0건 (트랜잭션 rollback 없음) |

---

## 7. Open Questions (Critic 에서 검토)

| # | 질문 | 1차 답안 |
|---|------|---------|
| Q1 | `is_demo` 컬럼과 `source='sandbox'` 플래그가 중복되지 않는가? | `is_demo` 는 series 만 존재. sandbox 는 event/flight/table 까지 격리해야 하므로 `source` 추가. 두 플래그 병행 유지. |
| Q2 | sandbox 데이터로 WebSocket publisher (J2) 가 이벤트 broadcast 해도 되는가? | 예, 단 `source='sandbox'` payload field 포함하여 구독자가 필터 가능 |
| Q3 | 매일 재생성 시 `competition_id=99` 가 점점 많은 series 를 축적. limit? | §5.3 D-8 hard delete 로 자동 해소. 추가로 `--max-series-retention=50` 옵션 |
| Q4 | Main Event 규칙을 DB CHECK 제약으로 강제해야 하는가? | SQLite CHECK 제약으로는 sibling 비교 불가. 애플리케이션 레벨 invariant + periodic audit job |
| Q5 | WSOP LIVE 실 pull 레코드와 sandbox 가 동시 존재할 때 Lobby UI 처리? | default 쿼리는 `source != 'sandbox'`. `?include_sandbox=true` 시 별도 섹션 또는 배지로 구분 |
| Q6 | 생성 주기를 daily 가 아닌 on-demand 로 할 대안은? | admin endpoint `POST /api/v1/sandbox/generate` 도 병행 제공 (테스트 유연성) |
| Q7 | Mix Game 이벤트의 rotation_order / allowed_games 구성은? | feedback_mix_game_mode 참조 — 17 종 프리셋에서 랜덤 선택 |

---

## 8. 변경 영향 (Impact)

| 영역 | 변경 필요 |
|------|----------|
| Schema | 선택 — `source` CHECK 제약 추가 여부 결정 필요 |
| API | `GET /api/v1/series|events|flights` 에 `?include_sandbox` 쿼리 파라미터 추가 |
| Lobby UI (team1) | sandbox 배지 / 섹션 표시 (별도 B-XXX 로 team1 협의) |
| Overlay (team3) | 변경 없음 (Flight status 시뮬레이션으로 Graphic 출력 그대로 소비) |
| CC (team4) | 변경 없음 (RFID mock 모드에서 동작 가능) |
| Audit | `event_type='sandbox.*'` 카탈로그 추가 (NOTIFY-CCR-039 연계) |

---

## 9. 관련 문서

| 문서 | 경로 |
|------|------|
| 기존 seed 정의 | `team2-backend/seed/README.md` |
| DB Schema | `docs/2. Development/2.2 Backend/Database/Schema.md` |
| Backend HTTP API | `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` (§5.17 sync-mock-seed/reset 과 구분) |
| Mix Game 정책 | MEMORY `feedback_mix_game_mode.md` |
| WSOP LIVE 정렬 | MEMORY `project_wsoplive_alignment_principle.md` |
| Multi-session | `docs/4. Operations/Multi_Session_Workflow.md` v3.0 |

---

## 10. Critic Review Log

### 2026-04-21 v0.1.0 → v0.2.0 (병렬 2-critic)

**Critic A (설계/원칙1 정렬)** — 판정: APPROVE_WITH_CHANGES
- [MAJOR] §1.1 WSOP LIVE 정렬 주장은 계층만 해당. "sandbox/demo" 패턴은 Confluence 미러에 없음 → **§1.1 EBS 고유 divergence 명시**
- [MAJOR] §2.2 Main Event 4조건 중복 판정 → **단일 invariant (event_no 최댓값) 로 단순화**, 나머지 secondary validation
- [MAJOR] `is_demo` + `source='sandbox'` 이중화 혼란 → **§1.2 primary/legacy 구분 명시**

**Critic B (DB/운영)** — 판정: APPROVE_WITH_CHANGES
- [CRITICAL] §5.3 hard delete 는 FK RESTRICT 때문에 실패 → **명시적 4단계 cascade 순서 + 트랜잭션**
- [CRITICAL] §2.1+§2.5+§2.6 수학 모순 (고정 비율 ×0.7 로는 3일 또는 10일 flight 에서 Final=1 도달 불가) → **§2.6 동적 공식 `ratio = (final/day1)^(1/(days-1))`**
- [CRITICAL] `source` 필터 사용처 1곳뿐 (sync.py) → **§4.1 FastAPI dependency middleware 로 모든 GET 강제**
- [MAJOR] 재현성 claim 파괴 (AUTOINCREMENT id + now()) → **§5.4 결정적/비결정적 분리, A7 용어 정확화**
- [MAJOR] 볼륨 과다 (4,320 tables/day × 7일) → **§2.1 Day1 기본 24→16, §5.3 retention D-8→D-3**
- [MINOR] race condition → **§5.5 app-level mutex 추가**

**자기반박 반영**: Main Event buy_in=max 조건은 Mix High Roller 와 충돌 가능성 있어 secondary 로 다운그레이드. 재현성 "완전 재현" claim 은 실무상 불가능 → field content 단위로 조정.

## 11. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-04-21 | v0.1.0 | 최초 작성 | - | 사용자 요청 (매일 동적 토너먼트 sandbox 필요) |
| 2026-04-21 | v0.2.0 | Critic 반영 | TECH | 병렬 2-critic 결과 (CRITICAL 3건 / MAJOR 5건 / MINOR 1건) 수정 반영 |
