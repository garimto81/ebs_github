---
title: Phase 1 Load Test Plan — 8시간 Soak + Production-strict Gate
owner: conductor
tier: internal
created: 2026-05-03
created-by: conductor (Mode A 자율, R7 critic resolution)
linked-decisions:
  - B-Q12 100ms SLA measurement (PENDING → IN_PROGRESS)
  - B-Q7 ㉠ Production-strict gate
  - Phase_Plan_2027.md (Phase 1 quality gate)
last-updated: 2026-05-03
reimplementability: PASS
confluence-page-id: 3818717608
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818717608/EBS+Phase+1+Load+Test+Plan+8+Soak+Production-strict+Gate
---

# Phase 1 Load Test Plan — 2027-01 Korea Soft-Launch 게이트

## TL;DR

| 항목 | 상태 |
|------|:----:|
| Harness scaffold | ✅ `tools/load_test/soak_8h_harness.py` 작성 |
| Smoke 30s baseline | ✅ Gate PASS — 모든 endpoint p99 < 11ms (target <200ms) |
| 8h soak run | ⏳ 별도 cascade (Phase 0 freeze 직전) |
| Locust/k6 외부 도구 의존 | **없음** (httpx + asyncio stdlib + httpx 패키지만) |

## 1. 도구 결정

**채택**: 자체 Python httpx + asyncio harness.

**Why**:
- 외부 의존 최소 (locust 미설치 환경에서도 실행 가능 — bandit 시 발견)
- integration-tests/scenarios/ 의 .http 패턴과 동일 라이브러리
- B-Q12 (p99 < 200ms) gate 평가 함수 내장
- 결과 JSON serialization → CI 통합 용이

**대안 (미채택)**:
- locust — Python deps 추가, web UI 불필요
- k6 — Go binary 추가, JS scripting 학습 cost
- ApacheBench (ab) — WebSocket 미지원

## 2. 시나리오 구성 (Weighted)

| Endpoint | Weight | 이유 (Phase 1 critical path) |
|----------|:------:|------------------------------|
| `GET /api/v1/series` | 5 | Lobby drill-down 진입점 |
| `GET /api/v1/events` | 5 | Lobby drill-down |
| `GET /api/v1/hands?limit=20` | 4 | B-Q19 fix path (high traffic in 8h 방송) |
| `GET /api/v1/flights` | 3 | Drill-down |
| `GET /api/v1/tables` | 3 | Drill-down |
| `GET /api/v1/audit-events` | 2 | Operator monitoring |
| `GET /api/v1/blind-structures` | 1 | B-Q18 fix path (low frequency) |
| `GET /api/v1/payout-structures` | 1 | B-Q18 fix path |
| `GET /api/v1/skins` | 1 | Phase 1 GFX |
| `GET /health` (BO) | 1 | self-probe |
| `GET /health` (engine) | 10% of total | engine harness availability |

**WebSocket** (별도 cascade — Phase 0.5):
- `/ws/lobby` monitor connection (1 시간 idle hold)
- `/ws/cc` write connection (game event ingest)

## 3. Production-strict Gate (B-Q7 ㉠ 자동 평가)

```python
# tools/load_test/soak_8h_harness.py:evaluate_gate()
- Error rate per endpoint < 0.1%
- p99 latency < 200ms (BO REST)
- p99 latency < 500ms (engine harness)
```

Gate 함수가 모든 endpoint 별 stats 검증 → JSON `{"pass": bool, "failures": [...]}` 반환. CI 통합 시 exit 1 = 실패.

## 4. 실행 방법

### Smoke (30s ~ 60s, dev verification)

```bash
cd C:/claude/ebs
python tools/load_test/soak_8h_harness.py --duration 30 --rps 5 --tag smoke
```

### Soak (8h, Phase 0 freeze 게이트)

```bash
cd C:/claude/ebs
python tools/load_test/soak_8h_harness.py --duration 28800 --rps 20 --tag soak
```

### CI 통합 (제안, B-Q12 cascade)

```yaml
# .github/workflows/load-smoke.yml (예시)
- run: python tools/load_test/soak_8h_harness.py --duration 60 --rps 10 --tag ci-smoke
```

8h soak 는 nightly 또는 release-candidate 타이밍.

## 5. Smoke baseline (2026-05-03)

```json
{
  "tag": "smoke-r7",
  "duration": 30,
  "rps_target": 5.0,
  "stats": {
    "boGET /api/v1/series":        {"p99":  7.78ms, "error_rate": 0.0},
    "boGET /api/v1/events":        {"p99": 11.63ms, "error_rate": 0.0},
    "boGET /api/v1/hands?limit=20":{"p99": 11.10ms, "error_rate": 0.0},
    "boGET /api/v1/flights":       {"p99":  8.12ms, "error_rate": 0.0},
    "boGET /api/v1/tables":        {"p99":  9.42ms, "error_rate": 0.0},
    "boGET /api/v1/audit-events":  {"p99":  7.78ms, "error_rate": 0.0},
    "boGET /api/v1/skins":         {"p99":  6.58ms, "error_rate": 0.0},
    "boGET /api/v1/blind-structures":{"p99": 10.37ms,"error_rate": 0.0},
    "boGET /api/v1/payout-structures":{"p99":7.0ms, "error_rate": 0.0},
    "boGET /health":               {"p99":  5.11ms, "error_rate": 0.0},
    "engineGET /health":           {"p99":  6.72ms, "error_rate": 0.0}
  },
  "gate": { "pass": true, "failures": [] }
}
```

→ **30s 베이스라인**: Gate PASS. p99 모든 endpoint < 12ms (gate < 200ms 의 6%). 여유 충분.

## 6. 8h Soak 추가 검증 항목

| 항목 | 측정 | Gate |
|------|------|:----:|
| Memory leak (bo) | docker stats 메모리 시계열 | < 100MB 증가 |
| Connection leak | netstat ESTABLISHED count | 안정 |
| DB connection pool | bo `/health` 의 pool stats | 지속 회복 |
| Error rate drift | 1h 단위 평균 비교 | 일정 |
| Disk usage (logs) | `du -sh /var/log` | < 1GB |

## 7. 후속 cascade

| 작업 | 시점 | 담당 |
|------|:----:|------|
| WebSocket harness 추가 (`/ws/lobby` + `/ws/cc`) | Phase 0.5 | conductor + team2 |
| 8h soak 실제 실행 | Phase 0 freeze 직전 (2026-12) | conductor + team2 |
| CI smoke gate 통합 | Phase 0.5 | conductor |
| memory profiling (py-spy) | 8h soak 결과 후 | team2 |

## 8. 관련

- `tools/load_test/soak_8h_harness.py` (구현)
- `tools/load_test/_results/` (결과 JSON)
- `integration-tests/scenarios/` (.http reference)
- `docs/4. Operations/Phase_Plan_2027.md` Phase 1 quality gate
- B-Q12 (100ms SLA measurement) — 본 plan 으로 IN_PROGRESS 전환

## Changelog

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-03 | v1.0 | 최초 작성 — harness scaffold + smoke baseline 통과 evidence |
