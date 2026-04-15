---
id: GAP-BO-009
title: WSOP LIVE 폴링 서킷브레이커 임계값 미정
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-009] WSOP LIVE 폴링 서킷브레이커 임계값 미정

- **관찰**: BO-02 동기화 프로토콜에 폴링 실패 시 동작이 "재시도" 수준으로만 기술됨. 서킷브레이커 임계값(실패율, 윈도우, 복구 시간)이 없음.
- **참조**: WSOP `APIGW.md` (외부 API 라우팅), 일반적 Hystrix/resilience4j 기본값
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §3.3 — CLOSED/OPEN/HALF_OPEN 상태 전이, 실패율 50%/20 req window/30s OPEN/HALF_OPEN 1 req 시범
  2. ✅ IMPL-10 §3.3 — Fallback `sync:wsop:pending` Redis Stream
  3. ✅ BO-02 §7.1 — 장애 대응 매트릭스(OPEN/HALF_OPEN/CLOSED 복귀) + Fallback Queue cursor 기반 delta 재처리 상세
  4. ✅ IMPL-05 §4.1 `get_circuit_breaker(name)` + `get_wsop_live_client()` DI
  5. ✅ IMPL-05 §6.2 `CB_FAILURE_RATIO=0.5` / `CB_WINDOW_SIZE=20` / `CB_OPEN_DURATION_S=30` 환경변수
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.3 + BO-02 §7.1 + IMPL-05 DI/환경변수에 전면 반영.

---
