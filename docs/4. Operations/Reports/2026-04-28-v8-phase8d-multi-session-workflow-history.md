---
title: Multi_Session_Workflow.md — v7.2 5-Session Pipeline + 변경 이력 (Archived 2026-04-28)
owner: conductor
status: archived
archived_date: 2026-04-28
archived_phase: v8.0 Phase 8d
parent: docs/4. Operations/Multi_Session_Workflow.md (v5.1+L4)
purpose: main doc 압축 (60+ lines 절감), 분량 모델 + 변경 이력 보존
mirror: none
---

# Multi_Session_Workflow — Archived sections (2026-04-28)

> 본 문서는 2026-04-28 v8.0 Phase 8d 마이그레이션으로 main doc 에서 archive 이동된 두 섹션을 통합 보존한다.

---

## 1. v7.2 — 5-Session Pipeline (SG-027, 2026-04-27)

대규모 production cascade (수만 line 코드 + 다중 영역) 의 **분량 분할 워크플로우**. v7.1 Mode A/B (권한 모델) 와 **직교** — 본 모델은 multi-turn 분량 모델.

### 5 Sessions 정의

| Session | 목표 | 가상 팀 | 전형 작업 |
|:-------:|------|---------|----------|
| **1. Foundation & Infrastructure** | 기획 SSOT 분석 + 인프라 정합성 | Conductor (Team 4 가상) | Broken URL 정렬, 도커 좀비 정리, 개발 환경 표준화 |
| **2. Core Logic & Backend Engine** | API + 엔진 구현 | Team 2 + Team 3 | DB 스키마 (Alembic), endpoint 구현, Coverage 95% 목표 |
| **3. Frontend Interface & Routing** | 클라이언트 + 백엔드 연동 | Team 1 | 단일 Desktop 라우팅, UI 컴포넌트, 100ms SLA 클라이언트 측정 |
| **4. System Integration & QA Harness** | 통합 + E2E 검증 | Team 1~4 + QA | 통합 하네스, 예외 케이스, 부분 재구현 (Surgical Edit) |
| **5. Final Production & Audit** | 보안 + 최종 빌드 | Conductor + QA | OWASP audit, PHASE-FINAL-REPORT, Main 통합 commit |

### Session Isolation

각 session 은 **자신의 scope 내 작업만**. 예: Session 2 에서 UI 코딩 금지, Session 3 에서 DB schema 변경 금지. Conductor 가 cross-session 변경 필요 시 **즉시 escalation** + handoff.

### State Handoff Protocol

각 session 종료 시 **`SESSION_X_HANDOFF.md`** 출력:
- 진행 결과 요약
- 커밋 hash
- 미해결 백로그
- 다음 session 권고

다음 session 시작 시 그 handoff 를 read.

### Mode 조합 (v7.2)

| Mode | Session 모델 | 권한 |
|:----:|------------|------|
| **Mode A + 5-Session** | Conductor 단일 세션, 5 turns 분할 | 단일 세션 권한 + multi-turn 분량 |
| Mode A + Single Session | Conductor 단일 세션, 단일 turn | 단일 세션 권한 + 단일 turn 분량 (v7.1 default) |
| Mode B + 5-Session | 멀티세션, 5 단계 분할 | decision_owner 회복 + multi-turn |
| Mode B + Single Session | 멀티세션, 단일 turn | v5.1 표준 |

5-Session 모델은 **분량이 단일 turn 한계 초과 시** default 권장.

### Zero-Regression 검증

- 새 코드 작성 시 기존 통과 테스트 100% 보존
- pytest / flutter test / dart test 등 baseline 유지

### 참조

- `Conductor_Backlog/SG-027-multi-session-pipeline.md`
- `Conductor_Backlog/SESSION_1_HANDOFF.md` (현재 session)
- `team-policy.json` v7.1 (Mode A/B)

---

## 2. 변경 이력 (전체 history)

| 날짜 | 버전 | 요약 |
|------|------|------|
| 2026-04-10 | v4.0 | Pre-Declaration manifest + conflict scan + safety gate 도입 |
| 2026-04-21 | v4.1 | Hybrid PR (Team=PR / Conductor=direct) patch |
| 2026-04-21 | v5.0 | 전체 재설계. 업계 표준 재사용. 3-Phase. free-tier 호환. v4.0/v4.1 deprecated |
| 2026-04-22 | **v5.1** | **L0 Pre-Work Contract 추가** (Active_Work.md). proactive coordination + reactive merge gate 이중 안전망. 4-Phase |
| 2026-04-27 | **v5.1+L4** | **L4 Merge Strategy 추가** (BLANK-3). worktree fast-forward + pre-push hook 명문화. Phase_1_Decision_Queue C.4 결정 |
| 2026-04-28 | **v8.0 Phase 8a/8d** | history 섹션 archive 이동, main doc 압축 |

## 관련 archive

- v4.0/v4.1 → v5.0 전환 이유: `docs/4. Operations/Reports/2026-04-28-v8-phase8a-multi-session-workflow-v4-history.md`
- SKILL.md v4.0/v4.1 폐기 이유: `docs/4. Operations/Reports/2026-04-28-v8-phase8c-skill-md-v4-history.md`
