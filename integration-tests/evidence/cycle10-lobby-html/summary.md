# Cycle 10 — Lobby 5-Screen E2E Evidence (hosts-free)

Run timestamp: 2026-05-12T13:21:10.397Z
Lobby base URL: http://localhost:3000
Login strategy: canvas-coordinate
Navigation: in-app hashchange + popstate (page.goto reload 회피)
host-resolver-rules: 미설정 (hosts 매핑 부재 환경)

## DoD
- hosts-free (api.ebs.local 호출 0건): **PASS** (got 0)
- same-origin /api/v1/* 호출 ≥ 1: **PASS** (got 10)
- 5 계층 endpoint 200 hit:
  - auth/login: PASS
  - /series: PASS
  - /series/{id}/events: PASS
  - /events/{id}/flights (main): PASS
  - /flights/{id}/tables: PASS
- 이벤트 분기 — distinct event_id ≥ 2 in flight calls: **PASS** (14, 11, 1)
- 이벤트 분기 — Main vs Branch A 의 flight id 가 서로 다름: **PASS** (main=[6,7,8] branchA=[18])

## Endpoint chain
- GET /api/v1/series                                  → 200
- GET /api/v1/series/1/events                         → 200 (events=[11,12,13,14])
- GET /api/v1/events/14/flights           → 200 (flights=[6,7,8])
- GET /api/v1/flights/6/tables          → 200
- GET /api/v1/events/11/flights        → 200 (flights=[18])
- GET /api/v1/series/2/events                         → 200 (events=[1,2,3,4,5,6,7,8,9,10])
- GET /api/v1/events/1/flights        → 200 (flights=[9])

## Screenshot evidence
- 00-login.png                Login UI (Phase 0)
- 01-series.png               Series 목록
- 02-events.png               Series 1 events (4 개)
- 03-flights.png              Event 14 flights (3 개)
- 04-tables.png               Flight 6 tables
- 03b-flights-evt11.png   분기 검증 A (event 11 → 1 flights)
- 03c-flights-evt1.png   분기 검증 B (series 2 event 1 → 1 flights)

## Network log (api/v1 + api.ebs.local)
- [00-login] POST http://localhost:3000/api/v1/auth/login → 200
- [00-login] GET http://localhost:3000/api/v1/auth/session → 200
- [00-login] GET http://localhost:3000/api/v1/series → 200
- [02-events] GET http://localhost:3000/api/v1/series/1/events → 200
- [03-flights] GET http://localhost:3000/api/v1/events/14/flights → 200
- [04-tables] GET http://localhost:3000/api/v1/flights/6/tables → 200
- [04-tables] GET http://localhost:3000/api/v1/flights/6/levels → 200
- [03b-flights-evt-branch-a] GET http://localhost:3000/api/v1/events/11/flights → 200
- [03c-flights-evt-branch-b] GET http://localhost:3000/api/v1/series/2/events → 200
- [03c-flights-evt-branch-b] GET http://localhost:3000/api/v1/events/1/flights → 200
