---
title: Multi-Session Orchestration Design v11 — Message Bus Push 기반
status: ACTIVE
last-updated: 2026-05-08
owner: conductor
tier: internal
supersedes: docs/4. Operations/Multi_Session_Design_v10.3.md
provenance:
  triggered_by: user_directive
  trigger_summary: "v10.3 polling → message bus push 전환"
  user_directive: "메시지 버스 기반으로 멀티 세션 워크플로우 v11 설계"
  trigger_date: "2026-05-08"
predecessors:
  - path: docs/4. Operations/Multi_Session_Design_v10.3.md
    relation: superseded
    reason: GitHub polling 30s → MCP broker push ~50ms 전환 (latency 250x 개선)
  - path: docs/4. Operations/Message_Bus_Runbook.md
    relation: continued
    reason: v11 의 핵심 인프라. PR #195 (commit b22ad74b) 통합 완료
confluence-page-id: 3818750393
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818750393/EBS+Multi-Session+Orchestration+Design+v11+Message+Bus+Push
---

## Edit History

| 날짜 | 버전 | 트리거 | 변경 |
|------|:----:|--------|------|
| 2026-05-08 | v11.0.0 | 사용자 directive — Message Bus 통합 후 워크플로우 재설계 | 최초 작성 (v10.3 supersede) |

## 🎯 Thesis

> **v10.3** = Architect-then-Observer + GitHub polling.
> **v11** = Architect-then-**Reactive** Observer + **Message Bus Push**.
>
> 사용자 진입점 동일 (VSCode 폴더 클릭 1회), 신호 매체만 in-host MCP broker (50ms push) 로 교체.
> *advisory 가 곧 event* + *blocking await 가 곧 dependency check*.

## Reader Anchor

이 문서는 EBS 멀티 세션 운영 SSOT 의 **차세대 (v11)**. 입구(현재 v10.3 ACTIVE) → 출구(v11 push 활성화 + v10.3 SUPERSEDED).

> **Phase 모델**: Phase 0 Architect Setup → Phase 1+ **Reactive** Observer Operation. v10.3 의 Phase 0 그대로 + Observer mode 만 진화.

---

## §1. 6 Streams 매트릭스 (변경 없음 — v10.3 계승)

상세 SSOT: [`team_assignment_v10_3.yaml`](./team_assignment_v10_3.yaml) (v11 에서 `topics:` 섹션 추가)

```
+------+------------------+----------------------------+--------+----------+
| ID   | 이름              | 흡수 폴더                  | Phase  | 의존     |
+------+------------------+----------------------------+--------+----------+
| S1   | Foundation       | (없음, 신설)                | P1     | -        |
| S2   | Lobby Stream     | team1-frontend/            | P2+P5  | S1       |
| S3   | CC Stream        | team4-cc/                  | P2+P5  | S1       |
| S4   | RIVE Standards   | (없음, 신설)                | P2     | S1       |
| S5   | AI Track         | (tools/ai_track 신설)       | P3     | S1       |
| S6   | Prototype        | integration-tests/         | P3     | S2,S3,S4 |
+------+------------------+----------------------------+--------+----------+
| S7   | Backend          | team2-backend/             | P5     | S1       |
| S8   | Engine           | team3-engine/              | P5     | S1       |
+------+------------------+----------------------------+--------+----------+
```

## §1.5 Product = SSOT, Cascade Routing (5 Layer 진화)

`docs/1. Product/` = **기준 SSOT**. v10.3 의 4 Layer 에 **L5 acquire_lock** 추가.

상세 매핑: [`Stream_Entry_Guide.md`](../2. Development/2.5 Shared/Stream_Entry_Guide.md). 정책 SSOT: [`Product_SSOT_Policy.md`](../1. Product/Product_SSOT_Policy.md).

### Cascade Routing 5 Layer (v11 신규 L5)

| Layer | 도구 / 파일 | 역할 |
|:-----:|------------|------|
| L1 | PRD frontmatter `derivative-of` + `if-conflict` | 정본 ↔ derivative 관계 선언 |
| L2 | `tools/doc_discovery.py --impact-of` | reverse-graph (변경 영향 list) |
| L3 | `orch_PreToolUse.py:cascade_advisory()` | hook 으로 Edit 직전 advisory + **publish_event(cascade:{file})** |
| L4 | `.github/workflows/scope_check.yml` | CI gate (Product Edit + derivative 동시 변경 강제) |
| **L5** | **`acquire_lock(resource="cascade:{file}", ttl=60)`** | **Edit 동안 점유 — race condition 영구 차단** |

**Edit 흐름 (v11)**:

```
S1 워크트리에서 Foundation.md Edit 시도
   ↓
orch_PreToolUse.py
   ├─ Layer 3 scope check: S1 의 owner 인가 → ✓
   ├─ Layer 2 cascade advisory:
   │   "Editing Foundation.md may affect: Lobby.md (S2), Command_Center.md (S3), ..."
   ├─ Layer 3 (v11): publish_event(topic="cascade:Foundation.md", impacted=[...])
   │   → 다른 stream 의 subscribe(topic="cascade:*") 즉시 wake
   └─ Layer 5: acquire_lock(resource="cascade:Foundation.md", holder=S1, ttl=60)
       → 다른 stream 이 같은 resource Edit 시도 시 lock 거부 → backoff retry
   ↓
Edit 진행 → commit → PR → release_lock (PostToolUse hook)
   ↓
Layer 4 scope_check.yml (PR 단계, 변경 없음)
```

## §2. Architect-then-Reactive Observer 모델 (v11)

```
                Phase 0
          [Architect Mode]                       (v10.3 와 동일)
                 │
                 │  Orchestrator: 90분 자율
                 │  - 설계서 + 도구 + GitHub 인프라
                 │  - 8 워크트리 폴더 + 모든 파일 사전 세팅
                 │  - .mcp.json 자동 배포 (Phase 5 통합)
                 │
                 v
          +------------------+
          | 게이트            |
          | - 산출물 검증      |
          | - 사용자 검토 1회  |
          +--------+---------+
                   │
                   v
                Phase 1+
          [Reactive Observer Mode]               (v11 진화 — 핵심)
                 │
                 │  Orchestrator: 영구 모니터링
                 │  - subscribe(topic="*") long-poll (push 시 즉시 wake)
                 │  - 의존성 위반 감지 (Cascade Lock)
                 │  - 사용자 동적 요청 처리
                 │
                 v
          (영구 자율 cycle, 사용자 진입점 0)
```

**v10.3 → v11 차이**:
- Phase 0: 변경 없음
- Phase 1+: Observer mode → **Reactive** Observer
  - polling 30s → subscribe push (50ms)
  - cascade advisory → cascade publish_event (다른 stream react 가능)
  - GitHub label 인덱스 catch-up → broker event log 즉시 신뢰

## §3. 8 워크트리 폴더 (v10.3 와 동일)

```
C:/claude/ebs-foundation/        ← S1
C:/claude/ebs-lobby-stream/      ← S2 (team1-frontend 흡수)
C:/claude/ebs-cc-stream/         ← S3 (team4-cc 흡수)
C:/claude/ebs-rive-standards/    ← S4
C:/claude/ebs-ai-track/          ← S5
C:/claude/ebs-prototype/         ← S6 (integration-tests 흡수)
C:/claude/ebs-backend-stream/    ← S7
C:/claude/ebs-engine-stream/     ← S8
```

각 폴더 사전 세팅 (v10.3 + v11 추가):
```
.team                          (Layer 2: Stream identity SSOT)
CLAUDE.md                      (Layer 3: 워크트리-local 가이드)
START_HERE.md                  (사용자 첫 화면)
.claude/
  ├── settings.local.json      (hook 활성화)
  └── hooks/
      ├── SessionStart.py      (Layer 4) + ensure_message_bus()
      ├── PreToolUse.py        (Layer 5) + cascade publish + acquire_lock
      └── PostToolUse.py       (v11 신규) — release_lock 자동
.vscode/settings.json
.mcp.json                      (v11 신규 — broker 자동 등록)
```

## §4. 7중 다층 방어 (v11 신규 L7)

| Layer | 메커니즘 | 강제 시점 |
|:-:|---------|---------|
| 1 | 워크트리 경로 패턴 | 진입 시 |
| 2 | `.team` + worktree_path cross-check | 진입 시 + Edit 직전 |
| 3 | 워크트리 CLAUDE.md | LLM context |
| 4 | SessionStart hook (identity inject + dep check) | 세션 시작 |
| 5 | PreToolUse hook (scope + meta + cascade) | Edit/Write 직전 |
| 6 | GitHub 인프라 (label + scope_check.yml) | PR 생성/머지 |
| **7** | **Topic ACL (`check_publish_acl` strict)** | **publish_event 호출 직전** |

**L7 의미**: 신호 매체에도 정체성 강제. S1 만 `stream:S1` topic 으로 publish 가능. 다른 stream 이 사칭하면 broker 가 거부. 정체성 = 신호 발화권.

상세: 글로벌 스킬 `~/.claude/skills/orchestrator/references/7-layer-defense.md` (예정)

## §5. Phase 게이트 + Topic ACL 정렬 (v11)

```
S2 Lobby Stream:
  P2 (기획):
    write: docs/2.1/Lobby/, docs/1./Lobby.md
    publish: stream:S2 (DONE / IN_PROGRESS / BLOCKED)
    blocked: team1-frontend/src/    ← P5에서 unlock
  P5 (코드):
    write: team1-frontend/, docs/2.1/Lobby/
    publish: stream:S2 (DONE / IN_PROGRESS / BLOCKED)
```

→ scope ↔ topic 자동 정합. S2 가 stream:S1 topic publish 시도 = ACL 거부.

## §6. 핵심 패턴 (v11 신규)

### 6.1 Subscribe blocking — Dependency Wake

S2 가 S1 완료를 await:

```python
# team_session_start.py (v11)
async def check_dependency_v11(team):
    if not team.get('blocked_by'):
        return True
    async with mcp_client(URL) as session:
        for upstream in team['blocked_by']:  # ['S1']
            r = await session.call_tool("subscribe", {
                "topic": f"stream:{upstream}",
                "from_seq": 0,
                "timeout_sec": 5,
            })
            done = [e for e in r["events"]
                    if e["payload"].get("status") == "DONE"]
            if done:
                continue  # broker 에서 확인됨
            if not _git_log_grep_fallback(upstream):  # v10.3 path
                return False
    return True
```

**Latency**: v10.3 평균 15s vs v11 평균 ~50ms (broker push).

### 6.2 자율 Cascade Publish — Advisory → Event

```python
# orch_PreToolUse.py (v11)
def cascade_advisory_v11(target_rel, repo_root, team_id):
    paths = _doc_discovery_impact(target_rel)
    if not paths:
        return
    sys.stderr.write(f"[doc-cascade] ... {len(paths)} docs ...\n")  # 사람용
    if _broker_alive():  # v11
        _publish_sync(
            topic=f"cascade:{target_rel}",
            payload={"impacted": paths, "editor": team_id},
            source=team_id,
        )
    if _is_cascade_resource(target_rel):  # v11 L5
        ok = _acquire_lock_sync(
            resource=f"cascade:{target_rel}", holder=team_id, ttl=60,
        )
        if not ok:
            sys.exit(2)  # 다른 stream lock 보유
```

### 6.3 Subscribe Observer Loop

```python
# observer_loop.py (v11 신규)
async def observer_loop_v11(config):
    last_seq = 0
    async with mcp_client(URL) as session:
        while True:
            r = await session.call_tool("subscribe", {
                "topic": "*",
                "from_seq": last_seq,
                "timeout_sec": 30,
            })
            for event in r["events"]:
                last_seq = max(last_seq, event["seq"])
                _handle_event(event, config)
            # idle = 무 cost, push 시 즉시 wake
```

## §7. 사용자 워크플로우 (v10.3 와 동일)

```
1. 사용자: VSCode에서 워크트리 폴더 열기
   → C:/claude/ebs-foundation/  (예: S1부터)

2. 자동 발생:
   - SessionStart hook → identity 주입 + ensure_message_bus (broker 자동 기동)
   - START_HERE.md 화면에 표시 (subscribe 로 BLOCKED/READY 결정)
   - .team / .mcp.json context 자동 로드

3. 사용자: "작업 시작"
   → tools/orchestrator/team_session_start.py
   → subscribe-first dependency check
   → GitHub Issue + Draft PR 자동 생성
   → publish_event(topic="stream:S{N}", payload={status: "IN_PROGRESS"})

4. 작업 진행 (PreToolUse hook 이 SCOPE + cascade + lock 강제)

5. 사용자: "작업 완료"
   → tools/orchestrator/team_session_end.py
   → PR ready + auto-merge + branch 삭제
   → publish_event(topic="stream:S{N}", payload={status: "DONE", pr: #N})
   → 다른 stream 의 subscribe 가 즉시 wake (50ms)

6. 다른 Stream 으로 전환 (또는 병렬 진행):
   - 의존하는 stream 이 자동 unblock 됨 (수동 step 0)
```

**v10.3 → v11 차이 (사용자 관점)**: 변화 없음. 내부 latency 250x 개선만.

## §8. v10.3 → v11 진화 매트릭스

| 패턴 | v10.3 | v11 | 진화 |
|------|-------|-----|------|
| Observer mode | `gh pr/issue list` 30s polling | `subscribe(topic="*")` long-poll | pull → push |
| Cascade L1-L4 | frontmatter / doc_discovery / hook stderr / CI | + L5 acquire_lock | race 0 |
| 6중 방어 | path / .team / CLAUDE.md / SessionStart / PreToolUse / GitHub | + L7 Topic ACL | 신호 정체성 |
| Dependency check | git log + gh pr list 3단 fallback | subscribe-first | 단순화 |
| DONE 신호 | PR 머지 → label 인덱스 → polling 감지 (30s+) | publish_event(stream:S{N}, DONE) | 50ms |
| Cascade advisory | stderr only | stderr + publish_event(cascade:{file}) | fan-out |
| 수동 NOTIFY-*.md | 가끔 작성 | 0 | broker 처리 |

## §9. 호환성 매트릭스

| 환경 | v10.3 hooks | v11 hooks |
|------|:-----------:|:---------:|
| broker alive | ✓ (broker 무시) | ✓ (push 활성) |
| broker dead | ✓ | ✓ (silent skip → polling fallback) |
| `.mcp.json` 없음 | ✓ | ✓ (broker probe 실패 → fallback) |
| GitHub 인덱스 30분 catch-up | ✓ (느림) | ✓ (broker 우선, GH 무시) |

**핵심**: broker 죽어도 v10.3 와 동일하게 동작. publish_event 가 silent skip.

## §10. 검증된 성능 (Phase 5 통합 검증 — v11 baseline)

| 항목 | 측정값 | v10.3 baseline | 비율 |
|------|-------|---------------|-----:|
| publish RTT (single client) | 3.0ms / p99 4.5ms | — | — |
| publish RTT (8 concurrent) | 23.4ms / p99 54.6ms | — | — |
| Dependency wake (S1 DONE → S2 시작) | < 200ms | 30s ~ 30분 | **150x ~ 9000x** |
| Cascade race (1000 iter / 8 worker) | 0 race | reproduce 가능 | ✓ |
| 사용자 수동 step | 0 | NOTIFY 가끔 | ✓ |
| Observer dashboard 신선도 | ~50ms | ~15s | 300x |
| WAL durability (kill -9) | 50/50 복구 | N/A | ✓ |

## §11. 위험 + 완화

| 위험 | 발생 | 완화 |
|------|------|------|
| Broker dead | subscribe 영구 hang | timeout_sec=30 + polling fallback. ensure_message_bus 자동 재기동 |
| Topic ACL strict 화 | PoC default-allow 가정 | Phase A 화이트리스트 추가, 기존 test 통과 확인 |
| publish_event 과다 | cascade 마다 fan-out | docs/ 만 발화, topic rate limit (broker side, future) |
| acquire_lock deadlock | cross-hold | TTL 60s 강제 + cycle 시 = TTL 만료까지 ~60s 지연 |
| events.db 무한 성장 | 디스크 fill | store.py 14일 retention (~30 LOC) |
| Topic ACL spoofing | source 인자 클라이언트 자유 | server.py 가 .team 파일 inject (v11.x hardening) |

## §12. Migration Path (4 Phase, 7 영업일)

| Phase | Day | 산출 | 검증 |
|------|----|------|------|
| **A. spec + topics strict** | 1 | Multi_Session_Design_v11.md, topics.py strict, yaml topics 섹션 (~400 LOC) | doc-critic + ACL test |
| **B. hook 진화** | 2-3 | orch_PreToolUse cascade publish + lock, orch_PostToolUse 신규, team_session_end DONE (~220 LOC) | broker events.db row 증가 |
| **C. subscribe 전환** | 4-5 | orchestrator_monitor subscribe loop, team_session_start subscribe-first, observer_loop.py 신규, orch_SessionStart subscribe-once (~480 LOC) | latency_bench sub-second |
| **D. verification + supersede** | 6-7 | tests/v11_e2e/, Stream_Entry_Guide_v11, v10.3 frontmatter SUPERSEDED (~150 LOC) | 1000 iter race 0 |

각 phase 독립 PR. A 머지 후에도 v10.3 100% 보존. C 머지 시점부터 v11 push 활성.

## §13. Critical Files

- `docs/4. Operations/Multi_Session_Design_v11.md` (이 문서)
- `docs/4. Operations/Multi_Session_Design_v10.3.md` (Phase D supersede)
- `docs/2. Development/2.5 Shared/Stream_Entry_Guide_v11.md` (Phase D 신규)
- `.claude/hooks/orch_PreToolUse.py` (Phase B publish_event + lock)
- `.claude/hooks/orch_SessionStart.py` (Phase C subscribe-once)
- `.claude/hooks/orch_PostToolUse.py` (Phase B 신규)
- `tools/orchestrator/team_session_start.py` (Phase C subscribe-first)
- `tools/orchestrator/team_session_end.py` (Phase B publish DONE)
- `tools/orchestrator/orchestrator_monitor.py` (Phase C subscribe loop)
- `tools/orchestrator/message_bus/topics.py` (Phase A strict)
- `tools/orchestrator/message_bus/observer_loop.py` (Phase C 신규)
- `docs/4. Operations/team_assignment_v10_3.yaml` (Phase A topics 섹션)

## §14. References

- v10.3 spec (predecessor): [`Multi_Session_Design_v10.3.md`](./Multi_Session_Design_v10.3.md)
- Message Bus 운영: [`Message_Bus_Runbook.md`](./Message_Bus_Runbook.md)
- Stream 매트릭스 SSOT: [`team_assignment_v10_3.yaml`](./team_assignment_v10_3.yaml)
- Plan 파일 (history): `C:/Users/AidenKim/.claude/plans/dreamy-fluttering-gem.md`
- 글로벌 orchestrator skill: `~/.claude/skills/orchestrator/`

---

## §15. v10.4 9-Session Matrix Extension (2026-05-11)

> **동기**: production 인텐트(SG-023) 9일째 검증 0%. 사용자 6 역할(orchestrator + dev + gap 분석 + gap 작성 + QA + 보조)을 기존 v11 8 Stream 위에 매핑.

### §15.1 매트릭스

```
역할 ╲ 도메인       S2 Lobby   S7 Backend   S3 CC      S8 Engine   기타
S0 Orchestrator   ←──── Conductor (main 폴더, broker supervisor) ────→
프로토 개발        S2 sess    S7 sess     S3 sess    S8 sess     S4 dormant
S9  QA            ←─────── cross-cutting (ebs-qa) ─────────────→
S10-A Gap 분석    ←─────── cross-cutting (ebs-gap-audit) ──────→
S10-W Gap 작성    ←─────── cross-cutting (ebs-gap-write) ──────→
S11 Dev Assist    ←─────── cross-cutting (ebs-devops) ─────────→
SMEM (옵션)       ←─────── cross-cutting (ebs-memory) ─────────→
```

### §15.2 신규 Stream 정의

| Stream | worktree | Phase | scope_owns (요약) | broker pub | broker sub |
|--------|----------|-------|------------------|-----------|-----------|
| **S9** QA | `C:/claude/ebs-qa` | P4→P5 | `integration-tests/**`, e2e workflows | `pipeline:qa-pass\|qa-fail` | `pipeline:build-success` |
| **S10-A** Gap 분석 | `C:/claude/ebs-gap-audit` | P1 | `Spec_Gap_Registry.md`, `spec_drift_check.py` | `pipeline:gap-classified` | `pipeline:qa-fail`, `cascade:build-fail` |
| **S10-W** Gap 작성 | `C:/claude/ebs-gap-write` | P2 | `Conductor_Backlog/_template_spec_gap*.md` | `pipeline:spec-patched` | `pipeline:gap-classified` |
| **S11** Dev Assist | `C:/claude/ebs-devops` | P5 | `Docker_Runtime.md`, root compose | `pipeline:env-ready\|env-broken` | `cascade:build-fail` |
| **SMEM** Memory | `C:/claude/ebs-memory` | P_always | (append-only) | `audit:memory-*` | `*` |

### §15.3 v11 spec 위 변경 (최소 변경)

| 영역 | 변경 |
|------|------|
| `topics.py` | `_OPEN_TOPIC_PREFIXES` 에 `"pipeline:"` 추가 + `_STREAM_TOPIC_RE` 가 S10-A/S10-W 대시 허용 (정규식 `^stream:(S[\w-]+)$`) |
| `team_assignment_v10_3.yaml` | version 10.3 → 10.4.5 (5 stream 활성화). `topics.acl` 에 5 stream entry |
| `team-policy.json` | version 10.3 → 10.4. `teams` 에 5 신규 entry (cwd_match + owns + broker_pub/sub) |
| `Message_Bus_Runbook.md` | §11 9-Session Integration 신설 |
| 활성화 도구 | `dynamic_stream_activation.py` 그대로 동작 (5 stream 순차 활성화) |
| Hook | 변경 없음 (v11 기존 hooks 가 신규 stream 자동 인식) |

### §15.4 단방향 Pipeline

```
spec_drift_check.py ──pipeline:gap-classified──> [S10-A]
                                                    │ (Type B/C)
                                                    v
                                              [S10-W] ──pipeline:spec-patched──> 도메인 4 dev
                                                                                  │ cascade:build-success
                                                                                  v
                                                                             [S11] ──pipeline:env-ready──> [S9]
                                                                                                            │
                                                                                          ┌────qa-pass────→ close (S0)
                                                                                          └────qa-fail────→ [S10-A] (loop)
```

### §15.5 1주일 KPI (Issue #215)

- **Goal**: 빌드 검증 0% → 1 hand 시나리오 통과 50%
- **Init PRs**: #211 S9 / #212 S10-A / #213 S11 / #214 SMEM (S10-W 는 S10-A 머지 후 unblock)
- **Plan**: `C:\Users\AidenKim\.claude\plans\kind-mapping-rivest.md`
- **Tracking**: `gh issue view 215`

### §15.6 약점 (정직)

1. 9세션은 1명에겐 과한 동시성 → 동시 활성 S0 + 2~3 권장, idle 자동 휴면
2. Pipeline 2 hop (분석→작성→dev) 가 1주 KPI 위협 → S9 가 Type A 를 도메인 hotpath 직송 shortcut
3. S10-A/S10-W 분리는 인지적 → 1주 후 효과 미흡 시 단일 합본 검토
4. broker SPOF → graceful degradation (GitHub authority) + start_message_bus.py 자동 재시작 가능
5. at-least-once 미보장 → handler idempotent + GitHub PR commit hash 가 진실
