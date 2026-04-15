---
title: Elements
owner: team4
tier: internal
legacy-id: BS-07-01
last-updated: 2026-04-15
---

# BS-07-01 Elements — 오버레이 요소 상세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 10개 오버레이 요소 트리거/갱신/데이터 소스/가시성 상세 |

---

## 개요

이 문서는 Overlay가 렌더링하는 **10개 오버레이 요소** 각각의 트리거 조건, 갱신 조건, 데이터 소스, 가시성 규칙을 정의한다.

> **참조**: Layer 1 그래픽 8종 + 보조 요소는 `BS-07-00-overview.md` §3. 트리거 정의는 `BS-06-00-triggers.md`. Enum 값은 `BS-06-00-REF-game-engine-spec.md`.

---

## 요소 총괄표

| # | 요소 | 트리거 | 갱신 조건 | 데이터 소스 |
|:-:|------|--------|----------|-----------|
| 1 | 홀카드 (HoleCards) | `CardDetected` | 새 카드 감지 시 | RFID HAL / Manual |
| 2 | 커뮤니티 카드 (Board) | `CardDetected` | Flop(3)/Turn(1)/River(1) | RFID HAL / Manual |
| 3 | 플레이어 이름 (Player Name) | `SeatAssign` | 좌석 배치 변경 시 | BO Player DB |
| 4 | 칩 스택 (Chip Stack) | `ActionPerformed` | 베팅/승리 시 | Game Engine |
| 5 | 팟 (Pot Display) | `ActionPerformed` | 베팅 누적 시 | Game Engine |
| 6 | 승률 바 (Equity Bar) | `EquityUpdated` | 카드 변경 시 | Game Engine (Monte Carlo/LUT) |
| 7 | 핸드 랭킹 (Hand Rank Label) | `EquityUpdated` | 보드 변경 시 | Hand Evaluator |
| 8 | 액션 배지 (Action Badge) | `ActionPerformed` | 플레이어 액션 시 | CC |
| 9 | 딜러 버튼 (Dealer Button) | `StartHand` | 핸드 시작 시 | Game Engine |
| 10 | 하단 자막 (Lower Third) | 수동 입력 | Admin 수동 텍스트 | Lobby Settings |

---

## 1. 홀카드 (HoleCards)

각 플레이어에게 비공개로 배분되는 카드 이미지.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| RFID 카드 감지 | `CardDetected` (antennaId → seat 매핑) | 해당 좌석 홀카드 슬롯에 카드 이미지 표시 |
| CC 수동 입력 | `ManualCardInput` → `CardDetected` 합성 | 동일 (Mock 모드 포함) |
| 폴드 | `Fold` → `ActionPerformed` | 카드 SlideAndDarken 후 숨김 |
| 쇼다운 | `ShowdownStarted` | Security Delay 이후 전체 공개 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 카드 수 | Hold'em: 2장 (좌석당) |
| Security Delay | `card_reveal_type` 설정에 따라 0~120초 지연 가능 |
| 공개 시점 | `show_type` enum: immediate(0), after_action(1), after_round(2), manual(3) |
| 폴드 시 | `fold_hide_type` enum: immediate(0), end_of_hand(1) |

### 위치/스타일

표시 위치, 크기, 카드 이미지는 **스킨에서 정의**한다. 좌석 번호(0~9)별 좌표가 스킨 JSON에 포함된다.

> 참조: BS-06-00-REF §6.1 card_reveal_type, show_type, fold_hide_type

---

## 2. 커뮤니티 카드 (Board)

테이블 중앙에 공개되는 공용 카드.

### 트리거/갱신

| 게임 단계 | 카드 수 | 트리거 | 동작 |
|----------|:------:|--------|------|
| Flop | 3장 | `CardDetected` × 3 → `BettingRoundComplete` | 3장 순차 SlideUp |
| Turn | 1장 | `CardDetected` × 1 → `BettingRoundComplete` | 1장 SlideUp |
| River | 1장 | `CardDetected` × 1 → `BettingRoundComplete` | 1장 SlideUp |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 최대 카드 수 | 5장 (Hold'em 기준) |
| 위치 | `board_pos_type` enum: left(0), centre(1), right(2) |
| 애니메이션 | SlideUp, 순차 50ms 간격 (Flop 3장) |

---

## 3. 플레이어 이름 (Player Name)

좌석에 배치된 플레이어의 이름, 국적, 사진.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 좌석 배치 | `SeatAssign` | 해당 좌석에 플레이어 정보 표시 |
| 좌석 해제 | `SeatVacate` | 해당 좌석 플레이어 정보 제거 |
| 정보 변경 | `PlayerUpdated` (BO) | 이름/사진 갱신 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 데이터 소스 | BO Player DB (WSOP LIVE API에서 수신) |
| 표시 항목 | 이름, 국적 플래그, 프로필 사진 (스킨에 따라 일부 생략 가능) |
| 글자 수 제한 | 스킨에서 정의 (넘칠 경우 말줄임 처리) |

---

## 4. 칩 스택 (Chip Stack)

플레이어의 현재 보유 칩 수량.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 베팅 수행 | `ActionPerformed` (Bet/Call/Raise/AllIn) | 스택에서 베팅액 차감 표시 |
| 블라인드 수집 | `BlindsPosted` | SB/BB/Ante 차감 |
| 팟 승리 | `WinnerDetermined` | 승리 금액 가산 |
| 핸드 시작 | `StartHand` | 최신 스택 표시 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 표시 형식 | `chipcount_disp_type`: amount(0), BB(1), both(2) |
| 올인 시 | 스택 0 표시 + ALL-IN 배지 |
| 숫자 포맷 | 천 단위 콤마 구분 (예: 1,250,000) |

> 참조: BS-06-00-REF §5.2 GfxPanelType ChipCount

---

## 5. 팟 (Pot Display)

현재 핸드에 베팅된 총액. 메인 팟 + 사이드 팟.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 베팅 발생 | `ActionPerformed` | 팟 총액 갱신 |
| 사이드 팟 생성 | `SidePotCreated` | 사이드 팟 표시 추가 |
| 핸드 종료 | `HandCompleted` | 팟 0으로 리셋 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 메인 팟 | 항상 표시 |
| 사이드 팟 | 0~N개, 생성 시 순차 표시 |
| 숫자 포맷 | 천 단위 콤마 구분 |
| 위치 | Bottom Info Strip 영역 또는 보드 근처 (스킨 정의) |

---

## 6. 승률 바 (Equity Bar)

각 플레이어의 승리 확률을 % 바로 표시.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 홀카드 배분 | `EquityUpdated` (카드 변경 후) | 초기 승률 계산 표시 |
| 보드 카드 공개 | `EquityUpdated` (보드 변경 후) | 승률 재계산 표시 |
| 플레이어 폴드 | `ActionPerformed` (Fold) | 해당 플레이어 승률 바 제거 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 표시 시점 | `equity_show_type`: start_of_hand(0), after_first_betting_round(1) |
| 계산 방식 | Monte Carlo 시뮬레이션 또는 LUT (사전 계산 테이블) |
| 값 범위 | 0.0~1.0 (내부) → 0%~100% (표시) |
| 폴드 플레이어 | 승률 바 숨김 |
| 표시 위치 | 플레이어 패널 하단 (스킨 정의) |

> 참조: BS-06-00-REF Ch4 Equity

---

## 7. 핸드 랭킹 (Hand Rank Label)

현재 보드 기준 플레이어의 핸드 등급 텍스트.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 보드 카드 공개 | `EquityUpdated` | 핸드 등급 재평가 표시 |
| 쇼다운 | `ShowdownStarted` | 최종 핸드 등급 표시 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 표시 조건 | `show_rank` = true |
| 값 예시 | "Pair of Aces", "Flush", "Full House" |
| 하이라이트 | `hilite_winning_hand_type`: none(0), immediate(1), after_action(2), showdown(3) |
| 위치 | 플레이어 패널 또는 카드 옆 (스킨 정의) |

> 참조: BS-06-00-REF §6.1 show_rank, hilite_winning_hand_type

---

## 8. 액션 배지 (Action Badge)

플레이어가 수행한 액션을 시각적 배지로 표시.

### 트리거/갱신

| 액션 | 배지 | 색상 (기본) | 지속 |
|------|------|:----------:|------|
| CHECK | CHECK | 녹색 | 다음 액션까지 |
| FOLD | FOLD | 적색 | 핸드 종료까지 |
| BET | BET + 금액 | 황색 | 다음 액션까지 |
| CALL | CALL | 청색 | 다음 액션까지 |
| RAISE | RAISE + 금액 | 황색 | 다음 액션까지 |
| ALL-IN | ALL-IN | 적/황 | 핸드 종료까지 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 트리거 | `ActionPerformed` (CC에서 운영자 입력) |
| 바운스 효과 | `player_action_bounce` = true 시 배지 등장 바운스 |
| 들여쓰기 | `indent_action` = true 시 배지 위치 조정 |
| 색상 | 스킨에서 재정의 가능 |

---

## 9. 딜러 버튼 (Dealer Button)

현재 딜러 위치를 표시하는 아이콘.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| 핸드 시작 | `StartHand` | 딜러 좌석 위치로 버튼 이동 |
| 핸드 종료 | `HandCompleted` | 위치 유지 (다음 StartHand까지) |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 아이콘 | "D" 버튼 (스킨에서 이미지 재정의 가능) |
| 위치 | 딜러 좌석 옆 (좌석 좌표 기반 오프셋) |
| 헤즈업 | `heads_up_layout_mode`에 따라 위치 변경 |

---

## 10. 하단 자막 (Lower Third)

화면 하단에 표시되는 텍스트 정보 영역.

### 트리거/갱신

| 조건 | 트리거 | 동작 |
|------|--------|------|
| Admin 텍스트 입력 | Lobby Settings 수동 입력 | 자막 텍스트 표시 |
| 설정 변경 | `ConfigChanged` (BO) | 자막 내용 갱신 |
| 블라인드 변경 | `BlindStructureChanged` | 블라인드 레벨 텍스트 갱신 |

### 표시 규칙

| 규칙 | 설명 |
|------|------|
| 구성 요소 | BLINDS, POT, 커스텀 텍스트 |
| 티커 통계 | `strip_display_type`으로 chipcount/vpip/pfr/agr/wtsd 전환 |
| 스크롤 | 긴 텍스트는 티커 스크롤 (스킨에서 속도 정의) |
| 위치 | 화면 하단 고정 (Bottom Info Strip) |

> 참조: Feature Catalog G3-001 하단 자막, G3-002 방송 제목

---

## 가시성 (Visibility) 토글

모든 오버레이 요소는 **개별 가시성 토글**을 지원한다. Settings에서 요소별 표시/숨김을 제어한다.

| 요소 | 가시성 키 | 기본값 |
|------|----------|:------:|
| 홀카드 | `show_holecards` | ON |
| 커뮤니티 카드 | `show_board` | ON |
| 플레이어 이름 | `show_player_name` | ON |
| 칩 스택 | `show_chip_stack` | ON |
| 팟 | `show_pot` | ON |
| 승률 바 | `show_equity` | ON |
| 핸드 랭킹 | `show_rank` | ON |
| 액션 배지 | `show_action_badge` | ON |
| 딜러 버튼 | `show_dealer_button` | ON |
| 하단 자막 | `show_lower_third` | ON |

> **핵심**: 가시성 토글은 Overlay 렌더링에만 영향을 미친다. Game Engine의 게임 로직에는 영향 없다.

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| `BS-07-00-overview.md` | Layer 1 그래픽 8종 정의 |
| `BS-07-02-animations.md` | 요소별 애니메이션 상세 |
| `BS-06-00-REF-game-engine-spec.md` | DisplayConfig 필드 (card_reveal_type 등) |
| `BS-06-00-triggers.md` | 트리거 이벤트 카탈로그 |
| `BS-03-settings/` | 가시성 토글 UI |
| `BS-05-03-seat-management §6` | CC 시각 규격 원본 (CCR-034 동기화) |

---

## Player Element 시각 규격 (CCR-034)

> **참조**: `BS-05-03-seat-management §6` (CC 시각 규격 원본)

Overlay의 Player Element(10좌석 각각)는 CC 화면과 **동일한 색상 체계**를 사용한다. 운영자(CC)와 시청자(Overlay)가 같은 시각 언어로 정보를 파악하도록 강제한다.

### 포지션 마커 색상

| 포지션 | CSS / Dart Color | 출처 |
|--------|-----------------|------|
| Dealer | `#E53935` (Material Red 600) | BS-05-03 §6.1 |
| SB | `#FDD835` (Material Yellow 600) | BS-05-03 §6.1 |
| BB | `#1E88E5` (Material Blue 600) | BS-05-03 §6.1 |
| UTG | `#43A047` (Material Green 600) | BS-05-03 §6.1 |
| 일반 | `#FFFFFF` | BS-05-03 §6.1 |

### 좌석 상태 배경색

| Seat 상태 | 배경 | 투명도 | 추가 요소 |
|-----------|------|:------:|----------|
| VACANT | `#616161` | 100% | "OPEN" (Overlay에서 숨김 가능) |
| OCCUPIED + active | `#2E7D32` | 100% | — |
| OCCUPIED + active + action_on | `#2E7D32` + action-glow | 100% | 노란 테두리 펄스 |
| OCCUPIED + folded | `#616161` | 40% | — |
| OCCUPIED + sitting_out | `#616161` | 60% | "AWAY" |
| OCCUPIED + all_in | `#000000` | 100% | "ALL-IN" 배지 (흰색) |

### action-glow 애니메이션

- **효과**: box-shadow 펄스 (CSS) 또는 Rive State Machine의 동등한 구현
- **주기**: **0.8초** (`BS-05-03 §6.3`과 동일)
- Rive 구현 시 `action_glow_intensity` Input(0.0~1.0)을 사인파로 구동
- **근거**: Preattentive Processing (0.8s가 무의식 감지 범위)

### Skin Override 정책

Graphic Editor(BS-08)에서 Admin이 Skin마다 위 색상을 커스터마이즈할 수 있다. **CC와 Overlay는 동일 override 값을 공유**해야 한다.

- `.gfskin` / `skin.json` 에 `player_state_colors` 섹션 **1개**만 유지
- CC 화면과 Overlay 화면이 모두 이 섹션을 참조
- **CC 전용/Overlay 전용 색상 분리 금지** (계약 위반)

### 상태 동기화 흐름

```
Game Engine (BS-06)
  │
  ├─ 상태 변경 (player_status: active → folded)
  │
  ├─ OutputEvent 발행 (API-04)
  │   └─ { seat_no, player_status, biggest_bet, ... }
  │
  ├─ Overlay 수신
  │   └─ Player Element 상태 업데이트
  │   └─ 본 문서 §Player Element 시각 규격 렌더링
  │
  └─ CC 수신
      └─ BS-05-03 §6에 따른 동일 렌더링 (같은 색상 코드)
```
