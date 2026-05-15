---
title: Multi-Session Workflow (v10.3 redirect)
owner: conductor
tier: operations
governance: v10.3 architect_then_observer
confluence-page-id: 3818717573
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818717573/EBS+Multi-Session+Workflow+v10.3+redirect
mirror: none
---

# Multi-Session Workflow — v10.3

EBS 멀티세션 운영 SSOT 는 다음 3 문서 조합:

| 문서 | 역할 |
|------|------|
| `Multi_Session_Design_v10.3.md` | 기술 spec (Architect-then-Observer 모델, Stream 매트릭스, Phase 정의) |
| `team_assignment_v10_3.yaml` | Stream 할당 (S1~S6 + future S7~S9, work_declaration_protocol, monitoring) |
| `docs/2. Development/2.5 Shared/Stream_Entry_Guide.md` | Stream 진입 가이드 + 공유 contract 충돌 SOP |
| `docs/2. Development/2.5 Shared/team-policy.json` | 운영 거버넌스 SSOT (v10.3 architect_then_observer) |

## v10.3 운영 모델 요약

```
사용자 의도 1회 (VSCode 폴더 클릭 또는 명시 지시)
        │
        ▼
┌──────────────────────────────────────────────┐
│ Phase 0 — Architect Mode (orchestrator 자율) │
│  · Stream 매트릭스 (이미 정립 → 자동 추론 스킵) │
│  · 워크트리 폴더 사전 세팅 (sibling-dir)      │
│  · GitHub 인프라 + hook + .team               │
│  · 자가 시뮬 → 게이트 (사용자 1회 검토 선택)  │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│ Phase 1+ — Observer Mode (orchestrator 영구) │
│  · 30초 GitHub 폴링                           │
│  · Stream 의존성 unblock 자동                 │
│  · Stream 세션 = team_session_start.py        │
│    (자동 Issue + Draft PR) → 작업 →           │
│    team_session_end.py (auto-merge)           │
│  · 동적 Stream 추가 = Architect 일시 전환      │
└──────────────────────────────────────────────┘
```

## 글로벌 v10.3 자산

- 글로벌 스킬: `~/.claude/skills/orchestrator/` (SKILL.md, scripts/, hook_templates/, references/, templates/)
- EBS 도구: `tools/orchestrator/` (9개)
- EBS hook: `.claude/hooks/orch_SessionStart.py`, `.claude/hooks/orch_PreToolUse.py`

## 진입 가이드

| 작업 종류 | 진입 절차 |
|-----------|----------|
| 신규 멀티세션 시작 | `Multi_Session_Design_v10.3.md` 읽고 Phase 0 Architect 진입 |
| Stream 작업 (사용자) | VSCode 에서 sibling worktree 폴더 클릭 1회 |
| 동적 Stream 추가 | `team_assignment_v10_3.yaml` `future_streams` 활성화 |

## 폐기 거버넌스 복원

이전 거버넌스 narrative (V9.x / Hub-and-Spoke / Mode A·B / decision_owner / 5-OS-process) 는 `docs/_archive/governance-2026-05/INDEX.md` 참조.
