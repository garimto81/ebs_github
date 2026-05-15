---
title: Deployment
owner: team1
tier: internal
last-updated: 2026-04-22
confluence-page-id: 3833626839
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833626839/Deployment
---

# Team 1 Frontend — 배포 형태 SSOT

## 개요

team1-frontend (Lobby) 의 **실제 사용자 배포 형태는 Docker Web 단독**. 사용자는 브라우저로 `http://<lan-ip>:3000/` 에 접속한다. Flutter Desktop 실행은 **개발자 디버깅 전용**이며 배포 형태가 아니다.

## 배포 매트릭스

| 용도 | 대상 | 방법 | 포트 | 언제 |
|------|------|------|------|------|
| **Docker Web (정규 배포)** | 실제 사용자 (운영자, 관찰자) | `docker compose --profile web up -d lobby-web` → 브라우저 접속 | 3000 | 현장 운영 |
| **Flutter Web 로컬 개발** | 개발자 | `flutter run -d chrome` | 동적 | 핫리로드 디버깅 |
| **Flutter Desktop 로컬 개발** | 개발자 | `flutter run -d windows` | — | Windows 네이티브 동작 확인 (Web 전용 API 없는지 검증 등) |

> **중요**: 실제 사용자가 `flutter run` 을 직접 실행하는 시나리오는 없다. Flutter SDK 설치 + CLI 명령은 개발자 환경이며, 사용자는 브라우저만 사용한다. Windows `.exe` 바이너리 배포 파이프라인도 현재 구축되어 있지 않다.

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

## 왜 Docker Web 인가

1. **설치 불필요** — 사용자는 브라우저만 열면 됨
2. **LAN 다중 접근** — 현장 여러 스태프가 동일 URL 로 동시 관찰
3. **배포 일관성** — nginx + Flutter Web build 만 이미지에 담아 버전 고정
4. **CORS 불필요** — nginx 가 `/api`, `/ws` 를 reverse proxy 로 BO 에 전달 → 브라우저는 동일 origin

## 파일 자산

| 파일 | 역할 |
|------|------|
| `team1-frontend/Dockerfile` | nginx:alpine 기반 — 호스트에서 사전 빌드된 `build/web` 을 COPY |
| `team1-frontend/nginx.conf` | SPA fallback + `/api`, `/ws` reverse proxy to `bo:8000` |
| `team1-frontend/web/` | Flutter Web platform scaffold (index.html, manifest, icons) — 개발자가 `flutter create . --platforms web` 으로 초기 생성 |
| `team1-frontend/build/web/` | `flutter build web --release` 산출물 (gitignored, Docker 빌드 전 반드시 생성) |
| `docker-compose.yml` `lobby-web` 서비스 | Docker Compose 정의 (profile: web, port 3000) |

## 빌드 + 기동 절차 (개발자 작업)

```bash
# 1. Flutter Web platform 활성화 (최초 1회, 이미 완료됨)
cd team1-frontend
flutter create . --platforms web

# 2. 코드 변경 시마다
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --dart-define=USE_MOCK=false

# 3. Docker 이미지 빌드 + 기동
cd ..
docker compose --profile web build --no-cache lobby-web
docker compose --profile web up -d lobby-web

# 4. healthcheck
docker ps --filter "name=^ebs-lobby-web-1" --format "{{.Status}}"
curl -o /dev/null -w "%{http_code}\n" http://localhost:3000/
```

## 개발자 로컬 디버깅 (배포 아님)

### Flutter Web 핫리로드 (브라우저)
```bash
cd team1-frontend
flutter run -d chrome --dart-define=EBS_BO_HOST=<lan-ip>
```
→ 소스 저장 시 브라우저 즉시 반영. UI 개발에 가장 유용.

### Flutter Desktop (Windows native, 선택)
```bash
cd team1-frontend
flutter run -d windows --dart-define=EBS_BO_HOST=<lan-ip>
```
→ Windows-specific 동작 확인용 (Web 에서 지원 안 되는 native API 사용 여부 검증 등). 평소 개발은 `-d chrome` 권장.

**둘 다 배포 방법이 아니다.** 개발 머신에서 Flutter SDK + CLI 로 실행하는 디버깅 모드.

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

## 환경변수 (Backend 연결)

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
| 2026-04-22 | 재정정 — "Desktop 배포" 재분류: 배포 아닌 **개발자 디버깅 모드** 로 축소. 실제 사용자 배포 = Docker Web 단독 | 사용자 지적: "누가 flutter run -d windows 이런식으로 앱을 사용해?" — 실제 사용자에게 Flutter SDK + CLI 를 요구할 수 없음. Desktop native 바이너리 배포 파이프라인도 없음. "Desktop + Web 병행" 표현 오류 시정 |
