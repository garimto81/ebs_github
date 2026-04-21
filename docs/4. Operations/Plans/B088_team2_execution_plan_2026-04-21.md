---
title: "B-088 team2 실행 계획 — camelCase/PascalCase 전수 마이그레이션"
owner: team2
tier: internal
last-updated: 2026-04-21
scope: team2 (PR 2, 3, 4 of B-088)
---

# B-088 team2 실행 계획 — WSOP LIVE 규약 전수 준수

> **목표**: EBS Backend 의 JSON field / WebSocket event type / REST URL path / Path variable 을 WSOP LIVE 규약과 **100% 정렬** 한다. `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2 SSOT 를 기준으로 team2 PR 2/3/4 를 실행.
>
> **notify**: team1 (ws_dispatch + Repository 연동 영향), team4 (CC consumer 영향), team3 (API-04 payload 영향)

## 0. WSOP LIVE 증거 재확인 (원칙 1)

| 증거 | 위치 | 규약 |
|------|------|------|
| REST path PascalCase | `wsoplive/docs/confluence-mirror/.../BMM Backend API 정리.md` | `[HttpGet("/Balances")]`, `/Series/{seriesId}/Balance`, `/Credential/Biometric/Credential`, `/TicketOrders/{ticketOrderId}/Transactions` |
| Path variable camelCase | 동상 | `{seriesId}`, `{ticketOrderId}`, `{playerId}` |
| JSON field camelCase | `Signalr Key Mapping.md`, `JsonSerialization 일원화.md` | `accessToken`, `eventFlightId`, `tableCount`, `isFeatured` |
| WS event PascalCase | `Signalr Service.md:27` | `hubConnection.on('SeatInfo', ...)` |

**핵심 시사**: WSOP LIVE 는 **lowercase resource path 도 PascalCase 로 발행**한다. 즉 `/balances` 가 아닌 `/Balances`. EBS 의 `/series`, `/events`, `/flights` 등도 전수 PascalCase 로 전환 필요 (단순 kebab 20개 교체가 아님).

---

## 1. 전수 검사 결과 (team2 — 2026-04-21 실측)

### 1.1 REST path (변경 대상)

| 항목 | 측정값 | 출처 |
|------|:------:|------|
| 전체 `@router.*` decorator | **126** | `src/routers/*.py` 17 파일 |
| kebab-case path (명시적 하이픈) | **20** | `/audit-logs`, `/blind-structures`, `/payout-structures`, `/reports/*`, `/wsop-live*`, `/verify-2fa`, `/clock/reload-page`, `/clock/adjust-stack` 등 |
| path variable `{snake_case}` | **84** | `{series_id}`, `{event_id}`, `{flight_id}`, `{table_id}`, `{hand_id}`, `{skin_id}`, `{user_id}`, `{player_id}`, `{bs_id}`, `{ps_id}`, `{deck_id}`, `{competition_id}`, `{section}`, `{seat_no}`, `{source}` |
| lowercase resource path (PascalCase 대상) | **~106** | `/series`, `/events`, `/flights`, `/tables`, `/players`, `/skins`, `/decks`, `/users`, `/configs`, `/hands`, `/audit`, `/reports`, `/sync`, `/settings` 등 |

### 1.2 WebSocket event (변경 대상)

| 항목 | 측정값 | 출처 |
|------|:------:|------|
| 전체 event emit site | **20** | publishers.py (publish 13) + lobby_handler.py (broadcast 3) + cc_handler.py (4 reply) |
| snake_case event type | **10** | publishers.py 7 + lobby_handler.py 3 |
| PascalCase event type (이미 준수) | **10** | `AuthFailed`, `TableNotFound`, `PermissionDenied`, `InvalidMessage`, `RfidHardwareError`, `DuplicateCard`, `CardConflict`, `SlowConnection`, `TokenExpiringSoon`, `AssignSeatCommand`, `BlindStructureChanged`, `PlayerUpdated`, `TableAssigned` 등 |

**snake → PascalCase 변환 대상 (10)**:

| 기존 | 변환 후 | 위치 |
|------|---------|------|
| `clock_detail_changed` | `ClockDetailChanged` | publishers.py:42 |
| `clock_reload_requested` | `ClockReloadRequested` | publishers.py:58 |
| `tournament_status_changed` | `TournamentStatusChanged` | publishers.py:74 |
| `blind_structure_changed` | `BlindStructureChanged` | publishers.py:90 ⚠️ 중복 (line 312 이미 Pascal — 일원화 필요) |
| `prize_pool_changed` | `PrizePoolChanged` | publishers.py:106 |
| `stack_adjusted` | `StackAdjusted` | publishers.py:124 |
| `skin_updated` | `SkinUpdated` | publishers.py:143 |
| `event_flight_summary` | `EventFlightSummary` | lobby_handler.py:90 |
| `clock_tick` | `ClockTick` | lobby_handler.py:105 |
| `clock_level_changed` | `ClockLevelChanged` | lobby_handler.py:120 |

### 1.3 Pydantic 모델 (변경 대상)

| 항목 | 측정값 | 출처 |
|------|:------:|------|
| BaseModel 직속 class | **48** | `models/schemas.py` |
| BaseModel 산개 class | **21** | `models/{audit_event,audit_log,hand,blind_structure,competition,config,payout_structure,skin,table,user}.py` 11 파일 |
| SQLModel `table=True` | **다수** | `models/*.py` |
| `alias_generator=to_camel` 사용 | **0** | 전역 도입 필요 |
| `ConfigDict` 활용 | **0** | 전역 도입 필요 |

### 1.4 문서 JSON 예시 (변경 대상)

| 문서 | snake_case field 수 |
|------|:-------------------:|
| `Backend_HTTP.md` | 108 |
| `WebSocket_Events.md` | 145 |
| `Auth_and_Session.md` | 25 |
| `Graphic_Editor_API.md` | 18 |
| **총** | **296** |

### 1.5 테스트 fixture (변경 대상)

| 경로 | snake_case field 수 |
|------|:-------------------:|
| `team2-backend/tests/` | **234** (25 파일) |
| `tests/fixtures/wsop_live/*.json` | 8 (4 파일) |

---

## 2. PR 2 — Pydantic alias_generator 전역 도입

### 2.1 목표

모든 Pydantic request/response 모델이 외부 JSON 직렬화 시 **camelCase**, 내부 코드 접근 시 **snake_case** 를 모두 허용하도록 전역 설정.

### 2.2 작업

#### Step 1 — EbsBaseModel 신설

```python
# src/models/base.py (NEW)
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class EbsBaseModel(BaseModel):
    """EBS 전역 Pydantic base — 외부 camelCase / 내부 snake_case 양립.

    원칙 1 (WSOP LIVE 정렬) 준수. `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2.
    """
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,    # 내부에서는 snake_case field name 사용 가능
        from_attributes=True,     # SQLModel/ORM 객체에서 직접 변환
    )
```

#### Step 2 — schemas.py 전수 리팩토링

`BaseModel` 상속 48 class 를 `EbsBaseModel` 로 일괄 교체. `response_model` 사용 엔드포인트는 자동으로 camelCase 직렬화.

```python
# BEFORE
from pydantic import BaseModel

class EventResponse(BaseModel):
    event_id: int
    event_name: str
    buy_in: int | None

# AFTER
from src.models.base import EbsBaseModel

class EventResponse(EbsBaseModel):
    event_id: int       # 외부 JSON: eventId
    event_name: str     # 외부 JSON: eventName
    buy_in: int | None  # 외부 JSON: buyIn
```

#### Step 3 — 산개 class 21개 migrate

`models/{audit_event,audit_log,hand,...}.py` 의 `BaseModel` 상속 class 도 동일.

**SQLModel (table=True)** 은 DB column 과 1:1 → **변경하지 않는다**. Pydantic response DTO 만 alias_generator 적용.

#### Step 4 — FastAPI response_model_by_alias=True 확인

FastAPI 는 기본적으로 `response_model_by_alias=True`. 명시 불필요 but 검증.

#### Step 5 — Request 입력 검증

클라이언트가 camelCase JSON 을 보내면 `populate_by_name=True` 로 snake_case 필드 매핑.
기존 snake_case JSON 을 보내던 테스트도 `populate_by_name` 으로 계속 동작.

### 2.3 검증

| 항목 | 방법 |
|------|------|
| Response JSON key = camelCase | `GET /api/v1/series` 응답이 `{"seriesId": 1, "seriesName": ...}` |
| Request JSON 양립 | camelCase / snake_case 둘 다 수용 (`populate_by_name=True`) |
| 기존 pytest 247 tests | 전부 PASS (response 파싱 로직만 영향) |
| ORM attribute access | `series.series_id` 내부 코드 그대로 동작 |

### 2.4 규모

- 수정 파일: **12** (models/base.py NEW + schemas.py + 10 산개 model)
- 수정 class: **69**
- line 변경: ~100 (import 변경 + base class 변경)

### 2.5 리스크 & 완화

| 리스크 | 완화 |
|--------|------|
| 기존 test 가 snake_case response 를 assert | `populate_by_name=True` 로 response 도 by_name 접근 가능. 단 실제 직렬화 key 는 camelCase — test assertion key 교체 필요 (234건) |
| 수동 JSON dict 조작 코드 | grep `json.dumps`, `dict(...)` 로 검출 후 Pydantic 경로로 통일 |
| SQLModel alias 충돌 | SQLModel 은 table=True 상태에서 alias_generator 적용 시 column 매핑 깨질 가능성. **response DTO 는 별도 EbsBaseModel**, ORM 은 SQLModel 유지 |

---

## 3. PR 3 — WebSocket publisher PascalCase 전수 통일

### 3.1 목표

10개 snake_case event type 을 PascalCase 로 전환. 동시에 payload 필드를 camelCase 로 직렬화.

### 3.2 작업

#### Step 1 — publishers.py / lobby_handler.py event type 교체

```python
# BEFORE
async def publish_clock_detail_changed(...):
    payload = {
        "type": "clock_detail_changed",
        ...
    }

# AFTER
async def publish_clock_detail_changed(...):   # 함수명은 snake_case 유지 (Python PEP 8)
    payload = {
        "type": "ClockDetailChanged",
        ...
    }
```

#### Step 2 — payload 필드 camelCase 직렬화

기존 수동 dict 구성을 Pydantic 모델로 전환:

```python
class ClockDetailChangedPayload(EbsBaseModel):
    flight_id: int
    level_no: int
    small_blind: int
    big_blind: int

payload = {
    "type": "ClockDetailChanged",
    "seq": next_seq(),
    "data": ClockDetailChangedPayload(...).model_dump(by_alias=True),
}
```

#### Step 3 — BlindStructureChanged 중복 정리

publishers.py line 90 (snake) + line 312 (Pascal) 존재. 하나로 통합. 기존 호출부 확인 후 단일 함수로 리팩토링.

#### Step 4 — WebSocket_Events.md 문서 업데이트

snake event 10개 문서 예시를 PascalCase 로 교체 + JSON payload 필드 camelCase.

### 3.3 검증

| 항목 | 방법 |
|------|------|
| publisher 출력 JSON | 모든 `type` 값이 PascalCase, data 필드 camelCase |
| team1 ws_dispatch | 26 case 중 snake 10개가 PascalCase 로 매핑 (PR 6 에서 반영 — 이번 PR 은 backend 만) |
| WebSocket_Events.md | 모든 event type/field 실제 emit 과 일치 |
| drift check | `tools/spec_drift_check.py --websocket` D4 증가 없음 (event 증감 0) |

### 3.4 규모

- 수정 파일: **3** (publishers.py + lobby_handler.py + WebSocket_Events.md)
- 수정 event type: **10**
- 수정 payload field: 이벤트당 3~6개 → 40~60개

### 3.5 리스크 & 완화

| 리스크 | 완화 |
|--------|------|
| team1/team4 consumer 동시 변경 실패 시 런타임 에러 | PR 3 단독 배포 금지 — PR 5 (team1 Freezed) / PR 7 (team4) 와 동일 배포 |
| 기존 WS test | 26건 (tests/test_websocket.py + test_ws_cc_commands.py + test_ws_rbac.py) assertion key 교체 |

---

## 4. PR 4 — REST path PascalCase + path variable camelCase 전수

### 4.1 목표

126 endpoint 전체 path 를 WSOP LIVE 규약으로 정렬:
- lowercase resource → PascalCase (`/series` → `/Series`)
- kebab-case → PascalCase (`/hand-history` → `/HandHistory`)
- path variable snake_case → camelCase (`{series_id}` → `{seriesId}`)

### 4.2 작업

#### Step 1 — 변환 규칙 자동화 스크립트

```python
# tools/b088_path_rename.py
import re

LOWERCASE_RESOURCES = [
    'series', 'events', 'flights', 'tables', 'players', 'skins',
    'decks', 'users', 'configs', 'hands', 'audit', 'reports', 'sync',
    'settings', 'competitions', 'blind-structures', 'payout-structures',
    'audit-logs', 'audit-events', 'wsop-live', 'verify-2fa',
    'password', 'google', 'me', 'login', 'logout', 'refresh', 'session', '2fa',
]

# kebab → PascalCase 변환
def to_pascal(segment: str) -> str:
    return ''.join(w.capitalize() for w in segment.split('-'))

# path variable snake → camelCase
def path_var_to_camel(match: re.Match) -> str:
    snake = match.group(1)
    parts = snake.split('_')
    return '{' + parts[0] + ''.join(p.capitalize() for p in parts[1:]) + '}'
```

이 스크립트로 `src/routers/*.py` 의 `@router.*` 데코레이터 prefix 를 일괄 rewrite.

#### Step 2 — APIRouter prefix 일괄 변경

```python
# BEFORE
router = APIRouter(prefix="/api/v1/decks", tags=["decks"])

# AFTER
router = APIRouter(prefix="/api/v1/Decks", tags=["decks"])
```

`/api/v1` 은 version prefix 로 유지 (lowercase 관행 허용 — WSOP LIVE 도 `/api/v1` 또는 버전 prefix 없음). `/api/v1` 이후 segment 만 PascalCase.

#### Step 3 — Backend_HTTP.md 180 endpoint 문서 교체

자동화: sed / 스크립트로 문서 내 path string 일괄 rewrite.

#### Step 4 — Path variable 사용처 FastAPI 함수 시그니처 업데이트

```python
# BEFORE
@router.get("/series/{series_id}")
def api_get_series(series_id: int, ...):

# AFTER
@router.get("/Series/{seriesId}")
def api_get_series(seriesId: int, ...):      # PEP 8 위반 — 함수 내부 재할당
# OR (권장)
def api_get_series(series_id: int = Path(..., alias="seriesId"), ...):
```

**권장 패턴**: FastAPI `Path(alias="seriesId")` 로 Python 내부는 snake_case 유지, URL 은 camelCase.

### 4.3 Pydantic/Query 파라미터

QueryParam 도 camelCase:
```python
# BEFORE
def list_hands(event_id: int = Query(None)):

# AFTER
def list_hands(event_id: int = Query(None, alias="eventId")):
```

`?event_id=42` → `?eventId=42`. `alias=` 로 URL 변환.

### 4.4 검증

| 항목 | 방법 |
|------|------|
| 모든 GET/POST 경로 PascalCase | `tools/naming_check.py` (PR 9) 로 자동 검증 |
| Path variable camelCase | 동상 |
| Query parameter camelCase | 동상 |
| pytest 247 tests | URL 변경 영향 받음 — test 경로 교체 후 PASS |
| FastAPI docs (`/docs`) | 자동 OpenAPI 에 반영 확인 |

### 4.5 규모

- 수정 파일: **17 routers + Backend_HTTP.md + 대다수 test 파일**
- 수정 endpoint: **126** (path + path variable + query param)
- 문서 교체: **~180 occurrence** (Backend_HTTP.md)

### 4.6 리스크 & 완화

| 리스크 | 완화 |
|--------|------|
| Integration test `.http` 시나리오 대량 교체 | integration-tests/ 폴더 sed 일괄 + 수동 검수 |
| team1/team4 Repository 동시 배포 필요 | PR 6 (team1) / PR 7 (team4) 와 동시 배포. 단독 merge 금지 |
| FastAPI 자동 OpenAPI 경로 충돌 | 없음 (단방향 변경) |

---

## 5. 실행 순서 (team2 내부)

```
PR 2 (Pydantic alias)
  ↓
PR 3 (WS event PascalCase)           PR 4 (REST path PascalCase)
  ↓                                    ↓
team1/team4 notify 수신 후 PR 5/6/7/8 진행
  ↓
PR 9 (Conductor CI gate)
```

권장 — PR 3 과 PR 4 는 **동시 진행 가능** (독립 파일). PR 2 가 선행 조건.

### 세션 분할 권고

1. **세션 1** — PR 2 완결 (Pydantic alias_generator + 69 class migration + 기존 247 test 통과)
2. **세션 2** — PR 3 + PR 4 병행 (WS 10 event PascalCase + REST 126 endpoint PascalCase + 문서 동기)
3. **세션 3** — 통합 검증 + integration-tests/ 교체 + tools/naming_check.py 후보 작성 (PR 9 선행)

---

## 6. 수락 기준 (team2 전체)

- [ ] PR 2 — 모든 Pydantic response JSON key = camelCase (자동 직렬화), request 는 양립 허용
- [ ] PR 2 — pytest 247 tests 통과 (assertion key 교체 후)
- [ ] PR 3 — publishers.py + lobby_handler.py 의 모든 `"type": "..."` 값 = PascalCase
- [ ] PR 3 — WebSocket_Events.md snake event 10개 문서 교체 완료
- [ ] PR 4 — 126 endpoint path = PascalCase (version prefix `/api/v1/` 예외)
- [ ] PR 4 — 84 path variable = camelCase
- [ ] PR 4 — Query parameter = camelCase (alias 사용)
- [ ] PR 4 — Backend_HTTP.md 180 occurrence 전수 교체
- [ ] 통합 — `tools/naming_check.py` (PR 9) 실행 시 team2 violation = 0

---

## 7. 변경 영향 분석

| 영역 | team2 영향 | 외부 팀 영향 |
|------|------------|-------------|
| **Backend Pydantic 모델** | 69 class 리팩토링 | — |
| **Backend routers** | 17 파일 prefix + path + param 교체 | — |
| **Backend WebSocket** | publishers.py / lobby_handler.py event type + payload | team1 ws_dispatch / team4 CC consumer (PR 6, 7) |
| **Backend 문서** | Backend_HTTP.md / WebSocket_Events.md / Graphic_Editor_API.md | — |
| **Backend test** | 25 파일 assertion 교체 (234 snake_case field) | — |
| **Frontend Repository** | — | team1 HTTP client URL / field 업데이트 (PR 6) |
| **Frontend Freezed** | — | team1 19 entity × ~15 field = ~285 JsonKey (PR 5) |
| **CC Freezed + Repository** | — | team4 동일 (PR 7) |
| **Engine Payload** | — | team3 21 event payload 필드 (PR 8) |

---

## 8. Critical 체크포인트

1. **단독 배포 금지** — PR 3/4 가 main 에 merge 되면 team1/team4 consumer 가 깨짐. PR 5/6/7 와 **동일 배포 window**.
2. **Cut-over vs gradual** — 프로토타입 프로젝트 성격상 **cut-over** 방식. snake/camel 혼재 기간 최소화.
3. **DB column 보존** — SQLAlchemy/SQLModel column 은 snake_case 유지. API 계약 layer 에서만 변환.
4. **Backlog ID 보존** — `B-088`, `SG-008` 등 행정 식별자는 snake 아니라 hyphen + 숫자. 규약 scope 외.

---

## 9. 관련 문서

- Naming SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- B-088 마스터 백로그: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- Backend API: `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md`
- WS events: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`
- team2 Backlog 연계: `docs/2. Development/2.2 Backend/Backlog/B-068-*.md` (Sandbox 와 무관, 병행 진행 가능)

---

## 10. 변경 이력

| 날짜 | 변경 | 근거 |
|------|------|------|
| 2026-04-21 | 최초 작성 | 사용자 지시 — B-088 전수 검사 + 수정 계획 수립 |

---

## 11. notify

- **team1**: PR 5 (Freezed @JsonKey 전수 교체 + build_runner) / PR 6 (ws_dispatch PascalCase + Repository URL) — 본 계획서 §1.1, §1.2 measurement 참조
- **team4**: PR 7 (CC consumer 동일) — 본 계획서 §3, §4 참조
- **team3**: PR 8 (Engine OutputEvent payload 필드 camelCase) — 본 계획서 §3 참조
- **Conductor**: PR 9 (naming_check.py CI gate) — 본 계획서 §6 수락 기준 참조
