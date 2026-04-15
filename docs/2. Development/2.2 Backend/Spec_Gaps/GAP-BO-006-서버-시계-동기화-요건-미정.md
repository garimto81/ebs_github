---
id: GAP-BO-006
title: 서버 시계 동기화 요건 미정
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-006] 서버 시계 동기화 요건 미정

- **관찰**: 다중 BO 인스턴스가 좌석 할당 timestamp로 ordering하면 clock skew 위험. NTP 운영 기준이 명시되지 않음.
- **참조**: WSOP+ Architecture (모든 데이터 AWS California 단일 리전 — 시계 문제 최소화)
- **구현 가능성**: 가능 (team2 내부 + DevOps)
- **액션**: 완료
  1. ✅ IMPL-10 §4.3 — chrony/NTP 설치, offset < 100ms 유지, 드리프트 시 경보
  2. ✅ IMPL-10 §4.3 — 벽시계 사용 금지 규칙 (`datetime.now()` 금지, DB `created_at` monotonic 우선)
  3. ✅ 모든 API 응답에 `server_time` 필드 포함 (WebSocket envelope는 CCR-015로 `ts`/`server_time` 병기)
  4. DevOps NTP 모니터링 runbook은 Phase 1 운영 시작 시 추가 (별도 이슈)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.3 에 반영. DevOps runbook은 기획서 범위 밖.

---
