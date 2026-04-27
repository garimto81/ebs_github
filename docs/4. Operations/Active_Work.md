<!--
=================================================================
Active Work — EBS 멀티 세션 사전 조정 SSOT (v5.1, 2026-04-22)
=================================================================

**작업 시작 전 반드시 읽으시오**. 편집 전 여기에 entry 를 추가해야
다른 세션이 당신의 의도를 알 수 있습니다.

## Why this exists

v5.0 의 Git/PR merge gate 는 **reactive** — 충돌이 이미 발생한 뒤 처리.
v5.1 Active Work 는 **proactive** — 작업 시작 시점에 의도 공유로 충돌
회피. reactive 와 proactive 는 병렬로 작동 (L0 + L1/L2/L3).

## CCR draft (deprecated) 와의 차이

| CCR draft (폐기) | Active Work (v5.1) |
|------------------|---------------------|
| 변경 request 문서 (heavy, review cycle) | 활성 claim (lightweight, no review) |
| per-change 파일 | 단일 SSOT |
| docs/3. Change Requests/ (폴더 난립) | docs/4. Operations/Active_Work.md (1 파일) |
| 문서 작성 전 approval 필요 | 작업 시작 전 visibility 공유만 |
| 수 시간~일 | 수 초~분 |

CCR 은 governance 도구, Active Work 는 coordination 도구. 혼동 금지.

## How to use

### 작업 시작 시

1. 이 파일을 읽는다 (session-start hook 이 자동 전시)
2. 자기 작업 scope 가 다른 claim 과 겹치는지 확인:
   ```bash
   python tools/active_work_claim.py check --scope "path/glob,..."
   ```
3. 겹치면: 해당 claim owner 와 조율 (Slack/이슈 comment), 또는 scope 축소
4. 안 겹치면: claim 추가:
   ```bash
   python tools/active_work_claim.py add \
     --team team2 --task "API-01 path rename" \
     --scope "team2-backend/src/routers/series.py,docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md" \
     --eta 2h
   ```
5. 이 파일 auto-commit + push (CLI 가 수행)

### 작업 중 scope 갱신

discovery 로 추가 파일 편집 필요 시:
```bash
python tools/active_work_claim.py update --id <N> --add-scope "new/path/*"
```

### 작업 완료 시

PR merge 후 자동 release (`tools/team_v5_merge.py` 가 호출).
수동 해제: `python tools/active_work_claim.py release --id <N>`

## Schema

각 claim 은 아래 구조. machine-parseable YAML frontmatter in fenced block:

```yaml
id: <incrementing int>
team: <conductor|team1|team2|team3|team4>
task: <short title (≤80 chars)>
started: <ISO-8601 UTC>
scope:
  - <glob 또는 path>
  - ...
blocks: [<other team names that shouldn't overlap>]  # optional
depends_on: [<claim id>, ...]                         # optional
eta: <hours, e.g. "2h" or "30m">                     # optional
pr: <github pr url>                                   # after phase 2
status: <active|paused|released>
```

## 금지

- Claim 없이 편집 시작 금지 (hook 이 warning 표시. 긴급은 `--skip-claim` 허용하되 commit msg 에 사유 명시)
- 다른 team 의 claim 을 수동으로 release 금지 (owner 외 release 는 Conductor 만)
- Claim 을 열어둔 채 다음 작업 시작 금지 (claim 1개 = task 1개)
- 이 파일을 CLI 외 수동 편집 금지 (race condition 위험, 실수 유발). 구조 변경만 Conductor 수동 OK

## 관련

- 공식 정책: `docs/4. Operations/Multi_Session_Workflow.md` v5.1
- CLI: `tools/active_work_claim.py`
- Hook: `.claude/hooks/active_work_reminder.py` (session-start 전시)
- Migration: `docs/4. Operations/V5_Migration_Plan.md`

=================================================================
-->

---
title: Active Work — Multi-session coordination SSOT
owner: conductor
tier: contract
last-updated: 2026-04-27
generator: tools/active_work_claim.py (편집은 CLI 만 사용)
schema_version: 1
---

# Active Work (v5.1)

> **이 문서는 `tools/active_work_claim.py` 로만 편집합니다.** 수동 편집 시 구조 깨짐.

## Active Claims

<!-- CLAIMS_BEGIN -->
### Claim #10 — team3: B-338 harness 세션 persistence — disk snapshot + restart recovery
```yaml
id: 10
team: team3
task: B-338 harness 세션 persistence — disk snapshot + restart recovery
started: '2026-04-23T01:40:39Z'
scope:
- team3-engine/ebs_game_engine/lib/harness/**
- team3-engine/ebs_game_engine/test/harness/**
- docs/2. Development/2.3 Game Engine/APIs/Harness_REST_API.md
status: active
eta: 2h
```

### Claim #13 — team1: Phase 5 production readiness (build/docker/observability)
```yaml
id: 13
team: team1
task: Phase 5 production readiness (build/docker/observability)
started: '2026-04-27T06:56:24Z'
scope:
- team1-frontend/**
- docker/**
status: active
eta: 2h
```

<!-- CLAIMS_END -->

## Recently Released (last 24h)

<!-- RELEASED_BEGIN -->
### Claim #12 — conductor: IMPR-5: Handoff auto-diff tool — 5-Session Context Bleed 가시화 (audit 후속, free-tier zero-cost)
```yaml
id: 12
team: conductor
task: 'IMPR-5: Handoff auto-diff tool — 5-Session Context Bleed 가시화 (audit 후속, free-tier
  zero-cost)'
started: '2026-04-27T06:39:52Z'
scope:
- tools/handoff_diff.py
status: released
eta: 1h
released: '2026-04-27T06:41:56Z'
```

<!-- RELEASED_END -->

## Usage Quick Reference

```bash
# 작업 시작 전
python tools/active_work_claim.py list                          # 현재 모든 claim 보기
python tools/active_work_claim.py check --scope "team2/**"     # scope 충돌 확인

# 작업 시작
python tools/active_work_claim.py add \
    --team <team> --task "<title>" \
    --scope "path1,path2/**" [--eta 2h] [--blocks team3]

# 작업 중 scope 추가
python tools/active_work_claim.py update --id N --add-scope "new/*"

# 작업 완료 (team_v5_merge.py 가 자동 호출)
python tools/active_work_claim.py release --id N
```
