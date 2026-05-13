---
title: Players + Hand History API (Lobby DB 연동 contract)
owner: s7
tier: contract
last-updated: 2026-05-13
version: 1.0.0
audience-target: 외부 백엔드 + Lobby 프론트엔드 시니어
derivative-of: ../Back_Office/Overview.md
if-conflict: derivative-of takes precedence
---

# Players + Hand History API — Lobby DB 연동 Contract

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2026-05-13 | v1.0.0 | 최초 작성 (Cycle 21 Wave 1, issue #443). 사용자 결정 — Lobby prototype 의 players / handhistory DB 연동 + Reports 탭 폐기. WSOP LIVE Staff App §09 Reports 영역은 EBS 운영 가치에서 제외, Hand History 는 `lib/features/hand_history/` 독립 feature 로 격상되어 본 contract 와 직접 통신. |

---

## §1 Context

### 1.1 왜 필요한가

본 contract 가 정의되기 전, Lobby 는 prototype `screens-extra.jsx` HandHistoryScreen 의 **mockup data** 만 표시했다 (`References/EBS_Lobby_Design/screens-extra.jsx:29`). DB 테이블 `players` / `hands` / `hand_players` / `hand_actions` (`Schema.md` §players, §hands) 는 이미 존재하지만 Lobby 가 조회할 수 있는 BO REST endpoint 가 부재했다.

본 contract 는 다음 세 가지 사용자 결정 (2026-05-13) 의 backend 측 정합이다:

1. **Reports 탭 폐기** — Lobby prototype Reports 화면 (`Reports.md` SSOT) 및 Flutter `lib/features/reports/` 통합 구현 모두 폐기.
2. **Hand History 독립 격상** — `lib/features/hand_history/` 독립 feature 로 분리, 본 contract 와 직접 연동.
3. **Players DB 연동** — Lobby 사이드바 `■ Players` 섹션이 BO REST 로 players 테이블 조회.

### 1.2 책임 분담

| 측 | 책임 |
|---|------|
| EBS (BO) | endpoint 구현 / pagination / RBAC enforce / DB JOIN 최적화 |
| EBS (Lobby Flutter) | 사용자 입력 → query param 직렬화 / cursor 기반 무한 스크롤 / 응답 캐싱 |
| EBS (Engine) | 권위 데이터 출처 — `hands` / `hand_actions` 는 Engine 이 hand 종료 시 BO 에 commit (Schema.md §1.3 Engine SSOT 예외 정합) |

### 1.3 SSOT pointers

- DB schema: `docs/2. Development/2.2 Backend/Database/Schema.md` §players (line 308–325) + §hands (line 424–494)
- Hand History feature spec: `docs/2. Development/2.1 Frontend/Lobby/Hand_History.md`
- Lobby UI spec: `docs/2. Development/2.1 Frontend/Lobby/UI.md` §좌측 사이드바 §Hand History 섹션 + §Players 섹션
- Lobby Overview narrative: `docs/2. Development/2.1 Frontend/Lobby/Overview.md` §화면 6 Hand History + §화면 계층 흐름 §4 진입 시점 카탈로그
- 외부 인계 PRD: `docs/1. Product/Lobby.md` v3.0.5 (Cycle 21 Changelog)
- HTTP 표준: `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` (전역 pagination/error pattern)
- 보안 / 인증: `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` (Bearer token + RBAC)

---

## §2 Endpoints

본 contract 는 4 endpoint 를 정의한다. 모두 `GET` (read-only). 인증은 Bearer token (Auth_and_Session.md §3 정합).

| Endpoint | 용도 | RBAC |
|----------|------|------|
| `GET /api/v1/players` | players 리스트 (Lobby 사이드바 검색, Player 독립 레이어) | Admin / Operator / Viewer 모두 read |
| `GET /api/v1/players/{id}` | players 상세 + 누적 stats | Admin / Operator / Viewer 모두 read |
| `GET /api/v1/hands` | hands 리스트 (Hand Browser) | Admin / Operator / Viewer 모두 read |
| `GET /api/v1/hands/{id}` | hand 상세 (nested hand_players + hand_actions) | Admin / Operator / Viewer (hole_cards RBAC 적용 — `Hand_History.md` §3 SSOT) |

### 2.1 GET /api/v1/players

**Request**:

```
GET /api/v1/players?event_id=42&search=John&limit=50&cursor=eyJpZCI6MTAwfQ
Authorization: Bearer {access_token}
```

| Query Param | Type | Required | Default | 설명 |
|-------------|:----:|:--------:|---------|------|
| `event_id` | int | ❌ | (전체) | 특정 event 등록 player 만 필터링 (events_players join) |
| `search` | str | ❌ | — | first_name / last_name / wsop_id ILIKE 부분 일치 |
| `nationality` | str | ❌ | — | ISO country_code 정확 일치 |
| `player_status` | str | ❌ | — | `active` / `eliminated` / `away` 등 |
| `limit` | int | ❌ | 50 | 1–200 |
| `cursor` | str | ❌ | — | base64 encoded `{"player_id": N}` (이전 페이지 마지막 player_id) |

**Response (200 OK)**:

```json
{
  "items": [
    {
      "player_id": 100,
      "wsop_id": "12345",
      "first_name": "John",
      "last_name": "Smith",
      "nationality": "USA",
      "country_code": "US",
      "profile_image": "https://cdn.ebs.live/players/100.jpg",
      "player_status": "active",
      "is_demo": false,
      "source": "wsop_live",
      "synced_at": "2026-05-13T07:00:00Z",
      "created_at": "2026-05-10T12:00:00Z",
      "updated_at": "2026-05-13T07:00:00Z"
    }
  ],
  "next_cursor": "eyJwbGF5ZXJfaWQiOjE1MH0",
  "has_more": true
}
```

**Cursor 규칙**: `next_cursor == null` 이면 마지막 페이지. 동일 cursor 재요청은 idempotent (동일 결과 반환).

### 2.2 GET /api/v1/players/{id}

**Request**:

```
GET /api/v1/players/100?include_stats=true
Authorization: Bearer {access_token}
```

| Query Param | Type | Required | Default | 설명 |
|-------------|:----:|:--------:|---------|------|
| `include_stats` | bool | ❌ | false | true 시 누적 통계 (총 hands, 우승 횟수, 누적 P&L) 포함 |

**Response (200 OK)**:

```json
{
  "player_id": 100,
  "wsop_id": "12345",
  "first_name": "John",
  "last_name": "Smith",
  "nationality": "USA",
  "country_code": "US",
  "profile_image": "https://cdn.ebs.live/players/100.jpg",
  "player_status": "active",
  "is_demo": false,
  "source": "wsop_live",
  "synced_at": "2026-05-13T07:00:00Z",
  "created_at": "2026-05-10T12:00:00Z",
  "updated_at": "2026-05-13T07:00:00Z",
  "stats": {
    "total_hands": 142,
    "wins": 23,
    "cumulative_pnl": 45000,
    "vpip_pct": 28.5,
    "pfr_pct": 18.2,
    "agr_pct": 31.7
  }
}
```

**Error**: 404 if player_id 없음.

### 2.3 GET /api/v1/hands

**Request**:

```
GET /api/v1/hands?event_id=42&flight_id=7&table_id=124&player_id=100&date_from=2026-05-13T00:00:00Z&date_to=2026-05-14T00:00:00Z&limit=50&cursor=eyJoYW5kX2lkIjo1MDB9
Authorization: Bearer {access_token}
```

| Query Param | Type | Required | Default | 설명 |
|-------------|:----:|:--------:|---------|------|
| `event_id` | int | ❌ | — | 해당 event 의 hand 만 (tables JOIN events) |
| `flight_id` | int | ❌ | — | 해당 flight 의 hand 만 (tables JOIN event_flights) |
| `table_id` | int | ❌ | — | 해당 table 의 hand 만 (직접 hands.table_id) |
| `player_id` | int | ❌ | — | 해당 player 가 참여한 hand 만 (hand_players JOIN) |
| `showdown_only` | bool | ❌ | false | true 시 ended_at IS NOT NULL AND board_cards JSON length >= 3 |
| `date_from` | ISO8601 | ❌ | — | hands.started_at >= |
| `date_to` | ISO8601 | ❌ | — | hands.started_at < |
| `limit` | int | ❌ | 50 | 1–200 |
| `cursor` | str | ❌ | — | base64 encoded `{"hand_id": N}` (이전 페이지 마지막 hand_id) |

**Response (200 OK)**:

```json
{
  "items": [
    {
      "hand_id": 500,
      "table_id": 124,
      "hand_number": 47,
      "game_type": 0,
      "bet_structure": 0,
      "dealer_seat": 3,
      "board_cards": "[\"As\",\"Kh\",\"Qd\",\"Js\",\"10c\"]",
      "pot_total": 25000,
      "side_pots": "[]",
      "current_street": null,
      "started_at": "2026-05-13T07:30:00Z",
      "ended_at": "2026-05-13T07:32:15Z",
      "duration_sec": 135,
      "winner_player_name": "John Smith"
    }
  ],
  "next_cursor": "eyJoYW5kX2lkIjo1NTB9",
  "has_more": true
}
```

> **Performance 약속 (§6 참조)**: 본 endpoint 는 `hand_actions` 와 `hand_players` 를 JOIN 하지 않는다. winner 정보만 `hand_players` 단일 JOIN (WHERE is_winner=true LIMIT 1) 으로 derive.

### 2.4 GET /api/v1/hands/{id}

**Request**:

```
GET /api/v1/hands/500
Authorization: Bearer {access_token}
```

**Response (200 OK)**:

```json
{
  "hand_id": 500,
  "table_id": 124,
  "hand_number": 47,
  "game_type": 0,
  "bet_structure": 0,
  "dealer_seat": 3,
  "board_cards": "[\"As\",\"Kh\",\"Qd\",\"Js\",\"10c\"]",
  "pot_total": 25000,
  "side_pots": "[]",
  "current_street": null,
  "started_at": "2026-05-13T07:30:00Z",
  "ended_at": "2026-05-13T07:32:15Z",
  "duration_sec": 135,
  "hand_players": [
    {
      "id": 2001,
      "hand_id": 500,
      "seat_no": 1,
      "player_id": 100,
      "player_name": "John Smith",
      "hole_cards": "[\"Ah\",\"As\"]",
      "start_stack": 50000,
      "end_stack": 65000,
      "final_action": "showdown_win",
      "is_winner": true,
      "pnl": 15000,
      "hand_rank": "Royal Flush",
      "win_probability": 0.98,
      "vpip": true,
      "pfr": true
    }
  ],
  "hand_actions": [
    {
      "id": 9001,
      "hand_id": 500,
      "seat_no": 1,
      "action_type": "raise",
      "action_amount": 1200,
      "pot_after": 1800,
      "street": "preflop",
      "action_order": 1,
      "board_cards": null,
      "action_time": "2026-05-13T07:30:15Z"
    }
  ]
}
```

**hole_cards RBAC** (Hand_History.md §3 SSOT):
- `Admin`: 전체 hole_cards 노출
- `Operator`: 본인 할당 테이블의 hand 만 hole_cards 노출
- `Viewer`: 본인 RBAC 매트릭스의 `view_hole_cards` flag 가 true 일 때만 노출. false 면 `"hole_cards": "[]"` 마스킹

**Error**: 404 if hand_id 없음.

---

## §3 Response Schema 요약 (Pydantic-style)

```python
# Reuse types
PlayerRead = {
    "player_id": int,
    "wsop_id": Optional[str],
    "first_name": str,
    "last_name": str,
    "nationality": Optional[str],
    "country_code": Optional[str],
    "profile_image": Optional[str],
    "player_status": str,           # active/eliminated/away
    "is_demo": bool,
    "source": str,                  # wsop_live/manual
    "synced_at": Optional[str],     # ISO8601
    "created_at": str,
    "updated_at": str,
}

PlayerStats = {
    "total_hands": int,
    "wins": int,
    "cumulative_pnl": int,          # chip 단위
    "vpip_pct": float,
    "pfr_pct": float,
    "agr_pct": float,
}

HandRead = {
    "hand_id": int,
    "table_id": int,
    "hand_number": int,
    "game_type": int,
    "bet_structure": int,
    "dealer_seat": int,
    "board_cards": str,             # JSON string
    "pot_total": int,
    "side_pots": str,               # JSON string
    "current_street": Optional[str],
    "started_at": str,
    "ended_at": Optional[str],
    "duration_sec": int,
}

HandListRead = HandRead + {
    "winner_player_name": Optional[str],
}

HandPlayerRead = {
    "id": int,
    "hand_id": int,
    "seat_no": int,
    "player_id": Optional[int],
    "player_name": str,
    "hole_cards": str,              # JSON string, RBAC 마스킹 가능
    "start_stack": int,
    "end_stack": int,
    "final_action": Optional[str],
    "is_winner": bool,
    "pnl": int,
    "hand_rank": Optional[str],
    "win_probability": Optional[float],
    "vpip": bool,
    "pfr": bool,
}

HandActionRead = {
    "id": int,
    "hand_id": int,
    "seat_no": int,
    "action_type": str,             # 14종 (Schema.md §hand_actions)
    "action_amount": int,
    "pot_after": Optional[int],
    "street": str,                  # preflop/flop/turn/river/showdown
    "action_order": int,
    "board_cards": Optional[str],
    "action_time": Optional[str],
}

HandDetailRead = HandRead + {
    "hand_players": list[HandPlayerRead],
    "hand_actions": list[HandActionRead],
}
```

---

## §4 Pagination — Cursor-based

본 contract 는 **cursor-based pagination** 을 채택한다. 이유:

1. **stable ordering**: `hand_id` (PK auto-increment) / `player_id` 기준 descending 정렬은 새 row 삽입 시에도 안정적.
2. **offset/limit 회피**: WSOP LIVE 대형 토너먼트에서 hands 가 10,000+ 누적 시 `OFFSET` 은 성능 저하 (PostgreSQL/SQLite 동일).
3. **무한 스크롤 친화**: Flutter `ListView.builder` + `ScrollController` 에 cursor 만 보관하면 됨.

### 4.1 Cursor 형식

```python
import base64, json

def encode_cursor(last_id: int) -> str:
    return base64.urlsafe_b64encode(
        json.dumps({"hand_id": last_id}).encode()
    ).decode()

def decode_cursor(cursor: str) -> int:
    return json.loads(
        base64.urlsafe_b64decode(cursor.encode()).decode()
    )["hand_id"]  # or "player_id"
```

### 4.2 Query 구현 예시

```sql
-- /api/v1/hands cursor query
SELECT h.*, hp.player_name as winner_player_name
FROM hands h
LEFT JOIN hand_players hp
  ON hp.hand_id = h.hand_id AND hp.is_winner = true
WHERE h.table_id = :table_id
  AND h.started_at >= :date_from
  AND h.started_at < :date_to
  AND h.hand_id < :cursor_hand_id  -- cursor 있을 때만
ORDER BY h.hand_id DESC
LIMIT :limit + 1;  -- +1 로 has_more 판정
```

**has_more 판정**: `LIMIT n+1` 후 결과가 n+1 행이면 `has_more = true`, n+1 번째 행은 응답에서 제외하고 `next_cursor` 만 그 값으로 설정.

---

## §5 RBAC

| Role | players list | players detail | hands list | hands detail | hole_cards 노출 |
|------|:------------:|:--------------:|:----------:|:------------:|:---------------:|
| Admin | ✅ 전체 | ✅ + stats | ✅ 전체 | ✅ | ✅ 전체 |
| Operator | ✅ event 단위 | ✅ + stats | ✅ 본인 할당 테이블 | ✅ | ✅ 본인 할당 테이블만 |
| Viewer | ✅ event 단위 | ✅ - stats (선택) | ✅ event 단위 | ✅ | ⚠ `view_hole_cards` flag 기반 (`Hand_History.md` §3) |

**Operator 본인 할당 테이블 식별**: `cc_sessions` 테이블의 `operator_id == current_user.id AND status == 'active'` 인 `table_id` 목록. 이 목록 밖의 table_id 로 query 시 hands list 에서 자동 필터링 (403 던지지 않고 단순 제외 — UX 친화).

---

## §6 Performance 약속

### 6.1 hands list — hand_actions JOIN 금지

`GET /api/v1/hands` 는 `hand_actions` 와 JOIN 하지 않는다. hand_actions 는 hand 당 평균 20–40 행 → 100 hand list 요청 시 2000–4000 행을 JOIN 하면 응답 크기 폭증 + DB 부담 ↑.

대신 hands list 응답은 `hand_id` + 메타데이터 + winner_player_name 만. 상세 액션은 사용자가 hand 를 클릭 → `/api/v1/hands/{id}` 로 lazy load.

### 6.2 hands detail — nested 전체 JOIN

`GET /api/v1/hands/{id}` 는 단일 hand 의 hand_players + hand_actions 를 모두 nested 응답에 포함. 평균 응답 크기는 약 5–15 KB (50 actions × ~200 byte + 9 players × ~300 byte).

### 6.3 index 요구 사항

본 contract 가 사용하는 index 는 이미 `Schema.md` §index 정의에 있음:

- `idx_hands_table` (table_id)
- `idx_hands_started` (started_at)
- `idx_hp_hand` (hand_id)
- `idx_hp_player` (player_id)
- `idx_ha_hand` (hand_id)

추가 index 요구 없음.

### 6.4 SLA

| Endpoint | p50 | p95 | p99 |
|----------|----:|----:|----:|
| GET /api/v1/players (limit=50) | 50ms | 200ms | 500ms |
| GET /api/v1/players/{id} (include_stats=false) | 20ms | 80ms | 200ms |
| GET /api/v1/players/{id} (include_stats=true) | 100ms | 400ms | 800ms |
| GET /api/v1/hands (limit=50) | 80ms | 300ms | 700ms |
| GET /api/v1/hands/{id} | 50ms | 200ms | 500ms |

> SLA 측정 환경: Schema.md §1.3 표준 — 10K hands / 1K players seed.

---

## §7 Cross-reference

| 영역 | 참조 |
|------|------|
| DB schema | `Schema.md` §players (line 308–325), §hands (line 424–446), §hand_players (line 448–473), §hand_actions (line 476–494), §index (line 1129–1133) |
| Lobby UI spec | `docs/2. Development/2.1 Frontend/Lobby/UI.md` §좌측 사이드바 §Hand History 섹션 (Cycle 21 보강) + §Players 섹션 (Cycle 21 NEW) |
| Lobby Overview | `docs/2. Development/2.1 Frontend/Lobby/Overview.md` §화면 6 Hand History (Cycle 21 데이터 출처 보강) + §UI 화면 설계 화면 표 |
| Hand History feature | `docs/2. Development/2.1 Frontend/Lobby/Hand_History.md` SSOT (RBAC / hole_cards / entry path / overlay 경계) |
| 외부 PRD | `docs/1. Product/Lobby.md` v3.0.5 §Changelog 2026-05-13 |
| 전역 HTTP 표준 | `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` (인증 / error / pagination 일반 규칙) |
| Reference design | `docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md` (Cycle 21 매핑 정정) |

---

## §8 Reports 폐기 영향 (informational, 2026-05-13)

본 contract 정립 이전에는 `Reports.md` (`docs/2. Development/2.1 Frontend/Lobby/Reports.md`) 가 다음 endpoint 를 요구했다:

- `GET /Reports/HandsSummary`
- `GET /Reports/PlayerStats`
- `GET /Reports/TableActivity`
- `GET /Reports/SessionLog`

Cycle 21 사용자 결정 (2026-05-13) 으로 **Reports 탭 폐기** 가 확정됨에 따라 위 4 endpoint 는 BO 구현 대상에서 제외된다. 본 contract 의 `GET /api/v1/players` (검색/리스트) + `GET /api/v1/hands` (조회/필터) 가 Lobby 사용자 요구를 완전히 흡수하며, 누적 통계는 `GET /api/v1/players/{id}?include_stats=true` 단일 endpoint 로 통합되었다.

`Reports.md` SSOT 본문 cleanup 및 `Hand_History.md` `lib/features/reports/` 경로 매핑 정정은 본 PR 범위 밖 — W3 (frontend impl) cycle 에서 수행 예정.
