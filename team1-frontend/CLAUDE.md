# Team 1: Frontend — CLAUDE.md (코드 전용)

## 🚀 표준 명령 (v3.0 이후)

모든 작업은 `/team` 스킬로:
```bash
/team "<task description>"
```
자동 수행: context detect → pre-sync → `/auto` → verify → commit → main ff-merge → push → report.
세션 시작/종료 불필요. 상세: `~/.claude/skills/team/SKILL.md`, `docs/4. Operations/Multi_Session_Workflow.md` v3.0

## 🎯 2026-04-21 이관 시 우선 작업 (MUST READ)

**Stream 진입 가이드**: `docs/2. Development/2.5 Shared/Stream_Entry_Guide.md` — 세션 시작 시 필독.

### team1 우선 작업 (기준 커밋 `7543452`)

1. **IMPL-002 Engine Connection UI 완결** — `docs/4. Operations/Conductor_Backlog/IMPL-002-team4-engine-connection-ui.md` 참조 (일부 team4 작업 포함되나 team1 splash/router 연동 부분 협력)
2. **Settings 5탭 교차검증** — `lib/features/settings/screens/` 의 레거시 필드 vs SG-003 Extended Fields (Conductor 가 추가한 섹션) 의 일관성. 현재 `UNKNOWN 5`. `docs/2. Development/2.1 Frontend/Settings/{Outputs,Graphics,Display,Rules,Statistics}.md` 와 교차검증 후 PASS 전환
3. **Quasar 잔재 정리 (SG-001 후속)** — `team1-frontend/src/`, `package.json`, `quasar.config.js`, `node_modules/`, `pnpm-lock.yaml`, `build/`, `.quasar/` 삭제. `_archive-quasar/` 는 보존
4. **skin-editor drafts 5 완결** — `docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/` 의 PRD-0006/7/7-S1/7-S2 + PLAN-UI-001 (모두 `status: draft`) → 본문 보강 후 `reimplementability: PASS`
5. **Chip_Management §6 미결 3건** — Multi-Table 일괄 API / Chip Discrepancy / Color-up/Race-off 설계 결정 (Conductor 협의)
6. **features 정렬** — 선언 8 (auth/lobby/settings/GE/staff/**players**/**audit_log**/**hand_history**) vs 실측 6 (auth/lobby/settings/GE/staff/**reports**). 결정: (a) reports 를 선언에 편입 (b) 미구현 3개 신규 기능 추가. `Engineering.md §0` 참조

### 주요 도구

- `python tools/spec_drift_check.py --settings` — settings drift 실시간 확인
- `python tools/reimplementability_audit.py --path docs/2.*Frontend*` — team1 계약 문서 재구현성

### 금지 / 범위 밖

- Graphic Editor 실제 Rive 에디터 기능 재구현 (rive 프리뷰 허용만)
- `docs/1. Product/`, `docs/2. Development/2.{2,3,4,5}*/`, `docs/4. Operations/` 수정 (다른 팀 소유, 단 v7 free_write 하 notify 후 가능)

---

## 브랜치 규칙

- **작업 브랜치**: `work/team1/{YYYYMMDD}-session` (SessionStart hook 자동 생성)
- **main 직접 작업 금지** — commit/push 차단됨
- **병합**: `/team-merge` 커맨드로만 main 병합 (Conductor 세션 권장)

## Role

Login UI + Lobby + Settings 6탭 (Outputs / GFX / Display / Rules / Stats / Preferences) + Graphic Editor Skin hub

**기술 스택**: Flutter/Dart + Riverpod + Freezed + Dio + go_router + `rive` (GE 프리뷰 전용)

**배포 형태 (2026-04-27 재정의 — SG-022 폐기, Multi-Service Docker 채택)**:

배포: **독립 Docker 컨테이너 (Lobby:3000 / CC:3001)**. 네트워크를 통해 Backend/Engine 과 연동되는 **멀티 세션 구조**.

Lobby (team1) 와 CC (team4) 는 단일 앱이 아니며, 각각 독립된 Flutter 프로젝트로 존재한다. 다만 완전 독립은 아니며, Docker 기반의 격리된 환경에서 기동되어 동일한 EBS 에코시스템 (`ebs-net`) 내에서 네트워크로 상호 작용한다.

| 용도 | 대상 | 방법 |
|------|------|------|
| **정규 배포** | 사용자 (운영자, 관찰자) | `docker compose --profile web up -d lobby-web` → 브라우저 `http://<lan-ip>:3000/` |
| **개발자 디버깅** (배포 아님) | 개발자 | `flutter run -d chrome` (Web 핫리로드) 또는 `flutter run -d windows` (native 확인) |

사용자가 Flutter SDK + CLI 를 실행하는 시나리오는 없다.

**"Flutter 단일 스택"의 의미**: 프레임워크 하나(Flutter)로 모든 팀(team1/team4) 통일 — Vue/Quasar 폐기 (`2cc13b1`, 2026-04-21). 2026-04-22 "Desktop only" 로 확대 해석된 오류는 2026-04-27 SG-022 공식 폐기로 정정 완료.

**SG-022 폐기 근거**: 단일 Desktop 바이너리 통합은 4팀 병렬 개발 + LAN 멀티 세션 운영 요구와 충돌. team1/team4 가 각자 독립 라이프사이클(Dockerfile/nginx)을 가지면서 공통 네트워크로 협력하는 multi-service 구조가 SSOT.

배포 상세 SSOT: `../docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md`

---

## 문서 위치 (docs v10)

**팀 문서는 모두 `docs/2. Development/2.1 Frontend/` 에 있다. 이 폴더는 코드 전용.**

| 문서 카테고리 | 경로 |
|--------------|------|
| 섹션 landing / 인덱스 | `../docs/2. Development/2.1 Frontend/2.1 Frontend.md` |
| Login 화면 | `../docs/2. Development/2.1 Frontend/Login/` |
| Lobby | `../docs/2. Development/2.1 Frontend/Lobby/` |
| Settings 6탭 | `../docs/2. Development/2.1 Frontend/Settings/` |
| Graphic Editor | `../docs/2. Development/2.1 Frontend/Graphic_Editor/` |
| Legacy Console UI (역사 기록) | `../docs/2. Development/2.1 Frontend/Settings/Legacy_Console_UI.md` |
| Engineering / Architecture | `../docs/2. Development/2.1 Frontend/Engineering.md` |
| Backlog | `../docs/2. Development/2.1 Frontend/Backlog.md` |

## 소유 경로 (코드)

| 경로 | 내용 |
|------|------|
| `lib/` | Flutter/Dart 소스 코드 |
| `test/` | flutter_test + mocktail |
| `windows/` | Windows runner |
| `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml` | 프로젝트 설정 |
| `_archive-quasar/` | Quasar 아카이브 (참조 전용, 수정 금지) |

## 아키텍처 (team4 CC 패턴 채택)

```
lib/
├── data/remote/          # Dio API client + WS client (Idempotency-Key + seq)
├── data/local/           # MockDioAdapter (MSW 대체)
├── features/             # 기능별 screens + providers + widgets (7개, 2026-04-21 Players 독립 레이어 추가)
│   ├── auth/             # 로그인 + 2FA (StateNotifier)
│   ├── lobby/            # Series→Event→Flight→Table 드릴다운
│   ├── players/          # Player 독립 화면 (Lobby/UI.md §화면 4 독립 레이어)
│   ├── settings/         # 6탭 (family provider by section)
│   ├── graphic_editor/   # 스킨 허브 + Rive 프리뷰 (Flutter rive ^0.13)
│   ├── staff/            # Staff 관리 (RBAC 3역할)
│   └── reports/          # Hand History + Audit Log 뷰어 (읽기 전용, BO DB 소비)
├── models/               # Freezed entities + enums
├── repositories/         # 11 repository 클래스
├── foundation/           # theme, router, configs, i18n, widgets
└── resources/            # constants, l10n ARB 파일
```

## Shared Package

`../shared/ebs_common/` — team1/team4 공통 유틸리티:
- Permission (RBAC bit-flag)
- UuidIdempotency
- SeqTracker

## 계약 참조 (읽기 전용)

팀 간 공통 계약 — publisher 팀이 소유, 이 팀은 consume만 함:

| 계약 | 경로 | 소유 |
|------|------|------|
| API-01 REST | `../docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` | team2 |
| API-05 WebSocket | `../docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | team2 |
| API-06 Auth | `../docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | team2 |
| DATA Schema | `../docs/2. Development/2.2 Backend/Database/Schema.md` | team2 |
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `../docs/2. Development/2.5 Shared/Authentication.md` | conductor |

수정 필요 시 해당 문서를 직접 보강 (additive). decision_owner 는 publisher 팀.

## API / WebSocket 경계

- 모든 HTTP 호출은 Backend (team2)로만 전송
- CC, Game Engine과의 직접 통신 금지
- WebSocket `ws://[host]/ws/lobby` — 모니터링 전용 (write 명령 없음)
- Idempotency-Key 자동 주입 (`lib/data/remote/bo_api_client.dart` Dio interceptor)
- seq 단조증가 검증 + `/ws/replay?from_seq=N` (`lib/data/remote/lobby_websocket_client.dart`)

## Mock Server (병렬 개발)

MockDioAdapter (`lib/data/local/`). `--dart-define=USE_MOCK=true` (기본값).

## i18n

flutter_localizations + intl, locale 3종 (`ko` 기본, `en` Vegas, `es` Vegas sub). 위치: `lib/resources/l10n/app_{ko,en,es}.arb` (231 keys).

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다 (additive). decision_owner 는 `team-policy.json` 참조. 상세: `../CLAUDE.md` §"문서 변경 거버넌스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{2,3,4,5}*/`, `../docs/4. Operations/` 수정 금지 (다른 팀 소유)
- 다른 팀 코드 폴더(`../team2-backend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- **Overlay 실제 렌더링 구현 금지** (team4 영역)
- **Rive 에디터 기능 재구현 금지** (out-of-scope) — rive 프리뷰만

## Build / Dev

```bash
cd team1-frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Freezed 코드 생성
flutter analyze                   # 정적 분석
flutter test                      # Unit + Widget 테스트
flutter run -d windows            # 개발 실행
flutter build windows --release   # 프로덕션 빌드
```

**커밋 전 필수**: `flutter analyze && flutter test` 통과.

## 환경변수

### 방법 1: Same-origin 모드 (Docker / nginx proxy 배포 — 권장, cycle 9 이후 기본)
```bash
flutter build web --release \
  --dart-define=USE_MOCK=false \
  --dart-define=EBS_SAME_ORIGIN=true
```
→ Lobby 가 자기 브라우저 origin (http://<host>:3000) 으로 `/api/`, `/ws/` 호출.
nginx 가 bo:8000 으로 reverse proxy. port hardcoding 없어, LAN IP (192.168.x.x:3000)
디바이스도 재빌드 없이 자동 작동. HTTPS 배포 시 wss:// 자동 전환.

### 방법 2: 호스트 지정 (네이티브 개발 / 비-proxy 환경)
```bash
flutter run -d windows --dart-define=EBS_BO_HOST=192.168.1.100
```
→ API: `http://192.168.1.100:8000/api/v1`, WS: `ws://192.168.1.100:8000` 자동 구성

### 방법 3: 직접 URL 지정 (최우선, 디버깅)
```bash
flutter run -d windows \
  --dart-define=API_BASE_URL=http://custom-host:9000/api/v1 \
  --dart-define=WS_BASE_URL=ws://custom-host:9000
```
→ `API_BASE_URL` + `WS_BASE_URL` 동시 지정 시 다른 모드 무시.

### 우선순위 (`AppConfig.fromEnvironment`)
1. `API_BASE_URL` + `WS_BASE_URL` 명시 → 그대로 사용
2. `EBS_SAME_ORIGIN=true` + web 빌드 → `window.location` origin 동적 사용
3. `EBS_BO_HOST` + `EBS_BO_PORT` → `http://<host>:<port>/api/v1` 구성

### 기본값 (개발)
| 변수 | 기본값 | 비고 |
|------|--------|------|
| `EBS_SAME_ORIGIN` | false | true 시 web 빌드는 same-origin 우선 |
| `EBS_BO_HOST` | (미설정 → localhost) | web 빌드는 window.location.hostname 자동 fallback |
| `EBS_BO_PORT` | 8000 | same-origin 모드에서는 사용 안 함 |
| `USE_MOCK` | false | true 시 MockDioAdapter 활성화 |
| `HAND_AUTO_SETUP` | false | 1 hand demo auto-wire (Cycle 2 #239) |

## 이전 코드 참조

- Quasar (Vue 3) 선행 작업물: `_archive-quasar/` (Flutter 전환으로 아카이브)
- React 19 + Vite 6 선행 작업물: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` (Quasar 전환으로 아카이브)
