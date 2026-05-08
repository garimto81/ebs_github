---
title: B-Q17 — ebs-v2-engine healthcheck unhealthy 수정 (Type A 구현 실수)
owner: conductor (또는 team3)
tier: internal
status: PENDING
type: backlog
linked-decision: Session 1 발견 (2026-04-27)
last-updated: 2026-04-27
confluence-page-id: 3819766404
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819766404/EBS+B-Q17+ebs-v2-engine+healthcheck+unhealthy+Type+A
---

## 발견

Session 1 인프라 점검 (2026-04-27) 에서 발견:
- `ebs-v2-engine` 13h **unhealthy** 상태
- 그러나 docker logs 검토 결과 **정상 동작 중** (200/201 응답, /health → 200 ms)
- 즉 service 자체 정상, **healthcheck spec 만 잘못 설정** = **Type A (구현 실수)**

## 가설

| 가설 | 검증 방법 |
|------|----------|
| (a) healthcheck command 경로 오류 (예: localhost vs 127.0.0.1, IPv6 우선) | docker inspect ebs-v2-engine 의 Healthcheck spec read |
| (b) healthcheck endpoint 다름 (예: /health vs /healthz vs /api/health) | engine code 의 endpoint 정의 확인 |
| (c) interval/timeout 너무 짧음 | inspect 후 비교 |
| (d) start_period 부족 (앱 초기화 시간 > start_period) | 로그 startup 시간 확인 |

## 처리 작업

1. `docker inspect ebs-v2-engine` → Healthcheck spec 추출
2. engine 의 health endpoint 정의 검증 (team3-engine/ebs_game_engine/lib/.../health.dart 또는 비슷)
3. mismatch 식별 후 수정:
   - (a) healthcheck command 정정 (docker-compose.yml 또는 Dockerfile)
   - (b) endpoint 통일
4. compose 정의 prefix mismatch 도 함께 검토 (ebs-v2 vs ebs)
5. Production-strict (B-Q7 ㉠) 99.9% uptime 영향 — 수정 후 재시작 + 검증

## 운영 영향

- 현재 service 동작 OK (log 정상)
- healthcheck 만 false positive
- 외부 모니터링 시스템 (Grafana 등) 영향 가능
- B-Q12 (100ms SLA 측정) cascade 와 연관

## 우선순위

P1 — Type A 구현 실수, 수정 비용 낮음. Phase 0 빠르게 처리 권장.

## 참조

- `docs/4. Operations/SESSION_1_HANDOFF.md` (발견 기록)
- `docs/4. Operations/Docker_Runtime.md` (운영 SSOT)
- B-Q12 100ms SLA 측정 framework
