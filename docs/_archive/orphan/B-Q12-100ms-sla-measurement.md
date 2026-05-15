---
title: B-Q12 — 운영 안정성 측정 framework (NFR — RFID/Engine/WS/Render 사슬 안정성)
owner: conductor
tier: internal
status: PENDING
type: backlog
linked-sg: BLANK-1, SG-026, SG-033
linked-decision: C.3 (BLANK-1) + B-Q7 ㉠ + SG-033 (2026-05-05 EBS 미션 재선언 cascade)
last-updated: 2026-05-05
confluence-page-id: 3818947257
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947257/EBS+B-Q12+framework+NFR+RFID+Engine+WS+Render
mirror: none
---

## 표기 주의 (2026-05-05, SG-033 cascade)

본 backlog 는 **운영 안정성 측정 framework (NFR / Non-Functional Requirements)** 입니다. 100ms 수치는 **EBS 핵심 가치가 아닌 운영 메트릭** 입니다 (사용자 directive 2026-05-05: "0.1초 100ms 이내같은 기술적인 용어는 EBS 에서 전혀 중요하지 않음"). EBS 핵심 가치는 Foundation §Ch.1.4 의 5 가치 — **정확성·장비 안정성·명확한 연결·단단한 HW·오류 없는 처리 흐름**. 본 측정 framework 는 시스템 동작 기준점 및 안정성 회귀 검증 도구로 보존됩니다.

## 개요

BLANK-1 결정 (C.3): 100ms = 전체 파이프라인 (RFID → Engine → WS → Render → Output) end-to-end **운영 메트릭** (NFR). **Phase 2 측정 대상**. B-Q7 ㉠ 채택으로 production 게이트 (p99 < 200ms 마진 포함) 확정. 측정 framework 구현 필요. **단, KPI 가 아닌 운영 안정성 회귀 검증 용도** — 측정 결과로 "EBS 미션 충족" 을 판정하지 않는다 (미션은 §Ch.1.4 5 가치로 별도 측정).

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

## SG-033 cascade 후속 (2026-05-05)

| 변경 | 적용 |
|------|------|
| 본 backlog 의 표제 | "100ms SLA 측정" → "**운영 안정성 측정 framework (NFR)**" 로 재명명 |
| 측정 결과의 의미 | EBS 미션 판정 도구 아님 (미션 = 5 가치 별도 검증) |
| 정확성·안정성·HW 견고성 측정 | 별도 backlog 등재 검토 (예: B-Q22 "5 가치 검증 framework" — 후속) |

## 참조

- Spec_Gap_Registry BLANK-1, SG-026
- Foundation §6.4 (WebSocket < 100ms)
- 현재 자산: team2 observability/ 디렉터리 (existing)
