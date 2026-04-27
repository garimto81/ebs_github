---
title: B-Q12 — 100ms SLA 측정 framework (BLANK-1 + B-Q7 cascade)
owner: conductor
tier: internal
status: PENDING
type: backlog
linked-sg: BLANK-1, SG-026
linked-decision: C.3 (BLANK-1) + B-Q7 ㉠
last-updated: 2026-04-27
---

## 개요

BLANK-1 결정 (C.3): 100ms = 전체 파이프라인 (RFID → Engine → WS → Render → Output) end-to-end. **Phase 2 측정 대상**. B-Q7 ㉠ 채택으로 production 게이트 (p99 < 200ms 마진 포함) 확정. 측정 framework 구현 필요.

## 측정 구간 (참고: Foundation §6.4)

| 구간 | 책임 | 예상 budget (cumulative) |
|------|------|--------------------------|
| RFID 감지 → Engine 입력 | team4 (HAL) + team3 | < 30ms |
| Engine 처리 | team3 | < 50ms (cumulative) |
| WebSocket broadcast | team2 | < 70ms (cumulative) |
| Rive 렌더링 | team1 (Lobby) + team4 (Overlay) | < 90ms (cumulative) |
| SDI/NDI 송출 | team4 (Overlay) | **< 100ms** (final) |

WebSocket 단일 구간 SLA = < 100ms (Foundation §6.4 기존 명시).

## 처리 작업

1. 각 구간 측정 instrument 추가 (timestamp marker 전파)
2. 통합 측정 dashboard (Grafana 또는 비슷)
3. CI/CD 의 부하 테스트 (smoke + soak)
4. p50/p95/p99 통계 수집

## 우선순위

P1 — B-Q7 ㉠ + BLANK-1 cascade. Phase 1 (2027-01) 직전 측정 가능 상태 도달 권장.

## 참조

- Spec_Gap_Registry BLANK-1, SG-026
- Foundation §6.4 (WebSocket < 100ms)
- 현재 자산: team2 observability/ 디렉터리 (existing)
