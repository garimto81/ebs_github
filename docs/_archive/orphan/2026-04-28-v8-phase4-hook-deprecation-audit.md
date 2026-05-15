---
title: v8.0 Phase 4 — Deprecated Hooks Audit (branch_guard + session_branch_init)
owner: conductor
tier: internal
status: audit-complete
last-updated: 2026-04-28
related:
  - docs/4. Operations/Plans/v8-team-simplification.plan.md (Phase 4-5)
  - docs/4. Operations/Conductor_Backlog/v8-phase9-governance-decisions.md (governance freeze)
  - .claude/hooks/branch_guard.py (deprecated since v5.0)
  - .claude/hooks/session_branch_init.py (deprecated since v5.0)
  - .claude/hooks/governance_check.py (대체 hook, IMPR-3 v7.1)
confluence-page-id: 3818881608
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818881608/EBS+v8.0+Phase+4+Deprecated+Hooks+Audit+branch_guard+session_branch_init
mirror: none
---

# Phase 4 Audit — Deprecated Hooks Disposition

## Executive Summary

두 hook 모두 v5.1+ 시스템에서 **redundant**. governance_check.py + `claude -w` 네이티브가 모든 기능 대체. **단계적 disable + 1주 모니터링 후 file 삭제** 권고.

```
+------------------------------------------------------+
|                                                      |
|  branch_guard.py    →  대체: governance_check.py    |
|  session_branch_init →  대체: claude -w 네이티브    |
|                                                      |
|  결론: 두 hook 모두 안전 deprecation 가능            |
|        단, 단계적 진행 + 1주 모니터링 권고          |
|                                                      |
+------------------------------------------------------+
```

## 1. branch_guard.py 분석

### 현재 동작 (PreToolUse Bash matcher)

| Phase | 차단 대상 | 코드 ref | v5.1+ 대체 |
|:-:|---------|---------|-----------|
| 1 | 팀 세션 → main push | L42 `PUSH_MAIN_RE` | ✅ `governance_check.py` L128 동일 패턴 차단 |
| 2 | 팀 세션 → main commit | L43 `COMMIT_RE` | ✅ `governance_check.py` `git_config` 카테고리 |
| 3 | subdir 세션 → git checkout/switch (HEAD 오염 방지) | L45 `CHECKOUT_BRANCH_RE` | ✅ v5.0 subdir mode `forbidden` (team-policy.json L48) → 불필요 |
| 4 | Conductor → team branch commit (warn-once) | override mechanism | ⚠️ 낮은 가치, governance_check 미커버 (low risk) |
| 5 | Session-pinned branch tracking + index lock 대기 | `.claude/.session-branches/` | ⚠️ shared HEAD race 완화 — sibling worktree 강제로 race window 자체 제거됨 |

### 외부 의존성

- import: `_common.py` (detect_team, read_payload, emit, PROJECT)
- 사용 데이터: `.claude/.branch-guard-overrides/`, `.claude/.session-branches/`, `.git/index.lock`
- 코드 라인: ~10KB (300+ 라인 추정)

### deprecation 영향

| 영향 | 평가 |
|------|------|
| 기능 대체 완전성 | 95% (Phase 1-3 완전 대체, Phase 4 warn-once 만 손실) |
| Phase 4 손실 risk | 낮음 (Conductor 가 team branch 에 commit = 의도적 cherry-pick 케이스 only) |
| 외부 ref 정리 양 | 9 docs (Multi_Session_Workflow, SKILL.md, V5_Migration_Plan, .claude/commands/team-merge.md, lock files) |

## 2. session_branch_init.py 분석

### 현재 동작 (SessionStart hook)

| 기능 | 동작 | v5.1+ 대체 |
|------|------|-----------|
| 1. subdir 모드 감지 | cwd 가 `C:/claude/ebs/team{N}-*/` 패턴 | ✅ v5.0 subdir 자체 forbidden |
| 2. subdir 시 sibling worktree 권고 안내 | sys.stderr 출력 | ✅ `claude -w` 네이티브 자동 처리 |
| 3. sibling worktree 시 자동 `work/{team}/{date}-{slug}` checkout | git checkout | ✅ `claude -w --branch work/team{N}/<slug>` 명시 |
| 4. Conductor 세션 → main 유지 (no-op) | conductor 감지 후 return | ✅ Mode A default 와 동일 의도 |

### 외부 의존성

- import: `_common.py` (detect_team, read_payload, PROJECT)
- 코드 라인: ~5KB (100+ 라인 추정)
- 다른 hook 의 ref: **없음** (active_work_reminder.py 의 grep 결과 = 0 — import X)

### deprecation 영향

| 영향 | 평가 |
|------|------|
| 기능 대체 완전성 | 100% (claude -w v2.1.50+ 가 native 대체) |
| 손실 risk | 매우 낮음 (sibling worktree 강제 정책과 정확 일치) |
| 외부 ref 정리 양 | 8 docs (Multi_Session_Workflow, V5_Migration_Plan, branch_guard.py 주석 ref, lock files) |

## 3. 대체 mechanism 매핑

```
branch_guard.py 의 9 가지 기능
        ↓
+------------------+--------------------------------+
|                  |                                |
|  Phase 1-3       |  Phase 4-5                     |
|  (95% 코어 차단)  |  (race 완화, low value)        |
|                  |                                |
|  ↓ 대체           |  ↓ 대체 또는 제거              |
|                  |                                |
|  governance_     |  - sibling worktree 강제 →     |
|  check.py        |    race window 자체 제거       |
|  (IMPR-3 v7.1)   |  - warn-once 는 운영 가치 낮음 |
|                  |                                |
+------------------+--------------------------------+

session_branch_init.py 의 4 가지 기능
        ↓
모두 → claude -w --branch (Claude Code v2.1.50+ 네이티브)
```

## 4. 위험 평가 (단계적 진행 path)

| Phase 4-Sub | 동작 | 위험 | 롤백 |
|:--:|------|:---:|:---:|
| **4-pre** | settings.json 에서 두 hook 등록 제거 (file 보존) | **낮음** | settings.json revert 1 commit |
| **4-monitor** | 1주 모니터링 (Mode A/B 모두) | - | - |
| **4-rm** | hook file 삭제 + ref doc 정리 (17 docs) | **중간** | git restore from backup tag |

**P0 차단 사유** (이전 turn): file 만 삭제 시 settings 활성 → SessionStart fail. **올바른 순서 = 4-pre 먼저, 4-monitor, 4-rm 마지막**.

## 5. Mode A 한계 적용

| Mode A 한계 | Phase 4 적용 | 평가 |
|------------|------------|------|
| destructive_system | hook 비활성화 = 시스템 변경 | ⚠️ 적용 — 사용자 명시 필요 |
| user_intent_change | 사용자가 Phase 4 진행 명시 (이번 turn) | ✅ user intent 일치 |
| user_memory_decisions | 사용자 critic 보고서 권고 + Plan 문서에 명시 | ✅ 일치 |
| external_messaging / git_config | 무관 | - |

→ **사용자 명시 + 단계적 진행 시 Mode A 안전 영역**.

## 6. 권고 진행 path (사용자 confirmation 후)

```
사용자 confirm "Phase 4-pre 진행"
        ↓
1. settings.json edit (두 hook 등록 제거)
2. atomic commit (file 보존, reversible)
        ↓
1주 monitoring (governance_check 가 충분 대체하는지)
        ↓
사용자 confirm "Phase 4-rm 진행"
        ↓
3. hook file 삭제 (branch_guard.py + session_branch_init.py)
4. ref doc 정리 (17 docs strikethrough or 삭제)
5. atomic commit
```

## 7. 안전 net (이미 적용)

- **backup tag**: `backup-pre-v8-2026-04-28` — 모든 변경 롤백 가능
- **governance_freeze**: until 2026-05-28 — 추가 governance proposal 차단
- **work branch 보존**: `work/conductor/v8-phase1-team-pr-merge` — 이전 Phase 1 시도 reference

## 8. 결론

| 결정 항목 | 권고 |
|----------|------|
| branch_guard 진짜 redundant? | **YES (95%)** — Phase 4-5 의 race tracking 만 unique 기능, 가치 낮음 |
| session_branch_init 진짜 redundant? | **YES (100%)** — `claude -w` 가 완전 대체 |
| 즉시 file 삭제? | **NO** — settings 활성 = SessionStart fail. 단계적 진행 필수 |
| 권고 path | **4-pre (settings edit) → 1주 monitor → 4-rm (file + ref)** |
| 1주 monitor 의 의미 | governance_check 가 cross-session race 차단 충분성 검증 |

## 9. 다음 turn 사용자 결정 요청

| 옵션 | 동작 |
|------|------|
| **`Phase 4-pre 진행`** | settings.json 두 hook 등록 제거 (file 보존) — 가장 안전 |
| **`Phase 4 전체 진행`** | 4-pre + 4-rm 동시 (file + ref doc 정리) — 1주 monitor 생략 |
| **`hold`** | 본 audit 만 보존, 진행 보류 |
| **`reject`** | hook 보존 결정 |

**제 권장**: `Phase 4-pre 진행`. 1주 monitor 후 4-rm 결정. 점진적 안전 path.

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-04-28 | 최초 audit (사용자 결정 "Phase 4 분석") |
