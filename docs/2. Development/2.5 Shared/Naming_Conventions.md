---
title: Naming Conventions (EBS Shared SSOT)
owner: conductor
tier: contract
last-updated: 2026-04-21
source-of-truth: WSOP LIVE Confluence (1,361 pages mirror at `C:/claude/wsoplive/`)
---

# Naming Conventions — EBS 전역 네이밍 규약 SSOT

모든 팀(team1/2/3/4)이 참조하는 네이밍 규약 단일 정본. **원칙 1 (WSOP LIVE 정렬)** 에 따라 WSOP LIVE Confluence 의 규약을 직접 인용하며, divergence 가 있는 경우 **근거를 명시**한다.

> **금지**: 이 문서 외부에서 네이밍 규약을 독립적으로 재정의하는 것. API 문서·Backlog·Frontmatter 등에 대체 규약을 선언하면 본 문서를 근거로 정정한다.

---

## 1. 대상 매트릭스

| 계층 | WSOP LIVE 원본 | EBS 채택 | 근거 |
|------|---------------|----------|------|
| **WebSocket/SignalR event type** | PascalCase (`SeatInfo`, `TableInfo`) | **PascalCase** ✅ 직접 준수 | WSOP LIVE 원본 규약 (SignalR hub method). `WsopSignalRConnector.md`, `Signalr Service.md` |
| **JSON field name** (REST + WS payload) | camelCase (`accessToken`, `eventFlightId`, `tableId`) | **snake_case** (divergence) | EBS `Auth_and_Session.md §4` (2026-04-13 결정): Python/FastAPI 생태계 정합. 변환 책임 = `API-01 Part II` UPSERT |
| **REST URL path** | PascalCase (`/SpotRegist/SendVerifyEmail`, `/QRPage/{id}`) | **kebab-case** (divergence) | EBS 관행 (`/hand-history`, `/blind-structures`). 원칙 1 재검토 대상 — Backlog `B-093` 신설 예정 |
| **URL path variable** | camelCase (`{eventFlightTransactionId}`) | **snake_case** (divergence) | JSON field 규약과 동일 (`{flight_id}`, `{table_id}`) |
| **Enum value** | 정본 부재 (code 확인 필요) | **lower snake** (`active`, `running`, `action_performed`) | DATA-03 State Machines 관행 |
| **Dart class / Flutter widget** | (해당 없음) | PascalCase | 프레임워크 규약 (Flutter Lint) |
| **Python class** | (해당 없음) | PascalCase | PEP 8 |
| **Python function/variable** | (해당 없음) | snake_case | PEP 8 |

**Divergence 표기 요약**: 3 계층에서 EBS 가 WSOP LIVE 와 다른 표기를 채택. 모두 **명시적 근거 문서** 와 연결되어 있다. 신규 divergence 추가 시 본 표 에 행 추가 + Conductor 승인 필수.

---

## 2. WebSocket Event Type 상세 규약 (B-087-2 해결)

### 2.1 필수 규칙

| 규칙 | 예시 | 금지 |
|------|------|------|
| **PascalCase** | `HandStarted`, `TableStatusChanged`, `ConfigChanged` | ~~`hand_started`~~, ~~`table.updated`~~, ~~`handStarted`~~ |
| **동사 과거분사 또는 명사** | `HandStarted` (과거), `ClockTick` (명사), `ConfigChanged` (과거) | ~~`StartHand`~~ (명령형 동사) |
| **도트 계층 표기 금지** | — | ~~`series.updated`~~, ~~`config.updated`~~ — 단일 식별자 사용 |
| **단수형** | `SeatUpdated` | ~~`SeatsUpdated`~~ |

### 2.2 Reply (Command Response) 메시지

클라이언트 command 에 대한 서버 응답은 HTTP status 와 의미적으로 유사하므로 동일 PascalCase 규약 적용:
`Ack`, `Error`, `AuthFailed`, `TableNotFound`, `PermissionDenied`

### 2.3 EBS 현재 상태 (2026-04-21 실측)

team2 publisher (`team2-backend/src/websocket/`) 실 emit 이벤트:

| 기존 이름 | 규약 준수 여부 | 정정 필요 |
|----------|:-------------:|-----------|
| `OperatorConnected`, `OperatorDisconnected`, `ConfigChanged`, `Ack`, `Error`, `AuthFailed`, `TableNotFound`, `PermissionDenied` | ✅ 준수 | — |
| `clock_tick`, `clock_level_changed`, `clock_detail_changed`, `clock_reload_requested`, `tournament_status_changed`, `blind_structure_changed`, `prize_pool_changed`, `stack_adjusted`, `skin_updated`, `event_flight_summary` | ❌ snake_case | **PascalCase 로 migrate** (`ClockTick`, `ClockLevelChanged`, ...) |

team1 consumer (`team1-frontend/lib/data/remote/ws_dispatch.dart`) 26 switch case 전부 **snake_case + dot.case 혼재** → PascalCase 로 통일 + dot.case 제거 + 중복 case 통합 (`skin.updated` + `skin_updated` → `SkinUpdated` 단일).

team4 CC consumer 동일 적용.

---

## 3. 실행 우선순위 (PR 체인)

| # | 소유 | 작업 | 의존 |
|:-:|------|------|------|
| 1 | **Conductor** | 본 Naming_Conventions.md 확립 + `WebSocket_Events.md line 329 divergence 주석` 정정 (근거 없음) + `BS_Overview.md §이벤트 네이밍` 본 문서 pointer 로 축약 | — |
| 2 | **team2** | Publisher backend `.py` snake_case 10개 이벤트 → PascalCase migrate | PR 1 |
| 3 | **team1** | `ws_dispatch.dart` switch case PascalCase 통일 + dot.case 제거 + 중복 정리 | PR 1, 2 동시 또는 차례 |
| 4 | **team4** | CC consumer 동일 | PR 1, 2 |
| 5 | **Conductor** | `tools/ws_naming_check.py` + CI gate (lint) — 재발 방지 | PR 1 |

본 commit 은 PR 1 의 절반 (Naming_Conventions.md SSOT 확립). `WebSocket_Events.md line 329` 정정은 team2 publisher 영역이므로 notify 로 인계.

---

## 4. 예외 / 관찰

### 4.1 JWT 토큰 type 값
`"access"`, `"refresh"`, `"password_reset"` (team2 `security/jwt.py`) — **JWT 토큰 내부 필드** 이지 WebSocket event type 이 아님. RFC 7519 (JWT spec) 관행으로 lower case. 규약 예외.

### 4.2 SignalR → WebSocket 전환
WSOP LIVE 는 SignalR hub (C# .NET), EBS 는 순수 WebSocket (Python FastAPI). **전송 프로토콜** 은 divergence (SignalR → raw WS). 하지만 **message naming convention** 은 원칙 1 준수로 PascalCase 유지.

### 4.3 기존 Backlog 명명
EBS Backlog 항목 ID (`B-087`, `SG-008` 등) 는 본 문서 scope 외 (행정 식별자).

---

## 5. 변경 이력

| 날짜 | 버전 | 변경 | 근거 |
|------|------|------|------|
| 2026-04-21 | v1.0 | 신규 작성. B-087-2 (WS 네이밍 drift) 해결. WSOP LIVE 규약 전수 조사 기반 | `wsoplive/docs/confluence-mirror/` 실측 |

---

## 6. 관련 문서

- `docs/2. Development/2.5 Shared/BS_Overview.md` — 행동 명세 개요 (네이밍 snippet 은 본 문서 pointer 로 축약)
- `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md §4` — JSON field snake_case divergence 결정 원본
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §1` — WS event PascalCase 선언 (준수)
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md line 329` — 정정 필요 (snake_case divergence 근거 부재)
- `wsoplive/docs/confluence-mirror/WSOP Live 홈/2. Development/Frontend/STAFF Achitecture/Staff - Services/Signalr Service.md` — SignalR event naming 원본
- `wsoplive/docs/confluence-mirror/WSOP Live 홈/2. Development/Backend/JsonSerialization 일원화.md` — WSOP LIVE JSON camelCase 원본
