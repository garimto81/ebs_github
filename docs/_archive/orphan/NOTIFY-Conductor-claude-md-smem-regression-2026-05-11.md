---
title: NOTIFY-Conductor — root CLAUDE.md 가 SMEM init PR #214 로 덮어씀 (cross-stream 영향)
owner: stream:S2 (Lobby) → conductor
target: conductor (main session + 6 Stream worktrees)
tier: notify
status: OPEN
created: 2026-05-11
trigger: S2 autonomous iteration — `git reset --hard origin/main` 시 SMEM 전용 CLAUDE.md 가 worktree 에 주입되는 현상 감지
github-pr-source: 214 (SMEM Stream Initialization)
severity: P2 (Conductor session 진입점 오염, Stream worktree 는 .team 이 SSOT 이므로 행동 영향 없음)
mirror: none
---

# NOTIFY-Conductor — root `CLAUDE.md` 가 SMEM 전용으로 덮어씀

## 발신

stream:S2 (Lobby) — autonomous iteration cycle 2 (2026-05-11).

## 수신

conductor (main session) — `CLAUDE.md` 는 S2 의 `meta_files_blocked` 이므로 S2 직접 정정 불가.

## 발견 경위

S2 worktree 에서 PR #233 머지 후 `git reset --hard origin/main` 실행 → 로컬 `CLAUDE.md` 가
다음 내용으로 변경됨:

```
# Conductor Memory Stream (Optional, cross-cutting) (SMEM) Worktree

## 🎯 Your Identity
You are working as **Conductor Memory Stream (Optional, cross-cutting)** in the multi-session orchestration.
```

원인 추적:

| 커밋 | 일자 | 영향 |
|------|------|------|
| `a18b3d7e` `docs(claude.md): v1.0.0 미니멀 모델 재설계` | 2026-05-07 이전 | EBS Conductor v1.0.0 (정상 SSOT) |
| `8387779e` `[SMEM] Stream Initialization - Conductor Memory (Optional) (#214)` | 2026-05-11 | `chore(ebs-memory): setup_stream_worktree.py initial customization (hooks + CLAUDE.md + settings.local)` commit 이 root `CLAUDE.md` 를 SMEM 전용으로 overwrite 후 squash merge |

## 핵심 모순

`tools/orchestrator/team_session_start.py` 의 `init_commit_and_push()` 주석:

```
"""Stream activation marker만 main에 commit (stream-specific 파일은 워크트리 로컬)

잘못된 패턴 (제거됨):
  .team, START_HERE.md, CLAUDE.md(override) → main 머지 → 6 stream 모두 conflict

올바른 패턴:
  .orchestrator/streams/{team_id}.activated 만 main 머지
"""
```

이 spec 은 명확히 "stream-specific CLAUDE.md 는 main 에 머지 안 함" 인데, PR #214 가 두 commit
(setup customization + marker) 모두 포함한 채 squash merge 되어 spec 위반.

## 영향 범위

| 영역 | 영향 | 차단성 |
|------|------|:------:|
| Conductor (main) session 진입 | CLAUDE.md 가 SMEM 전용 텍스트 → 정체성 오인 가능 | P2 |
| S1~S11 worktrees 의 SessionStart hook | `.team` 이 SSOT 이므로 정체성은 보호됨 | 무영향 |
| 새 worktree clone (setup 미실행) | main 의 잘못된 CLAUDE.md 가 그대로 노출 | P2 |
| Stream worktree `git reset --hard origin/main` | 로컬 CLAUDE.md 가 SMEM 전용으로 오염 | P3 (재현 가능, 워크트리 로컬 영향) |

## Conductor 권장 행동

1. **즉시**: `CLAUDE.md` 를 a18b3d7e 시점 (EBS Conductor v1.0.0 미니멀 모델) 으로 복원.
   ```bash
   git checkout a18b3d7e -- CLAUDE.md
   git commit -m "fix(claude.md): revert SMEM regression — restore EBS Conductor v1.0.0"
   ```
2. **재발 방지**: `setup_stream_worktree.py` 의 CLAUDE.md customization 커밋 패턴 점검.
   - 옵션 (a): customization 을 .gitignore 화 (워크트리 로컬 only)
   - 옵션 (b): init PR 머지 시 CLAUDE.md 변경분 자동 제외 (filter 또는 amend)
   - 옵션 (c): squash 대신 init PR 의 marker commit 만 cherry-pick 정책
3. **검증**: 다른 cross-cutting Stream (S9 QA, S10-A, S10-W, S11) init PR (#211/212/213) 도
   동일 regression 가능성 점검.

## 차단 여부

본 NOTIFY 는 **차단성 아님** — `.team` SSOT 가 정체성을 보호하므로 Stream 작업은 영향 없음.
단, Conductor session 의 진입점 오염이 누적되면 사용자 경험 저하.

## Cross-Reference

- 원인 PR: https://github.com/garimto81/ebs_github/pull/214 (SMEM Stream Initialization)
- spec: `tools/orchestrator/team_session_start.py` 의 `init_commit_and_push()` 주석
- 이전 정상 commit: `a18b3d7e docs(claude.md): v1.0.0 미니멀 모델 재설계 + 7개 거버넌스 archive`
- 발견 cycle: S2 autonomous iteration 2 (PR 본 NOTIFY 가 포함된 PR)
