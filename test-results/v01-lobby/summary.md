# Cycle 10 — S2 Lobby hierarchy wire evidence

Run timestamp: 2026-05-12T12:45:52.514Z
Lobby base URL: http://localhost:3000
Login strategy: canvas-coordinate
Navigation: in-app pushState + popstate (page.goto reload disabled)

## BO endpoint chain
- GET /api/v1/series                         → 200
- GET /api/v1/series/1/events                → 200
- GET /api/v1/events/11/flights     → 200
- GET /api/v1/flights/18/tables      → 200
- GET /api/v1/events/12/flights     → 200

## KPI — distinct flights per event
- Event 11 flights: [18]
- Event 12 flights: [19]
- Distinct: **PASS**

## Screenshot evidence
- 01-series-list.png   — Series 목록 (로그인 직후 자동 진입)
- 02-event-list.png    — Series 1 events
- 03-flight-list.png   — Event 11 flights
- 04-table-list.png    — Flight 18 tables
- 05-player-view.png   — Players view
- 06-different-event-different-flight.png — Event 12 flights (KPI)

## Network log (api/v1 only)
- POST http://localhost:3000/api/v1/auth/login → 200
- GET http://localhost:3000/api/v1/auth/session → 200
- GET http://localhost:3000/api/v1/series → 200
- GET http://localhost:3000/api/v1/series/1/events → 200
- GET http://localhost:3000/api/v1/events/11/flights → 200
- GET http://localhost:3000/api/v1/flights/18/tables → 200
- GET http://localhost:3000/api/v1/flights/18/levels → 200
- GET http://localhost:3000/api/v1/players → 200
- GET http://localhost:3000/api/v1/events/12/flights → 200
