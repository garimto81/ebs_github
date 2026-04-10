# IMPL-09 Build & Deployment — 빌드 타겟, Docker, 환경 변수

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 앱별 빌드 명령, Docker 구성, 환경 변수, 배포 절차 |
| 2026-04-09 | Docker 서버 기본 설계 | BO+Lobby Docker 컨테이너 통합, docker-compose 전면 재설계 |

---

## 개요

이 문서는 EBS의 **빌드 및 배포 전략**을 정의한다. **BO + Lobby는 Docker 컨테이너로 통합 실행**하며, CC와 Overlay는 Flutter 데스크톱 빌드, Engine은 Dart 패키지를 사용한다.

> 참조: IMPL-01 기술 스택, IMPL-02 프로젝트 구조, PRD-EBS_Foundation Ch.10 5-Phase 로드맵

---

## 1. 빌드 타겟 요약

| 앱 | 빌드 도구 | 타겟 OS | 산출물 |
|----|---------|---------|--------|
| **CC** | `flutter build` | Windows / macOS / Linux | 실행 파일 (.exe / .app / binary) |
| **Overlay** | `flutter build` | Windows (1차) | 실행 파일 (.exe) |
| **BO** | Docker | Linux (컨테이너) | Docker 이미지 |
| **Engine** | `dart compile` | 크로스 플랫폼 | Dart 패키지 + Simulator CLI |
| **Lobby** | Docker (Next.js) | Linux (컨테이너) | Docker 이미지 |

---

## 2. Command Center (CC) — Flutter 빌드

### 2.1 빌드 명령

| 타겟 | 명령 | 산출물 경로 |
|------|------|-----------|
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

### 2.2 빌드 설정

| 항목 | 값 | 비고 |
|------|:--:|------|
| Flutter 채널 | stable | beta/dev 사용 금지 |
| 최소 Windows 버전 | Windows 10 (1809+) | Flutter Desktop 요구사항 |
| 앱 이름 | EBS Command Center | 윈도우 타이틀바 |
| 앱 아이콘 | `assets/icons/cc_icon.ico` | 커스텀 아이콘 |
| 서명 | 코드 서명 (Phase 2+) | Phase 1은 미서명 |

### 2.3 릴리스 체크리스트

| 단계 | 명령/확인 |
|------|----------|
| 1. 의존성 확인 | `flutter pub get` |
| 2. 분석 | `flutter analyze` (warning 0) |
| 3. 테스트 | `flutter test` (전체 통과) |
| 4. 빌드 | `flutter build windows --release` |
| 5. 크기 확인 | 빌드 산출물 < 100MB 확인 |
| 6. 스모크 테스트 | 빌드된 .exe 실행 → 로그인 → 테이블 선택 |

---

## 3. Overlay — Flutter 빌드

### 3.1 빌드 명령

| 타겟 | 명령 | 비고 |
|------|------|------|
| Windows | `flutter build windows --release` | Phase 1 1차 타겟 |

### 3.2 특수 설정

| 항목 | 값 | 비고 |
|------|:--:|------|
| 창 투명도 | 활성화 | 크로마키 합성을 위한 투명 배경 |
| 항상 위 | 선택 옵션 | OBS/vMix 캡처 시 |
| 해상도 | 1920x1080 (기본) / 3840x2160 (4K) | 런타임 설정 가능 |
| Rive 에셋 | `assets/rive/*.riv` | 빌드에 포함 |

---

## 4. Back Office (BO) — Docker 빌드

### 4.1 Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# 시스템 의존성
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드
COPY src/ ./src/
COPY alembic/ ./alembic/
COPY alembic.ini .

# DB 마이그레이션 실행
RUN alembic upgrade head

# 포트
EXPOSE 8000

# 실행
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 4.2 Docker Compose (서버 통합 구성)

```yaml
version: "3.8"

services:
  # ── Back Office API ──
  bo:
    build:
      context: ./ebs_bo
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=sqlite:///data/ebs.db
      - JWT_SECRET=${JWT_SECRET:-dev-secret-change-me}
      - RFID_MODE=mock
      - LOG_LEVEL=DEBUG
      - CORS_ORIGINS=["http://localhost:3000","http://lobby:3000"]
    volumes:
      - bo-data:/app/data
      - bo-logs:/app/logs
      - skin-assets:/app/skins
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  # ── Lobby 웹 앱 ──
  lobby:
    build:
      context: ./ebs_lobby
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_BO_URL=http://bo:8000
      - NEXT_PUBLIC_WS_URL=ws://bo:8000/ws
    depends_on:
      bo:
        condition: service_healthy
    restart: unless-stopped

volumes:
  bo-data:
    driver: local
  bo-logs:
    driver: local
  skin-assets:
    driver: local
```

### 4.3 Phase별 배포

| Phase | 배포 방식 | DB | 비고 |
|:-----:|---------|:--:|------|
| 1 | `docker compose up` (BO + Lobby) | SQLite | 기본 실행 방식 |
| 2 | Docker + Nginx Reverse Proxy | SQLite | HTTPS, 정적 캐시 |
| 3+ | Docker + PostgreSQL 컨테이너 추가 | PostgreSQL | 수평 확장 대비 |

---

## 5. Game Engine — Dart 패키지 + Simulator

### 5.1 패키지 빌드

Engine은 CC/Overlay에 패키지로 import되므로 별도 빌드 산출물은 없다. 다만 **Interactive Simulator**를 CLI로 빌드한다.

| 타겟 | 명령 | 산출물 |
|------|------|--------|
| AOT 컴파일 | `dart compile exe bin/simulator.dart -o simulator` | 실행 파일 |
| JIT 실행 | `dart run bin/simulator.dart` | 직접 실행 (개발용) |

### 5.2 Interactive Simulator

Simulator는 터미널에서 게임을 시뮬레이션하는 CLI 도구다.

| 기능 | 설명 |
|------|------|
| 게임 선택 | 22종 게임 중 선택 |
| 수동 이벤트 입력 | 카드, 액션을 텍스트로 입력 |
| YAML 시나리오 재생 | 시나리오 파일 로드 → 자동 실행 |
| 상태 덤프 | 현재 GameState를 JSON으로 출력 |

### 5.3 Docker (Simulator 서버 모드)

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/simulator.dart -o bin/simulator

FROM debian:bookworm-slim
COPY --from=build /app/bin/simulator /app/simulator
EXPOSE 8080
CMD ["/app/simulator", "--server", "--port", "8080"]
```

---

## 6. Lobby — Docker 빌드

### 6.1 Dockerfile

```dockerfile
FROM node:22-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
EXPOSE 3000
CMD ["npm", "start"]
```

### 6.2 빌드 명령

| 명령 | 용도 |
|------|------|
| `docker compose build lobby` | Docker 이미지 빌드 |
| `docker compose up lobby` | Docker 컨테이너 실행 |
| `npm run dev` | 로컬 개발 (Hot Reload, Docker 외부) |

### 6.3 환경 변수

| 변수 | Docker 기본값 | 설명 |
|------|-------------|------|
| `NEXT_PUBLIC_BO_URL` | `http://bo:8000` | BO API (컨테이너 내부 네트워크) |
| `NEXT_PUBLIC_WS_URL` | `ws://bo:8000/ws` | WebSocket (컨테이너 내부) |

> 로컬 개발 시 (`npm run dev`): `http://localhost:8000`, `ws://localhost:8000/ws` 사용

---

## 7. 환경 변수 전체 목록

### 7.1 BO 환경 변수

| 변수 | 기본값 | 필수 | 설명 |
|------|--------|:----:|------|
| `DATABASE_URL` | `sqlite:///ebs.db` | O | DB 연결 문자열 |
| `JWT_SECRET` | — | O | JWT 서명 키 (최소 32자) |
| `JWT_ALGORITHM` | `HS256` | X | JWT 알고리즘 |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | X | Access Token 만료 (분) |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | X | Refresh Token 만료 (일) |
| `RFID_MODE` | `mock` | X | 기본 RFID 모드 |
| `LOG_LEVEL` | `INFO` | X | 로그 레벨 |
| `WSOP_LIVE_API_URL` | — | X | WSOP LIVE API 엔드포인트 |
| `WSOP_LIVE_API_KEY` | — | X | WSOP LIVE API 키 |
| `CORS_ORIGINS` | `["http://localhost:3000"]` | X | CORS 허용 오리진 |

### 7.2 CC 환경 변수 (커맨드라인 인자)

| 인자 | 환경 변수 | 기본값 | 설명 |
|------|---------|--------|------|
| `--bo-url` | `BO_URL` | `http://localhost:8000` | BO 서버 URL |
| `--rfid-mode` | `RFID_MODE` | BO Config에서 로드 | RFID 모드 |
| `--table-id` | — | 없음 | 초기 테이블 ID |
| `--log-level` | `LOG_LEVEL` | `WARNING` | 로그 레벨 |

### 7.3 Lobby 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `NEXT_PUBLIC_BO_URL` | `http://localhost:8000` | BO API URL (클라이언트 노출) |
| `NEXT_PUBLIC_WS_URL` | `ws://localhost:8000` | BO WebSocket URL |

---

## 8. 배포 절차

### 8.1 Phase 1 — Docker 배포

```
1. Docker 서버 시작 (BO + Lobby 통합)
   $ cd ebs
   $ docker compose up -d
   # BO: http://localhost:8000
   # Lobby: http://localhost:3000

2. CC 실행 (Flutter 데스크톱)
   $ ./ebs_cc.exe --bo-url=http://{server-ip}:8000

3. Overlay 실행 (Flutter 데스크톱)
   $ ./ebs_overlay.exe --bo-url=http://{server-ip}:8000
```

> **디버깅 시**: Docker 없이 개별 실행 가능 — `uvicorn src.main:app --reload` (BO), `npm run dev` (Lobby)

### 8.2 네트워크 구성 (방송 현장)

```
┌──────────────────────────────────────────────┐
│  방송 네트워크 (유선 LAN)                     │
│                                              │
│  BO 서버 (192.168.1.10:8000)                 │
│      │                                       │
│      ├── Lobby (192.168.1.10:3000)           │
│      │                                       │
│      ├── CC #1 (192.168.1.101) ── RFID #1   │
│      │     └── Overlay #1                    │
│      │                                       │
│      ├── CC #2 (192.168.1.102) ── RFID #2   │
│      │     └── Overlay #2                    │
│      │                                       │
│      └── CC #N ...                           │
│                                              │
│  vMix / OBS (192.168.1.200)                  │
│      └── NDI로 Overlay 캡처                  │
└──────────────────────────────────────────────┘
```

### 8.3 헬스 체크

| 엔드포인트 | 방법 | 성공 기준 |
|-----------|------|----------|
| `GET /health` | HTTP 200 | BO 서버 정상 |
| `GET /health/db` | HTTP 200 + DB ping | DB 연결 정상 |
| WebSocket 연결 | Ping/Pong | 30초 이내 응답 |

---

## 9. 백업 전략

### 9.1 DB 백업

| Phase | 방식 | 주기 | 보존 |
|:-----:|------|:----:|:----:|
| 1-2 | SQLite 파일 복사 | 방송 시작 전 + 종료 후 | 30일 |
| 3+ | PostgreSQL pg_dump | 1시간 간격 | 90일 |

### 9.2 방송 현장 백업 절차

```
방송 시작 전:
  1. SQLite DB 파일 복사 → backup/{date}_pre.db
  2. Rive 에셋 + Config 백업

방송 종료 후:
  1. SQLite DB 파일 복사 → backup/{date}_post.db
  2. 로그 파일 보관
  3. 핸드 리플레이 JSON Export
```
