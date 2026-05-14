---
title: Multi-Session Docker Handoff (SG-022 deprecation cascade)
owner: conductor
tier: operations
last-updated: 2026-04-27
status: active
supersedes: SG-022 single-binary-desktop intent
confluence-page-id: 3818455454
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455454/EBS+Multi-Session+Docker+Handoff+SG-022+deprecation+cascade
---

# Multi-Session Docker Handoff

> 2026-04-27 SG-022 (단일 Desktop 바이너리) 공식 폐기. **Multi-Service Docker 아키텍처**가 EBS 배포 SSOT.

## Edit History

| 날짜 | 변경 | 결정 |
|------|------|------|
| 2026-04-27 | v1.0 신규 | SG-022 폐기 cascade. lobby-web 복원 + cc-web multi-stage 전환 + ebs-net 단일 네트워크 |

## 핵심 원칙

> **"Lobby(team1)와 CC(team4)는 단일 앱이 아니며, 각각 독립된 Flutter 프로젝트로 존재한다. 다만 완전 독립은 아니며, Docker 기반의 격리된 환경에서 기동되어 동일한 EBS 에코시스템 (`ebs-net`) 내에서 네트워크로 상호 작용한다."**

- **세션 독립성** — team1, team4 는 각자 Dockerfile / nginx.conf / 빌드 파이프라인 / 라이프사이클 보유
- **에코시스템 통합** — `docker-compose` 레벨에서 `ebs-net` bridge 네트워크 + service-name DNS + 환경 변수 (LOBBY_URL / CC_URL / BO_URL / ENGINE_URL) 로 협력
- **개발자 디버깅 분리** — Flutter 네이티브 (`flutter run -d windows`) 는 정규 배포가 아닌 개발자 도구로만 유지

## 서비스 토폴로지

```
                ┌─────────────────────────── ebs-net (bridge) ─────────────────────────────┐
                │                                                                            │
                │   ┌──────────┐    ┌─────────┐    ┌──────────┐    ┌───────────┐    ┌─────┐ │
   사용자 ───▶  │   │ lobby-web│    │  cc-web │    │    bo    │    │   engine  │    │redis│ │
   (브라우저)   │   │  team1   │◀──▶│  team4  │◀──▶│  team2   │◀──▶│   team3   │◀──▶│     │ │
                │   │ :3000    │    │ :3001   │    │  :8000   │    │   :8080   │    │:6379│ │
                │   └─────┬────┘    └────┬────┘    └─────┬────┘    └─────┬─────┘    └──┬──┘ │
                │         │              │               │               │             │    │
                └─────────┼──────────────┼───────────────┼───────────────┼─────────────┼────┘
                          │              │               │               │             │
   호스트 매핑:        :3000          :3001           :8000           :8080         :6380
                     (profile web) (profile web)
```

## 포트 맵 (정본 테이블)

| 서비스 | 컨테이너 포트 | 호스트 포트 | 팀 | profile | 빌드 방식 |
|--------|:-------------:|:-----------:|:---:|:-------:|----------|
| `bo` | 8000 | 8000 | team2 | (default) | `team2-backend/Dockerfile` |
| `redis` | 6379 | 6380 | — | (default) | `redis:7-alpine` |
| `engine` | 8080 | 8080 | team3 | (default) | `team3-engine/ebs_game_engine/Dockerfile` |
| `lobby-web` | 3000 | 3000 | team1 | `web` | `team1-frontend/docker/lobby-web/Dockerfile` (multi-stage) |
| `cc-web` | 3001 | 3001 | team4 | `web` | `team4-cc/docker/cc-web/Dockerfile` (multi-stage) |

## 환경 변수 매핑

`docker-compose.yml` 이 각 서비스에 다음을 주입한다 (override 가능, default 는 컨테이너 내 service-name DNS):

| 변수 | 의미 | default (컨테이너 내) | LAN 배포 예시 |
|------|------|----------------------|--------------|
| `BO_URL` | Backend REST/WS | `http://bo:8000` | `http://192.168.1.100:8000` |
| `ENGINE_URL` | Game Engine harness | `http://engine:8080` | `http://192.168.1.100:8080` |
| `LOBBY_URL` | Lobby Web | `http://lobby-web:3000` | `http://192.168.1.100:3000` |
| `CC_URL` | Command Center Web | `http://cc-web:3001` | `http://192.168.1.100:3001` |
| `EBS_EXTERNAL_HOST` | bo 의 launch-cc 응답 호스트 | `localhost` | `192.168.1.100` |

## 빌드 & 기동

### 정규 LAN 배포 (모든 Web 서비스 포함)

```bash
EBS_EXTERNAL_HOST=192.168.1.100 \
  docker compose --profile web up -d --build
```

기동 후 사용자 접속:
- Lobby: `http://192.168.1.100:3000/`
- CC:    `http://192.168.1.100:3001/`

### 부분 빌드

```bash
# Lobby 만 재빌드
docker compose --profile web build --no-cache lobby-web && \
  docker compose --profile web up -d lobby-web

# CC 만 재빌드
docker compose --profile web build --no-cache cc-web && \
  docker compose --profile web up -d cc-web
```

### 헬스체크 검증

```bash
curl -fsS http://localhost:3000/healthz   # → "ok"
curl -fsS http://localhost:3001/healthz   # → "ok"
curl -fsS http://localhost:8000/health    # bo
docker ps --filter "name=^ebs-" --format "table {{.Names}}\t{{.Status}}"
```

모든 컨테이너가 60초 이내 healthy 로 전환되어야 정상.

## Dockerfile 비교 (team1 ↔ team4)

| 측면 | `team1-frontend/docker/lobby-web/Dockerfile` | `team4-cc/docker/cc-web/Dockerfile` |
|------|----------------------------------------------|--------------------------------------|
| Build context | `./team1-frontend` (Flutter root = context) | `./team4-cc` (Flutter root = `src/` 하위) |
| pubspec 위치 | `pubspec.yaml` (context root) | `src/pubspec.yaml` |
| 코드 복사 | `COPY . .` | `COPY src/ ./` |
| Web renderer | `--web-renderer=html` | `--web-renderer=canvaskit` (Rive 애니메이션) |
| Obfuscation | `--obfuscate --split-debug-info` | (생략 — Demo Mode 우선) |
| 노출 포트 | 3000 | 3001 |
| nginx healthz | `/healthz` (port 3000) | `/healthz` (port 3001) |
| Cache 자산 | js/css/woff2/이미지 | + `*.riv` (Rive) |
| 비-root 실행 | `USER nginx` | `USER nginx` (동일) |
| 최종 이미지 | nginx:1.27-alpine ≈ 28 MB | nginx:1.27-alpine ≈ 28 MB |

> 의도적 divergence: CC 는 Rive 런타임 자산 (`.riv`) 캐시 정책 추가, canvaskit 렌더러 (애니메이션 품질 우선). Lobby 는 html 렌더러 (대시보드 위주, 텍스트 SEO 친화).

## Multi-Session 시나리오

### 시나리오 A — 운영자 (정규 배포)

브라우저 두 탭으로 독립 접근:
- 탭 1: `http://lan-ip:3000/` — Lobby (테이블 관리, 운영 모니터)
- 탭 2: `http://lan-ip:3001/` — CC (테이블별 액션 입력)

세션 간 통신은 BO WebSocket (`/ws/lobby`, `/ws/cc`) 으로 동기화.

### 시나리오 B — 개발자 (네이티브 디버깅)

```bash
# Lobby 핫리로드
cd team1-frontend && flutter run -d chrome

# CC 네이티브
cd team4-cc/src && flutter run -d windows \
  --dart-define=BO_URL=http://localhost:8000 \
  --dart-define=ENGINE_URL=http://localhost:8080
```

이때 BO/Engine 은 `docker compose up -d bo redis engine` 으로 백엔드만 띄움.

### 시나리오 C — 멀티 팀 병렬

각 팀이 sibling worktree (`C:/claude/ebs-team{N}-work/`) 에서 독립 작업.
변경 사항은 해당 팀 컨테이너만 재빌드 (`docker compose build --no-cache <service>`) 해 빠르게 검증.

## SG-022 폐기 사유

| 항목 | SG-022 (단일 Desktop) | Multi-Service Docker (현 SSOT) |
|------|------------------------|--------------------------------|
| 빌드 단위 | 1 (단일 .exe) | 5 (bo, redis, engine, lobby-web, cc-web) |
| 팀 라이프사이클 | 통합 (충돌 빈발) | 독립 (Dockerfile 분리) |
| LAN 배포 | 호스트당 .exe 설치 | 1 호스트 docker compose, N 호스트 브라우저 |
| 운영자 시나리오 | Lobby + CC 동일 화면 | Lobby (운영 대시보드) ↔ CC (액션 입력) 분리 워크플로우 |
| 의존성 관리 | Flutter SDK + Windows 빌드 도구 (호스트 마다) | Docker 1개 |
| 핫픽스 | 전체 .exe 재배포 | 영향받은 서비스만 재빌드 |
| 결정 | 2026-04-22 임시 채택 (Type C 기획 모순) | 2026-04-27 사용자 명시 폐기 → 본 문서 SSOT |

상세 결정 기록: `docs/4. Operations/Conductor_Backlog/SG-022-deprecation.md`

## 관련 자산

| 경로 | 역할 |
|------|------|
| `docker-compose.yml` | Multi-Service orchestration SSOT |
| `team1-frontend/docker/lobby-web/{Dockerfile,nginx.conf}` | team1 빌드 자산 |
| `team1-frontend/docker/lobby-web/compose.snippet.yaml` | 단독 검토용 참조 |
| `team4-cc/docker/cc-web/{Dockerfile,nginx.conf}` | team4 빌드 자산 (2026-04-27 신규) |
| `team4-cc/docker/cc-web/compose.snippet.yaml` | 단독 검토용 참조 |
| `team1-frontend/CLAUDE.md` §"배포 형태" | team1 세션 진입자용 가이드 |
| `team4-cc/CLAUDE.md` §"배포 형태" | team4 세션 진입자용 가이드 |
| `docs/4. Operations/Docker_Runtime.md` | 컨테이너 운영 체크리스트 (좀비 스캔 / unhealthy 진단) |

## 금지

- `docker-compose.yml` 의 `ebs-net` 네트워크 제거 또는 `bridge` → `host` 전환 (격리 깨짐)
- 새 Web 서비스 추가 시 `profiles: ["web"]` 누락 (default up 시 무차별 기동 방지)
- service-name 대신 `localhost` 또는 `127.0.0.1` 을 컨테이너 간 URL 로 hardcode
- SG-022 부활 시도 ("Lobby + CC 단일 .exe 통합") — 사용자 명시 결정 필수
