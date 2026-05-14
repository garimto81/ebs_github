---
title: Inter-Session Message Bus — Operational Runbook
owner: conductor
tier: internal
status: ACTIVE (Phase 5 통합 완료 후)
plan: C:/Users/AidenKim/.claude/plans/dreamy-fluttering-gem.md
last-updated: 2026-05-08
confluence-page-id: 3819274844
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819274844/EBS+Inter-Session+Message+Bus+Operational+Runbook
---

# EBS Inter-Session Message Bus — Runbook

> **목적**: 8 Stream 워크트리 간 실시간 메시지 버스 — `30s GitHub polling → 50ms MCP push` 전환.
> **상태**: Phase 4 Hardening 완료. Phase 5 통합 진행 시 본 runbook 활성.

## 1. 한 줄 요약

```
broker = http://127.0.0.1:7383/mcp (MCP StreamableHTTP, SQLite WAL backed)
```

각 Claude Code 세션이 `.mcp.json` 으로 broker에 연결 → publish_event / subscribe / acquire_lock 등 7 tools 자동 사용.

## 2. 아키텍처 (refresher)

```
                         broker.log (rotating 10MB × 3)
                         broker.pid / .port / .health
                                  │
   ┌──────────────────────────────┴────────────────────────────┐
   │  Local MCP Broker (Python asyncio + FastMCP)              │
   │  http://127.0.0.1:7383/mcp                                │
   │                                                           │
   │  ┌─ 7 Tools ─────────────────────────────────────────┐    │
   │  │ publish_event(topic, payload, source)             │    │
   │  │ subscribe(topic, from_seq?, timeout_sec?)         │    │
   │  │ broadcast(payload, source)                        │    │
   │  │ unsubscribe(subscription_id)                      │    │
   │  │ discover_peers()                                  │    │
   │  │ get_history(topic, since_seq?, limit?)            │    │
   │  │ acquire_lock(resource, holder, ttl_sec)           │    │
   │  │ release_lock(resource, holder)   (helper)         │    │
   │  └───────────────────────────────────────────────────┘    │
   │                                                           │
   │  state ─ SQLite WAL (.claude/message_bus/events.db)       │
   │   - events(seq, topic, source, ts, payload)               │
   │   - locks(resource, holder, expires_at)                   │
   │                                                           │
   │  optional: GitHub Issue mirror (broker death fallback)    │
   └────────┬───────────────┬───────────────┬──────────────────┘
            │ StreamableHTTP │               │ ... (8+ MCP clients)
            ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ S1 sess  │    │ S2 sess  │    │ S3 sess  │ ...
    │ .mcp.json│    │ .mcp.json│    │ .mcp.json│
    └──────────┘    └──────────┘    └──────────┘
```

## 3. 일상 운영

### 3.1 broker 시작

```bash
# Foreground (development / debugging)
python tools/orchestrator/start_message_bus.py

# Background detached (production)
python tools/orchestrator/start_message_bus.py --detach

# Custom port
python tools/orchestrator/start_message_bus.py --port 7384
```

### 3.2 health probe

```bash
python tools/orchestrator/start_message_bus.py --probe
# Returns JSON:
# {
#   "pid": 12345,
#   "pid_alive": true,
#   "port": 7383,
#   "port_open": true,
#   "alive": true
# }
```

### 3.3 broker 중지

```bash
python tools/orchestrator/stop_message_bus.py            # graceful (10s)
python tools/orchestrator/stop_message_bus.py --force    # 즉시 kill
```

### 3.4 로그 확인

```bash
tail -f C:/claude/ebs/.claude/message_bus/broker.log
# 형식: 2026-05-08 17:15 [INFO] publish topic=stream:S1 source=S1 seq=42
```

### 3.5 events.db 직접 query

```bash
sqlite3 C:/claude/ebs/.claude/message_bus/events.db
> SELECT topic, source, COUNT(*) FROM events GROUP BY topic, source;
> SELECT * FROM events ORDER BY seq DESC LIMIT 10;
> SELECT * FROM locks WHERE expires_at > datetime('now');
```

## 4. Phase 5 통합 절차 (Track A 완료 후)

### 4.1 사전 조건

| 조건 | 검증 명령 |
|------|----------|
| 모든 8 audit PR 머지 완료 | `gh pr list --label consistency-audit --state merged | wc -l` = 9 |
| Track A 통합 검증 통과 | `python tools/doc_discovery.py --impact-of "docs/1. Product/Foundation.md"` = 0 drift |
| feat/message-bus Phase 4 완료 | 본 runbook 존재 |

### 4.2 통합 단계 (사용자 진입점 0)

```
Step 1: feat/message-bus → main PR 생성
   gh pr create --base main --head feat/message-bus \
       --title "feat: inter-session message bus (Phase 5 통합)" \
       --body "Plan: C:/Users/AidenKim/.claude/plans/dreamy-fluttering-gem.md"

Step 2: PR 머지 (auto-merge OK)

Step 3: 각 worktree 에 .mcp.json 배포 (한 worktree씩, 검증)
   cd C:/claude/ebs-foundation
   python tools/orchestrator/setup_stream_worktree.py --stream S1 \
       --config docs/4. Operations/team_assignment_v10_3.yaml
   # → .mcp.json 자동 생성

Step 4: broker 첫 시작 (사용자 또는 자동)
   python tools/orchestrator/start_message_bus.py --detach

Step 5: 검증 — 각 worktree 에서 publish_event tool 호출 가능
   (Claude Code 세션 진입 시 .mcp.json 자동 인식)
```

### 4.3 hook 자동 기동 통합 (선택, Phase 5 끝에)

`orch_SessionStart.py` 에 broker probe + auto-start 로직 추가:

```python
def ensure_broker():
    p = subprocess.run(
        [sys.executable, "tools/orchestrator/start_message_bus.py", "--probe"],
        capture_output=True, text=True, timeout=2,
    )
    if p.returncode != 0:
        # broker dead → auto-start detached
        subprocess.Popen(
            [sys.executable, "tools/orchestrator/start_message_bus.py", "--detach"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.DETACHED_PROCESS if sys.platform == "win32" else 0,
        )
```

## 5. Topic 컨벤션

| 패턴 | 사용 | ACL |
|------|-----|------|
| `stream:S{N}` | Stream 진행 상황 (DONE / BLOCKED / ETA) | 해당 source 만 |
| `cascade:<file>` | cascade 영향 advisory | 모든 source |
| `defect:<id>` | defect 보고 | 모든 source |
| `*` (broadcast) | 전체 알림 (e.g., shutdown) | 모든 source |
| `bench-*`, `test-*`, `poc-*` | 개발/테스트 | 모든 source |
| `bus:*` | 예약 (broker only) | 사용 금지 |

## 6. Troubleshooting

| 증상 | 원인 | 조치 |
|-----|-----|-----|
| `port 7383 in use` | 다른 프로세스 점유 | port range scan 자동 (7383-7393) |
| `stale PID found` | broker 비정상 종료 | start_message_bus.py 자동 cleanup |
| publish 응답 없음 | broker dead | `--probe` → 결과 따라 restart |
| subscribe 항상 timeout | dispatcher state 손실 | broker restart (events.db 안전) |
| `ACL denied` | source 가 stream:S{N} 위반 | source 확인, stream id 일치 시 publish |
| broker.log 폭발 | 과도한 publish | RotatingFileHandler 가 10MB × 3 자동 회전 |
| Lock contention 무한 retry | TTL 너무 김 | acquire_lock ttl_sec 5~10 권장 |

## 7. 검증된 성능 (Phase 1-4)

| 항목 | 측정값 | 목표 (Plan §7) |
|------|-------|--------------|
| publish RTT (single client) | 3.0ms avg / 4.5ms p99 | <200ms ✓ |
| publish RTT (8 concurrent) | 23.4ms avg / 54.6ms p99 | <500ms ✓ |
| throughput sustained | 105 RPS | 800 RPS worst-case 견딤 |
| WAL durability (kill -9) | 50/50 events 복구 | 100% ✓ |
| Cascade race (240 ops) | 0 race condition | 0 race ✓ |
| Lock concurrent acquire | 정확히 1 winner | 정확 ✓ |

## 8. 폴더 + 파일 reference

```
C:/claude/ebs/
├── .claude/
│   ├── locks/
│   │   ├── broker.pid          # 단일 broker PID
│   │   ├── broker.port         # 사용 중 port
│   │   └── broker.health       # heartbeat
│   └── message_bus/
│       ├── events.db           # SQLite WAL
│       ├── events.db-wal
│       ├── events.db-shm
│       └── broker.log          # rotating 10MB × 3
└── tools/
    └── orchestrator/
        ├── start_message_bus.py
        ├── stop_message_bus.py
        └── message_bus/
            ├── server.py        # FastMCP entry + 7 tools + ACL hook + logger
            ├── store.py         # SQLite WAL store + lock support
            ├── dispatcher.py    # in-memory wake-up
            ├── topics.py        # Topic ACL
            ├── github_mirror.py # G fallback channel
            └── tests/
                ├── pub_demo.py
                ├── sub_demo.py
                ├── latency_bench.py
                ├── test_concurrent_8sessions.py
                ├── test_lock_contention.py
                ├── test_broker_death.py
                └── test_cascade_race.py
```

## 9. 통합 후 사용자 진입점

**0 추가**. VSCode 폴더 클릭 + "작업 시작" 입력 = 그대로.
- Hook 이 broker 자동 기동
- Claude 가 자율적으로 publish/subscribe 호출
- cascade race / dependency unblock 즉시 반영

## 10. Plan 5 Phase 진행 상태

| Phase | 상태 | 산출물 |
|-------|-----|------|
| 0. 격리 셋업 | ✅ | feat/message-bus + ebs-message-bus-dev worktree |
| 1. PoC | ✅ | 2 tools, 3ms RTT, MCP push spec 검증 |
| 2. MVP | ✅ | 7 tools, ACL, 8 client 400/400, lock 4/4 PASS |
| 3. Hybrid | ✅ | supervisor (port lock + PID + heartbeat), GH mirror, kill -9 durability |
| 4. Hardening | ✅ | broker.log, cascade race 240/240 PASS |
| 5. ★통합★ | ⏳ | Track A 완료 + main PR + .mcp.json 배포 |

---

## 11. v10.4 9-Session Matrix Integration (2026-05-11)

> v11 broker(@7383) 위에 사용자 6 역할(orchestrator + dev + gap 분석 + gap 작성 + QA + 보조)을 매핑한 9-세션 통합. 변경 최소: `topics.py` 1줄 + `team_assignment_v10_3.yaml` 4 신규 stream + ACL 등록.

### 11.1 신규 Topic Prefix

```python
# tools/orchestrator/message_bus/topics.py — v10.4 변경
_STREAM_TOPIC_RE = re.compile(r"^stream:(S[\w-]+)$")  # S10-A/S10-W 대시 허용
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "audit:", "pipeline:")  # pipeline:* 추가
```

### 11.2 9-세션 Pub/Sub 매트릭스

| Stream | Init PR | publish 권한 | subscribe |
|--------|---------|------------|-----------|
| S0 Conductor (main) | — | `bus:*`, `pipeline:*`, broadcast | `*` |
| S2 Lobby (ebs-lobby-stream) | — (기존 활성) | `stream:S2`, `cascade:*`, `pipeline:build-*` | `pipeline:spec-patched`, `cascade:*` |
| S7 Backend (ebs-backend-stream) | — (기존) | `stream:S7`, `cascade:*`, `pipeline:build-*` | `pipeline:spec-patched`, `cascade:*` |
| S3 CC (ebs-cc-stream) | — (기존) | `stream:S3`, `cascade:*`, `pipeline:build-*` | `pipeline:spec-patched`, `cascade:*` |
| S8 Engine (ebs-engine-stream) | — (기존) | `stream:S8`, `cascade:*`, `pipeline:build-*` | `pipeline:spec-patched`, `cascade:*` |
| S9 QA (ebs-qa) | #211 | `stream:S9`, `pipeline:qa-pass`, `pipeline:qa-fail` | `pipeline:build-success`, `cascade:*` |
| S10-A Gap 분석 (ebs-gap-audit) | #212 | `stream:S10-A`, `pipeline:gap-classified`, `defect:*` | `pipeline:qa-fail`, `cascade:build-fail` |
| S10-W Gap 작성 (ebs-gap-write) | (S10-A 머지 후) | `stream:S10-W`, `pipeline:spec-patched` | `pipeline:gap-classified` |
| S11 Dev Assist (ebs-devops) | #213 | `stream:S11`, `pipeline:env-ready`, `pipeline:env-broken` | `cascade:build-fail`, `pipeline:build-fail` |
| SMEM Memory (ebs-memory) | #214 | `audit:memory-snapshot`, `audit:memory-rotate` | `*` (audit only) |

### 11.3 단방향 Pipeline

```
spec_drift_check.py ──pipeline:gap-classified──> [S10-A]
                                                    │
                                            (Type B/C) │
                                                    v
                                              [S10-W] ──pipeline:spec-patched──> 도메인 4
                                                                                       │
                                                                                       │ cascade:build-success
                                                                                       v
                                                                                  [S11] ──pipeline:env-ready──> [S9]
                                                                                                                  │
                                                                                                                  ├── qa-pass ──> close (S0)
                                                                                                                  └── qa-fail ──> [S10-A] (loop)
```

### 11.4 acquire_lock TTL 가이드

| 자원 종류 | TTL | 사용 stream |
|----------|-----|-----------|
| PRD 본문 편집 (`docs/1. Product/*_PRD.md`) | **300s (5분)** | S10-W 만 PR 발행, 도메인 owner 머지 |
| Conductor_Backlog ticket 신규 | 180s | S10-W, S0 |
| root `docker-compose.yml` | 180s | S11 |
| `Spec_Gap_Triage.md` (S0 owner) | 600s | S0 only |
| `team_assignment_v10_3.yaml` (meta) | 600s | S0 only |
| `MEMORY.md`, `CLAUDE.md` | 300s | S0 + SMEM |

### 11.5 Graceful Degradation (broker SPOF 대응)

| 시나리오 | 동작 |
|---------|------|
| broker 정상 | publish/subscribe push 모드 (~50ms) |
| broker down | `orchestrator_monitor.py --legacy` 30s polling fallback. GitHub Issue/PR = source of truth. |
| broker 재시작 | `subscribe(from_seq=<last>)` 로 missed event 최대 50건 replay (at-least-once 미보장) |
| 메시지 손실 | 각 handler idempotent 필수 (e.g. `if already_processed(seq): skip`) |

### 11.6 1주일 KPI (Issue #215 tracking)

| Day | Phase | 검증 |
|-----|-------|------|
| 1 | broker --detach + Phase 0 활성화 + 도메인 4 `docker compose up` | broker probe alive=true |
| 2 | 빌드 fix → `cascade:build-success`, smoke e2e → `pipeline:qa-fail` | 첫 e2e green |
| 3 | hand 시나리오 wire, drift -50, playwright 1 case | drift trending down |
| 4 | 1 hand 통과 + OutputEvent emit, drift -100 | 1 hand green |
| 5 | 2 hand e2e, mid-week review | 누적 KPI |
| 6 | 3 hand e2e, qa-fail re-triage, Schema drift -10 | regression 안정화 |
| 7 | **1 hand 통과 verification**, Open Spec_Gap ≤ 5 | **KPI 보고** |

### 11.7 Plan reference

- 전체 설계: `C:\Users\AidenKim\.claude\plans\kind-mapping-rivest.md`
- 신규 PRs: #211 S9 / #212 S10-A / #213 S11 / #214 SMEM
- KPI tracking Issue: #215
- yaml: `team_assignment_v10_3.yaml` v10.4.5 (5 cross-cutting future → streams 이관)
