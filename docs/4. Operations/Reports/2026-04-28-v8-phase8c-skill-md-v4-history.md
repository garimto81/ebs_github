---
title: SKILL.md (team) — v4.0/v4.1 폐기 이유 (Archived 2026-04-28)
status: archived
archived_date: 2026-04-28
archived_phase: v8.0 Phase 8c
parent: .claude/skills/team/SKILL.md (v5.1)
purpose: SKILL.md 압축, history 섹션 보존
---

# SKILL.md — v4.0/v4.1 폐기 이유 (Archived)

> 본 섹션은 2026-04-28 v8.0 Phase 8c 마이그레이션으로 main SKILL.md 에서 archive 이동되었다.
> v5.0/v5.1 전환의 역사적 맥락 보존 목적.

## v4.0/v4.1 폐기 이유

| v4.0 가정 | 현실 | v5.0 대안 |
|-----------|------|-----------|
| "매 작업 자동 main push" | 플랫폼이 main push 차단 | PR + auto-merge workflow |
| Manifest / conflict-scan / revise / safety-gate | 복잡도만 증가, 실제 race 못 막음 | GitHub Actions `concurrency:` group |
| `session_branch_init` subdir 허용 | shared HEAD 오염 지속 발생 | sibling worktree 강제 |
| Conductor 직접 push 특권 | 4 팀 일관성 깨짐 | Conductor 도 PR |

## 관련 마이그레이션

- v4.0/v4.1: 자체 orchestration (10 Phase, manifest/conflict-scan)
- v5.0: 업계 표준 재사용 (sibling worktree + PR + concurrency)
- v5.1: L0 Pre-Work Contract 추가
- v8.0 Phase 8c: 본 섹션 archive 이동
