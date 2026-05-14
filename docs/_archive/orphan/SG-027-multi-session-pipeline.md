---
title: SG-027 — 5-Session Pipeline 도입 (multi-turn 분량 분할 모델)
owner: conductor
tier: internal
status: DONE
resolved: 2026-04-27
resolved-by: conductor (사용자 5-session 명시 cascade)
type: spec-gap
spec-gap-type: B
linked-decision: user 2026-04-27 (5-Session Pipeline 도입)
last-updated: 2026-04-27
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "status=DONE — 5-Session Pipeline (multi-turn) 도입 완료"
confluence-page-id: 3818881568
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818881568/EBS+SG-027+5-Session+Pipeline+multi-turn
---
## 결정 (사용자 명시 2026-04-27)

> "5개의 순차적 멀티 세션 + 4개의 전문 에이전트 팀" — Hybrid Multi-Session Orchestrator 모델 도입. LLM 컨텍스트 한계 회피 + 분량 분할.

**EBS workflow 에 5-Session Pipeline 추가** (SG-024 Mode A/B 위에 직교 layer).

## 분류

| 항목 | 값 |
|------|-----|
| Spec Gap Type | **B (기획 공백)** — 분량이 단일 turn 한계 초과 시 분할 모델 미정의 |
| 영향 범위 | Multi_Session_Workflow.md + Phase_1_Decision_Queue + 모든 향후 cascade |
| Decision Owner | 사용자 |

## 5 Sessions 정의

자세히: `Multi_Session_Workflow.md` §"v7.2 — 5-Session Pipeline"

```
Session 1: Foundation & Infrastructure  → Conductor (Team 4 가상)
Session 2: Core Logic & Backend Engine  → Team 2 + Team 3
Session 3: Frontend Interface & Routing → Team 1
Session 4: System Integration & QA      → Team 1~4 + QA
Session 5: Final Production & Audit     → Conductor + QA
```

## v7.1 Mode A/B 와의 관계 (직교)

| Layer | 역할 |
|-------|------|
| v7.1 Mode A/B (SG-024) | **권한 모델** — Conductor 단일 세션 전권 (A) vs 멀티세션 decision_owner (B) |
| v7.2 5-Session (SG-027) | **분량 모델** — multi-turn 분할 (5 sessions) vs 단일 turn (default) |

조합:
- Mode A + 5-Session = 단일 Conductor 세션이 5 turns 에 걸쳐 진행 (현재 사용자 패턴)
- Mode B + 5-Session = 각 팀 세션이 자기 session 진행
- Mode A + Single = 단일 turn 자율 (v7.1 default)
- Mode B + Single = v5.1 표준

## 거버넌스 보호

각 session 은 **자기 scope 내 작업만**. 위반 시 **즉시 stop + handoff escalation**.

## Zero-Regression 검증

새 code 추가 시 기존 통과 테스트 100% 보존 (예: team2 261 passed → +N passed, regression 0).

## 참조

- `docs/4. Operations/Multi_Session_Workflow.md` §"v7.2 — 5-Session Pipeline"
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group I (SG-027 결정)
- `docs/4. Operations/Conductor_Backlog/SESSION_1_HANDOFF.md` (현재 session)
