---
title: Overview
owner: team3
tier: internal
legacy-id: BS-06-00
last-updated: 2026-05-08
last-synced: 2026-05-08  # Foundation v4.5 §10 정합 (S8 audit 2026-05-08, D1)
---

# BS-06-00-REF: EBS 게임 엔진 레퍼런스

> **존재 이유**: 22종 게임 공통 enum·룰 레퍼런스 index — BS-06-04~32 TOC 허브.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Ch1-Ch2 초판 |
| 2026-04-06 | Ch3~7 삭제 | 중복 제거, 순수 레퍼런스 전환 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-REF → BS-06-00-REF |
| 2026-04-07 | 표기법 → 전체 → critic 지적 수정 | 게임 수 정정, enum 값 할당, Chapter 재번호, 문서 작성 규칙 적용 |
| 2026-04-07 | 내러티브 → 전체 → 맥락 보강 | 용어 사전, Chapter 브릿지, 예시, 자연어 설명 추가 |
| 2026-04-07 | 표기법 → 전체 → 필드명 정규화 | prefix 제거, 모듈명 통일, 프로토콜명 통일 |
| 2026-04-07 | 데이터 → 전체 → WSOP LIVE API 통합 | event_game_type, event_flight_status, competition, payout, TournamentType enum 추가. game_type 확장 |
| 2026-04-07 | 구조 → 전체 → Hold'em 전용화 | game enum/game_class/페이즈를 Hold'em만으로 축소, 드로우 필드 제거, 마스터 테이블 축소 |
| 2026-04-08 | Ch7 추가 → Engine API 계약 | reduce() 시그니처, ReduceResult, 책임 경계, 구독 패턴, HandState↔GameSession 매핑 |
| 2026-04-09 | doc-critic 개선: 용어 해설 추가 | 문서 서두 용어 해설 테이블, Ch7 프로그래밍 용어 괄호 설명 추가 |
| 2026-04-09 | Ch8 추가 → Docker 서버 아키텍처 | Interactive Simulator Harness 서버 설계, Docker 컨테이너, HTTP API, 세션 관리 |
| 2026-04-09 | Ch8.4 보완 → API 명세 완성 | 누락 endpoint 4개, 이벤트 7개, config 파라미터, 응답 JSON 스키마 추가 |
| 2026-04-09 | Ch7.6 추가 → Event Log 수집 명세 | Event Log 데이터 구조, 로그 레코드 포맷, 스코프, cursor 정의, Call 금액 자동 계산 강제 |
| 2026-04-09 | Ch7.6.7 + Ch8.4 보강 → UNDO/Call enforcement | Contract Test FAIL 근거: UNDO 5단계 제한 Harness 적용 명시, undo endpoint 제한 반영 |
| 2026-04-10 | WSOP 규정 반영 | §2.1 GameState에 `prev_hand_bb_seat`, `boxed_card_count` 필드 추가, §2.2 Player에 `missed_sb`, `missed_bb` 필드 추가. Rules 86, 87, 88 지원. CCR-DRAFT-team3-20260410-wsop-conformance 참조 |
| 2026-04-10 | WSOP P0/P1 규정 반영 | §2.1 GameState에 `tournament_heads_up`, `bomb_pot_opted_out`, `mixed_game_sequence`, `current_game_index`, `game_transition_pending` 필드 추가, §2.2 Player에 `cards_tabled` 필드 추가, Ch7.5 Pot Size Display Policy 신설. Rules 28.3.2, 71, 96, 100, 101 + Mixed Omaha 지원. CCR-DRAFT-team3-20260410-wsop-conformance P0-3/P1-5/P1-6/P1-8/P2-11 반영 |
| 2026-05-08 | D1 [CRITICAL] HORSE 5종 정합 | §2.1 `mixed_game_sequence` 예시: HORSE=[O8, Razz, Stud, Stud8, NLH, PLO] 6종 → [Hold'em, O8, Razz, Stud, Stud8] 5종 FL. Foundation §10 위반 정정 (Lifecycle 도메인 마스터와 동일). (S8 consistency audit 2026-05-08) |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | NL/PL/FL | No Limit(무제한) / Pot Limit(팟 크기까지) / Fixed Limit(고정 금액) 베팅 구조 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 가상 코드. 로직을 이해하기 위한 참고용 |

## 개요

이 문서는 EBS 게임 엔진의 **기준값 총괄 레퍼런스**다. Enum 정의, 데이터 모델, 게임 설정, Equity/통계/표시 설정의 정확한 값을 제공한다.

**구성**: Ch1 Enum Registry, Ch2 Data Model, Ch3 Hold'em 게임 설정, Ch4 Equity, Ch5 Statistics, Ch6 Display Configuration, Ch7 Engine API 계약

**사용법**: 개발 중 enum 값, 필드 정의, 계산 공식이 필요하면 이 문서에서 30초 내에 찾는다. 상태 머신, 이벤트 트리거, 베팅 알고리즘, 핸드 평가는 BS-06-01~10 시나리오 문서를 참조한다.

EBS 게임 엔진은 포커 방송에서 실시간으로 카드 정보, 승률, 플레이어 통계를 화면에 표시하는 소프트웨어다. 이 문서는 그 엔진이 사용하는 모든 코드 번호, 데이터 구조, 계산 공식을 한곳에 모은 사전이다.

**데이터 흐름**:

```
정의 → 구조 → 인스턴스 → 계산 → 집계 → 출력 → API
Ch1     Ch2     Ch3        Ch4     Ch5     Ch6    Ch7
```

---

## 용어 사전

### 포커 용어

| 용어 | 설명 |
|------|------|
| 홀카드 | 각 플레이어에게 비공개로 배분되는 카드 |
| 보드 | 테이블 중앙에 공개되는 공용 카드 |
| 블라인드 | 게임 시작 전 의무적으로 거는 금액. SB = 소액, BB = 대액 |
| 앤티 | 모든 참가자가 게임 전에 내는 참가비 |
| 플롭 | 보드 카드 3장이 동시에 공개되는 단계 |
| 턴 | 보드 4번째 카드가 공개되는 단계 |
| 리버 | 보드 5번째, 마지막 카드가 공개되는 단계 |
| 폴드 | 카드를 버리고 현재 핸드를 포기 |
| 올인 | 보유 칩 전부를 베팅 |
| 쇼다운 | 마지막까지 남은 플레이어들이 카드를 공개하여 승패 결정 |
| 팟 | 해당 핸드에 걸린 총 금액 |
| 프리플롭 | 보드 공개 전, 홀카드만으로 베팅하는 첫 라운드 |
| 스트래들 | BB 다음 플레이어가 자발적으로 2배를 거는 특수 베팅 |
| 헤즈업 | 2인 대결 |
| 3벳 | 첫 레이즈에 대한 재레이즈 |
| CBet | 프리플롭 레이즈 플레이어가 플롭에서도 계속 베팅 |

### 기술 용어

| 용어 | 설명 |
|------|------|
| Enum | 선택지를 숫자로 매긴 번호표 |
| Bitmask | 각 비트로 여러 조건을 동시에 표현하는 숫자 방식 |
| LUT | 미리 계산해둔 정답표. 즉시 조회하여 실시간 성능 확보 |
| Monte Carlo | 무작위 시뮬레이션을 수만 번 반복하여 확률을 추정하는 계산법 |
| Protocol | 서버와 클라이언트 간 데이터 교환 규약 |
| DLL | 외부 라이브러리 파일. 특정 기능을 별도 모듈로 분리한 것 |
| Pseudocode | 실제 프로그래밍 언어가 아닌 로직 설명용 가상 코드 |
| RFID UID | RFID 태그의 고유 식별 번호 |

---

# Chapter 1: Enum Registry

게임 엔진은 모든 상태를 숫자로 관리한다. 게임 종류, 베팅 방식, 카드 공개 시점 등 모든 선택지에 고유 번호를 부여하며, 이 번호 체계를 Enum이라 부른다.

## 1.1 게임 Enum

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §2.5 game Enum. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

`game` enum으로 게임 종류를 식별한다.

| 값 | 이름 | 계열 | 특수 규칙 |
|:--:|------|:--:|----------|
| 0 | holdem | flop | 표준 홀덤 |

> 참고: `game` 1~21은 확장 게임이며 Tier 2~4 문서에서 정의한다.

> 주의: game enum 값 0이 Hold'em이다. 확장 게임 추가 시 Tier 2~4 문서를 참조한다.

---

## 1.2 게임 분류 Enum

### 1.2.1 game_class

게임을 계열로 분류. `cards_per_player` 필드와 연동하여 카드 처리 로직 결정.

| 값 | 이름 | 특징 |
|:--:|------|------|
| 0 | flop | 보드 5장 공개, 4 베팅 라운드 |

> 참고: `game_class` 1 = draw, 2 = stud는 Tier 3~4 문서에서 정의한다.

---

### 1.2.2 game_type

게임 진행 방식 분류 (캐시, 토너먼트, SNG 등). 서버 API의 `GAME_TYPE` 메시지로 설정.

| 값 | 이름 | 특징 |
|:--:|------|------|
| 0 | Cash | 개방형, 플레이어 자유 진/퇴, 바이인 재입금 가능 |
| 1 | Regular | 표준 토너먼트, 고정 진행, 엘리미네이션 |
| 2 | Bounty | 바운티 토너먼트, 탈락 시 상금 지급 |
| 3 | MysteryBounty | 미스터리 바운티, 랜덤 상금 |
| 4 | FlipAndGo | Flip & Go, 단축형 토너먼트 |
| 5 | Shootout | 슛아웃, 테이블별 승자 결정 |
| 6 | Satellite | 새틀라이트, 상위 이벤트 진출권 |
| 7 | SNG | Sit & Go, 고정 테이블, 자동 시작 |

---

### 1.2.3 bet_structure

베팅 제한 구조. `bet_structure` 필드에 저장, 베팅 최대값 (`cap`) 계산에 사용.

| 값 | 이름 | 베팅 규칙 | 예시 |
|:--:|------|---------|------|
| 0 | no_limit | 제한 없음 (스택까지) | 1/2 NL: 모든 사이즈 가능 |
| 1 | fixed_limit | 고정액 (라운드별 다름) | 1/2 FL: 소 바퀴 1, 큰 바퀴 2 |
| 2 | pot_limit | 팟의 3배까지 | 1/2 PL: 팟 + 콜액 × 3 |

> 참고: WSOP LIVE 이벤트 시스템은 `BlindType` enum (0=NoLimitHoldem, 1=HORSE, 2=Limits, 5=PotLimitOmaha, 6=Stud, 7=MixedGame)으로 게임+베팅을 혼합 분류한다. EBS에서는 `game` enum과 `bet_structure` enum을 분리하여 더 세밀하게 제어한다.

---

### 1.2.4 event_game_type

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §2.6 event_game_type Enum + §3.9 Mix Type 별 Rotation 매트릭스 + §5.13 Mixed Game Transition pseudocode. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

WSOP LIVE 이벤트에서 게임 계열을 지정하는 상위 분류. EBS의 `game` enum (0-21)이 세부 변형이라면, `event_game_type`은 이벤트 등록 시 사용하는 대분류다.

| 값 | 이름 | EBS `game` enum 매핑 |
|:--:|------|---------------------|
| 0 | Holdem | 0, 1, 2, 3 |
| 1 | Omaha | 4, 5, 6, 7, 8, 9, 10, 11 |
| 2 | Stud | 19, 20 |
| 3 | Razz | 21 |
| 4 | Lowball | 13, 14, 15 |
| 5 | HORSE | Mixed 순환 |
| 6 | DealerChoice | 임의 선택 |
| 7 | Mixed | 복합 게임 |
| 8 | Badugi | 16, 17, 18 |

#### Mixed Game Rotation & Button Freeze (WSOP LIVE 기준)

**원칙**: Mixed 토너먼트(HORSE, 8-Game, Mixed Omaha 등)에서 게임 전환은 **레벨 종료 시**에만 발생하며, 전환 핸드 동안 button은 freeze된다. 이는 WSOP LIVE Confluence의 "New Blind Type: Mixed Omaha" 문서 및 Rule 287-288(Stud 테이블 균형 포함)에 근거한다.

##### Mix Type별 Rotation 규칙

| Mix Type | Rotation 단위 | Button 이동 | Bet Structure 전환 | 참조 규정 |
|----------|--------------|:----------:|-------------------|----------|
| HORSE | 레벨 종료 시 전환 | **전환 핸드 freeze** | Limit 유지 (BB stud 포함) | Rule 287-288 |
| 8-Game | 레벨 종료 시 전환 | **전환 핸드 freeze** | 게임별 상이 (NL, PL, FL 혼합) | Rule 287-288 |
| Mixed Omaha (NEW) | 레벨 종료 시 전환 | **전환 핸드 freeze** | PLO ↔ Limit 교대 | New Blind Type: Mixed Omaha |
| Dealer's Choice | 매 핸드 딜러 선택 | 평소대로 이동 | 게임별 상이 | WSOP 별도 규정 |
| PPC (Player Pick) | 매 핸드 플레이어 선택 | 평소대로 이동 | 게임별 상이 | 비표준 |

##### State 필드 참조

관련 State 필드는 §2.1 GameState에 정의되어 있다:

- `mixed_game_sequence: List<GameDef>` — 전체 mix 순서
- `current_game_index: int` — 현재 게임 인덱스
- `game_transition_pending: bool` — 다음 핸드에서 전환 예정

**GameDef 구조** (pseudo):
```
GameDef {
    variant_name: str,      // "O8", "Razz", "Stud", "NLH", "PLO", etc.
    bet_structure: int,     // NL/PL/FL
    hole_card_count: int,   // variant에 따름
    level_hands: int?,      // null이면 레벨당 hand 수 무관 (시간 기반)
}
```

##### 전환 트리거

BO(Backoffice)가 blind level 종료 이벤트를 전파하면 엔진은 다음과 같이 처리한다:

```
1. 신규 Input Event 수신:
   SET_GAME_TRANSITION_PENDING { table_id }
   → state.game_transition_pending = true

2. 현재 핸드 HAND_COMPLETE 시 (IT-10 ButtonFreezeMixedGame 트리거):
   if state.game_transition_pending:
       state.current_game_index = (state.current_game_index + 1) % len(sequence)
       state.variantName = sequence[current_game_index].variant_name
       state.bet_structure = sequence[current_game_index].bet_structure
       // Button freeze: dealer_seat 유지 (이동 스킵)
       state.game_transition_pending = false
       emit OutputEvent.GameTransitioned {
           from: prev_game,
           to: current_game,
           button_frozen: true
       }
   else:
       state.dealer_seat = (state.dealer_seat + 1) % n  // 평소 이동
```

##### Stud 계열 테이블 균형 (Rule 288 보충)

Mix에 Stud 변형이 포함된 경우 table balance 시 high card rule을 적용한다:

- 대상 플레이어 선정: 모든 seat에 1장씩 open card 딜 → 가장 높은 카드 플레이어가 이동
- 현재 게임이 Stud이든 Flop 게임이든 **동일하게 적용** (Rule 288: "스터드 이벤트 또는 스터드 변형이 있는 혼합 이벤트의 테이블 균형을 조정할 때")
- EBS 엔진은 `BalancePlayerSelection` 이벤트를 BO로부터 수신하여 판정을 수행 (후속 CCR에서 별도 정의)

##### Contracts 영향 (후속 CCR 필요)

- `SET_GAME_TRANSITION_PENDING` Input Event: Team 2 BO와 Team 3 Engine 간 계약 필요 → `contracts/api/API-01` Part II 또는 `API-05` 확장
- `GameTransitioned` OutputEvent: Team 4 CC/Overlay와 Team 3 Engine 간 계약 필요 → `contracts/api/API-04` 확장
- 본 문서는 engine 내부 규정만 명시하고, 외부 계약은 별도 CCR로 처리한다.

---

### 1.2.5 event_flight_status

이벤트 진행 상태. EBS는 **Running** 상태에서만 게임 데이터를 처리한다. 나머지 상태는 상위 시스템에서 관리.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | Created | 이벤트 생성됨, 미공개 |
| 1 | Announce | 공지됨, 등록 전 |
| 2 | Registering | 등록 진행 중 |
| 4 | Running | **게임 진행 중** — EBS 활성 상태 |
| 5 | Completed | 이벤트 종료 |
| 6 | Canceled | 이벤트 취소 |

---

### 1.2.6 blind_detail_type

블라인드 구조 내 각 항목의 유형.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | Blind | 블라인드 레벨 |
| 1 | Break | 휴식 |
| 2 | DinnerBreak | 식사 휴식 |
| 3 | HalfBlind | 하프 블라인드 |
| 4 | HalfBreak | 하프 휴식 |

---

### 1.2.7 competition_type

대회 유형.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | WSOP | World Series of Poker 본대회 |
| 1 | WSOPC | WSOP Circuit |
| 2 | APL | Asian Poker League |
| 3 | APT | Asian Poker Tour |
| 4 | WSOPP | WSOP Paradise |

### 1.2.8 competition_tag

대회 태그.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | None | 태그 없음 |
| 1 | Bracelets | WSOP 브레이슬릿 이벤트 |
| 2 | Circuit | 서킷 이벤트 |
| 3 | SuperCircuit | 슈퍼 서킷 |

---

### 1.2.9 payout_assignment_progress

상금 지급 진행 상태.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | InProgress | 진행 중 |
| 1 | Eliminated | 탈락 |
| 2 | ITM | 입상 확정 |
| 3 | Confirmed | 금액 확인 |
| 4 | Paid | 지급 완료 |

---

## 1.3 앤티 Enum (7개 유형)

앤티 수집 방식을 정의. `ante_type` 필드에 저장, RFID 태그 시스템과 연동하여 앤티 수납 자동 추적.

| 값 | 이름 | 수집 방식 | 활용 |
|:--:|------|---------|------|
| 0 | std_ante | 모든 플레이어에게 균등 수집 | 일반 앤티 |
| 1 | button_ante | 딜러(버튼) 위치에서만 수집 | 버튼 앤티 규칙 |
| 2 | bb_ante | 빅블라인드 위치에서만 수집 | BB 앤티 (최신 고액 게임) |
| 3 | bb_ante_bb1st | BB 앤티 + BB 포스트 우선 (BB가 먼저 블라인드 올림) | BB 앤티 변형 |
| 4 | live_ante | 라이브 앤티 (수동 입력) | 라이브 토너먼트 |
| 5 | tb_ante | 테이블 뱅크 앤티 (중앙 풀 수집) | 특수 게임 |
| 6 | tb_ante_tb1st | 테이블 뱅크 앤티 + 순서 우선 | 테이블 뱅크 변형 |

> 참고: 앤티 수집 시 RFID로 각 플레이어 칩 개수 변화를 추적하며, `Player.stack` 업데이트 후 `Player.stats.session_ante_paid` 누적.

---

## 1.4 카드 공개 관련 Enum

### 1.4.1 card_reveal_type

홀카드 공개 시점. 게임 규칙과 무관하게 운영 정책으로 설정.

| 값 | 이름 | 공개 시점 | 용도 |
|:--:|------|---------|------|
| 0 | immediate | 카드 감지 직후 즉시 | 라이브 방송 표준 |
| 1 | after_action | 현재 플레이어 액션 후 | 액션 강조 |
| 2 | end_of_hand | 핸드 완료(쇼다운) 후 | 보수적 룰 |
| 3 | never | 절대 공개 안 함 | 히든 게임 (드문 경우) |
| 4 | showdown_cash | 쇼다운 시만, 캐시 게임 | 캐시 전용 |
| 5 | showdown_tourney | 쇼다운 시만, 토너먼트 | 토너먼트 전용 |

---

### 1.4.2 show_type

액션 플레이어 표시 시점.

| 값 | 이름 | 표시 시점 | 용도 |
|:--:|------|---------|------|
| 0 | immediate | 즉시 표시 | 표준 |
| 1 | action_on | 액션 시 표시 | 강조 효과 |
| 2 | after_bet | 베팅 후 표시 | 지연 효과 |
| 3 | action_on_next | 다음 플레이어 액션 시 전환 | 부드러운 전환 |

---

### 1.4.3 fold_hide_type

폴드 카드 숨김 시점.

| 값 | 이름 | 숨김 시점 | 용도 |
|:--:|------|---------|------|
| 0 | immediate | 폴드 직후 즉시 | 표준 |
| 1 | delayed | 액션 완료 후 일괄 숨김 | 시각적 혼란 방지 |

---

### 1.4.4 hilite_winning_hand_type

승자 카드 강조 표시 조건.

| 값 | 이름 | 강조 조건 | 용도 |
|:--:|------|---------|------|
| 0 | never | 표시 안 함 | 보수적 |
| 1 | immediate | 즉시 표시 | 표준 |
| 2 | showdown_or_winner_all_in | 쇼다운 또는 올인 승리 | 균형 |
| 3 | showdown | 쇼다운 시만 표시 | 쇼다운 우선 |

---

### 1.4.5 BoardRevealStage

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §2.3 BoardRevealStage Enum — 단, 보드 카드 감지 로직은 BS-06-12 권위 (Triggers 도메인 §3.5 T4-T8 atomic flop). 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

보드 공개 진행 단계. Flop games에서 현재 보드 상태 추적.

| 값 | 이름 | 상태 | board_cards[0] |
|:--:|------|------|:-------:|
| 0 | None | 초기 상태 (카드 없음) | undefined |
| 1 | Flop | 플롭 공개 (3장) | 3 |
| 2 | Turn | 턴 공개 (4장) | 4 |
| 3 | River | 리버 공개 (5장) | 5 |

---

## 1.5 핸드 평가 Enum

**HandEvaluator**는 카드 조합의 강도를 평가하는 핸드 평가 모듈이다.

### 1.5.1 HandRank

포커 핸드 랭킹. **HandEvaluator**의 `HandType` enum으로 정의. Bitmask 기반 계산.

| 값 | 이름 | 조건 | 포함 게임 |
|:--:|------|------|----------|
| 0 | HighCard | 쌍 없음 | 모든 하이 게임 |
| 1 | Pair | 같은 랭크 2장 | 모든 하이 게임 |
| 2 | TwoPair | 서로 다른 쌍 2개 | 모든 하이 게임 |
| 3 | Trips | 같은 랭크 3장, Three of a Kind | 모든 하이 게임 |
| 4 | Straight | 연속 랭크 5장, 에이스는 로우/하이 가능 | 모든 하이 게임 |
| 5 | Flush | 같은 수트 5장 | 모든 하이 게임 |
| 6 | FullHouse | Trips + Pair | 모든 하이 게임 |
| 7 | FourOfAKind | 같은 랭크 4장, Quads | 모든 하이 게임 |
| 8 | StraightFlush | Straight + Flush — Royal Flush는 A-high Straight Flush | 모든 하이 게임 |

> 주의: RoyalFlush는 별도 enum이 아니며 StraightFlush — A-high로 표현됨.

---

### 1.5.2 PlayerStatus

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §2.4 PlayerStatus Enum. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

플레이어 게임 중 상태.

| 값 | 이름 | 의미 | 전환 조건 |
|:--:|------|------|----------|
| 0 | **active** | 활성, 액션 가능 | 핸드 시작, 폴드 해제 |
| 1 | **folded** | 폴드됨, 해당 핸드 제외 | FOLD 액션 후 |
| 2 | **allin** | 올인, 스택 0, 쇼다운 진행 | BET/CALL로 스택 전부 소진 |
| 3 | **eliminated** | 탈락, 토너먼트 | 스택 0 + 재입금 불가 |
| 4 | **sitting_out** | 관전, 현재 핸드 불참 | 플레이어 관전 모드 전환 |

---

## 1.6 렌더링/애니메이션 Enum

**Renderer**는 카드 애니메이션과 UI 요소의 렌더링 파이프라인을 담당하는 모듈이다.

### 1.6.1 AnimationState (16개)

카드/UI 요소 애니메이션 상태. **Renderer** 모듈의 렌더링 파이프라인에서 관리.

| 값 | 이름 | 트리거 | 지속 시간 |
|:--:|------|--------|:-------:|
| 0 | FadeIn | 카드 첫 등장 | ~300ms |
| 1 | Glint | 반짝임 시작 | ~200ms |
| 2 | GlintGrow | 반짝임 확대 | ~500ms |
| 3 | GlintRotateFront | 반짝임 회전 (앞) | ~400ms |
| 4 | GlintShrink | 반짝임 축소 | ~300ms |
| 5 | PreStart | 사전 준비 | ~100ms |
| 6 | ResetRotateBack | 리셋 회전 (뒤) | ~400ms |
| 7 | ResetRotateFront | 리셋 회전 (앞) | ~400ms |
| 8 | Resetting | 리셋 중 | ~500ms |
| 9 | RotateBack | 회전 (뒤) | ~300ms |
| 10 | Scale | 스케일 변환 | ~200ms |
| 11 | SlideAndDarken | 슬라이드 + 어두워짐 | ~400ms |
| 12 | SlideDownRotateBack | 아래로 슬라이드 + 회전 | ~500ms |
| 13 | SlideUp | 위로 슬라이드 | ~300ms |
| 14 | Stop | 정지 | 무한 |
| 15 | Waiting | 대기 | ~600ms |

---

### 1.6.2 GfxPanelType (20개)

플레이어 패널 통계 유형. 각 플레이어 위 표시되는 정보 박스 유형.

| 값 | 이름 | 표시 내용 | 단위 |
|:--:|------|---------|------|
| 0 | None | 패널 없음 | — |
| 1 | ChipCount | 칩 스택 | 칩 또는 BB |
| 2 | VPiP | VPIP — 자발적 팟 참여율 | % (0-100) |
| 3 | PfR | PfR — 프리플롭 레이즈율 | % (0-100) |
| 4 | Blinds | 블라인드 포지션 | 포지션명 |
| 5 | Agr | 공격성 지수 | % (0-200+) |
| 6 | WtSd | 쇼다운까지 진행율 | % (0-100) |
| 7 | Position | 포지션 명칭 | SB/BB/UTG 등 |
| 8 | CumulativeWin | 누적 승리 | 칩 |
| 9 | Payouts | 지급액 (토너먼트) | 달러 |
| 10 | PlayerStat1 | 커스텀 통계 1 | 가변 |
| 11 | PlayerStat2 | 커스텀 통계 2 | 가변 |
| 12 | PlayerStat3 | 커스텀 통계 3 | 가변 |
| 13 | PlayerStat4 | 커스텀 통계 4 | 가변 |
| 14 | PlayerStat5 | 커스텀 통계 5 | 가변 |
| 15 | PlayerStat6 | 커스텀 통계 6 | 가변 |
| 16 | PlayerStat7 | 커스텀 통계 7 | 가변 |
| 17 | PlayerStat8 | 커스텀 통계 8 | 가변 |
| 18 | PlayerStat9 | 커스텀 통계 9 | 가변 |
| 19 | PlayerStat10 | 커스텀 통계 10 | 가변 |

---

### 1.6.3 transition_type

화면 전환 애니메이션 유형.

| 값 | 이름 | 효과 | 지속 시간 |
|:--:|------|------|:-------:|
| 0 | fade | 페이드 인/아웃 | ~300ms |
| 1 | slide | 슬라이드 진입 | ~400ms |
| 2 | pop | 튀어나옴 | ~200ms |
| 3 | expand | 확장 | ~250ms |

---

## 1.7 레이아웃/표시 Enum

### 1.7.1 board_pos_type

보드(커뮤니티 카드) 위치.

| 값 | 이름 | 화면 위치 |
|:--:|------|---------|
| 0 | left | 좌측 |
| 1 | centre | 중앙 |
| 2 | right | 우측 |

---

### 1.7.2 chipcount_disp_type

칩 개수 표시 형식.

| 값 | 이름 | 표시 예시 |
|:--:|------|----------|
| 0 | amount | 절대값 (5000) |
| 1 | bb_multiple | BB 배수 (250 BB) |
| 2 | both | 둘 다 표시 (5000 / 250 BB) |

---

### 1.7.3 auto_blinds_type

자동 블라인드 상향 규칙.

| 값 | 이름 | 상향 조건 |
|:--:|------|---------|
| 0 | never | 수동 상향만 |
| 1 | every_hand | 매 핸드마다 (드문 경우) |
| 2 | new_level | 새 레벨 도달 시 |
| 3 | with_strip | Strip 업데이트와 함께 |

---

### 1.7.4 equity_show_type

Equity 표시 시점.

| 값 | 이름 | 표시 시점 |
|:--:|------|---------|
| 0 | start_of_hand | 핸드 시작 (플롭 후) |
| 1 | after_first_betting_round | 첫 베팅 라운드 후 |

---

### 1.7.5 outs_show_type

아웃(승리 가능 카드) 표시 조건.

| 값 | 이름 | 표시 조건 |
|:--:|------|---------|
| 0 | never | 표시 안 함 |
| 1 | heads_up | 헤즈업 시만 |
| 2 | heads_up_all_in | 헤즈업 + 올인 시 |

---

## 1.8 로그/이벤트 Enum

### 1.8.1 log event_type

핸드 진행 이벤트 로그 유형.

| 값 | 이름 | 설명 | 기록 대상 |
|:--:|------|------|---------|
| 0 | bet | 베팅 액션 | 금액 + 플레이어 |
| 1 | call | 콜 액션 | 금액 (엔진 자동 계산값) |
| 2 | all_in | 올인 | 스택 (엔진 자동 계산값) |
| 3 | fold | 폴드 | 플레이어 |
| 4 | board | 보드 공개 | 카드 |
| 5 | discard | 카드 버림 | 개수 |
| 6 | check | 체크 | 플레이어 |
| 7 | raise | 레이즈 | 금액 + 플레이어 |
| 8 | chop | 칩 합의 분배 | 분배액 |
| 9 | next_run_out | 런잇타임 다음 보드 | 보드 카드 |
| 10 | hand_start | 핸드 시작 | 딜러 좌석 + 블라인드 |
| 11 | hand_end | 핸드 종료 | — |
| 12 | deal_hole | 홀카드 배분 | 좌석별 카드 |
| 13 | misdeal | 미스딜 | — |
| 14 | pot_awarded | 팟 지급 | 좌석별 금액 |
| 15 | timeout_fold | 타임아웃 폴드 | 플레이어 |
| 16 | muck | 머크/쇼 결정 | 플레이어 + showCards |

> **call, all_in의 금액**: Ch7.6.2에 정의된 대로 엔진이 자동 계산한 실제 적용 금액을 기록한다. 외부 입력값이 아니다.

---

## 1.9 게임 페이즈 Enum

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §2.2 game_phase Enum + §2.1 Hold'em FSM 상태 흐름 다이어그램. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

게임 진행 단계. `game_phase` 필드에 저장.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | **IDLE** | 대기 |
| 1 | **SETUP_HAND** | 핸드 준비 |
| 2 | **PRE_FLOP** | 프리플롭 베팅 |
| 3 | **FLOP** | 플롭 공개 + 베팅 |
| 4 | **TURN** | 턴 공개 + 베팅 |
| 5 | **RIVER** | 리버 공개 + 베팅 |
| 6 | **SHOWDOWN** | 카드 공개, 승패 결정 |
| 7 | **HAND_COMPLETE** | 핸드 종료 |
| 17 | **RUN_IT_MULTIPLE** | 런잇타임 진행 |

> 참고: Draw 게임 페이즈 8~11, Stud 게임 페이즈 12~16은 Tier 3~4 문서에서 정의한다.

**Hold'em 페이즈 흐름**:

```
IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

---

# Chapter 2: Data Model

Ch1에서 정의한 Enum들이 실제로 어떤 데이터 묶음에 담기는지 정의한다. 게임 상태, 플레이어, 카드, 팟 등 엔진이 관리하는 모든 데이터의 필드명과 타입을 명시한다.

## 2.1 GameState (최상위 핸드 상태)

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §5.1 GameState 28 필드 (`bomb_pot_opted_out` / `mixed_game_sequence` / `tournament_heads_up` 등 WSOP Rule 28.3.2/87/88/100.b 의존 state 포함). 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

현재 진행 중인 핸드의 전체 게임 상태를 한 덩어리로 묶은 구조다. 방송 화면에 보이는 모든 정보 — 보드 카드, 팟 금액, 플레이어 칩 — 가 이 구조에서 나온다. 서버는 이 데이터를 `GameInfoResponse`(게임 정보 응답) 메시지로 클라이언트에 전송한다.

| 필드 | 타입 | 설명 | 범위/제약 |
|------|------|------|---------|
| hand_number | int | 현재 핸드 번호 | 1+ (누적) |
| game | int | 게임 종류 | 0 = Hold'em |
| game_class | int | 게임 계열 | 0 = flop |
| bet_structure | int | 베팅 구조 | 0-2 (NL/FL/PL) |
| ante_type | int | 앤티 유형 | 0-6 (7가지) |
| game_phase | int | 현재 단계 | 0-17, game_phase enum (1.10 참조) |
| players | Player[] | 모든 플레이어 | 최대 10명 (seats 0-9) |
| board_cards | Card[] | 보드 카드 | 0-5장 |
| pot | Pot | 메인 팟 | amount >= 0 |
| side_pots | Pot[] | 사이드 팟 | 빈 배열 또는 1+ |
| dealer_seat | int | 딜러 버튼 위치 | 0-9 또는 -1 (미할당) |
| blinds | Blinds | 블라인드 정보 | 구조체 |
| action_on | int | 현재 액션 플레이어 좌석 | 0-9 또는 -1 (없음) |
| hand_in_progress | bool | 핸드 진행 중 | true/false |
| board_reveal_stage | int | 보드 공개 진행도 | 0-3 (None/Flop/Turn/River) |
| event_game_type | int | 이벤트 게임 대분류 | 0-8, event_game_type enum |
| event_flight_status | int | 이벤트 진행 상태 | 0-6, event_flight_status enum |
| competition_type | int | 대회 유형 | 0-4, competition_type enum |
| table_id | int | 테이블 식별자 | 1+ |
| table_no | int | 테이블 표시 번호 | 1+ |
| is_feature_table | bool | 중계 테이블 여부 | true/false |
| prev_hand_bb_seat | int? | 직전 핸드에서 BB였던 플레이어 seat index. 헤즈업 전환 시 "연속 BB 방지" button 조정용 (WSOP Rule 87, BS-06-03 §Heads-up 전환 참조). HAND_COMPLETE 시 현재 `bbSeat`를 복사, 신규 핸드 시작 전 유지 | -1 또는 0-9 |
| boxed_card_count | int | 현재 핸드에서 RFID가 감지한 boxed card(face-up 상태 딜링) 누적 수. 2 이상이면 Rule 88에 따라 misdeal 트리거 (BS-06-08 매트릭스 5 참조) | 0+, HAND_COMPLETE/MisDeal 시 0으로 리셋 |
| tournament_heads_up | bool | 전체 토너먼트에 2명만 남은 상태. FL 게임의 raise cap 무시 판정 기준 (WSOP Rule 100.b, BS-06-02 §5.2 참조). BO가 `SET_TOURNAMENT_HEADS_UP` 이벤트로 설정. Cash game은 항상 false | true/false, 기본 false |
| bomb_pot_opted_out | Set<int> | 현재 bomb pot 핸드에서 opt-out한 플레이어 seat indexes. Button freeze로 position equity 보존 (WSOP Rule 28.3.2, BS-06-01 §Bomb Pot 참조). HAND_COMPLETE 시 clear | 빈 Set 또는 seat indexes |
| mixed_game_sequence | List<GameDef> | Mixed 토너먼트의 전체 mix 순서 (예: HORSE=[Hold'em, O8, Razz, Stud, Stud8] 5종 FL — Foundation §10). null이면 단일 게임 모드. Rule 100.b 및 New Blind Type: Mixed Omaha 참조 | null 또는 1+ 요소 |
| current_game_index | int | `mixed_game_sequence`에서 현재 게임 인덱스. 전환 시 `(index + 1) % len` 진행. 단일 게임 모드에서는 0 고정 | 0+ |
| game_transition_pending | bool | 다음 핸드에서 게임 전환이 예정된 상태. BO가 레벨 종료 시 설정. 전환 핸드의 HAND_COMPLETE에서 button freeze 트리거 (Mixed Omaha New Blind Type 참조) | true/false, 기본 false |

> 예시: Hold'em NL 1/2, 플롭 직후 상태
> `hand_number=47, game=0, game_class=0, bet_structure=0, game_phase=3(FLOP), board_cards=["As","Kh","7d"], board_reveal_stage=1, action_on=3`

---

## 2.2 Player (플레이어 상태)

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §5.2 Player 15 필드 (`missed_sb` / `missed_bb` / `cards_tabled` 등 WSOP Rule 71/86 의존 state 포함). 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

게임 테이블의 개별 플레이어 정보. 좌석별 배열로 관리.

| 필드 | 타입 | 설명 | 범위/제약 |
|------|------|------|---------|
| name | string | 플레이어 이름 | 최대 30자 |
| seat | int | 좌석 번호 | 0-9 |
| stack | int | 현재 칩 스택 | 0+ (단위: 칩) |
| hole_cards | Card[] | 홀카드 | 2장 |
| status | string | 상태 | "active", "folded", "allin", "eliminated", "sitting_out" |
| position | string | 포지션명 | "SB", "BB", "UTG", "HJ", "CO", "BTN" 등 |
| stats | PlayerStats | 누적 통계 | 구조체 |
| profile_pic | string | 프로필 사진 URL | URI 또는 null |
| reentry_count | int | 재진입 횟수 | 0+ |
| sit_in_status | int | 착석 상태 (대기→순번→착석 3단계) | 0=None, 1=Queueing(대기열), 2=Waiting(순번 대기), 3=Seating(착석 중) |
| join_type | int | 참가 경로 | 0=APP, 1=SPOT, 2=STAFF |
| missed_sb | bool | 최근 lap에서 SB 포지션을 놓친 상태 (sit out 등). 복귀 시 포스팅 의무 발생 (WSOP Rule 86, BS-06-03 §Missed Blind 참조) | true/false, 기본 false |
| missed_bb | bool | 최근 lap에서 BB 포지션을 놓친 상태 (sit out 등). 복귀 시 포스팅 의무 발생 (WSOP Rule 86, BS-06-03 §Missed Blind 참조) | true/false, 기본 false |
| cards_tabled | bool | 플레이어가 테이블 위에 카드를 명시적으로 공개한 상태. true일 때 dealer/engine의 임의 muck 처리가 금지됨 (WSOP Rule 71, BS-06-07 §7 핸드 보호 참조). HAND_COMPLETE 시 false로 리셋 | true/false, 기본 false |

---

## 2.3 Card (카드 표현)

단일 카드 정보. RFID UID와 표시 문자 포함.

| 필드 | 타입 | 설명 | 범위/제약 |
|------|------|------|---------|
| suit | int | 수트 | 0=Club, 1=Diamond, 2=Heart, 3=Spade |
| rank | int | 랭크 | 0=2, 1=3, ..., 11=K, 12=A |
| uid | string | RFID 태그 UID | 16자 16진 문자열 또는 null |
| display | string | 표시 문자 | "2c", "As", "Kh" 등 |

**표시 형식**: 랭크('2'-'9', 'T', 'J', 'Q', 'K', 'A') + 수트('c', 'd', 'h', 's')

---

## 2.4 Pot (팟 정보)

메인 팟 또는 사이드 팟 정보.

| 필드 | 타입 | 설명 | 범위/제약 |
|------|------|------|---------|
| amount | int | 팟 금액 | 0+ (칩 단위) |
| eligible_players | int[] | 참여 자격 있는 플레이어 좌석 | 1+ (좌석 인덱스) |

**사이드 팟 발생**: 플레이어 올인 → 올인 금액까지만 메인 팟 → 초과분 사이드 팟 생성.

---

## 2.5 Blinds (블라인드 정보)

현재 핸드의 블라인드 액터.

| 필드 | 타입 | 설명 | 범위/제약 |
|------|------|------|---------|
| small_blind | int | SB 금액 | 0+ |
| big_blind | int | BB 금액 | 0+ (일반적으로 SB × 2) |
| ante | int | 앤티 금액 | 0+ |
| straddle | int | 스트래들 금액 (특수) | 0+ |
| min_chip | int | 최소 칩 단위 | 1+ (베팅 최소 단위) |

---

## 2.6 GameTypeData (게임 구성 데이터)

게임 엔진의 모든 파라미터를 저장하는 61개 필드.

### 2.6.1 게임 흐름 제어 (8개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| hand_in_progress | bool | 핸드 진행 중 | true/false |
| action_on | int | 현재 액션 플레이어 좌석 | 0-9, -1 |
| prev_action_on | int | 이전 액션 플레이어 | 0-9, -1 |
| next_hand_ok | bool | 다음 핸드 시작 가능 | true/false |
| final_betting_round | bool | 최종 베팅 라운드 (리버) | true/false |
| cards_on_table | bool | 보드 카드 테이블 위 | true/false |
| hand_count | int | 누적 핸드 번호 | 1+ |
| allow_at_updates | bool | ActionTracker 업데이트 허용 | true/false |

---

### 2.6.2 게임 분류 (7개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| game_class | int | 게임 계열 | 0 = flop |
| game_type | int | 게임 방식 | 0 (Cash), 1 (Regular) 등 |
| game_variant | string | 게임명 | "Hold'em" |
| game_variant_list | GameVariant[] | 게임 변형 리스트 | 배열 |
| bet_structure | int | 베팅 구조 | 0 (NL), 1 (FL), 2 (PL) |
| ante_type | int | 앤티 유형 | 0-6 |
| enhanced_mode | bool | 향상된 모드 | true/false |

---

### 2.6.3 테이블 구조 (14개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| num_seats | int | 테이블 좌석 수 | 6, 8, 9, 10 |
| pl_dealer | int | 딜러 좌석 | 0-9 |
| pl_small | int | SB 좌석 | 0-9 |
| pl_big | int | BB 좌석 | 0-9 |
| pl_third | int | 서드 (선택사항) | 0-9 또는 -1 |
| num_blinds | int | 블라인드 개수 | 0 (없음), 1 (BB만), 2 (SB+BB), 3 (SB+BB+3) |
| small | int | SB 금액 | 0+ |
| big | int | BB 금액 | 0+ |
| third | int | 서드 금액 | 0+ 또는 0 |
| ante | int | 앤티 금액 | 0+ |
| button_blind | int | 버튼 블라인드 (특수) | 0+ 또는 0 |
| bring_in | int | Bring-in (스터드) | 0+ |
| smallest_chip | int | 최소 칩 단위 | 1+ (베팅 정밀도) |
| blind_level | int | 블라인드 레벨 | 1+ (토너먼트 진행도) |

---

### 2.6.4 베팅 상태 (8개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| biggest_bet_amt | int | 현재 라운드 최대 베팅액 | 0+ |
| min_raise_amt | int | 최소 레이즈액 | 이전 raise increment 또는 `high_limit` |
| cap | int | 베팅 캡 (고정 리밋) | 0 (NL/PL) 또는 4+ (FL) |
| low_limit | int | 저가 리밋 (고정 리밋) | 0 또는 low_한계 |
| high_limit | int | 고가 리밋 (고정 리밋) | 0 또는 high_한계 |
| predictive_bet | bool | 예측 베팅 표시 | true/false |
| bomb_pot | int | 봄 팟 금액 | 0 (없음) 또는 금액 |
| seven_deuce | int | 7-2 게임 상태 | 0 (비활성) 또는 상태값 |

---

### 2.6.5 보드/카드 상태 (8개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| board_cards | string[] | 보드 카드 배열 | ["As", "Kh", "Qd"] 또는 빈 배열 |
| num_boards | int | 보드 개수 (런잇타임) | 1 (표준) 또는 2+ |
| cards_per_player | int | 플레이어 홀카드 수 | 2 (홀덤), 4 (오마하), 5 (파이어플) |
| extra_cards_per_player | int | 추가 카드 수 | 0 (없음) 또는 1+ |
| cards_max_len | int | 최대 카드 문자열 길이 | 2 ("As") |
| num_active_players | int | 활성 플레이어 수 | 1-10 |
| card_rescan | bool | 카드 재스캔 필요 | true/false |
| card_verify_mode | bool | 카드 검증 모드 | true/false |

---

### 2.6.6 런잇타임 (5개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| run_it_times | int | 런잇타임 횟수 | 0 (비활성) 또는 2-4 |
| run_it_times_remaining | int | 남은 런 횟수 | 0-run_it_times |
| run_it_timesboard_cards | int | 각 런의 보드 카드 수 | 0-5 |
| can_select_run_it_times | bool | 플레이어 선택 가능 | true/false |
| can_trigger_next_board | bool | 다음 보드 진행 가능 | true/false |

---

### 2.6.7 칩 합의 (4개 필드)

| 필드 | 타입 | 설명 | 값 예시 |
|------|------|------|--------|
| xfer_cumwin | bool | 누적 승리 이전 | true/false |
| can_chop | bool | 칩 합의 가능 | true/false |
| is_chopped | bool | 칩 합의 진행 중 | true/false |
| overrideButton | bool | 자동 다음 핸드 | true/false |

---

## 2.7 PlayerStats (플레이어 누적 통계)

게임 진행 중 누적되는 개별 플레이어 통계.

| 필드 | 타입 | 설명 | 계산식 |
|------|------|------|--------|
| vpip | float | VPIP — 자발적 팟 참여율 | (참여 핸드 수) / (전체 핸드 수) × 100 |
| pfr | float | PfR — 프리플롭 레이즈율 | (레이즈 핸드 수) / (전체 핸드 수) × 100 |
| wtsd | float | WTSD — 쇼다운 진행율 | (쇼다운 진행 핸드) / (참여 핸드) × 100 |
| agr | float | Aggressiveness | (베팅+레이즈) / (총 액션) × 100 |
| cumulative_win | int | 누적 승리 칩 | session 시작 대비 증감 |
| session_ante_paid | int | 세션 앤티 수납액 | 누적 앤티 |
| hands_played | int | 참여 핸드 수 | 누적 카운트 |
| hands_seen_flop | int | 플롭 본 핸드 | 누적 카운트 |
| hands_to_showdown | int | 쇼다운 진행 핸드 | 누적 카운트 |
| three_bet_pct | float | 3Bet% | (3벳 횟수) / (3벳 기회) × 100 |
| cbet_pct | float | CBet% | (CBet 횟수) / (CBet 기회) × 100 |

---

# Chapter 3: Hold'em 게임 설정

Ch1의 Enum과 Ch2의 Data Model이 Hold'em에서 어떤 값을 갖는지 정의한다.

| 속성 | 값 |
|------|---|
| `game_id` | 0 |
| `game_class` | 0 — flop |
| `hole_cards` | 2 |
| `board_cards` | 5 |
| `draw_count` | 0 |
| `evaluator` | standard_high |
| `deck_size` | 52 |
| `hi_lo` | N |
| `forced_bet` | blind |
| `betting_rounds` | 4 |
| 규칙 | best 5 of 7 |

> 참고: game 1~21의 설정은 Tier 2~4 확장 문서에서 정의한다.

Hold'em 설정이 확정되면, 방송 중 실시간으로 계산해야 할 값이 두 가지다: **승률**(Ch4)과 **플레이어 통계**(Ch5). 아래에서 순서대로 정의한다.

---

# Chapter 4: Equity Calculation

게임 설정이 정해지면, 방송 중 화면에 실시간 승률을 표시해야 한다. 이 Chapter는 승률 계산 알고리즘과 성능 요구사항을 정의한다.

**4.1 Street별 계산 방법**

| 스트리트 | 알려진 카드 | 계산 방법 | 성능 |
|----------|-----------|----------|------|
| Pre-Flop | 홀카드만 | PocketHand169 LUT 즉시 조회 | <1ms |
| Flop | 홀카드 + 보드 3장 | Monte Carlo (Turn + River 시뮬레이션) | <200ms |
| Turn | 홀카드 + 보드 4장 | Monte Carlo (River 1장 시뮬레이션) | <100ms |
| River | 홀카드 + 보드 5장 | 확정 평가 (시뮬레이션 불필요) | <1ms |

**4.2 Monte Carlo Pseudocode**

Monte Carlo 승률 계산은 4단계로 진행된다:

1. 아직 공개되지 않은 카드(덱 잔여분)를 무작위로 섞는다
2. 부족한 보드 카드를 채워 가상의 완성 보드를 만든다
3. 각 플레이어의 홀카드 + 완성 보드로 핸드를 평가하여 승자를 판정한다
4. 위 과정을 10,000회 반복한 뒤, 각 플레이어의 승리 비율을 백분율로 환산한다

```
function calculate_equity(known_cards, board, players, N=10000):
    deck = full_deck - known_cards - board
    wins = [0] * len(players)
    ties = [0] * len(players)
    
    for i in range(N):
        remaining = shuffle(deck)
        # Deal missing board cards
        sim_board = board + remaining[:5 - len(board)]
        remaining = remaining[5 - len(board):]
        
        # Evaluate each player's hand
        ranks = []
        for p in players:
            if p.status == folded: continue
            ranks.append(evaluate(p.hole_cards, sim_board, game_type))
        
        # Find winner(s)
        best = max(ranks)
        winners = [j for j, r in enumerate(ranks) if r == best]
        if len(winners) == 1:
            wins[winners[0]] += 1
        else:
            for w in winners: ties[w] += 1.0 / len(winners)
    
    # Calculate percentages
    equity = []
    for p in range(len(players)):
        eq = (wins[p] + ties[p]) / N * 100
        equity.append(round(eq, 1))
    
    return equity
```

**4.3 성능 요구사항**

| 항목 | 요구값 |
|------|-------|
| Monte Carlo iteration | N = 10,000 |
| 최대 허용 지연 | 200ms (방송 실시간) |
| 동시 계산 플레이어 | 2~10명 |
| LUT 기반 평가 | 1회 < 0.01ms |
| Pre-Flop LUT 항목 | 169개 starting hand |

**4.4 재계산 트리거**

| 이벤트 | 재계산 |
|--------|--------|
| 보드 카드 공개 (RFID) | 전원 equity 재계산 |
| 홀카드 공개 (RFID) | 해당 플레이어 포함 재계산 |
| 플레이어 Fold | 해당 플레이어 제외 재계산 |
| All-in | equity bar 확장 표시 트리거 |

**4.5 Outs 계산**

| 조건 | 동작 |
|------|------|
| outs_show_type == never | 계산 안 함 |
| outs_show_type == heads_up | 2인 시만 표시 |
| outs_show_type == heads_up_all_in | 2인 + 올인 시만 표시 |

Outs = 다음 카드 1장으로 현재 열세 플레이어가 역전 가능한 카드 수

---

# Chapter 5: Statistics Engine

방송 화면에는 승률 외에도 플레이어별 누적 통계가 표시된다. 8개 지표의 계산 공식과 표시 방법을 정의한다.

**5.1 8개 Player Statistics**

방송 해설진과 시청자가 플레이어의 플레이 스타일을 즉시 파악할 수 있도록, 다음 8개 지표를 실시간 계산하여 오버레이에 표시한다.

| 값 | 축약어 | 공식 | 설명 |
|:--:|--------|------|------|
| 1 | VPIP | (PF Call/Raise 핸드) / (총 핸드) × 100 | 자발적 팟 참여율. BB check 제외 |
| 2 | PFR | (PF Raise 핸드) / (총 핸드) × 100 | 프리플롭 레이즈율 |
| 3 | AGR | (Bet + Raise) / Call | 공격성 지수. 1 초과 = 공격적, 1 미만 = 소극적. 전 스트리트 합산 |
| 4 | WTSD | (쇼다운 핸드) / (Flop 참여 핸드) × 100 | 쇼다운 진행율 |
| 5 | 3Bet% | (3벳 횟수) / (3벳 기회) × 100 | PF 3벳 빈도. 앞에 raise 있는 상황 기준 |
| 6 | CBet% | (CBet 횟수) / (CBet 기회) × 100 | PF raiser의 Flop bet 빈도 |
| 7 | WIN% | (승리 핸드) / (총 핸드) × 100 | 팟 획득율 |
| 8 | AFq | (Bet+Raise) / (전체 액션) × 100 | 공격 빈도. Fold 포함 전체 액션 기준. AGR과 차이: AGR은 Call 대비 비율, AFq는 전체 대비 % |

> 예시: 10번 액션 중 3번 Bet, 2번 Raise, 3번 Call, 2번 Fold이면:
> AGR = (3+2) / 3 = 1.67 (공격적), AFq = (3+2) / 10 × 100 = 50%

**5.2 GfxPanelType 매핑**

GfxPanelType은 방송 화면에서 플레이어 이름 옆에 표시되는 **정보 칸의 종류**를 결정하는 번호다. 예를 들어 "칩 수량을 보여줄지, VPIP를 보여줄지" 선택.

| GfxPanelType | 표시 내용 | 포맷 |
|:------------:|----------|------|
| 1 (ChipCount) | 현재 칩 스택 | chipcount_disp_type에 따라 amount/BB/both |
| 2 (VPiP) | VPIP % | XX.X% |
| 3 (PfR) | PFR % | XX.X% |
| 4 (Blinds) | 현재 블라인드 레벨 | SB/BB |
| 5 (Agr) | AGR factor | X.X |
| 6 (WtSd) | WTSD % | XX.X% |
| 7 (Position) | 좌석 포지션 | SB/BB/UTG/HJ/CO/BTN |
| 8 (CumulativeWin) | 누적 수익 | ±금액 |
| 9 (Payouts) | 토너먼트 상금 | 금액 |
| 10-19 (PlayerStat1-10) | 커스텀 통계 | 설정 가능 |

**5.3 Auto-Stats Configuration**

| 설정 | 설명 | 기본값 |
|------|------|--------|
| auto_stats_first_hand | 통계 자동 표시 시작 핸드 수 | 설정 가능 |
| auto_stats_hand_interval | 통계 갱신 주기 (핸드 단위) | 설정 가능 |
| equity_show_type | 시작 시점 | start_of_hand(0) 또는 after_first_betting_round(1) |

**5.4 Ticker Statistics**

하단 티커에 표시되는 통계:
chipcount, vpip, pfr, agr, wtsd (strip_display_type으로 제어)

---

# Chapter 6: Display Configuration Reference

Ch4의 승률과 Ch5의 통계가 실제 방송 화면에 어떻게 배치되는지 설정한다. 38개 이상의 표시 설정 필드를 카테고리별로 정리한다.

**방송 화면 영역 구조**:

```
+---------------------------------------------+
|  [Leaderboard]              [Vanity Banner]  |
|                                              |
|    P1[Panel]  P2[Panel]  P3[Panel]           |
|          [ Board Cards (5장) ]               |
|              [ Pot 금액 ]                    |
|    P4[Panel]  P5[Panel]  P6[Panel]           |
|                                              |
|  [Ticker Strip: VPIP | PFR | AGR | ...]     |
+---------------------------------------------+

Panel = 플레이어 이름 + 칩 + 홀카드 + 통계(GfxPanelType)
Ticker = 하단 흐르는 통계 텍스트
Leaderboard = 토너먼트 순위 / 상금 표시
```

**6.1 DisplayConfig 필드 그룹**

오버레이 렌더링 설정을 제어하는 38개 이상의 필드. 카테고리별 분류:

**카드 표시 설정**

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| card_reveal_type | enum (0-5) | 홀카드 공개 시점 | immediate(0) |
| show_type (at_show) | enum (0-3) | 카드 표시 트리거 | immediate(0) |
| fold_hide_type | enum (0-1) | 폴드 시 카드 숨김 | immediate(0) |
| show_rank | bool | 핸드 랭크 텍스트 표시 | true |
| hilite_winning_hand_type | enum (0-3) | 위너 하이라이트 | showdown(3) |

**레이아웃 설정**

| 필드 | 타입 | 설명 |
|------|------|------|
| board_pos_type | enum (0-2) | 보드 위치 (left/centre/right) |
| gfx_vertical | bool | 수직 레이아웃 |
| gfx_bottom_up | bool | 하단 정렬 |
| gfx_fit | bool | 화면 맞춤 |
| leaderboard_pos | enum (0-8) | 리더보드 위치 (9방향) |
| heads_up_layout_mode | enum (0-2) | 헤즈업 레이아웃 모드 |
| heads_up_layout_direction | enum (0-1) | 헤즈업 방향 |

**애니메이션 설정**

| 필드 | 타입 | 설명 |
|------|------|------|
| transition_type | enum (0-3) | 전환 효과 (fade/slide/pop/expand) |
| skin_transition_type | enum (0-4) | 스킨 전환 효과 |
| indent_action | bool | 액션 들여쓰기 |
| player_action_bounce | bool | 액션 바운스 애니메이션 |

**통계/패널 설정**

| 필드 | 타입 | 설명 |
|------|------|------|
| auto_stats_first_hand | int | 자동 통계 시작 핸드 |
| auto_stats_hand_interval | int | 통계 갱신 간격 |
| panel_logo | bool | 패널 로고 표시 |
| board_logo | bool | 보드 로고 표시 |
| strip_logo | bool | 스트립 로고 표시 |
| ticker_stat_selection | enum[] | 티커 표시 통계 |

**Heads-Up 전용 설정**

| 필드 | 타입 | 설명 |
|------|------|------|
| headsup_history | bool | 헤즈업 히스토리 표시 |
| hu_layout_type | enum (0-2) | 헤즈업 레이아웃 타입 |
| custom_ypos | int | 커스텀 Y 좌표 |

**미디어/카메라 설정**

| 필드 | 타입 | 설명 |
|------|------|------|
| vanity_text | string | 배너 텍스트 |
| game_name_in_vanity | bool | 게임명 배너 표시 |
| media_path | string | 미디어 파일 경로 |
| post_bet_cam_action | enum (0-2) | 베팅 후 카메라 액션 |
| post_hand_cam_action | enum (0-2) | 핸드 후 카메라 액션 |

**Chip Precision 설정 (8 필드)**

칩 금액을 얼마나 정밀하게 표시할지 결정한다. 예: 12,345칩 → 정확(12,345) / 반올림(12,300) / 축약(12.3K).

| 필드 | 적용 대상 | 타입 |
|------|----------|------|
| cp_leaderboard | 리더보드 | chipcount_precision_type (0-2) |
| cp_pl_stack | 플레이어 스택 | chipcount_precision_type |
| cp_pl_action | 플레이어 액션 | chipcount_precision_type |
| cp_blinds | 블라인드 표시 | chipcount_precision_type |
| cp_pot | 팟 표시 | chipcount_precision_type |
| cp_twitch | Twitch 연동 | chipcount_precision_type |
| cp_ticker | 티커 | chipcount_precision_type |
| cp_strip | 스트립 | chipcount_precision_type |

**6.2 game_type별 기본값 차이**

| 설정 | Cash (0) | Tournament (1) | SNG (2) |
|------|:--------:|:--------------:|:-------:|
| card_reveal_type | immediate(0) | showdown_tourney(5) | showdown_tourney(5) |
| chipcount_disp_type | amount(0) | bb_multiple(1) | amount(0) |
| auto_blinds_type | never(0) | new_level(2) | every_hand(1) |
| leaderboard | 비활성 | 활성 (상금 표시) | 활성 |

---

# Chapter 7: Engine API 계약

> 2026-04-08 추가: Dart 프로토타입의 엔진 public interface 정의

Ch1-6은 **"데이터 사전"** — 엔진이 다루는 모든 값과 설정을 정의했다. Ch7은 **"프로그램 인터페이스"** — 이 데이터를 프로그램에서 어떻게 다루는지 정의한다.

API(Application Programming Interface)란 프로그램끼리 대화하는 약속된 규칙이다. 자판기에 비유하면: 동전을 넣고(입력) 버튼을 누르면(이벤트) 음료가 나온다(출력). 게임 엔진도 같다 — **게임 상태**(동전) + **이벤트**(버튼) → **새 게임 상태**(음료).

```
게임 엔진 = 자판기
  입력:  현재 상태 + 이벤트
  출력:  새 상태 + UI 알림
  핵심:  reduce() 함수
          ↓
  reduce(현재 상태, "Fold 버튼") → 새 상태
```

이 Chapter는 엔진이 외부(Flutter UI, 통계 모듈, 기록 저장)에 **어떤 인터페이스를 노출**하는지 정의한다.

## 7.1 핵심 인터페이스

### GameEngine 클래스

```
class GameEngine {
  // 현재 핸드 상태 (읽기 전용)
  HandState get state

  // 이벤트 dispatch → 상태 전이 + 출력 이벤트 반환
  ReduceResult dispatch(GameEvent event)

  // UNDO (최대 5단계)
  ReduceResult undo()

  // 새 핸드 시작을 위한 상태 초기화
  HandState createInitialState(GameConfig config, List<EnginePlayer> players)
}
```

### ReduceResult 구조

```
class ReduceResult {
  final HandState state         // 전이 후 상태
  final List<OutputEvent> outputs  // UI에 전달할 이벤트
  final bool accepted           // 이벤트가 수락되었는가
  final String? rejectReason    // 거부 시 사유
}
```

### 순수 함수 reduce

```
// 핵심 순수 함수 — side effect(부수 효과 — 함수 외부 상태를 변경하는 것) 없음
HandState reduce(HandState state, GameEvent event) → HandState

// GameEngine.dispatch()는 내부에서 이 함수를 호출하고,
// event log 기록 + 불변식 검증 + output 수집을 추가 처리
```

## 7.2 책임 경계

| 책임 | 엔진 내부 | 엔진 외부 (Provider(상태를 전달하는 컨테이너)/UI) |
|------|:--------:|:-------------------:|
| FSM 상태 전이 | ✓ | |
| 베팅 금액 검증 | ✓ | |
| 팟 분리/분배 | ✓ | |
| 핸드 평가 | ✓ | |
| action_on 결정 | ✓ | |
| UNDO/MissDeal | ✓ | |
| Equity 계산 | ✓ (Optional) | ✓ (대안: 별도 모듈) |
| Statistics 갱신 | | ✓ (VPIP/PFR 등, 핸드 종료 후) |
| 화면 렌더링 | | ✓ (Flutter/Rive) |
| RFID 하드웨어 통신 | | ✓ (RfidReader) |
| 트리거 Coalescence | | ✓ (Provider debounce, BS-06-04) |
| 핸드 기록 저장 | | ✓ (JSON export) |
| 애니메이션/사운드 | | ✓ (OutputEvent 구독) |

### Equity 계산 책임 판정

Equity(승률) 계산은 `reduce()` 순수 함수의 범위 **밖**이다. 이유:

1. Equity는 **Monte Carlo 시뮬레이션** 기반 (BS-06-00-REF Ch4, 10,000회, <200ms)
2. 비결정론적 연산 → 순수 함수에 부적합
3. 계산 시간이 길어 reduce()의 동기 반환을 지연시킴

**해결**: `EquityCalculator`를 별도 클래스로 분리. 엔진의 `HandState`를 입력으로 받아 비동기로 승률 반환.

```
class EquityCalculator {
  Future(비동기 작업의 결과를 담는 객체)<Map<int, double>> calculate(HandState state)
  // seat → equity (0.0~1.0)
}
```

UI Provider가 `OutputEvent.StateChanged` 수신 시 `EquityCalculator.calculate()`를 비동기 호출하고, 결과를 오버레이에 반영.

## 7.3 구독 패턴

Flutter는 화면을 만드는 프레임워크, Riverpod(Flutter 상태 관리 라이브러리)는 Flutter에서 데이터 변경을 자동으로 화면에 반영하는 도구다. 아래는 이 도구들과 엔진을 연결하는 흐름이다.

```
// Provider 레벨에서의 통합 흐름

1. UI 이벤트 (CC 버튼 클릭)
   ↓
2. GameSessionController.dispatchAction(GameEvent)
   ↓
3. GameEngine.dispatch(event) → ReduceResult
   ↓
4. ReduceResult.outputs 순회:
   ├─ StateChanged → Riverpod state 갱신 → UI 자동 리빌드
   ├─ ActionOnChanged → CC 버튼 활성/비활성 갱신
   ├─ PotUpdated → 오버레이 팟 갱신
   ├─ BoardUpdated → 오버레이 보드 갱신
   ├─ Rejected → 경고 메시지 표시
   └─ EquityUpdated → 승률 표시 갱신 (비동기)
   ↓
5. event log에 이벤트 기록 (UNDO용)
```

### RFID 이벤트 라우팅

```
RFID 카드 감지
  ↓
RfidReader.cardStream(연속적으로 데이터를 전달하는 채널) (기존 추상 인터페이스)
  ↓
GameSessionController._onCardScanned(card)
  ├─ phase == deckRegistration → 기존 로직 (덱 등록)
  └─ phase == live:
     ├─ SETUP_HAND → dispatch(HoleCardDetected(seat, card))
     └─ PRE_FLOP~TURN → dispatch(BoardCardRevealed([card]))
```

## 7.4 HandState → GameSession 매핑

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §5.4 GameSession ↔ HandState 매핑 + §2.7 GamePhase → Street 매핑. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

기존 `GameSession` 모델과 새 `HandState`의 통합 지점이다.

```
class GameSession {
  // 기존 필드 (변경 없음)
  final SessionPhase phase;
  final String userName, tableName;
  final List<Player> players;
  final Set<PlayingCard> registeredCards;
  final int handNumber;

  // 신규 필드
  final HandState? activeHand;  // live 상태에서만 non-null

  // street getter 변경: activeHand에서 파생
  Street get street => activeHand?.phase.toStreet() ?? Street.preflop;

  // communityCards getter 변경: activeHand에서 파생
  List<PlayingCard> get communityCards =>
    activeHand?.boardCards ?? const [];
}
```

### GamePhase → Street 매핑

| GamePhase | Street | 비고 |
|-----------|--------|------|
| IDLE, SETUP_HAND | null (live 아님) | street getter 미사용 |
| PRE_FLOP | preflop | |
| FLOP | flop | |
| TURN | turn | |
| RIVER | river | |
| SHOWDOWN, RUN_IT_MULTIPLE, HAND_COMPLETE | showdown | UI 축약 |

## 7.5 엔진 초기화 흐름

> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: Lifecycle 도메인 마스터 §5.15 엔진 초기화 흐름 5 단계 (Live 진입 → GameEngine 인스턴스 → createInitialState → activeHand → StartHand). 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.

```
1. 사용자가 "Live 진입" 클릭
   ↓
2. GameSessionController.enterLive()
   ├─ GameEngine 인스턴스 생성
   ├─ GameConfig 구성 (bet_structure, blinds, ante)
   └─ players → EnginePlayer 변환
   ↓
3. engine.createInitialState(config, enginePlayers)
   → HandState(phase: IDLE, ...)
   ↓
4. session.copyWith(activeHand: initialState)
   ↓
5. 운영자가 "NEW HAND" 클릭
   → dispatch(StartHand())
   → IDLE → SETUP_HAND → (RFID 대기)
```

## 7.6 Event Log 수집

> 7.3 구독 패턴의 "5. event log에 이벤트 기록"의 상세 명세. 모든 Input Event는 `dispatch()` 호출 시 자동으로 로그에 기록되며, UNDO와 시나리오 재생의 기반이 된다.

### 7.6.1 Event Log 데이터 구조

```
EventLog {
  events: List<GameEvent>     // 불변 이벤트 목록 (시간순)
  maxUndoDepth: int = 5       // UNDO 최대 단계
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| events | List\<GameEvent\> | 핸드 시작부터 현재까지의 모든 Input Event. 추가만 가능 (삭제는 UNDO만) |
| maxUndoDepth | int | UNDO 가능 최대 단계. 기본값 5 |

**EventLog는 GameEngine.dispatch()가 관리한다.** reduce() 순수 함수는 로그를 알지 못한다.

### 7.6.2 로그 레코드 포맷

각 이벤트는 아래 필드로 직렬화된다:

| 필드 | 타입 | 설명 |
|------|------|------|
| index | int | 이벤트 순번 (0부터) |
| type | string | 이벤트 타입 (Ch1.8.1 log event_type 참조) |
| seat | int? | 액션 플레이어 좌석 (해당 시) |
| action | string? | 액션 이름 (fold, check, call, bet, raise, allin) |
| amount | int? | 금액 (엔진이 계산한 실제 적용 금액) |
| cards | List\<string\>? | 카드 표기 (deal_community, deal_hole 시) |
| timestamp | int | 이벤트 발생 시각 (밀리초) |

**Call/AllIn 금액 규칙**: `amount`는 엔진이 자동 계산한 **실제 적용 금액**을 기록한다. 외부에서 전달한 금액이 아니다.
- Call: `min(biggest_bet_amt - player.current_bet, player.stack)`
- AllIn: `player.stack`
- Short Call (stack 부족): 실제 납부액 기록 (예: call_amount=100, stack=70 → amount=70)

### 7.6.3 로그 스코프

| 스코프 | 범위 | 용도 |
|--------|------|------|
| **핸드 로그** (EventLog) | HandStart ~ HandEnd | UNDO, 시나리오 저장, API 응답 |
| **스트리트 베팅 히스토리** (_street_bet_history) | 현재 스트리트 내 | 베팅 라운드 완료 판정, FL cap 계산 |

- `_street_bet_history`는 스트리트 전환 시 초기화된다
- EventLog는 핸드 종료까지 유지되며, 새 핸드 시작 시 초기화된다
- 두 로그는 독립적이다. EventLog는 영구 기록, _street_bet_history는 임시 판정용

### 7.6.4 _street_bet_history 필드 정의

BS-06-02에서 참조하는 `_street_bet_history`의 정의:

```
_street_bet_history: List<BetRecord>

BetRecord {
  seat: int              // 좌석 번호
  action: string         // "BET", "CALL", "RAISE", "CHECK", "FOLD", "ALLIN"
  amount: int            // 실제 적용 금액
}
```

| 시점 | 동작 |
|------|------|
| 스트리트 시작 | 빈 리스트로 초기화 |
| 액션 발생 | `append((seat, action, actual_amount))` |
| 스트리트 종료 | 다음 스트리트 시작 시 초기화 |
| 핸드 종료 | 참조 해제 |

### 7.6.5 cursor 정의

API의 `?cursor=N` 파라미터는 **EventLog의 이벤트 인덱스**를 지정한다.

| 값 | 의미 |
|------|------|
| 생략 | 전체 이벤트 적용 후 최신 상태 반환 |
| 0 | 초기 상태 (이벤트 미적용) |
| N | 첫 N개 이벤트만 적용한 중간 상태 반환 |
| events.length | 최신 상태 (생략과 동일) |

cursor는 Event Sourcing 기반으로 동작한다. 상태를 저장하는 것이 아니라, 초기 상태에서 N개 이벤트를 순차 적용하여 해당 시점의 상태를 재구성한다.

### 7.6.6 연쇄 이벤트 로깅

하나의 Input Event가 Internal Transition을 연쇄 발동할 때, **Input Event만 EventLog에 기록**한다. Internal Transition과 Output Event는 로그에 기록하지 않는다.

| 구분 | EventLog 기록 | 예시 |
|------|:------------:|------|
| Input Event | ✓ | PlayerAction(seat:3, fold) |
| Internal Transition | ❌ | AllFoldDetected |
| Output Event | ❌ | WinnerDetermined, HandCompleted |

이유: reduce()는 결정론적이므로, Input Event만 재생하면 동일한 Internal Transition과 Output Event가 자동으로 재생성된다.

### 7.6.7 UNDO 제약

| 규칙 | 설명 |
|------|------|
| 최대 깊이 | 5단계 (maxUndoDepth) |
| UNDO 시 로그 처리 | EventLog.events에서 마지막 이벤트 제거 |
| 상태 재구성 | 초기 상태 + 남은 이벤트 순차 적용 (Event Sourcing) |
| UNDO 불가 조건 | events가 비어있을 때, 또는 핸드 종료 후 |
| 연쇄 이벤트 UNDO | Input Event 1개 제거 → 연쇄된 Internal Transition도 자동 소멸 |
| Harness Session 적용 | HTTP `/api/session/:id/undo` endpoint도 동일한 5단계 제한을 적용한다. Session은 내부적으로 EventLog를 사용하여 undo를 처리해야 한다 |

---

## 7.7 Pot Size Display Policy (WSOP Rule 101)

**원칙**: 플레이어를 위한 pot 정확 금액 표시는 **PL(Pot-Limit) 게임에만 허용**된다. NL/FL/Spread 게임에서는 플레이어 대상 UI에서 pot 정확 금액을 숨겨야 한다. 이는 WSOP Official Live Action Rules Rule 101의 "참가자는 팟 리밋 게임에서만 팟 크기에 대한 정보를 받을 수 있습니다. 딜러는 리미트 및 노리밋 게임에서 팟을 계산하지 않습니다" 조항에 근거한다.

### 7.7.1 게임 형식별 정책

| 게임 형식 | Pot 정확 금액 (플레이어 UI) | Pot 추정/힌트 | Pot 표시 (CC/Broadcast) |
|-----------|:--------------------------:|:-------------:|:----------------------:|
| NL (No-Limit) | ❌ 금지 | 선택적 ("약 X BB") | ✅ 자유 |
| PL (Pot-Limit) | ✅ 허용 | ✅ 허용 | ✅ 자유 |
| FL (Fixed-Limit) | ❌ 금지 | 선택적 | ✅ 자유 |
| Spread Limit | ❌ 금지 | 선택적 | ✅ 자유 |

### 7.7.2 Canvas 구분

Output은 `canvas_type`에 따라 다르게 렌더링된다:

- **Broadcast Canvas**: 관객 대상이므로 모든 pot 정보 **항상 표시** (Rule 101은 플레이어 대상 규정이므로 방송 송출은 제외 대상)
- **Venue Canvas**: 테이블 주변 모니터 등 플레이어가 볼 수 있는 디스플레이 → 게임 형식에 따라 제한
- **CC Canvas**: 운영자 대상 내부 UI → 항상 표시 (운영 목적)

### 7.7.3 OutputEvent 플래그

`PotUpdated` OutputEvent에 `display_to_players: bool` 플래그를 추가하여 소비자(Overlay/CC)가 표시 여부를 결정할 수 있도록 한다:

```
PotUpdated {
    main: int,
    sides: List<SidePot>,
    total: int,
    display_to_players: bool  // 게임 형식 기반 자동 설정
}
```

**플래그 계산**:
```
display_to_players = (state.bet_structure == PL)
```

### 7.7.4 구현 책임

- **Engine**: `PotUpdated.display_to_players` 플래그 자동 설정 (bet_structure 기반)
- **CC**: 플레이어 대상 UI (table monitor 등)에서 플래그 false 시 금액 숨김, "About X BB" 같은 추정 표시는 선택적
- **Overlay (Broadcast)**: 플래그 무시, 항상 표시
- **Overlay (Venue)**: 플래그 준수 필수

### 7.7.5 Contracts 영향

`PotUpdated` OutputEvent 시그니처 변경은 `Overlay_Output_Events.md` (legacy-id: API-04)에 영향이 있으며, **후속 CCR 필요**. 본 문서는 engine 측 정책만 명시하고, 외부 계약은 별도 CCR로 처리.

---

## Ch8. Docker 서버 아키텍처 — Interactive Simulator Harness

> 이 Chapter는 게임 엔진의 **개발자 검증 도구**인 Interactive Simulator Harness의 서버 설계를 기술한다. 이 Harness는 프로덕션 CC/Overlay에 포함되지 않는다.

### 8.1 목적과 범위

Interactive Simulator Harness는 게임 엔진 로직을 **Docker 컨테이너 안에서 독립 실행**하고, HTTP API로 제어하는 개발자 도구다.

| 항목 | 설명 |
|------|------|
| 목적 | 카드 딜/액션 입력, 타임라인 스크럽, 시나리오 저장/재생을 통한 엔진 검증 |
| 기술 스택 | 순수 Dart (`dart:io` HttpServer, 프레임워크 없음) |
| 프런트엔드 | Vanilla JS + CSS, SVG 좌석 원형 레이아웃 |
| 제품 포함 여부 | **금지** — CC/Overlay와 혼용하지 않는다 |

### 8.2 Docker 컨테이너 설계

멀티 스테이지 빌드로 빌드 환경과 런타임 환경을 분리한다.

**Stage 1 — Build**

| 항목 | 값 |
|------|-----|
| Base Image | `dart:stable` |
| 빌드 명령 | `dart compile exe bin/harness.dart` (AOT) |
| 산출물 | `harness_exe` (서버), `replay_exe` (CLI 재생) |

**Stage 2 — Runtime**

| 항목 | 값 |
|------|-----|
| Base Image | `debian:bookworm-slim` (~80MB) |
| 복사 대상 | AOT 바이너리 2개 + `lib/harness/web/` 정적 파일 |
| 포트 | 8080 |
| 엔트리포인트 | `/app/harness --port 8080` |

> AOT 컴파일된 Dart 바이너리는 VM 없이 단독 실행된다. 런타임 이미지에 Dart SDK가 필요 없으므로 최종 이미지는 ~100MB 이하.

### 8.3 실행 모드

| 모드 | 서비스명 | 명령 | 용도 |
|------|---------|------|------|
| Production | `harness` | `docker compose up harness` | AOT 바이너리, 최소 크기 |
| Dev | `harness-dev` | `docker compose --profile dev up harness-dev` | 소스 마운트, 라이브 리로드 |

**볼륨 매핑:**

| 호스트 경로 | 컨테이너 경로 | 용도 |
|------------|-------------|------|
| `./scenarios/` | `/app/scenarios/` | YAML 시나리오 파일 (읽기/쓰기) |
| `./out/` | `/app/out/` | 저장된 세션 출력 |

### 8.4 HTTP API 엔드포인트

서버는 `/api/` 경로로 REST API를 제공하고, `/` 경로로 정적 웹 파일을 서빙한다.

#### 세션 관리

| Method | Path | 요청 본문 | 설명 |
|--------|------|----------|------|
| POST | `/api/session` | `{variant, seatCount, stacks, blinds, dealerSeat, seed}` | 새 세션 생성. HandStart + DealHoleCards 자동 실행 |
| GET | `/api/session/:id` | — | 현재 GameState + 이벤트 로그 + 유효 액션 |
| GET | `/api/session/:id?cursor=N` | — | N번째 이벤트 이후 상태만 반환 |

#### 세션 생성 파라미터 상세

`POST /api/session` 요청 본문의 최상위 필드:

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| variant | string | `"nlh"` | 게임 변형 (variants API로 목록 조회) |
| seatCount | int | 6 | 좌석 수 |
| stacks | int 또는 int[] | 1000 | 단일 값이면 전 좌석 동일, 배열이면 좌석별 지정 |
| blinds | object | `{sb:5, bb:10}` | `{sb, bb}` 형식 또는 `{"좌석번호": 금액}` 형식 |
| dealerSeat | int | 0 | 딜러 좌석 인덱스 |
| seed | int | null | 덱 셔플 시드 (결정론적 재현용) |
| config | object | `{}` | 게임 설정 (아래 참조) |

**config 객체 필드:**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| anteType | int | null | 앤티 타입 |
| anteAmount | int | null | 앤티 금액 |
| straddleEnabled | bool | false | 스트래들 활성화 |
| straddleSeat | int | null | 스트래들 좌석 인덱스 |
| bombPotEnabled | bool | false | 봄팟 활성화 |
| bombPotAmount | int | null | 봄팟 금액 |
| canvasType | string | `"broadcast"` | `"venue"` 또는 `"broadcast"` |
| sevenDeuceEnabled | bool | false | 7-2 게임 활성화 |
| sevenDeuceAmount | int | null | 7-2 보너스 금액 |
| actionTimeoutMs | int | null | 액션 타임아웃 (밀리초) |

#### 세션 응답 JSON 스키마

`GET /api/session/:id` 및 이벤트 주입 후 반환되는 JSON 객체의 구조:

| 필드 | 타입 | 설명 |
|------|------|------|
| sessionId | string | 세션 고유 ID |
| variant | string | 게임 변형명 (nlh, short_deck 등) |
| street | string | 현재 스트리트 (setupHand, preflop, flop, turn, river, showdown, runItMultiple) |
| seats | Seat[] | 좌석 배열 (아래 참조) |
| community | string[] | 커뮤니티 카드 표기 배열 (예: ["Ah", "Kd", "5s"]) |
| pot | object | 팟 정보 — main (int), total (int), sides (SidePot[]) |
| actionOn | int / null | 현재 액션 대상 좌석 인덱스 |
| dealerSeat | int | 딜러 좌석 인덱스 |
| legalActions | Action[] | 현재 가능한 액션 목록 |
| handNumber | int | 핸드 번호 |
| anteType | int / null | 앤티 타입 |
| anteAmount | int / null | 앤티 금액 |
| straddleEnabled | bool | 스트래들 활성화 여부 |
| straddleSeat | int / null | 스트래들 좌석 |
| bombPotEnabled | bool | 봄팟 활성화 여부 |
| bombPotAmount | int / null | 봄팟 금액 |
| canvasType | string | 캔버스 타입 (venue, broadcast) |
| sevenDeuceEnabled | bool | 7-2 게임 활성화 여부 |
| sevenDeuceAmount | int / null | 7-2 보너스 금액 |
| runItTimes | int / null | Run It 횟수 |
| actionTimeoutMs | int / null | 액션 타임아웃 (밀리초) |
| isAllInRunout | bool | 올인 런아웃 진행 여부 |
| eventCount | int | 총 이벤트 수 |
| cursor | int | 현재 커서 위치 |
| log | string[] | 이벤트 설명 로그 배열 |

**Seat 객체:**

| 필드 | 타입 | 설명 |
|------|------|------|
| index | int | 좌석 인덱스 |
| label | string | 좌석 라벨 (예: "Seat 1") |
| stack | int | 현재 스택 |
| currentBet | int | 현재 스트리트 베팅 금액 |
| status | string | 좌석 상태 (active, folded, allIn 등) |
| holeCards | string[] | 홀카드 표기 배열 (예: ["As", "Ks"]) |
| isDealer | bool | 딜러 여부 |

**pot.sides 배열 요소 (SidePot):**

| 필드 | 타입 | 설명 |
|------|------|------|
| amount | int | 사이드팟 금액 |
| eligible | int[] | 참여 가능 좌석 인덱스 (정렬됨) |

#### 이벤트 제어

| Method | Path | 요청 본문 | 설명 |
|--------|------|----------|------|
| POST | `/api/session/:id/event` | `{type, seatIndex, amount, ...}` | 이벤트 주입 |
| POST | `/api/session/:id/undo` | — | 마지막 이벤트 되돌림 (Event Sourcing). 최대 5단계 (Ch7.6.7). 초과 시 무시 |

**지원 이벤트 유형:**

| type | 추가 필드 | 설명 |
|------|----------|------|
| `fold` | seatIndex | 폴드 |
| `check` | seatIndex | 체크 |
| `call` | seatIndex, amount | 콜 |
| `bet` | seatIndex, amount | 베팅 |
| `raise` | seatIndex, amount | 레이즈 |
| `allin` | seatIndex, amount | 올인 |
| `street_advance` | next (setupHand/preflop/flop/turn/river/showdown/runItMultiple) | 스트리트 전진 |
| `deal_community` | cards (["Ah", "Kd", ...]) | 커뮤니티 카드 배분 |
| `deal_hole` | cards ({"0": ["As", "Ks"], ...}) | 홀카드 수동 지정 |
| `pot_awarded` | awards ({"0": 1000, ...}) | 팟 지급 |
| `hand_end` | — | 핸드 종료 |
| `misdeal` | — | 미스딜 선언 |
| `bomb_pot_config` | amount (int) | 봄팟 금액 설정 |
| `run_it_choice` | times (int) | Run It 횟수 선택 (1=한번, 2=두번 등) |
| `manual_next_hand` | — | 수동 다음 핸드 시작 |
| `timeout_fold` | seatIndex | 타임아웃에 의한 자동 폴드 |
| `muck` | seatIndex, showCards (bool) | 머크/쇼 결정. showCards=true면 카드 공개 |
| `pineapple_discard` | seatIndex, card (string) | Pineapple 변형 — 카드 1장 디스카드 (예: "Ah") |

#### 시나리오 관리

| Method | Path | 요청 본문 | 설명 |
|--------|------|----------|------|
| POST | `/api/session/:id/save` | — | 현재 세션을 YAML로 저장 |
| GET | `/api/scenarios` | — | scenarios/ 디렉토리 목록 |
| POST | `/api/scenarios/:name/load` | — | YAML 시나리오 재생 (새 세션 생성) |

#### 메타 정보

| Method | Path | 응답 | 설명 |
|--------|------|------|------|
| GET | `/api/variants` | `{variants: ["nlh", "short_deck", ...]}` | 지원 variant 목록 |

#### 분석 및 검증

> **증분 처리 전용**: 아래 endpoint는 **현재 GameState 스냅샷**만을 대상으로 계산한다. 전체 이벤트 히스토리를 재분석하거나 과거 상태를 소급 계산하지 않는다. 매 이벤트 주입 후 호출하면 해당 시점의 증분 결과를 반환한다.

| Method | Path | 응답 | 설명 |
|--------|------|------|------|
| GET | `/api/session/:id/equity` | `{equity: {"0": 0.55, "2": 0.45}}` | 활성 시트의 Monte Carlo 에퀴티 계산 (5,000 iterations). 홀카드 2장 보유 시트만 포함. 2인 미만이면 빈 객체 반환 |
| GET | `/api/session/:id/validate` | `{valid: bool, issues: [...]}` | 카드 중복 검증. issues 배열이 비어있으면 valid=true |
| GET | `/api/session/:id/showdown-order` | `{revealOrder: [seatIndex, ...]}` | 쇼다운 시 카드 공개 순서 반환. 마지막 어그레서 기준 시계방향 |
| GET | `/api/session/:id/runout-check` | `{isAllInRunout: bool}` | 올인 런아웃 필요 여부 확인 |

> **에퀴티 제한**: equity endpoint는 `holeCards.length == 2` 조건으로 필터링한다. NLH, Short Deck 등 홀카드 2장 변형만 지원하며, Omaha(4장), Pineapple(3장) 변형은 에퀴티 계산에서 제외된다.

### 8.5 세션 생명주기

```
POST /api/session {variant: "nlh", seatCount: 6, stacks: 1000}
  ↓ 자동: HandStart(blinds) + DealHoleCards
  ↓
GET /api/session/:id → 현재 상태 확인
  ↓
POST /api/session/:id/event {type: "call", seatIndex: 2, amount: 10}
  ↓ ... 액션 반복 ...
  ↓
POST /api/session/:id/event {type: "street_advance", next: "flop"}
POST /api/session/:id/event {type: "deal_community", cards: ["Ah", "Kd", "5s"]}
  ↓ ... 스트리트 진행 ...
  ↓
POST /api/session/:id/undo  ← 실수 시 되돌림 (Event Sourcing)
  ↓
POST /api/session/:id/save  → scenarios/m1a2b3c.yaml 저장
```

> **세션 생성 시 자동 실행**: `POST /api/session`은 세션을 만든 뒤 `HandStart` + `DealHoleCards`를 자동 주입한다. Courchevel variant의 경우 `DealCommunity`(preflop 공용 카드 1장)도 자동 추가된다.

### 8.6 YAML 시나리오

시나리오는 `scenarios/` 디렉토리에 YAML 파일로 저장/로드된다.

| 항목 | 설명 |
|------|------|
| 저장 | `POST /api/session/:id/save` → `scenarios/{id}.yaml` |
| 로드 | `POST /api/scenarios/:name/load` → 새 세션 생성 + 이벤트 순차 재생 |
| 내장 fixture | `test/scenarios/` 에 15개 시나리오 (NLH 5 + 변형 7 + 엣지케이스 3) |
| 결정론적 재현 | `seed` 파라미터로 덱 셔플 고정 가능 |

### 8.7 프런트엔드 (Static Serving)

서버는 `/` 경로로 `lib/harness/web/` 디렉토리의 정적 파일을 서빙한다.

| 모듈 | 파일 | 역할 |
|------|------|------|
| 진입점 | `index.html` | 단일 페이지 앱 |
| API 클라이언트 | `js/api.js` | fetch 기반 API 호출 |
| 앱 초기화 | `js/app.js` | 세션 생성, variant 선택 |
| 게임 제어 | `js/controls.js` | 액션 버튼 (fold/check/call/bet/raise/allin) |
| 이벤트 로그 | `js/event-log.js` | 이벤트 히스토리 표시 |
| 수동 딜 | `js/manual-deal.js` | 카드 직접 지정 (버그 재현용) |
| 테이블 뷰 | `js/table-view.js` | SVG 좌석 원형 레이아웃 |
| 타임라인 | `js/timeline.js` | 이벤트 스크럽 (Event Sourcing 기반) |
| 스타일 | `css/style.css` | 레이아웃 |

### 8.8 배포 제약 및 보안

| 제약 | 설명 |
|------|------|
| 바인딩 | `InternetAddress.loopbackIPv4` (127.0.0.1) — 외부 접근 불가 |
| CORS | 전체 허용 (`Access-Control-Allow-Origin: *`) — 개발 환경 전용 |
| Graceful Shutdown | SIGINT 핸들링 → `server.close(force: true)` |
| 프로덕션 포함 금지 | 이 Harness는 개발자 검증 도구. CC/Overlay 배포 패키지에 포함하지 않는다 |
| 인증 | 없음 — 로컬 개발 전용이므로 인증 불필요 |
