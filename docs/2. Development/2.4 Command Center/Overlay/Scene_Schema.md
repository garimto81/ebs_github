---
title: Scene Schema
owner: team4
tier: internal
legacy-id: BS-07-04
last-updated: 2026-04-15
confluence-page-id: 3818947217
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947217/EBS+Scene+Schema
---

# BS-07-04 Scene Schema — 씬 JSON 스키마

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 씬 스키마 정의, 필드 상세, 버전 관리, 스냅샷 API |
| 2026-04-21 | Hand History 경계 명시 | Lobby `Hand_History.md` 화면 데이터는 본 Scene Schema 의 일부가 **아님**. Hand History 는 Lobby 내부 운영 도구이며 시청자 송출되지 않는다 (`Layer_Boundary.md` §1.4 참조). Hand 데이터의 시청자 송출은 기존 HoleCards/Board/Action Badge/Winner 그래픽 (§3 Layer 1) 만 담당 |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — Scene JSON 의 element 좌표/치수는 5-Act 시퀀스의 각 Act 별 element visibility (Act 별 활성/비활성) 기준으로 설계. SSOT: `Sequences.md §"v4.0 5-Act → Overlay 매핑"`. |

---

## 개요

이 문서는 Overlay가 렌더링하는 **전체 상태의 직렬화 포맷**(Scene JSON Schema)을 정의한다. 씬 스키마는 특정 시점의 Overlay 상태를 완전히 기술하는 JSON 구조로, 스냅샷 저장, 리플레이, 테스트 검증에 사용된다.

> **참조**: 게임 상태 Enum은 `Behavioral_Specs/Overview.md` (legacy-id: BS-06-00). 오버레이 요소는 `Elements.md` (legacy-id: BS-07-01). 스킨 구조는 `Skin_Loading.md` (legacy-id: BS-07-03).

---

## 1. 용도

| 용도 | 설명 |
|------|------|
| **스냅샷 저장** | 특정 시점의 Overlay 상태를 파일로 저장하여 이후 복원 |
| **리플레이** | 저장된 스냅샷 시퀀스를 순차 재생하여 핸드 복기 |
| **테스트 검증** | 예상 씬 JSON과 실제 렌더링 상태를 비교하여 자동 테스트 |
| **디버깅** | 문제 발생 시 해당 시점의 전체 상태 덤프 |

---

## 2. 최상위 구조

```json
{
  "schema_version": "1.0",
  "timestamp": "2026-04-08T14:32:15.123Z",
  "table_id": 1,
  "hand_number": 47,
  "game_type": 0,
  "game_phase": "FLOP",
  "game_phase_value": 3,
  "skin": "wsop-2026-default",
  "elements": {
    "board": [],
    "players": [],
    "pot": {},
    "equity_bars": [],
    "hand_ranks": [],
    "dealer_button": {},
    "lower_third": {},
    "action_badges": []
  },
  "animations": {},
  "output": {}
}
```

### 최상위 필드 정의

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `schema_version` | string | Y | 스키마 버전 (SemVer) |
| `timestamp` | string (ISO 8601) | Y | 스냅샷 생성 시각 |
| `table_id` | int | Y | 테이블 ID |
| `hand_number` | int | Y | 현재 핸드 번호 (IDLE 시 마지막 핸드) |
| `game_type` | int | Y | 게임 종류 enum (BS-06-00-REF §1.1) |
| `game_phase` | string | Y | 현재 게임 단계 (가독성용) |
| `game_phase_value` | int | Y | game_phase enum 값 (BS-06-00-REF §1.9) |
| `skin` | string | Y | 현재 적용된 스킨 이름 |
| `elements` | object | Y | 오버레이 요소 상태 (§3) |
| `animations` | object | Y | 현재 애니메이션 상태 (§4) |
| `output` | object | Y | 출력 설정 (§5) |

---

## 3. elements 상세

### 3.1 board (커뮤니티 카드)

```json
"board": [
  { "index": 0, "suit": 3, "rank": 12, "card_code": "As", "visible": true },
  { "index": 1, "suit": 2, "rank": 11, "card_code": "Kh", "visible": true },
  { "index": 2, "suit": 1, "rank": 10, "card_code": "Qd", "visible": true }
]
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `index` | int (0~4) | 보드 카드 순서 |
| `suit` | int (0~3) | 수트 enum: 0=clubs, 1=diamonds, 2=hearts, 3=spades |
| `rank` | int (0~12) | 랭크 enum: 0=2, 1=3, ..., 12=Ace |
| `card_code` | string | 랭크+수트 2자 표기 (예: "As", "Th") |
| `visible` | bool | 현재 표시 여부 |

### 3.2 players (플레이어 배열)

```json
"players": [
  {
    "seat_index": 0,
    "player_id": 12345,
    "name": "John Doe",
    "country": "US",
    "photo_url": "https://...",
    "stack": 1250000,
    "status": "active",
    "status_value": 0,
    "holecards": [
      { "suit": 3, "rank": 12, "card_code": "As", "visible": true },
      { "suit": 2, "rank": 11, "card_code": "Kh", "visible": true }
    ],
    "position": "BTN"
  }
]
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int (0~9) | 좌석 번호 |
| `player_id` | int | 플레이어 고유 ID (BO DB) |
| `name` | string | 플레이어 이름 |
| `country` | string (ISO 3166-1 alpha-2) | 국적 코드 |
| `photo_url` | string | 프로필 사진 URL (없으면 null) |
| `stack` | int | 현재 보유 칩 (정수) |
| `status` | string | 플레이어 상태 (가독성용) |
| `status_value` | int | PlayerStatus enum 값 (BS-06-00-REF §1.5.2) |
| `holecards` | array | 홀카드 배열 (Hold'em: 2장). 비공개 시 빈 배열 |
| `position` | string | 포지션 (SB/BB/UTG/HJ/CO/BTN 등) |

### 3.3 pot (팟)

```json
"pot": {
  "main_pot": 420000,
  "side_pots": [
    { "amount": 150000, "eligible_seats": [0, 3, 7] }
  ],
  "total": 570000
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `main_pot` | int | 메인 팟 금액 |
| `side_pots` | array | 사이드 팟 배열 (없으면 빈 배열) |
| `side_pots[].amount` | int | 사이드 팟 금액 |
| `side_pots[].eligible_seats` | array[int] | 수령 자격 좌석 목록 |
| `total` | int | 전체 팟 합계 |

### 3.4 equity_bars (승률 바)

```json
"equity_bars": [
  { "seat_index": 0, "equity": 0.65, "display": "65%", "visible": true },
  { "seat_index": 3, "equity": 0.35, "display": "35%", "visible": true }
]
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | 좌석 번호 |
| `equity` | float (0.0~1.0) | 승률 값 |
| `display` | string | 표시 문자열 (% 변환) |
| `visible` | bool | 표시 여부 (폴드 플레이어는 false) |

### 3.5 hand_ranks (핸드 랭킹)

```json
"hand_ranks": [
  { "seat_index": 0, "rank_value": 7, "rank_name": "Full House", "description": "Aces full of Kings", "visible": true }
]
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | 좌석 번호 |
| `rank_value` | int | 핸드 랭크 enum 값 (BS-06-00-REF §1.5.1) |
| `rank_name` | string | 핸드 등급 이름 |
| `description` | string | 상세 설명 (예: "Aces full of Kings") |
| `visible` | bool | 표시 여부 |

### 3.6 dealer_button (딜러 버튼)

```json
"dealer_button": {
  "seat_index": 5,
  "visible": true
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | 딜러 좌석 번호 |
| `visible` | bool | 표시 여부 |

### 3.7 lower_third (하단 자막)

```json
"lower_third": {
  "text": "BLINDS 50K/100K | ANTE 15K",
  "custom_text": "",
  "ticker_stats": { "type": "chipcount" },
  "visible": true
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `text` | string | 표시 텍스트 |
| `custom_text` | string | Admin 수동 입력 텍스트 (빈 문자열이면 미표시) |
| `ticker_stats` | object | 티커 통계 설정 |
| `ticker_stats.type` | string | strip_display_type (chipcount/vpip/pfr/agr/wtsd) |
| `visible` | bool | 표시 여부 |

### 3.8 action_badges (액션 배지)

```json
"action_badges": [
  { "seat_index": 0, "action": "RAISE", "amount": 250000, "visible": true },
  { "seat_index": 3, "action": "FOLD", "amount": null, "visible": true }
]
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | 좌석 번호 |
| `action` | string | 액션 이름 (CHECK/FOLD/BET/CALL/RAISE/ALL-IN) |
| `amount` | int or null | 베팅 금액 (CHECK/FOLD는 null) |
| `visible` | bool | 표시 여부 |

---

## 4. animations (현재 애니메이션 상태)

```json
"animations": {
  "active": [
    {
      "target": "board.2",
      "state": "SlideUp",
      "state_value": 13,
      "progress": 0.7,
      "duration_ms": 300
    }
  ],
  "transition_type": "fade",
  "transition_type_value": 0
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `active` | array | 현재 진행 중인 애니메이션 목록 |
| `active[].target` | string | 대상 요소 (예: "board.2", "player.0.holecards") |
| `active[].state` | string | AnimationState 이름 (가독성용) |
| `active[].state_value` | int | AnimationState enum 값 (BS-06-00-REF §1.6.1) |
| `active[].progress` | float (0.0~1.0) | 진행률 |
| `active[].duration_ms` | int | 전체 지속 시간 (ms) |
| `transition_type` | string | 기본 전환 효과 이름 |
| `transition_type_value` | int | transition_type enum 값 |

---

## 5. output (출력 설정)

```json
"output": {
  "resolution": "1920x1080",
  "width": 1920,
  "height": 1080,
  "format": "ndi",
  "chromakey": {
    "enabled": true,
    "color": "#00FF00"
  },
  "security_delay_ms": 0
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `resolution` | string | 해상도 문자열 (가독성용) |
| `width` | int | 가로 px |
| `height` | int | 세로 px |
| `format` | string | 출력 채널: "ndi", "hdmi", "chromakey" |
| `chromakey.enabled` | bool | 크로마키 활성 여부 |
| `chromakey.color` | string (hex) | 크로마키 배경색 |
| `security_delay_ms` | int | Security Delay (ms) |

---

## 6. 스키마 버전 관리

| 규칙 | 설명 |
|------|------|
| **버전 형식** | SemVer (MAJOR.MINOR) |
| **MAJOR 변경** | 기존 필드 삭제/타입 변경 (하위 비호환) |
| **MINOR 변경** | 새 필드 추가 (하위 호환 — 기존 파서가 무시 가능) |
| **현재 버전** | 1.0 |

### 하위 호환 규칙

| 변경 유형 | 버전 영향 | 예시 |
|----------|----------|------|
| 새 element 추가 | MINOR | elements에 `outs` 필드 추가 |
| 기존 필드 타입 변경 | MAJOR | stack: int → float |
| 기존 필드 삭제 | MAJOR | player에서 country 제거 |
| 새 optional 필드 추가 | MINOR | player에 `avatar_frame` 추가 |

---

## 7. 씬 스냅샷 API

### 7.1 스냅샷 저장

| 항목 | 내용 |
|------|------|
| **트리거** | 매 이벤트 후 자동 / Admin 수동 요청 |
| **저장 위치** | 로컬 파일 시스템 (핸드 히스토리 디렉토리) |
| **파일명 규칙** | `scene_{table_id}_{hand_number}_{game_phase}_{timestamp}.json` |
| **보존 기간** | BO Config에서 설정 (기본: 최근 100핸드) |

### 7.2 스냅샷 로드

| 항목 | 내용 |
|------|------|
| **용도** | 리플레이, 디버깅, 테스트 |
| **동작** | JSON 파일 로드 → Overlay에 상태 주입 → 정적 렌더링 |
| **제약** | 로드된 스냅샷은 읽기 전용. Game Engine 이벤트로만 상태 변경 가능 |

### 7.3 스냅샷 시퀀스 (리플레이)

| 항목 | 내용 |
|------|------|
| **구조** | 동일 핸드의 스냅샷 배열을 시간 순서로 정렬 |
| **재생** | 스냅샷 간 타임스탬프 차이만큼 대기 후 순차 렌더링 |
| **배속** | 1x, 2x, 4x, 0.5x 재생 속도 지원 |

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| `Elements.md` (legacy-id: BS-07-01) | 각 element의 동작 정의 |
| `Animations.md` (legacy-id: BS-07-02) | animations 섹션의 상태값 |
| `Behavioral_Specs/Overview.md` (legacy-id: BS-06-00) | Enum 값 (game_phase, suit, rank, PlayerStatus 등) |
| `BS-00-definitions.md` | 엔티티·상태 용어 |
| `Seat_Management.md §6` (legacy-id: BS-05-03) | CC 시각 규격 원본 (CCR-034 동일 색상 체계) |

---

## player_state_colors 섹션 (CCR-034)

Scene Schema의 `player_state_colors` 필드는 CC와 Overlay가 공유하는 **단일 색상 체계**를 정의한다. `BS-07-01 §Player Element 시각 규격`과 `BS-05-03 §6`에서 참조하는 hex 코드를 이 섹션에 확정한다.

```json
{
  "player_state_colors": {
    "position_markers": {
      "dealer":  "#E53935",
      "sb":      "#FDD835",
      "bb":      "#1E88E5",
      "utg":     "#43A047",
      "default": "#FFFFFF"
    },
    "seat_backgrounds": {
      "vacant":      { "color": "#616161", "opacity": 1.0 },
      "active":      { "color": "#2E7D32", "opacity": 1.0 },
      "folded":      { "color": "#616161", "opacity": 0.4 },
      "sitting_out": { "color": "#616161", "opacity": 0.6 },
      "all_in":      { "color": "#000000", "opacity": 1.0 }
    },
    "action_glow": {
      "color":     "#FDD835",
      "period_ms": 800,
      "easing":    "alternate"
    }
  }
}
```

**규칙**:
- Skin마다 override 가능하지만 CC와 Overlay가 **동일 값**을 공유
- CC 전용/Overlay 전용 색상 분리 **금지** (계약 위반)
- Table별 색상 Override는 `Settings/Graphics.md §7` (legacy-id: BS-03-02) 참조 (skin 수준이 아닌 table 설정 수준)
