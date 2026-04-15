# Team 4: Command Center + Overlay — CLAUDE.md (코드 전용)

## Role

Command Center (실시간 운영) + Overlay (방송 그래픽 출력, Skin Consumer)

**기술 스택**: Flutter/Dart + Rive 애니메이션 (WSOP Fatima.app 프로덕션 패턴: Riverpod + Dio/Retrofit + Freezed)

**Publisher**: RFID HAL (API-03).

> Graphic Editor는 team1 Lobby 소유 (CCR-011). team4는 `skin_updated` WebSocket 이벤트 수신 후 Overlay 를 reload 하는 **Skin Consumer**. GE UI 구현 금지.

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
| Spec Gaps | `../docs/2. Development/2.4 Command Center/Spec_Gaps.md` |
| Backlog | `../docs/2. Development/2.4 Command Center/Backlog.md` |

### Publisher Fast-Track

team4는 RFID HAL 을 직접 수정 가능:

| 파일 | 직접 수정 허용 |
|------|---------------|
| `../docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` | ✓ |

**단**, 수정 후 `python ../tools/ccr_validate_risk.py --draft <파일명>` 실행 필수.

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

## 다른 팀이 소유하는 공통 계약 (읽기 전용)

| 계약 | 경로 | 소유 |
|------|------|------|
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `../docs/2. Development/2.5 Shared/Authentication.md` | conductor |
| API-04 Overlay Output | `../docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` | team3 |
| API-05 WebSocket | `../docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | team2 |
| API-06 Auth | `../docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | team2 |
| BS-08 Graphic Editor | `../docs/2. Development/2.1 Frontend/Graphic_Editor/` | team1 (CCR-011) |
| DATA-07 .gfskin Schema | `../docs/2. Development/2.2 Backend/Database/` | team2 |

수정 필요 시 CR 프로세스 경유 (`../docs/3. Change Requests/pending/CR-team4-*.md`).

## RFID HAL 규칙

`IRfidReader`는 추상 인터페이스:
- 실제 HAL (`ST25R3911BReader`) — 시리얼 UART, Phase 2 대응 (CCR-022 §ST25R3916 마이그레이션 경로)
- 모의 HAL (`MockRfidReader`) — Phase 1 주력. 결정적 타이밍 + 장애 주입 API
- **의존성 주입 필수** — `rfidReaderProvider` Riverpod Provider로만 접근

## 인프라 CCR 구현 (소비자)

| CCR | 요약 | 구현 위치 |
|-----|------|---------|
| CCR-012 | `.gfskin` ZIP 포맷 단일화 | `lib/repositories/skin_repository.dart` |
| CCR-015 | `skin_updated` WebSocket 이벤트 | `lib/features/overlay/services/skin_consumer.dart` |
| CCR-019 | Idempotency-Key 헤더 | `lib/data/remote/bo_api_client.dart` Dio 인터셉터 |
| CCR-021 | WebSocket `seq` + replay | `lib/foundation/utils/seq_tracker.dart` + `bo_websocket_client.dart` |

## Spec Gap (CCR-first)

- **Shared/다른 팀 경로 변경 필요 시**: CR draft 먼저. Spec_Gaps.md 에는 pointer + 임시 구현 1줄만.
- **팀 내부 판단만 필요 시**: Spec_Gaps.md 에 직접.
- CC 형식: `GAP-CC-{NNN}`
- Graphic Editor: team1 소유. team4에서 GE Gap 기록 금지.
- 상세: `../CLAUDE.md` §"Spec Gap 프로세스"

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{1,2,3,5}*/`, `../docs/3. Change Requests/{in-progress,done}/`, `../docs/4. Operations/` 수정 금지
- 다른 팀 코드 폴더(`../team1-frontend/`, `../team2-backend/`, `../team3-engine/ebs_game_engine/lib/`) 수정 금지
- **Graphic Editor UI 구현 금지** (CCR-011 — team1 소유)
- IRfidReader 구현체 직접 인스턴스화 금지 (Riverpod DI 사용)
- `lib/features/overlay/layer2_push/` 영역 구현 금지 (CCR-035 Phase 2 외)

## Build

- 테스트: `cd src && flutter test`
- 빌드: `cd src && flutter build windows --debug`
- 코드 생성: `cd src && dart run build_runner build --delete-conflicting-outputs`
