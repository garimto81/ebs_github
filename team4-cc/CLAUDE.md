# Team 4: Command Center + Overlay — CLAUDE.md (코드 전용)

## 브랜치 규칙

- **작업 브랜치**: `work/team4/{YYYYMMDD}-session` (SessionStart hook 자동 생성)
- **main 직접 작업 금지** — commit/push 차단됨
- **병합**: `/team-merge` 커맨드로만 main 병합 (Conductor 세션 권장)

## Role

Command Center (실시간 운영) + Overlay (방송 그래픽 출력, Skin Consumer)

**기술 스택**: Flutter/Dart + Rive 애니메이션 (WSOP Fatima.app 프로덕션 패턴: Riverpod + Dio/Retrofit + Freezed)

**Publisher**: RFID HAL (API-03).

> Graphic Editor는 team1 소유. team4는 `skin_updated` WebSocket 이벤트 수신 후 Overlay 를 reload 하는 **Skin Consumer**. GE UI 구현 금지.

---

## 문서 위치 (docs v10)

**팀 문서는 모두 `docs/2. Development/2.4 Command Center/` 에 있다. 이 폴더는 코드 전용.**

| 문서 카테고리 | 경로 |
|--------------|------|
| 섹션 landing | `../docs/2. Development/2.4 Command Center/2.4 Command Center.md` |
| APIs (publisher) | `../docs/2. Development/2.4 Command Center/APIs/` |
| RFID Cards | `../docs/2. Development/2.4 Command Center/RFID_Cards/` |
| Command Center UI | `../docs/2. Development/2.4 Command Center/Command_Center_UI/` |
| Overlay | `../docs/2. Development/2.4 Command Center/Overlay/` |
| Integration Test Plan | `../docs/2. Development/2.4 Command Center/Integration_Test_Plan.md` |
| Backlog | `../docs/2. Development/2.4 Command Center/Backlog.md` |

### Publisher 직접 편집 권한

team4는 RFID HAL 을 직접 수정 가능:

| 파일 | 직접 수정 허용 |
|------|---------------|
| `../docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` | ✓ |

파괴적 변경(remove/rename/breaking) 시 subscriber 팀 전원 사전 합의 필수.

## 2개 화면 — 동일 Flutter 앱

| 화면 | 페르소나 | 역할 | 렌더링 |
|------|---------|------|--------|
| Command Center | Operator | 액션 버튼, 좌석 관리, RFID 카드 입력 | Flutter UI |
| Overlay | 무인 | holecards, pot, equity, animations + Skin Consumer | Rive Canvas |

## 소유 경로 (코드)

| 경로 | 내용 |
|------|------|
| `src/` | Flutter 소스 코드 (`ebs_cc` 프로젝트) |

## 엔진 연동

**권장 (Option A — Service)**: `http://localhost:8080/engine/*` (team3 `bin/harness.dart`)

**대안 (Option B — Path Dependency)**:
```yaml
dependencies:
  ebs_game_engine:
    path: ../team3-engine/ebs_game_engine
```

### ENGINE_URL 환경변수 (SG-002)

| 방법 | 문법 | 기본값 |
|------|------|--------|
| dart-define (권장) | `--dart-define=ENGINE_URL=http://host:port` | `http://localhost:8080` |
| launch_config JSON (보조) | BO 가 WS 로 푸시 | — |

```dart
const kEngineUrl = String.fromEnvironment('ENGINE_URL',
    defaultValue: 'http://localhost:8080');
```

### 3-stage 상태 머신 (SG-002)

| Stage | 조건 | UI | 사용자 행동 |
|:---:|------|----|------------|
| **Connecting** | 앱 시작 ~ 초기 연결 5초 내 | `SplashScreen` ("엔진 연결 중...") — router redirect 로 강제 진입 | 대기 |
| **Degraded** | 초기 연결 실패, 재시도 진행 중 (backoff 1s → 2s → 4s, 최대 3회) | CC UI 활성 + `EngineConnectionBanner` (orange 경고) + Demo Mode 자동 | 대기 or 계속 조작 |
| **Offline** | 재시도 3회 모두 실패 | `EngineConnectionBanner` (red, "ENGINE_URL 확인 필요" + "재연결" 버튼) — Demo Mode 유지 | 수동 재연결 or Demo Mode 지속 |
| **Online** | `/engine/health` 2xx | 배너 숨김 (`SizedBox.shrink`) | 정상 조작 |

**타임아웃**: `connectTimeout 5s / sendTimeout 3s / receiveTimeout 3s` (`engine_connection_provider.dart`).

### 구현 위치

| 책임 | 파일 |
|------|------|
| 상태 머신 | `src/lib/features/command_center/providers/engine_connection_provider.dart` |
| 배너 위젯 | `src/lib/features/command_center/widgets/engine_connection_banner.dart` |
| Splash | `src/lib/features/splash/splash_screen.dart` |
| Router redirect guard | `src/lib/routing/app_router.dart` (`AppRoutes.splash` + `refreshListenable`) |
| Stub 엔진 | `src/lib/features/command_center/services/stub_engine.dart` |

상세 계약: `../docs/2. Development/2.4 Command Center/Overlay/Engine_Dependency_Contract.md`

## 다른 팀이 소유하는 공통 계약 (읽기 전용)

| 계약 | 경로 | 소유 |
|------|------|------|
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `../docs/2. Development/2.5 Shared/Authentication.md` | conductor |
| API-04 Overlay Output | `../docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` | team3 |
| API-05 WebSocket | `../docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | team2 |
| API-06 Auth | `../docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | team2 |
| BS-08 Graphic Editor | `../docs/2. Development/2.1 Frontend/Graphic_Editor/` | team1 |
| DATA-07 .gfskin Schema | `../docs/2. Development/2.2 Backend/Database/` | team2 |

수정 필요 시 해당 문서를 직접 보강 (additive). decision_owner 는 publisher 팀.

## RFID HAL 규칙

`IRfidReader`는 추상 인터페이스:
- 실제 HAL (`ST25R3911BReader`) — 시리얼 UART, Phase 2 대응 (ST25R3916 마이그레이션 경로)
- 모의 HAL (`MockRfidReader`) — Phase 1 주력. 결정적 타이밍 + 장애 주입 API
- **의존성 주입 필수** — `rfidReaderProvider` Riverpod Provider로만 접근

## 인프라 구현 (소비자)

| 기능 | 요약 | 구현 위치 |
|------|------|---------|
| .gfskin | ZIP 포맷 단일화 | `lib/repositories/skin_repository.dart` |
| skin_updated | WebSocket 이벤트 | `lib/features/overlay/services/skin_consumer.dart` |
| Idempotency-Key | 헤더 자동 주입 | `lib/data/remote/bo_api_client.dart` Dio 인터셉터 |
| seq + replay | WebSocket 단조증가 검증 | `lib/foundation/utils/seq_tracker.dart` + `bo_websocket_client.dart` |

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다 (additive). Graphic Editor 관련 공백은 team1 이 `decision_owner` — 편집 시 team1 notify. decision_owner 는 `team-policy.json` 참조. 상세: `../CLAUDE.md` §"문서 변경 거버넌스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{1,2,3,5}*/`, `../docs/4. Operations/` 수정 금지 (다른 팀 소유)
- 다른 팀 코드 폴더(`../team1-frontend/`, `../team2-backend/`, `../team3-engine/ebs_game_engine/lib/`) 수정 금지
- **Graphic Editor UI 구현 금지** (team1 소유)
- IRfidReader 구현체 직접 인스턴스화 금지 (Riverpod DI 사용)
- `lib/features/overlay/layer2_push/` 영역 구현 금지 (Phase 2 영역)

## Build

- 테스트: `cd src && flutter test`
- 빌드: `cd src && flutter build windows --debug`
- 코드 생성: `cd src && dart run build_runner build --delete-conflicting-outputs`
