---
title: Network Deployment Guide
owner: conductor
tier: internal
last-updated: 2026-04-17
---

# Network Deployment Guide

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-17 | 신규 작성 | Docker Compose 통합 + CC 호스트 실행 LAN 배포 |
| 2026-04-17 | v2.0 전면 개정 | 3종 배포 시나리오, 환경 변수 카탈로그, TLS/VPN, 진단 체크리스트 추가 |

---

## 개요

EBS는 4개 서비스(BO, Engine, Redis, CC)로 구성된다. 모든 서비스는 동일 네트워크 또는 VPN을 통해 연결되며, 배포 환경에 따라 설정이 달라진다.

---

## 서비스 포트 테이블

| 서비스 | 포트 | 프로토콜 | 설명 |
|--------|:----:|:--------:|------|
| Back Office (BO) | 8000 | HTTP + WS | REST API + WebSocket (`/ws/lobby`, `/ws/cc`) |
| Game Engine | 8080 | HTTP | 순수 Dart 엔진 harness |
| Redis | 6379 | TCP | Idempotency + Circuit Breaker (BO 내부) |
| Lobby | — | Desktop app (Flutter) | BO에 HTTP/WS 연결 |
| Command Center | — | Desktop app (Flutter) | BO + Engine에 연결 |

> Redis는 BO 내부 의존성이며 외부 노출 불필요.

---

## 배포 시나리오 3종

### A. 단일 머신 (개발)

```
  ┌────────────────── localhost ──────────────────┐
  │                                                │
  │  ┌────────┐  ┌────────┐  ┌────────────────┐  │
  │  │ Redis  │  │ Engine │  │      BO        │  │
  │  │ :6379  │  │ :8080  │  │ :8000 REST+WS  │  │
  │  └────────┘  └────────┘  └────────────────┘  │
  │                                                │
  │  ┌────────┐  ┌────────────────┐               │
  │  │ Lobby  │  │ CC (Flutter)   │               │
  │  │ :9000  │  │ Desktop        │               │
  │  └────────┘  └────────────────┘               │
  └────────────────────────────────────────────────┘
```

모든 서비스가 `localhost`에서 실행. 기본 설정 그대로 사용.

```bash
docker compose up -d          # BO + Engine + Redis
cd team1-frontend && pnpm dev # Lobby :9000
cd team4-cc/src && flutter run -d windows --dart-define=DEMO_MODE=true
```

### B. LAN (현장 방송)

```
  ┌──────── Server (192.168.1.100) ────────┐
  │                                         │
  │  ┌────────┐ ┌────────┐ ┌────────────┐ │
  │  │ Redis  │ │ Engine │ │     BO     │ │
  │  │ :6379  │ │ :8080  │ │ :8000      │ │
  │  └────────┘ └────────┘ └────────────┘ │
  └─────────────────────────────────────────┘
           ↑          ↑          ↑
           │    LAN (192.168.1.x/24)
      ┌────┴──────────┴──────────┘
      │
  ┌───┴───────────┐  ┌─────────────────┐
  │ CC (Flutter)  │  │ Lobby (Browser) │
  │ 192.168.1.101 │  │ 192.168.1.102   │
  └───────────────┘  └─────────────────┘
```

서버에서 Docker Compose 실행, CC/Lobby는 별도 머신에서 서버 IP로 연결.

```bash
EBS_EXTERNAL_HOST=192.168.1.100 docker compose --profile lan up -d
```

CC 원격 연결:

```bash
flutter run -d windows -- \
  --table_id=1 \
  --ws_url=ws://192.168.1.100:8000/ws/cc \
  --bo_base_url=http://192.168.1.100:8000 \
  --engine_url=http://192.168.1.100:8080
```

방화벽에서 **8000, 8080** 포트 인바운드 허용 필수.

### C. 멀티 지역 (원격)

```
  ┌─── Site A (서울) ───┐     VPN      ┌─── Site B (Vegas) ──┐
  │                      │   Tunnel    │                      │
  │  BO :8000            │◄──────────►│  CC (Flutter)        │
  │  Engine :8080        │             │  Lobby               │
  │  Redis :6379         │             │                      │
  │  nginx (TLS) :443    │             │                      │
  └──────────────────────┘             └──────────────────────┘
```

VPN 터널을 통해 원격지 CC/Lobby가 서버에 연결. TLS는 nginx reverse proxy로 제공.

---

## 환경 변수 카탈로그

| 변수명 | 컴포넌트 | 기본값 | 설명 |
|--------|----------|--------|------|
| `EBS_BO_HOST` | BO | `0.0.0.0` | BO 바인드 주소 |
| `EBS_BO_PORT` | BO | `8000` | BO 리슨 포트 |
| `EBS_ENGINE_HOST` | Engine | `0.0.0.0` | Engine 바인드 주소 |
| `EBS_ENGINE_PORT` | Engine | `8080` | Engine 리슨 포트 |
| `EBS_EXTERNAL_HOST` | BO | `localhost` | WS URL 응답에 포함되는 외부 호스트명 |
| `CORS_ORIGINS` | BO | `["*"]` | CORS 허용 Origin 목록 (JSON 배열) |
| `DATABASE_URL` | BO | `sqlite:///./ebs.db` | DB 연결 문자열 |
| `REDIS_URL` | BO | `redis://redis:6379/0` | Redis 연결 URL |
| `JWT_SECRET` | BO | `dev-secret-change-me` | JWT 서명 키 (프로덕션 반드시 변경) |
| `AUTH_PROFILE` | BO | `dev` | 인증 프로파일 (`dev` / `lan` / `prod`) |
| `LOG_LEVEL` | 전체 | `INFO` | 로그 레벨 (`DEBUG` / `INFO` / `WARNING` / `ERROR`) |

---

## 컴포넌트별 설정 방법

### Team1 Lobby (Flutter Desktop)

`--dart-define` CLI 인자 또는 `lib/config/env.dart` 환경 상수로 설정:

```
flutter run --dart-define=API_BASE_URL=http://{host}:8000/api/v1 \
            --dart-define=WS_BASE_URL=ws://{host}:8000
```

### Team2 BO (FastAPI)

`.env` 파일 또는 시스템 환경변수. Docker Compose `environment:` 섹션에서 오버라이드.

### Team3 Engine (Dart)

Docker port mapping으로 외부 포트 변경:

```yaml
ports:
  - "${EBS_ENGINE_PORT:-8080}:8080"
```

### Team4 CC (Flutter)

CLI 인자로 전달:

```bash
flutter run -d windows -- \
  --bo_base_url=http://{host}:8000 \
  --ws_url=ws://{host}:8000/ws/cc \
  --engine_url=http://{host}:8080
```

`--dart-define`으로 빌드 시 고정:

```bash
flutter build windows --dart-define=BO_URL=http://{host}:8000
```

---

## CORS 정책

| 환경 | `CORS_ORIGINS` 값 | 비고 |
|------|-------------------|------|
| dev | `["*"]` | 개발 편의, 모든 Origin 허용 |
| lan | `["http://192.168.*"]` | LAN 대역만 허용 |
| prod | `["https://ebs.example.com"]` | 명시적 Origin 목록만 |

BO의 `CORS_ORIGINS` 환경변수에 JSON 배열 형식으로 설정.

---

## TLS / VPN 가이드라인

| 환경 | TLS | 비고 |
|------|-----|------|
| dev (localhost) | 불필요 | 로컬 개발 |
| LAN (내부망) | 불필요 | 폐쇄 네트워크, 물리적 보안 |
| WAN (원격) | **필수** | nginx reverse proxy + Let's Encrypt 또는 VPN 터널 |

- **JWT는 항상 HTTPS 권장** — 평문 전송 시 토큰 탈취 위험
- LAN에서도 민감 데이터 전송 시 TLS 고려
- VPN: WireGuard 또는 OpenVPN으로 사이트 간 터널 구성

nginx reverse proxy 예시:

```nginx
server {
    listen 443 ssl;
    ssl_certificate /etc/ssl/ebs.crt;
    ssl_certificate_key /etc/ssl/ebs.key;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## Docker Compose 프로필

```bash
# 개발 (기본)
docker compose up -d

# LAN 배포
EBS_EXTERNAL_HOST=192.168.1.100 docker compose --profile lan up -d

# 프로덕션
docker compose --profile prod up -d
```

---

## 진단 체크리스트

- [ ] BO health: `curl http://{host}:8000/health`
- [ ] Engine health: `curl http://{host}:8080/health`
- [ ] WS 연결: `wscat -c ws://{host}:8000/ws/lobby?token=JWT`
- [ ] CORS: 브라우저 DevTools Console에서 Origin 에러 확인
- [ ] Redis: `redis-cli -h {host} ping` → `PONG`
- [ ] 방화벽: `Test-NetConnection {host} -Port 8000` (Windows PowerShell)
- [ ] Docker 상태: `docker compose ps` — 모든 서비스 `Up`

---

## 알려진 제한사항

| 항목 | 상태 | 비고 |
|------|------|------|
| CC `boApiClientProvider` localhost 하드코딩 | CR 필요 | CLI 인자로 우회 가능 |
| Engine 포트 8080 고정 | Docker port mapping 우회 | 내부 포트 변경 불가 |
| Flutter Web에서 CLI 인자 미지원 | `--dart-define` 사용 | URL 쿼리 파라미터 구현 예정 |

---

## CC 웹 배포 (Flutter Web)

CC는 기본적으로 Flutter 데스크톱 앱이지만, **Flutter Web 빌드**로 브라우저 접속이 가능하다.

### 제약 사항

| 기능 | 데스크톱 | 웹 | 비고 |
|------|:--------:|:---:|------|
| 게임 진행 | O | O | |
| Demo Mode | O | O | |
| WebSocket | O | O | |
| RFID 하드웨어 | O | X | 플랫폼 채널 미지원 |
| NDI 출력 | O | X | 네이티브 플러그인 미지원 |

### 빌드 + 서빙

```bash
cd team4-cc/src
flutter build web --release --dart-define=DEMO_MODE=true

cd C:/claude/ebs
docker compose up -d cc-web
# 접속: http://LAN_IP:3100
```

---

## Phase 2: mDNS 서비스 디스커버리

현재는 LAN IP를 수동 지정. Phase 2에서 mDNS 도입 시:

| 서비스 | mDNS 호스트명 | 용도 |
|--------|-------------|------|
| BO | `ebs-bo.local` | REST + WS |
| Engine | `ebs-engine.local` | Game Harness |
