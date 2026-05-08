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
| `ebs-redis-1` | `redis:7-alpine` | internal | conductor | (재빌드 불필요, `docker compose pull` 만) |

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

## 5. 레퍼런스

- `docker-compose.yml` — 정규 서비스 정의
- `docs/4. Operations/Network_Deployment.md` — 다중 네트워크 배포 시나리오 (dev/LAN/WAN)
- `docs/2. Development/2.5 Shared/Network_Config.md` — 팀 간 포트/환경변수/CORS 계약
- 사건 기록:
  - 2026-04-22 **1차**: `ebs-lobby-web` 좀비 오판 — 5일간 옛 이미지 서빙 발견 → stop/rm/rmi 수행. **그러나 "Desktop 단일 스택" 기획 문구를 문자 그대로 해석하여 실제 운영 요구 (Docker Web 배포) 를 out-of-scope 로 단정** 한 2차 오류 발생.
  - 2026-04-22 **2차**: 사용자 지적으로 기획 ↔ 운영 괴리 (Type C) 인식. Deployment.md 신설 + Dockerfile/nginx.conf/compose `lobby-web` 서비스 복원 + Flutter Web platform 재활성. 본 문서의 "Desktop only" 선언 철회.
