# Team 1: Frontend — CLAUDE.md (코드 전용)

## Role

Login UI + Lobby + Settings 6탭 (Outputs / GFX / Display / Rules / Stats / Preferences) + Graphic Editor Import/Activate 허브 (CCR-011)

**기술 스택**: Flutter/Dart + Riverpod + Freezed + Dio + go_router + `rive` (GE 프리뷰 전용)

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
├── data/remote/          # Dio API client + WS client (CCR-019/021)
├── data/local/           # MockDioAdapter (MSW 대체)
├── features/             # 기능별 screens + providers + widgets
│   ├── auth/             # 로그인 + 2FA (StateNotifier)
│   ├── lobby/            # Series→Event→Table 드릴다운
│   ├── players/
│   ├── staff/
│   ├── settings/         # 6탭 (family provider by section)
│   ├── graphic_editor/   # 스킨 허브 + Rive 프리뷰
│   ├── audit_log/
│   └── hand_history/
├── models/               # Freezed entities + enums
├── repositories/         # 11 repository 클래스
├── foundation/           # theme, router, configs, i18n, widgets
└── resources/            # constants, l10n ARB 파일
```

## Shared Package

`../shared/ebs_common/` — team1/team4 공통 유틸리티:
- CCR-017 Permission (RBAC bit-flag)
- CCR-019 UuidIdempotency
- CCR-021 SeqTracker

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

수정은 CR 프로세스 경유 (`../docs/3. Change Requests/pending/CR-team1-YYYYMMDD-*.md`).

## API / WebSocket 경계

- 모든 HTTP 호출은 Backend (team2)로만 전송
- CC, Game Engine과의 직접 통신 금지
- WebSocket `ws://[host]/ws/lobby` — 모니터링 전용 (write 명령 없음)
- CCR-019 Idempotency-Key 자동 주입 (`lib/data/remote/bo_api_client.dart` Dio interceptor)
- CCR-021 seq 단조증가 검증 + `/ws/replay?from_seq=N` (`lib/data/remote/lobby_websocket_client.dart`)

## Mock Server (병렬 개발)

MockDioAdapter (`lib/data/local/`). `--dart-define=USE_MOCK=true` (기본값).

## i18n

flutter_localizations + intl, locale 3종 (`ko` 기본, `en` Vegas, `es` Vegas sub). 위치: `lib/resources/l10n/app_{ko,en,es}.arb` (231 keys).

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다. Spec_Gaps.md · CR draft · CCR-first 프로세스는 폐지되었다. 상세: `../CLAUDE.md` §"기획 공백 발견 시 프로세스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{2,3,4,5}*/`, `../docs/3. Change Requests/{in-progress,done}/`, `../docs/4. Operations/` 수정 금지 (CR 프로세스)
- 다른 팀 코드 폴더(`../team2-backend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- **Overlay 실제 렌더링 구현 금지** (team4 영역)
- **Rive 에디터 기능 재구현 금지** (CCR-011 out-of-scope) — rive 프리뷰만

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

**환경변수** (`--dart-define`):
- `API_BASE_URL` — 기본 `http://localhost:8000/api/v1`
- `WS_BASE_URL` — 기본 `ws://localhost:8000`
- `USE_MOCK` — 기본 `true` (Mock 모드)

## 이전 코드 참조

- Quasar (Vue 3) 선행 작업물: `_archive-quasar/` (Flutter 전환으로 아카이브)
- React 19 + Vite 6 선행 작업물: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` (Quasar 전환으로 아카이브)
