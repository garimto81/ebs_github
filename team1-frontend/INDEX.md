# Team 1 Frontend 인덱스 (Flutter + Docker Web 배포)

> 목적: Flutter 코드 디렉토리 + 연관 기획 문서 경로를 한 화면에서 파악. 탐색 치트시트로 O(1) 점프.
> 최종 갱신: 2026-04-21 (Flutter 단일 스택 확정 + Quasar 잔재 제거 + v10 docs 경로)

## 한눈 지도 — 기획 문서 (`docs/2. Development/2.1 Frontend/`)

| 범주 | 파일 | 1줄 존재 이유 |
|------|------|--------------|
| 팀 경계 | `../CLAUDE.md` | 팀 범위·금지·Hook 스코프 가드 입력 |
| 섹션 landing | `docs/.../2.1 Frontend.md` | CI 자동 생성 하위 문서 목록 |
| Engineering | `docs/.../Engineering.md` | Flutter 스택/아키텍처 SSOT (Riverpod/Freezed/Dio/go_router) |
| Backlog | `docs/.../Backlog.md` | PENDING / IN_PROGRESS / DONE |
| Login 기획 | `docs/.../Login/{Form,Session_Init,Error_Handling}.md` | 로그인 3 문서 |
| Lobby 기획 | `docs/.../Lobby/{Overview,Event_and_Flight,Table,Session_Restore,UI}.md` | 5 문서 |
| Settings 기획 | `docs/.../Settings/{Overview,Outputs,Graphics,Display,Rules,Statistics,Preferences,UI}.md` | 8 문서 (6탭 + Overview + UI) |
| Graphic Editor 기획 | `docs/.../Graphic_Editor/{Overview,Import_Flow,Metadata_Editing,Activate_Broadcast,RBAC_Guards,UI}.md` | 6 문서 |

## 한눈 지도 — Flutter 코드 (`lib/`)

| 범주 | 경로 | 역할 |
|------|------|------|
| 진입점 | `lib/main.dart`, `lib/app.dart` | ProviderScope + MaterialApp.router |
| Dio | `lib/data/remote/bo_api_client.dart` | Idempotency-Key + Auth refresh interceptor |
| WebSocket | `lib/data/remote/lobby_websocket_client.dart` | seq 단조증가 + `/ws/replay?from_seq=N` |
| Mock | `lib/data/local/mock_dio_adapter.dart`, `mock_data.dart` | `--dart-define=USE_MOCK=true` 토글 |
| Features | `lib/features/{auth,lobby,players,settings,graphic_editor,staff,reports}/` | **7개 feature** (2026-04-21 Players 독립 레이어 추가) |
| Freezed 모델 | `lib/models/entities/*.dart` | 15+ entities (.freezed.dart + .g.dart 자동 생성) |
| Repositories | `lib/repositories/*.dart` | 11개 Repository (API-01 계약 소비) |
| Foundation | `lib/foundation/{theme,router,configs,i18n,widgets}/` | 공통 인프라 |
| Shared util | `../shared/ebs_common/` | team1 + team4 공용 (Permission/UuidIdempotency/SeqTracker) |

## 탐색 치트시트

구현 중 "어디를 봐야 하나" 자주 걸리는 포인트.

| 찾는 것 | 가야 할 곳 |
|---------|-----------|
| Settings 6탭 구조 | `docs/.../Settings/Overview.md` (기획) + `lib/features/settings/` (구현) |
| Event/Flight 상태 enum | `docs/.../Lobby/Event_and_Flight.md` |
| Table FSM (EMPTY/SETUP/LIVE/...) | `docs/.../Lobby/Table.md` |
| `.gfskin` ZIP 업로드 FSM | `docs/.../Graphic_Editor/Import_Flow.md` |
| GE Rive 프리뷰 구현 (Flutter rive ^0.13) | `docs/.../Graphic_Editor/Overview.md §8` |
| GE Activate + WS broadcast 포맷 | `docs/.../Graphic_Editor/Activate_Broadcast.md` |
| RBAC Admin/Operator/Viewer 게이트 | `docs/.../Graphic_Editor/RBAC_Guards.md` |
| Riverpod provider 패턴 | `docs/.../Engineering.md §3` |
| Dio interceptor 체인 (Idempotency + Auth refresh) | `docs/.../Engineering.md §5` + `lib/data/remote/bo_api_client.dart` |
| WS seq gap 감지 + replay | `docs/.../Engineering.md §6` + `lib/data/remote/lobby_websocket_client.dart` |
| Mock 서버 (MockDioAdapter) 토글 | `docs/.../Engineering.md §7` + `lib/data/local/` |
| i18n locale (ko/en/es, 231 keys) | `docs/.../Engineering.md §8` + `lib/resources/l10n/app_{ko,en,es}.arb` |
| Material3 dark 테마 | `docs/.../Engineering.md §9` + `lib/foundation/theme/ebs_theme.dart` |
| 환경변수 (`--dart-define=EBS_BO_HOST=...`) | `docs/.../Engineering.md §11` + `../CLAUDE.md §환경변수` |
| 팀 경계 (뭘 하면 안 되나) | `../CLAUDE.md §금지` |

## 외부 계약 참조 (read-only)

| 계약 | 위치 | Publisher |
|------|------|-----------|
| REST API (66+ endpoints) | `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` | team2 |
| WebSocket Events | `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | team2 |
| Auth & Session | `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | team2 |
| DATA Schema | `docs/2. Development/2.2 Backend/Database/Schema.md` | team2 |
| Graphic_Editor_API | `docs/2. Development/2.2 Backend/APIs/Graphic_Editor_API.md` | team2 |
| BS-00 공통 정의 | `docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `docs/2. Development/2.5 Shared/Authentication.md` | conductor |

## 상태 (2026-04-21)

- **Flutter 단일 스택 확정** — Quasar 잔재 (src/, package.json, quasar.config.js, e2e/, node_modules 관련 config) 100건 tracked 파일 제거 완료 (commit `2cc13b1`). `_archive-quasar/` 는 참조 전용 보존
- **features 7 정렬** — 선언=실측 일치 달성. `auth / lobby / players / settings / graphic_editor / staff / reports`. 2026-04-21 Players 독립 레이어 구현 (`Lobby/UI.md §화면 4` 준수). audit_log/hand_history 는 `reports` 하위로 통합
- **CI workflow 전환** — `pnpm/node` → `subosito/flutter-action@v2` + build_runner + analyze + test
- **4팀 계약 subscriber** — Backend API-01/05/06/07 + DATA-04 + BS-00/01 소비만. publisher 자격 없음

## 유지보수 규칙

- 파일 추가/삭제/rename 시 본 INDEX.md 의 테이블 동시 갱신 (drift 방지)
- 기획 문서 수정은 `docs/2. Development/2.1 Frontend/` 만 — 다른 팀 폴더 금지 (v7 free_write 하에서도 decision_owner 존중)
- 신규 feature 디렉토리 추가 시 `lib/features/` + 본 INDEX 동시 반영 + `team1/CLAUDE.md §아키텍처` 섹션 동기화
- 외부 계약 변경 필요 시 publisher 팀에 notify (commit 메시지 `notify: team{N}`)
