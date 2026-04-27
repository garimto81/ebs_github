---
title: ECOSYSTEM E2E Handoff — Multi-Service Docker Validation
owner: conductor
tier: operations
last-updated: 2026-04-27
status: PARTIAL — Run #2: 2/5 PASS, 3 distinct Type B/D gaps surfaced
---

# ECOSYSTEM E2E Handoff — Multi-Service Docker Validation

## Edit History

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-27 | v1.0 | 최초 작성 — Run #1 BLOCKED 상태 정직 기록 |
| 2026-04-27 | v1.1 | 외부 세션 reset 으로 산출물 손실 후 재생성. Docker pipe missing 진단 추가 |
| 2026-04-27 | v1.2 | Docker 회복 후 Run #2 실제 실행. 2/5 PASS, 4개 distinct Type B/D gap 발견 |

## TL;DR (Run #2 — 2026-04-27 22:32 KST)

| 항목 | 결과 |
|------|------|
| **Gatekeeper 판정** | 🟡 **PARTIAL FAIL** (2/5 PASS, exit 1) |
| **PASS (2)** | bo (200 OK `{"status":"ok","db":"connected"}`), engine (200 OK + uptime/sessions) |
| **FAIL (3)** | lobby-web (build 미완 + 포트 외부 점유), cc-web (build 미완), bo-ws-lobby (auth 403) |
| **자가 치유** | 1회 사용 (cc-web `web/` scaffold 추가) — 후속 Flutter SDK 미스매치로 추가 차단 |
| **Real Execution 원칙** | ✅ 준수 — 실제 docker ps + 실제 verify stdout + 실제 exit 1 |
| **거버넌스 의의** | SG-022 폐기 cascade 후 채택된 Multi-Service Docker compose 가 **소스 vs 빌드 컨텍스트** 미정렬 입증 — 후속 4개 Type B/D 백로그 |

## 작업 범위 (Sequential Backlog 추적)

### Run #1 (BLOCKED)

| Step | 상태 | 산출물 / 비고 |
|------|------|---------------|
| **Step 1**: Claim + 브랜치 | ✅ Done | 브랜치 `work/conductor/e2e-ecosystem-validation` |
| **Step 2**: Compose Build + Up | ⛔ BLOCKED | Docker daemon unresponsive |
| **Step 3**: verify_ecosystem.py | ✅ Done (작성만) | `tools/verify_ecosystem.py` (stdlib only) |
| **Step 4**: 자가 치유 | ⛔ N/A | Step 2 진입 실패로 트리거 미충족 |
| **Step 5**: PR | ✅ PR #8 (BLOCKED 상태로) | https://github.com/garimto81/ebs_github/pull/8 |

### Run #2 (PARTIAL — Docker 회복 후 자동 재실행)

| Step | 상태 | 결과 |
|------|------|------|
| **Step 2**: Compose Build | 🟡 3/5 빌드 성공 | bo ✅, redis ✅, engine ✅, lobby-web ❌ (Docker context), cc-web ❌ (Flutter SDK) |
| **Step 2**: Compose Up | 🟡 3 서비스 기동 | bo healthy, redis healthy, engine running (no healthcheck) |
| **Step 3**: verify_ecosystem.py 실행 | ✅ 실행 완료 | exit 1, 2/5 PASS |
| **Step 4**: 자가 치유 1회 | ✅ 사용 | cc-web `web/` scaffold (team1 template 복제) — Missing index.html 해소되었으나 다음 컴파일 에러로 재차단 |
| **Step 5**: Teardown | ✅ Done | `docker compose down -v` (network/volume 모두 제거) |

## 환경 상태 (수집 시점 2026-04-27 19:53–20:13 KST)

### Docker Daemon

```
Docker version 29.3.1, build c2be9cc
Docker Compose version v5.1.1
Docker Desktop GUI: PID 624, 30308, 45700, 53104, 57028, 63664 (running)

docker desktop status:
  Status              starting     (≥10분 유지)
  SessionID           9a1044f1-dda6-41b2-8379-91614ff535fd

docker info: TIMEOUT (>15s, daemon not responding) → 후에 즉시 응답으로 변경
docker version (server): TIMEOUT (>15s)
docker desktop restart: TIMEOUT (>90s, status remained "starting")
docker desktop start: "Docker Desktop is already running" 응답
docker info (재시도, 20:11): "failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified"
```

진단 변화:
- 처음: daemon 호출이 **15초 hang** → 빌드 단계 진입 불가
- 후에: daemon 호출이 **즉시 fail** ("pipe not found") → Linux engine 자체가 미기동

### WSL2

```
wsl --status:
  기본 배포: Ubuntu
  버전: 2
```

WSL2 자체는 정상. Docker Desktop 의 WSL2 backend integration 단계에서 Linux engine 기동 실패 추정.

### Git / Repo

| 항목 | 값 |
|------|------|
| 시작 브랜치 | `work/team3/20260427-lifecycle-domain` |
| 작업 브랜치 | `work/conductor/e2e-ecosystem-validation` (origin/main `c1551eb` 기반) |
| 외부 간섭 | 다른 세션 (team3) 의 branch switch + reset 으로 작업 트리 untracked 파일 손실 → 재생성 |
| 미커밋 변경 | `tools/verify_ecosystem.py` (재생성), `docs/4. Operations/ECOSYSTEM_E2E_HANDOFF.md` (재생성) |

## 작성된 산출물

### `tools/verify_ecosystem.py`

stdlib only (urllib + socket + base64) Python 3.x 스크립트. pip install 불필요.

**검증 대상 (`docker-compose.yml` SSOT 기준)**:

| Service | Kind | Endpoint | 출처 |
|---------|------|----------|------|
| bo (team2) | HTTP | `http://localhost:8000/health` | `team2-backend/src/main.py:89` |
| engine (team3) | HTTP | `http://localhost:8080/engine/health` | `team3-engine/.../harness/server.dart:168` (B-331) |
| lobby-web (team1) | HTTP | `http://localhost:3000/healthz` | `docker-compose.yml:137` (compose healthcheck SSOT) |
| cc-web (team4) | HTTP | `http://localhost:3001/healthz` | `docker-compose.yml:176` |
| bo-ws-lobby | WebSocket | `ws://localhost:8000/ws/lobby` (HTTP/1.1 101 Upgrade) | `team2-backend/src/main.py:173` |

**핵심 동작**:
- 각 check 별 timeout 5s, 재시도 default 3회 (interval 2s).
- HTTP 는 200 OK + body excerpt (200 byte) 캡처.
- WebSocket 은 raw RFC 6455 handshake — `Sec-WebSocket-Key` 생성 후 `HTTP/1.1 101 Switching Protocols` 응답 첫 줄로 판정. 추가 프레임 처리 없음 (smoke 만 검증).
- `--json` 플래그로 CI/agent-friendly 구조화 출력.
- Exit 0 = 전부 PASS, Exit 1 = 1개라도 FAIL.

**정상 boot 시 사용법**:

```bash
docker compose --profile web up -d
sleep 15
python tools/verify_ecosystem.py            # 사람용 표 출력
python tools/verify_ecosystem.py --json     # CI/agent 용 JSON
docker compose --profile web down -v        # teardown
```

## Run #2 실제 출력 (2026-04-27 22:32 KST)

### docker ps (실측)

```
NAMES        STATUS                    PORTS
ebs-bo       Up 49 seconds (healthy)   0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp
ebs-redis    Up 59 seconds (healthy)   0.0.0.0:6380->6379/tcp, [::]:6380->6379/tcp
ebs-engine   Up 59 seconds             0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

(lobby-web, cc-web 은 build 실패로 미기동)

### verify_ecosystem.py stdout (실측)

```
==============================================================================
EBS Multi-Service Docker E2E Smoke Validation
  HTTP checks: 4  |  WS checks: 1  |  retries: 3
==============================================================================
service      kind  status  elapsed_ms  result  detail
-----------  ----  ------  ----------  ------  ---------------------------------------
bo           http  200     63.0        PASS    OK
engine       http  200     15.0        PASS    OK
lobby-web    http  500     15.0        FAIL    HTTP 500: Internal Server Error
cc-web       http  -       4094.0      FAIL    URLError: WinError 10061 connection refused
bo-ws-lobby  ws    403     16.0        FAIL    unexpected: HTTP/1.1 403 Forbidden

  [bo]          body: {"status":"ok","db":"connected"}
  [engine]      body: {"status":"ok","version":"0.1.0","uptime_seconds":71,"sessions_active":0,
                       "timestamp":"2026-04-27T13:32:01.700465Z"}
  [lobby-web]   body: <!DOCTYPE html><html>...next-hide-fouc...  ← Next.js 응답 (외부 node.exe 점유)
  [bo-ws-lobby] body: HTTP/1.1 403 Forbidden

GATEKEEPER FAIL — 3/5 services unhealthy.
exit code: 1
```

## 발견된 Type B/D Gap 4개 (Run #2 → 후속 backlog)

### Gap 1 — lobby-web Docker build context 경계 위반 (Type B)

```
Step: lobby-web build
Error: COPY ../shared/ebs_common /shared/ebs_common
       failed to compute cache key: "/shared/ebs_common": not found
```

**원인**: Dockerfile 이 `../shared/ebs_common` 을 COPY 하지만 build context 는 `team1-frontend/` 로 한정 — Docker 는 context 외부 파일을 COPY 할 수 없음.

**해결 후보**:
- (a) compose `additional_contexts: shared: ./shared` + Dockerfile `COPY --from=shared ebs_common /shared/ebs_common` (BuildKit, docker compose v2.17+)
- (b) build context 를 repo root 로 변경 + dockerfile path 조정
- (c) `team1-frontend/` 안에 `shared/ebs_common` symlink (Windows symlink 권한 이슈)

### Gap 2 — cc-web Flutter SDK 버전 미스매치 (Type B)

```
Step: cc-web build (자가 치유 후 재시도)
Error: The method 'withValues' isn't defined for the class 'Color'.
       The method 'withValues' isn't defined for the class 'Color'.
       No named parameter with the name 'initialValue'.
       Compilation failed.
```

**원인**: `Color.withValues()` 는 Flutter 3.27+ API (2024-12 출시). Dockerfile 은 `ghcr.io/cirruslabs/flutter:3.22.0` 핀.

**team1 vs team4 비교**: 둘 다 3.22.0 핀이지만 team1 은 해당 API 미사용 → team1 빌드 진행 (단, Gap 1 으로 별도 차단).

**해결 후보**:
- (a) `team4-cc/docker/cc-web/Dockerfile` `FROM ghcr.io/cirruslabs/flutter:3.27.0` 으로 bump (team1 도 동시 검증)
- (b) team4 에서 `Color.withValues` 사용처를 `Color.withOpacity` 로 다운그레이드

### Gap 3 — bo /ws/lobby 인증 (Type D — 검증 스크립트 vs BO 정책 미정렬)

```
service      kind  status  result  detail
bo-ws-lobby  ws    403     FAIL    HTTP/1.1 403 Forbidden
```

**원인**: BO `/ws/lobby` 는 인증된 WebSocket 만 허용. verify_ecosystem.py 는 미인증 raw 핸드셰이크 → 403.

**의의**: 정상 동작 (보안 OK). 단 smoke 검증으로는 부적절.

**해결 후보**:
- (a) verify_ecosystem.py 에 인증 헤더 / dev token 주입 옵션 추가
- (b) BO 에 인증 불필요한 WS health probe endpoint 추가 (예: `/ws/health` echo)
- (c) verify_ecosystem.py 에서 WS check 를 "403 expected = PASS" 로 처리 (단, 다른 거부 이유와 구분 어려움)

### Gap 4 — 호스트 포트 :3000 외부 점유 (Operational, Type D)

```
Process: node.exe (PID 62240) — Next.js dev server
Port: :3000 (LISTEN)
Result: lobby-web 가 빌드되어도 docker compose up 시 port conflict 로 실패할 위치
```

**해결 후보**:
- (a) 운영 절차: 본 검증 시작 전 `:3000` 점유 자동 검사 + 사용자 확인 후 stop (Mode A 준수: 임의 kill 금지)
- (b) docker-compose.yml 에 `EBS_LOBBY_HOST_PORT=${EBS_LOBBY_HOST_PORT:-3000}` 주입 + 충돌 시 다른 포트로 fallback

## Real Execution 원칙 준수 — 회피한 가짜 출력

다음은 Run #1 (BLOCKED) 시점에 거부했던 항목 — Run #2 에서 일부는 진실로 대체되었음:

| 항목 | Run #1 처리 | Run #2 처리 |
|------|------------|------------|
| `docker ps` healthy 출력 | ❌ 거부 (미기동) | ✅ 실측 3/5 (bo, redis, engine) |
| `verify_ecosystem.py` stdout 5/5 PASS | ❌ 거부 (미실행) | ✅ 실측 2/5 PASS — 정직하게 FAIL 보고 |
| "Complete automated E2E validation" commit message | ❌ 정정 (거짓) | ❌ 여전히 정정 (Run #2 도 PARTIAL FAIL) |
| 5개 서비스 healthy 보고 | ❌ 거부 | ❌ 여전히 거부 (실제 2/5) |

## 재시도 절차 (사용자 액션 필요)

### Option A — Docker Desktop 수동 회복 (권장)

1. **Docker Desktop GUI 종료**
   - 트레이 아이콘 우클릭 → Quit Docker Desktop
   - 또는 작업 관리자에서 "Docker Desktop" 프로세스 그룹 모두 종료
2. **WSL 정리** (선택, Linux engine pipe missing 시 종종 필요):
   ```powershell
   wsl --shutdown
   ```
   ⚠️ 다른 WSL2 세션 영향. 다른 팀 세션 (team1/2/3/4) 활성 시 사전 협의.
3. **Docker Desktop 재시작**
   - 시작 메뉴에서 Docker Desktop 실행
   - 트레이 아이콘이 "Docker Desktop is running" 으로 안정될 때까지 대기 (~60s)
4. **검증 재실행**:
   ```bash
   cd C:/claude/ebs
   git checkout work/conductor/e2e-ecosystem-validation
   docker compose --profile web build
   docker compose --profile web up -d
   sleep 30  # healthcheck 안정 대기
   docker ps
   python tools/verify_ecosystem.py
   ```
5. 결과를 본 문서 v1.2 로 업데이트 + Run #2 섹션 추가.

### Option B — Conductor 세션 재시작 후 자동 재실행

회복 후 `/team` 워크플로우 재시작 시 본 문서를 conductor 세션이 읽고 Run #2 자동 실행 가능.

## 결정 트리 (Conductor → 사용자 에스컬레이션 근거)

```
Docker daemon 응답 없음 (≥10분, 그 후 pipe missing 진단)
  ├─ Process kill 으로 강제 회복?
  │   └─ ❌ 차단: 프로젝트 CLAUDE.md `Process kill prohibited`
  ├─ wsl --shutdown 으로 회복?
  │   └─ ⚠️ Mode A 한계: 다른 팀 세션 영향 가능, 사용자 명시 필요
  ├─ docker desktop restart?
  │   └─ ✅ 시도함 → timeout (90s 초과, 미회복)
  ├─ docker desktop start?
  │   └─ ✅ 시도함 → "already running" 응답하지만 pipe 여전히 missing
  ├─ 더 긴 시간 polling 대기?
  │   └─ ❌ 사용자 turn 시간 낭비 + 회복 보장 없음
  └─ 정직한 handoff + 사용자 에스컬레이션 ← 선택
       └─ Real Execution & No Hallucination 원칙 준수
       └─ 재시도 가능한 산출물 (script + branch) 보존
```

## 외부 세션 간섭 사건 기록 (2026-04-27 ~20:08 KST)

작업 중 다른 세션 (team3) 이 동일 working tree 에서 brand switch + reset 을 수행:

```
git reflog (요약):
  6ec95cd HEAD@{0}: checkout: moving from work/conductor/e2e-ecosystem-validation to main
  c1551eb HEAD@{1}: reset: moving to HEAD
  c1551eb HEAD@{2}: checkout: moving from main to work/conductor/e2e-ecosystem-validation
  6ec95cd HEAD@{3}: checkout: moving from work/team3/20260427-triggers-domain to main
  edd7756 HEAD@{4}: commit: chore(active-work): add claim #17 [team3]
```

영향: 본 세션이 작성한 untracked 파일 (`tools/verify_ecosystem.py`, `ECOSYSTEM_E2E_HANDOFF.md`) 이 손실됨. 재생성 후 즉시 commit 으로 보호.

후속 backlog 후보:
- B-NNN: `tools/branch_guard.py` 강화 — 다른 세션의 working tree reset 차단 (active-edits registry 와 연동)
- B-NNN: 본 사건을 `docs/4. Operations/Multi_Session_Workflow.md` §"외부 세션 간섭 방지" 절에 사례로 등재

## 후속 backlog (Conductor)

### Run #2 발견에 의한 신규 backlog (P0)

- [ ] **SG-XXX-1** [team1] lobby-web Docker build context — `additional_contexts: shared: ./shared` 패턴으로 Dockerfile 수정 + verify Run #3 통과
- [ ] **SG-XXX-2** [team4] cc-web Flutter SDK bump (3.22.0 → 3.27+) 또는 `Color.withValues` 다운그레이드. team1 도 동시 SDK 갱신 검증
- [ ] **SG-XXX-3** [team2 + conductor] BO `/ws/lobby` 미인증 health probe endpoint (또는 verify_ecosystem.py 에 dev-token 주입)
- [ ] **SG-XXX-4** [conductor] `tools/verify_ecosystem.py` 시작 시 호스트 포트 :3000/:3001 점유 자동 검사 + 안내

### 기존 (P1)

- [ ] B-NNN: Docker Desktop "starting" hang 진단 자동화 (WSL2 distro health probe + restart-with-backoff)
- [ ] B-NNN: verify_ecosystem.py 를 `tools/team_merge.py` Phase 7 후 자동 실행하는 hook 추가 (Docker_Runtime.md §protocol)
- [ ] B-NNN: ECOSYSTEM_E2E_HANDOFF.md Run #N 누적 패턴 정형화 (성공/실패 이력 SSOT)
- [ ] B-NNN: `tools/branch_guard.py` 강화 — 다른 세션의 working tree reset 차단 (active-edits registry 와 연동)

## 참조

| 문서 | 경로 |
|------|------|
| Multi-Service Docker SSOT | `docs/4. Operations/Docker_Runtime.md` |
| SG-022 폐기 cascade 결정 | memory `project_multi_service_docker_2026_04_27` |
| 거버넌스 (Mode A 한계) | `docs/2. Development/2.5 Shared/team-policy.json` v7.1 `mode_a_limits` |
| Compose 정의 | `docker-compose.yml` (5 services + ebs-net) |
| 검증 스크립트 | `tools/verify_ecosystem.py` (본 PR) |
