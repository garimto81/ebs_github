---
title: Stream Entry Guide v11 — 사용자 진입 가이드
owner: conductor
tier: internal
status: ACTIVE
spec_ref: docs/4. Operations/Multi_Session_Design_v11.md
supersedes: docs/2. Development/2.5 Shared/Stream_Entry_Guide.md
last-updated: 2026-05-08
confluence-page-id: 3819078225
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078225/EBS+Stream+Entry+Guide+v11
mirror: none
---

# Stream Entry Guide v11

> **목적**: EBS 멀티 세션 환경에서 사용자가 Stream 작업 시작 시 진입 가이드.
> **변경 (v10.3 → v11)**: 사용자 행동 변화 **0**. 내부 latency 만 30s → 50ms 개선.

## ⚡ 1줄 요약

```
VSCode 폴더 클릭 → "작업 시작" 입력 → 자율 진행
```

**v10.3 와 동일**. 차이는 hood 안에서 broker push 로 latency 250x~9000x 개선.

## §1. 사용자 진입 (변경 없음)

### Step 1: VSCode 폴더 열기

자기 stream 의 워크트리 폴더 선택:

| Stream | 폴더 |
|:------:|------|
| S1 Foundation | `C:/claude/ebs-foundation` |
| S2 Lobby | `C:/claude/ebs-lobby-stream` |
| S3 Command Center | `C:/claude/ebs-cc-stream` |
| S4 RIVE Standards | `C:/claude/ebs-rive-standards` |
| S5 AI Track | `C:/claude/ebs-ai-track` |
| S6 Prototype | `C:/claude/ebs-prototype` |
| S7 Backend | `C:/claude/ebs-backend-stream` |
| S8 Engine | `C:/claude/ebs-engine-stream` |

### Step 2: 자동 진행 (v11 효과)

VSCode 진입 시 자동 발생:

```
SessionStart hook
   │
   ├─ ① identity 주입 (.team SSOT 검증)
   │
   ├─ ② ensure_message_bus()  ← v11 (Phase 5 통합)
   │     ├─ broker 살아있나? (1s probe)
   │     │   ├─ alive  → "✅ broker alive"
   │     │   └─ dead   → DETACHED auto-start (5s wait)
   │     └─ silent skip if 시작 실패 → v10.3 fallback
   │
   ├─ ③ check_dependency_status()  ← v11 (Phase C)
   │     ├─ broker subscribe(stream:upstream, 5s) — ~50ms
   │     ├─ broker dead → gh pr list (v10.3 fallback)
   │     └─ "READY" or "BLOCKED by S{N}"
   │
   └─ ④ START_HERE.md 자동 갱신 (READY/BLOCKED 표시)
```

### Step 3: 사용자 입력

```
작업 시작
```

자동 진행:
- `tools/orchestrator/team_session_start.py`
- subscribe-first dependency check (~50ms)
- GitHub Issue + Draft PR 자동 생성
- `publish_event(stream:S{N}, IN_PROGRESS)` (broker)

### Step 4: 작업 진행

PreToolUse hook 자동 검증:
- L1-L7 7중 다층 방어
- L5 cascade lock (Product SSOT 편집 시 자동 acquire)

PostToolUse hook 자동 정리:
- L5 cascade lock 자동 release (Edit 끝나면)

### Step 5: 작업 완료

```
작업 완료
```

자동 진행:
- `tools/orchestrator/team_session_end.py`
- PR ready + auto-merge
- `publish_event(stream:S{N}, DONE, pr=#N)` ← **의존 stream 즉시 wake (50ms)**

## §2. v11 효과 (사용자 관점)

### 2.1 Latency 비교

| 지표 | v10.3 | v11 | 개선 |
|------|------:|----:|------|
| Dependency wake (S1 DONE → S2 시작) | 30s ~ 30분 (인덱스 catch-up) | ~50ms | **300x ~ 9000x** |
| Cascade race | 가끔 발생 (defect #138) | 0 (L5 lock) | ✓ |
| 수동 NOTIFY-*.md | 가끔 작성 | 0 | ✓ |
| Observer dashboard 신선도 | 평균 15s | ~50ms | 300x |

### 2.2 사용자 진입점 비교

| 단계 | v10.3 | v11 |
|------|:-----:|:---:|
| VSCode 폴더 열기 | 1 | 1 |
| "작업 시작" 입력 | 1 | 1 |
| 의존성 BLOCKED 시 진단 | 가끔 (~5분) | **0** |
| NOTIFY-*.md 작성 | 가끔 (~3분) | **0** |
| **합계** | 2 + α | **정확히 2** |

## §3. 신호 흐름 다이어그램

```
+----------------+                          +----------------+
| S1 Foundation  |                          | S2 Lobby       |
| (PR #170)      |                          | (blocked_by S1)|
+--------+-------+                          +--------+-------+
         |                                           |
         | team_session_end                          | team_session_start
         |   ├─ PR auto-merge                        |   ├─ subscribe(stream:S1, 5s)
         |   └─ publish_event(stream:S1, DONE) ----->|   └─ ✓ DONE found (~50ms)
         |                                           |
         |                                           | "작업 시작"
         v                                           v
   merged to main                                  진입 + 작업

         (broker = http://127.0.0.1:7383/mcp, push push 즉시 wake)
```

## §4. broker 운영 (사용자 인지 X)

### 4.1 자동 가동

- SessionStart hook 이 매 세션 진입 시 probe + auto-start
- 사용자 명시 명령 X
- broker 가동 상태 = `python tools/orchestrator/start_message_bus.py --probe`

### 4.2 broker dead 시

- subscribe → fallback to v10.3 polling (자동)
- publish_event → silent skip (작업 흐름 막지 않음)
- 사용자 진입점 = 변화 없음

### 4.3 dashboard 보기

```bash
python tools/orchestrator/orchestrator_monitor.py --config "docs/4. Operations/team_assignment_v10_3.yaml"
# v11 default = subscribe loop (~50ms 갱신)
# --legacy = v10.3 polling (30s 갱신)
```

## §5. Topic 컨벤션

| 패턴 | 사용 | ACL (v11 strict) |
|------|------|---|
| `stream:S{N}` | Stream 진행 (DONE / IN_PROGRESS / BLOCKED) | 해당 source 만 |
| `cascade:<file>` | Product SSOT 편집 advisory | 모든 source |
| `defect:<id>` | defect 보고 | 모든 source |
| `audit:<topic>` | audit 신호 | 모든 source |
| `*` | broadcast | 모든 source |
| `bench-/test-/poc-` | 개발/테스트 | EBS_BUS_DEV_MODE=1 |
| `bus:*` | broker 예약 | 사용 금지 |

## §6. Troubleshooting

| 증상 | 원인 | 조치 |
|------|------|-----|
| 진입 시 "🔄 broker dead, auto-starting" | 첫 세션 진입 | 정상. 5s 후 auto-start |
| BLOCKED 표시 안 풀림 | upstream PR 미머지 | upstream worktree 에서 작업 마무리 |
| `⛔ cascade lock held by S{N}` | 다른 stream 이 동일 cascade resource 편집 중 | 60s TTL 만료 후 재시도 또는 release_lock 명시 |
| broker 가동 확인 | `python tools/orchestrator/start_message_bus.py --probe` |
| broker 강제 재시작 | `python tools/orchestrator/stop_message_bus.py && python tools/orchestrator/start_message_bus.py --detach` |

## §7. v10.3 → v11 Migration 완료 (Edit History)

| 날짜 | PR | Phase | 효과 |
|------|----|-------|------|
| 2026-05-08 | #197 | A. spec + topics strict | v11 spec 작성, ACL strict |
| 2026-05-08 | #198 | B. hook publish + lock | cascade race 0, DONE auto-publish |
| 2026-05-08 | #199 | C. subscribe 전환 | dependency wake 50ms |
| 2026-05-08 | (이 PR) | D. verification + supersede | v10.3 frontmatter SUPERSEDED, e2e tests |

## §8. 참조

- v11 spec SSOT: [`Multi_Session_Design_v11.md`](../../4. Operations/Multi_Session_Design_v11.md)
- 전임자 v10.3 (frozen): [`Multi_Session_Design_v10.3.md`](../../4. Operations/Multi_Session_Design_v10.3.md)
- broker 운영: [`Message_Bus_Runbook.md`](../../4. Operations/Message_Bus_Runbook.md)
- Stream 매트릭스: [`team_assignment_v10_3.yaml`](../../4. Operations/team_assignment_v10_3.yaml)
