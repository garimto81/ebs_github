# 통합 테스트

> Conductor 소유. 팀 간 API 계약을 HTTP/WebSocket 호출로 검증.

## 규칙

- **소스 임포트 금지** — 다른 팀 폴더의 소스를 직접 import하지 않음
- **HTTP/WebSocket only** — 각 팀의 서비스 엔드포인트를 호출
- 테스트 시나리오는 `.http` 형식 (REST Client 호환)
- 계약 문서 위치: `../contracts/api/`
- 이 폴더는 통합 테스트 전용 Conductor 세션 영역입니다.

## 서비스 엔드포인트

| 서비스 | 단일 인스턴스 (compose) | 클러스터 (cluster 인스턴스) | 팀 |
|--------|------------------------|-----------------------------|-----|
| Backend (BO) | http://localhost:8000 | http://localhost:18001 | Team 2 |
| Engine Harness | http://localhost:8080 | http://localhost:18080 | Team 3 |
| WebSocket (Lobby) | ws://localhost:8000/ws/lobby | ws://localhost:18001/ws/lobby | Team 2 |
| WebSocket (CC) | ws://localhost:8000/ws/cc | ws://localhost:18001/ws/cc | Team 2 |

> 포트 매핑은 `team2-backend/docker-compose.yml` (단일) 또는 `team2-backend/docker-compose.cluster.yml` (멀티 인스턴스, M5 Quickstart_Local_Cluster) 참조.

---

## JWT 발급 가이드 (Cycle 2 #236)

`_env.http` 의 `@admin_token` / `@operator_token` / `@viewer_token` 변수는 외부 환경 (`.env` 파일) 에서 주입된다. 다음 절차로 토큰을 발급한다.

### 1. dev/integration admin 계정

BO 컨테이너 기동 시 `src/app/database.py:_seed_admin()` 가 자동으로 다음 admin 계정을 시드한다 (`AUTH_PROFILE=dev` 일 때만 — `live` 환경에서는 skip).

| email | password | 용도 |
|-------|----------|------|
| `admin@ebs.local` | `admin123` | 기존 dev 도구 (backward compat) |
| `admin@ebs.test` | `test-password-1234` | **integration-tests 본 시나리오 표준** |

> 수동 재시드 (예: password 변경 후): `cd team2-backend && python -m seeds.admin --init-db` 또는 `EBS_SEED_FORCE=1` 환경변수로 컨테이너 entrypoint 재실행.

### 2. JWT 발급 (curl)

```bash
# 단일 인스턴스 (compose, 포트 8000)
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@ebs.test","password":"test-password-1234"}' \
  | python -c "import json,sys;print(json.load(sys.stdin)['access_token'])"

# 클러스터 인스턴스 (포트 18001) — Cycle 2 KPI
curl -s -X POST http://localhost:18001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@ebs.test","password":"test-password-1234"}'
```

성공 응답 (200 OK):

```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 3600,
  "expires_at": "2026-05-11T12:34:56Z",
  "auth_profile": "dev",
  "refresh_expires_in": 86400
}
```

### 3. `.env` 파일로 시나리오에서 사용

`_env.http` 가 참조하는 `.env` 파일 (`integration-tests/.env`, **gitignore 대상**) 을 다음과 같이 채운다.

```dotenv
# integration-tests/.env (절대 commit 금지)
ADMIN_JWT=eyJhbGc...
OPERATOR_JWT=eyJhbGc...
VIEWER_JWT=eyJhbGc...
```

VSCode REST Client / httpyac 가 `{{$dotenv ADMIN_JWT}}` 를 자동 치환한다.

### 4. 자동화 헬퍼 (선택)

토큰 수동 복사가 번거로우면 다음 스크립트로 `.env` 일괄 갱신:

```bash
# integration-tests/.env 갱신 (단일 인스턴스 기준)
BASE_URL="${BASE_URL:-http://localhost:8000}"
ADMIN_JWT=$(curl -s -X POST $BASE_URL/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@ebs.test","password":"test-password-1234"}' \
  | python -c "import json,sys;print(json.load(sys.stdin)['access_token'])")
echo "ADMIN_JWT=$ADMIN_JWT" > integration-tests/.env
echo "OPERATOR_JWT=$ADMIN_JWT" >> integration-tests/.env   # 운영자 계정 별도 시드 후 교체
echo "VIEWER_JWT=$ADMIN_JWT"   >> integration-tests/.env
```

### 5. 검증 KPI (Cycle 2 #236)

다음 명령이 200 OK 를 반환해야 한다 (BO healthy + auth/login 동작 + admin@ebs.test seed 정합 동시 검증):

```bash
curl -i -X POST http://localhost:18001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@ebs.test","password":"test-password-1234"}'
# → HTTP/1.1 200 OK
# → access_token, refresh_token, auth_profile=dev 응답
```

401 응답 시 확인 순서:
1. BO 컨테이너 healthy: `docker ps | grep bo`
2. seed 실행 여부: `docker exec ebs-bo python -m seeds.admin` (재시드, idempotent)
3. AUTH_PROFILE: `docker exec ebs-bo printenv AUTH_PROFILE` → `dev` 여야 함 (`live` 시 자동 seed skip)
