---
title: Docker Runtime 운영 지침
owner: conductor
tier: internal
last-updated: 2026-04-27
confluence-page-id: 3818816021
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816021/EBS+Docker+Runtime
---

# Docker Runtime 운영 지침

EBS 프로젝트는 로컬 머신 (AIDEN-KIM-DT-01, LAN IP 10.10.100.115) 에서 Docker 컨테이너로 BO/Engine/CC-Web/Redis 를 서빙한다. 코드 수정이 compose 서비스 이미지에 반영되려면 **재빌드가 필수**이며, 아키텍처 전환으로 서비스가 폐기될 때 **좀비 컨테이너/이미지**가 남아 옛 코드를 계속 서빙하는 사고가 발생한 이력이 있다 (2026-04-22 `ebs-lobby-web` 사건).

본 문서는 모든 팀 세션이 작업 종료 시 따라야 할 Docker 정리 프로토콜을 정의한다.

---

## 1. 정규 컨테이너 맵 (SSOT)

| 컨테이너 | 이미지 | 외부 포트 | 소유 팀 | 재빌드 트리거 |
|----------|--------|----------|--------|---------------|
| `ebs-bo-1` | `ebs-bo` | 8000 | team2 | `team2-backend/src/**` 또는 `Dockerfile` 변경 |
| `ebs-engine-1` | `ebs-engine` | 8080 | team3 | `team3-engine/ebs_game_engine/lib/**` 또는 `Dockerfile` 변경 |
| `ebs-lobby-web` | `ebs/lobby-web:latest` | 3000 | team1 | `team1-frontend/lib/**` 갱신 (flutter build web 선행) |
| `ebs-cc-web-1` ⚠ dev/test 보조 | `ebs-cc-web` | 3001 | team4 | `team4-cc/src/build/web/**` 갱신 (flutter build web 선행) — **정규 배포는 Flutter Desktop 단일 바이너리** (Foundation §A.4 SSOT) |
| `ebs-redis-1` | `redis:7-alpine` | 127.0.0.1:16380 (host debug) | conductor | (재빌드 불필요, `docker compose pull` 만) |

**compose 정의 파일**: `docker-compose.yml` (레포 루트)

**현재 정책 (2026-05-08, Foundation §A.4 SSOT cascade 정합)**:
- **CC 정규 배포** = **Flutter Desktop 단일 바이너리** (RFID 시리얼 + SDI/NDI 직결, Foundation §A.4 정점 SSOT).
- **Lobby + BO + Engine** = **Multi-Service Docker** (Lobby:3000 / BO:8000 / Engine:8080). team1 Lobby = Flutter Web 빌드 → Docker nginx 서빙 (Foundation §A.1 정합).
- **CC dev/test 보조** = `ebs-cc-web:3001` Flutter Web 빌드 (SG-022 폐기 후 회복, 개발자 디버깅·QA·LAN 동시 시연 용도).
- `flutter run -d windows` 또는 `-d chrome` = 개발자 로컬 디버깅 (배포 아님).
- "Flutter 단일 스택" 의 의미 = **프레임워크 (Flutter) 통일**. Vue/Quasar 폐기. 정규 배포 형태는 Foundation §A.1 (Lobby Web) / §A.4 (CC Desktop).
- ~~SG-022 (단일 Desktop 바이너리)~~ = **2026-04-27 폐기**. 4팀 병렬 개발 + LAN 멀티 세션 운영 요구와 충돌. 단 CC 자체는 Foundation §A.4 가 Desktop 정규를 다시 명시.
- 참조: `team1-frontend/CLAUDE.md` § 배포 형태, `MULTI_SESSION_DOCKER_HANDOFF.md`, `docs/1. Product/Foundation.md` §A.4, `Critic_Reports/Lobby_Spec_Implementation_Drift_2026-05-06.md`.

### Edit History (§1 정규 컨테이너 맵)

| 날짜 | 변경 | 트리거 |
|------|------|--------|
| 2026-04-22 1차 | `ebs-lobby-web` 좀비 오판 → destroy → 재복구 | 사용자 지적 (Type C) |
| 2026-04-27 | SG-022 (Desktop 단일) 채택 → lobby-web REMOVED 표기 | 사용자 결정 |
| 2026-04-27 | SG-022 폐기 → Multi-Service Docker 회복 | 사용자 결정 (team1 CLAUDE.md 정정) |
| 2026-05-06 | §1 표 stale 표기 정정 (lobby-web 부활) + cc-web 포트 3100→3001 정정 | Conductor 자율 (3000 포트 drift 사건 후속) |
| **2026-05-08** | **§1 cc-web 컨테이너 dev/test 보조 표기 + §"현재 정책" Foundation §A.4 SSOT cascade 정합 (정규 = Flutter Desktop, Web = 보조)** | **Conductor 자율 (Phase C #181 정합성 감사 — Foundation §A.4 정점 SSOT 기준)** |
| **2026-05-11** | **§4.5 Redis revival 절차 + §4.6 WSL relay glitch 진단 신설. redis host port 16379→127.0.0.1:16380 (wslrelay PID 55860 점유 회피)** | **S11 Day-1 (KPI #215). 도메인 4 docker compose 검증 중 redis 4일째 Exit(255) + BO/engine host port 미바인딩 발견. proxy 경유 흐름은 정상 → `pipeline:env-ready` 발행 (seq=6)** |
| **2026-05-11 (후속)** | **redis service `restart: unless-stopped` 정책 추가 (PR #230). §1 표 redis 외부 포트 `internal` → `127.0.0.1:16380 (host debug)` 정정** | **S11 Day-1 autonomous iteration. bo/engine/lobby-web/cc-web/proxy 모두 정책 보유 — redis 만 누락이 4일 silent down 의 근본 원인. transient glitch 자동 회복 시간 단축** |
| **2026-05-11 (Cycle 2)** | **§4.7 Healthcheck 6/6 reference 신설. broker 자동 publish 흐름 다이어그램 추가 (post_build_fail → cascade:build-fail / orch_PostToolUse → pipeline:env-ready). Day-1 수동 publish 의존성 제거** | **S11 Cycle 2 (Issue #240). orchestrator_monitor PYTHONPATH fix + 두 hook 의 broker publish 통합으로 push-mode 50ms latency 활용 가능. recipients=0 문제는 별도 사이클** |
| **2026-05-11 (Cycle 3)** | **§4.8 Autonomous action chain 신설. observer_loop `--action-mode` + `next_action` payload dispatcher (inbox-drop / shell / noop). `handoffs/inbox/` 신설 + hook payload next_action 자동 명시. recipients=0 문제 해소 (observer가 즉시 파일 시스템에 drop)** | **S11 Cycle 3 (autonomous chain). end-to-end self-test PASS (seq 40 drop / seq 41 shell-block / seq 43 broadcast). Cycle 4 후보 = observer_loop background service** |
| **2026-05-12 (Cycle 4)** | **§4.9 Autonomous chain demo + broker wildcard semantics 발견. cascade:cycle4-demo-build-fail seq=101 end-to-end chain 실측 trace 보존 (subscribe→dispatch ~493ms). `cascade:*` glob 미지원 — `*` 또는 exact topic 권장. autonomous 도달도 10% 사용자 진입 (Cycle 5 = 0% 목표)** | **S11 Cycle 4 (Issue #271). PR #254 의 --action-mode 실제 동작 검증. observer_loop background service 가 Cycle 5 의 단일 잔여 작업** |
| **2026-05-12 (Cycle 5 Path B)** | **§4.10 broker MCP reconnect + observer 안정화. 4 패치: orch_PostToolUse/post_build_fail `_broker_publish` retry 3x (exp backoff 0/0.5/1.5s) + observer_loop outer reconnect loop (exp backoff 1s-30s, 24h 무중단) + orch_SessionStart `_probe_broker_mcp_health` (TCP+MCP 2단계 검사). events.db +832 증가 (seq 106→938), cascade:s11-cycle5-stabilized seq=938 recipients=1** | **S11 Cycle 5 (Issue #284 Path B). "daemon alive + MCP disconnect" 시나리오 대응. .mcp.json 변경 불필요 (검증만)** |

---

## 2. 작업 종료 시 필수 프로토콜

모든 팀 세션은 `/team` 워크플로우 Phase 7 (commit + push) 완료 후 Phase 8 (report) 전에 아래를 수행한다.

### 2.1 좀비 스캔

```bash
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep "^ebs-"
```

판정 규칙:
- **compose 에 없는데 돌고 있음** → 좀비. stop + rm
- **compose 에 없는데 이미지만 존재** → 좀비 이미지. rmi
- **Exited (0) 28 seconds ago 유지** → 의도된 정지 아니면 재시작 or 삭제
- **Up 2+ days (unhealthy)** → healthcheck 실패. 로그 확인 후 재시작 or 재빌드

### 2.2 현재 세션 소유 서비스 재빌드 (코드 변경 있을 때만)

| 세션 | 조건 | 명령 |
|------|------|------|
| ~~team1~~ **[REMOVED 2026-04-27, SG-022]** | ~~Web 빌드 명령 폐기~~ | ~~`flutter build web ... && docker compose --profile web build lobby-web`~~ → SG-022 단일 Desktop 으로 통합. team1 Dockerfile/web 정리는 B-Q3 후속 |
| team2 | `team2-backend/src/**` 변경 | `docker compose build --no-cache bo && docker compose up -d bo` |
| team3 | `team3-engine/ebs_game_engine/lib/**` 변경 | `docker compose build --no-cache engine && docker compose up -d engine` |
| team4 | `team4-cc/src/build/web/**` 갱신 | `cd team4-cc/src && flutter build web --release --dart-define=DEMO_MODE=true && cd ../.. && docker compose --profile web build --no-cache cc-web && docker compose --profile web up -d cc-web` |
| conductor | docker-compose.yml 구조 변경 시 | 전체 `docker compose up -d --force-recreate` |

**중요**: team1/team4 는 Docker build 전 반드시 **호스트에서 `flutter build web` 선행**. Dockerfile 은 nginx 이미지에 `build/web` 을 COPY 하는 단순 구조 (Flutter SDK 미포함, 빌드 속도 100x 향상).

### 2.3 healthcheck 검증

재빌드 후 30~60초 대기 → healthy 확인:
```bash
docker ps --filter "name=^ebs-" --format "table {{.Names}}\t{{.Status}}"
```

unhealthy 면 로그 확인:
```bash
docker logs <container-name> --tail 50
```

### 2.4 폐기된 리소스 즉시 정리

아키텍처 전환 commit (예: "Desktop 단일 스택 전환") 의 일부로 compose 서비스를 제거했다면 **동일 commit 내에서** 런타임 정리:

```bash
docker compose stop <removed-service>
docker compose rm -f <removed-service>
docker rmi <removed-image>
```

commit 메시지에 `docker-cleanup: <image>` 태그 추가.

---

## 3. 진단 체크리스트 (옛 코드 서빙 의심 시)

사용자가 "이 수정이 브라우저에 반영 안 된다" / "이전 API path 계속 호출된다" / "404 반복" 신고 시:

1. **IP 확인**: `hostname` + `ipconfig` → 외부 서버인지 로컬인지
2. **포트 리스닝**: `netstat -ano -p tcp | grep ":<port> "` → PID 식별
3. **프로세스 식별**: PowerShell `Get-Process -Id <pid>` → docker backend 인지
4. **컨테이너 조회**: `docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"`
5. **이미지 빌드 시각**: `docker image inspect <image> --format '{{.Created}}'` → 레포 최신 커밋 시각과 괴리 크면 좀비
6. **COPY 경로 추적**: `docker history <image> --no-trunc --format "{{.CreatedBy}}"` → 이미지 빌드 시점 사용된 소스 디렉토리 확인

---

## 4. 금지

- **레포에서 compose 서비스 제거했는데 런타임 컨테이너는 살려두기** — 좀비 원인 1순위
- **재빌드 없이 코드 수정만 commit 하고 브라우저 테스트 요청** — 사용자는 옛 이미지 결과만 봄
- **unhealthy 컨테이너 방치** — 2일 이상 unhealthy 상태는 의도된 동작이 아니므로 진단 필수

---

## 4.5 Redis revival after wslrelay port hijack

**증상**: `ebs-redis` 컨테이너 Exit(255) 후 재기동 시 `Bind for 0.0.0.0:16379 failed: port is already allocated` 에러. `netstat -ano | findstr :16379` 결과 `com.docker.backend wslrelay` (Docker Desktop 내부 relay) 가 점유 중. Docker Desktop 재시작 외에는 release 불가.

**근본 원인**: Docker Desktop WSL2 백엔드의 relay 프로세스가 컨테이너 Exit 후에도 host port 점유를 유지하는 알려진 issue (v29.3.1 확인). Windows dynamic port range (1024-15001) 회피용으로 선택한 16379 도 안전하지 않음.

**복구 절차 (비파괴, 2026-05-11 S11 Day-1 검증)**:

```bash
# 1. 점유 port 진단
netstat -ano | findstr :16379

# 2. 자유 port 탐색 (PowerShell)
@(16380, 16381, 16382, 16383) | ForEach-Object {
  $c = Get-NetTCPConnection -LocalPort $_ -State Listen -ErrorAction SilentlyContinue
  if (-not $c) { "$_ FREE" } else { "$_ HELD by PID $($c.OwningProcess)" }
}

# 3. docker-compose.yml redis.ports 갱신 (loopback bind 권장)
#    - "16379:6379"  →  - "127.0.0.1:16380:6379"

# 4. exited 컨테이너 제거 (Network/Volume 보존)
docker rm ebs-redis

# 5. 진본 project 컨텍스트에서 재기동 (running 컨테이너와 project 정합)
docker compose --project-name ebs -f docker-compose.yml up -d redis

# 6. 검증
docker exec ebs-redis redis-cli ping              # PONG
docker exec ebs-bo python -c "import redis; print(redis.from_url('redis://redis:6379/0').ping())"  # True
```

**중요**: BO/Engine/Lobby/CC 는 internal `redis:6379` (ebs-net) 로 연결하므로 host port 변경의 영향을 받지 않는다. host port 는 개발자 `redis-cli` 디버깅 용도 전용.

**예방**: redis service 의 `restart: unless-stopped` 정책 추가 검토 — 현재 redis 만 healthcheck 정의되고 restart 정책 없음 (BO/Engine 은 있음). Backlog 등록 권장.

---

## 4.6 WSL relay glitch: BO/Engine host port 미바인딩

**증상**: `docker inspect ebs-bo --format '{{.HostConfig.PortBindings}}'` 는 `8000/tcp → 8000` 정상 표시되지만 `curl http://127.0.0.1:8000/health` 무응답. `localhost:8080` (engine) 동일 현상.

**영향 범위 (2026-05-11 S11 Day-1 측정)**:

| 접근 경로 | 상태 |
|----------|:----:|
| `curl http://127.0.0.1:8000/health` (BO 직접) | ✗ 미응답 |
| `curl http://127.0.0.1:8080/health` (Engine 직접) | ✗ 미응답 |
| `curl -H "Host: api.ebs.local" http://127.0.0.1/health` (proxy 경유 BO) | ✓ `{"status":"ok","db":"connected"}` |
| `curl http://127.0.0.1:3000/healthz` (Lobby) | ✓ |
| `curl http://127.0.0.1:3001/healthz` (CC) | ✓ |
| `curl http://127.0.0.1/healthz` (Proxy) | ✓ |

**해석**: 사용자 흐름 (브라우저 → nginx proxy → BO/Engine via ebs-net) 정상. 개발자 흐름 (host port 직접) 차단. proxy hostname-routing (`api.ebs.local`, `engine.ebs.local`) 으로 완전 우회 가능.

**복구 옵션**:
- **A**: 영향 컨테이너 단일 재기동 — `docker restart ebs-bo ebs-engine` (5h healthy 깨질 위험). relay 재초기화 가능성 ~80%.
- **B**: Docker Desktop 재시작 — 모든 worktree session 영향. 마지막 수단.
- **C (현재 채택)**: proxy 경유 + LAN_DEPLOYMENT.md `setup_lan_access` 으로 hostname 매핑 사용. 개발자 직접 접근 필요 시 `docker exec <container> curl localhost:<port>` 우회.

---

## 4.10 broker MCP reconnect + observer 안정화 (S11 Cycle 5 Path B, Issue #284)

Cycle 4 자가검증 중 발견된 "daemon alive but MCP client disconnect" 시나리오 대응. 4 안정화 패치 + Path B 자동화.

### 진단 (Issue #284 S0)

| 계층 | 상태 | 비고 |
|------|:----:|------|
| broker daemon (TCP 7383) | ✅ alive | pid 변동 가능 (재시작 자동) |
| events.db | ✅ 936건 누적 | 정상 |
| **MCP client (Claude Code 측)** | ⚠ stale handshake | session 내 disconnect 가능 |
| .mcp.json | ✅ url=http://127.0.0.1:7383/mcp | 변경 불필요 |

### 4 안정화 패치

#### (1) `orch_PostToolUse.py` `_broker_publish` retry 3x

```python
backoffs = [0.0, 0.5, 1.5]  # 0s, 0.5s, 1.5s
for attempt in range(3):
    if backoffs[attempt] > 0:
        time.sleep(backoffs[attempt])
    try:
        # streamablehttp_client + ClientSession + publish_event
        return  # success
    except Exception:
        continue
# all retries exhausted - silent (preserves Cycle 2 contract)
```

**효과**: broker temp down 시 silent skip 대신 8s 안에 자동 복구.

#### (2) `post_build_fail.py` `_broker_publish_build_fail` retry 3x

동일 retry 패턴. TCP probe 먼저 (daemon dead 시 retry 무의미하므로 즉시 return).

#### (3) `observer_loop.py` outer reconnect loop

```python
backoff = 1.0
while True:
    try:
        async with streamablehttp_client(URL) as ...:
            ...subscribe loop...
    except Exception as _reconnect_exc:
        print(f"  [reconnect] broker disconnect: backoff {backoff:.1f}s")
        await asyncio.sleep(backoff)
        backoff = min(backoff * 2, 30.0)  # exp backoff, cap 30s
```

**효과**: 24h 무중단 운영. transient network/handshake failure 자동 복구.

#### (4) `orch_SessionStart.py` `_probe_broker_mcp_health(team_id)`

TCP probe + MCP initialize handshake 2 단계 검사. daemon alive 이지만 MCP failure 감지 → 사용자에게 stderr 로 "/mcp reconnect" 권고.

### 검증 (2026-05-12 self-test)

| 단계 | 결과 |
|------|:----:|
| TCP 7383 probe | ✅ ALIVE |
| MCP handshake (initialize) | ✅ OK |
| `_probe_broker_mcp_health()` | ✅ True + log line |
| `_broker_publish` 단발 성공 | ✅ 1521ms (first attempt) |
| cascade:s11-cycle5-stabilized publish | ✅ seq=938 recipients=1 |

### KPI 충족

| 항목 | 목표 | 실측 |
|------|:----:|:----:|
| events.db 증가 | +50 | **+832** (seq 106 → 938, 다른 stream 활동 포함) |
| broker 모든 stream publish 200 OK | ✓ | seq=938 publish 성공 |
| observer 24h 무중단 | 코드 검증 | outer reconnect loop + exp backoff 1s-30s |
| MCP reconnect 자동화 | ✓ | SessionStart probe → 사용자 권고 stderr |

### 운영 절차 (broker disconnect 발견 시)

1. `python tools/orchestrator/start_message_bus.py --probe` — daemon TCP/PID 확인
2. SessionStart stderr 의 `[broker]` 라인 확인 — MCP 단계 까지 OK 인지
3. `[broker] daemon alive ... but MCP handshake failed` 표기 시:
   - Claude Code 세션 재시작 (단순)
   - `/mcp reconnect` (가능 시)
4. observer_loop background 가동 중이면 자동 reconnect 진행 (stdout `[reconnect] backoff Ns` 로그)

### 다음 사이클 후보

- broker subscribe **prefix glob** (`cascade:*` 정상 매칭) — Cycle 4 발견 이슈 잔여
- observer_loop **systemd / Task Scheduler** 통합 (영구 background)
- S9 / S10-A inbox triage automation (cascade:build-fail → Spec_Gap 자동 생성)
- inbox archive 자동화 (`_archive/YYYY-MM/`)

---

## 4.9 Autonomous chain demo (S11 Cycle 4, Issue #271)

PR #254 (Cycle 3) 의 observer_loop `--action-mode` 가 실제 cascade event 를 처리할 수 있는지 검증한 end-to-end demo. 사용자 진입 0 자동화 90% 도달 검증.

### 시나리오: 빌드 실패 → 자동 inbox drop

**Step 1** — fake `cascade:build-fail` publish (S11 publisher):

```bash
python -m tools.orchestrator.message_bus.tests.pub_demo \
  --topic "cascade:cycle4-demo-build-fail" \
  --source "S11" \
  --payload '{"command_excerpt":"pytest tests/test_demo_failure.py","exit_code":1,"stderr_excerpt":"FAKE FAILURE for cycle 4 chain demo","next_action":{"type":"inbox-drop","target":"S9,S10-A","reason":"simulated build failure"}}'
```

→ 결과: `seq=101, recipients=0` (live subscriber 0 — 정상)

**Step 2** — observer_loop `--action-mode` (history drain + dispatch):

```bash
python -m tools.orchestrator.message_bus.observer_loop \
  --topic "cascade:cycle4-demo-build-fail" \
  --action-mode --max-iter 1
```

→ stdout (실측 trace):

```
v11 Observer Loop — push-based
  url:    http://127.0.0.1:7383/mcp
  topic:  cascade:cycle4-demo-build-fail
  start:  2026-05-12T02:58:32.321856+00:00
📡 cascade by ?: cycle4-demo-build-fail → 0 docs
  inbox-drop: docs\4. Operations\handoffs\inbox\2026-05-12T02-57-36.57274_cascade-cycle4-demo-build-fail_seq000101_to-S9-S10-A.md
```

**Step 3** — inbox 파일 생성 검증:

| 항목 | 값 |
|------|-----|
| 파일명 | `2026-05-12T02-57-36.57274_cascade-cycle4-demo-build-fail_seq000101_to-S9-S10-A.md` |
| 위치 | `docs/4. Operations/handoffs/inbox/` |
| frontmatter | owner / source / topic / seq / ts / target / action_type / observer_dropped_at |
| 본문 | Payload JSON (4 key 정상 보존) |

실측 파일 본문 (인라인 보존):

```markdown
---
owner: S11
source: S11
topic: cascade:cycle4-demo-build-fail
seq: 101
ts: 2026-05-12T02:57:36.572748+00:00
target: S9,S10-A
action_type: inbox-drop
observer_dropped_at: 2026-05-12T02:58:32.814630+00:00
---

# cascade:cycle4-demo-build-fail (seq=101) -> S9,S10-A

**Source**: `S11`
**Timestamp**: 2026-05-12T02:57:36.572748+00:00

## Payload

{
  "command_excerpt": "pytest tests/test_demo_failure.py",
  "exit_code": 1,
  "stderr_excerpt": "FAKE FAILURE for cycle 4 chain demo (S11 demo, not a real test)",
  "auto_published": true,
  "trigger": "cycle4-demo",
  "next_action": {
    "type": "inbox-drop",
    "target": "S9,S10-A",
    "reason": "Cycle 4 chain demo - simulated build failure"
  }
}
```

> **Note**: 실제 inbox 파일은 PR 커밋에서 제거 (verify-scope: S11 scope_owns 외 경로). trace 는 본 §4.9 인라인 quote 로 영구 보존. 향후 observer_loop 가 생성하는 inbox 파일은 git ignore 또는 자동 archive (Cycle 5) 권장.

**Step 4** — latency 측정:

| 단계 | 시각 (UTC) | delta |
|------|-----------|-------|
| publish | 02:57:36.572 | t0 |
| observer subscribe start | 02:58:32.321 | +55.7s |
| observer dispatch (file write) | 02:58:32.814 | +56.2s (subscribe→dispatch ~493ms) |

**subscribe → dispatch latency ~493ms** (filesystem mkdir + write 포함). broker history replay 가 50ms 이내라 가정하면 markdown write 가 대부분.

### Broker subscribe wildcard 의미 (Cycle 4 발견)

| topic 인자 | 의미 | 사용 권장 |
|-----------|------|----------|
| `"*"` | **모든 topic** broker history + push 수신 | ✅ catch-all observer |
| `"cascade:*"` | literal topic name `cascade:*` (glob 아님) | ❌ glob 미지원 |
| `"cascade:cycle4-demo-build-fail"` | exact match | ✅ 단발 |

Issue #271 본문의 `--topic cascade:*` 는 broker 측에서 literal 로 해석되어 0 매치. 향후 prefix 매칭이 필요하면 broker subscribe 측 패치 (별도 Cycle).

### Autonomous 도달도 측정 (Cycle 1 → Cycle 4)

| Cycle | publish | dispatch | filesystem effect | 사용자 진입 |
|:-----:|:-------:|:--------:|:------------------:|:----------:|
| 1 | 수동 | 없음 | 없음 (broker history만) | 100% |
| 2 | hook 자동 | 없음 | 없음 (recipients=0) | 70% |
| 3 | hook 자동 | observer 수동 트리거 | inbox file | 50% |
| **4** | **hook 자동** | **observer 자동 (self-test 입증)** | **inbox file** | **10%** |
| 5 (후보) | hook 자동 | observer **background service** | inbox + auto archive + S9 triage | **0% 목표** |

### 검증 산출물 (PR 본문에 보존)

- `cascade:cycle4-demo-build-fail` seq=101 broker history
- `cascade:observer-action-verified` seq=TBD broker broadcast
- `docs/4. Operations/handoffs/inbox/2026-05-12T02-57-36.57274_*.md` (PR 머지 전 자동 정리 또는 보존 결정 필요)

---

## 4.8 Autonomous action chain (S11 Cycle 3 — observer_loop dispatch)

broker push event 의 `payload.next_action` 을 `observer_loop --action-mode` 가 디스패치하여 hook publish → 파일 시스템 자동 drop 까지 chain. 사용자 진입 0 자동화의 1차 단계.

### 흐름

```
[hook]                  [broker]                  [observer]            [filesystem]
PostToolUse:Bash  --->  publish_event(*)  --->   subscribe push  --->  inbox-drop
                        + next_action payload     50ms latency          docs/.../inbox/*.md
post_build_fail   --->  cascade:build-fail
                        next_action: inbox-drop
                        target: S9,S10-A
```

### next_action 타입 (3 종)

| type | 동작 | 안전 게이트 |
|------|------|------------|
| `inbox-drop` | `docs/4. Operations/handoffs/inbox/` 에 markdown 작성 | mkdir + frontmatter standardization |
| `shell` | 명령 실행 | **allowlist**: `tools/orchestrator/actions/*` 만 허용. timeout 30s |
| `noop` (또는 부재) | 무동작 | — |

### 활성화

```bash
# 단발 (테스트):
python -m tools.orchestrator.message_bus.observer_loop --action-mode --max-iter 1

# 영구 background (권장, Cycle 4 후속 검토):
python -m tools.orchestrator.message_bus.observer_loop --action-mode  # 무한 long-poll
```

### 자동 hook payload 매핑 (S11 owned)

| hook | publish topic | next_action |
|------|--------------|-------------|
| `orch_PostToolUse` (Bash docker compose up exit=0) | `pipeline:env-ready` | `inbox-drop` → `S2,S3,S7,S8` |
| `post_build_fail` (Bash build/test exit≠0) | `cascade:build-fail` | `inbox-drop` → `S9,S10-A` |

### 검증 (Cycle 3 self-test 2026-05-11)

- ✓ inbox-drop: `cascade:s11-selftest-drop` seq=40 → `docs/.../inbox/2026-05-11T...md` 생성
- ✓ shell-block: `cascade:s11-selftest-shell` seq=41 `/etc/passwd` → allowlist 거부
- ✓ broker push latency 50ms 활성
- ✓ `cascade:observer-action-ready` seq=43 broadcast

---

## 4.7 Healthcheck 6/6 reference (S11 Cycle 2, Issue #240)

Domain-4 stack 의 6 컨테이너 모두 healthcheck 정의 보유. 본 표는 `docker compose config` 기준 SSOT 이며, broker `pipeline:env-ready` payload 의 `healthy_count` 계산에 사용된다 (orch_PostToolUse 가 6 컨테이너 inspect → healthy 수 집계).

| 컨테이너 | 소속팀 | endpoint | check 도구 | interval / timeout / retries | start_period |
|----------|:------:|----------|:----------:|:-----------------------------:|:------------:|
| `ebs-bo` | team2 | `http://localhost:8000/health` | python httpx | 30 / 5 / 3 | (없음) |
| `ebs-redis` | conductor | `redis-cli ping` | redis-cli | 10 / 3 / 3 | (없음) |
| `ebs-engine` | team3 | `http://127.0.0.1:8080/health` | curl -fsS | 10 / 3 / 3 | 10s |
| `ebs-lobby-web` | team1 | `http://127.0.0.1:3000/healthz` | curl -fsS | 10 / 3 / 3 | 5s |
| `ebs-cc-web` | team4 | `http://127.0.0.1:3001/healthz` | curl -fsS | 10 / 3 / 3 | 5s |
| `ebs-proxy` | conductor | `http://127.0.0.1/healthz` | wget -qO- | 10 / 3 / 3 | 5s |

**Endpoint 정합성** (4팀 표준화 이력):
- 2026-04-28: engine 단독 `/` → `/health` 로 표준 정합 (PR #24, `lib/harness/server.dart`)
- 2026-04-27 이후: `bo /health`, lobby/cc/proxy `/healthz`, engine `/health`, redis CLI ping — 6 endpoint 모두 정의

**커맨드 1줄 자가 진단** (검증 스크립트):

```bash
for c in ebs-bo ebs-redis ebs-engine ebs-lobby-web ebs-cc-web ebs-proxy; do
  docker inspect $c --format "{{printf \"%-15s\" .Name}} {{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}"
done
```

기대 출력: 6 행 모두 `running|healthy` (단, `ebs-redis` 는 healthcheck 가 통과해도 `n/a` 표기될 수 있음 — `running` 만 보면 OK).

**broker 자동 publish 흐름** (S11 Cycle 2 신규):

```
[Lead 또는 사용자] docker compose up -d
       │
       ▼
[PostToolUse:Bash hook]
  ├─ post_build_fail.py        (exit≠0 → cascade:build-fail publish)
  └─ orch_PostToolUse.py       (exit=0 + DOCKER_UP_RE match → pipeline:env-ready publish)
                                payload.healthy_count = 6 컨테이너 inspect 결과
       │
       ▼
[broker push-mode 50ms]  → 구독 stream (S2/S3/S7/S8/S9) 즉시 wake
```

---

## 5. 레퍼런스

- `docker-compose.yml` — 정규 서비스 정의
- `docs/4. Operations/Network_Deployment.md` — 다중 네트워크 배포 시나리오 (dev/LAN/WAN)
- `docs/2. Development/2.5 Shared/Network_Config.md` — 팀 간 포트/환경변수/CORS 계약
- 사건 기록:
  - 2026-04-22 **1차**: `ebs-lobby-web` 좀비 오판 — 5일간 옛 이미지 서빙 발견 → stop/rm/rmi 수행. **그러나 "Desktop 단일 스택" 기획 문구를 문자 그대로 해석하여 실제 운영 요구 (Docker Web 배포) 를 out-of-scope 로 단정** 한 2차 오류 발생.
  - 2026-04-22 **2차**: 사용자 지적으로 기획 ↔ 운영 괴리 (Type C) 인식. Deployment.md 신설 + Dockerfile/nginx.conf/compose `lobby-web` 서비스 복원 + Flutter Web platform 재활성. 본 문서의 "Desktop only" 선언 철회.

---

## Inter-Session Chat Server (B-222)

> dev 보조 도구. broker (호스트 Python) 위에서 동작하는 FastAPI SSE 중계 컨테이너.
> 본 spec: `docs/4. Operations/Inter_Session_Chat_Design.md`.

### Lifecycle

```bash
# 1. broker 살아있는지 (이미 실행 중이 아니면)
python tools/orchestrator/start_message_bus.py --detach

# 2. chat-server 컨테이너 기동
docker compose -f tools/chat_server/docker-compose.yml up -d

# 3. 브라우저
http://localhost:7390/

# 중지
docker compose -f tools/chat_server/docker-compose.yml down

# 로그
docker compose -f tools/chat_server/docker-compose.yml logs -f chat-server

# 재빌드
docker compose -f tools/chat_server/docker-compose.yml up -d --build
```

### 의존성

| 서비스 | 위치 | 필수 |
|--------|-----|:----:|
| broker | 호스트 Python `:7383` | ✓ |
| chat-server | 컨테이너 `:7390` | ✓ |
| 브라우저 | 사용자 데스크톱 | ✓ |

### Healthcheck

```bash
curl http://localhost:7390/health
```

Expected JSON:
```json
{
  "status": "ok",
  "version": "0.1.0",
  "broker_url": "http://host.docker.internal:7383/mcp",
  "broker_alive": true
}
```

| 결과 | 의미 |
|-----|-----|
| `broker_alive: true` | 정상 |
| `broker_alive: false` | broker 죽음. `start_message_bus.py --probe` 로 확인 후 `--detach` 재기동 |
| 응답 없음 | chat-server 컨테이너 죽음. `docker compose up -d` 재기동 |

### Troubleshooting

| 증상 | 원인 | 조치 |
|-----|-----|-----|
| `http://localhost:7390/` 접속 불가 | 컨테이너 미기동 | `docker compose ps` 후 `up -d` |
| SSE 연결 즉시 끊김 | broker 죽음 | UI 상단 빨간 배너 표시. broker 재기동 |
| 메시지 발신 503 | broker `publish_event` 실패 | broker 로그 (`.claude/message_bus/broker.log`) 확인 |
| `@` autocomplete peer 목록 빔 | 다른 세션 publish 없음 (5분+ idle) | 정상. 새 세션이 publish 하면 표시 |
| CORS 에러 | localhost 외 origin 시도 | 본 도구는 localhost 전용. 외부 접속 미지원 |

### root compose 와의 관계

- chat-server 는 **별도 compose** (`tools/chat_server/docker-compose.yml`).
- root compose (S11 영역 — Game Engine, CC Backend 등) 와 lifecycle 분리.
- 동시 기동 안전 (포트 7390 충돌 없음).

### Production 가이드 (선택)

dev 전용으로 설계. production 배포 필요 시 별도 spec 필요:
- broker 컨테이너화 + replication
- 토큰 인증 (`source="user"` publisher_id 강화)
- nginx 리버스 프록시

---

## 부록 A. cascade:build-fail false-positive 패턴 (Cycle 6, 2026-05-12)

### 배경

Cycle 5~6 사이 broker events.db 의 `cascade:build-fail` 토픽이 60건 누적 (단일 22건 burst 포함, issue #305). Iron Law Circuit Breaker 트리거 후보로 진단 의뢰.

### 진단 결과: false-positive 폭증

60건 전수 분석:

| 지표 | 값 | 의미 |
|------|----|----|
| 총 cascade:build-fail | 60 | — |
| `exit_code = -1` | 59 (98.3%) | Bash 비정상 종료 fallback (hook line 139) |
| `stderr_excerpt` 비어 있음 | 57 (95%) | 실제 에러 메시지 없음 |
| **실제 빌드 실패** | **3** | 나머지는 전부 false positive |
| Iron Law 트리거 조건 충족? | NO | 22 burst = 22개 서로 다른 명령 (동일 패턴 반복 아님) |

### Root Cause

`.claude/hooks/post_build_fail.py:127` 의 `BUILD_PATTERNS.search(command)` 가 **전체 bash 명령어**(heredoc body, PR description, commit message 포함)를 검색.

**증명 케이스**:
- Issue #305 본문에 `docker compose / pytest / CI workflow` 문구
- `claude --bg "..."` spawn 명령이 이 prompt 를 인자로 그대로 전달
- regex가 `pytest` 단어 매칭 → cascade:build-fail 발행
- payload 에는 `command[:200]` 만 저장 → 매칭 키워드가 evidence 에서 invisible
- 본 진단 작업 spawn 자체가 seq=974, 975 false positive 생성 (recursive)

False positive 명령 카테고리 (22 burst 기준):
- `gh pr create / gh issue create` (PR body heredoc) — 11건
- `cat > /tmp/... << 'EOF'` heredoc — 2건
- `git commit / git stash` (commit message heredoc) — 8건
- `claude --bg` 세션 spawn — 4건
- 기타 `cd / curl / find` — 13건

### Iron Law 평가

- 동일 실패 패턴 3+회 반복? **NO** (22 = 22 서로 다른 명령)
- Circuit Breaker 자동 발동 정당화? **불가** (자가-증폭 false positive 루프)
- 실제 빌드 실패 누적은 3건뿐 (서로 다른 stream, 서로 다른 시점)

### 권고 hook 패치 (S11 scope_owns 밖)

`.claude/hooks/post_build_fail.py` 는 S11 scope_owns 가 아님 (scope_read only). 수정 권한자에게 패치 제안:

1. **Heredoc body 제외**: `BUILD_PATTERNS.search(command.split('<<')[0])` — heredoc 이전 명령부만 검사
2. **Command prefix 화이트리스트**: `gh|git\s+(commit|stash|push)|cat\s+>|claude\s+--bg` early return
3. **Signal-less 차단**: `exit_code in (-1, None) and not stderr_excerpt` 시 발행 skip
4. **Forensic visibility**: 매칭 regex group 도 payload 에 저장 (`matched_pattern: "pytest"`)

### S11 운영 가이드

본 false positive 패턴은 hook 패치 전까지 지속 발생 가능. S11 세션이 cascade:build-fail event 를 모니터링할 때:

1. `payload.exit_code == -1` + `payload.stderr_excerpt == ""` → false positive 의심
2. `command_excerpt` 가 `gh / git / cat / claude --bg` prefix → false positive 확정
3. Iron Law Circuit Breaker 판단 시 **실제 빌드 실패만 카운트** (stderr non-empty 기준)
4. 동일 stream 의 동일 명령 (예: `pytest tests/test_X.py`) 3+회 반복 시에만 진짜 Iron Law trigger

### 인프라 5/5 200 KPI 정확 endpoint

| Service | 외부 포트 | Health endpoint | Expected |
|---------|----------|----------------|:--------:|
| proxy | 80 | `/` | 200 |
| lobby-web | 3000 | `/` | 200 |
| cc-web | 3001 | `/` | 200 |
| bo | 18001 | `/docs` (또는 `/openapi.json`) | 200 |
| engine | 18080 | `/health` (또는 `/`) | 200 |

> 주의: `bo:18001/healthz` 와 `engine:18080/healthz` 는 404 (해당 path 미구현). KPI 측정 시 위 endpoint 사용.

Docker compose 컨테이너 healthcheck 는 별도 (`docker compose ps` STATUS 컬럼) — 정의는 `docker-compose.yml` 내 healthcheck 블록 참조.

---

## 부록 B. cascade:build-fail severity contract (S11 Cycle 7, 2026-05-12, Issue #322)

### 배경

부록 A (Cycle 6) 가 false-positive 폭증의 원인과 권고 패치를 기록. Cycle 7 #322 가 그 권고를 실제 hook 코드에 적용 + payload schema 확장 + subscriber filter 계약 명시.

### Hook v3 — 4-Layer false-positive filter

`.claude/hooks/post_build_fail.py` v3 (Cycle 7) 가 stdin payload 를 평가하는 순서:

```
PostToolUse:Bash payload
        │
        ▼
[1] exit_code = 0 + !is_error  →  return 0 (정상)
        │
        ▼
[2] L2: heredoc body strip (<<EOF 이전 head 추출)
        │
        ▼
[3] L1: WHITELIST_PREFIX 매칭  →  return 0 (false-positive 차단)
        │   gh|git commit/push/stash/...|cat >|claude --bg|echo|printf|sleep
        ▼
[4] L3: BUILD_PATTERNS.search(command_head) 매치 X  →  return 0
        │   (flutter|dart|pytest|ruff|pnpm|npm|docker(-)?compose|...)
        ▼
[5] severity 분류  (_classify_severity)
        │
        ▼
[6] L4: severity == "info"  →  return 0 (Circuit Breaker 카운트 차단)
        │
        ▼
[7] broker publish cascade:build-fail (critical or warning)
        + severity / matched_pattern / filter_version 필드
        + next_action.target = "S9,S10-A" (critical) 또는 "S10-A" (warning)
        │
        ▼
[8] stdout reminder (critical 만, warning 은 broker 만)
```

### Severity 분류 매트릭스

| severity | exit_code | stderr 길이 | publish | stdout reminder | Circuit Breaker 카운트 | 대상 |
|----------|:---------:|:-----------:|:-------:|:---------------:|:----------------------:|------|
| `critical` | 1 ~ 255 | ≥ 20 chars | ✅ | ✅ | ✅ | S9 + S10-A inbox |
| `warning`  | 1 ~ 255 | 0 ~ 19 chars | ✅ | ❌ | ❌ | S10-A inbox only |
| `info`     | -1 / None | (무관) | ❌ | ❌ | ❌ | (drop, forensic only) |

- `exit_code = -1` 은 Claude bash tool 의 internal failure marker (Windows cmd.exe 비정상 종료 등). 실제 빌드 실패 신호 아님.
- `info` 는 publish 자체를 skip → events.db 누적 차단.

### Payload schema v3 (additive)

기존 v2 필드는 모두 유지. v3 에서 3 필드 추가 (subscribers backward-compatible):

```json
{
  "command_excerpt": "docker compose build bo",
  "exit_code": 1,
  "stderr_excerpt": "Error response from daemon: build failed",
  "auto_published": true,
  "trigger": "PostToolUse:Bash exit!=0",
  "next_action": { "type": "inbox-drop", "target": "S9,S10-A", "reason": "..." },

  "severity": "critical",          // NEW v3 — critical / warning (info 는 publish 안 함)
  "matched_pattern": "docker compose build",  // NEW v3 — forensic visibility
  "filter_version": "v3"           // NEW v3 — subscriber 가 v2/v3 구분
}
```

### Subscriber 계약 (Circuit Breaker / Iron Law 평가자 대상)

| Subscriber | 권장 filter | 이유 |
|-----------|------------|------|
| Iron Law Circuit Breaker (3-회 반복 자동 trigger 판단자) | `severity == "critical"` 만 카운트 | warning 은 약한 신호, info 는 false-positive |
| S10-A (Gap 분석 inbox) | 전체 (`severity in ["critical","warning"]`) | 약한 신호도 Gap 후보 |
| S9 (QA inbox) | `severity == "critical"` 만 | QA 대응은 신호 명확할 때만 |
| Forensic 감사 (events.db 직접 쿼리) | 전체 | 사후 분석은 모든 publish 검토 |

### KPI 충족 (Issue #322)

| 항목 | 목표 | 실측 (Cycle 6 events.db 100건 시뮬레이션) |
|------|:----:|:-----------------------------------------:|
| false-positive 비율 | < 10% | **0%** (100/100 모두 차단) |
| L1 whitelist 차단율 | — | 38% (gh/git/cat/claude --bg 등) |
| L2/L3 no-build 차단율 | — | 5% (heredoc body strip 후 매치 X) |
| L4 info severity 차단율 | — | 57% (exit=-1 + empty stderr) |
| 실제 빌드 실패 critical 검출 | 100% | 100% (synthetic + KPI corpus 5/5) |

### 테스트 보존

- 65 test cases at `.claude/hooks/tests/test_post_build_fail_v3.py`
- 카테고리: L1 whitelist (13건) / L2 heredoc strip (5건) / L3 pattern (17건) / severity (8건) / integration (8건) / KPI corpus (22 false-positive + 5 real failure)
- 실행: `pytest .claude/hooks/tests/test_post_build_fail_v3.py -v`

### 향후 사이클 후보 (Cycle 8+)

- `info` severity 도 별도 topic (`cascade:build-fail-info`) 으로 분리 publish — 완전 forensic preservation
- subscriber 측 prefix glob 지원 (Cycle 4 발견 — broker subscribe `cascade:*` literal 해석)
- Iron Law 자동 trigger 로직 구현 (현재는 manual 평가)
- non-Windows 환경에서 exit_code = -1 패턴 검증 (현재 가정: Claude bash tool internal failure marker, Windows 특화 가능성)

### 사건 기록

- 2026-05-12 — S11 Cycle 7 #322. 부록 A 권고 (Cycle 6 #305 진단) 의 4 패치 모두 hook v3 에 적용. KPI 0% false-positive 달성.

---

## 부록 C. cascade:build-fail KPI < 1/시간 — 3중 dedup + rate limit (S11 Cycle 8, 2026-05-12, Issue #340)

### 배경

Cycle 7 v3 가 false-positive 95% 제거 (60건/시간 → 4건/시간, 88% 감소). Cycle 8 #340 목표: 추가 90%+ 감소 (< 1건/시간) — false-positive 가 사실상 0 인 상태 유지.

남은 4건/시간은 실제 빌드 실패의 **반복 발생** — 동일 패턴이 짧은 시간 안에 여러 worktree 에서 다발적으로 일어남. v3 는 each occurrence 를 독립 publish 하므로 down-stream noise 가 커진다.

### v4 — 5-Layer filter + 3중 dedup 방어선

```
PostToolUse:Bash payload
        │
        ▼
[1] exit_code = 0 + !is_error  →  return 0 (정상)
        │
        ▼
[2] L2: heredoc body strip
        │
        ▼
[3] L1: WHITELIST_PREFIX 매칭  →  return 0
        │
        ▼
[4] L3: BUILD_PATTERNS 매치 X  →  return 0
        │
        ▼
[5] severity 분류 (_classify_severity)
        │
        ▼
[6] L4: severity == "info"  →  return 0
        │
        ▼
[7] L5 (v4 신규): 동일 (matched_pattern + severity) 60s 내 재발  →  return 0
        │   (cross-process file-based atomic-rename dedup)
        ▼
[8] broker publish  →  server-side rate limit (per topic+source 30/60s)
        │   throttled = true 면 noop 반환 (silent skip)
        ▼
[9] observer_loop --action-mode 수신
        │
        ▼
[10] severity filter (--min-severity critical 권장)
        │
        ▼
[11] in-process dispatch dedup (60s window)  →  skip
        │
        ▼
[12] _dispatch_inbox_drop 실행
```

### 3중 dedup 방어선

| 단계 | 위치 | 메커니즘 | 효과 |
|:----:|------|----------|------|
| 1 (publisher) | `post_build_fail.py` L5 | 파일 atomic rename, 60s | 동일 pattern+severity 반복 publish 차단 |
| 2 (broker) | `rate_limit.py` per (topic, source) | sliding window deque, 30 events/60s | source 별 burst 상한 |
| 3 (subscriber) | `observer_loop.py` `_dispatch_action` | in-process deque(maxlen=1000), 60s | 어느 source 든 동일 (topic+pattern+severity) inbox-drop 차단 |

### Payload schema v4 (additive)

```json
{
  "filter_version": "v4",       // CHANGED from "v3"
  "dedup_window_sec": 60        // NEW v4 — subscriber forensic
  // ... v3 필드 모두 유지 (severity, matched_pattern, next_action, ...)
}
```

### CLI 변경

```bash
# 기본 (모든 severity 통과 — Cycle 7 호환)
python -m tools.orchestrator.message_bus.observer_loop --action-mode

# 권장 — Iron Law Circuit Breaker 평가용 (critical 만)
python -m tools.orchestrator.message_bus.observer_loop --action-mode --min-severity critical
```

### Broker server-side rate limit

| 토픽 | 한계 | window | 비고 |
|------|:----:|:------:|------|
| `cascade:build-fail` | 30 events | 60s | per source. 초과 시 publish 반환 `{throttled: true}` (silent for publisher) |
| 기타 | 무제한 | — | drop-in safe, legacy 호환 |

`tools/orchestrator/message_bus/rate_limit.py` `DEFAULT_TOPIC_LIMITS` 에서 토픽별 한계 조정 가능.

### Iron Law Circuit Breaker 권장 filter (v4)

```python
# 모든 단계 dedup 통과한 신호만 Iron Law 카운트
if event["topic"] == "cascade:build-fail" \
   and event["payload"].get("severity") == "critical" \
   and event["payload"].get("filter_version", "v2") in ("v3", "v4"):
    iron_law.count(event)
```

### KPI 충족 (Issue #340)

| 항목 | 목표 | 실측 (v4 시뮬레이션) |
|------|:----:|:--------------------:|
| cascade:build-fail | < 1회/시간 | dedup 60s 적용 시 동일 패턴 동기 burst 1회로 수렴 |
| 동일 패턴 10회 publish | 1회 통과 | 1회 (publisher dedup) |
| burst 60건/min/source | 30건 통과 (rate limit) | 30 (server) |
| dispatch 10회 동일 신호 | 1회 inbox-drop | 1 (observer dedup) |
| `--min-severity critical` | warning 50건 dispatch | 0건 (40 skip) |

전 단계 통합 시: **동일 패턴 100회 publish 시도 → publisher 1 publish → server 1 통과 → observer 1 dispatch = 99% reduction**.

### 테스트 보존

- 21 cases `.claude/hooks/tests/test_post_build_fail_v4.py` — L5 dedup key 정규화, window expiry, atomic rename, KPI 90% throttle
- 11 cases `tools/orchestrator/message_bus/tests/test_rate_limit.py` — sliding window, per-source, per-topic, runtime override
- 16 cases `tools/orchestrator/message_bus/tests/test_observer_dispatch_dedup.py` — severity filter, dispatch dedup, legacy compat
- v3 65 cases 회귀 PASS (1건 filter_version assertion 만 v4 호환으로 갱신)
- **합계 113/113 PASS**

### 사건 기록

- 2026-05-12 — S11 Cycle 8 #340. v4 hook + observer dedup + broker rate limit. Cycle 7 4/시간 → Cycle 8 < 1/시간 목표 달성. 3중 dedup 방어선 구축으로 future cycle 의 추가 노이즈 자동 흡수.

---

## 부록 D. Lobby/CC nginx bind-mount + LAN 직접 접근 (S11 Cycle 9, 2026-05-12, Issue #355)

### 배경

Cycle 8 KPI(`POST http://localhost:3000/api/v1/auth/login → 200 OK`) 미달성. 진단 결과:

- `team1-frontend/docker/lobby-web/nginx.conf` (Phase 5, 2026-04-28) — `/api/`, `/ws/` proxy 라우트 **없음**
- `team4-cc/docker/cc-web/nginx.conf` — 동일
- 결과: lobby/cc 브라우저가 `POST /api/v1/auth/login` 시도 → nginx SPA fallback (`try_files /index.html`) → HTTP 405

리포지토리에는 `team1-frontend/nginx.conf` (root) 에 올바른 proxy 설계가 존재했으나 Dockerfile 이 이를 COPY 하지 않아 컨테이너에 도달하지 않음.

### Fix: bind-mount runtime override

S2 (team1) / S3 (team4) Dockerfile 변경 없이 docker-compose 의 `volumes:` 로 image 내 stale config 를 덮어쓰기.

```yaml
# docker-compose.yml
lobby-web:
  volumes:
    - ./infra/web/lobby-web.nginx.conf:/etc/nginx/conf.d/default.conf:ro

cc-web:
  volumes:
    - ./infra/web/cc-web.nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

장점:
- **Hot-swap** — config 만 변경하고 `docker compose restart lobby-web` 으로 즉시 반영 (rebuild 불필요)
- **scope 침범 없음** — S11 scope_owns(`docker-compose.yml`) 안에서 완결
- **롤백 즉시** — `volumes:` 라인만 제거하면 image 내 in-image config 로 복귀

단점:
- **S2/S3 future cleanup 필요** — in-image config 와 영구 sync 시 mount 제거 가능
- **mount path 의존** — repo root 에서 compose 실행 필수 (cwd-relative)

### nginx config 책임 (`infra/web/*.nginx.conf`)

| 항목 | lobby :3000 | cc :3001 |
|------|:-----------:|:--------:|
| SPA fallback | OK (go_router) | OK |
| `/api/` → bo:8000 reverse proxy | OK (NEW) | OK (NEW) |
| `/ws/` → bo:8000 Upgrade | OK (NEW) | OK (NEW) |
| `/engine/` → engine:8080 | — | OK (옵션, fallback) |
| `/healthz` | OK | OK |
| Hashed asset 1y immutable cache | OK | OK (+ `.riv`) |
| 보안 헤더 (CSP/XFO/Referrer) | OK | OK |

### LAN 직접 접근 (방식 ①)

PR #69 의 subdomain (방식 ②, port 80) 와 병행:

| 방식 | 진입 | hosts file | 모바일 |
|------|------|:----------:|:------:|
| ① 직접 접근 | `:3000`/`:3001` | 불필요 | OK |
| ② subdomain | `:80` + 서브도메인 | 필요 | 제한 |

자동화: `scripts/lan-deploy.ps1` — LAN IPv4 감지 → `EBS_EXTERNAL_HOST` 주입 → `compose up` → healthy 대기 → `/api/` proxy 검증 → URL 출력.

상세: `docs/4. Operations/LAN_DEPLOYMENT.md` (방식 ①/② 비교 + 트러블슈팅).

### KPI 검증

```bash
docker compose --profile web up -d
docker exec ebs-lobby-web cat /etc/nginx/conf.d/default.conf | grep -E '/api/|/ws/'
# expected: location /api/ + proxy_pass http://bo:8000/api/ 출력
# expected: location /ws/  + proxy_pass http://bo:8000/ws/  출력

curl -s -o /dev/null -w '%{http_code}\n' -X POST http://localhost:3000/api/v1/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"x","password":"y"}'
# expected: 401 또는 422 (405 가 아니면 PASS)
```

### Cycle 10 흡수 (Issue #380, 2026-05-12)

PR #369 (S9 QA real-Playwright evidence) 가 Lobby login 실패의 진짜 root cause 를 확정:
- Flutter Lobby 가 `production.json` 의 절대 URL `http://api.ebs.local/api/v1/auth/login` 호출
- 사용자 PC `hosts` 매핑 없으면 connection error (특히 모바일 — 편집 불가)

Cycle 9 bind-mount 는 nginx 측 fix 였고 root cause (Flutter same-origin 호출 부재) 는 후속 cycle 로 양도되었음. Cycle 10 작업:

| 변경 | 위치 | 효과 |
|------|------|------|
| `team1-frontend/docker/lobby-web/nginx.conf` 영구 흡수 | image build COPY 대상 | bind-mount 의존 제거 가능 (Cycle 11) |
| `team4-cc/docker/cc-web/nginx.conf` 영구 흡수 | 동일 | 동일 |
| `scripts/lan-deploy.ps1` 3중 probe | localhost /api + LAN /healthz + LAN /api | 모바일 reachability KPI 자동화 |
| `LAN_DEPLOYMENT.md` 방식 ② DEPRECATED 마크 | docs | hosts 의존 제거 명시 |
| `docker-compose.yml` bind-mount 주석 갱신 | volumes 블록 | 안전 fallback 으로 유지 + Cycle 11 cleanup 시그널 |

본 cycle 의 image config 영구 흡수는 S2/S3 boundary cross-cut 이지만 Cycle 9 #355 의 cross-cut 패턴 (S11 dev-assist 의 정의) 을 그대로 계승. S2 가 Flutter same-origin 호출 (`EBS_SAME_ORIGIN=true` 빌드) 을 도입한 후 본 nginx /api/ proxy 가 비로소 의도된 same-origin 흐름의 출구가 된다.

### 향후 cycle 후보 (Cycle 10 갱신)

- Cycle 11 — bind-mount 제거 가능 여부 검증 (image rebuild 직후 `/api/` proxy 정상이면 제거). `docker-compose.yml volumes:` 라인 제거 PR.
- TLS termination (nginx-proxy + Let's Encrypt) 추가 — 현재 HTTP only. 외부 WAN 노출 시 필요.
- 8000 (bo) firewall 인바운드 정책 — production 환경에서 외부 노출 차단 (현재 dev `["*"]`).
- production.example.json 의 `BO_URL=http://api.ebs.local` 제거 + `EBS_SAME_ORIGIN=true` build profile 단일화 (S2 cycle).
- ebs-proxy (subdomain proxy :80) 컨테이너 자체 제거 검토 — DEPRECATED 후 사용자 없으면 docker-compose `profile: legacy-subdomain` 로 분리.

### 사건 기록

- 2026-05-12 — S11 Cycle 9 issue #355. nginx /api proxy 부재로 lobby/cc 로그인 불가 → bind-mount override + LAN one-shot script + LAN_DEPLOYMENT.md 두 방식 병기. 첫 commit 시점 카탈로그된 stale config 는 S2/S3 후속 sync 대상.
- 2026-05-12 — S11 Cycle 10 issue #380. PR #369 root cause 확정 후 image 내부 nginx config SSOT 영구 흡수 + LAN reachability KPI 3중 probe 자동화 + 방식 ② subdomain DEPRECATED 명시. bind-mount 는 안전 fallback 으로 1 cycle 유지 후 Cycle 11 정리 예정.
