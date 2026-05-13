---
title: P0 Remediation Handoff (port 3000 + Dockerfile context)
owner: conductor
tier: internal
session: work/conductor/fix-p0-context-and-port
last-updated: 2026-04-28
status: PASS — 5/5 healthy on canonical port 3000, E2E 6/6 PASS exit 0
confluence-page-id: 3818685091
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818685091/EBS+P0+Remediation+Handoff+port+3000+Dockerfile+context
---

# P0 Remediation — Port 3000 좀비 + Dockerfile Build Context Promotion

## TL;DR

두 P0 이슈 모두 물리적 해결. **(1)** PID 62240 (node.exe) 종료로 호스트 port 3000 해방. **(2)** lobby-web Dockerfile build context 를 project root 로 승격하여 monorepo `shared/ebs_common` 의존성 정상 resolve. lobby-web 신규 빌드 + canonical port 3000 binding 으로 5/5 healthy stack 기동, E2E 6/6 PASS (exit 0). 자가 교정은 **5단 cascade** (의도된 시나리오 1개 + 발견 갭 4개 추가) 로 진행.

## 1. 좀비 프로세스 종료 (Port 3000 해방)

### 종료 전

```
$ netstat -ano | grep :3000
  TCP    0.0.0.0:3000     0.0.0.0:0    LISTENING    62240
  TCP    [::]:3000        [::]:0       LISTENING    62240

$ Get-Process -Id 62240
Id          : 62240
ProcessName : node
Path        : C:\Program Files\nodejs\node.exe
StartTime   : 2026-04-27 19:43:42  ← 18+ 시간 orphan
```

### 종료 + Gatekeeper 검증

```
$ Stop-Process -Id 62240 -Force
$ Start-Sleep -Seconds 2
$ if (Get-Process -Id 62240 -EA SilentlyContinue) { "STILL ALIVE - GATEKEEPER FAIL" } else { "PID 62240 terminated" }
PID 62240 terminated

$ sleep 3 && netstat -ano | grep :3000
(empty — port 3000 free)

$ curl -s -o /dev/null -w "%{http_code}\n" --connect-timeout 2 http://localhost:3000/
000  ← Connection refused (port 미바인딩 = 정상)
```

**Gatekeeper PASS** — port 3000 완전 해방.

> **Note**: CLAUDE.md "Process kill prohibited" 정책은 일반 보호 규약이지만, 본 task 에서 사용자가 명시적으로 "종료" 권한 부여 (`Step 2 — Stop-Process -Id 62240 -Force`). Instruction Priority 에 따라 사용자 명시 지시가 우선.

## 2. Dockerfile Build Context Promotion (Type A 갭 해소)

### 변경 1: `docker-compose.yml` — lobby-web build context

**Before**:
```yaml
lobby-web:
  build:
    context: ./team1-frontend
    dockerfile: docker/lobby-web/Dockerfile
```

**After**:
```yaml
lobby-web:
  build:
    # 2026-04-28 — Type A 갭 (Monorepo build context promotion).
    # 이전: context=./team1-frontend → COPY ../shared/ebs_common 컨텍스트 위반.
    # 변경: context=. (project root) → ebs_common (path:../shared/ebs_common 의존)
    # 정상 접근 가능. Dockerfile COPY paths 도 team1-frontend/ prefix 됨.
    context: .
    dockerfile: team1-frontend/docker/lobby-web/Dockerfile
```

### 변경 2: `team1-frontend/docker/lobby-web/Dockerfile` COPY paths

**Before**:
```dockerfile
COPY pubspec.yaml pubspec.lock ./
COPY ../shared/ebs_common /shared/ebs_common  # ← context boundary violation
...
COPY . .
COPY docker/lobby-web/nginx.conf /etc/nginx/conf.d/default.conf
```

**After**:
```dockerfile
COPY team1-frontend/pubspec.yaml team1-frontend/pubspec.lock ./
COPY shared/ebs_common /shared/ebs_common
...
COPY team1-frontend/ ./
COPY team1-frontend/docker/lobby-web/nginx.conf /etc/nginx/conf.d/default.conf
```

## 3. 자가 교정 cascade (5-Layer)

빌드 진행 중 **추가 4개 갭** 발견 — 각각 다음 갭을 가린 양파 구조:

| Layer | 갭 | 증상 | 교정 |
|:-----:|------|------|------|
| **L1** | Dockerfile context (Type A) | `COPY ../shared/ebs_common: not found` | compose context: . + Dockerfile prefix |
| **L2** | intl ↔ Flutter SDK pin (왕복) | Flutter 3.22.0: intl 0.19 / stable: intl 0.20.2 — pin 불일치 | Flutter image upgrade (3.22→stable) + pubspec intl ^0.20.2 (원복) |
| **L3** | Dart 3.4 < patrol_finders 요구 >=3.5 | `Because ebs_lobby depends on patrol_finders >=2.1.3 which requires SDK version >=3.5.0` | Flutter base image: `flutter:3.22.0` → `flutter:stable` |
| **L4** | `flutter build web --web-renderer` 폐기 | `Could not find an option named "--web-renderer"` | flag 제거 (build config 로 대체) |
| **L5** | `--obfuscate` web 미지원 | `Could not find an option named "--obfuscate"` | flag 제거 + `mkdir -p build/debug-info` (runtime COPY 호환) |

### 교정 파일 목록

| 파일 | 변경 |
|------|------|
| `docker-compose.yml` | lobby-web `build.context: .` + `dockerfile: team1-frontend/...` |
| `team1-frontend/docker/lobby-web/Dockerfile` | FROM image stable + COPY paths prefix + flutter build flags 정리 + `mkdir -p build/debug-info` |
| `team1-frontend/pubspec.yaml` | intl: ^0.20.2 (확인용 — 원래 값으로 settle. cascade 중 0.19.0 ↔ 0.20.2 왕복) |

## 4. Canonical Stack 기동 + Verification

### `docker ps` (5/5 healthy, lobby-web on canonical 3000)

```
NAMES           STATUS                    PORTS
ebs-lobby-web   Up 19 seconds (healthy)   0.0.0.0:3000->3000/tcp  ← canonical SSOT
ebs-engine      Up 5 hours (healthy)      0.0.0.0:8080->8080/tcp
ebs-cc-web      Up 5 hours (healthy)      0.0.0.0:3001->3001/tcp
ebs-bo          Up 5 hours (healthy)      0.0.0.0:8000->8000/tcp
ebs-redis       Up 5 hours (healthy)      0.0.0.0:6380->6379/tcp
```

**5/5 모두 healthy ✓** + **lobby-web 정규 3000 binding** (override 제거됨).

### E2E Verification (`verify_team1_e2e.py` default env)

```bash
$ MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
    python team1-frontend/tools/verify_team1_e2e.py
```

```
============================================================================
 team1 Phase 5 — Final E2E Integration Verification
 started_at: Tue Apr 28 14:08:44 2026
 lobby=http://localhost:3000  bo=http://localhost:8000  engine=http://localhost:8080  ws=ws://localhost:8000
============================================================================
 [✓] S1   lobby static + Flutter bootstrap               (  11ms)
        index 200 1552B + bootstrap.js 200 9975B          ← 8061B → 9975B (신규 빌드 진본성 증명)
 [✓] S2   bo /api/v1 reachable (frontend apiBaseUrl)     (  17ms)
        401 (auth gate)
 [✓] S2b  bo openapi has /auth/login                     (  22ms)
        85 paths, login present
 [✓] S3   ws://<bo>/ws/lobby (frontend WS)               (  38ms)
        auth gate detected (HTTP 403)
 [✓] S4   engine HTTP 8080 (HTTP-only — Type B note)     (   4ms)
        200 5652B (engine harness static page)
 [i] S4b  engine WS @ 8080 (task spec) — NOT IMPLEMENTED (   0ms)
 [✓] S5   CORS preflight (Origin=http://localhost:3000)  (  26ms)
        200, Allow-Origin='http://localhost:3000'        ← canonical Origin echoed
----------------------------------------------------------------------------
 PASS=6  FAIL=0  NOTE=1
============================================================================
```

**Exit code 0**

> **빌드 진본성**: bootstrap.js byte size 가 8061B → 9975B 변경. 같은 endpoint, 같은 script — 응답 크기 변화 = 신규 build 가 실제로 산출물에 반영되었다는 hash-free 증거.

## 5. SSOT 정렬 결과

| 항목 | Before (PR #16 시점) | After (본 PR) |
|------|----------------------|---------------|
| lobby-web host port | 3010 (override) | **3000 (canonical)** |
| docker-compose.override.yml | 존재 (gitignored) | 삭제됨 |
| lobby-web Dockerfile build | FAIL (`COPY ../shared`) | **PASS** (root context) |
| Image freshness | 10시간 전 캐시 | **방금 빌드** (Flutter stable) |

## 6. 다음 세션 후속 작업

### P0 (해결 완료)
- [x] PID 62240 (node.exe) 종료 → port 3000 해방
- [x] lobby-web Dockerfile build context 승격
- [x] canonical 3000 binding 복원

### P1 (cascade 발견 갭)

- [ ] **Sentry source map upload sidecar 재설계** — `--obfuscate`/`--split-debug-info` web 미지원 → 별도 dart2js source-map upload 스크립트 필요 (`scripts/sentry_release.sh` 보강)
- [ ] **Flutter SDK 버전 pinning policy** — `flutter:stable` 사용은 build reproducibility 약함. `flutter:3.27.x` 같은 explicit version pin 권장
- [ ] **patrol_finders Dart 3.5+ 요구 명문화** — README 에 minimum Dart SDK version 명시
- [ ] **dependabot 또는 renovate 설정** — pubspec ↔ Flutter SDK pin drift 자동 감지

### P2 (workflow 개선)

- [ ] CI 에 docker compose build 단계 통합 → Dockerfile context drift 즉시 감지
- [ ] team1 verify_harness.py / verify_team1_e2e.py 의 default env 를 canonical 기준으로 갱신
- [ ] team_v5_merge.py 가 `ebs-conductor-*` 패턴 worktree 인식 (현재 team1-4 만 매칭)

### P3 (장기)

- [ ] `C:\claude\ebs_v2\` archive 또는 삭제 (별 프로젝트로 잔존 시 혼선)
- [ ] team3 engine `/health` endpoint 추가 검토 (현재 healthcheck 는 `/`)
- [ ] team1 `lib/data/remote/*` 이 `EBS_BO_HOST` 단일 변수만 사용함을 README 명시

## 7. Active Work Claims

```
✅ #18 added (conductor): P0 remediation: kill PID 62240 + lobby-web Dockerfile context promotion
   scope: docker-compose.yml, team1-frontend/docker/lobby-web/Dockerfile, P0_REMEDIATION_HANDOFF.md
```

## 8. 변경 파일 (PR scope)

| 경로 | 변경 |
|------|------|
| `docker-compose.yml` | lobby-web build context: . + dockerfile path |
| `team1-frontend/docker/lobby-web/Dockerfile` | FROM stable + COPY prefix + flag cleanup + `mkdir build/debug-info` |
| `team1-frontend/pubspec.yaml` | (no net change — cascade 중 왕복했으나 ^0.20.2 로 settle) |
| `P0_REMEDIATION_HANDOFF.md` | NEW — 본 문서 |

## 9. Cross-Ownership Notify

본 PR 은 conductor 권한 (claim #18) 으로 team1 소유 파일 (`team1-frontend/docker/lobby-web/Dockerfile`) 직접 수정. team1 decision_owner 는 사후 review 권장:
- Sentry sidecar 재설계 의향 확인
- Flutter SDK pin policy 협의
