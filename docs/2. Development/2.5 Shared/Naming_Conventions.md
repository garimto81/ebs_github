---
title: Naming Conventions (EBS Shared SSOT)
owner: conductor
tier: contract
last-updated: 2026-04-21
source-of-truth: WSOP LIVE Confluence (1,361 pages mirror at `C:/claude/wsoplive/`)
---

# Naming Conventions — EBS 전역 네이밍 규약 SSOT

모든 팀(team1/2/3/4)이 참조하는 네이밍 규약 단일 정본. **원칙 1 (WSOP LIVE 정렬)** 에 따라 WSOP LIVE Confluence 의 규약을 **직접 준수**한다. 독립 규약 설계 금지.

> **금지**: 이 문서 외부에서 네이밍 규약을 독립적으로 재정의하는 것. API 문서·Backlog·Frontmatter 등에 대체 규약을 선언하면 본 문서를 근거로 정정한다.

> **사용자 지시 (2026-04-21)**: "PascalCase snake_case 등을 독립적으로 설계하지 말고 wsop live 규약을 그대로 따를것". 이전 `Auth_and_Session §4` 의 snake_case divergence 는 **원칙 1 위반** 으로 판정되어 취소되었다.

---

## 1. 대상 매트릭스 (v2 — 2026-04-21 divergence 취소)

| 계층 | WSOP LIVE 원본 | EBS 채택 | 증거 |
|------|---------------|:--------:|------|
| **WebSocket/SignalR event type** | PascalCase (`SeatInfo`, `HandStarted`) | **PascalCase** | `Signalr Service.md:27` `hubConnection.on('SeatInfo', ...)` |
| **JSON field name** (REST + WS payload) | camelCase (`accessToken`, `eventFlightId`, `tableId`, `seatNo`, `isFeatured`) | **camelCase** | `JsonSerialization 일원화.md` (CamelCaseNamingStrategy 전역), `Signalr Key Mapping.md` (필드명 실측) |
| **REST URL path** | PascalCase (`/SpotRegist/SendVerifyEmail`, `/QRPage/{id}`, `/Push`) | **PascalCase** | `APIs/Player App Api/*.md` 실측 |
| **URL path variable** | camelCase (`{eventFlightTransactionId}`) | **camelCase** | 동상 |
| **DB column** | snake_case (Postgres 관행) | **snake_case** | WSOP LIVE Backend PostgreSQL 관행 + EBS 동일 |
| **Enum value (wire format)** | PascalCase (WSOP LIVE C# enum 직렬화) | **PascalCase** | WSOP LIVE `Enum.md` 실측 필요 (후속 조사 B-088) |
| **Dart class / Flutter widget** | — | PascalCase | Flutter Lint (프레임워크 규약, 원칙 1 scope 외) |
| **Python class** | — | PascalCase | PEP 8 (원칙 1 scope 외) |
| **Python function/variable** | — | snake_case | PEP 8 (원칙 1 scope 외) |

**Divergence 0 원칙**: 원칙 1 적용 대상(WS event / JSON field / REST path) 은 **100% WSOP LIVE 직접 준수**. 언어/프레임워크 관행(Dart class PascalCase, Python function snake_case)은 원칙 1 scope 외이므로 divergence 라고 분류하지 않는다.

---

## 2. 변환 경계 (Boundary 규칙)

### 2.1 API 계약 vs 내부 구현

```
┌─────────────────────────────────────────────────────────────┐
│ 외부 API 계약 (원칙 1 강제) — camelCase / PascalCase         │
│                                                             │
│  REST Request/Response JSON:    camelCase                   │
│  WebSocket envelope + payload:  camelCase (payload 필드)   │
│  WebSocket type 필드:            PascalCase                 │
│  URL path:                       PascalCase                 │
│  Path variable:                  camelCase                  │
└─────────────────────────┬───────────────────────────────────┘
                          │ 변환 경계
                          │
┌─────────────────────────▼───────────────────────────────────┐
│ 내부 구현 (언어 관행) — 프레임워크 자유                       │
│                                                             │
│  Python variable:       snake_case                          │
│  Python class:          PascalCase                          │
│  Dart class:            PascalCase                          │
│  Dart variable:         camelCase                           │
│  DB column:             snake_case (Postgres 관행)          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Backend (team2) 변환 구현

Pydantic v2 `alias_generator` 로 내부 snake_case ↔ 외부 camelCase 자동 변환:

```python
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

class EbsBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,   # 내부에서는 snake_case 사용 가능
        from_attributes=True,
    )

class EventFlight(EbsBaseModel):
    event_flight_id: int       # 외부 JSON: eventFlightId
    table_count: int           # 외부 JSON: tableCount
    is_featured: bool          # 외부 JSON: isFeatured
```

SQLAlchemy 모델 컬럼은 snake_case 유지 (Postgres 관행). Pydantic 응답 모델에서 camelCase 로 변환.

### 2.3 Frontend (team1/team4) 변환 구현

Flutter Freezed `@JsonKey(name: 'camelCase')`:

```dart
@freezed
class EventFlight with _$EventFlight {
  const factory EventFlight({
    @JsonKey(name: 'eventFlightId') required int eventFlightId,
    @JsonKey(name: 'tableCount') required int tableCount,
    @JsonKey(name: 'isFeatured') @Default(false) bool isFeatured,
  }) = _EventFlight;
}
```

참고: 2026-04-21 현재 코드는 snake_case 기반. 마이그레이션 작업은 `B-088` (별건, 대형) 에서 진행.

---

## 3. WebSocket Event Type 상세 규약

### 3.1 필수 규칙

| 규칙 | 예시 | 금지 |
|------|------|------|
| **PascalCase** | `HandStarted`, `TableStatusChanged`, `ConfigChanged` | ~~`hand_started`~~, ~~`table.updated`~~, ~~`handStarted`~~ |
| **동사 과거분사 또는 명사** | `HandStarted` (과거), `ClockTick` (명사), `SeatInfo` (명사) | ~~`StartHand`~~ (명령형) |
| **도트 계층 표기 금지** | — | ~~`series.updated`~~ — 단일 식별자 사용 |
| **단수형** | `SeatUpdated` | ~~`SeatsUpdated`~~ |

### 3.2 Reply 메시지

Command response 는 HTTP status 의미체계 — 동일 PascalCase:
`Ack`, `Error`, `AuthFailed`, `TableNotFound`, `PermissionDenied`

---

## 4. 마이그레이션 현황 (2026-04-21 실측)

### 4.1 WS event type

team2 publisher 실 emit:
- **이미 PascalCase (9)**: `OperatorConnected`, `ConfigChanged`, `Ack`, `Error`, `AuthFailed`, `TableNotFound`, `PermissionDenied`, `OperatorDisconnected`, `OperatorConnected`
- **snake → PascalCase migrate 필요 (10)**: `clock_tick` → `ClockTick`, `clock_level_changed` → `ClockLevelChanged`, `clock_detail_changed` → `ClockDetailChanged`, `clock_reload_requested` → `ClockReloadRequested`, `tournament_status_changed` → `TournamentStatusChanged`, `blind_structure_changed` → `BlindStructureChanged`, `prize_pool_changed` → `PrizePoolChanged`, `stack_adjusted` → `StackAdjusted`, `skin_updated` → `SkinUpdated`, `event_flight_summary` → `EventFlightSummary`

team1 consumer `ws_dispatch.dart` 26 case + team4 CC consumer — 전면 PascalCase migrate 필요.

### 4.2 JSON field

**현재**: EBS 전역 snake_case (`event_flight_id`, `table_count`, `is_featured`)
**목표**: WSOP LIVE 직접 준수 camelCase (`eventFlightId`, `tableCount`, `isFeatured`)
**Scope**:
- team2 Backend Pydantic 모델 전체 (~50 class)
- team1 Flutter Freezed `@JsonKey` 전체 (19 entity × ~15 field = ~285 JsonKey)
- team4 CC Freezed 동일
- team3 Engine OutputEvent payload (21 event)
- 모든 API 계약 문서 (`Backend_HTTP.md`, `WebSocket_Events.md`, `Auth_and_Session.md`, `Overlay_Output_Events.md`) JSON 예시 전수 교체

이 규모 때문에 **별건 Backlog B-088** 로 분리. 본 문서는 **규약 확정만** 수행.

### 4.3 REST URL path

**현재**: kebab-case (`/hand-history`, `/blind-structures`, `/payout-structures`)
**목표**: PascalCase (`/HandHistory`, `/BlindStructures`, `/PayoutStructures`)
**Scope**: Backend_HTTP.md 180 endpoint 전수 교체 + Backend router + Frontend Repository

이 규모도 **B-088** 에 포함.

---

## 5. 실행 계획 — B-088 마스터

| PR | 소유 | 작업 | 의존 | 규모 |
|:--:|------|------|------|:---:|
| **0** | **Conductor** | 본 Naming_Conventions.md v2 확립 (WSOP LIVE 직접 준수 완전 선언) — **이 commit** | — | S |
| 1 | Conductor | `Auth_and_Session §4` snake_case 선언 제거 + camelCase 로 대체. `WebSocket_Events.md line 329` divergence 주석 제거. `BS_Overview.md §네이밍` 본 문서 pointer 로 축약 | PR 0 | M |
| 2 | team2 | Pydantic `alias_generator=to_camel` 전역 도입 + `populate_by_name=True` 검증. SQLAlchemy 컬럼은 snake 유지 | PR 1 | L |
| 3 | team2 | WS publisher 10 snake event → PascalCase migrate + JSON payload 필드 camelCase | PR 2 | M |
| 4 | team2 | REST path kebab → PascalCase (`/hand-history` → `/HandHistory` 등) | PR 2 | M |
| 5 | team1 | Freezed 모델 19 entity `@JsonKey(name: 'snake')` → `@JsonKey(name: 'camelCase')` 전수 교체 + build_runner 재생성 | PR 2 | L |
| 6 | team1 | `ws_dispatch.dart` PascalCase 통일 + Repository REST path 업데이트 | PR 3, 4, 5 | M |
| 7 | team4 | CC consumer 동일 적용 | PR 3, 4 | M |
| 8 | team3 | Engine OutputEvent payload 필드 camelCase (in-process 이지만 API-04 계약상 준수) | PR 2 | S |
| 9 | Conductor | `tools/naming_check.py` + CI gate (WS event / JSON field / REST path 자동 검증) | 전부 | M |

**예상 총 규모**: 대형 (수백 파일, 수천 라인). 프로토타입 프로젝트 성격상 cut-over 방식 (version 호환 불필요).

---

## 6. 예외 / 원칙 1 scope 외

### 6.1 JWT 토큰 type 값
`"access"`, `"refresh"`, `"password_reset"` (team2 `security/jwt.py`) — **JWT RFC 7519** spec 관행 lower_snake_case. 규약 예외.

### 6.2 DB column 이름
Postgres 관행 snake_case 유지. WSOP LIVE Backend 도 동일 (증거: `Signalr Key Mapping.md` app/web key 는 camelCase 이지만 DB 는 snake 로 추정 — 직접 확인 불가하지만 관행 일치). API 계약 layer 에서만 camelCase 변환.

### 6.3 언어별 관행
- Dart class = PascalCase (Flutter Lint)
- Dart variable = camelCase (DartConventions)
- Python class = PascalCase (PEP 8)
- Python function/variable = snake_case (PEP 8)

→ 모두 **내부 구현** 이며 외부 API 계약 표면에서는 camelCase/PascalCase 로 노출된다.

### 6.4 Backlog ID
`B-087`, `SG-008` 등 행정 식별자는 본 규약 scope 외.

---

## 7. 변경 이력

| 날짜 | 버전 | 변경 | 근거 |
|------|------|------|------|
| 2026-04-21 | v1.0 | 신규 작성 (WS PascalCase + JSON snake divergence 유지) | `wsoplive/` 실측 |
| 2026-04-21 | **v2.0** | **사용자 지시 정정** — JSON field / REST path / Path variable divergence 전면 취소. WSOP LIVE 규약 100% 직접 준수. 마이그레이션 계획 B-088 분리 | 사용자: "PascalCase snake_case 등을 독립적으로 설계하지 말고 wsop live 규약을 그대로 따를것" |

---

## 8. 관련 문서

- `docs/2. Development/2.5 Shared/BS_Overview.md` — 행동 명세 개요 (네이밍 snippet 은 본 문서 pointer 로 축약 필요)
- `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md §4` — **snake_case divergence 선언 취소 필요** (PR 1)
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §1` — WS event PascalCase 선언 (준수)
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md line 329` — divergence 주석 제거 필요 (PR 1)
- WSOP LIVE 증거:
  - `wsoplive/.../Signalr Service.md` (SignalR PascalCase event)
  - `wsoplive/.../JsonSerialization 일원화.md` (Backend CamelCaseNamingStrategy 전역)
  - `wsoplive/.../Signalr Key Mapping.md` (camelCase 필드 실측)
  - `wsoplive/.../APIs/Player App Api/*.md` (REST path PascalCase 실측)
