---
id: GAP-BO-004
title: WebSocket 이벤트 순번(seq) 및 replay 엔드포인트 부재
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-004] WebSocket 이벤트 순번(seq) 및 replay 엔드포인트 부재

- **관찰**: `contracts/api/API-05` 는 이벤트 envelope에 순번을 갖지 않음. WebSocket 재연결 후 놓친 이벤트를 복구할 수단 없음.
- **참조**:
  - WSOP+ Architecture (SignalR + MSK 이벤트 스트림)
  - `Action History.md` EventFlightHistory 기반 조회
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-015 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-015-websocket-이벤트에-단조증가-seq-필드-replay-엔드포인트-추가.md`. 정본은 `contracts/api/API-05 §envelope` (`seq`/`server_time`) + `contracts/api/API-01 §replay` (`GET /tables/{id}/events?since={seq}`)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.2, IMPL-07 §2.3, BO-03 §4.1 에 구현 가이드 반영됨

---
