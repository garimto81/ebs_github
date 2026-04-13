# EBS Back Office API

EBS tournament management backend built with Python FastAPI. Provides RESTful API for series, events, flights, tables, seats, players, staff, configurations, and real-time WebSocket updates.

> **Docker-only 개발 환경**: 로컬 pip install 불필요. `docker compose up`으로 실행.

## Quick Start (Docker)

```bash
# 프로젝트 루트 (/c/claude/) 에서 실행
docker compose up              # BO + Lobby 동시 시작 (hot-reload)
docker compose run --rm bo-seed   # 시드 데이터 투입
```

- BO API: http://localhost:8000
- Swagger UI: http://localhost:8000/docs
- Lobby: http://localhost:5173

## 개발 워크플로우

```bash
docker compose up              # 서비스 시작 (소스 bind mount → 코드 수정 즉시 반영)
docker compose run --rm bo-test   # 테스트 실행
docker compose run --rm bo-seed   # 시드 데이터 재투입
docker compose logs -f bo         # BO 로그 실시간
docker compose restart bo         # BO 재시작
```

소스 코드 수정 시 uvicorn `--reload`가 자동으로 서버를 재시작합니다.

## Authentication

POST `/api/v1/auth/login` with `{"email": "admin@ebs.local", "password": "admin1234!"}` to obtain a JWT access token. Include `Authorization: Bearer <token>` in subsequent requests.

## Tests

```bash
docker compose run --rm bo-test           # 전체 테스트
docker compose run --rm bo-test pytest tests/routers/ -v   # 라우터만
```

199 tests covering all 68 endpoints, services, models, and WebSocket.

## Production

```bash
docker compose --profile prod up -d    # 프로덕션 모드 (workers=2, no reload)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `sqlite:///./data/ebs.db` | Database connection string |
| `JWT_SECRET` | (required in prod) | Secret key for JWT signing |
| `JWT_ACCESS_EXPIRE_MINUTES` | `15` | Access token TTL |
| `JWT_REFRESH_EXPIRE_DAYS` | `7` | Refresh token TTL |
| `CORS_ORIGINS` | `http://localhost:5173` | Allowed CORS origins |
| `BO_HOST` | `0.0.0.0` | Server bind host |
| `BO_PORT` | `8000` | Server bind port |
| `LOG_LEVEL` | `info` | Logging level |
