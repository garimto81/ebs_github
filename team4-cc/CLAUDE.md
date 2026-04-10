# Team 4: CC + Overlay + Graphic Editor — CLAUDE.md

## Role

Command Center (실시간 운영) + Overlay (방송 그래픽 출력) + Graphic Editor (Skin/Overlay 편집)

**기술 스택**: Flutter/Dart + Rive 애니메이션

## 소유 경로

| 경로 | 내용 |
|------|------|
| `specs/testing/` | 테스트 전략 (TEST-01~07) |
| `qa/commandcenter/` | CC QA (QA-CC-00~02) |
| `qa/graphic-editor/` | Graphic Editor QA (QA-GE-00~02) |
| `ui-design/` | UI-02 (CC), UI-04 (Overlay), UI-05 (Component Library), UI-06 (Skin Editor) |
| `src/` | Flutter 소스 코드 |

## 3개 앱 — 동일 Flutter 프로젝트

| 앱 | 페르소나 | 역할 |
|-----|---------|------|
| **Command Center** | Operator | 실시간 게임 진행 — 액션 버튼, 좌석 관리, RFID 카드 입력 |
| **Overlay** | 무인 | 방송 그래픽 출력 — holecards, pot, equity, animations |
| **Graphic Editor** | Admin | Skin/Overlay 시각 편집 — Rive 애니메이션 설정, 레이아웃, 색상 |

> Graphic Editor는 Flutter/Rive 렌더링이 필수이므로 React 기반 Team 1이 아닌 이 팀에 소속.

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
| RFID HAL | `../../contracts/api/API-03-rfid-hal-interface.md` | IRfidReader 구현 (DI 필수) |
| OutputEvent | `../../contracts/api/API-04-overlay-output.md` | Overlay가 소비 + 렌더링 |
| WebSocket CC | `../../contracts/api/API-05-websocket-events.md` | CC 채널 send/receive |
| BS-04 RFID | `../../contracts/specs/BS-04-rfid/` | Deck 등록, 카드 감지 구현 |
| BS-05 CC | `../../contracts/specs/BS-05-command-center/` | 핸드 라이프사이클, 액션 버튼 |
| BS-07 Overlay | `../../contracts/specs/BS-07-overlay/` | 요소, 애니메이션, 스킨 로딩 |
| BS-03 Settings | `../../contracts/specs/BS-03-settings/` | Overlay/Skin 탭 (시각 설정 부분) |

## RFID HAL 규칙

`IRfidReader`는 추상 인터페이스:
- 실제 HAL (`RfidReader`) — 시리얼 UART via Flutter 플러그인
- 모의 HAL (`MockRfidReader`) — 테스트/개발용
- **의존성 주입 필수** — 비즈니스 로직에서 구현체 직접 인스턴스화 금지

## Spec Gap

- CC: `qa/commandcenter/` — 형식: `GAP-CC-{NNN}`
- Graphic Editor: `qa/graphic-editor/` — 형식: `GAP-GE-{NNN}`

## 금지

- `../../contracts/` 파일 수정 금지
- `../team3-engine/ebs_game_engine/lib/` 코드 직접 수정 금지 (엔진은 의존성)
- `../team1-frontend/`, `../team2-backend/` 접근 금지
- IRfidReader 구현체 직접 인스턴스화 금지 (DI 사용)

## Build

- 테스트: `cd src && flutter test`
- 빌드: `cd src && flutter build`
