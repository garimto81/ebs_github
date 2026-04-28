# team1-frontend — EBS Lobby (Flutter Web)

EBS (Event Broadcast System) Team 1 frontend: **Login + Lobby + Settings 6탭 + Graphic Editor 허브**. Flutter/Dart 단일 코드베이스로 배포 타깃은 두 가지:

| 타깃 | 용도 | 명령 |
|------|------|------|
| **Flutter Web (정규 배포)** | LAN/운영자 브라우저 접속, Docker 컨테이너 (`ebs-lobby-web` :3000) | `flutter build web` (CI 자동) + `docker compose --profile web up -d lobby-web` |
| **Flutter Desktop / Chrome (개발 전용)** | 핫리로드 디버깅 | `flutter run -d windows` 또는 `flutter run -d chrome` |

CLAUDE.md `Role` 섹션 참조.

---

## Architecture Decisions (2026-04-28, post-PR #18)

### AD-1 — Flutter SDK Pinning (deterministic build)

`team1-frontend/docker/lobby-web/Dockerfile` 의 builder image 는 **`ghcr.io/cirruslabs/flutter:3.41.7`** 로 explicit pin.

| 항목 | 내용 |
|------|------|
| **결정** | `:stable` 부동 tag 사용 금지. semver 명시 tag 만 허용. |
| **이유** | PR #17 cascade 에서 발견된 5-layer 갭 (intl pin / Dart SDK / `--web-renderer` / `--obfuscate`) 은 모두 Flutter SDK minor 업그레이드가 trigger. `:stable` 은 CI/local 결과 비결정성 발생원. |
| **현 pin** | `flutter:3.41.7` (digest `sha256:644e3cea0a8440ce75804b67ceab77b16a87b39d9e9d89b07aceca7a98af1aa3`, 2026-04-15 release) |
| **업그레이드 protocol** | (1) 새 pin 후보 explicit tag 로 옵션 PR 작성, (2) cascade 갭 (intl pin / web flag) 재현 여부 확인, (3) pubspec.yaml 의존성 일괄 점검, (4) PR-#18 패턴으로 머지 |
| **자동 감지** | `.github/dependabot.yml` 의 docker ecosystem 이 매주 수요일 새 Flutter SDK release 를 PR 로 제안 |
| **CI 가드** | `.github/workflows/team1-e2e.yml` 의 dockerfile-lint + hadolint + docker-build-gate 3-tier 가 PR pre-merge 단계에서 회귀 차단 |

### AD-2 — Frontend Wiring (single host variable)

Frontend 는 **`EBS_BO_HOST` 단일 환경변수** 로 backend (BO) 만 가리킨다. **Engine (8080) 은 frontend 에서 직접 호출하지 않는다**.

| 항목 | 내용 |
|------|------|
| **단일 host** | `EBS_BO_HOST` (+ optional `EBS_BO_PORT`, default `8000`) |
| **유도 변수** | `apiBaseUrl = http://$EBS_BO_HOST:$EBS_BO_PORT/api/v1` <br> `wsBaseUrl  = ws://$EBS_BO_HOST:$EBS_BO_PORT` (frontend lobby_websocket_client → `/ws/lobby`) |
| **금지** | `BO_URL`, `ENGINE_URL`, `CC_URL` 등 별도 frontend env 변수. 모두 `EBS_BO_HOST` 1 곳에서 derive 되어야 함 (DRY + 잘못된 endpoint 분기 방지) |
| **Engine 경계** | team3 engine (port 8080) 은 BO ↔ Engine 간 backend-internal 통신 전용. frontend 가 직접 호출하면 multi-tenant 보안 / WS auth gate 우회 위험. |
| **검증** | `team1-frontend/tools/verify_team1_e2e.py` 의 S2 (apiBaseUrl) + S3 (wsBaseUrl) + S4 (engine HTTP-only NOTE) 가 wiring 정합성 보증 |
| **SSOT 코드** | `lib/foundation/configs/app_config.dart` `AppConfig.fromEnvironment()` |

### AD-3 — Build Context (monorepo root)

(PR #17, 2026-04-28) `docker-compose.yml` 의 `lobby-web` build context 는 **project root (`.`)** 로 승격됨. Dockerfile 의 모든 `COPY` 경로는 `team1-frontend/` 로 prefix.

이유: `pubspec.yaml` 의 `ebs_common: path: ../shared/ebs_common` 의존성을 docker build 가 resolve 하려면 `shared/` 가 build context 안에 포함되어야 함.

CI 차단:
- **dockerfile-lint job** (~11 s) — Linux BuildKit 이 silently normalize 하는 `COPY ../` 패턴을 grep-based static check 로 차단 (PR #22)
- **hadolint job** (~30 s) — community Dockerfile best-practice (PR #25)
- **docker-build-gate** (~5 min) — 실제 BuildKit 빌드로 5-layer cascade 회귀 차단

3-tier defense, fast-fail 우선순위. 자세히: `.github/workflows/team1-e2e.yml`.

---

## Tech Stack

| 계층 | 채택 |
|------|------|
| **Language** | Dart (`>=3.3.0 <4.0.0`) |
| **Framework** | Flutter (`>=3.22.0`, CI 빌드 image `flutter:3.41.7`) |
| **State management** | `flutter_riverpod` ^2.5 (+ `riverpod_annotation`) |
| **Code generation** | `freezed` / `json_serializable` / `riverpod_generator` (build_runner) |
| **HTTP client** | `dio` ^5.4 (Idempotency-Key interceptor in `lib/data/remote/`) |
| **WebSocket** | `web_socket_channel` ^2.4 (seq cursor + replay) |
| **Routing** | `go_router` ^14 (declarative SPA routing) |
| **i18n** | `flutter_localizations` + `intl` ^0.20.2 (ko/en/es ARB) |
| **Graphic Editor preview** | `rive` ^0.13 (`.gfskin` 프리뷰만; 에디터 기능 재구현은 out-of-scope) |
| **Telemetry** | `sentry_flutter` ^8.3 (release tagging via `scripts/sentry_release.sh`) |
| **Tests** | `flutter_test` + `mocktail` (unit/widget) + `tools/verify_team1_e2e.py` (E2E python harness) |

자세한 의존성: `pubspec.yaml`.

---

## Repository Layout

```
team1-frontend/
├── pubspec.yaml                # Dart/Flutter 의존성
├── analysis_options.yaml       # static analysis
├── l10n.yaml                   # ARB → Dart codegen 설정
├── lib/
│   ├── main.dart               # Flutter entry
│   ├── app.dart                # MaterialApp + go_router
│   ├── data/
│   │   └── remote/             # Dio + WS clients (auth_interceptor, bo_api_client, lobby_websocket_client)
│   ├── features/               # 7 features: auth, lobby, players, settings, graphic_editor, staff, reports
│   ├── foundation/
│   │   └── configs/
│   │       └── app_config.dart # AD-2 SSOT — EBS_BO_HOST → apiBaseUrl/wsBaseUrl
│   ├── models/                 # Freezed entities + enums
│   ├── repositories/           # 11 repository 클래스 (use case 경계)
│   └── resources/
│       └── l10n/               # ARB 번역 파일 (231 keys)
├── test/                       # flutter_test + mocktail
│   ├── data/
│   ├── features/
│   ├── foundation/
│   ├── integration/
│   └── widget_test.dart
├── docker/lobby-web/           # 정규 Docker 배포 자산 (PR #17/#18/#22 검증됨)
│   ├── Dockerfile              # Flutter SDK 3.41.7 → nginx:1.27-alpine multi-stage
│   ├── nginx.conf              # SPA fallback + /healthz + cache strategy
│   └── compose.snippet.yaml    # 참조용 compose 발췌 (실제는 root docker-compose.yml 통합)
├── production.example.json     # build-arg ENV_FILE 기본값
├── scripts/
│   ├── build_release.sh        # production 빌드 헬퍼
│   ├── sentry_release.sh       # web sourcemap upload sidecar (PR #18)
│   └── verify_harness.py       # E2E 3-tier validation harness (PR #10/#11)
└── tools/
    └── verify_team1_e2e.py     # Phase 5 final E2E verification (PR #16)
```

---

## Dev Setup

### 사전 요구

- **Flutter SDK** 3.41.7 (또는 동등 stable). 로컬 native debugging 시 필수.
- **Python** 3.10+ (`tools/verify_team1_e2e.py` 실행 시).
- **Docker** + Docker Compose (정규 배포 검증 시).

> `flutter:3.41.7` 와 동일 SDK 사용 권장 — pubspec.yaml 의존성 (`intl`, `patrol_finders` 등) 이 본 버전에 맞춤. 다른 SDK 사용 시 `flutter pub get` cascade 갭 발생 가능 (AD-1 참조).

### 첫 셋업

```bash
cd team1-frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Freezed/Riverpod/JSON codegen
flutter analyze                                             # 정적 분석
flutter test                                                # unit + widget
```

### 환경 변수 (run/build 시 주입)

방법 1 — 호스트 지정 (권장):
```bash
flutter run -d chrome --dart-define=EBS_BO_HOST=192.168.1.100
# → apiBaseUrl = http://192.168.1.100:8000/api/v1
# → wsBaseUrl  = ws://192.168.1.100:8000
```

방법 2 — 직접 URL override (CI 등):
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://custom-host:9000/api/v1 \
  --dart-define=WS_BASE_URL=ws://custom-host:9000
```

### 기본값 (개발)

| 변수 | 기본값 |
|------|--------|
| `EBS_BO_HOST` | (미설정 → localhost) |
| `EBS_BO_PORT` | 8000 |
| `USE_MOCK` | false |

---

## Build & Run

### Local development (핫리로드)

```bash
flutter run -d chrome                    # Web (브라우저 핫리로드)
flutter run -d windows                   # Native (Desktop 디버깅, 일부 web-only API 미지원)
```

### Production web build

```bash
flutter build web \
  --release \
  --tree-shake-icons \
  --dart-define-from-file=production.json \
  --source-maps \
  --output=build/web
```

산출물: `build/web/` (정적 nginx serve 가능). Sentry sourcemap 업로드는 `scripts/sentry_release.sh` 사이드카 사용 — `team1-frontend/docker/lobby-web/Dockerfile` 의 `flutter build web` 명령과 동일 옵션.

> ⚠ `--web-renderer`, `--obfuscate`, `--dart2js-optimization` flag 는 Flutter 3.27+ 에서 제거/미지원. Dockerfile 빌드 명령 변경 시 PR #17 cascade history 참조.

### Docker (정규 배포)

```bash
# 프로젝트 루트에서 실행 (compose context = root)
docker compose --profile web build lobby-web
docker compose --profile web up -d lobby-web
# → http://localhost:3000/  (canonical SSOT, AD-3)
```

---

## E2E Verification

### 3-tier validation (`scripts/verify_harness.py`)

contract-level "5개 서비스가 응답하나" 검사:

```bash
python scripts/verify_harness.py
# L1 HTTP probes: lobby /, /healthz, bo /health, /openapi, engine /health
# L2 WebSocket: ws://bo/ws/{lobby,cc} handshake (auth gate detection)
# L3 Headless DOM: Playwright Chromium → console errors 검사
```

### Phase 5 final E2E (`tools/verify_team1_e2e.py`)

frontend wiring 관점 "team1 이 의존하는 채널들이 정합한가" 검사:

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
  LOBBY_URL=http://localhost:3000 \
  python tools/verify_team1_e2e.py
# S1 lobby static + Flutter bootstrap
# S2 bo /api/v1 reachable (apiBaseUrl)
# S2b bo openapi /auth/login present
# S3 ws://<bo>/ws/lobby (auth gate)
# S4 engine HTTP 8080 (HTTP-only — Type B note)
# S5 CORS preflight (Origin echo)
```

두 스크립트는 **다른 lens 로 같은 stack 검증** — `verify_harness.py` 는 contract 차원, `verify_team1_e2e.py` 는 wiring 차원. 자세히: `TEAM1_E2E_HARNESS_HANDOFF.md` (PR #10) + `TEAM1_FINAL_E2E_HANDOFF.md` (PR #16).

---

## Documentation Cross-references

| 문서 | 역할 |
|------|------|
| `CLAUDE.md` | 팀 범위, API 경계, 금지 사항 |
| `../docs/2. Development/2.1 Frontend/` | 기능 명세 (Login/Lobby/Settings/Graphic_Editor 등) |
| `../docs/2. Development/2.5 Shared/` | 팀 간 공통 계약 (BS Overview, Authentication 등) |
| `../docs/2. Development/2.2 Backend/APIs/` | API-01/05/06 (read-only consume) |
| `TEAM1_E2E_HARNESS_HANDOFF.md` | 3-tier validation 결과 (PR #10) |
| `TEAM1_FINAL_E2E_HANDOFF.md` | wiring E2E 결과 (PR #16) |

> 팀 문서 (`docs/2. Development/2.1 Frontend/`) 는 `docs v10` 단일 경로 원칙에 따라 레포 루트에 통합. team1-frontend/ 는 코드 전용 (PR-history 의 6 cascade 참조).

---

## 이전 코드 참조 (legacy)

| 폴더 | 내용 |
|------|------|
| `_archive-quasar/` | Quasar (Vue 3) 선행 작업물 — Flutter 전환으로 archive (수정 금지) |
| `../C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` | React 19 + Vite 6 선행 작업물 — Quasar 전환 시 archive |

---

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{2,3,4,5}/`, `../docs/4. Operations/` 수정 금지 (다른 팀/conductor 소유)
- 다른 팀 코드 폴더 (`../team2-backend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- **Overlay 실제 렌더링 구현 금지** (team4 영역, BS-07)
- **Rive 에디터 기능 재구현 금지** (out-of-scope; 공식 에디터 외부 사용)
- **Engine (port 8080) 직접 호출 금지** (AD-2)
