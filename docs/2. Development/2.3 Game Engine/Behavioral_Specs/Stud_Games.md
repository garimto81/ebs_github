---
title: Stud Games
owner: team3
tier: internal
legacy-id: BS-06-3X
last-updated: 2026-04-15
---

# BS-06-3X: Seven Card Stud — 라이프사이클 + Street + 핸드 평가

> **존재 이유**: Stud 3종(game 19–21) 통합 사양. `coalescence.dart:CoalescenceWindow.stud3rd()`가 §1 Street 시스템을 인용. §2 Hi-Lo/Razz 평가가 Phase 3 구현 타겟.
>
> **Status**: Phase 3 (deferred) — Hold'em Core 구현 완료 후 착수.
>
> **통합 이력**: 2026-04-14 — BS-06-31(라이프사이클) + BS-06-32(평가) 통합. 같은 게임군의 두 측면.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Stud 3종 FSM, Street, bring-in, Hi-Lo/Razz 평가 (BS-06-31, 32 분리) |
| 2026-04-09 | Phase 표시 | **Phase 3** 명시 |
| 2026-04-14 | **통합** | BS-06-31 + BS-06-32 → BS-06-3X 단일 문서 |

---

## 공통 용어

| 용어 | 설명 |
|------|------|
| FSM | 게임 진행 단계 흐름도 |
| RFID | 무선 카드 자동 인식 기술 |
| CC | Command Center, 운영자 화면 |
| coalescence | 동시 신호 병합 처리 규칙 |
| evaluator | 카드 조합 분석 함수 |
| Street | 각 베팅 라운드 (카드가 추가 배분되는 단계) |
| down card | 뒤집어 놓은 비공개 카드 |
| up card | 앞면이 보이는 공개 카드 |
| door card | 처음 받는 공개 카드 1장 |
| bring-in | 약한 패 보유자가 의무로 내는 최소 베팅 |
| ante | 모든 참가자가 게임 시작 전 내는 참가비 |
| visible hand | 공개 카드만으로 보이는 패 |
| 커뮤니티 카드 | 모든 플레이어가 공유하는 공용 카드 |
| 8-or-better | Low 자격: 5장 모두 ≤ 8, 서로 다른 rank |
| scoop | 한 사람이 양쪽 팟 모두 가져가는 것 |
| odd chip | 팟 분배 시 1개 잔여 베팅 토큰 |
| C(n,k) | n장에서 k장 선택 조합 수 |

## Hold'em과의 핵심 차이

- 보드 카드 없음 (모든 카드 개인 소유)
- **5 베팅 라운드** (Hold'em 4회 + 1)
- Blind 없음 — ante + bring-in
- 공개/비공개 혼합 (2 down + 5 up; 7TH만 down)
- 액팅 순서 가변 (Street마다 visible hand 기준 재결정)

## 대상 게임

| `game_id` | 이름 | `evaluator` | 핵심 |
|:--:|------|------|------|
| 19 | stud7 | standard_high | 표준 하이 (BS-06-05 참조) |
| 20 | stud7_hilo8 | hilo_8or_better | Hi/Lo split + 8-or-better |
| 21 | razz | lowball_a5 | 로우볼 전용 |

---

# §1. 라이프사이클 + Street (구 BS-06-31)

## FSM 상태 다이어그램

```
IDLE
  ▼
SETUP_HAND ─── ante 수집 + 3장 딜 (2 down + 1 up)
  ▼
3RD_STREET ─── bring-in 결정 + 1st 베팅
  ▼
4TH_STREET ─── +1 up, 2nd 베팅
  ▼
5TH_STREET ─── +1 up, 3rd 베팅 (big bet 시작)
  ▼
6TH_STREET ─── +1 up, 4th 베팅
  ▼
7TH_STREET ─── +1 down, final 베팅
  ▼
SHOWDOWN ───── 핸드 평가 + 팟 분배
  ▼
HAND_COMPLETE
```

## 상태별 정의

### SETUP_HAND

| 항목 | 값 |
|------|-----|
| Entry | SendStartHand() 성공 |
| Exit | 모든 플레이어 3장 RFID 감지 완료 |
| 동작 | ante 수집 → 2 down + 1 up 배분 |
| `ante_type` | std_ante (0) — 전원 균등 |
| `bring_in` | ante < bring-in < small bet |

### 3RD_STREET

| 항목 | 값 |
|------|-----|
| Entry | SETUP 카드 배분 완료 |
| Exit | 베팅 완료 OR 1인 잔류 |
| `action_on` | bring-in 플레이어 |
| 베팅 크기 | `low_limit` (small bet) |

### 4TH_STREET

| 항목 | 값 |
|------|-----|
| Entry | 3RD 베팅 완료 |
| 동작 | 각 active +1 up |
| `action_on` | 최고 visible hand |
| 베팅 크기 | `low_limit` |
| **pair visible 예외 (FL)** | 2장 up에 pair 발견 시 big bet 선택 가능 |

### 5TH / 6TH / 7TH_STREET

| Street | 카드 | 베팅 | first to act |
|--------|------|------|------|
| 5TH | +1 up | `high_limit` (big bet 시작) | 최고 visible |
| 6TH | +1 up | `high_limit` | 최고 visible |
| 7TH | +1 **down** | `high_limit` | 최고 visible |

**7TH 덱 부족 예외**: 잔여 카드 < active 플레이어 → 1장을 **커뮤니티 카드**로 공개 (모든 active 공유). `stud_community_card = true`.

### SHOWDOWN

7장 (3 down + 4 up) 중 best 5. C(7,5)=21 조합. evaluator는 §2 라우팅.

### HAND_COMPLETE

Hold'em과 동일.

## 상태 전이 매트릭스

| 현재 | 트리거 | 다음 |
|------|--------|------|
| IDLE | SendStartHand() | SETUP_HAND |
| SETUP_HAND | 3장 RFID 완료 | 3RD_STREET |
| 3RD~6TH | 베팅 완료 | 다음 Street |
| 3RD~6TH | 전원 폴드 | HAND_COMPLETE |
| 7TH | 베팅 완료 + 2인+ | SHOWDOWN |
| 7TH | 전원 폴드 | HAND_COMPLETE |
| SHOWDOWN | 우승자 결정 | HAND_COMPLETE |
| HAND_COMPLETE | cycle 완료 | IDLE |

---

## Bring-in 시스템

### 결정 규칙

| `game_id` | 기준 |
|:--:|------|
| 19, 20 | 최저 up card 보유자 |
| 21 (Razz) | **최고** up card 보유자 (역순) |

> Razz 역순: 로우볼이므로 높은 카드 = 불리 → 약한 손이 먼저 강제 베팅 원칙.

### Bring-in 매트릭스

| 상황 | 동작 |
|------|------|
| 단독 최저/최고 door | 해당 플레이어 bring-in |
| 동점 (game 19, 20) | suit 순서로 가장 낮은 suit |
| 동점 (game 21) | suit 순서로 가장 높은 suit |
| bring-in 포스팅 | bring-in 금액만 |
| bring-in complete | full small bet 선택 |
| bring-in 후 raise | small bet 이상 가능 |
| 미포스팅 | 30초 타임아웃 → 자동 강제 차감 또는 fold |
| 잔액 부족 | all-in 처리 |
| 모두 콜/체크 | 4TH_STREET |

### Suit 순서

| 순위 | Suit |
|:--:|------|
| 1 (최저) | Clubs ♣ |
| 2 | Diamonds ♦ |
| 3 | Hearts ♥ |
| 4 (최고) | Spades ♠ |

> Suit 순서는 bring-in 결정에만 사용. SHOWDOWN에서는 사용 안 함.

---

## RFID 카드 감지

| Street | 카드 | 안테나 | 이벤트 (6인) |
|--------|------|--------|:--:|
| SETUP (3RD) | 2 down + 1 up | seat | **18** |
| 4TH | 1 up | 공개 | 6 |
| 5TH | 1 up | 공개 | 6 |
| 6TH | 1 up | 공개 | 6 |
| 7TH | 1 down | seat | 6 |

총 42 이벤트 (6인). 폴드 플레이어 카드도 감지되지만 무시.

### Down/Up 처리 우선순위

| 종류 | 안테나 | 공개 | RFID |
|------|--------|:--:|:--:|
| Down | seat (개별) | 비공개 | **필수** |
| Up | 공개 영역 | 공개 | 선택 (시각 확인 보조) |

### Coalescence

| 상황 | 처리 |
|------|------|
| 3RD burst (18장) | 표준 100ms 윈도우 확장 |
| bring-in 판정 대기 | up card 6장 RFID 완료까지 대기 |
| 4TH~6TH | 1장/인, 표준 100ms |
| 7TH | seat antenna |

---

## 블라인드/앤티 (Stud 전용)

| 항목 | Hold'em | Stud |
|------|---------|------|
| 강제 베팅 | SB + BB | ante + bring-in |
| 수집 대상 | SB, BB만 | **전원 ante** |
| 수집 시점 | SETUP_HAND | SETUP (ante), 3RD (bring-in) |
| `ante_type` | 0–6 | std_ante (0)만 |
| `bring_in` | 0 | 설정값 |

## 베팅 구조 (FL 기준)

| Street | 베팅 크기 | 예외 |
|--------|---------|------|
| 3RD | `low_limit` | bring-in 별도 |
| 4TH | `low_limit` | pair visible 시 big bet 선택 |
| 5TH–7TH | `high_limit` | 없음 |

| `bet_structure` | 지원 |
|:--:|:--:|
| 0 (NL) | 가능 (드묾) |
| 1 (FL) | **기본** |
| 2 (PL) | 가능 (드묾) |

### First to Act

| Street | First | 기준 |
|--------|------|------|
| 3RD | bring-in | 최저/최고 door |
| 4TH–7TH | 최고 visible hand | 공개 카드 best rank, 동점 시 딜러 왼쪽 |

---

## 예외 처리

| 예외 | 트리거 | 처리 |
|------|--------|------|
| 3RD RFID burst 실패 | 18장 중 일부 미감지 (5초) | CC 수동 입력 모드 |
| 덱 부족 (7TH) | 잔여 < active | 커뮤니티 카드 1장 공개 |
| bring-in 미포스팅 | 30초 | 자동 강제 차감 |
| bring-in 잔액 부족 | bring-in > 스택 | all-in |
| all-in 발생 | 라운드 중 스택 소진 | 이후 Street 자동, 베팅 불참 |
| 미스딜 | down card 감지 != 2 | 경고 + 재딜 옵션 |
| up card RFID 불일치 | 시각 vs RFID | CC 수동 보정 |

---

# §2. 핸드 평가 (구 BS-06-32)

## 평가기 라우팅

| `game_id` | `evaluator` | 평가 위치 |
|:--:|------|------|
| 19 | standard_high | BS-06-05 (Hold'em 평가) |
| 20 | hilo_8or_better | §2.1 |
| 21 | lowball_a5 | §2.2 |

## 7-Card Stud 공통

7장 (3 down + 4 up) 중 best 5. C(7,5)=21 조합. 보드 카드 없음.

## §2.1 Stud Hi-Lo 8-or-better (game 20)

### High 평가

`standard_high` (BS-06-05). 7장 중 best 5-card high.

### Low 자격 (8-or-better qualifier)

5장 모두 충족:

| 조건 | 설명 |
|------|------|
| rank ≤ 8 | A, 2, 3, 4, 5, 6, 7, 8 |
| 서로 다른 rank | 5장 모두 다름 |
| A = Low | Ace = 1 |
| Straight 무시 | 영향 없음 |
| Flush 무시 | 영향 없음 |

### Low 자격 예시

| 핸드 | 자격 | 이유 |
|------|:--:|------|
| A-2-3-4-5 | 충족 | wheel (최고 Low) |
| A-2-3-4-8 | 충족 | 모두 ≤ 8 |
| A-2-3-4-9 | 불충족 | 9 > 8 |
| A-2-3-3-5 | 불충족 | 3 중복 |
| 2-3-4-5-6 | 충족 | Straight 무시 |

### Low 랭킹 (가장 높은 카드부터 비교)

| 순위 | 예시 |
|:--:|------|
| 1 | A-2-3-4-5 (5-4-3-2-A) |
| 2 | A-2-3-4-6 (6-4-3-2-A) |
| 3 | A-2-3-5-6 (6-5-3-2-A) |
| ... | ... |
| 최저 | 4-5-6-7-8 (8-7-6-5-4) |

### 팟 분배

| High 승자 | Low 자격자 | 분배 |
|:--:|:--:|------|
| A | 없음 | A 전체 (scoop) |
| A | B (다른 사람) | A 50%, B 50% |
| A | A (동일인) | A 100% (scoop) |
| A, B 동점 Hi | C Low | Hi 50% 균분 (A 25%, B 25%), Lo C 50% |
| A | B, C 동점 Lo | Hi A 50%, Lo 균분 (B 25%, C 25%) |

### Odd Chip

| 상황 | 수령자 |
|------|--------|
| Hi/Lo split | Hi 우선 |
| Hi 동점 | 딜러 왼쪽 |
| Lo 동점 | 딜러 왼쪽 |

## §2.2 Razz (game 21)

| 항목 | 값 |
|------|-----|
| 평가 | Lowball A-5 |
| A | Low (1) |
| Straight | 무시 |
| Flush | 무시 |
| 최고 | A-2-3-4-5 (wheel) |
| 최악 | 높은 pair 조합 |

### Razz 랭킹

7장 중 가장 낮은 5장 선택. 가장 높은 카드부터 비교, 낮을수록 승리.

| 순위 | 예시 | 설명 |
|:--:|------|------|
| 1 | A-2-3-4-5 | wheel |
| 2 | A-2-3-4-6 | 6-low |
| 3 | A-2-3-5-6 | 6-low (5 > 4) |
| 4 | A-2-3-4-7 | 7-low |
| ... | ... | ... |
| 하위 | 2-3-4-5-K | K-low |
| 최악 | 높은 pair+ | pair 있는 핸드 항상 짐 |

### 평가 상세

| 규칙 | 설명 |
|------|------|
| pair 없는 핸드 > pair | 항상 우위 |
| pair 동점 | 더 낮은 pair 승리 |
| 최고 카드 비교 | 내림차순 |
| 모두 pair | 가장 낮은 pair 승, 동점 시 잔여 카드 |
| Straight/Flush | Low에 영향 없음 |

### Razz vs Deuce-7 차이

| 속성 | Razz (game 21) | Deuce-7 (game 13, 14) |
|------|:--:|:--:|
| A | Low (1) | High (14) |
| Straight | 무시 | 불리 |
| Flush | 무시 | 불리 |
| 최고 Low | A-2-3-4-5 | 7-5-4-3-2 |
| `game_class` | stud (2) | draw (1) |

### Bring-in과의 관계

| 항목 | game 19, 20 | game 21 (Razz) |
|------|:--:|:--:|
| bring-in 기준 | 최저 up | **최고** up (역순) |
| first to act (4TH–7TH) | 최고 visible | 최고 visible (동일) |

> 4TH–7TH의 first to act는 모든 Stud에서 동일하게 **최고 visible hand**. Razz에서도 "가장 강해 보이는 공개 카드"가 먼저 액션 — bring-in 역순 규칙과 별개.

---

## 통합 구현 체크리스트

### 라이프사이클 (§1)

| 항목 | 우선순위 |
|------|:--:|
| FSM 8상태 (IDLE~HAND_COMPLETE) | P0 |
| bring-in 결정 (game별 + suit 순서) | P0 |
| Street별 카드 배분 (3RD 3장, 4TH–6TH +1up, 7TH +1down) | P0 |
| first to act (3RD=bring-in, 4TH–7TH=visible hand) | P0 |
| ante + bring-in 수집 (blind 비활성) | P0 |
| Razz bring-in 역순 | P0 |
| 4TH pair visible 예외 (FL big bet) | P1 |
| 덱 부족 커뮤니티 카드 (7TH) | P1 |
| 3RD 18장 RFID burst 윈도우 | P1 |

### 평가 (§2)

| 항목 | 우선순위 |
|------|:--:|
| hilo_8or_better (Hi standard + Lo qualifier 동시) | P0 |
| 8-or-better qualifier (5장 ≤ 8, 다른 rank) | P0 |
| lowball_a5 (A=Low, S/F 무시, 7장 중 best low 5) | P0 |
| Hi/Lo split pot 50/50, No-Low 시 Hi scoop | P0 |
| C(7,5)=21 조합 평가 (Hi, Lo 각각) | P0 |
| Odd chip (Hi 우선, 동점 시 딜러 왼쪽) | P1 |
| Razz bring-in 역순 ↔ §1 일관성 | P1 |
| No-Low UI 표시 | P1 |
