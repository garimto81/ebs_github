---
title: CR-team4-20260410-api05-writegameinfo-schema
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-api05-writegameinfo-schema
---

# CCR-DRAFT: API-05 WriteGameInfo 프로토콜 22+ 필드 스키마 완전 명세

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2, team3]
- **변경 대상 파일**: contracts/api/`WebSocket_Events.md` (legacy-id: API-05), contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md
- **변경 유형**: modify
- **변경 근거**: CCR-018(BS-05 서버 프로토콜 매핑)에서 `WriteGameInfo` 프로토콜을 NEW HAND 버튼 매핑으로 명시하며 "22+ 필드"라고만 기술하고 실제 필드 목록은 누락했다. 이는 CCR-018의 미완 부분이며, Team 2가 WriteGameInfo 핸들러를 구현할 때 필드 이름/타입/필수 여부를 임의로 결정할 위험이 있다. WSOP 원본 PokerGFX 역설계(`team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md` §I-4 Blind 자동화)에 따르면 WriteGameInfo는 블라인드 자동화의 핵심 프로토콜이며, 필드 누락은 자동화 실패로 직결된다. 본 CCR은 22+ 필드 전체 스키마를 계약으로 확정한다.

## 변경 요약

1. API-05에 `WriteGameInfo` 프로토콜 전체 필드 스키마 추가 (24개 필드)
2. BS-05-02-action-buttons §서버 프로토콜 매핑의 WriteGameInfo 행에 API-05 참조 링크 보강

## 변경 내용

### 1. API-05 §WriteGameInfo 프로토콜 스키마 (신규 섹션)

```markdown
## WriteGameInfo 프로토콜

### 용도

CC의 NEW HAND 버튼이 서버에 발행하는 핸드 초기화 명령. Game Engine의 핸드 FSM을 
IDLE → SETUP_HAND으로 전이시키며, 블라인드 구조/포지션/특수 규칙을 1회 명령으로 확정한다.

- **발행자**: CC (BS-05-02 NEW HAND 버튼)
- **수신자**: BO → Game Engine
- **응답**: `GameInfoAck { hand_id }` 또는 `GameInfoRejected { reason }`

### 필드 스키마 (24개)

```json
{
  "type": "WriteGameInfo",
  "payload": {
    "table_id": 5,
    "hand_id": 248,
    "dealer_seat": 3,
    "sb_seat": 4,
    "bb_seat": 5,
    "sb_amount": 500,
    "bb_amount": 1000,
    "ante_amount": 100,
    "big_blind_ante": false,
    "straddle_seats": [6],
    "straddle_amount": 2000,
    "blind_structure_id": "wsop-ft-2026-lv42",
    "blind_level": 42,
    "current_level_start_ts": "2026-04-10T14:30:00Z",
    "next_level_start_ts": "2026-04-10T14:50:00Z",
    "game_type": "no_limit_holdem",
    "allowed_games": ["nlhe"],
    "rotation_order": null,
    "chip_denominations": [100, 500, 1000, 5000, 25000, 100000],
    "active_seats": [1, 2, 3, 4, 5, 6, 7, 8],
    "dead_button_mode": true,
    "run_it_multiple_allowed": true,
    "bomb_pot_enabled": false,
    "cap_bb_multiplier": null
  },
  "timestamp": "2026-04-10T14:30:00.123Z",
  "source_id": "cc-table-5",
  "message_id": "msg-uuid-1234"
}
```

### 필드 정의

| # | 필드 | 타입 | 필수 | 설명 |
|:-:|------|------|:----:|------|
| 1 | `table_id` | int | O | 테이블 식별자 |
| 2 | `hand_id` | int | O | 핸드 식별자 (핸드 시작 전 Backend에서 할당) |
| 3 | `dealer_seat` | int (0~9) | O | Dealer button 좌석 |
| 4 | `sb_seat` | int (0~9) | O | Small Blind 좌석 |
| 5 | `bb_seat` | int (0~9) | O | Big Blind 좌석 |
| 6 | `sb_amount` | int | O | Small Blind 금액 |
| 7 | `bb_amount` | int | O | Big Blind 금액 |
| 8 | `ante_amount` | int | O | Ante 금액 (0이면 없음) |
| 9 | `big_blind_ante` | bool | O | true면 BB가 전체 ante 선납 |
| 10 | `straddle_seats` | int[] | O | Straddle 활성 좌석 (빈 배열이면 없음) |
| 11 | `straddle_amount` | int | △ | Straddle 금액 (straddle_seats 존재 시 필수) |
| 12 | `blind_structure_id` | string | O | 블라인드 구조 ID (BS-02 Lobby가 생성) |
| 13 | `blind_level` | int | O | 현재 레벨 번호 (1부터) |
| 14 | `current_level_start_ts` | ISO 8601 | O | 현재 레벨 시작 시각 |
| 15 | `next_level_start_ts` | ISO 8601 | O | 다음 레벨 시작 예정 시각 |
| 16 | `game_type` | enum | O | `no_limit_holdem` / `pot_limit_holdem` / `limit_holdem` / `plo` / `mix` |
| 17 | `allowed_games` | string[] | O | Mix 게임 시 허용 종목 리스트 (`game_type == "mix"` 시) |
| 18 | `rotation_order` | string[] \| null | △ | Mix 게임 순환 순서 (null이면 랜덤) |
| 19 | `chip_denominations` | int[] | O | 테이블 가용 토큰 단위 |
| 20 | `active_seats` | int[] | O | 현재 핸드에 참여하는 좌석 (Sitting Out 제외) |
| 21 | `dead_button_mode` | bool | O | Dead Button Rule 적용 여부 |
| 22 | `run_it_multiple_allowed` | bool | O | Run It Multiple(X2/X3) 허용 여부 |
| 23 | `bomb_pot_enabled` | bool | O | 이 핸드가 Bomb Pot인지 |
| 24 | `cap_bb_multiplier` | int \| null | O | Cap Game BB 배수 (null = 무제한) |

### 검증 규칙

- `dealer_seat`, `sb_seat`, `bb_seat`는 `active_seats`에 포함되어야 함
- `straddle_seats`는 `active_seats`의 부분집합
- `sb_amount < bb_amount < straddle_amount` (Straddle 존재 시)
- `game_type == "mix"`이면 `allowed_games` 최소 2개 필수
- `current_level_start_ts < next_level_start_ts`

### 응답

#### 성공: `GameInfoAck`

```json
{
  "type": "GameInfoAck",
  "payload": {
    "hand_id": 248,
    "ready_for_deal": true,
    "estimated_deal_ready_ts": "2026-04-10T14:30:00.200Z"
  }
}
```

CC는 이 응답 수신 후 DEAL 버튼을 활성화한다.

#### 실패: `GameInfoRejected`

```json
{
  "type": "GameInfoRejected",
  "payload": {
    "hand_id": 248,
    "error_code": 4001,
    "reason": "dealer_seat 3 is not in active_seats"
  }
}
```

### 에러 코드

| 코드 | 설명 |
|:----:|------|
| 4001 | 좌석 검증 실패 (dealer/sb/bb 부재) |
| 4002 | 블라인드 금액 순서 오류 |
| 4003 | Mix 게임 필드 누락 |
| 4004 | Blind structure ID 미존재 |
| 4005 | 이전 핸드가 미완료 상태 |
| 4006 | Table FSM이 LIVE 아님 |
| 4999 | 기타 (reason 필수) |

### Mock 모드 (Engine Harness)

Engine Harness는 `WriteGameInfo` 수신 시 즉시 `GameInfoAck` 응답 (결정적).
테스트용 에러 주입 API:

- `POST /engine/mock/inject_game_info_rejection { error_code, reason }`
```

### 2. BS-05-02-action-buttons.md §서버 프로토콜 매핑 업데이트

CCR-018에서 추가한 표의 NEW HAND 행을 업데이트:

```diff
-| NEW HAND | WriteGameInfo | hand_id, dealer_seat, sb/bb/ante, ... (22+) |
+| NEW HAND | WriteGameInfo | 24개 필드 (API-05 §WriteGameInfo 프로토콜 참조) |
```

## 영향 분석

### Team 2 (Backend)
- **영향**:
  - BO에서 `WriteGameInfo` 파서 구현 (24필드 검증)
  - Game Engine에 전달하기 전 DB/캐시에서 Blind structure 조회
  - `GameInfoAck` / `GameInfoRejected` 응답 반환
  - 에러 코드 4001~4999 처리
- **예상 작업 시간**: 12시간

### Team 3 (Game Engine)
- **영향**:
  - Engine이 `WriteGameInfo`의 24필드를 모두 수용하여 `HandFSM.startHand(...)` 호출
  - Mix 게임 필드(`allowed_games`, `rotation_order`)를 기반으로 게임 전환 로직 수행
  - Engine Harness Mock 응답 구현
- **예상 작업 시간**: 16시간

### Team 4 (self)
- **영향**:
  - BS-05-02 NEW HAND 버튼에서 24필드를 모두 수집/전송
  - `GameInfoRejected` 수신 시 에러 코드 기반 UI 피드백
  - Mock 모드에서 결정적 응답 활용 테스트
- **예상 작업 시간**: 8시간

### 마이그레이션
- 없음 (API-05 신규 프로토콜 정의이므로 기존 이벤트 영향 없음)

## 대안 검토

### Option 1: 필드 스키마 미명시 (현행 유지)
- **단점**: 각 팀이 임의로 필드 결정 → 통합 테스트에서 필드 불일치 발견
- **채택**: ❌

### Option 2: 24필드 완전 명세 (본 제안)
- **장점**: 
  - Team 2/3/4가 1:1 일치 구현 가능
  - WSOP 원본 Blind 자동화 설계 충실 반영
  - Mock 응답 결정적 → 테스트 재현성
- **채택**: ✅

### Option 3: 최소 필드 12개만 명세 (Phase 1), 나머지는 Phase 2
- **단점**: 
  - Mix 게임, Cap Game, Bomb Pot 등이 Phase 2로 미뤄짐
  - DATA-02 Entities에 이미 `allowed_games`, `rotation_order` 필드 존재 → Phase 1에 반드시 전송해야 함
- **채택**: ❌

## 검증 방법

### 1. 스키마 일관성
- [ ] DATA-02 Entities의 Hand/Table 엔티티 필드와 1:1 매핑 확인
- [ ] BS-00 Definitions의 게임 상태 enum과 `game_type` 필드 값 일치

### 2. 검증 규칙 테스트
- [ ] `dealer_seat`가 `active_seats`에 없는 payload → `error_code: 4001` 반환
- [ ] `sb_amount >= bb_amount` payload → `error_code: 4002` 반환
- [ ] `game_type: "mix"` + `allowed_games: []` payload → `error_code: 4003` 반환

### 3. Mock 결정성
- [ ] Engine Harness에 동일 WriteGameInfo 10회 전송 → 모두 동일 `GameInfoAck` 응답
- [ ] Mock 에러 주입 API로 각 에러 코드 시뮬레이션

### 4. BS-05-02 연동
- [ ] CC NEW HAND 버튼 → WriteGameInfo 전송 → GameInfoAck 수신 → DEAL 버튼 활성화 E2E 시나리오

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (파서, 검증, 에러 응답)
- [ ] Team 3 기술 검토 (Engine 수용, Mock 응답)
- [ ] Team 4 기술 검토 (CC 필드 수집 UI)
