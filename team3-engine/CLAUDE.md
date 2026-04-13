# Team 3: Game Engine — CLAUDE.md

## Role

순수 Dart 포커 엔진 패키지. 22종 게임의 규칙/상태/평가 엔진.

**기술 스택**: Dart ^3.11.0 (순수 패키지 — Flutter/HTTP/IO 임포트 절대 금지)

## 소유 경로

| 경로 | 내용 |
|------|------|
| `ebs_game_engine/` | 소스 코드, 테스트, Dockerfile, 시나리오 |
| `specs/engine-spec/` | 20개 게임 스펙 (BS-06-00~BS-06-32) |
| `specs/games/` | PRD-GAME-01~04 (Confluence 발행 대상) |
| `qa/` | 게임 엔진 QA (QA-GE-00~10, spec-gap) |

## 엔진 코드 위치

```
ebs_game_engine/
├── lib/
│   ├── engine.dart          ← 메인 엔트리
│   ├── core/
│   │   ├── actions/         ← Action, Event, OutputEvent
│   │   ├── cards/           ← Card, Deck, HandEvaluator
│   │   ├── math/            ← EquityCalculator
│   │   ├── rules/           ← BetLimit, Showdown, StreetMachine
│   │   ├── state/           ← GameState, Seat, Pot, BettingRound
│   │   └── variants/        ← NLH, PLH, FLH, Omaha, ShortDeck 등 11종
│   └── harness/             ← 테스트 하네스 (HTTP 서버)
├── bin/
│   ├── harness.dart         ← HTTP 서비스 (port 8080)
│   └── replay.dart          ← 시나리오 리플레이 CLI
└── test/                    ← 30+ 테스트 파일
```

## 계약 준수 (읽기 전용)

| 계약 | 경로 | 준수 규칙 |
|------|------|----------|
| Hand FSM | `../../contracts/data/DATA-03-state-machines.md` | 엔진 FSM 상태 전이는 이 문서와 정확히 일치해야 함 |
| OutputEvent | `../../contracts/api/API-04-overlay-output.md` | 엔진이 발행하는 유일한 외부 인터페이스 |
| RFID 트리거 | `../../contracts/specs/BS-04-rfid/` | 트리거 반응 로직 참조용 (HAL 구현은 Team 4) |
| 공유 정의 | `../../contracts/specs/BS-00-definitions.md` | 공통 enum, status 값 |

## Harness 서비스

`bin/harness.dart` — port 8080 HTTP 서버
- Team 4 (CC)는 이 harness를 통해 엔진과 통신
- 통합 테스트도 이 엔드포인트를 호출

## 게임 PRD 규칙 (Confluence 발행)

`specs/games/` 문서는 Confluence 업로드 대상:
- Markdown 링크, 앵커 링크 금지
- 다른 문서명 언급 금지
- 각 문서는 독립 완결적이어야 함

## Spec Gap

`qa/QA-GE-10-spec-gap.md` — 형식: `GAP-GE-{NNN}`

## 금지

- Flutter, dart:io 서버, HTTP 패키지 임포트 금지 (순수 Dart만)
- `../../contracts/` 파일 수정 금지
- `../team1-frontend/`, `../team2-backend/`, `../team4-cc/` 접근 금지

## Build

- 테스트: `cd ebs_game_engine && dart test`
- 개별: `dart test test/phase1_ante_straddle_test.dart -v`
- Docker: `cd ebs_game_engine && docker-compose up`

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
