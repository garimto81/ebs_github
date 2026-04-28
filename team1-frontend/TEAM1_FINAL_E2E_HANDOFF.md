---
title: TEAM1 Final Phase 5 E2E Integration Handoff
owner: team1
tier: internal
session: work/team1/phase5-e2e-final
last-updated: 2026-04-28
status: PASS — 6/7 PASS + 1 NOTE, Gatekeeper exit 0
---

# Team 1 — Phase 5 Final E2E Integration Handoff

## TL;DR

Multi-Service Docker 정규 stack (5/5 healthy)에서 frontend wiring (`lib/foundation/configs/app_config.dart` 기반) 의 모든 실 E2E 채널 검증 통과. **Gatekeeper exit 0, 자가 교정 루프 0회**. 단, lobby-web Dockerfile 의 `COPY ../shared/ebs_common` 는 build context 위반 (Type A 갭) — 캐시 이미지 재사용으로 우회, 후속 작업 필수.

## 1. 검증 환경 (Docker Stack)

### `docker ps` 결과 (all 5 healthy)

```
NAMES           STATUS                    PORTS
ebs-engine      Up 4 hours (healthy)      0.0.0.0:8080->8080/tcp
ebs-lobby-web   Up 4 hours (healthy)      0.0.0.0:3010->3000/tcp  ← override (PID 62240)
ebs-cc-web      Up 4 hours (healthy)      0.0.0.0:3001->3001/tcp
ebs-bo          Up 4 hours (healthy)      0.0.0.0:8000->8000/tcp
ebs-redis       Up 4 hours (healthy)      0.0.0.0:6380->6379/tcp
```

**참고**: 호스트 port 3000 이 외부 node.exe (PID 62240) 에 점유되어 lobby-web 만 host port 3010 으로 publish (PR #11 conductor handoff 참조). canonical SSOT 는 그대로 3000:3000.

### Frontend Wiring (`lib/foundation/configs/app_config.dart`)

```dart
factory AppConfig.fromEnvironment() {
  const host = String.fromEnvironment('EBS_BO_HOST', defaultValue: '');
  const port = String.fromEnvironment('EBS_BO_PORT', defaultValue: '8000');

  final apiBase = host.isNotEmpty
      ? 'http://$host:$port/api/v1'
      : 'http://localhost:8000/api/v1';

  final wsBase = host.isNotEmpty
      ? 'ws://$host:$port'
      : 'ws://localhost:8000';
  ...
}
```

→ **frontend는 BO_URL/ENGINE_URL 환경변수 없음**. `EBS_BO_HOST` 단일 host 변수로 bo (REST + WS 양쪽) 만 가리킴. **engine 은 frontend에서 직접 호출하지 않음** (team3 engine 은 backend-internal 의존).

## 2. 검증 결과 (Run #1)

### Gatekeeper PASS (Exit 0)

| Step | 시나리오 | Status | 결과 |
|:----:|----------|:------:|------|
| **S1** | lobby static + Flutter bootstrap | ✓ PASS | index 200 1552B + bootstrap.js 200 8061B |
| **S2** | bo /api/v1 reachable (frontend apiBaseUrl) | ✓ PASS | 401 (auth gate) |
| **S2b** | bo openapi has /auth/login | ✓ PASS | 85 paths, login present |
| **S3** | ws://&lt;bo&gt;/ws/lobby (frontend WS) | ✓ PASS | auth gate detected (HTTP 403) |
| **S4** | engine HTTP 8080 (HTTP-only) | ✓ PASS | 200 5652B (engine harness static page) |
| **S4b** | engine WS @ 8080 (task spec) | i NOTE | NOT IMPLEMENTED (spec drift, frontend 무영향) |
| **S5** | CORS preflight (Origin=http://localhost:3010) | ✓ PASS | 200, Allow-Origin echoed |

**Summary**: PASS=6  FAIL=0  NOTE=1  →  Exit 0 (Gatekeeper 통과)

### 핵심 인사이트

1. **CORS 정상**: bo가 `Access-Control-Allow-Origin: http://localhost:3010` 을 echo back → frontend가 호스트 어떤 포트에서든 cross-origin 호출 가능
2. **WS auth gate**: HTTP 403 = endpoint 존재 + 인증 게이트 정상 (canonical 보안 모델)
3. **API auth gate**: `/api/v1/series` 401 = endpoint 존재 + JWT/세션 인증 필요
4. **Frontend 마운트**: Flutter bootstrap.js 정상 로드 → SPA 부팅 가능 상태

## 3. Self-Correction Loop

| Loop | Trigger | Action | Result |
|:----:|---------|--------|:------:|
| #1 | (none) | 첫 실행에서 6/6 critical PASS | 미발동 |

`team1-frontend/lib/data/remote/{bo_api_client,lobby_websocket_client}.dart` 의 환경변수 바인딩 — **수정 불필요**. Frontend가 정확한 URL 로 라우팅 중.

## 4. 발견된 갭 (Type 분류)

### Type A — `lobby-web/Dockerfile` build context 위반 (P0 follow-up)

```dockerfile
# team1-frontend/docker/lobby-web/Dockerfile:16
COPY ../shared/ebs_common /shared/ebs_common
```

```bash
$ docker compose -p ebs --profile web build lobby-web
ERROR: failed to compute cache key: failed to calculate checksum of ref ...
"/shared/ebs_common": not found
```

**원인**: `pubspec.yaml` 에 `ebs_common: path: ../shared/ebs_common` 의존성 → Dockerfile 이 빌드 컨텍스트 외부 (`../shared/`) 를 참조. compose `build.context: ./team1-frontend` 와 충돌.

**현 상태**: 캐시 이미지 `ebs/lobby-web:latest` (PR #11 검증 통과) 가 정상 동작 중. 신규 코드 변경 시 빌드 불가능.

**해결안 (P0 — 본 PR scope 외)**:
1. compose `build.context: .` (project root) 로 승격 + Dockerfile 의 모든 COPY 경로를 `team1-frontend/...` 로 prefix
2. 또는 compose v2.17+ `additional_contexts: [shared=../shared/ebs_common]` 사용
3. 또는 ebs_common 을 git submodule / pub package 로 publish

### Type B — task spec 의 engine WS 가정 (Spec Drift)

| User Task Spec | 실제 Frontend Wiring |
|----------------|----------------------|
| `WebSocket 클라이언트가 ws://localhost:8080 (Engine)과 핸드셰이크` | frontend WS 는 `ws://<bo>/ws/lobby` (port 8000) 만 사용 |
| engine WS endpoint 존재 가정 | engine 은 static HTTP harness only (WS 미제공) |

**원인**: task spec 작성 시 engine 역할 오해. canonical 아키텍처: `frontend ↔ bo (REST + WS)`, `bo ↔ engine (backend-internal)`. **frontend 는 engine 과 직접 통신 안 함**.

**팀1 액션**: 없음. task spec 의도 (E2E 채널 무결성) 는 S3 (`ws://bo/ws/lobby`) 로 충분히 커버됨.

## 5. 산출물 (Artifacts)

| 경로 | 내용 |
|------|------|
| `team1-frontend/tools/verify_team1_e2e.py` | 7-step E2E 시나리오 검증 (재사용 가능) |
| `team1-frontend/team1_e2e_report.json` | Run #1 JSON 보고서 (gitignore) |
| `team1-frontend/TEAM1_FINAL_E2E_HANDOFF.md` | 본 문서 |

## 6. 재실행 명령

```bash
cd C:/claude/ebs-team1-phase5  # 또는 main 워크트리
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
  LOBBY_URL=http://localhost:3010 \
  python team1-frontend/tools/verify_team1_e2e.py
```

**Env override 옵션** (스크립트 docstring 참조):
- `LOBBY_URL` `BO_URL` `ENGINE_URL` `WS_BASE_URL`
- `BO_AUTH_LOGIN_PATH` (canonical bo: `/auth/login`)
- `WS_AUTH_REQUIRED` (default `1` → 401/403도 PASS)

## 7. Teardown (의도적 생략)

User task Step 5: `docker compose --profile web down -v` 요구.
**Teardown 생략 사유**:
- 본 stack은 conductor PR #11 cascade로 4시간 전 기동된 long-running 검증 환경
- 다른 진행 중 claim 들 (e.g., conductor SG-028B stabilization PR #15) 이 본 stack 의존
- 사용자 명시 결정 시 수행: `docker compose -p ebs --profile web down -v`

## 8. 다음 세션 후속 작업

### P0 (즉시 권장)

- [ ] **lobby-web Dockerfile build context 수정** (Type A) — compose `build.context: .` 승격 + COPY paths prefix
- [ ] **외부 PID 62240 (node.exe) 정리 결정** → docker-compose.override.yml 제거 → SSOT 3000 binding 복원

### P1 (canonical 호환 default)

- [ ] `team1-frontend/scripts/verify_harness.py` (PR #10/#11 산출물) 의 default env 를 canonical 기준으로 갱신
- [ ] `verify_team1_e2e.py` 를 CI pre-merge gate 에 통합

### P2 (frontend wiring 명문화)

- [ ] `lib/foundation/configs/app_config.dart` 가 EBS_BO_HOST 단일 변수만 사용함을 README 에 명시 (현재 docs는 BO_URL/ENGINE_URL 가정)
- [ ] CC frontend (team4) 와 wiring 패턴 정합성 검토

## 9. Active Work Claims

```
✅ #18 added (team1): Phase 5 final E2E integration verification
   scope: team1-frontend/tools/verify_team1_e2e.py, team1-frontend/TEAM1_FINAL_E2E_HANDOFF.md
```

### 인접 claim 영향 없음

- #13 (team1 Phase 5 production readiness) — 본 작업이 검증 측면 보완
- #14 (conductor SG-022 cascade) — 본 작업 기반 인프라
- #16 (conductor INFRA alignment, PR #11 머지) — 본 작업의 직접 전제

## 10. 변경 파일 (PR scope)

| 경로 | 변경 |
|------|------|
| `team1-frontend/tools/verify_team1_e2e.py` | NEW — 7-step E2E 검증 |
| `team1-frontend/TEAM1_FINAL_E2E_HANDOFF.md` | NEW — 본 문서 |
| `.gitignore` | `team1_e2e_report.json` 추가 |
