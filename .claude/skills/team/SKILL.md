---
name: team
description: EBS V9.5 — /team 슬래시 audit-only demoted (2026-04-29). Hub-and-Spoke 폐기. Conductor 단일 session + Agent Teams in-process 가 default. 사용자가 /team 호출할 필요 없음 — AI Conductor 가 사용자 의도 trigger 로 자율 진행.
---

# /team — V9.5 Audit-Only (DEPRECATED for active use)

> **🚨 V9.5 패러다임 (2026-04-29)**: Hub-and-Spoke 폐기. `/team` 슬래시는 **audit / diagnosis 용도** 로만 사용. 사용자가 작업 의도 trigger 시 AI Conductor 가 단일 session 에서 자율 진행 — `/team` 슬래시 불필요.

## 🎯 V9.5 운영 모델

**Default = Conductor 단일 session**:

```
사용자 의도 trigger ("X 작업해", "잔존 처리", 결과물 부적합 신호)
       │
       ▼
   AI Conductor (단일 session, 현재 cwd)
       │
       ├─ SSOT 검색 (Foundation > team-policy > Risk_Matrix > APIs > Backlog)
       ├─ 모호 시 SSOT 보강 PR 자율 생성
       ├─ Multi-team scope → Agent Teams in-process spawn (필요 시)
       │
       ▼
   work/<owner>/<slug> branch + commit + PR
       │
       ▼
   tools/v93_autonomous_merge.py 자율 머지
       │
       ▼
   결과물 main 적용
```

## 🚫 폐기된 흐름 (V9.0~V9.4 Hub-and-Spoke)

| 항목 | 사유 |
|------|------|
| `cd C:/claude/ebs-team{N}-work && claude` 5 session 운영 | 사용자 입력 5회 = V9.4 위배 |
| Worker session 의 보드 self-discovery + Idle 대기 | trigger 메커니즘 부재 |
| `/team "<task>"` 슬래시 사용자 호출 | 사용자 입력 = anti-pattern |
| 5 transition (ASSIGNED→IN_PROGRESS→...) | ceremony 결과물 기여 미정당화 |

## ✅ V9.5 사용 (Audit/Diagnosis only)

`/team` 슬래시는 진단 도구로만:

```bash
/team status     # 현재 운영 모델 확인 (Single Session Mode)
/team audit      # 최근 cycle 운영 metric (v93_metrics.yml 참조)
/team diagnose   # critic mode 진단 (architect agent 위임)
```

**작업 trigger 로 사용 금지** — 사용자 의도는 일반 메시지로 충분.

## 🛠 Multi-Team Work (필요 시)

V9.5 도 다중 팀 작업 처리 가능 — **Agent Teams in-process 패턴**:

```python
# 사용자 의도: "team1 + team2 동시 작업"
# AI Conductor 자율 진행:

TeamCreate(team_name="<feature>")
Agent(subagent_type="executor", name="team1-worker", team_name=..., prompt="...")
Agent(subagent_type="executor", name="team2-worker", team_name=..., prompt="...")
# 병렬 실행, 결과 통합
SendMessage(to="team1-worker", message={type: "shutdown_request"})
TeamDelete()
```

**핵심**: OS process 5개 ❌ / single Conductor session 내부 in-process Agent ✅

## 📂 자산 맵

### Active (V9.5)

| 자산 | 역할 |
|------|------|
| `tools/v93_autonomous_merge.py` | AI 자율 머지 (PR 조건 검증 후 squash) |
| `tools/scope_check.py` | PR 카테고리 분류 + governance-change 라벨 검증 |
| `tools/team_v92_safe_merge.py` | 머지 전 통합 체크리스트 |
| `tools/v93_active_check.py` | sibling worktree count 자동 감지 (Mode A trigger) |
| `.github/workflows/v92-scope-check.yml` | PR 자동 scope 검증 |
| `.githooks/pre-push` | main 직접 push 차단 + work/infra/feat allowlist |
| `.github/CODEOWNERS` | 자동 리뷰어 알림 |

### Demoted (V9.5)

| 자산 | 새 역할 |
|------|---------|
| `docs/4. Operations/Task_Dispatch_Board.md` | **audit log** (실시간 dispatch SSOT 아님). history 보존 |
| `tools/team_v5_merge.py` | 단순 PR 생성 도구 (auto-merge 라벨 부여 단계 사용 금지 — V9.2 부터) |

### Deprecated (V9.5)

| 자산 | 사유 |
|------|------|
| Hub-and-Spoke 5-session 모델 | 1인 환경 비현실 |
| Worker session SOP (보드 self-discovery + Idle) | trigger 부재 |
| `/team "<task>"` 슬래시 사용자 호출 | 사용자 입력 anti-pattern |

## 📐 V9.4 critic 결함 해소 매핑

| critic ID | V9.5 처리 |
|-----------|-----------|
| F1 (worker trigger 부재) | ✅ Hub-and-Spoke 폐기 |
| F2 (헤더 4종 stale) | ✅ V9.5 일제 갱신 |
| F3 (forbidden_terms 위배) | ✅ SOP 단순화 + 사용자 친화 |
| F4 (Mode A vs 5-session) | ✅ Single Session 이 default |
| F5 (SSOT-first 누락) | ✅ V9.5 SOP 에 명시 |
| F6 (push/pull mismatch) | ✅ 사용자 의도 trigger = push |
| F7 (ceremony 무용) | ✅ 5→2 transition |
| F8 (AI 다중 worker 모델 미정의) | ✅ Agent Teams in-process 명시 |
| F9 (Backlog 자동 분해 부재) | ✅ AI Conductor 가 SSOT 기반 자율 분해 |

## 🔗 관련

- `docs/_archive/governance-2026-05/V9_5_Single_Session_Output_Centric.md` — V9.5 본문 (archived 2026-05-08, supersede: CLAUDE.md §3 v10.3)
- `docs/_archive/governance-2026-05/V9_4_AI_Centric_Governance.md` — V9.4 (archived, supersede: CLAUDE.md §2 + §3)
- `docs/4. Operations/Multi_Session_Workflow.md` — V9.5 갱신 후 Single Session SOP
- `docs/2. Development/2.5 Shared/team-policy.json` — `governance_model.operating_model.default: single_session_conductor`
