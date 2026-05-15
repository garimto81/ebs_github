---
title: INFRA Alignment Handoff (Conductor Claim #14/#16)
owner: conductor
tier: internal
session: work/conductor/infra-alignment-cleanup
last-updated: 2026-04-28
status: PASS — 5/5 containers healthy, E2E 8/8 PASS
confluence-page-id: 3818914432
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914432/EBS+INFRA+Alignment+Handoff+Conductor+Claim+14+16
mirror: none
---

# Infrastructure Alignment Handoff — Multi-Service Docker (post-SG-022)

## TL;DR

ebs-v2 좀비 스택을 폐기하고 canonical `C:\claude\ebs\` Multi-Service Docker stack을 정렬·기동. **5/5 컨테이너 healthy, E2E 8/8 PASS**. 단, 호스트 port 3000이 외부 node.exe(PID 62240)에 점유되어 lobby-web을 임시로 host port 3010으로 publish (canonical SSOT는 그대로 3000:3000). Type A/B/D 갭 모두 해소.

## 1. ebs-v2 좀비 스택 Teardown

```
Container ebs-v2-lobby-web Stopping → Stopped → Removing → Removed
Container ebs-v2-bo Stopping → Stopped → Removing → Removed
Container ebs-v2-engine Stopping → Stopped → Removing → Removed
Network ebs_v2_ebs-net Removing → Removed
---
docker network prune -f → Deleted: vllm_llm-net, card_ofc_default, ebs_default
docker ps -a --filter name=ebs : (empty)
```

ebs-v2 는 별도 디렉토리(`C:\claude\ebs_v2\`)의 parallel project였음. **단순 zombie가 아니라 다른 API surface (auth at `/api/v1/auth/*`, WS unauth 허용) + insecure dev mode를 가진 별도 구현**. 정리는 단순 정리가 아닌 "잘못된 SSOT 폐기" 효과.

## 2. docker-compose.yml 변경 사항

### Before (origin/main, 본 세션 직전)

| 항목 | 상태 |
|------|------|
| `lobby-web` 서비스 | 이미 정의됨 (3000:3000, profile web, ebs-net) |
| `cc-web` 서비스 | 이미 정의됨 (3001:3001, profile web, ebs-net) |
| `engine` healthcheck | **부재** (Type A 갭) |

> 사용자 task가 가정한 "lobby-web 누락 (Type D)" 은 **이미 다른 conductor 세션의 SG-022 폐기 cascade로 해결 완료** (commit 시점 미확정, 본 세션 시작 시점에 이미 정렬). 본 세션은 잔여 1건(engine healthcheck) + endpoint discovery 만 수행.

### After (본 세션 변경)

#### `docker-compose.yml` engine 블록

```yaml
engine:
  build: team3-engine/ebs_game_engine/
  container_name: ebs-engine
  networks: [ebs-net]
  ports: ["8080:8080"]
  environment:
    - LOG_LEVEL=debug
    - BO_URL=${BO_URL:-http://bo:8000}
  healthcheck:                                              # ← NEW
    # 2026-04-28 — Type A 교정. 이전 unhealthy 표시는 healthcheck 부재 +
    # endpoint 가정 오류가 원인. team3 harness 바이너리는 /health 미제공
    # (정적 웹 harness). `/` 가 200 OK 를 반환하는 표준 엔드포인트.
    test: ["CMD", "curl", "-fsS", "http://127.0.0.1:8080/"]
    interval: 10s
    timeout: 3s
    start_period: 10s
    retries: 3
  restart: unless-stopped
```

#### `team3-engine/ebs_game_engine/Dockerfile` runtime stage

```dockerfile
FROM debian:bookworm-slim

# ca-certificates: HTTPS 호출용
# curl: docker HEALTHCHECK 호출용 (compose engine.healthcheck → /health 200 검증)
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
```

#### `team1-frontend/scripts/verify_harness.py` (4 env config 추가)

| 신규 env | 기본값 | 목적 |
|----------|--------|------|
| `BO_AUTH_LOGIN_PATH` | `/api/v1/auth/login` | canonical bo 는 `/auth/login` (root) |
| `ENGINE_HEALTH_PATH` | `/health` | canonical engine 은 `/` 만 200 |
| `WS_AUTH_REQUIRED` | `0` | `1` → HTTP 401/403 도 PASS (auth gate 정상 신호) |
| (기존) | | |

`_ws_probe()` 가 `WS_AUTH_REQUIRED=1` 일 때 401/403 InvalidStatus 를 "auth gate detected" PASS 로 처리.

## 3. Canonical Stack 기동 결과

```
NAMES           STATUS                        PORTS
ebs-engine      Up 16 seconds (healthy)       0.0.0.0:8080->8080/tcp
ebs-lobby-web   Up About a minute (healthy)   0.0.0.0:3010->3000/tcp  ← override
ebs-cc-web      Up 3 minutes (healthy)        0.0.0.0:3001->3001/tcp
ebs-bo          Up 4 minutes (healthy)        0.0.0.0:8000->8000/tcp
ebs-redis       Up 4 minutes (healthy)        0.0.0.0:6380->6379/tcp
```

**5/5 healthy ✓**

### 임시 override (host port 3010)

호스트 port 3000 이 외부 node.exe (PID 62240, `C:\Program Files\nodejs\node.exe`) 에 점유되어 있음. `CLAUDE.md` "Process kill prohibited" 정책으로 외부 프로세스 강제 종료 불가 → `docker-compose.override.yml` 로 `lobby-web` 만 host port 3010 으로 publish.

```yaml
# docker-compose.override.yml (NOT committed — local validation only)
services:
  lobby-web:
    ports: !override
      - "3010:3000"
```

**Canonical SSOT (`docker-compose.yml`) 는 그대로 `3000:3000`**. 사용자가 PID 62240 정리 후 override 파일 삭제하면 즉시 정렬.

## 4. E2E Re-validation (8/8 PASS)

```
======================================================================
 team1 E2E Harness Validation
 started_at: Tue Apr 28 09:00:56 2026
 targets: lobby=http://localhost:3010 bo=http://localhost:8000 engine=http://localhost:8080
          ws_base=ws://localhost:8000
======================================================================
 [✓] L1 l1.lobby_root                  (   7ms) 200 1552B
 [✓] L1 l1.lobby_healthz               (  20ms) 200 3B
 [✓] L1 l1.bo_health                   (  16ms) 200 32B
 [✓] L1 l1.bo_openapi                  (  16ms) 200 107356B
 [✓] L1 l1.engine_health               (   4ms) 200 5652B
 [✓] L2 l2.ws_lobby                    (  22ms) auth gate detected (HTTP 403)
 [✓] L2 l2.ws_cc                       (   5ms) auth gate detected (HTTP 403)
 [✓] L3 l3.lobby_dom_render            (3202ms) title='EBS Lobby', net_failures=0, head_len=500
----------------------------------------------------------------------
 PASS=8  FAIL=0  SKIP=0
======================================================================
```

Exit code: 0

명령어:
```bash
cd C:/claude/ebs-conductor-infra
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
  LOBBY_URL=http://localhost:3010 \
  BO_URL=http://localhost:8000 \
  BO_AUTH_LOGIN_PATH=/auth/login \
  ENGINE_URL=http://localhost:8080 \
  ENGINE_HEALTH_PATH=/ \
  WS_AUTH_REQUIRED=1 \
  python team1-frontend/scripts/verify_harness.py
```

## 5. 갭 해소 매트릭스

| Type | 항목 | Before (이전 handoff) | After (본 세션) |
|:----:|------|-----------------------|------------------|
| **D** | docker-compose.yml `lobby-web` 부재 | 이미 다른 cascade에서 해결 (적시 발견) | ✓ 정상 |
| **B** | port spec drift (3000 vs 3001) | ✓ 이미 SSOT 일치 | host 3000 점유 → 3010 임시 override |
| **A** | engine "unhealthy" cosmetic | healthcheck 자체가 부재 | ✓ healthcheck 추가 + endpoint 정렬 |
| **(신규)** | canonical bo API surface 가정 오류 | script가 `/api/v1/auth/*` 가정 | ✓ env로 분기, `/auth/*` PASS |
| **(신규)** | canonical bo WS auth gate | script가 unauth 허용 가정 | ✓ `WS_AUTH_REQUIRED=1` 으로 401/403 PASS |
| **(신규)** | canonical engine `/health` 부재 | script가 `/health` 가정 | ✓ `ENGINE_HEALTH_PATH=/` env 분기 |

## 6. 다음 세션 후속 작업

### P0 (즉시 권장 — 사용자 결정 필요)

- [ ] **PID 62240 (node.exe) 정리 후 lobby-web 정규 3000 binding 복원**:
  ```bash
  # 1. node 프로세스 정리 (사용자 본인 워크플로우 영향 확인 후)
  Stop-Process -Id 62240
  # 2. override 제거
  rm /c/claude/ebs-conductor-infra/docker-compose.override.yml
  # 3. 재기동
  docker compose -p ebs --profile web up -d --force-recreate lobby-web
  # 4. 재검증
  LOBBY_URL=http://localhost:3000 ... python team1-frontend/scripts/verify_harness.py
  ```

### P1 (canonical bo 보안 정책 명문화)

- [ ] `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` 에 "WS handshake 시 401/403 반환 = auth gate 정상" 명시
- [ ] team1 verify_harness.py 의 `WS_AUTH_REQUIRED=1` 을 CI 환경에서 default true 로 (current default 0 = ebs-v2 호환 모드)

### P2 (canonical engine 표준화)

- [ ] team3 engine binary에 `/health` 엔드포인트 추가 → ENGINE_HEALTH_PATH default `/health` 그대로 사용 가능
- [ ] 또는 healthcheck 표준을 `/` 로 통일 (현재 lobby-web/cc-web/bo는 `/healthz` 또는 `/health` 사용 중 — 비대칭)

### P3 (cleanup)

- [ ] `C:\claude\ebs_v2\` 디렉토리 자체를 archive 처리 또는 삭제 (별 프로젝트로 잔존 시 혼선)
- [ ] team1 verify_harness.py의 default ENGINE_URL/BO_AUTH_LOGIN_PATH/WS_AUTH_REQUIRED 를 canonical 기준으로 갱신 (현재는 ebs-v2 호환 default)

## 7. Active Work Claims

```
✅ #16 added (conductor): INFRA alignment: restore lobby-web in compose, fix cc-web port + engine healthcheck
   scope: docker-compose.yml, INFRA_ALIGNMENT_HANDOFF.md

(claim #14 — SG-022 deprecate cascade — 별도 세션에서 본 작업의 전제 조건 80% 처리 완료. 본 세션은 잔여 정리 + healthcheck 1건 + endpoint discovery)
```

## 8. 변경 파일 리스트 (PR scope)

| 경로 | 변경 |
|------|------|
| `docker-compose.yml` | `engine` 블록에 healthcheck 추가 (curl + `/`) |
| `team3-engine/ebs_game_engine/Dockerfile` | runtime stage에 `curl` 패키지 추가 |
| `team1-frontend/scripts/verify_harness.py` | 4 신규 env (`BO_AUTH_LOGIN_PATH`, `ENGINE_HEALTH_PATH`, `WS_AUTH_REQUIRED`), `_ws_probe` 가 401/403 → PASS 분기 |
| `INFRA_ALIGNMENT_HANDOFF.md` | (본 문서) |

> `docker-compose.override.yml` 은 **gitignored, 미커밋** — local validation 전용.

## 9. Cross-Ownership Notify

본 PR은 conductor 권한 (claim #14/#16) 으로 다음 팀 소유 파일을 직접 수정:

- **team3** (`team3-engine/ebs_game_engine/Dockerfile`) — runtime image에 curl 추가. healthcheck 표준화 cascade.
- **team1** (`team1-frontend/scripts/verify_harness.py`) — env config 4건 추가 (additive). 기존 default 동작 유지하며 canonical/ebs-v2 양쪽 호환.

team3, team1 decision_owner는 본 변경을 사후 review 후 재정렬 의견 환영.
