# Team 3: Game Engine — CLAUDE.md (코드 전용)

## 🚀 표준 명령 (v3.0 이후)

모든 작업은 `/team` 스킬로:
```bash
/team "<task description>"
```
자동 수행: context detect → pre-sync → `/auto` → verify → commit → main ff-merge → push → report.
세션 시작/종료 불필요. 상세: `~/.claude/skills/team/SKILL.md`, `docs/4. Operations/Multi_Session_Workflow.md` v3.0

## 🎯 2026-04-21 이관 시 우선 작업 (MUST READ)

**전체 이관 가이드**: `docs/4. Operations/Multi_Session_Handoff.md` — 세션 시작 시 필독.

### team3 우선 작업 (기준 커밋 `7543452`)

1. **CCR-050 Clock FSM 세부 구체화** — `BS_Overview §3.7 ClockFSM` 스펙 준수 + engine 내 구현 검증. `team2 websocket publisher` (publish_clock_detail_changed / publish_clock_reload_requested) 와 정합
2. **NOTIFY-CCR-024 WriteGameInfo 22 필드 스키마** — `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` 의 21 OutputEvent 에서 WriteGameInfo 관련 payload 완결
3. **Draw 7종 + Stud 3종 variant 완결성** — `test/phase1~5` 에 기반 테스트 존재. 커버리지 검증 + 누락 edge case 보강
4. **HandEvaluator 완결성** — Low hand (Razz, Stud 8-or-better, Omaha Hi-Lo), Split pot, Sidepot 계산
5. **harness HTTP 인터페이스 안정화** — `bin/harness.dart` (port 8080) 를 team4 가 Option A HTTP 로 호출. `/engine/health` endpoint 추가 (team4 engine_connection_provider 가 health probe)

### 주요 도구

- `dart analyze C:/claude/ebs/team3-engine/ebs_game_engine` — 0 errors 유지 (현재 170 info/warning)
- `dart test` — 39 test file

### 현 baseline
- events drift: **완전 PASS** (21/21 D4)
- OutputEvent 21종 카탈로그 확정 (§6.0, 2026-04-15 실측 정정 반영)
- 순수 Dart 규칙: `lib/core/` 엄격 / `bin/harness.dart` + `lib/harness/` 만 `dart:io` 허용

### 금지 / 범위 밖

- Flutter import (lib/core)
- HTTP package import (lib/core — harness 만 허용)
- OutputEvent 신규 추가 시 `Overlay_Output_Events.md §6.0` 동시 업데이트 필수

---

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
