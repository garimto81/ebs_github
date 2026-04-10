| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | H2 Harness Server API 명세 초기 버전 |

## 개요

EBS Game Engine Interactive Simulator의 HTTP REST API 명세.
서버 (`lib/harness/server.dart`)와 웹 클라이언트 (`lib/harness/web/js/`) 모두 이 문서를 기준으로 구현한다.

**Base URL**: `http://localhost:{port}` (기본 8080, Docker 매핑에 따라 변경)

---

## 1. 세션 생성

### `POST /api/session`

새 게임 세션을 생성하고 자동으로 HandStart + DealHoleCards를 적용한다.

**Request Body**:

```json
{
  "variant": "nlh",
  "seatCount": 6,
  "stacks": [1000, 1000, 1000, 1000, 1000, 1000],
  "blinds": { "sb": 5, "bb": 10 },
  "dealerSeat": 0,
  "seed": 42,
  "config": {
    "anteType": null,
    "anteAmount": null,
    "straddleEnabled": false,
    "straddleSeat": null,
    "bombPotEnabled": false,
    "bombPotAmount": null,
    "canvasType": "broadcast",
    "sevenDeuceEnabled": false,
    "sevenDeuceAmount": null,
    "actionTimeoutMs": null
  }
}
```

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|:----:|--------|------|
| `variant` | string | N | `"nlh"` | 게임 변형 (GET /api/variants로 목록 조회) |
| `seatCount` | int | N | `6` | 좌석 수 (2~10) |
| `stacks` | int[] | N | `[1000 × seatCount]` | 좌석별 초기 스택. 단일 int 전달 시 전원 동일 |
| `blinds` | object | N | `{sb:5, bb:10}` | 블라인드 설정 (아래 형식 참조) |
| `dealerSeat` | int | N | `0` | 딜러 좌석 인덱스 |
| `seed` | int | N | `null` | 덱 셔플 시드 (null = 랜덤) |
| `config` | object | N | `{}` | H2 확장 설정 (아래 참조) |

**blinds 형식 (2가지 허용)**:

| 형식 | 예시 | 설명 |
|------|------|------|
| **이름 키** | `{"sb": 5, "bb": 10}` | SB/BB 금액. 좌석은 dealerSeat 기준 자동 계산 |
| **좌석 인덱스 키** | `{"1": 5, "2": 10}` | 좌석 번호에 직접 매핑 |

> 웹 UI는 이름 키 형식을 사용한다.

**config 필드**:

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `anteType` | int? | `null` | Ante 유형 (0~6). null이면 ante 없음 |
| `anteAmount` | int? | `null` | Ante 금액 |
| `straddleEnabled` | bool | `false` | Straddle 활성화 |
| `straddleSeat` | int? | `null` | Straddle 좌석 인덱스 |
| `bombPotEnabled` | bool | `false` | Bomb Pot 활성화 |
| `bombPotAmount` | int? | `null` | Bomb Pot 금액 |
| `canvasType` | string | `"broadcast"` | `"broadcast"` 또는 `"venue"` |
| `sevenDeuceEnabled` | bool | `false` | 7-2 Side Bet 활성화 |
| `sevenDeuceAmount` | int? | `null` | 7-2 Side Bet 금액 |
| `actionTimeoutMs` | int? | `null` | 액션 타임아웃 (ms). null이면 무제한 |

**Response** (201):

```json
{
  "sessionId": "mnr20wkam3",
  "variant": "NL Hold'em",
  "street": "preflop",
  "seats": [
    {
      "index": 0,
      "label": "Seat 1",
      "stack": 1000,
      "currentBet": 0,
      "status": "active",
      "holeCards": ["Tc", "Th"],
      "isDealer": true
    }
  ],
  "community": [],
  "pot": {
    "main": 15,
    "total": 15,
    "sides": []
  },
  "actionOn": 3,
  "dealerSeat": 0,
  "legalActions": [
    { "type": "fold" },
    { "type": "call", "callAmount": 10 },
    { "type": "raise", "minAmount": 20, "maxAmount": 1000 }
  ],
  "handNumber": 0,
  "anteType": null,
  "anteAmount": null,
  "straddleEnabled": false,
  "straddleSeat": null,
  "bombPotEnabled": false,
  "bombPotAmount": null,
  "canvasType": "broadcast",
  "sevenDeuceEnabled": false,
  "sevenDeuceAmount": null,
  "runItTimes": null,
  "actionTimeoutMs": null,
  "isAllInRunout": false,
  "eventCount": 2,
  "cursor": 2,
  "log": [
    "#0 HandStart dealer=0 blinds={1: 5, 2: 10}",
    "#1 DealHoleCards seats=[0, 1, 2, 3, 4, 5]"
  ]
}
```

---

## 2. 세션 조회

### `GET /api/session/{id}`

| 쿼리 파라미터 | 타입 | 설명 |
|---------------|------|------|
| `cursor` | int? | 이벤트 커서 (타임라인 리플레이). 생략 시 최신 상태 |

**Response** (200): 세션 생성과 동일한 JSON 구조.

---

## 3. 이벤트 적용

### `POST /api/session/{id}/event`

**Request Body** — `type` 필드로 이벤트 종류를 결정:

### 3.1 플레이어 액션

| type | 필수 필드 | 설명 |
|------|-----------|------|
| `fold` | `seatIndex` | 폴드 |
| `check` | `seatIndex` | 체크 |
| `call` | `seatIndex`, `amount` | 콜 |
| `bet` | `seatIndex`, `amount` | 베팅 |
| `raise` | `seatIndex`, `amount` | 레이즈 (amount = raise-to 금액) |
| `allin` | `seatIndex`, `amount` | 올인 |

```json
{ "type": "fold", "seatIndex": 3 }
{ "type": "call", "seatIndex": 3, "amount": 10 }
{ "type": "raise", "seatIndex": 3, "amount": 40 }
```

### 3.2 딜링

| type | 필수 필드 | 설명 |
|------|-----------|------|
| `deal_hole` | `cards` | 홀카드 딜. cards: `{"0": ["As","Ks"], "1": ["Qd","Qc"]}` |
| `deal_community` | `cards` | 커뮤니티 카드. cards: `["Ac","Kd","2c"]` |
| `street_advance` | `next` | 스트릿 전환. next: `"flop"`, `"turn"`, `"river"`, `"showdown"` |

```json
{ "type": "deal_community", "cards": ["Ac", "Kd", "2c"] }
{ "type": "street_advance", "next": "flop" }
```

### 3.3 핸드 관리

| type | 필수 필드 | 설명 |
|------|-----------|------|
| `pot_awarded` | `awards` | 팟 분배. awards: `{"0": 100, "2": 50}` |
| `hand_end` | — | 핸드 종료 |
| `misdeal` | — | 미스딜 (스택 복원, 팟 초기화) |
| `manual_next_hand` | — | 다음 핸드 준비 |
| `timeout_fold` | `seatIndex` | 타임아웃 폴드 |

```json
{ "type": "pot_awarded", "awards": { "0": 100 } }
{ "type": "misdeal" }
{ "type": "timeout_fold", "seatIndex": 2 }
```

### 3.4 H2 확장

| type | 필수 필드 | 설명 |
|------|-----------|------|
| `bomb_pot_config` | `amount` | Bomb Pot 설정 |
| `run_it_choice` | `times` | Run It Multiple (2 또는 3) |
| `muck` | `seatIndex`, `showCards` | 쇼다운 muck 결정 |
| `pineapple_discard` | `seatIndex`, `card` | 파인애플 디스카드 |

```json
{ "type": "bomb_pot_config", "amount": 50 }
{ "type": "run_it_choice", "times": 2 }
{ "type": "muck", "seatIndex": 1, "showCards": false }
{ "type": "pineapple_discard", "seatIndex": 0, "card": "Qh" }
```

**Response** (200): 이벤트 적용 후 세션 상태 JSON.

---

## 4. Undo

### `POST /api/session/{id}/undo`

마지막 이벤트 1개를 되돌린다. Request body 없음.

**Response** (200): Undo 후 세션 상태 JSON.

---

## 5. 저장

### `POST /api/session/{id}/save`

세션을 YAML 시나리오 파일로 저장한다.

**Response** (200):
```json
{ "saved": "scenarios/mnr20wkam3.yaml" }
```

---

## 6. 시나리오

### `GET /api/scenarios`

**Response** (200):
```json
{ "scenarios": ["01-nlh-basic-showdown", "02-nlh-preflop-all-fold"] }
```

### `POST /api/scenarios/{name}/load`

시나리오를 로드하고 모든 이벤트를 적용한 세션을 생성한다.

**Response** (201): 세션 상태 JSON.

---

## 7. 변형 목록

### `GET /api/variants`

**Response** (200):
```json
{
  "variants": ["nlh", "flh", "flh_2_4", "flh_5_10", "plh",
    "short_deck", "short_deck_triton", "pineapple",
    "omaha", "omaha_hilo", "five_card_omaha", "five_card_omaha_hilo",
    "six_card_omaha", "six_card_omaha_hilo", "courchevel", "courchevel_hilo"]
}
```

---

## 8. Equity 계산

### `GET /api/session/{id}/equity`

현재 상태에서 각 활성 플레이어의 승률을 Monte Carlo 시뮬레이션으로 계산한다.

**Response** (200):
```json
{
  "equity": { "0": 0.156, "1": 0.601, "2": 0.166, "3": 0.077 }
}
```

> 활성 플레이어가 2명 미만이면 `{"equity": {}}` 반환.

---

## 9. 카드 검증

### `GET /api/session/{id}/validate`

딜된 카드에 중복이 있는지 검증한다.

**Response** (200):
```json
{ "valid": true, "issues": [] }
```

중복 발견 시:
```json
{ "valid": false, "issues": ["Duplicate card at seat 2: As"] }
```

---

## 10. 쇼다운 순서

### `GET /api/session/{id}/showdown-order`

쇼다운 카드 공개 순서를 반환한다 (last aggressor first, 이후 딜러 좌측 시계방향).

**Response** (200):
```json
{ "revealOrder": [1, 2, 3, 0] }
```

---

## 11. All-in Runout 체크

### `GET /api/session/{id}/runout-check`

모든 활성 플레이어가 all-in 상태인지 확인한다.

**Response** (200):
```json
{ "isAllInRunout": false }
```

---

## 공통 에러 응답

| 상태 코드 | 조건 |
|-----------|------|
| 400 | 잘못된 요청 (알 수 없는 variant, 잘못된 이벤트 type 등) |
| 404 | 세션 또는 시나리오를 찾을 수 없음 |
| 500 | 서버 내부 오류 |

```json
{ "error": "Unknown variant: xyz" }
{ "error": "Session not found: abc123" }
```

---

## 카드 표기법

`{Rank}{Suit}` 형식. 대소문자 구분.

| Rank | `2` `3` `4` `5` `6` `7` `8` `9` `T` `J` `Q` `K` `A` |
|------|------|
| **Suit** | `s` (spade) `h` (heart) `d` (diamond) `c` (club) |

예: `As` = Ace of Spades, `Th` = Ten of Hearts, `2c` = Two of Clubs

---

## Seat Status 값

| 값 | 설명 |
|----|------|
| `active` | 핸드 진행 중 |
| `folded` | 폴드 |
| `allIn` | 올인 |
| `sittingOut` | 참여하지 않음 |

---

## Street 값

| 값 | 설명 |
|----|------|
| `setupHand` | 핸드 준비 (블라인드 포스팅 전) |
| `preflop` | 프리플랍 |
| `flop` | 플랍 |
| `turn` | 턴 |
| `river` | 리버 |
| `showdown` | 쇼다운 |
| `runItMultiple` | Run It Twice/Thrice 진행 중 |

---

## Ante Type 값

| 값 | 이름 | 설명 |
|----|------|------|
| `0` | Standard Ante | 전원 동일 금액 |
| `1` | Button Ante | 딜러만 전체 부담 |
| `2` | BB Ante | BB만 전체 부담 |
| `3` | BB Ante 1st | BB 전체 부담 + BB 첫 액션 |
| `4` | Live Ante | 전원, 첫 베팅으로 간주 |
| `5` | TB Ante | SB+BB 분담 |
| `6` | TB Ante 1st | SB+BB 분담 + SB 첫 액션 |
