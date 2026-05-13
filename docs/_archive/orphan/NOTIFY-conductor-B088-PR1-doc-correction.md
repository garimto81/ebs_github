---
id: NOTIFY-conductor-B088-PR1
title: "B-088 PR-1 — 기존 divergence 선언 정정 (Conductor 영역)"
status: OPEN
created: 2026-04-21
from: team1 (B-088 PR-5 선행 알림)
target: conductor
priority: P1 (다른 PR 블로킹)
---

# NOTIFY → Conductor: B-088 PR-1 문서 정정 필요

team1 에서 B-088 PR-5 (Flutter Freezed @JsonKey camelCase 전환) 를 선행 수행함. Backend/다른 팀 작업 진입 전에 Conductor 영역 문서 정정이 필요합니다.

## 정정 대상

### 1. `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md §4`

**현재 (2026-04-13 선언)**:
```
모든 JSON 응답 필드는 **snake_case** 를 사용한다.
- WSOP LIVE API 는 camelCase ... EBS는 Python/FastAPI 생태계에 맞춰 snake_case 로 통일한다.
- 클라이언트(team1 Lobby, team4 CC)는 항상 snake_case 기준으로 구현한다.
```

**정정 (2026-04-21 사용자 지시)**:
```
모든 JSON 응답 필드는 camelCase 를 사용한다 (WSOP LIVE 직접 준수).
- WSOP LIVE API 와 동일 형식: accessToken, eventFlightId, tableCount, isFeatured
- Backend: Pydantic alias_generator=to_camel + populate_by_name=True 로 내부 snake_case ↔ 외부 camelCase 자동 변환
- 클라이언트(team1 Lobby, team4 CC)는 항상 camelCase 기준 @JsonKey 사용
- 상세: docs/2. Development/2.5 Shared/Naming_Conventions.md §2 Boundary 규칙
```

### 2. `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md line 329`

**현재**:
```
> SSOT: Confluence Page 1793328277 (SignalR Service). 의도적 divergence: SignalR→순수 WebSocket 2 엔드포인트, CamelCase→snake_case + 동작형 suffix(`_changed`, `_requested`).
```

**정정**:
```
> SSOT: Confluence Page 1793328277 (SignalR Service). 의도적 divergence: SignalR→순수 WebSocket 2 엔드포인트 (전송 프로토콜만). Event type 네이밍은 WSOP LIVE PascalCase 직접 준수 (예: SeatInfo, HandStarted, ClockTick). Payload 필드는 camelCase 직접 준수.
```

### 3. `docs/2. Development/2.5 Shared/BS_Overview.md §네이밍` (line 270 부근)

**현재**:
```
모든 시스템 이벤트는 PascalCase + 동사 과거분사 패턴을 따른다.
```

**정정 (축약 + pointer)**:
```
네이밍 규약은 `docs/2. Development/2.5 Shared/Naming_Conventions.md` 가 SSOT. 본 문서는 요약만 기재.
- WS event type: PascalCase
- JSON field: camelCase
- REST path: PascalCase
```

## 실행 조건

- v7 free_write 하에서 Conductor 세션이 직접 편집
- 본 commit 은 team1 이 B-088 PR-5 로 Freezed 를 camelCase 전환했음을 Backend 팀이 알기 전에 수행되어야 함 (team2 PR-2 선행 블로커)

## 수락 기준

- [ ] Auth_and_Session.md §4 camelCase 로 재작성
- [ ] WebSocket_Events.md line 329 정정
- [ ] BS_Overview.md §네이밍 pointer 로 축약
- [ ] `docs/2. Development/2.5 Shared/Naming_Conventions.md` 를 참조하도록 인덱스 갱신 (`_generated/`)

## 관련

- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- 선행 team1 작업: 본 session commit (Freezed @JsonKey camelCase 전환)
