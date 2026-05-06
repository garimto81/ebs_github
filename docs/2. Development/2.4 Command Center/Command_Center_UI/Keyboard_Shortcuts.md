---
title: Keyboard Shortcuts
owner: team4
tier: internal
legacy-id: BS-05-06
last-updated: 2026-04-15
---

# BS-05-06 Command Center — 키보드 단축키

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 단축키 전체 맵, 카드 입력 단축키, 네비게이션, 충돌 방지 규칙 |
| 2026-05-06 | **§5 KeyboardHintBar 시각 표시 신설** (B-team4-011 V1) | 단축키 활성/비활성 상태를 화면 상단 바에 실시간 시각화. `actionButtonProvider` 매트릭스 동기화. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`. |

---

## 개요

CC는 **키보드 우선** 설계 원칙을 따른다. 운영자는 마우스 없이 단축키만으로 핸드 전체를 진행할 수 있다. 본방송 중 속도와 정확성이 핵심이므로, 자주 사용하는 액션은 단일 키로 매핑된다.

---

## 정의

| 용어 | 정의 |
|------|------|
| **단축키** | 단일 키 또는 Modifier+키 조합으로 CC 기능을 실행하는 키 매핑 |
| **카드 입력 모드** | 수동 카드 입력 활성화 상태. 이 모드에서는 수트+랭크 키가 카드 선택으로 동작 |
| **액션 모드** | 기본 상태. 키 입력이 게임 액션으로 동작 |

---

## 1. 액션 단축키

핵심 게임 액션을 단일 키로 실행한다. HandFSM 상태에 따라 활성/비활성이 결정된다.

| 키 | 액션 | 활성 조건 | 비고 |
|:--:|------|----------|------|
| **N** | NEW HAND | IDLE 상태 | 새 핸드 시작 |
| **D** | DEAL | SETUP_HAND 상태 | 홀카드 딜 시작 |
| **F** | FOLD | 베팅 라운드 + action_on | 즉시 처리 (확인 없음) |
| **C** | CHECK / CALL | 베팅 라운드 + action_on | biggest_bet == current_bet → CHECK, 아니면 CALL |
| **B** | BET | biggest_bet == 0 + action_on | 금액 입력 패드 열림 |
| **R** | RAISE | biggest_bet > 0 + action_on | 금액 입력 패드 열림 |
| **A** | ALL-IN | 베팅 라운드 + action_on + stack > 0 | 즉시 처리 |

### 동적 전환 규칙

**C 키**는 게임 상태에 따라 CHECK 또는 CALL로 자동 전환된다:

| biggest_bet_amt | player.current_bet | C 키 동작 |
|:--------------:|:-----------------:|----------|
| 0 또는 == current_bet | — | **CHECK** |
| > current_bet | < biggest_bet | **CALL {amount}** |

**B 키**와 **R 키**:

| biggest_bet_amt | B 키 | R 키 |
|:--------------:|------|------|
| 0 | **BET** (활성) | 비활성 |
| > 0 | 비활성 | **RAISE** (활성) |

---

## 2. 카드 입력 단축키

카드 입력 모드가 활성화되면 수트+랭크 키 조합으로 카드를 선택한다.

### 2.1 수트 키

| 키 | 수트 | 기호 |
|:--:|------|:----:|
| **s** | Spades | ♠ |
| **h** | Hearts | ♥ |
| **d** | Diamonds | ♦ |
| **c** | Clubs | ♣ |

### 2.2 랭크 키

| 키 | 랭크 |
|:--:|------|
| **A** | Ace |
| **2** ~ **9** | 해당 숫자 |
| **T** | 10 (Ten) |
| **J** | Jack |
| **Q** | Queen |
| **K** | King |

### 2.3 카드 입력 방법

수트 키를 먼저 누르고, 이어서 랭크 키를 누른다:

| 입력 | 결과 |
|------|------|
| `s` → `A` | Ace of Spades (As) |
| `h` → `T` | Ten of Hearts (Th) |
| `d` → `7` | Seven of Diamonds (7d) |
| `c` → `K` | King of Clubs (Kc) |

> 수트 키 입력 후 1초 이내에 랭크 키를 누르지 않으면 수트 선택이 취소된다.

---

## 3. 네비게이션 단축키

| 키 | 동작 | 활성 조건 |
|:--:|------|----------|
| **Tab** | 다음 좌석으로 이동 (시계 방향) | 카드 입력 모드 |
| **Shift+Tab** | 이전 좌석으로 이동 (반시계 방향) | 카드 입력 모드 |
| **Esc** | 현재 모드 취소/닫기 | 카드 입력 모드, 금액 입력 패드, 다이얼로그 |
| **Enter** | 확인/진행 | 금액 입력 확정, 다이얼로그 확인 |
| **Backspace** | 마지막 입력 삭제 | 카드 입력 (마지막 카드 제거), 금액 입력 (마지막 숫자 삭제) |

---

## 4. 시스템 단축키

| 키 | 동작 | 비고 |
|:--:|------|------|
| **Ctrl+Z** | UNDO (마지막 이벤트 되돌리기) | 최대 5단계 |
| **Space** | 확인/진행 (Enter 대체) | 다이얼로그, 금액 확정 |
| **F11** | 풀스크린 토글 | CC 앱 창 크기 전환 |

---

## 5. 금액 입력 단축키

BET/RAISE 시 금액 입력 패드가 열린 상태에서:

| 키 | 동작 |
|:--:|------|
| **0~9** | 숫자 입력 |
| **Backspace** | 마지막 숫자 삭제 |
| **Enter** | 금액 확정, 액션 실행 |
| **Esc** | 금액 입력 취소, 패드 닫기 |

> **M/P 키(MIN/POT 자동 입력)는 제거되었다** (UI-02 2026-04-13). Quick Preset 제거에 따라 관련 단축키도 제거. 금액은 숫자 키패드(0-9, C, ←, 000)로만 입력.

---

## 6. 단축키 전체 맵

| 카테고리 | 키 | 동작 |
|---------|:--:|------|
| **액션** | N | NEW HAND |
| | D | DEAL |
| | F | FOLD |
| | C | CHECK / CALL (동적) |
| | B | BET |
| | R | RAISE |
| | A | ALL-IN |
| **카드 수트** | s, h, d, c | Spades, Hearts, Diamonds, Clubs |
| **카드 랭크** | A, 2-9, T, J, Q, K | Ace ~ King |
| **네비게이션** | Tab | 다음 좌석 |
| | Shift+Tab | 이전 좌석 |
| | Esc | 취소/닫기 |
| | Enter / Space | 확인/진행 |
| | Backspace | 삭제/되돌리기 |
| **시스템** | Ctrl+Z | UNDO |
| | F11 | 풀스크린 |
| **금액** | 0-9 | 숫자 입력 |
| | 000 | 천 단위 빠른 입력 |
| | ~~M~~ | ~~제거 (UI-02 2026-04-13)~~ |
| | ~~P~~ | ~~제거 (UI-02 2026-04-13)~~ |

---

## 7. 단축키 충돌 방지 규칙

### 7.1 모드별 키 분리

CC는 2가지 입력 모드를 가지며, 모드에 따라 키의 의미가 달라진다:

| 모드 | 활성 상황 | C 키 의미 | A 키 의미 |
|------|----------|----------|----------|
| **액션 모드** (기본) | 베팅 라운드 중, 카드 입력 비활성 | CHECK/CALL | ALL-IN |
| **카드 입력 모드** | 카드 그리드 열린 상태 | Clubs (♣) 수트 | Ace 랭크 |

### 7.2 충돌 해결

| 충돌 상황 | 해결 |
|---------|------|
| C 키: CHECK vs Clubs | 카드 입력 모드에서는 Clubs, 아니면 CHECK/CALL |
| A 키: ALL-IN vs Ace | 카드 입력 모드에서는 Ace, 아니면 ALL-IN |
| D 키: DEAL vs Diamonds | 카드 입력 모드에서는 Diamonds, 아니면 DEAL |
| B 키: BET vs (미사용) | BET (카드 입력 모드에서도 B는 미사용 수트) |

### 7.3 모드 전환 규칙

| 전환 | 트리거 | 시각 표시 |
|------|--------|----------|
| 액션 → 카드 입력 | 카드 슬롯 클릭, 또는 카드 그리드 열기 | 상단 바에 "CARD INPUT" 표시 |
| 카드 입력 → 액션 | Esc, 또는 카드 입력 완료 | "CARD INPUT" 표시 제거 |

---

## 8. 커스터마이즈

### 8.1 v1.0 (고정)

v1.0에서는 단축키 매핑이 고정이다. 변경 불가.

### 8.2 v2.0+ (계획)

| 기능 | 설명 |
|------|------|
| 키 리매핑 | Settings에서 각 액션의 단축키 변경 |
| 프로필 저장 | 운영자별 단축키 프리셋 저장/로드 |
| 매크로 | 연속 키 입력을 1키에 매핑 |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | N 키 입력 (IDLE 상태) | NEW HAND 시작 |
| 2 | 운영자 | F 키 입력 (베팅 라운드) | 현재 action_on 플레이어 FOLD |
| 3 | 운영자 | C 키 입력 (biggest_bet == 0) | CHECK 처리 |
| 4 | 운영자 | C 키 입력 (biggest_bet > current_bet) | CALL 처리 |
| 5 | 운영자 | B 키 → 숫자 입력 → Enter | BET 금액 확정 |
| 6 | 운영자 | 카드 입력 모드에서 `s` → `A` | Ace of Spades 선택 |
| 7 | 운영자 | 카드 입력 모드에서 Tab | 다음 좌석 카드 슬롯으로 이동 |
| 8 | 운영자 | 금액 입력 중 Esc | 금액 입력 취소, 패드 닫기 |
| 9 | 운영자 | Ctrl+Z | 마지막 액션 UNDO |
| 10 | 운영자 | 비활성 상태에서 F 키 입력 | 무반응 (FOLD 조건 미충족) |

---

## 비활성 조건

- CC 앱이 포커스를 잃은 경우 단축키 비수신
- 모달 다이얼로그가 열린 경우 배경 단축키 비활성 (Esc/Enter만 동작)
- Table 상태가 PAUSED/CLOSED일 때 액션 단축키 비활성

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-02 액션 버튼 | 각 버튼의 단축키 매핑 |
| BS-05-04 수동 카드 입력 | 카드 입력 모드 단축키 |
| BS-05-05 Undo/복구 | Ctrl+Z 단축키 |

---

## 5. KeyboardHintBar — 시각 표시 정책 (B-team4-011 V1, 2026-05-06)

> **트리거**: 2026-05-05 디자이너 React 시안 critic 판정. 단축키가 명세에는 있으나 화면에 표시되지 않아 신규 운영자 학습 시간 길어지는 문제 식별. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`.

### 5.1 위치 및 크기

| 속성 | 값 |
|------|----|
| 화면 위치 | InfoBar (40px) 직하, SeatArea 직상 |
| 높이 | 32px |
| 배경 | `Theme.colorScheme.surfaceContainerLow` |
| 테두리 | bottom `outlineVariant` 1px |

### 5.2 표시 항목 (좌 → 우)

| 칩 | 키 | 라벨 | 활성 조건 (actionButtonProvider 매트릭스) |
|:--:|:--:|------|------------------------------------------|
| 1 | F | FOLD | `CcAction.fold` enabled |
| 2 | C | CHECK / CALL (동적) | `CcAction.checkCall` enabled · 라벨은 `checkCallLabel` 동기 |
| 3 | B | BET / RAISE (동적) | `CcAction.betRaise` enabled · 라벨은 `betRaiseLabel` 동기 |
| 4 | A | ALL-IN | `CcAction.allIn` enabled |
| 5 | N | NEW / FINISH (동적) | newHand 또는 deal enabled |
| 6 | M | MISS DEAL | `CcAction.missDeal` enabled |
| ─ | (Spacer) | ─ | ─ |
| 7 | Ctrl+L | DEBUG | 항상 활성 |

### 5.3 시각 동기 규칙

활성 칩과 비활성 칩은 다음 차이로 즉시 판별:

| 상태 | 키 칩 색상 | 라벨 색상 | opacity |
|------|----------|----------|:-------:|
| 활성 | accent color (FOLD = error red, BET = warning amber, ...) | onSurface | 1.0 |
| 비활성 | outline gray | onSurfaceVariant | 0.45 |

활성 키별 accent 색상은 `ActionPanel` 의 버튼 색상과 **동일** — 운영자 시각 언어 일관성.

### 5.4 단축키 입력 / 시각 힌트 분리 원칙

**단축키 자체는 본 문서 §1 ~ §4 매핑 그대로**. KeyboardHintBar 는 입력 핸들러가 아닌 **시각 reminder** 만 — `KeyboardShortcutHandler` 에 영향 없음.

### 5.5 접근성

| 요구 | 구현 |
|------|------|
| Tooltip (마우스 hover) | "Press F → FOLD" 또는 "FOLD (disabled)" |
| 색맹 대응 | accent 색상 + opacity 차이로 이중 신호 |
| 광민감 발작 (WCAG 2.3.1) | 깜빡임 없음 (정적 표시) |

### 5.6 구현 위치

- 위젯: `team4-cc/src/lib/features/command_center/widgets/keyboard_hint_bar.dart`
- 통합: `at_01_main_screen.dart` Column 의 InfoBar 와 SeatArea 사이

### 5.7 향후 확장

| 항목 | 근거 |
|------|------|
| 카드 입력 모드 (§2) 활성 시 chip 셋 자동 전환 (수트/랭크 키) | 모드 전환 시 운영자 혼동 방지 |
| Multi-Table 모드 (1:N) 시 active table 강조 | `Multi_Table_Operations.md` 와 cross-ref |
