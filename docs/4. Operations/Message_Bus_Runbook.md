---
title: Inter-Session Message Bus — Operational Runbook
owner: conductor
tier: internal
status: ACTIVE (Phase 5 통합 완료 후)
plan: C:/Users/AidenKim/.claude/plans/dreamy-fluttering-gem.md
last-updated: 2026-05-08
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
