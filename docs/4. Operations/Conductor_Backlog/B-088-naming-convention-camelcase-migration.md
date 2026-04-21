---
id: B-088
title: "Naming Convention camelCase 전면 마이그레이션 (WSOP LIVE 직접 준수)"
status: PENDING
source: docs/2. Development/2.5 Shared/Naming_Conventions.md v2
created: 2026-04-21
owner: conductor
priority: P1
scope: cross-team (all 4 teams)
---

# B-088 — camelCase/PascalCase 전면 마이그레이션 (WSOP LIVE 직접 준수)

## 배경

2026-04-21 사용자 지시: **"PascalCase snake_case 등을 독립적으로 설계하지 말고 wsop live 규약을 그대로 따를것"**

WSOP LIVE 규약 전수 조사 결과:
- WS event type = PascalCase (`SeatInfo`)
- JSON field = camelCase (`eventFlightId`, `tableCount`, `isFeatured`)
- REST path = PascalCase (`/SpotRegist/SendVerifyEmail`)
- Path variable = camelCase (`{eventFlightTransactionId}`)

EBS 현재 상태:
- WS event: PascalCase + snake 혼재 (team2 backend 9:10)
- JSON field: **전 계약 snake_case** (`event_flight_id`) — 원칙 1 위반
- REST path: **전 계약 kebab-case** (`/hand-history`) — 원칙 1 위반
- Path variable: **snake_case** (`{flight_id}`) — 원칙 1 위반

→ 전면 마이그레이션 필요.

## 규약 SSOT

`docs/2. Development/2.5 Shared/Naming_Conventions.md` v2 (2026-04-21 확립)

## PR 체인 (9 단계)

| PR | 소유 | 작업 | 의존 | 규모 |
|:--:|------|------|------|:---:|
| 0 | Conductor | Naming_Conventions.md v2 확립 | — | S ✅ DONE |
| **1** | **Conductor** | `Auth_and_Session §4` snake_case 선언 제거 + camelCase 로 대체 / `WebSocket_Events.md line 329` divergence 주석 제거 / `BS_Overview §네이밍` 본 문서 pointer 로 축약 | PR 0 | M |
| 2 | team2 | Pydantic v2 `alias_generator=to_camel` + `populate_by_name=True` 전역 도입. SQLAlchemy column 은 snake_case 유지 (Postgres 관행) | PR 1 | L |
| 3 | team2 | WS publisher — snake 10 event → PascalCase, payload 필드 camelCase | PR 2 | M |
| 4 | team2 | REST path kebab → PascalCase 전수 (`/hand-history` → `/HandHistory` 등 180 endpoint) | PR 2 | M |
| 5 | team1 | Freezed 19 entity `@JsonKey(name: 'snake_case')` → `'camelCase'` 전수 교체 + `dart run build_runner build` | PR 2 | L |
| 6 | team1 | `ws_dispatch.dart` switch case PascalCase 통일 + Repository REST path 업데이트 | PR 3, 4, 5 | M |
| 7 | team4 | CC consumer 동일 적용 (ws + REST + Freezed) | PR 3, 4 | M |
| 8 | team3 | Engine OutputEvent payload 필드 camelCase (API-04 계약 준수) | PR 2 | S |
| 9 | Conductor | `tools/naming_check.py` + CI gate (WS event / JSON field / REST path / Path variable 자동 검증) | 전부 | M |

## 수락 기준

- [x] PR 0: Naming_Conventions.md v2 존재
- [ ] PR 1: Auth_and_Session §4 / WebSocket_Events line 329 / BS_Overview §네이밍 정정
- [ ] PR 2: team2 Pydantic alias_generator 전역 도입
- [ ] PR 3: WS publisher snake 10 → PascalCase
- [ ] PR 4: REST path kebab → PascalCase (180 endpoint)
- [ ] PR 5: team1 Freezed @JsonKey 전수 교체
- [ ] PR 6: team1 ws_dispatch + Repository
- [ ] PR 7: team4 CC consumer
- [ ] PR 8: team3 Engine OutputEvent payload
- [ ] PR 9: CI naming gate

## 리스크 & 완화

| 리스크 | 완화 |
|--------|------|
| **대규모 breaking change** — 전 API 계약 동시 변경 | 프로토타입 프로젝트 성격 (production 호환 불필요) → cut-over 방식. 중간 상태 (snake/camel 혼재) 최소화 |
| **DB column vs API field 변환 누락** | Pydantic `alias_generator=to_camel` + `populate_by_name=True` 전역 설정으로 자동 변환. 수동 JSON dict 조작 금지 |
| **Mock fixture 대량 교체** | `mock_data.dart` / pytest fixtures 도 camelCase 로 교체 (PR 5, 2 범위) |
| **문서 JSON 예시 수백 블록** | grep `"event_flight_id":` → `"eventFlightId":` 스크립트 일괄 변환 + 수동 검수 |
| **Integration test .http 시나리오** | integration-tests/ 폴더 `.http` 파일 JSON body 교체 (PR 2/3/4 와 동시) |
| **외부 팀 영향** | EBS 외부에는 아직 인계 안 됨 (프로토타입 단계) — 외부 영향 없음 |

## 예상 소요

- 프로토타입 프로젝트 규모 고려: **1-2 세션 집중 작업** 으로 완료 가능 추정
- Pydantic alias_generator 는 Backend 전역 1회 설정 후 자동 동작 → 수동 필드 교체 최소화
- Frontend Freezed `@JsonKey` 는 파일 19개 × field 200+ → sed 일괄 변환 후 build_runner 재생성

## 원칙 1 정합성

본 마이그레이션 완료 시:
- WS event = PascalCase ✅
- JSON field = camelCase ✅
- REST path = PascalCase ✅
- Path variable = camelCase ✅
- Enum value (wire) = PascalCase ✅ (B-088 이후 확인)

→ **Divergence 0** 달성. 원칙 1 완전 준수.

## 관련

- Naming_Conventions.md v2: `docs/2. Development/2.5 Shared/Naming_Conventions.md`
- 선행 결정 취소: Auth_and_Session §4 (2026-04-13 snake_case divergence — 취소)
- B-087-2 에서 분기된 마스터 항목
