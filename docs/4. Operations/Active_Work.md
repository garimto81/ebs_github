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
last-updated: 2026-04-22
generator: tools/active_work_claim.py (편집은 CLI 만 사용)
schema_version: 1
---

# Active Work (v5.1)

> **이 문서는 `tools/active_work_claim.py` 로만 편집합니다.** 수동 편집 시 구조 깨짐.

## Active Claims

<!-- CLAIMS_BEGIN -->
### Claim #9 — conductor: Foundation §5.3 Rive Manager 섹션 말미 이미지 삽입
```yaml
id: 9
team: conductor
task: Foundation §5.3 Rive Manager 섹션 말미 이미지 삽입
started: '2026-04-22T12:02:25Z'
scope:
- docs/1. Product/Foundation.md
- docs/1. Product/images/foundation/app-rive-manager.png
status: active
eta: 10min
```

<!-- CLAIMS_END -->

## Recently Released (last 24h)

<!-- RELEASED_BEGIN -->
### Claim #1 — conductor: v5.1 smoke test
```yaml
id: 1
team: conductor
task: v5.1 smoke test
started: '2026-04-22T02:16:23Z'
scope:
- dummy/test_only.md
status: released
eta: 5m
released: '2026-04-22T02:16:24Z'
```

### Claim #2 — conductor: Foundation.md v2026-04-22 재설계 전파 — 영향도 분석 및 수정 계획 수립
```yaml
id: 2
team: conductor
task: Foundation.md v2026-04-22 재설계 전파 — 영향도 분석 및 수정 계획 수립
started: '2026-04-22T10:26:28Z'
scope:
- docs/1. Product/**
- docs/2. Development/2.5 Shared/**
- docs/4. Operations/**
- docs/4. Operations/_plans/foundation-redesign-propagation-plan.md
status: released
eta: 2h
released: '2026-04-22T10:45:12Z'
```

### Claim #3 — team3: Foundation v11 재설계 대응 — team3 기획 문서 gap 분석 + Backlog 8 항목 등재
```yaml
id: 3
team: team3
task: Foundation v11 재설계 대응 — team3 기획 문서 gap 분석 + Backlog 8 항목 등재
started: '2026-04-22T10:31:36Z'
scope:
- docs/2. Development/2.3 Game Engine/Backlog.md
- docs/2. Development/2.3 Game Engine/Backlog/**
status: released
eta: 1h
released: '2026-04-22T10:34:24Z'
```

### Claim #4 — team3: B-331 harness /engine/health endpoint 구현 — Demo Mode fallback 지원
```yaml
id: 4
team: team3
task: B-331 harness /engine/health endpoint 구현 — Demo Mode fallback 지원
started: '2026-04-22T11:39:02Z'
scope:
- team3-engine/ebs_game_engine/lib/harness/server.dart
- team3-engine/ebs_game_engine/test/harness/**
- docs/2. Development/2.3 Game Engine/APIs/Harness_REST_API.md
- docs/2. Development/2.3 Game Engine/Backlog/B-331-harness-engine-health-endpoint.md
status: released
eta: 1h
released: '2026-04-22T11:45:53Z'
```

### Claim #5 — conductor: 회의 D3 GE 제거 결정 — Conductor 소유 5 지점 반영 (BS_Overview §7.4 GEM-* 폐기, §1 GE 행 축소, Foundation Ch.9 L610, 1. Product.md γ 교정, SG-004 SUPERSEDED)
```yaml
id: 5
team: conductor
task: 회의 D3 GE 제거 결정 — Conductor 소유 5 지점 반영 (BS_Overview §7.4 GEM-* 폐기, §1 GE 행 축소,
  Foundation Ch.9 L610, 1. Product.md γ 교정, SG-004 SUPERSEDED)
started: '2026-04-22T11:42:23Z'
scope:
- docs/1. Product/Foundation.md
- docs/1. Product/1. Product.md
- docs/2. Development/2.5 Shared/BS_Overview.md
- docs/4. Operations/Conductor_Backlog/SG-004-gfskin-zip-format.md
- docs/4. Operations/Conductor_Backlog/B-209-ge-d3-meeting-decision.md
- docs/4. Operations/Foundation_Alignment_Plan.md
status: released
eta: 1h
released: '2026-04-22T11:47:13Z'
```

### Claim #6 — team3: B-332 Engine 응답 = 게임 상태 SSOT 명시 (API-04 3 문서)
```yaml
id: 6
team: team3
task: B-332 Engine 응답 = 게임 상태 SSOT 명시 (API-04 3 문서)
started: '2026-04-22T11:50:12Z'
scope:
- docs/2. Development/2.3 Game Engine/APIs/Harness_REST_API.md
- docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md
- docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md
status: released
eta: 30m
released: '2026-04-22T11:52:54Z'
```

### Claim #7 — conductor: Foundation.md 본문에 Rive Manager (구 Graphic Editor) 독립 섹션 신설 — D3 회의 결정 SSOT 반영
```yaml
id: 7
team: conductor
task: Foundation.md 본문에 Rive Manager (구 Graphic Editor) 독립 섹션 신설 — D3 회의 결정 SSOT 반영
started: '2026-04-22T11:53:13Z'
scope:
- docs/1. Product/Foundation.md
- docs/4. Operations/Conductor_Backlog/B-209-ge-d3-meeting-decision.md
status: released
eta: 40min
released: '2026-04-22T11:57:23Z'
```

### Claim #8 — team2: api D1=7 docs prefix fix — Backend_HTTP.md /api/v1 prefix 누락 보정
```yaml
id: 8
team: team2
task: api D1=7 docs prefix fix — Backend_HTTP.md /api/v1 prefix 누락 보정
started: '2026-04-22T11:54:29Z'
scope:
- docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
status: released
eta: 30m
released: '2026-04-22T12:02:19Z'
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
