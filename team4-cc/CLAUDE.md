# Team 4: Command Center + Overlay — CLAUDE.md

## Role

Command Center (실시간 운영) + Overlay (방송 그래픽 출력, Skin Consumer)

**기술 스택**: Flutter/Dart + Rive 애니메이션 (WSOP Fatima.app 프로덕션 패턴: Riverpod + Dio/Retrofit + Freezed)

> Graphic Editor는 team1 Lobby(Quasar+rive-js) 소유 (CCR-011, 2026-04-10). team4는 `skin_updated` WebSocket 이벤트 수신 후 Overlay를 reload하는 **Skin Consumer** 역할이며, GE UI는 구현하지 않는다.

## 소유 경로

| 경로 | 내용 |
|------|------|
| `specs/BS-04-rfid/` | RFID UI 명세 (팀 내부 설계, contracts/에서 이관. 04-04 HAL은 contracts/ 잔류) |
| `specs/BS-05-command-center/` | CC 행동 명세 (팀 내부 설계, contracts/에서 이관) |
| `specs/BS-07-overlay/` | Overlay 행동 명세 (팀 내부 설계, contracts/에서 이관) |
| `specs/testing/TEST-PLAN.md` | 통합 테스트 계획 (§1 계획 §2 E2E §3 픽스처 §4 Mock §5 체크리스트 §6 감사 §7 전략). 2026-04-14 7개 → 1개 통합 |
| `ui-design/` | UI-02 (CC). Overlay 시퀀스는 `specs/BS-07-overlay/BS-07-08-sequences.md` 참조. 컴포넌트 정의는 Flutter 위젯 코드(`src/lib/widgets/`)가 SSOT |
| `ui-design/reference/action-tracker/EBS-AT-Reference.md` | PokerGFX Action Tracker 역설계 통합본 (2026-04-14 12개 → 1개 통합). Skin Editor 자료는 team1-frontend/ui-design/reference/skin-editor/ 이관 (CCR-011) |
| `src/` | Flutter 소스 코드 (`ebs_cc` 프로젝트) |

## 2개 화면 — 동일 Flutter 앱

| 화면 | 페르소나 | 역할 | 렌더링 |
|------|---------|------|--------|
| **Command Center** | Operator | 실시간 게임 진행 — 액션 버튼, 좌석 관리, RFID 카드 입력 | Flutter UI |
| **Overlay** | 무인 | 방송 그래픽 출력 — holecards, pot, equity, animations + Skin Consumer | **Rive Canvas** |

> CC는 Flutter 네이티브 UI, Overlay는 Rive Canvas 위젯으로 렌더링.
> Graphic Editor는 team1 Lobby 소유 (CCR-011). Overlay는 `skin_updated` WebSocket 이벤트 수신 시 BS-07-03 §5 기존 로드 FSM으로 새 `.gfskin` ZIP을 in-memory 압축 해제하여 리렌더.

## 엔진 연동

**권장 (Option A — Service)**:
```
Engine Harness: http://localhost:8080/engine/*
```
Team 3의 `bin/harness.dart`가 HTTP 서비스로 엔진을 노출.
버전 격리 + 독립 배포 가능.

**대안 (Option B — Path Dependency)**:
```yaml
# pubspec.yaml
dependencies:
  ebs_game_engine:
    path: ../team3-engine/ebs_game_engine
```
직접 호출, 타입 안전하지만 team3 HEAD에 즉시 영향받음.

## 계약 참조 (읽기 전용)

| 계약 | 경로 | 이 팀의 역할 |
|------|------|-------------|
| RFID HAL | `../../contracts/api/API-03-rfid-hal-interface.md` | IRfidReader 구현 (DI 필수, CCR-022 UART 생명주기) |
| OutputEvent | `../../contracts/api/API-04-overlay-output.md` | Overlay가 소비 + 렌더링 (CCR-036 Security Delay) |
| WebSocket CC | `../../contracts/api/API-05-websocket-events.md` | CC 채널 send/receive + `skin_updated` 수신 + `seq`/replay (CCR-015, CCR-021) |
| BS-04 RFID | `../../contracts/specs/BS-04-rfid/` | Deck 등록 (BS-04-05 AT-05), 카드 감지, Mock 우선 |
| BS-05 CC | `../../contracts/specs/BS-05-command-center/` | 핸드 라이프사이클, 액션 버튼, AT-00~AT-07 8화면, Multi-Table (CCR-024~032) |
| BS-07 Overlay | `../../contracts/specs/BS-07-overlay/` | 8 Layer 1 요소, 시각 규격, Audio (BS-07-05), Layer 경계 (BS-07-06), Security Delay (BS-07-07) |
| BS-08 Graphic Editor | `../../contracts/specs/BS-08-graphic-editor/` | **읽기 전용** (team1 소유, CCR-011). Overlay가 skin_updated 수신 시 참고 |
| BS-03 Settings | `../../contracts/specs/BS-03-settings/` | Overlay/Skin 시각 설정 탭 (BS-03-02 gfx, CCR-025) 소비 |
| DATA-07 .gfskin Schema | `../../contracts/data/DATA-07-gfskin-schema.md` | Overlay ZIP 로드 시 JSON Schema 검증 (CCR-012) |

## RFID HAL 규칙

`IRfidReader`는 추상 인터페이스 (API-03 §HAL Interface):
- 실제 HAL (`ST25R3911BReader`) — 시리얼 UART, Phase 2 대응 (CCR-022 §ST25R3916 마이그레이션 경로 준수)
- 모의 HAL (`MockRfidReader`) — Phase 1 주력. 결정적 타이밍 + 장애 주입 API
- **의존성 주입 필수** — `rfidReaderProvider` Riverpod Provider로만 접근. 비즈니스 로직에서 구현체 직접 인스턴스화 금지.

## 인프라 수용 CCR (소비자 구현 필수)

| CCR | 요약 | Team 4 구현 위치 |
|-----|------|---------------|
| CCR-012 | `.gfskin` ZIP 포맷 단일화 | `lib/repositories/skin_repository.dart` — in-memory 압축 해제 |
| CCR-015 | `skin_updated` WebSocket 이벤트 | `lib/features/overlay/services/skin_consumer.dart` |
| CCR-019 | Idempotency-Key 헤더 표준 | `lib/data/remote/bo_api_client.dart` Dio 인터셉터 |
| CCR-021 | WebSocket `seq` 단조증가 + replay | `lib/foundation/utils/seq_tracker.dart` + `bo_websocket_client.dart` |

## Spec Gap (CCR-first)

- **contracts/ 변경 필요 시**: 먼저 `../docs/05-plans/ccr-inbox/CCR-DRAFT-team4-YYYYMMDD-slug.md` 작성 (**필수**).
  QA Gap 문서(`qa/commandcenter/spec-gap.md`)에는 "CCR-DRAFT-XXX 제출됨" pointer + 임시 구현 1줄만 기록. 장문 근거는 CCR-DRAFT 본문에만.
- **팀 내부 판단만 필요 시** (contracts/ 영향 없음): QA Gap 문서에 직접 기록.
- CC 형식: `GAP-CC-{NNN}` — `qa/commandcenter/spec-gap.md`
- Graphic Editor: **team1 소유** (`team1-frontend/qa/graphic-editor/`). team4에서 GE Gap 기록 금지.
- 상세 절차: `../CLAUDE.md` §"Spec Gap 프로세스 (CRITICAL — CCR-first)" 참조.

## 금지

- `../../contracts/` 파일 수정 금지 (CCR-DRAFT는 `docs/05-plans/ccr-inbox/CCR-DRAFT-team4-*.md` 형식으로만 제안)
- `../team3-engine/ebs_game_engine/lib/` 코드 직접 수정 금지 (엔진은 의존성)
- `../team1-frontend/`, `../team2-backend/` 접근 금지
- **Graphic Editor UI 구현 금지** — team1 소유 (CCR-011). `../team1-frontend/src/screens/lobby/graphic-editor/` 접근 금지
- IRfidReader 구현체 직접 인스턴스화 금지 (Riverpod DI 사용)
- `lib/features/overlay/layer2_push/` 영역 구현 금지 — Phase 2 범위 외 (CCR-035 Layer 경계)

## Build

- 테스트: `cd src && flutter test`
- 빌드: `cd src && flutter build windows --debug` (또는 macos/linux)
- 코드 생성: `cd src && dart run build_runner build --delete-conflicting-outputs`

---

## 문서 동기화 규칙

### 문서 계층
- **L0 계약** (contracts/): 읽기 전용, Conductor 소유. 이 팀은 수정 불가.
- **L1 파생** (이 팀의 ui-design/, qa/, 구현 가이드): 이 팀 소유. contracts/ 기준 일관성은 AI 책임.

### 사용자의 동기화 지시 시
1. 지정된 contracts/ 파일 Read
2. 자기 파생 문서와 비교 → 불일치 수정 (contracts/가 맞음)
3. 변경 사항 보고

### 파생 문서 생성/수정 시
- 반드시 contracts/ 참조하여 일관성 확인
- contracts/와 다르면 → CCR draft 제출 (contracts/ 직접 수정 금지)
- 파생 문서 = 인간이 읽지 않는 AI 산출물 (일관성은 AI 책임)

### 금지
- contracts/와 불일치하는 파생 문서 생성 금지
- 불일치 발견 시 "어느 쪽이 맞나요?" 질문 금지 (contracts/가 맞음, 파생 문서 수정)
- 파생 문서(ui-design/, qa/, LLD)를 인간에게 읽으라고 제시 금지
