# 통합 테스트

> Conductor 소유. 팀 간 API 계약을 HTTP/WebSocket 호출로 검증.

## 규칙

- **소스 임포트 금지** — 다른 팀 폴더의 소스를 직접 import하지 않음
- **HTTP/WebSocket only** — 각 팀의 서비스 엔드포인트를 호출
- 테스트 시나리오는 `.http` 형식 (REST Client 호환)
- 계약 문서 위치: `../contracts/api/`
- 이 폴더는 통합 테스트 전용 Conductor 세션 영역입니다.

## 서비스 엔드포인트

| 서비스 | 포트 | 팀 |
|--------|------|-----|
| Backend (BO) | http://localhost:8000 | Team 2 |
| Engine Harness | http://localhost:8080 | Team 3 |
| WebSocket (Lobby) | ws://localhost:8000/ws/lobby | Team 2 |
| WebSocket (CC) | ws://localhost:8000/ws/cc | Team 2 |

## Fixture (`fixtures/`)

`.gfskin` 더미 파일 6종. 자세히는 [`fixtures/README.md`](./fixtures/README.md).

| 파일 | git 상태 | 비고 |
|------|---------|------|
| `wsop-2026-test.gfskin` | tracked | 정상 ZIP (201) |
| `invalid-colors.gfskin` | tracked | schema 위반 (422) |
| `missing-skin-json.gfskin` | tracked | 구조 결함 (422) |
| `missing-skin-riv.gfskin` | tracked | 구조 결함 (422) |
| `invalid-rive-magic.gfskin` | tracked | Rive magic 위반 (422) |
| `huge-51mb.gfskin` | **gitignored** | 50MB 초과 (413) — on-demand 생성 |

**시나리오 실행 전 필수 (`huge-51mb` 사용 시)**:

```bash
python integration-tests/fixtures/_generate.py
```

> `_generate.py` 는 6 fixture 모두를 재생성한다. tracked 5종은 idempotent (동일 결과), `huge-51mb` 는 매번 무작위 51MB 바이트 (`os.urandom`).

## 환경 변수 (`.env`)

`integration-tests/.env` (gitignored) 에 JWT 4종 정의:

```bash
ADMIN_JWT=eyJhbGc...      # Admin 계정 JWT
OPERATOR_JWT=eyJhbGc...   # Operator 계정 JWT
VIEWER_JWT=eyJhbGc...     # Viewer 계정 JWT
CC_SERVICE_JWT=eyJhbGc... # CC 서비스 계정 JWT
REFRESH_TOKEN=eyJhbGc...  # 10-auth refresh 테스트용
```

각 JWT는 `POST /api/v1/auth/login` 으로 발급. 자세히는 `scenarios/10-auth-login-profile.http`.

## 책임 (S6 Prototype Stream)

본 디렉토리는 S6 own. 자세한 빌드/검증 plan = [`docs/4. Operations/Prototype_Build_Plan.md`](../docs/4.%20Operations/Prototype_Build_Plan.md). §4.4 fixture / §5 의존성 / §6 검증 게이트 참조.
