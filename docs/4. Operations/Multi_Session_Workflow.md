---
title: Multi-Session Workflow (V9.5 — Single Session AI-Centric, Hub-and-Spoke Deprecated)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.5 single_session_ai_centric_output_focused
reimplementability: PASS
reimplementability_checked: 2026-04-29
reimplementability_notes: "V9.5 — V9.4 critic 9 결함 (F1-F9) 권고 A 채택. Hub-and-Spoke 폐기. Conductor 단일 session + Agent Teams in-process 가 default. 사용자 입력 0 + 결과물 중심주의."
---

# Multi-Session Workflow — V9.5 Single Session AI-Centric

> **🚨 V9.5 패러다임 (2026-04-29)**:
> V9.0~V9.4 의 Hub-and-Spoke (Conductor + 4 Worker session) 모델 **폐기**. 1인 사용자 환경에서 Worker session trigger 메커니즘 부재 + ceremony 결과물 기여 미정당화 = V9.4 anti-pattern.
> V9.5 = **Single Session AI-Centric** — Conductor 단일 session + Agent Teams in-process (multi-team work 시).

## 🎯 V9.5 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **Single Session Default** | Conductor 단일 session 이 default. 사용자 의도 trigger → AI 가 모든 것 자율 진행 |
| **Agent Teams In-Process** | Multi-team work 필요 시 Conductor session 내부에서 `TeamCreate + Agent` spawn |
| **사용자 입력 0** | V9.4 계승. 사용자는 모니터링/감독만 |
| **결과물 중심주의** | V9.4 계승. 2 결과물 (기획 문서 + 최종 프로토타입) 만 |
| **2 Transition** | `DRAFT → DONE` (V9.0 의 5 transitions 폐기) |

## 🔄 V9.5 표준 운영 절차 (단순화)

### Step 1: 의도 수신 + SSOT 검색

사용자 의도 trigger 또는 자동 cycle (governance freeze metric) 수신 시 AI Conductor:

1. **SSOT 우선순위 검색** (team-policy.json `conflict_resolution.ssot_priority`):
   - `docs/1. Product/Foundation.md`
   - `docs/2. Development/2.5 Shared/team-policy.json`
   - `docs/2. Development/2.5 Shared/Risk_Matrix.md`
   - `docs/2. Development/2.{2,3,4}/APIs/**`
   - `docs/2. Development/2.*/Backlog/**`
2. **답 있음** → Step 2 직행
3. **답 모호** → SSOT 보강 PR 자율 생성 → 머지 → 다시 Step 1
4. **답 없음 + 큰 방향성** → 사용자 의도 영역 질문 (마지막 수단)

### Step 2: 작업 분해 + 실행

Single Session 내부에서:

- **Single team scope**: Conductor 가 직접 work 브랜치 생성 + commit
- **Multi-team scope**: `TeamCreate + Agent(subagent_type=executor, name=team{N}-worker)` 으로 in-process Agent spawn
- 각 변경은 `work/<owner>/<slug>` 브랜치 (sibling worktree 는 격리 안전망 — 선택)

### Step 3: PR + 자율 머지

```
gh pr create --base main --head work/<owner>/<slug>
       │
       ▼
   tools/scope_check.py (CI 자동)
       │
       ▼
   tools/v93_autonomous_merge.py
       │
   ┌───┴───┐
   │       │
  조건만족  조건불만족
   │       │
   ▼       ▼
 자율머지  사용자 의도 영역 (큰 방향성/외부/destructive 만)
```

자율 머지 조건 (`team-policy.json governance_model.merge_authority.ai_autonomous_merge_conditions`):
- AI authored
- mergeable
- CI green
- 의도 정합

## 📐 V9.0 → V9.5 전환

| 차원 | V9.0 Hub-and-Spoke | V9.5 Single Session |
|------|--------------------|--------------------|
| Session 수 | Conductor + 4 Worker | **Conductor 1개** |
| Worker trigger | 사용자가 5회 `claude` 호출 | **불필요 — 단일 session 자율** |
| Dispatch SSOT | Task_Dispatch_Board.md row | **사용자 의도 trigger 직접** |
| Multi-team work | OS process 5개 | **Agent Teams in-process** |
| Transition | 5단계 | **2단계 (DRAFT → DONE)** |
| Sibling worktree | 강제 | **선택 (격리 필요 시만)** |
| Ceremony | 보드 4회 commit | **0** |

## 📂 자산 변화

### Active (V9.5)

| 자산 | 역할 |
|------|------|
| `tools/v93_autonomous_merge.py` | AI 자율 머지 |
| `tools/scope_check.py` + `team_v92_safe_merge.py` | 3-gate enforcement |
| `tools/v93_active_check.py` | sibling 자동 감지 (참고용) |
| `.github/workflows/v92-scope-check.yml` | PR CI gate |
| `.githooks/pre-push` | main 직접 push 차단 |
| `.github/CODEOWNERS` | 리뷰어 알림 |

### Demoted (V9.5)

| 자산 | 새 역할 |
|------|---------|
| `Task_Dispatch_Board.md` | audit log 만 (실시간 dispatch SSOT 아님) |
| `.claude/skills/team/SKILL.md` | audit/diagnosis only (사용자 작업 trigger 사용 금지) |
| `tools/team_v5_merge.py` | 단순 PR 생성 도구 (Conductor 자율 PR 생성으로 대부분 흡수) |

### Deprecated (V9.5)

| 자산 | 사유 |
|------|------|
| Hub-and-Spoke 5-session 모델 | F1 worker trigger 부재 |
| Worker session SOP (Idle 대기 + 보드 self-discovery) | F6 push/pull mismatch |
| `/team "<task>"` 슬래시 사용자 호출 | F3 사용자 입력 anti-pattern |
| 5 transition (ASSIGNED→IN_PROGRESS→...) | F7 ceremony 무용 |

## 🛡 Mode A 통합

V9.3 의 `single_session_mode_a` 가 V9.5 의 default 가 됨:

- `sibling_worktree_count == 0` → V9.5 default (`single_session_conductor`)
- `sibling_worktree_count >= 1` → 외부 개발팀 인계 후 그들의 자유 (V9.5 governance 폐기 가능)

본 cycle 의 실증: 0 sibling 으로 8 PR 자율 진행 — V9.5 가 V9.4 환경의 자연스러운 결과.

## 🌐 외부 인계 가능성

V9.5 SOP 자체는 **EBS 1인 사용자 + AI-Centric 특수 모델**. 외부 개발팀 인계 시:

- **인계 대상**: 결과물 (기획 문서 `docs/` + 최종 프로토타입 `team1~4/`) 만
- **인계 안 함**: V9.x governance / SOP / 도구
- **외부 팀의 자유**: GitHub Flow / GitFlow / 자체 프로세스 — 그들 결정

V9.5 SOP 는 **사용자 + AI 협업의 제품 공정** 이며, 인계 후 폐기 가능한 메타 layer.

## 📜 변경 이력

| 날짜 | 버전 | 핵심 변화 |
|------|------|----------|
| 2026-04-29 | **v9.5** | **Hub-and-Spoke 폐기** — Single Session AI-Centric. V9.4 critic 9 결함 (F1-F9) 권고 A 채택 |
| 2026-04-29 | v9.4 | AI-Centric Zero-Friction + 결과물 중심주의 (사용자 입력 0) |
| 2026-04-29 | v9.3 | Intent-Execution Separation + AI 자율 머지 |
| 2026-04-29 | v9.2 | 충돌 없는 worker self-merge (3-gate) |
| 2026-04-29 | v9.0 | Hub-and-Spoke 도입 (V9.5 폐기) |

## 🔗 관련 문서

- `../../_archive/governance-2026-05/V9_5_Single_Session_Output_Centric.md` — V9.5 운영 본문 (archived 2026-05-08, supersede: CLAUDE.md §3 v10.3)
- `../../_archive/governance-2026-05/V9_4_AI_Centric_Governance.md` — V9.4 (archived, supersede: CLAUDE.md §2 + §3)
- `../../_archive/governance-2026-05/V9_3_Intent_Execution_Boundary.md` — V9.3 (archived, supersede: CLAUDE.md §3)
- `team-policy.json` `governance_model.operating_model` (v9.5)
- `Task_Dispatch_Board.md` — audit log (demoted)
- `.claude/skills/team/SKILL.md` — audit/diagnosis only (demoted)
