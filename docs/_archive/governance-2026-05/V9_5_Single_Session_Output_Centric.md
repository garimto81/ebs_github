---
title: V9.5 Single Session AI-Centric — Hub-and-Spoke Deprecation
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.5
related: ["V9_4_AI_Centric_Governance.md", "Multi_Session_Workflow.md", "team-policy.json"]
---

# V9.5 Single Session AI-Centric

> **사용자 결정 (2026-04-29)**: V9.4 critic 결과 (9 결함, F1-F4 HIGH) 을 권고 A 로 처리. Hub-and-Spoke 모델 폐기, Conductor 단일 session + Agent Teams in-process 로 통일.

## 🎯 V9.4 → V9.5 전환

| 차원 | V9.4 | V9.5 |
|------|------|------|
| 운영 모델 | Hub-and-Spoke (Conductor + 4 Worker session) | **Single Session AI-Centric** |
| Worker session | sibling worktree + `claude` CLI 5개 | **in-process Agent Teams (필요 시)** |
| Dispatch | `Task_Dispatch_Board.md` self-discovery | **사용자 의도 trigger 직접** |
| 사용자 입력 | 0 (의도만) | **0 (의도만)** — V9.4 보존 |
| Worker trigger | 사용자가 `cd && claude` 5회 | **불필요. AI Conductor 가 자율 진행** |
| Ceremony | 5 transition (ASSIGNED→IN_PROGRESS→...) | **2 transition (DRAFT → DONE)** |

## 🚫 폐기 항목 (Deprecated)

| 항목 | 사유 |
|------|------|
| **Hub-and-Spoke 5-session 모델** | 1인 사용자 환경에서 비현실. Worker trigger = 사용자 입력 = V9.4 위배 |
| **`Task_Dispatch_Board.md` dispatch SSOT** | 사용자 의도 자체가 dispatch source. 보드는 audit log 로 demote |
| **Worker session SOP** (보드 self-discovery + Idle 대기) | trigger 메커니즘 부재 + ceremony 무용 |
| **`/team "<task>"` 슬래시 사용자 호출** | 사용자 입력 = anti-pattern. 슬래시는 audit/diagnosis only |
| **`tools/team_v5_merge.py` worker-side 사용** | Conductor 자율 PR 생성으로 흡수 |

## ✅ 보존 항목

| 항목 | 이유 |
|------|------|
| **Sibling worktree 격리** | git 안전망. 외부 개발팀 인계 시 표준 git 패턴 |
| **`work/<owner>/<slug>` 브랜치 명명** | git history audit 가능 |
| **`tools/v93_autonomous_merge.py`** | AI 자율 머지 — V9.4/V9.5 핵심 |
| **`tools/scope_check.py`** + **`tools/team_v92_safe_merge.py`** | 3-gate enforcement |
| **`Task_Dispatch_Board.md`** | audit log 로 demote (history 보존) |
| **`.githooks/pre-push`** + **CODEOWNERS** | enforcement 보존 |

## 🔄 V9.5 표준 운영 절차 (단순화)

```
사용자 의도 (1줄)
       │
       ▼
   AI Conductor (단일 session)
       │
       ├─ SSOT 검색 (Foundation > team-policy > Risk_Matrix > APIs > Backlog)
       ├─ 답 모호 → SSOT 보강 PR 자율 생성
       ├─ 작업 분해 (필요 시 Agent Teams in-process spawn)
       │
       ▼
   work/<owner>/<slug> 브랜치 + commit
       │
       ▼
   gh pr create + scope_check + safe_merge
       │
       ▼
   v93_autonomous_merge (조건 만족 시 자율 머지)
       │
       ▼
   결과물 적용 → main 동기화
```

**중간 ceremony 0**. 사용자 의도 → 결과물 사이 AI 자율 진행.

## 🤖 Multi-team work 처리 (필요 시)

V9.5 도 multi-team scope 작업 처리 가능 — Agent Teams in-process pattern 으로:

```
TeamCreate(team_name="<feature>")

Agent(subagent_type="executor", name="team1-worker", ...)  # 병렬 작업
Agent(subagent_type="executor", name="team2-worker", ...)
Agent(subagent_type="executor", name="team3-worker", ...)

# 결과 통합
SendMessage(to="team1-worker", message={type: "shutdown_request"})
TeamDelete()
```

**핵심 차이**: OS process 5개 (claude CLI) 가 아니라 **단일 Conductor session 내부의 in-process Agent**. 사용자 trigger 0회.

## 📐 결과물 중심주의 (V9.4 계승)

V9.5 의 모든 활동 정당화 = 2 결과물 quality:

1. **기획 문서** (`docs/`) — 외부 개발팀 재구현 가능
2. **최종 프로토타입** (`team1~4/`) — 동작 증명

V9.5 가 ceremony 를 줄이는 이유 = 결과물 진전 단위로 작업 분해 위함.

## 🛡 V9.5 critic 결함 매핑

| ID | 결함 (V9.4 critic) | V9.5 해소 |
|----|---------------------|-----------|
| **F1** | Worker trigger 메커니즘 부재 | Hub-and-Spoke 폐기 — Worker 자체 불필요 |
| **F2** | SOP 헤더 4종 stale | 본 PR 에서 일괄 V9.5 갱신 |
| **F3** | forbidden_terms 위배 | SOP 본문 사용자 친화 + AI internal 분리 |
| **F4** | Mode A vs 5-session 충돌 | Single Session 이 default — Mode A 가 유일 |
| **F5** | SSOT-first judgment 누락 | 본 SOP §"V9.5 표준 운영 절차" 에 명시 |
| **F6** | self-discovery push/pull mismatch | 사용자 의도 trigger = push 모델로 통일 |
| **F7** | ceremony 결과물 기여 미정당화 | 5 transition → 2 transition 으로 축소 |
| **F8** | AI 다중 worker 운영 모델 미정의 | Agent Teams in-process 명시 |
| **F9** | Backlog 자동 분해 부재 | AI Conductor 가 SSOT 검색 + 자동 분해 |

## 📊 외부 인계 가능성 (V9.5 결과물)

V9.5 SOP 자체는 **EBS 1인 사용자 환경 특수 모델**. 외부 개발팀 인계 시:

- **인계 대상**: 결과물 (기획 문서 + 프로토타입) 만
- **인계 안 함**: V9.x governance / SOP / Hub-and-Spoke 등 메타 시스템
- **외부 팀의 자유**: 자체 워크플로우 채택 (GitHub Flow, GitFlow 등)

V9.5 governance 는 **인계 후 폐기 가능** 한 메타 layer. 이는 결과물 중심주의 정합.

## 🔗 관련

- `V9_4_AI_Centric_Governance.md` (V9.4 본문, 계승)
- `Multi_Session_Workflow.md` (V9.5 갱신 후 단일 session SOP)
- `team-policy.json` `governance_model` (V9.5 갱신)
- `.claude/skills/team/SKILL.md` (V9.5 audit-only 로 demote)
- `Task_Dispatch_Board.md` (audit log 로 demote)
