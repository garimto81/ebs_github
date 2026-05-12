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
| frontmatter | source / topic / seq / ts / target / action_type / observer_dropped_at |
| 본문 | Payload JSON (4 key 정상 보존) |

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
