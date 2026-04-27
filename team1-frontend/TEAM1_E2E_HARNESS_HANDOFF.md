---
title: TEAM1 E2E Harness Handoff
owner: team1
tier: internal
session: work/team1/harness-e2e-validation
last-updated: 2026-04-28
status: PASS — 8/8 checks, self-correction loops 0
---

# Team 1 — E2E Harness Validation Handoff

## TL;DR

Multi-Service Docker (SG-022 폐기) 환경에 대해 **headless E2E 검증 8/8 PASS**. 자가 교정 루프 **0회** (실행 환경이 contract를 모두 만족). team1 nginx.conf / production.json 수정 불필요. 단, **`docker-compose.yml` 정의-런타임 비동기**가 발견되어 별도 후속 작업 필요 (Conductor 영역, Claim #14).

## 1. 검증 대상 (Target)

| Service | URL | Container | Owner |
|---------|-----|-----------|-------|
| Lobby Web | `http://localhost:3001/` | `ebs-v2-lobby-web` | team1 |
| Backend (BO) | `http://localhost:8000/` | `ebs-v2-bo` | team2 |
| Engine | `http://localhost:8080/` | `ebs-v2-engine` | team3 |
| WebSocket | `ws://localhost:8000/ws/{lobby,cc}` | `ebs-v2-bo` | team2 |

> **사전 조건**: ebs_v2 stack이 이미 가동되어 있었음 (`C:\claude\ebs_v2\docker-compose.yml`,
> Conductor가 SG-022 폐기 cascade로 deploy 완료). 본 세션은 새로 띄우지 않고
> 기존 deploy를 검증 대상으로 채택 — Cross-Session Scope 준수.

## 2. 검증 결과 (Run #1, 2026-04-28 08:26 UTC)

### 3-Tier Validation 결과

| Tier | Check | Status | Latency | Detail |
|------|-------|:------:|--------:|--------|
| L1 | `lobby_root` | ✓ PASS | 10ms | 200 1183B |
| L1 | `lobby_healthz` | ✓ PASS | 19ms | 200 "ok" |
| L1 | `bo_health` | ✓ PASS | 15ms | 200 52B |
| L1 | `bo_openapi` | ✓ PASS | 16ms | 200 29455B (`/api/v1/auth/login` present) |
| L1 | `engine_health` | ✓ PASS | 14ms | 200 56B |
| L2 | `ws_lobby` | ✓ PASS | 27ms | handshake + 101B initial frame |
| L2 | `ws_cc` | ✓ PASS | 4ms | handshake + 106B initial frame |
| L3 | `lobby_dom_render` | ✓ PASS | 3779ms | title=`EBS Lobby Web`, console_errors=0, network_failures=0 |

**Summary**: PASS=8 FAIL=0 SKIP=0  →  Exit code 0

### Self-Correction Loop

| Loop | Trigger | Action | Result |
|:----:|---------|--------|:------:|
| #1 | (none) | 첫 실행에서 모든 check PASS | 루프 진입 안 함 |

`team1-frontend/docker/lobby-web/nginx.conf`, `production.example.json` 모두 **수정 불필요**.

## 3. 발견된 갭 (Type 분류)

### Type D — docker-compose.yml 정의/런타임 비동기 (Critical)

| 항목 | 정의 (C:\claude\ebs\docker-compose.yml) | 런타임 (`ebs-v2-*`) |
|------|---------------------------------------|---------------------|
| `lobby-web` 서비스 | **REMOVED** (SG-022 시점 코멘트 처리) | **존재** (`ebs-v2-lobby-web`) |
| 포트 | 명시 없음 (정의 자체가 없음) | `3001:80` |
| 네트워크 | 정의 없음 | `ebs_v2_ebs-net` |
| 빌드 컨텍스트 | 정의 없음 | nginx:alpine + 프리빌드 web 정적 자산 |

**원인**: SG-022 (단일 Desktop 바이너리) 결정 시점에 `lobby-web` 서비스를 docker-compose.yml에서 제거. 그 후 SG-022가 폐기되고 Multi-Service Docker (lobby:3000 / cc:3001)가 SSOT로 채택되었으나, **루트 docker-compose.yml에 lobby-web 정의가 복원되지 않음**. 대신 Conductor가 별도 디렉토리 `C:\claude\ebs_v2\`에 새 compose stack을 deploy.

**영향**:
- 신규 개발자가 `cd C:/claude/ebs && docker compose --profile web up -d lobby-web` 실행 시 `service "lobby-web" not defined` 오류
- team1 의 `docker/lobby-web/compose.snippet.yaml` 은 정의되어 있으나 루트로 merge 안 됨
- `docs/4. Operations/Docker_Runtime.md` SSOT와 실제 compose 파일이 불일치

**책임자**: Conductor (Claim #14: SG-022 deprecate + Multi-Service Docker)
**team1 액션**: 없음 (Cross-Session Scope — `docker-compose.yml` 은 conductor 영역). 본 handoff에 명시함으로써 인지 전달.

### Type B — 포트/엔드포인트 spec drift

| 항목 | User Task Spec | 실제 Runtime |
|------|----------------|--------------|
| Lobby 포트 | `localhost:3000` | `localhost:3001` |
| WebSocket | `ws://localhost:8080` | `ws://localhost:8000/ws/{lobby,cc}` |
| Engine WebSocket | (없음, 8080 가정) | engine 은 WebSocket 미제공 (HTTP `/health` 만) |

**원인**: `team1 CLAUDE.md` 에 명시된 SSOT는 "Lobby:3000 / CC:3001" 인데 실제 deploy는 lobby-web → 3001 (CC 자리). 즉 **포트 충돌이 일어났을 때 lobby가 cc 자리로 밀린 상태**일 가능성. CC web 컨테이너는 `cc-web` 이며 `compose.yml` 의 정의로는 `3100:80` 인데 그것도 운영 중 아님 (only ebs-v2-* 가 운영 중).

**책임자**: Conductor (claim #14)
**team1 액션**: verify_harness.py 의 `LOBBY_URL` env override로 양쪽 다 호환 (`LOBBY_URL=http://localhost:3000` 로 future port migration 시 1 var만 변경).

### Type A — Engine "unhealthy" status (Cosmetic)

`docker ps` 가 `ebs-v2-engine` 을 `unhealthy` 로 표시. 그러나 실제 `/health` 는 200 응답 + `POST /api/session` 도 정상 처리 중 (logs 확인). 즉 healthcheck endpoint 정의 문제일 뿐 service 자체는 정상.

**책임자**: team3 (engine compose healthcheck 정의)
**team1 영향**: 없음.

## 4. 산출물 (Artifacts)

| 경로 | 내용 |
|------|------|
| `team1-frontend/scripts/verify_harness.py` | 3-tier E2E 검증 스크립트 (재사용 가능) |
| `team1-frontend/harness_report.json` | Run #1 JSON 보고서 (gitignore 권장) |
| `team1-frontend/TEAM1_E2E_HARNESS_HANDOFF.md` | 본 문서 |

## 5. 재실행 방법 (Reproducibility)

```bash
# 사전 조건: ebs_v2 또는 동등 Multi-Service Docker stack 가동 중
cd C:/claude/ebs-team1-harness  # 또는 main 체크아웃
python team1-frontend/scripts/verify_harness.py

# Env override 예시 (포트 변경 / Playwright 스킵)
LOBBY_URL=http://localhost:3000 \
  BO_URL=http://localhost:8000 \
  WS_BASE_URL=ws://localhost:8000 \
  SKIP_PLAYWRIGHT=1 \
  python team1-frontend/scripts/verify_harness.py
```

**의존성**: `pip install requests websockets playwright` + `python -m playwright install chromium`.

## 6. Teardown (의도적으로 생략)

User task Step 4는 `docker compose --profile web down` 으로 정리 요구. 그러나:

1. 본 세션은 새로 띄우지 않고 **기존 ebs_v2 stack** 을 재사용
2. ebs_v2 stack 은 Conductor 의 long-running deploy
3. teardown 시 Conductor 의 다른 진행 중 작업 (`Run #2 PARTIAL FAIL`, `e2e-ecosystem-validation` 브랜치) 영향

→ **teardown 생략**. Conductor 또는 사용자가 명시적으로 종료 결정 시 수행.

## 7. 다음 세션 인수 (Handoff)

### Conductor 후속 작업 (P0, Claim #14)

- [ ] `C:\claude\ebs\docker-compose.yml` 에 `lobby-web` 서비스 정의 복원 (`team1-frontend/docker/lobby-web/compose.snippet.yaml` merge)
- [ ] `lobby-web` 포트를 SSOT 와 일치시킴 (3000 vs 3001 결정)
- [ ] `cc-web` 활성화 (`docker compose --profile web up -d cc-web`) + healthcheck PASS 확인
- [ ] `ebs_v2` stack vs `ebs` stack 통합 또는 deprecation 계획 수립

### team1 후속 작업 (P1)

- [ ] verify_harness.py 를 CI에 통합 (PR pre-merge gate)
- [ ] Playwright 시나리오 확장: 로그인 흐름, Lobby 드릴다운, Settings 6탭 토글
- [ ] `harness_report.json` 을 `.gitignore` 에 추가

### team3 후속 작업 (P2)

- [ ] engine compose healthcheck 정의를 `/health` 로 명시적 매핑 → unhealthy 표시 제거

## 8. 변경 이력

| 날짜 | 액션 | 결과 |
|------|------|------|
| 2026-04-28 08:26 UTC | Run #1 (요청 후 첫 실행) | PASS=8 FAIL=0, no self-correction needed |

## 부록 A — verify_harness.py stdout (Run #1)

```
======================================================================
 team1 E2E Harness Validation
 started_at: Tue Apr 28 08:26:54 2026
 targets: lobby=http://localhost:3001 bo=http://localhost:8000 engine=http://localhost:8080
          ws_base=ws://localhost:8000
======================================================================
 [✓] L1 l1.lobby_root                  (  10ms) 200 1183B
 [✓] L1 l1.lobby_healthz               (  19ms) 200 3B
 [✓] L1 l1.bo_health                   (  15ms) 200 52B
 [✓] L1 l1.bo_openapi                  (  16ms) 200 29455B
 [✓] L1 l1.engine_health               (  14ms) 200 56B
 [✓] L2 l2.ws_lobby                    (  27ms) handshake OK, first msg 101B
 [✓] L2 l2.ws_cc                       (   4ms) handshake OK, first msg 106B
 [✓] L3 l3.lobby_dom_render            (3779ms) title='EBS Lobby Web', net_failures=0, head_len=500
----------------------------------------------------------------------
 PASS=8  FAIL=0  SKIP=0
======================================================================
 report → C:\claude\ebs-team1-harness\team1-frontend\harness_report.json
```

## 부록 B — Active Work Claim

```
✅ claim #15 added (team1: E2E harness validation (verify_harness.py + Self-correction loop))
   scope:
     - team1-frontend/scripts/verify_harness.py
     - team1-frontend/TEAM1_E2E_HARNESS_HANDOFF.md
     - team1-frontend/docker/lobby-web/nginx.conf       (수정 안 함, 미리 reserve)
     - team1-frontend/production.example.json           (수정 안 함, 미리 reserve)
   force-add 사유: claim #13 (team1 Phase 5 production readiness) 와 보완 관계
                  (동일 team1 세션, scripts/** 와 docker/lobby-web/** 부분 overlap)
```
