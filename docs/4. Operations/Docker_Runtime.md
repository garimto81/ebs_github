---
title: Docker Runtime 운영 지침
owner: conductor
tier: internal
last-updated: 2026-04-27
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
| ~~`ebs-lobby-web-1`~~ **[REMOVED 2026-04-27, SG-022]** | — | — | — | 단일 Desktop 바이너리로 통합. Conductor 가 컨테이너/이미지 destroy 완료. team1 Dockerfile/web 정리는 B-Q3 위임 |
| `ebs-cc-web-1` | `ebs-cc-web` | 3100 | team4 | `team4-cc/src/build/web/**` 갱신 (flutter build web 선행) |
| `ebs-redis-1` | `redis:7-alpine` | internal | conductor | (재빌드 불필요, `docker compose pull` 만) |

**compose 정의 파일**: `docker-compose.yml` (레포 루트)

**~~중요 정정 (2026-04-22)~~** [SUPERSEDED 2026-04-27, SG-022]:
- ~~2026-04-22 정정: `ebs-lobby-web` 을 "정규 Web 배포" 로 분류 + γ 하이브리드 (Web Lobby + Desktop CC) 채택~~
- ~~team1-frontend 정규 배포 = Docker Web 단독~~ → SG-022 로 역전 (단일 Desktop 바이너리)
- ~~Flutter Desktop = 개발자 디버깅 모드~~ → SG-022 로 역전 (Desktop = 정규 배포)

**현재 정책 (2026-04-27, SG-022 결정)**:
- EBS = **단일 Flutter Desktop 바이너리**. Lobby + Command Center + Overlay 모두 단일 바이너리 내부 라우팅.
- Docker `ebs-lobby-web` 컨테이너/이미지 destroy 완료 (2026-04-27 Conductor 처리).
- team1-frontend Web 빌드 자산 (`web/`, `Dockerfile` Web 단계) 정리는 **B-Q3 (team1 위임)**, due 2026-05-04.
- 참조: `Phase_1_Decision_Queue.md`, `BS_Overview §1`, `Spec_Gap_Registry SG-022`, MEMORY `feedback_web_flutter_separation` [SUPERSEDED].

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
