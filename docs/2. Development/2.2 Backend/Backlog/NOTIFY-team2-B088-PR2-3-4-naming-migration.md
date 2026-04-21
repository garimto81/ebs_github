---
id: NOTIFY-team2-B088-PR2-3-4
title: "B-088 PR-2/3/4 — Backend camelCase 전환 (Pydantic + WS publisher + REST path)"
status: OPEN
created: 2026-04-21
from: team1 (B-088 PR-5 선행 알림)
target: team2
priority: P1 (team1 코드 기 camelCase 전환 완료 → Backend 응답이 snake_case 인 동안 실 BO 연결 불가)
---

# NOTIFY → team2: B-088 camelCase 마이그레이션 Backend 파트

team1 이 B-088 PR-5 (Freezed @JsonKey camelCase 전환 + MockDioAdapter camelCase 전환) 를 선행 완료했습니다. 실 BO 연결 시 API 응답 파싱이 실패하므로 team2 PR-2/3/4 수행 필요.

## 현재 상태 (team1 side)

- `lib/models/entities/*.dart` 17 파일 — `@JsonKey(name: 'camelCase')` 전수 적용 (163 개 교체)
- `lib/data/local/mock_data.dart` — JSON fixture camelCase (20 개 교체)
- `lib/data/local/mock_dio_adapter.dart` — query params + response camelCase (44 개 교체)
- `test/integration/model_parse_test.dart` — JSON fixture camelCase (158 개 교체)
- `flutter analyze`: 0 errors
- Mock 환경 (`USE_MOCK=true`) : 동작 확인 완료

## Backend 필요 작업 (PR-2/3/4)

### PR-2 (우선순위 최상): Pydantic alias_generator 전역 도입

```python
# team2-backend/src/models/base.py (신규 파일 권장)
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

class EbsBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,   # 내부 snake_case 사용 허용
        from_attributes=True,    # SQLAlchemy ORM 지원
    )
```

**전환 대상**: `team2-backend/src/models/schemas.py` 등 Pydantic BaseModel 상속 전 class 를 `EbsBaseModel` 로 변경.

**중요**:
- SQLAlchemy ORM 컬럼 (`team2-backend/src/models/competition.py` 등) 은 **snake_case 유지** (Postgres 관행)
- 변환은 Pydantic 직렬화 layer 에서만 발생

**검증**:
- `GET /api/v1/series` 응답 body 가 `{"seriesId": 1, "competitionId": 1, ...}` 로 camelCase 인지 확인
- team1 Flutter 앱 실 BO 연결 (`USE_MOCK=false`) 해서 Lobby 대시보드 동작 검증

### PR-3: WS publisher event type PascalCase + payload camelCase

`team2-backend/src/websocket/publishers.py` 와 `lobby_handler.py` 의 snake_case event 10 개:

| 기존 | 정정 |
|------|------|
| `clock_tick` | `ClockTick` |
| `clock_level_changed` | `ClockLevelChanged` |
| `clock_detail_changed` | `ClockDetailChanged` |
| `clock_reload_requested` | `ClockReloadRequested` |
| `tournament_status_changed` | `TournamentStatusChanged` |
| `blind_structure_changed` | `BlindStructureChanged` |
| `prize_pool_changed` | `PrizePoolChanged` |
| `stack_adjusted` | `StackAdjusted` |
| `skin_updated` | `SkinUpdated` |
| `event_flight_summary` | `EventFlightSummary` |

이미 PascalCase 인 9개(`Ack`, `Error`, `ConfigChanged`, `OperatorConnected` 등) 는 변경 없음.

Payload 필드는 camelCase (PR-2 의 Pydantic 변환 자동 적용).

### PR-4: REST path kebab-case → PascalCase

`team2-backend/src/routers/*.py` 의 router path 전수 교체:

| 기존 | 정정 | 영향 |
|------|------|------|
| `/api/v1/hand-history` | `/api/v1/HandHistory` | reports feature |
| `/api/v1/blind-structures` | `/api/v1/BlindStructures` | settings |
| `/api/v1/payout-structures` | `/api/v1/PayoutStructures` | settings |
| `/api/v1/audit-logs` | `/api/v1/AuditLogs` | reports |
| (kebab 모두 해당) | (PascalCase) | 전체 |

Path variable (`{flight_id}` → `{flightId}`) 도 동시 교체.

**전환 후 알림**: team1/team4 에 완료 알림 (Repository 전수 교체 필요).

## Migration 완료 검증 체크리스트 (team2)

- [ ] Pydantic `EbsBaseModel` 도입 + 전 BaseModel 상속 class 치환
- [ ] pytest 전체 0 errors (기존 테스트 camelCase 대응 확인)
- [ ] WS publisher 10 event PascalCase 전환
- [ ] REST path kebab → PascalCase 전수
- [ ] `Backend_HTTP.md` 문서 JSON 예시 + path 전수 camelCase/PascalCase 교체
- [ ] `WebSocket_Events.md` 문서 event 이름 정정 + payload camelCase 예시

## 관련

- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- 의존 선행: NOTIFY-conductor-B088-PR1 (Auth_and_Session §4 정정) 동시 또는 먼저
