---
id: GAP-BO-005
title: Redis 캐시 TTL 및 Pub/Sub 무효화 전략 미정
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-005] Redis 캐시 TTL 및 Pub/Sub 무효화 전략 미정

- **관찰**: IMPL-10 §5에서 Redis 3계층 캐시(table/player/tournament)를 채택했으나, TTL 수치·무효화 이벤트 채널 이름·멀티 워커 전파 규칙이 구체화 안 됨.
- **참조**: WSOP+ Architecture (Redis Cache — Player/Staff/Tournament 분리)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §5.1 캐시 키 체계 표 — `table:{id}` 5min, `table:list:{event_flight_id}` 2min, `player:{id}` 10min, `tournament:{id}` 30min, `blinds:{event_flight_id}` 1h, `config:global` 1h
  2. ✅ IMPL-10 §5.2 Write-Through + Invalidate-on-Write 규칙 + Pub/Sub 채널 `cache:invalidate:{entity}` 표준
  3. ✅ IMPL-10 §5.3 캐시 실패 격리 (CB OPEN → DB 직접 조회)
  4. ✅ IMPL-05 `get_redis()` DI 등록
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §5 전체 + IMPL-05 `get_redis` DI 에 반영.

---
