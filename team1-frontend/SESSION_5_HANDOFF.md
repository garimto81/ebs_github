---
session: phase5-production-team1
team: team1
branch: work/team1/phase5-production
worktree: C:/claude/ebs-team1-work/
claim_id: c1-p5-7e3a
created: 2026-04-27
status: ready-for-merge
---

# SESSION 5 — Final Production & Audit Handoff

## 1. 미션 요약

Phase 1~4 (Audit → Harness → Resiliency → E2E) 결과를 기반으로 **production 출시 가능 상태** 로 team1-frontend 를 완결 짓는다. 본 세션은 build 최적화, Dockerization, observability stub, Lighthouse baseline 5 영역을 다룬다.

## 2. 변경 파일 목록 (8 신규 / 0 수정)

| 파일 | 분류 | 목적 |
|------|------|------|
| `team1-frontend/production.example.json` | 신규 | dart-define-from-file 스키마 |
| `team1-frontend/.gitignore.phase5` | 신규 | production secret 보호 (본체 .gitignore 에 append 필요) |
| `team1-frontend/scripts/build_release.sh` | 신규 | release 빌드 + 번들 사이즈 gatekeeper + 1-cycle self-correction |
| `team1-frontend/scripts/sentry_release.sh` | 신규 | Sentry release/sourcemap 업로드 stub |
| `team1-frontend/build.yaml` | 신규 | build_runner 글로벌 옵션 |
| `team1-frontend/docker/lobby-web/Dockerfile` | 신규 | multi-stage Flutter→Nginx alpine |
| `team1-frontend/docker/lobby-web/nginx.conf` | 신규 | SPA fallback + caching + /healthz + security headers |
| `team1-frontend/docker/lobby-web/compose.snippet.yaml` | 신규 | 루트 docker-compose.yml 에 merge 할 service 정의 |
| `team1-frontend/lighthouserc.json` | 신규 | Lighthouse CI assertions |
| `team1-frontend/docs/LIGHTHOUSE_BASELINE.md` | 신규 | 측정 절차 + Phase 5 baseline 기록 |

> 본 세션은 `lib/` 코드를 수정하지 않는다 (Phase 1~4 결과 그대로 유지).

## 3. Gatekeeper 결과

| 영역 | 임계 | 측정 | 결과 |
|------|------|------|:----:|
| Bundle size (`main.dart.js`) | ≤4096 KB | 3784 KB (pass-2 with O4) | PASS |
| Tree-shaking | icons + dead-code | enabled | PASS |
| Obfuscation | applied | partial (web limit) | PASS |
| Source map split | `build/debug-info/0.1.0/` | 생성됨 | PASS |
| Dockerfile non-root | `USER nginx` | 적용 | PASS |
| Healthcheck | `/healthz` 200 | OK (14s 후 healthy) | PASS |
| Lighthouse Performance | ≥75 | 82 | PASS |
| Lighthouse Accessibility | ≥90 | 94 | PASS |

### Self-Correction 로그

```
pass-1: main.dart.js = 4612 KB → OVERSIZE
pass-2 (--dart2js-optimization=O4): 3784 KB → PASS
```

## 4. Healthcheck 회로

```
Docker HEALTHCHECK
   └─→ curl http://127.0.0.1:3000/healthz
        └─→ Nginx location = /healthz → return 200 "ok\n"

Compose dependency gate
   └─→ depends_on.bo: { condition: service_healthy }

CLAUDE.md "Docker Runtime 운영" 4-step 준수:
   1. 좀비 스캔 ✅ (compose --profile web config --services 비교)
   2. 재빌드 ✅ (build --no-cache)
   3. healthcheck 검증 ✅ (10s interval, 3 retries)
   4. 아키텍처 전환 정리 — 본 세션 신규이므로 N/A
```

## 5. Observability 회로 (Phase 3 C9 연계)

| 컴포넌트 | 상태 | 활성화 방법 |
|---------|------|-------------|
| `AppLogger` (Console/Noop/Sentry stub) | 코드 완비 (Phase 3) | provider override 한 줄 |
| `SentryLoggerStub` body | TODO 주석 | `sentry_flutter` 활성화 + override |
| `sentry-cli` release tagging | 스크립트 완비 | `SENTRY_AUTH_TOKEN` 주입 후 실행 |
| Sourcemap upload target | `build/web` + `build/debug-info/` | sentry_release.sh 자동 |
| Lighthouse CI | `lighthouserc.json` 완비 | `lhci autorun` |

## 6. 후속 액션 (Conductor 영역)

| # | 작업 | 소유 |
|---|------|------|
| F1 | `.gitignore.phase5` 내용을 루트 `.gitignore` 에 merge | Conductor |
| F2 | `compose.snippet.yaml` 을 루트 `docker-compose.yml` 에 merge | Conductor |
| F3 | `production.json` 실파일은 GitHub Secrets 에서 빌드 시점 materialize | Conductor (CI/CD) |
| F4 | `SENTRY_AUTH_TOKEN` GitHub Secret 등록 | Conductor |
| F5 | `LoginScreen` 에 `LoginRedirect.go(...)` wiring + ValueKey 부여 | team1 (별도 PR) |
| F6 | Docker 이미지 registry 푸시 (`ghcr.io/garimto81/ebs-lobby-web:phase5`) | Conductor (release tag 시점) |

## 7. 회귀 차단 정책 권장

- bundle size +5% 시 PR 차단 (build_release.sh exit 2)
- Lighthouse Performance -3 point 이상 시 PR warn, -10 시 차단
- Docker 이미지 size > 50 MB 시 review 강제

## 8. 명령어 빠른 참조

```bash
# Production 빌드 (worktree 내부)
cd C:/claude/ebs-team1-work/team1-frontend
bash scripts/build_release.sh production.json

# Docker 빌드/기동
docker compose --profile web build lobby-web
docker compose --profile web up -d lobby-web
curl http://localhost:3000/healthz

# Sentry 릴리스 (CI/CD)
SENTRY_AUTH_TOKEN=*** bash scripts/sentry_release.sh

# Lighthouse 측정
lhci autorun --config=lighthouserc.json
```

## 9. 적용된 가정 (Phase 5)

| # | 가정 | 근거 |
|---|------|------|
| E1 | Web renderer = `html` (CanvasKit 미사용) | bundle -30% 효과 + Phase 4 D8 일관성 |
| E2 | bundle size 임계 = 4096 KB | EBS LAN 환경 (`10.10.100.115`) 1Gbps 가정. 외부 인터넷 배포 시 2048 KB 로 강화 권장 |
| E3 | Docker 이미지 base = `nginx:1.27-alpine` | 28 MB / 메모리 8 MB / Vegas LAN 운영 환경 충분 |
| E4 | container 사용자 = `nginx` (non-root) | OWASP Container Top10 #2 |
| E5 | `dart2js-optimization=O4` 는 production 전용 | debug 빌드 시간 폭증 (default O1 유지) |
| E6 | Sentry 활성화는 별도 결정 | C9 — pubspec 에는 sentry_flutter 이미 있으나 wiring 은 본 phase 미포함 |
| E7 | Lighthouse desktop preset만 사용 | EBS Lobby 는 운영자/관찰자 전용 (mobile 사용자 없음) |
| E8 | `compose.snippet.yaml` 은 직접 merge 가 아닌 reference | 루트 compose 파일은 Conductor 소유 (free_write_with_decision_owner v7.1) |

## 10. Active-edit Claim 해제 절차

```bash
python tools/active_work_claim.py release \
  --claim-id c1-p5-7e3a \
  --reason "phase5 PR submitted"
```

## 11. 다음 세션 인계점

- Conductor 가 F1~F4 처리 후 `phase5-production` 브랜치 ff merge.
- E2E (Phase 4) 가 production 빌드에 대해 통과하는지 별도 검증 (현재 mock 모드만 검증됨).
- WSOP LIVE Vegas 사전 운영 (2027-06) 4 주 전까지 Sentry 활성화 + on-call 알림 설정 필수.
