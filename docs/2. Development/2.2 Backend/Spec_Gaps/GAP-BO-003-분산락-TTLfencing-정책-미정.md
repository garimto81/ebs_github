---
id: GAP-BO-003
title: 분산락 TTL·fencing 정책 미정
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-003] 분산락 TTL·fencing 정책 미정

- **관찰**: IMPL-10 §4.1에서 `lock:table:{id}` Redis SET NX EX 10s + fencing token을 채택했으나, 정확한 TTL/fencing 생성 규칙·장애 시나리오별 동작은 team2 내부 구현 결정 사항.
- **참조**:
  - WSOP `Tables API.md` 동시성 보호 패턴
  - Redlock / fencing token 원칙 (Martin Kleppmann)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-05 §4.1에 `get_distributed_lock()` DI 추가 (`RedisDistributedLock(redis)` / `InMemoryLock`)
  2. ✅ IMPL-10 §4.1 에 자원별 락 키·TTL 매트릭스, 재시도 3회(10/50/200ms 백오프), lease 연장, fencing token 규칙 반영
  3. IMPL-05 §6.2 `LOCK_DEFAULT_TTL_S=10` 환경변수 등록
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.1 + IMPL-05 `get_distributed_lock` DI에 반영. 단위 테스트는 Phase 1 구현 시 추가.

---
