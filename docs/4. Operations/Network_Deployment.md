---
title: Network Deployment
owner: conductor
tier: internal
last-updated: 2026-04-17
---

# LAN 네트워크 배포 가이드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-17 | 신규 작성 | Docker Compose 통합 + CC 호스트 실행 LAN 배포 |

---

## 개요

EBS 서비스를 동일 네트워크(LAN)에서 실행하여 개발/QA/데모 환경을 구성하는 방법.

## 아키텍처

```
┌─────────────────── Docker Compose ───────────────────┐
│                                                       │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐│
│  │  Redis    │    │  Engine  │    │   BO (Backend)   ││
│  │  :6379   │    │  :8080   │    │   :8000          ││
│  └──────────┘    └──────────┘    │  REST + WebSocket ││
│                                   └──────────────────┘│
│                                                       │
└───────────────────────────────────────────────────────┘
         ↑                ↑                ↑
         │                │                │
    (내부 전용)    LAN_IP:8080      LAN_IP:8000
                          │                │
                   ┌──────┴────────────────┘
                   │
          ┌────────┴────────┐
          │   CC (Flutter)  │  ← 호스트에서 직접 실행
          │   데스크톱 앱    │
          └─────────────────┘
```

## 빠른 시작

### 1. Docker Compose 시작

```bash
cd C:/claude/ebs
docker compose up -d
```

서비스 상태 확인:
```bash
docker compose ps
# bo       → 0.0.0.0:8000
# engine   → 0.0.0.0:8080
# redis    → 0.0.0.0:6379
```

### 2. LAN IP 확인

```bash
# Windows
ipconfig | findstr IPv4
# → 예: 192.168.1.100

# Linux/Mac
hostname -I
```

### 3. CC 실행 (같은 머신)

```bash
cd team4-cc/src
flutter run -d windows --dart-define=DEMO_MODE=true
```

### 4. CC 실행 (다른 머신에서 원격 서비스 연결)

```bash
cd team4-cc/src
flutter run -d windows -- \
  --table_id=1 \
  --token=eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiT3BlcmF0b3IiLCJhc3NpZ25lZF90YWJsZXMiOlsxXX0.fake \
  --cc_instance_id=550e8400-e29b-41d4-a716-446655440000 \
  --ws_url=ws://192.168.1.100:8000/ws/cc \
  --bo_base_url=http://192.168.1.100:8000 \
  --engine_url=http://192.168.1.100:8080
```

---

## 포트 매핑

| 서비스 | 포트 | 프로토콜 | 용도 |
|--------|:----:|:--------:|------|
| BO (Backend) | 8000 | HTTP + WS | REST API + WebSocket |
| Engine | 8080 | HTTP | Game Engine 하니스 |
| Redis | 6379 | TCP | BO 내부 캐시 (외부 접근 불필요) |

방화벽에서 **8000, 8080** 포트를 LAN 내부에서 허용해야 합니다.

---

## 환경변수

### docker-compose.yml

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `JWT_SECRET` | `dev-secret-change-me-in-production` | JWT 서명 키 |
| `EBS_EXTERNAL_HOST` | `localhost` | BO launch-cc 응답의 ws_url 호스트 |
| `CORS_ORIGINS` | `["*"]` | CORS 허용 오리진 |

### CC (Flutter)

| 인자 | 기본값 | 설명 |
|------|--------|------|
| `--bo_base_url` | `http://localhost:8000` | BO REST API |
| `--ws_url` | `ws://localhost:8000/ws/cc` | BO WebSocket |
| `--engine_url` | `http://localhost:8080` | Game Engine |
| `--demo` | (없음) | Demo Mode 활성화 |

### dart-define (flutter run 시)

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `DEMO_MODE` | `false` | Demo Mode 활성화 |

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| CC에서 WS 연결 실패 | BO 미실행 또는 잘못된 IP | `docker compose ps`로 BO 상태 확인, `--ws_url` IP 확인 |
| CORS 에러 | BO CORS 설정에 CC 오리진 미포함 | `CORS_ORIGINS=["*"]` 설정 (개발용) |
| Engine 연결 실패 | Engine 미실행 또는 포트 차단 | `curl http://LAN_IP:8080/` 로 Engine 응답 확인 |
| 방화벽 차단 | Windows Defender 등 | 8000, 8080 포트 인바운드 규칙 추가 |
| Demo 모드에서 NEW HAND 비활성 | TableFSM이 LIVE가 아님 | `--demo` 플래그 또는 `--dart-define=DEMO_MODE=true` 확인 |

---

## CC 웹 배포 (Flutter Web)

CC는 기본적으로 Flutter 데스크톱 앱이지만, **Flutter Web 빌드**로 브라우저 접속이 가능하다. 동일 네트워크의 다른 머신에서 URL만으로 CC에 접근할 수 있는 유일한 방법.

### 제약 사항

| 기능 | 데스크톱 | 웹 | 비고 |
|------|:--------:|:---:|------|
| 게임 진행 (HandFSM, 액션) | O | O | |
| Demo Mode (시나리오) | O | O | |
| WebSocket 연결 | O | O | |
| RFID 하드웨어 | O | X | 플랫폼 채널 미지원 — MockRfid만 |
| NDI 출력 | O | X | 네이티브 플러그인 미지원 |
| 로컬 파일 접근 | O | X | .gfskin 로드 등 |

> **결론**: Demo Mode + 게임 진행 검증에는 Web 빌드로 충분. 프로덕션 운영은 데스크톱 빌드 필수.

### 빌드 + 서빙

```bash
# 1. Web 빌드
cd team4-cc/src
flutter build web --release --dart-define=DEMO_MODE=true

# 2. 결과물 위치
# team4-cc/src/build/web/

# 3. Docker Compose로 Nginx 서빙 (docker-compose.yml cc-web 서비스)
cd C:/claude/ebs
docker compose up -d cc-web

# 4. 접속
# http://LAN_IP:3100
```

### 브라우저 접속 흐름

```
다른 머신 브라우저
  │
  ├─ http://192.168.1.100:3100     → CC Web UI (Nginx)
  │    └─ JS에서 WS 연결 ──────────→ ws://192.168.1.100:8000/ws/cc
  │    └─ JS에서 REST 호출 ─────────→ http://192.168.1.100:8000/api/v1
  │    └─ JS에서 Engine 호출 ───────→ http://192.168.1.100:8080
  │
  └─ Demo Mode 자동 활성화 (DEMO_MODE=true 빌드)
```

### 환경변수 주입 (Web)

Flutter Web에서는 CLI 인자(`--table_id` 등)를 사용할 수 없다. 대신 **`--dart-define`** 으로 빌드 시 주입하거나, URL 쿼리 파라미터로 전달:

| 방법 | 예시 | 용도 |
|------|------|------|
| `--dart-define` | `flutter build web --dart-define=BO_URL=http://192.168.1.100:8000` | 빌드 시 고정 |
| URL 쿼리 | `http://IP:3100/?bo_url=http://192.168.1.100:8000` | 런타임 변경 (구현 필요) |

---

## Phase 2: mDNS 서비스 디스커버리

현재는 LAN IP를 수동 지정합니다. Phase 2에서 mDNS 도입 시:

| 서비스 | mDNS 호스트명 | 용도 |
|--------|-------------|------|
| BO | `ebs-bo.local` | REST + WS |
| Engine | `ebs-engine.local` | Game Harness |

구현 방안:
- Linux: Avahi 데몬 (`avahi-publish-service`)
- Windows: Bonjour SDK
- Docker: `extra_hosts` 또는 Traefik + mDNS 플러그인
