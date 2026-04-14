# IMPL-00 Dev Setup — 개발 환경 셋업

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | 3-앱 개발 환경 셋업 가이드 |
| 2026-04-09 | Docker 서버 기본화 | BO+Lobby Docker 기본 실행, 개별 실행은 디버깅 옵션 |

---

## 개요

EBS 3-앱 아키텍처(Lobby, CC, BO)의 개발 환경 셋업 가이드. git clone 후 10분 이내 빌드 가능을 목표로 한다.

## 1. 공통 요구사항

| 도구 | 버전 | 용도 |
|------|------|------|
| Git | 2.40+ | 소스 관리 |
| Node.js | 22 LTS | Lobby 빌드 |
| Flutter SDK | 3.27+ | CC, Overlay 빌드 |
| Dart SDK | 3.6+ (Flutter 내장) | Game Engine |
| Python | 3.12+ | Back Office |
| Docker | 24+ | **서버 실행 (필수)** — BO + Lobby 통합 실행 |

## 2. Lobby (Next.js)

```bash
cd ebs_lobby
npm install
cp .env.example .env.local
npm run dev          # http://localhost:3000
```

| 환경 변수 | 기본값 | 설명 |
|----------|--------|------|
| `NEXT_PUBLIC_BO_URL` | `http://localhost:8000` | Back Office API |
| `NEXT_PUBLIC_WS_URL` | `ws://localhost:8000/ws` | WebSocket |

## 3. Command Center + Overlay (Flutter)

```bash
cd ebs_cc
flutter pub get
flutter run -d windows    # 또는 -d chrome (웹 디버깅)
```

## 4. Back Office + Lobby 서버 (Docker)

**기본 실행 방식**: Docker Compose로 BO + Lobby를 동시에 실행.

```bash
cd ebs
docker compose up -d     # BO(8000) + Lobby(3000) 시작
docker compose logs -f   # 로그 확인
docker compose down      # 종료
```

| 서비스 | URL | 설명 |
|--------|-----|------|
| BO API | http://localhost:8000 | REST + WebSocket |
| BO Docs | http://localhost:8000/docs | Swagger UI |
| Lobby | http://localhost:3000 | 웹 앱 |

### 디버깅 시 개별 실행 (Docker 없이)

```bash
# BO
cd ebs_bo
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn src.main:app --reload    # http://localhost:8000

# Lobby
cd ebs_lobby
npm install
npm run dev                      # http://localhost:3000
```

## 5. Game Engine (Dart 패키지)

```bash
cd ebs_game_engine
dart pub get
dart test
```

## 6. 전체 서버 실행 확인

```bash
docker compose up -d
curl http://localhost:8000/health   # BO 헬스 체크
curl http://localhost:3000          # Lobby 접근 확인
```

## 7. Mock 모드

Phase 1 POC에서는 RFID 하드웨어 없이 Mock 모드로 개발:

| 컴포넌트 | Mock 방법 |
|----------|----------|
| RFID HAL | `MockRfidReader` DI 교체 (IMPL-05 참조) |
| WSOP LIVE API | Mock 서버 또는 seed 데이터 (`team2-backend/seed/README.md` 참조) |

## 참조

| 문서 | 경로 |
|------|------|
| 기술 스택 | `docs/impl/IMPL-01-tech-stack.md` |
| 프로젝트 구조 | `docs/impl/IMPL-02-project-structure.md` |
| DI 패턴 | `docs/impl/IMPL-05-dependency-injection.md` |
| 시드 데이터 | `team2-backend/seed/README.md` |
