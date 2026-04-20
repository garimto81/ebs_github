# Team 3: Game Engine — CLAUDE.md (코드 전용)

## 브랜치 규칙

- **작업 브랜치**: `work/team3/{YYYYMMDD}-session` (SessionStart hook 자동 생성)
- **main 직접 작업 금지** — commit/push 차단됨
- **병합**: `/team-merge` 커맨드로만 main 병합 (Conductor 세션 권장)

## Role

순수 Dart 포커 엔진 패키지. 22종 게임의 규칙/상태/평가 엔진.

**기술 스택**: Dart ^3.11.0 — `lib/` 엔진 코어는 순수 Dart (Flutter/HTTP/IO 임포트 금지). `bin/harness.dart` 와 `lib/harness/` 는 외부 인터페이스 제공 위해 `dart:io` HTTP 서버 허용 (SG-001 resolution 2026-04-20, BS_Overview §1 참조)

**Publisher**: API-04 Overlay Output Events (유일한 외부 인터페이스).

---

## 문서 위치 (docs v10)

**팀 문서는 모두 `docs/2. Development/2.3 Game Engine/` 에 있다. 이 폴더는 코드 전용.**

| 문서 카테고리 | 경로 |
|--------------|------|
| 섹션 landing | `../docs/2. Development/2.3 Game Engine/2.3 Game Engine.md` |
| APIs (publisher) | `../docs/2. Development/2.3 Game Engine/APIs/` |
| Behavioral Specs (BS-06-*) | `../docs/2. Development/2.3 Game Engine/Behavioral_Specs/` |
| Holdem 상세 | `../docs/2. Development/2.3 Game Engine/Behavioral_Specs/Holdem/` |
| Game Rules (Confluence 발행) | `../docs/1. Product/Game_Rules/` |
| Backlog | `../docs/2. Development/2.3 Game Engine/Backlog.md` |

### Publisher 직접 편집 권한

team3은 API-04 OutputEvent 를 직접 수정 가능:

| 파일 | 직접 수정 허용 |
|------|---------------|
| `../docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` | ✓ |

파괴적 변경(remove/rename/breaking) 시 subscriber 팀 전원 사전 합의 필수.

## 소유 경로 (코드)

| 경로 | 내용 |
|------|------|
| `ebs_game_engine/lib/` | 엔진 소스 코드 |
| `ebs_game_engine/bin/` | `harness.dart` (HTTP 서비스 port 8080), `replay.dart` CLI |
| `ebs_game_engine/test/` | 30+ 테스트 파일 |
| `ebs_game_engine/Dockerfile`, `docker-compose.yml` | 컨테이너 |

### 엔진 코드 구조

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
│   │   └── variants/        ← NLH, PLH, FLH, Omaha, ShortDeck 등
│   └── harness/
├── bin/
└── test/
```

## 다른 팀이 소유하는 공통 계약 (읽기 전용)

| 계약 | 경로 | 소유 |
|------|------|------|
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| API-03 RFID HAL | `../docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` | team4 |
| DATA Schema (FSM 등) | `../docs/2. Development/2.2 Backend/Database/Schema.md` | team2 |

수정 필요 시 해당 문서를 직접 보강 (additive). decision_owner 는 publisher 팀.

## Harness 서비스

`bin/harness.dart` — port 8080 HTTP 서버. team4 (CC) 와 통합 테스트가 이 엔드포인트를 호출.

## Game Rules (Confluence 발행 규칙)

`docs/1. Product/Game_Rules/` 문서는 Confluence 업로드 대상:
- Markdown 링크, 앵커 링크 금지
- 다른 문서명 언급 금지
- 각 문서는 독립 완결적

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다 (additive). decision_owner 는 `team-policy.json` 참조. 상세: `../CLAUDE.md` §"문서 변경 거버넌스".

## 금지

- **엔진 코어 `lib/core/`, `lib/engine.dart`**: Flutter, `dart:io` 서버, HTTP 패키지 임포트 금지 (순수 Dart만)
- **예외**: `bin/harness.dart`, `lib/harness/**` 는 외부 인터페이스(HTTP 서비스) 제공 위해 `dart:io` 허용 (BS_Overview §1 SSOT / SG-001 resolution)
- `../docs/1. Product/`, `../docs/2. Development/2.{1,2,4,5}*/`, `../docs/4. Operations/` 수정 금지 (다른 팀 소유)
- 다른 팀 코드 폴더(`../team1-frontend/`, `../team2-backend/`, `../team4-cc/`) 접근 금지

## Build

- 테스트: `cd ebs_game_engine && dart test`
- 개별: `dart test test/phase1_ante_straddle_test.dart -v`
- Docker: `cd ebs_game_engine && docker-compose up`
