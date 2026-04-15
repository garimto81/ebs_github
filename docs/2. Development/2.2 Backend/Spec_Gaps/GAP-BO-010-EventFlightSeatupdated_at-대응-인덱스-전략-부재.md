---
id: GAP-BO-010
title: EventFlightSeat.updated_at 대응 인덱스 전략 부재
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-010] EventFlightSeat.updated_at 대응 인덱스 전략 부재

- **관찰**: WSOP DB 설명에서 `EventFlightSeat.UpdatedAt` 미인덱스 시 좌석 변경 쿼리가 full scan 위험. EBS DATA-04의 좌석 테이블에 동등 패턴 필요.
- **참조**: WSOP+ Database 설명 (EventFlightSeat, JSON BlindJson 파싱 오버헤드)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §8.2 인덱스 전략 표 — `table_seats(updated_at)`, `table_seats(table_id, seat_no) unique`, `hands(table_id, started_at DESC)`, `audit_logs(created_at DESC)`, `audit_logs(user_id, created_at)`, `audit_events(table_id, seq DESC) unique`, `audit_events(correlation_id)`, `audit_events(event_type, created_at)`, `idempotency_keys(user_id, key) unique`, `idempotency_keys(expires_at)`
  2. ✅ `src/db/init.sql` — `audit_events` / `idempotency_keys` 인덱스 실제 DDL 생성 (CCR-001 반영, 작업 #16)
  3. 실 운영 EXPLAIN 모니터링 runbook은 Phase 1 운영 시작 시 추가 (별도 이슈)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §8.2 + init.sql 반영. `table_seats(updated_at)` 실제 DDL은 GAP-BO-011 전면 동기화 시점에 생성 (core 엔티티 동기화 작업).

---
