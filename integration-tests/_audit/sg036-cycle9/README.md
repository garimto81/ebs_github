# SG-036 Cycle 9 — .http vs BO router 정밀 mismatch 분석

**Date**: 2026-05-12
**Owner**: S9 QA Stream
**Branch**: `work/s9/cycle9-2026-05-12`
**Issue**: SG-036 (Spec_Gap_Registry §4.5)

## 결론 (TL;DR)

| 지표 | 1차 추정 (#241, Cycle 2) | 정밀 측정 (Cycle 9) | 변화 |
|------|:----------------------:|:---------------------:|:----:|
| `.http` unique endpoints | 53 | **59** | +6 |
| BO router unique endpoints | 137 | **137** | 0 |
| router coverage (.http 가 호출) | (미측정) | **27 / 137 = 19.7%** | — |
| uncovered routers (path/method 다름) | 84 (path diff) | **110** | +26 |
| orphan `.http` (router 미존재) | 8 (RBAC/header drift) | **26** | +18 |
| **총 mismatch** | **92** | **136** | **+44** |

> 1차 92 추정은 단순 path diff + RBAC/header drift 합계. 정밀 측정은 method-aware 매칭 (regex param 치환) + auth router prefix 보정 (`auth_router.prefix=/auth` + main.py `include_router(prefix=/api/v1)` → 최종 `/api/v1/auth/*`) 적용.

## 우선순위 분류 (110 uncovered)

| Priority | Label | 카운트 | 비고 |
|:--------:|-------|:------:|------|
| **P1** | core CRUD list/create/read/update/delete | **51** | 사용자/운영 직접 영향 |
| └ P1-core-list | 기본 list (`GET /api/v1/{resource}`) | 9 | Lobby/CC 진입 직후 호출 |
| └ P1-core-read | 기본 read-by-id | 10 | item 상세 |
| └ P1-core-create | 기본 create | 7 | admin 등록 작업 |
| └ P1-core-update | PUT/PATCH/DELETE 단일 entity | 25 | 수정/삭제 |
| **P2** | auth/audit/settings | **16** | 보안/감사 critical |
| └ P2-auth-2fa | 2FA + password reset | 9 | admin 보안 |
| └ P2-audit | audit-events + audit-logs | 3 | 감사 추적 |
| └ P2-settings | settings KV | 4 | 운영 설정 |
| **P3** | reports/sync | **13** | 분석/통합 |
| └ P3-reports | dashboard 6종 | 6 | 운영 대시보드 |
| └ P3-sync | WSOP LIVE sync | 7 | 외부 통합 |
| **P4** | clock/seats/skin-action 등 advanced | **30** | 게임 진행 액션 |
| └ P4-clock | flights clock (start/pause/resume/restart) | 9 | 게임 시계 제어 |
| └ P4-blind-levels | blind-structures levels 서브 | 3 | FT 진행 |
| └ P4-seats | tables seats CRUD | 2 | 좌석 배정 |
| └ P4-flight-tables | flights tables/blind-structure 서브 | 4 | flight 관계 |
| └ P4-table-status | tables status/events | 2 | 상태 조회 |
| └ P4-hand-detail | hand actions/players 서브 | 2 | hand 상세 |
| └ P4-skin-action | skin upload/activate/deactivate | 3 | 그래픽 |
| └ P4-player-search | player search | 1 | 검색 |
| └ P4-flight-cancel-complete | flight cancel/complete | 2 | flight 종료 |
| └ P4-series-events | series events 서브 | 2 | series 관계 |
| └ P4-event-flights | events flights 서브 | 1 | events 관계 |
| └ P4-event-flights-list | flights levels list | 1 | level 목록 |
| └ P4-user-force-logout | users force-logout | 1 | 강제 로그아웃 |

## Orphan .http (26건 — 진성 spec drift)

router에 존재하지 않는데 .http가 호출하는 endpoint. 두 카테고리:

### A. Engine API (정상, 분류 외)

BO가 아니라 team3-engine 또는 team4-cc 가 처리:

- `GET /api/session`, `POST /api/session`, `POST /api/session//event`, `POST /api/session//next-hand`
- `GET /api/v1/_mock/overlay/last-frame` (overlay mock)
- `POST /api/v1/_mock/rfid/scan` (rfid mock)
- `GET /api/variants` (variants service)
- `GET /health` (health check, 모든 stream 공통)

### B. 진성 drift — BO 미구현 endpoint (`.http`가 future-spec)

| Path | Method | 추정 출처 |
|------|:------:|----------|
| `/api/v1/skins/{}/metadata` | GET | skin metadata 조회 미구현 |
| `/api/v1/tables/{}/output-config` | GET, PATCH | output config 미구현 |
| `/api/v1/tables/{}/delay-buffer-status` | GET | delay buffer 미구현 |
| `/api/v1/tables/{}/state` | GET | table state snapshot 미구현 |
| `/api/v1/tables/{}/replay-events` | POST | replay 트리거 미구현 |
| `/api/v1/sagas/{}` | GET, POST `/rollback` | saga 조회/롤백 미구현 |
| `/api/v1/flights/{}/late-reg-remaining` | GET | late-reg 조회 미구현 |

### C. Method drift (Type D, router ↔ .http 불일치)

| Path | router method | `.http` method |
|------|:-------------:|:--------------:|
| `/api/v1/tables/{}` | PUT | PATCH |
| `/api/v1/tables/{}/active_deck` | PUT | PATCH |
| `/api/v1/flights/{}` | PUT | PATCH |
| `/api/v1/blind-structures` | POST (create) | DELETE (RBAC fail expected) |
| `/api/v1/blind-structures/{}/levels` | POST + PUT + DELETE 모두 router 에 존재 | `.http` 의 DELETE 가 path-param empty (`//levels`) 형태로 매칭 실패 |

> Method drift는 BO를 truth로 보고 `.http`를 정합화하거나, 반대로 RESTful PATCH convention을 따르도록 BO 보강 결정 필요. 본 cycle은 측정만, 결정은 후속.

## 처리 계획 (Cycle 9-12 분할)

| Cycle | 범위 | endpoint 수 | PR 예상 |
|:-----:|------|:-----------:|--------|
| **9 (이번)** | P1 list/create top-10 | **10** | 1 PR (본) |
| 10 | P1-core-read 10 + P1-core-update 잔여 11 | 21 | 1-2 PR |
| 11 | P1-core-update 잔여 14 + P2 auth-2fa 9 | 23 | 2 PR |
| 12 | P2 audit/settings 7 + P3 reports/sync 13 | 20 | 2 PR |
| 13 | P4 clock 9 + P4 advanced 21 | 30 | 2-3 PR |
| 14 | Orphan B (진성 drift 14) + Method drift C (5) | 19 | spec ↔ code 결정 PR |

총 6 cycle 예상 (10+21+23+20+30+19 = 123, P1~P4 110 + Orphan B/C 13 = 123).

## 재현 명령

```bash
# .http endpoints 추출
python integration-tests/_audit/sg036-cycle9/extract_http_endpoints.py

# router endpoints 추출
python integration-tests/_audit/sg036-cycle9/extract_router_endpoints.py

# 정밀 mismatch 분석
python integration-tests/_audit/sg036-cycle9/mismatch_analyze.py

# 우선순위 분류
python integration-tests/_audit/sg036-cycle9/classify_priority.py
```

## 산출물

- `http_endpoints.json` — `.http` 180 raw 요청 + 59 unique (method, path) 추출
- `router_endpoints.json` — BO 137 router (FastAPI route decorator AST 분석)
- `mismatch_result.json` — covered/uncovered/orphan 분류
- `priority_classified.json` — 110 uncovered의 P1~P4 분류 JSON
- `priority_report.txt` — 우선순위별 상세 endpoint 리스트

## Iron Law 준수

- **Core Philosophy**: top-10만 .http 보강 — over-engineering 회피 (사용자 결정 영역 아닌 측정 영역)
- **Visual-First**: 표 + 카테고리 ↑↑/↑ 표기로 우선순위 시각화
- **Backlog 캡처**: Spec_Gap_Registry §4.5 갱신으로 PENDING → IN_PROGRESS 반영
