---
title: Deployment
owner: team1
tier: internal
last-updated: 2026-04-22
---

# Team 1 Frontend — 배포 형태 SSOT

## 개요

team1-frontend (Lobby) 는 Flutter multi-platform 프레임워크로 작성되었으며, 같은 소스에서 **Desktop (Windows)** 와 **Web (Docker nginx)** 두 가지 배포를 병행한다. 배포 타겟 선택은 운영 시나리오에 따른다.

## 배포 매트릭스

| 배포 형태 | 운영 시나리오 | 포트 | 접근 방식 | 실행 방법 |
|-----------|---------------|------|-----------|-----------|
| **Desktop (Windows)** | 현장 운영자 PC, 개발자 디버깅 | — | 로컬 실행 | `flutter run -d windows --dart-define=EBS_BO_HOST=<ip>` |
| **Web (Docker nginx)** | 동일 네트워크 LAN 브라우저 접근, 다중 사용자 관찰, 회의실 프로젝터 공유 | 3000 | `http://<lan-ip>:3000/` | `docker compose --profile web up -d lobby-web` |

## 왜 둘 다 필요한가

1. **Desktop** — Flutter 네이티브 성능, 오프라인 사용 가능, 설치형 배포
2. **Web** — 설치 불필요, 동일 LAN 내 여러 운영자/관찰자 동시 접근, 브라우저 DevTools 로 현장 디버깅

EBS 운영 환경은 토너먼트 현장에서 **다중 스태프 동시 관찰** 이 필수이므로 Web 배포를 포기할 수 없다.

## Docker Web 배포 스택

```
사용자 브라우저 (LAN)
    ↓ http://<lan-ip>:3000/
[ebs-lobby-web-1 컨테이너]
    ├─ nginx:alpine
    ├─ /usr/share/nginx/html ← team1-frontend/build/web (Flutter Web build)
    └─ /etc/nginx/conf.d/default.conf ← team1-frontend/nginx.conf
         ├─ / → SPA fallback (index.html)
         ├─ /api/ → proxy to ebs-bo:8000 (compose 내부 네트워크)
         └─ /ws/  → proxy to ebs-bo:8000 (WebSocket upgrade)
```

## 파일 자산

| 파일 | 역할 |
|------|------|
| `team1-frontend/Dockerfile` | Multi-stage: Flutter SDK build → nginx serve |
| `team1-frontend/nginx.conf` | SPA fallback + BO/WS reverse proxy |
| `team1-frontend/web/` | Flutter Web platform scaffold (index.html, manifest, icons) |
| `team1-frontend/build/web/` | `flutter build web --release` 산출물 (gitignored) |
| `docker-compose.yml` `lobby-web` 서비스 | Docker Compose 정의 (profile: web) |

## 빌드 + 기동 절차

```bash
# 1. Flutter Web platform 활성화 (초기 1회)
cd team1-frontend
flutter create . --platforms web

# 2. 소스 변경 시마다
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release

# 3. Docker 이미지 빌드 + 기동
cd ..
docker compose --profile web build lobby-web
docker compose --profile web up -d lobby-web

# 4. healthcheck
docker ps --filter "name=^ebs-lobby-web-1" --format "{{.Status}}"
curl -o /dev/null -w "%{http_code}\n" http://localhost:3000/
```

## 재빌드 트리거

team1 소유 파일 중 다음 변경 시 **반드시 재빌드 + 재배포** (Docker_Runtime.md §2.2):

| 변경 대상 | 재빌드 필요 |
|-----------|-------------|
| `lib/**/*.dart` (소스) | ✓ flutter build web + docker build |
| `pubspec.yaml`, `pubspec.lock` | ✓ flutter build web + docker build |
| `web/index.html`, `web/manifest.json` | ✓ flutter build web + docker build |
| `Dockerfile`, `nginx.conf` | ✓ docker build (코드 빌드 없음) |
| `docker-compose.yml` `lobby-web` 섹션 | ✓ docker compose up -d --force-recreate |
| 기획 문서 (`docs/**`) 만 변경 | ✗ 재빌드 불필요 |

## 환경변수 (Web Backend 연결)

Docker Compose 내부 네트워크에서 nginx → BO 프록시는 서비스명 `bo:8000` 사용. 외부 노출은 nginx `/api/` + `/ws/` 만. 즉 브라우저는 `http://<lan-ip>:3000/api/...` 로 요청하고 nginx 가 내부 `http://bo:8000/api/...` 로 전달.

Flutter 앱 측은 `AppConfig` 에서 **동일 origin 사용** (`window.location.origin`). CORS 불필요.

## 관련 문서

- `docs/4. Operations/Docker_Runtime.md` — 전체 프로젝트 Docker 운영 SSOT (좀비 스캔, 재빌드 프로토콜)
- `docs/4. Operations/Network_Deployment.md` — 다중 네트워크 시나리오
- `docs/2. Development/2.5 Shared/Network_Config.md` — 팀 간 포트/CORS 계약
- `team1-frontend/CLAUDE.md §Role §배포 형태` — 팀 세션 진입 시 필독

## 변경 이력

| 날짜 | 변경 | 사유 |
|------|------|------|
| 2026-04-22 | 최초 작성 — Desktop + Web 병행 배포 명문화 | 2026-04-22 `ebs-lobby-web` 좀비 오판 사건 해소. `2cc13b1` "Desktop 단일 스택" 선언이 Web 배포까지 배제하는 의미로 확대 해석된 기획-운영 괴리 Type C 정정 |
