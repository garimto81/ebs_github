---
title: RIVE Standards — Overlay Graphics 정본
owner: S4 (RIVE Standards)
tier: contract
last-updated: 2026-05-07
version: 0.3.0
audience-target: 외부 개발팀 + 외부 디자이너 + 방송 PD
purpose: |
  Overlay Graphics 의 정본 SSOT.
  Rive 에셋이 어떻게 EBS 에 통합되고, 5 데이터 소스 (Rive Asset / EBS DB / Command Center / RFID / Game Engine) 가
  어떻게 합류하여 한 장의 화면이 되는지를 정의한다.
---

# RIVE Standards — Overlay Graphics 정본

> **Version**: 0.3.0
> **Date**: 2026-05-07
> **문서 유형**: 정본 SSOT (Reference Manual)
> **대상 독자**: 외부 개발팀 / 외부 디자이너 / 방송 PD
> **범위**: Overlay 그래픽이 어떤 요소로 이루어지고, 어떻게 출력되며, 어디에서 어떤 데이터를 받아 출력되는가의 정의.

---

## 한 줄 정의

> **Overlay Graphics** = 포커 테이블 위 카메라 화면 위에 떠 있는 투명한 막.
> 그 막은 처음에 비어 있다. **다섯 명의 작가** — Rive Asset, EBS DB, Command Center, RFID, Game Engine — 가 동시에 같은 막에 글을 쓰기 시작하면, 그 막은 비로소 한 장면이 된다.

다섯 중 하나라도 빠지면 화면은 불완전해진다.

| 빠진 작가 | 화면이 되는 것 |
|----------|---------------|
| Rive Asset 가 없으면 | 그래픽 형태가 없어 데이터 표시 불가 |
| EBS DB 가 없으면 | 선수 이름·국가·브랜딩 정보 부재 |
| Command Center 가 없으면 | 액션 표식 갱신 불가 |
| RFID 가 없으면 | 카드 정보 부재 |
| Game Engine 이 없으면 | 팟·스택·Equity 등 계산값 부재 |

본 문서는 이 다섯 작가가 어떻게 한 장의 막에 동시에 글을 쓰는지를 정의한다.

---

## 목차

**Part I — 만남 (Overlay 의 정체)**

- [Ch.1 — 다섯 작가의 만남](#ch1)
- [Ch.2 — 그래픽 요소 12 카테고리 한눈에](#ch2)

**Part II — Rive 런타임**

- [Ch.3 — Rive 의 정체](#ch3) — 벡터 + State Machine + Variable Binding
- [Ch.4 — Rive Editor ↔ EBS 통합 두 경로](#ch4) — Export-Import vs API 직접 연동
- [Ch.5 — Variable Binding](#ch5) — 데이터를 그래픽 속성에 묶는 메커니즘

**Part III — 다섯 데이터 소스**

- [Ch.6 — Rive Asset](#ch6) — `.riv` 파일 명세 + 디자이너 의무
- [Ch.7 — EBS DB](#ch7) — 영속의 기억
- [Ch.8 — Command Center 입력](#ch8) — 인간의 결정
- [Ch.9 — RFID](#ch9) — 카드의 정체
- [Ch.10 — Game Engine](#ch10) — 계산 결과
- [Ch.11 — 다섯의 합류](#ch11) — 한 변수에서 만나는 길

**Part IV — 그래픽 요소 카탈로그**

- [Ch.12 — 플레이어 정체성](#ch12) — 이름·국가·좌석·아바타
- [Ch.13 — 칩 스택과 베팅 라인](#ch13) — 자산의 흐름
- [Ch.14 — 카드: 홀카드 + 커뮤니티](#ch14) — 비밀과 공유
- [Ch.15 — 핸드 강도와 Equity](#ch15) — 확률의 시각화
- [Ch.16 — 액션 표식](#ch16) — Bet / Call / Raise / Fold / All-In
- [Ch.17 — 팟](#ch17) — 메인 + 사이드
- [Ch.18 — 블라인드와 레벨](#ch18) — 토너의 박동
- [Ch.19 — 토너먼트 상태](#ch19) — 큰 그림
- [Ch.20 — 시계와 Time Bank](#ch20) — 두 종류의 시계
- [Ch.21 — 브랜딩](#ch21) — 로고·워터마크·광고
- [Ch.22 — 운영자 전용 표식](#ch22) — 백스테이지의 그림
- [Ch.23 — 우승 화면](#ch23) — 핸드와 토너의 마지막 막

**Part V — 살아 움직이는 법**

- [Ch.24 — State Machine](#ch24) — Rive 의 상태 전이
- [Ch.25 — 게임 흐름과 그래픽 전이](#ch25) — Preflop → Showdown
- [Ch.26 — Entry / Emphasis / Exit](#ch26) — 모든 그래픽의 3 막극

**Part VI — 무대 구조**

- [Ch.27 — 9 단 z-layer](#ch27) — 막의 순서
- [Ch.28 — Safe Zone 과 시각 위계](#ch28) — 화면 안의 좌표

**Part VII — 부록**

- [Ch.29 — 용어 사전](#ch29)
- [Ch.30 — FAQ](#ch30)
- [Ch.31 — 송출 준비 체크리스트](#ch31)

---

# Part I — 만남

<a id="ch1"></a>

## Ch.1 — 다섯 작가의 만남

### 1.1 다섯 작가가 누구인가

Overlay 화면 한 장이 만들어지려면 — 다음 다섯 출처의 데이터가 동시에 필요하다.

| 작가 | 가져오는 것 | 비유 |
|------|------------|------|
| **Rive Asset** | 그래픽의 형태 (벡터 도형, 색, 폰트, 애니메이션) |
| **EBS DB** | 영속 데이터 (선수 프로필, 토너 정보, 브랜드 패키지, 히스토리) |
| **Command Center** | 운영자 결정 (FOLD / BET / RAISE / ALL-IN / 핸드 시작 / 종료) |
| **RFID** | 카드의 정체 (무늬·숫자·좌석) |
| **Game Engine** | 계산된 결과 (팟, 사이드 팟, Equity, 핸드 강도, 스택 변동) |

이 다섯이 만나는 곳이 **Rive Variable** 이다 (Ch.5). Variable 하나하나가 그래픽 한 조각으로 변환된다.

### 1.2 한 화면에 동시에 흐르는 다섯 줄기

```
   +---------------+    +---------------+    +---------------+
   |  Rive Asset   |    |    EBS DB     |    | Command Center|
   |  (.riv 파일)  |    |  (영속 기억)   |    |  (운영자 입력) |
   +-------+-------+    +-------+-------+    +-------+-------+
           |                    |                    |
           v                    v                    v
   +---------------+    +---------------+    +---------------+
   |     RFID      |    |  Game Engine  |    |  (다른 출처   |
   |  (카드 인식)   |    |   (계산기)    |    |   는 없음)    |
   +-------+-------+    +-------+-------+    +---------------+
           |                    |
           +--------+-----------+
                    |
                    v
           +-------------------+
           |  Rive Variables   |  <- 다섯이 만나는 지점
           +---------+---------+
                     |
                     v
           +-------------------+
           |  Rive Renderer    |  <- 변수를 그림으로
           +---------+---------+
                     |
                     v
           +-------------------+
           |   Overlay 화면    |  <- 시청자가 보는 한 장
           +-------------------+
```

### 1.3 본 문서의 범위

본 문서는 이 다섯 작가의 글이 **어디에서 와서 어떻게 변수에 담기고, 어떻게 그림으로 변환되는가** 만 정의한다. 다섯 작가 각자의 내부 동작 (예: RFID 안테나가 NFC 를 읽는 알고리즘, Engine 이 Equity 를 계산하는 몬테카를로 시뮬레이션) 은 본 문서의 범위가 아니다. 그건 각 작가의 영역이다.

본 문서가 답하는 세 가지 질문:

1. **무엇이 보이는가?** — 12 카테고리 그래픽 요소 (Part IV)
2. **어떻게 만들어지는가?** — Rive 런타임 + Variable Binding (Part II)
3. **어디에서 데이터가 오는가?** — 다섯 작가별 매핑 (Part III)

<a id="ch2"></a>

## Ch.2 — 그래픽 요소 12 카테고리 한눈에

본 Part 의 끝에서 — Part IV 본문 들어가기 전에 — 12 카테고리를 한 페이지로 펼친다. 시청자가 화면에서 보게 되는 모든 것은 다음 12 안에 들어간다.

```
  +================================================================+
  |                                                                |
  |   [Brand Logo]                              [Tournament State] |
  |                                                                |
  |     +--------+                              +--------+         |
  |     |Player  |                              |Player  |         |
  |     |Card    |    (테이블 카메라 영상)       |Card    |         |
  |     |+ Stack |                              |+ Stack |         |
  |     +---+----+                              +----+---+         |
  |         |                                        |             |
  |       Bet 라인                                 Bet 라인         |
  |          \                                    /                |
  |           \      [홀카드]      [커뮤니티 5장] /                  |
  |            \                                 /                 |
  |             \         [POT]                 /                  |
  |              \________/        \___________/                   |
  |                                                                |
  |   [Hand Strength + Equity]            [Action 표식 (RAISE)]    |
  |                                                                |
  |   [Blind / Level]                       [Hand / Level Clock]   |
  |                                                                |
  |   [Watermark]                           [Bottom Banner]        |
  +================================================================+
              ASCII MOCK · 12 카테고리 한 화면 배치
```

<!-- IMG_TODO: 실제 방송 화면에 12 카테고리 라벨링한 reference 시안 -->

| # | 카테고리 | 데이터 소스 매핑 |
|---|---------|--------------|
| 1 | Player Card (정체성) | DB (이름·국가·아바타) + RFID (좌석) + Engine (탈락 여부) |
| 2 | Stack + Bet 라인 | Engine (계산된 stack, bet) |
| 3 | 카드 (홀 + 커뮤니티) | RFID (카드 정체) + Engine (공개 시점) |
| 4 | Hand Strength + Equity | Engine (계산 결과) |
| 5 | 액션 표식 | Command Center (FOLD/BET/...) |
| 6 | 팟 | Engine (메인 + 사이드 계산) |
| 7 | 블라인드 / 레벨 | DB (스케줄) + Engine (현재 레벨) |
| 8 | 토너먼트 상태 | DB (총 인원) + Engine (남은 인원, ITM) |
| 9 | 시계 + Time Bank | Engine (시계 카운트) + Command Center (Time Bank 사용) |
| 10 | 브랜딩 | DB (브랜드 패키지) |
| 11 | 운영자 전용 표식 | Command Center + RFID 진단 |
| 12 | 우승 화면 | Engine (우승자 결정) + DB (트로피 이미지) |

> **모든 카테고리는 Rive Asset (.riv 파일) 이 그래픽 형태를 제공**. 위 표에서는 그 외 데이터 소스만 표시.

각 카테고리는 Part IV 의 별도 챕터에서 — 그래픽 모양, 5 데이터 소스에서 받는 정확한 변수, 변화의 순간 — 으로 풀어 다룬다.

---

# Part II — Rive 런타임

<a id="ch3"></a>

## Ch.3 — Rive 의 정체

5 데이터 소스의 값을 화면에 옮기는 런타임이 **Rive** 다. 왜 Rive 인가.

### 3.1 Rive 가 답하는 세 질문

| 질문 | Rive 의 답 |
|------|-----------|
| 어떻게 그릴 것인가? | **벡터 그래픽** — 어떤 해상도에서도 깨지지 않음 |
| 어떻게 움직일 것인가? | **State Machine** — 그래픽이 상태를 갖고 상태 사이를 이동 |
| 어떻게 데이터를 받을 것인가? | **Variable Binding** — 그래픽의 모든 속성이 변수에 묶일 수 있음 |

### 3.2 Rive 파일 (.riv) 안에 있는 것

```
   +--------------------------------------+
   |          .riv 파일                    |
   +--------------------------------------+
   |                                      |
   |  [Vector Artwork]                    |
   |    - 도형 (사각형, 곡선, 텍스트)       |
   |    - 색상 / 그라데이션 / 그림자        |
   |    - 폰트                             |
   |                                      |
   |  [Animations]                        |
   |    - Timeline (키프레임 애니메이션)    |
   |    - Tween (값 보간)                  |
   |                                      |
   |  [State Machine]                     |
   |    - States (Idle / Active / ...)    |
   |    - Transitions (조건 + trigger)    |
   |                                      |
   |  [Variables (Inputs)]                |
   |    - Number / Boolean / Trigger      |
   |    - 외부에서 주입 가능               |
   |                                      |
   +--------------------------------------+
              ASCII MOCK · .riv 파일 내부 구조
```

이 한 파일이 디자이너가 Rive Editor 에서 만들어 export 한 산출물이다. EBS 는 이 파일을 받아 — Variable 에 데이터를 주입하면서 — 화면에 그린다.

### 3.3 그래픽 요소 1 개 = .riv 파일 1 개 (원칙)

본 문서의 12 카테고리는 각각 별도의 `.riv` 파일로 만들어진다.

| 카테고리 | 파일명 (제안) |
|---------|--------------|
| Player Card | `player_card.riv` |
| Stack + Bet | `stack_bet.riv` |
| 카드 (홀카드) | `hole_card.riv` |
| 카드 (커뮤니티) | `community_card.riv` |
| Hand Strength | `hand_strength.riv` |
| 액션 표식 | `action_badge.riv` |
| 팟 | `pot.riv` |
| 블라인드 / 레벨 | `blind_level.riv` |
| 토너먼트 상태 | `tournament_state.riv` |
| 시계 | `clock.riv` |
| 브랜딩 | `branding.riv` |
| 운영자 표식 | `ops_overlay.riv` |
| 우승 화면 | `winner.riv` |

> 위 파일명은 1 차 가설 제안. 실제 명명 규칙은 외부 디자이너 / 개발팀 합의로 확정.

이 분할의 이유는 **변경 격리** 다. 디자이너가 Player Card 만 다듬고 싶을 때 — 그 한 파일만 export 하여 EBS 에 교체한다. 전체 Overlay 를 다시 빌드할 필요가 없다.

<a id="ch4"></a>

## Ch.4 — Rive Editor ↔ EBS 통합 두 경로

디자이너가 Rive Editor 에서 만든 `.riv` 파일이 EBS 에 들어가는 길은 두 가지다. 각각의 장단이 있다.

### 4.1 경로 A — Export & Import (정적 통합)

```
   디자이너 (Rive Editor)
      |
      | "Player Card 디자인 완성"
      v
   +---------------------+
   |  .riv export        |
   |  player_card.riv    |
   +---------------------+
      |
      | (파일 전송: Git / Drive / 메일)
      v
   +---------------------+
   |  EBS Repo           |
   |  assets/rive/       |
   +---------------------+
      |
      | (빌드 시 번들링)
      v
   +---------------------+
   |  EBS 앱 빌드         |
   +---------------------+
```

| 특징 | 설명 |
|------|------|
| 흐름 | Rive Editor 에서 export → 파일 전송 → EBS repo 추가 → 빌드 |
| 장점 | 디자이너 작업이 EBS 운영과 분리. 버전 관리 (Git) 가 자연스러움 |
| 단점 | 디자이너가 변경할 때마다 파일을 다시 보내야 함 |
| 적합한 시기 | 초기 개발, 안정 단계. 디자인이 자주 바뀌지 않을 때 |

### 4.2 경로 B — Rive Editor ↔ EBS API 직접 연동 (동적 통합)

```
   디자이너 (Rive Editor)
      |
      | "Player Card 디자인 완성"
      v
   +---------------------+
   |  Rive Editor        |
   |  "Publish" 버튼      |
   +---------------------+
      |
      | (Rive Cloud API)
      v
   +---------------------+
   |  Rive Cloud         |
   |  (디자이너의 작업물)  |
   +---------------------+
      |
      | (EBS 가 API 로 fetch)
      v
   +---------------------+
   |  EBS Asset Sync     |
   |  (자동 다운로드)     |
   +---------------------+
      |
      v
   +---------------------+
   |  EBS 런타임 즉시 반영 |
   +---------------------+
```

| 특징 | 설명 |
|------|------|
| 흐름 | 디자이너 publish → Rive Cloud → EBS 가 API 로 가져옴 → 런타임 반영 |
| 장점 | 디자이너 변경이 EBS 운영자에게 직접 전달. 파일 수동 전송 불필요 |
| 단점 | Rive Cloud 의존성. 인증 / 권한 / 버전 lock 메커니즘 필요 |
| 적합한 시기 | 후기 안정화, 라이브 시즌 중 빠른 디자인 보정 필요 시 |

### 4.3 두 경로의 동시 운영 (권장 모델)

본 문서가 권장하는 1 차 가설은 — **두 경로의 동시 운영**:

| 환경 | 경로 |
|------|------|
| 개발 / 스테이징 | 경로 A (Export & Import, Git 관리) |
| 라이브 운영 | 경로 A 가 기본. 경로 B 는 긴급 디자인 보정 채널 |

```
   +--------------------------------+
   |       EBS Asset Loader         |
   +--------------------------------+
   |                                |
   |  1. assets/rive/{name}.riv     |  <- 경로 A (빌드 번들)
   |     (로컬 파일 우선)            |
   |                                |
   |  2. (옵션) Rive Cloud API      |  <- 경로 B (런타임 fetch)
   |     (긴급 override 시)         |
   |                                |
   +--------------------------------+
```

이 구조는 — 평소엔 안정된 빌드를 쓰고, 비상시에만 Cloud override 가 작동한다는 뜻이다.

<a id="ch5"></a>

## Ch.5 — Variable Binding

Rive 의 핵심 메커니즘은 그래픽의 거의 모든 속성이 **변수에 묶일 수 있다**는 데 있다.

### 5.1 Variable 이 무엇인가

`.riv` 파일 안에는 외부에서 주입할 수 있는 **Inputs** (변수) 가 들어 있다. 디자이너가 Rive Editor 에서 미리 선언한다.

| 변수 타입 | 의미 | 사용 예시 |
|-----------|------|----------|
| **Number** | 실수 / 정수 | `stack_amount = 480000` |
| **Boolean** | true / false | `is_folded = true` |
| **Trigger** | 1 회성 신호 | `play_fold_animation` |
| **Text** | 문자열 | `player_name = "PLAYER A"` (Rive 7+ 지원) |

### 5.2 Player Card 의 변수 예시

```
   player_card.riv 의 Inputs:
   +-----------------------------------+
   |  Number   stack_amount            |
   |  Number   bet_amount              |
   |  Number   equity_percent          |
   |  Boolean  is_to_act               |
   |  Boolean  is_folded               |
   |  Boolean  is_eliminated           |
   |  Trigger  on_action               |
   |  Text     player_name             |
   |  Text     country_code            |
   |  Text     hand_label              |
   +-----------------------------------+
```

### 5.3 데이터 소스 → 변수 매핑

위 변수 10 개에 데이터를 채우는 출처:

| 변수 | 출처 (데이터 소스) |
|------|------------------|
| `player_name` | EBS DB (selectedPlayerProfile.name) |
| `country_code` | EBS DB (selectedPlayerProfile.country) |
| `stack_amount` | Game Engine (engineState.players[i].stack) |
| `bet_amount` | Command Center (cc.lastBet) → Engine 정합 |
| `equity_percent` | Game Engine (engineState.equity[i]) |
| `is_to_act` | Game Engine (engineState.actorIndex == i) |
| `is_folded` | Command Center (cc.foldedSeats) |
| `is_eliminated` | Game Engine (engineState.eliminatedAt[i]) |
| `on_action` | Command Center (action 발생 시 trigger) |
| `hand_label` | Game Engine (engineState.handStrength[i]) |

> 위 매핑은 1 차 가설 제안. 실제 변수명과 데이터 경로는 외부 개발팀 / 디자이너 합의로 확정.

---

# Part III — 다섯 데이터 소스

이 Part 는 5 데이터 소스 각자를 자세히 들여다본다. 각 소스가 어떤 데이터를 가지고 있고, 그 데이터가 어떤 변수를 채우는지.

<a id="ch6"></a>

## Ch.6 — Rive Asset

### 6.1 Rive Asset 이 가져오는 것

| 요소 | 의미 |
|------|------|
| **Vector artwork** | 도형 / 색상 / 폰트 / 그림자 |
| **Timeline** | 키프레임 애니메이션 (페이드, 슬라이드, 회전) |
| **State Machine** | 상태 전이 규칙 |
| **Variable schema** | 외부에서 주입 받을 변수 목록 |

다른 네 데이터 소스는 모두 **데이터** 만 제공한다. Rive Asset 만이 **형태** 를 제공한다. 데이터가 어떻게 보일지를 결정하는 유일한 출처다.

### 6.2 디자이너의 책임

Rive Asset 을 만드는 주체는 **외부 디자이너** 다. 디자이너가 Rive Editor 에서 — 본 문서의 Part IV 12 카테고리 각각에 대해 — `.riv` 파일을 만든다.

디자이너의 의무 (외부 합의 후 확정):

| 의무 | 내용 |
|------|------|
| Variable 명명 규칙 | 본 문서 Ch.5.3 매핑 표를 표준으로 사용 |
| State 명명 규칙 | `idle` / `entering` / `exiting` / `highlighted` / `folded` / ... |
| Trigger 명명 규칙 | `on_action` / `on_fold` / `on_eliminate` / ... |
| Safe Zone 준수 | Ch.28 Title Safe 90% 안에 핵심 그래픽 배치 |
| 색상 변수화 | 하드코드 색상 금지 — Brand Pack 으로 override 가능하게 |

### 6.3 Brand Pack — 외부 분리된 색상 / 폰트 / 로고

대회마다 그래픽의 색·폰트·로고가 다르다. `.riv` 파일을 대회마다 새로 만들지 않고, `.riv` 안의 색·폰트·로고를 **Brand Pack** 이라는 별도 데이터로 분리하여 외부에서 주입한다.

```
   +-----------------------+         +-----------------------+
   |  player_card.riv      |  +      |  brand_packs/         |
   |  (변수만 정의)         |         |    wsop_2026.json     |
   +-----------------------+         |    ept_2026.json      |
              |                      |    gg_master.json     |
              |   (브랜드 변수 주입)   +-----------------------+
              v
   +-----------------------+
   |  화면 출력 결과         |
   |  - WSOP 일 때 검정·금색  |
   |  - EPT 일 때 빨강·검정   |
   |  - GG 일 때 청록·흰색    |
   +-----------------------+
```

Brand Pack 은 **EBS DB** 에 저장된다 (Ch.7 참조). 대회 하나가 시작되면 그 대회의 Brand Pack 이 모든 `.riv` 파일에 주입된다.

<a id="ch7"></a>

## Ch.7 — EBS DB

### 7.1 EBS DB 가 가져오는 것

EBS DB 는 **시간이 지나도 변하지 않는** 데이터의 저장소다. 한 핸드, 한 토너먼트가 끝나도 사라지지 않는다.

| 도메인 | 데이터 |
|--------|--------|
| **Player Profile** | 이름, 국적, 아바타 이미지, 경력, 별명 |
| **Tournament** | 대회명, 일정, 상금 풀, 바이인, 레벨 구조 |
| **Brand Pack** | 컬러 팔레트, 폰트, 로고 (3 종), 그래픽 모티프 |
| **Sponsor** | 스폰서 로고, 회전 슬롯, 노출 시간 |
| **History** | 과거 우승자, 이전 핸드 기록 |
| **Asset Index** | `.riv` 파일의 위치, 버전, 만료 |

### 7.2 어떻게 query 되는가

DB 의 데이터는 — Engine 또는 Renderer 가 — query 하여 Rive Variable 에 주입한다.

```
   +----------------+
   |  Game Engine   |
   +-------+--------+
           |
           | "이번 핸드 P3 좌석의 player_id 는?"
           v
   +-------+--------+
   |  RFID + Lobby   |  (RFID 좌석 매핑 + 좌석↔player 매핑)
   +-------+--------+
           |
           | "player_id = 472"
           v
   +-------+--------+
   |  EBS DB        |
   |  SELECT name,   |
   |  country, ...   |
   |  WHERE id=472   |
   +-------+--------+
           |
           v
   +-------+--------+
   |  Rive Variable |
   |  player_name   |
   |  country_code  |
   +----------------+
```

### 7.3 캐싱 전략 (1 차 가설)

매 프레임마다 DB 를 조회하지 않는다. 한 핸드의 시작에 한 번 로드하여 **메모리 캐시** 에 둔다.

| 캐시 영역 | TTL |
|----------|-----|
| Player Profile (현재 테이블) | 한 핸드 |
| Tournament 정보 | 한 레벨 |
| Brand Pack | 한 대회 |
| Sponsor | 한 대회 |
| Asset Index | 앱 시작 시 |

> TTL (Time To Live) 정책은 1 차 가설. 외부 검증 후 확정.

<a id="ch8"></a>

## Ch.8 — Command Center 입력

### 8.1 Command Center 가 가져오는 것

운영자가 키보드로 입력하는 — 다른 어떤 데이터 소스에도 없는 — 한 핸드의 **결정** 들.

| 입력 | 의미 |
|------|------|
| **NEW HAND** | 새 핸드 시작 신호 |
| **DEAL** | 홀카드 딜 시작 |
| **FOLD** | 좌석 i 가 패를 포기 |
| **CHECK** | 좌석 i 가 패스 |
| **BET** + 금액 | 좌석 i 가 첫 베팅 |
| **CALL** | 좌석 i 가 동일 금액 매칭 |
| **RAISE** + 금액 | 좌석 i 가 추가 베팅 |
| **ALL-IN** | 좌석 i 가 전체 스택 |
| **HAND END** | 핸드 종료 + 우승자 결정 |
| **TIME BANK** | 좌석 i 가 추가 시간 사용 |

### 8.2 입력이 변수로 가는 길

운영자의 한 키 입력이 — 화면의 그래픽 한 조각으로 변환되는 길.

```
   운영자: [R] 키 + 숫자 [30000] + [Enter]
                |
                v
   +---------------------+
   |  Command Center     |
   |  Action 객체 생성    |
   |  {                  |
   |    type: "RAISE",   |
   |    seat: 3,         |
   |    amount: 30000    |
   |  }                  |
   +---------+-----------+
             |
             v
   +---------------------+
   |  Game Engine 수신    |
   |  - 베팅 라운드 갱신   |
   |  - 팟 갱신           |
   |  - 다음 차례 결정     |
   +---------+-----------+
             |
             v
   +---------------------+
   |  Rive Variables     |
   |  - bet_amount[3] = 30000      |
   |  - on_action[3] (trigger)     |
   |  - actor_index = 4 (다음)     |
   |  - pot_total += 30000         |
   +---------+-----------+
             |
             v
   +---------------------+
   |  Rive 화면 갱신      |
   |  - P3 베팅 라인 등장 |
   |  - "RAISE" 라벨     |
   |  - P4 highlight     |
   |  - 팟 카운트업       |
   +---------------------+
```

### 8.3 Command Center 가 직접 변수에 닿는 것 vs Engine 을 거치는 것

| 변수 | 직접 / Engine 경유 |
|------|:-----------------:|
| `on_action` (trigger) | **직접** (CC → Rive) |
| 액션 라벨 텍스트 ("RAISE" 등) | **직접** |
| `bet_amount` | Engine (검증 + 정합 후) |
| `stack_amount` | Engine (베팅만큼 차감) |
| `pot_total` | Engine (합산) |
| `actor_index` (다음 차례) | Engine (게임 룰 적용) |

원칙: **즉각 반응이 필요한 시각 표식 (라벨, 트리거) 은 직접 / 계산이 필요한 숫자는 Engine 경유**.

<a id="ch9"></a>

## Ch.9 — RFID

### 9.1 RFID 가 가져오는 것

테이블 아래 깔린 11 개 안테나 (10 좌석 + 1 보드) 가 카드의 NFC 태그를 읽어 가져오는 단 한 가지 데이터:

| 데이터 | 형식 |
|--------|------|
| 카드 ID | 무늬 + 숫자 (예: `AS` = Ace of Spades) |
| 좌석 / 위치 | 안테나 번호 → 좌석 / 보드 매핑 |
| 시점 | 카드가 안테나에 닿은 순간 |

### 9.2 RFID 가 답하는 질문

> **"지금 좌석 3 의 첫 카드는 무엇인가?"**

이 질문에 답하는 것이 RFID 의 유일한 역할이다.

```
   +----------------------------------------------+
   |                                              |
   |          [Comm Card Antenna]                 |
   |              · · · · ·                       |
   |          (테이블 중앙)                        |
   |                                              |
   |   [P1] [P2] [P3] [P4] [P5]                   |
   |    안테나 1~5                                |
   |                                              |
   |   [P6] [P7] [P8] [P9] [P10]                  |
   |    안테나 6~10                               |
   |                                              |
   +----------------------------------------------+
              ASCII MOCK · 11 안테나 배치
```

<!-- IMG_TODO: 실제 테이블의 RFID 안테나 배치 (top-down view) -->

### 9.3 RFID 가 변수로 가는 길

```
   카드가 안테나 3 위에 놓임
        |
        v
   +---------------------+
   |  RFID 안테나 3 신호  |
   |  NFC ID = "AS"      |
   +---------+-----------+
             |
             v
   +---------------------+
   |  RFID Reader 변환    |
   |  {                  |
   |    seat: 3,         |
   |    slot: "hole_1",  |
   |    card: "AS"       |
   |  }                  |
   +---------+-----------+
             |
             v
   +---------------------+
   |  Game Engine 수신    |
   |  - 핸드 전개 검증     |
   |  - 카드 공개 시점 결정 |
   +---------+-----------+
             |
             v
   +---------------------+
   |  Rive Variables     |
   |  hole_card_1[3] = "AS"        |
   |  show_hole_card[3] (trigger)  |
   +---------------------+
```

### 9.4 보드 (커뮤니티) 의 특별한 흐름

좌석의 홀카드와 달리, 보드 카드는 **공개 시점이 게임 단계에 따라 결정**된다.

| 카드 | 공개 시점 |
|------|---------|
| 보드 1, 2, 3 (Flop) | Flop 이 시작될 때 |
| 보드 4 (Turn) | Turn 이 시작될 때 |
| 보드 5 (River) | River 가 시작될 때 |

RFID 가 카드를 인식해도 — 게임 단계가 도래해야 변수가 활성화된다.

```
   카드가 보드 안테나 위에 놓임
        |
        v
   RFID 인식 (즉시)
        |
        v
   +---------------------+
   |  Game Engine 보관    |
   |  pendingBoard[1..5]  |
   +---------+-----------+
             |
             | (게임 단계 도래 시 — Command Center 가 보냄)
             v
   +---------------------+
   |  Rive Variables     |
   |  community_card[i]  |
   |  show_community[i]  |
   +---------------------+
```

<a id="ch10"></a>

## Ch.10 — Game Engine

### 10.1 Game Engine 이 가져오는 것

다른 네 데이터 소스의 입력을 받아 — **계산해서** 새 데이터를 만든다. 가장 풍부한 출력을 만드는 소스다.

| 계산 결과 | 의미 |
|-----------|------|
| `stack[i]` | 좌석 i 의 현재 칩 (베팅만큼 차감 누적) |
| `bet_round[i]` | 좌석 i 의 이번 라운드 베팅 합계 |
| `pot_main` | 메인 팟 |
| `pot_side[]` | 사이드 팟 (ALL-IN 시 분리) |
| `actor_index` | 지금 차례인 좌석 |
| `equity[i]` | 좌석 i 가 이길 확률 |
| `hand_strength[i]` | 좌석 i 의 현재 핸드 명칭 |
| `phase` | preflop / flop / turn / river / showdown |
| `hand_clock` | 한 핸드의 진행 시간 |
| `level_clock` | 레벨 남은 시간 |
| `players_left` | 토너먼트 전체 남은 인원 |
| `avg_stack` | 평균 스택 |
| `winner_seat` | 우승자 좌석 (핸드 종료 시) |

### 10.2 Game Engine 의 입력 의존성

Engine 은 단독으로 작동하지 않는다. 다른 네 데이터 소스의 입력에 기반한다.

```
   +---------------+   +---------------+   +---------------+
   |  EBS DB       |   |  RFID         |   | Command Center |
   |  (선수 정보,   |   |  (카드 정체)   |   | (액션 + 금액)  |
   |   토너 정보)   |   |               |   |                |
   +-------+-------+   +-------+-------+   +-------+-------+
           |                   |                   |
           +---------+---------+-------------------+
                     |
                     v
              +-------------+
              | Game Engine |
              |  (계산기)    |
              +------+------+
                     |
                     v
   +-----------------+-----------------+
   |   계산된 결과 → Rive Variables    |
   |                                   |
   |   stack / bet_round / pot         |
   |   actor_index / equity            |
   |   hand_strength / phase           |
   |   players_left / avg_stack ...    |
   +-----------------------------------+
```

### 10.3 게임 룰의 변형

| 게임 | Engine 동작의 차이 |
|------|------------------|
| **NL Hold'em** | 표준. 홀카드 2 / 커뮤니티 5 |
| **PL Omaha** | 홀카드 4. Equity 시뮬 입력이 더 큼 |
| **Stud** | 커뮤니티 카드 없음. door card 분리 |
| **Razz** | "낮은 패가 이긴다". hand_strength 평가 반전 |
| **Mixed Game** | 게임 종목 회전. phase 와 별도로 game_type 변수 |

> Engine 의 게임 룰 상세는 Game_Rules 폴더 정본 참조.

### 10.4 Engine 이 직접 만지지 않는 변수

Engine 은 **계산** 의 책임만 진다. 다음 변수는 Engine 의 책임이 아니다:

| 변수 | 책임 작가 |
|------|----------|
| `player_name` | EBS DB |
| `country_code` | EBS DB |
| `brand_color_*` | EBS DB (Brand Pack) |
| `hole_card[i][j]` | RFID |
| `community_card[i]` | RFID (Engine 이 시점만 결정) |
| `last_action_label` | Command Center |
| `is_folded[i]` | Command Center (Engine 이 검증) |

<a id="ch11"></a>

## Ch.11 — 다섯의 합류

### 11.1 한 변수에서 다섯이 만나는 사례

5 데이터 소스는 **같은 변수에 동시에 쓰지 않는다**. 각 변수는 **단 하나의 소스가 책임**진다. 그러나 한 그래픽 조각을 만들기 위해서는 여러 변수가 동시에 채워져야 한다.

예시: **Player Card 한 장이 그려지려면**

```
   player_card.riv (P3 좌석)
   +-------------------------------------+
   |   변수             |  책임 소스      |
   +-------------------------------------+
   |   player_name      |  EBS DB         |
   |   country_code     |  EBS DB         |
   |   avatar_image     |  EBS DB         |
   |   stack_amount     |  Game Engine    |
   |   bet_amount       |  Game Engine    |
   |   equity_percent   |  Game Engine    |
   |   hand_label       |  Game Engine    |
   |   is_to_act        |  Game Engine    |
   |   is_folded        |  Command Center |
   |   on_action        |  Command Center |
   |   hole_card_1      |  RFID           |
   |   hole_card_2      |  RFID           |
   |   show_hole        |  Game Engine    |  (시점 결정)
   |   brand_color_*    |  EBS DB         |  (Brand Pack)
   |   (그래픽 형태)       |  Rive Asset     |  (.riv 파일)
   +-------------------------------------+
```

5 소스 모두가 한 Player Card 의 변수를 채운다. 한 소스라도 빠지면 그 자리는 변수가 default 값으로 남는다.

### 11.2 합류 다이어그램

```
   +----------+   +----------+   +----------+   +----------+   +----------+
   |  Rive    |   |  EBS DB  |   |   CC     |   |  RFID    |   | Engine   |
   |  Asset   |   |          |   |          |   |          |   |          |
   +----+-----+   +----+-----+   +----+-----+   +----+-----+   +----+-----+
        |              |              |              |              |
        | (그래픽)     | (이름·       | (액션·       | (카드        | (계산된
        |              |  Brand)      |  trigger)    |  ID)         |  숫자)
        |              |              |              |              |
        v              v              v              v              v
   +-----------------------------------------------------------------------+
   |                    Rive Variables (player_card.riv)                   |
   |                                                                       |
   |   player_name | brand_* | bet_amount | hole_card | stack | equity ... |
   +---------------------------------+-------------------------------------+
                                     |
                                     v
                         +------------------------+
                         |   Rive Renderer        |
                         |   (변수 -> 픽셀)       |
                         +------------+-----------+
                                      |
                                      v
                         +------------------------+
                         |   Overlay 화면 출력     |
                         +------------------------+
```

### 11.3 변수 책임 매트릭스 (요약)

본 매트릭스는 5 데이터 소스가 12 카테고리에 어떻게 기여하는지를 한 번에 보여준다.

```
                      Rive   EBS    CC     RFID   Engine
                      Asset  DB
   ----------------- ------ ------ ------ ------ -------
   Player Card        Asset  이름   폴드   좌석    스택
   Stack + Bet        Asset  -      -      -      합산
   홀카드             Asset  -      -      ID     공개시점
   커뮤니티 카드       Asset  -      -      ID     공개시점
   Hand Strength      Asset  -      -      -      계산
   액션 표식          Asset  -      라벨   -      차례
   팟                 Asset  -      -      -      합산
   블라인드           Asset  스케줄  -      -      현재값
   토너먼트 상태       Asset  기준값  -      -      현재값
   시계               Asset  -      Time   -      카운트
                              -    Bank
   브랜딩             Asset  Brand  -      -      -
                              Pack
   운영자 표식        Asset  -      모드   진단    응답상태
   우승 화면          Asset  트로피  -      -      우승자
```

이 표는 Part IV 본문의 12 챕터에서 각각 자세히 풀어진다.

---

# Part IV — 그래픽 요소 카탈로그

이 Part 의 12 챕터는 같은 형식을 갖는다.

| 섹션 | 내용 |
|------|------|
| {N}.1 시각 | 그래픽이 어떻게 보이는가 (ASCII mockup) |
| {N}.2 데이터 소스 매핑 | 어디에서 어떤 데이터가 오는가 |
| {N}.3 변화의 순간 | 언제 그래픽이 바뀌는가 |

<a id="ch12"></a>

## Ch.12 — 플레이어 정체성

### 12.1 시각

```
  +-----------------------------+
  | [국기] PLAYER A (가공)       |  <- 이름 (Primary)
  |        Country               |  <- 국적 (Secondary)
  |                              |
  |  Stack: 1,250,000            |  <- 칩 스택
  |  ━━━━━━━━━━━━━━━━━━━━━━━━━ |  <- 스택 바
  |                              |
  |  [Avatar 64x64]              |  <- 아바타 (선택)
  +-----------------------------+
              ASCII MOCK · Player Card 기본형
```

<!-- IMG_TODO: Player Card 디자인 시안 (정상 / 강조 / 폴드 3 상태) -->

### 12.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (도형, 폰트, 그림자) | Rive Asset (`player_card.riv`) |
| `player_name` | EBS DB (Player Profile) |
| `country_code` + 국기 이미지 | EBS DB |
| `avatar_image` | EBS DB |
| `seat_index` (좌석 매핑) | RFID + Lobby seat-map |
| `stack_amount` | Game Engine |
| `is_to_act` | Game Engine |
| `is_folded` | Command Center |
| `is_eliminated` | Game Engine |
| `brand_color_*` | EBS DB (Brand Pack) |

### 12.3 변화의 순간

| 이벤트 | 변화 |
|--------|------|
| 좌석 착석 | Entry 애니메이션 (페이드 + 슬라이드) |
| 칩 스택 변동 | Stack 숫자 Tween |
| 차례 (To Act) | highlight border 펄싱 |
| 폴드 | dim + grayscale + 50% 투명 |
| 탈락 | Exit 애니메이션 |
| 다른 테이블로 이동 | Player Card 제거 |


<a id="ch13"></a>

## Ch.13 — 칩 스택과 베팅 라인

### 13.1 시각

```
  +----------------------------+        +----------------------------+
  | PLAYER A (가공)             |        | PLAYER B (가공)             |
  | Stack: 1,250,000           |        | Stack:   480,000           |
  +----------------------------+        +----------------------------+
            |                                       |
            v  Bet: 50,000                          v  Bet: 50,000
       [Chip Stack Icon]                       [Chip Stack Icon]
            \                                     /
             \                                   /
              \         [POT: 250,000]          /
               \________/                \_____/
              ASCII MOCK · 베팅 라인이 팟으로 흘러가는 모습
```

### 13.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (라인 도형, 칩 아이콘) | Rive Asset (`stack_bet.riv`) |
| `stack_amount` | Game Engine |
| `bet_amount` (이번 라운드) | Command Center → Engine 검증 |
| 색상 (스택 위계 — 안정/위험) | Rive Asset 변수 (Engine 이 임계값 비교 후 색상 변수 주입) |

### 13.3 변화의 순간

| 이벤트 | 변화 |
|--------|------|
| BET / RAISE / CALL | 칩 → 베팅라인 슬라이드 + 숫자 카운트업 |
| 라운드 종료 | 베팅 라인 → 팟 sweep 애니메이션 |
| ALL-IN | 전체 stack → 베팅라인 통째 이동 |

### 13.4 스택 위계 색상 (1 차 가설)

| 스택 크기 | 제안 색상 | 이유 |
|-----------|----------|------|
| > 평균 × 1.5 | Green | 안정 |
| 평균 ± 50% | White | 보통 |
| < 평균 × 0.5 | Yellow | 위험 |
| < BB × 10 | Red | 다음 핸드면 모든 칩이 블라인드로 사라질 수 있는 위치 |

> 색상은 1 차 가설. 외부 디자이너 / 방송 PD 검증 후 확정.


<a id="ch14"></a>

## Ch.14 — 카드: 홀카드 + 커뮤니티

### 14.1 시각 — 홀카드

```
   카메라 화면 (실물)             Overlay 가 덧씌운 화면

   +-------+                       +-------+
   | (뒤)  |                       | A♠ K♠ |
   |       |       =>              | (앞면 |
   |       |                       |  공개) |
   +-------+                       +-------+
   플레이어 손에 있는              RFID 가 인식한 카드를
   뒤집힌 카드                      Overlay 가 덧씌움
```

### 14.2 시각 — 커뮤니티

```
  +--------------------------------------------+
  |                                            |
  |  [ A♠ ] [ K♥ ] [ Q♦ ]  <- Flop (3 장)        |
  |                                            |
  |  [ A♠ ] [ K♥ ] [ Q♦ ] [ J♣ ]                |
  |                              ↑             |
  |                            Turn (4 번째)    |
  |                                            |
  |  [ A♠ ] [ K♥ ] [ Q♦ ] [ J♣ ] [ T♠ ]         |
  |                                    ↑       |
  |                                  River     |
  |                                (5 번째)     |
  +--------------------------------------------+
              ASCII MOCK · Flop -> Turn -> River
```

<!-- IMG_TODO: Flip 애니메이션 키프레임 (Rive .riv 시안) -->

### 14.3 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (카드 도형, 무늬 SVG) | Rive Asset (`hole_card.riv`, `community_card.riv`) |
| `card_id` (예: "AS") | RFID |
| `seat_index` / `board_slot` | RFID (안테나 매핑) |
| `show_card` (공개 시점 trigger) | Game Engine (게임 단계 도래 시) |

### 14.4 카드 등장 4 단계

```
  +-----+       +-----+       +-----+       +-----+
  |     |  ->   |  ▌  |  ->   |  /  |  ->   | A♠ |
  | (뒤)|       |회전 |       |회전 |       |(앞) |
  +-----+       +-----+       +-----+       +-----+
   단계 1        단계 2        단계 3        완료
```

> 회전 키프레임의 길이와 보간은 디자이너의 영역. 본 문서는 단계의 존재만 정의한다.


<a id="ch15"></a>

## Ch.15 — 핸드 강도와 Equity

### 15.1 시각

```
  +----------------------------------+
  | PLAYER A (가공)                   |
  | A♠ K♠                             |
  |                                  |
  | Flush Draw                       |  <- 핸드 명칭
  | --------                         |
  | 65.2%                            |  <- Equity (%)
  | ▰▰▰▰▰▰▱▱▱                        |  <- 시각 게이지
  +----------------------------------+
              ASCII MOCK · Hand Strength + Equity
```

### 15.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (게이지 도형) | Rive Asset (`hand_strength.riv`) |
| `hand_label` (예: "Flush Draw") | Game Engine |
| `equity_percent` | Game Engine |
| `is_winning` (우승 가능성 100%) | Game Engine |

### 15.3 핸드 명칭 (11 종)

| 명칭 | 영문 |
|------|------|
| 하이카드 | High Card |
| 원페어 | One Pair |
| 투페어 | Two Pair |
| 트립스 / 셋 | Three of a Kind |
| 스트레이트 | Straight |
| 플러시 | Flush |
| 풀하우스 | Full House |
| 포카드 | Four of a Kind |
| 스트레이트 플러시 | Straight Flush |
| 로열 플러시 | Royal Flush |
| (드로우) | Straight Draw / Flush Draw |

### 15.4 Equity 의 변화

| 단계 | Engine 시뮬 |
|------|-----------|
| Preflop | 보유 카드만으로 시뮬 |
| Flop | + 커뮤니티 3 장, 남은 2 장 시뮬 |
| Turn | + 커뮤니티 4 장, 남은 1 장 시뮬 |
| River | 100% 또는 0% 확정 |

게이지가 100% 가 되면 — 우승 직전을 알리는 황금색 펄싱 (Rive Asset 책임).

<a id="ch16"></a>

## Ch.16 — 액션 표식

### 16.1 8 가지 액션

| 액션 | 표식 | 색상 (1 차 가설) |
|------|------|------|
| **NEW HAND** | "딜링 중..." 모달 | 흰색 |
| **DEAL** | 홀카드 등장 (Flip) | — |
| **FOLD** | 카드 회색 + 좌석 dim | 회색 |
| **CHECK** | "CHECK" 텍스트 | 청색 |
| **BET** | 칩 → 베팅라인 + "BET" 라벨 | 황색 |
| **CALL** | 칩 → 베팅라인 매칭 | 청색 |
| **RAISE** | 칩 → 베팅라인 + "RAISE" 라벨 | 적색 |
| **ALL-IN** | 전체 스택 → "ALL-IN" 박스 | 흑색 + 진동 |

> 색상은 1 차 가설. 외부 디자이너 / Brand Pack 별 override.

### 16.2 ALL-IN 박스

```
  +====================================================+
  |                                                    |
  |          ★★★  ALL-IN  ★★★                         |
  |                                                    |
  |        PLAYER A goes ALL-IN                        |
  |              for {amount}                          |
  |                                                    |
  |          ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰                        |
  |              (펄싱)                                 |
  +====================================================+
              ASCII MOCK · ALL-IN 박스 (전화면 강조)
```

### 16.3 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (라벨 도형, 박스) | Rive Asset (`action_badge.riv`) |
| 라벨 텍스트 ("RAISE" 등) | Command Center |
| `on_action` trigger | Command Center |
| 라벨 색상 | EBS DB (Brand Pack) — `action_color_raise` 등 |
| ALL-IN 시 amount 표시 | Game Engine (전체 스택값) |

<a id="ch17"></a>

## Ch.17 — 팟

### 17.1 시각 — 메인 + 사이드

```
  +======================================================+
  |                                                      |
  |        (테이블 + 좌석 + 카드)                          |
  |                                                      |
  |    [Main Pot: 800,000]    [Side Pot 1: 300,000]      |
  |                            (P3 only)                  |
  |    [Side Pot 2: 150,000]                              |
  |    (P5 only)                                          |
  |                                                      |
  +======================================================+
              ASCII MOCK · 다중 사이드 팟 표시
```

### 17.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (팟 박스, 칩 그래픽) | Rive Asset (`pot.riv`) |
| `pot_main_amount` | Game Engine |
| `pot_side[i]_amount` | Game Engine (ALL-IN 시 분리) |
| `pot_side[i]_eligible_seats[]` | Game Engine |
| `winner_seat` (우승 흡수 시) | Game Engine |

### 17.3 변화의 순간

| 이벤트 | 애니메이션 |
|--------|-----------|
| 베팅 추가 | 팟 숫자 카운트업 tween |
| 라운드 종료 | 베팅 라인 → 팟 sweep |
| 사이드 팟 생성 | 메인 팟에서 분리 + 새 박스 등장 |
| 우승자 결정 | 팟 → 우승자 Player Card 흡수 |


<a id="ch18"></a>

## Ch.18 — 블라인드와 레벨

### 18.1 시각

```
  +============================================+
  |  Level {N}                                  |
  |  Blinds: {SB} / {BB}                        |
  |  Ante:   {Ante}                             |
  |  Time Left: {MM:SS}                         |
  +============================================+
              ASCII MOCK · 좌측 하단 블라인드 박스
```

### 18.2 레벨 전환 알림 (1 분 전)

```
  +======================================================+
  |                                                      |
  |    NEXT LEVEL IN 1:00                                |
  |    Blinds will increase to {next-SB} / {next-BB}     |
  |    Ante: {next-ante}                                 |
  |                                                      |
  +======================================================+
              ASCII MOCK · 레벨 전환 1 분 전 알림 (상단 배너)
```

### 18.3 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| 그래픽 형태 | Rive Asset (`blind_level.riv`) |
| `level_index` | Game Engine |
| `sb_amount` / `bb_amount` / `ante_amount` | EBS DB (스케줄) → Engine (현재 레벨 lookup) |
| `level_clock` | Game Engine |
| `next_level_*` (전환 알림용) | EBS DB (다음 레벨 미리 fetch) |

<a id="ch19"></a>

## Ch.19 — 토너먼트 상태

### 19.1 시각

```
  +======================================================+
  |  {Tournament Name} · Day {N}                          |
  |                                                      |
  |  Players Left:  {N} / {Total}                        |
  |  Avg Stack:     {Average}                            |
  |  ITM:           {ITM-position} (Top {%})             |
  |  Prize Pool:    ${Total}                             |
  |  Next Payout:   ${Amount} ({Position})               |
  +======================================================+
              ASCII MOCK · 토너먼트 상태 (우상단)
```

### 19.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| 그래픽 형태 | Rive Asset (`tournament_state.riv`) |
| `tournament_name` | EBS DB |
| `total_players` | EBS DB (등록 인원) |
| `players_left` | Game Engine |
| `avg_stack` | Game Engine |
| `itm_position` | EBS DB (상금 구조) |
| `prize_pool` | EBS DB |
| `next_payout` | EBS DB |

### 19.3 ITM 의 드라마

| ITM 거리 | 그래픽 강조 |
|----------|-----------|
| Bubble 까지 5 명 | "5 from Money" 작은 표시 |
| Bubble 까지 1 명 | **"BUBBLE" 전화면 배너** |
| Bubble Burst | "MONEY!" 축하 애니메이션 |

<a id="ch20"></a>

## Ch.20 — 시계와 Time Bank

### 20.1 두 종류

| 시계 | 측정 | 위치 |
|------|------|------|
| **Hand Clock** | 한 핸드의 진행 시간 | 화면 상단 작게 |
| **Level Clock** | 레벨 남은 시간 | 좌측 하단 블라인드 박스 |

### 20.2 Time Bank

```
  +============================================+
  |  [TIME BANK]                                |
  |  PLAYER A (가공)                            |
  |  +0:30 added                                |
  |  Time:  0:45                                |
  |  ▰▰▰▰▰▰▰▰▱▱                                 |
  |  Time Banks: 2 / 5                          |
  +============================================+
              ASCII MOCK · Time Bank 사용 표시
```

### 20.3 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| 그래픽 형태 | Rive Asset (`clock.riv`) |
| `hand_clock_seconds` | Game Engine |
| `level_clock_seconds` | Game Engine |
| `time_bank_active` | Command Center (사용 시작 시 trigger) |
| `time_bank_remaining[i]` | Game Engine |

<a id="ch21"></a>

## Ch.21 — 브랜딩

### 21.1 4 슬롯

```
  +======================================================+
  |  [Tournament Logo]                    [Sponsor Logo] |
  |                                                      |
  |       (테이블 콘텐츠)                                  |
  |                                                      |
  |  [Watermark · 우하단]                                  |
  |  [Bottom Banner — 회전 광고]                          |
  +======================================================+
              ASCII MOCK · 4 브랜딩 슬롯
```

### 21.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (슬롯 위치, 회전 메커니즘) | Rive Asset (`branding.riv`) |
| `tournament_logo_url` | EBS DB (Brand Pack) |
| `sponsor_logos[]` | EBS DB (Sponsor 테이블) |
| `watermark_url` | EBS DB (Brand Pack) |
| `bottom_banner_slots[]` | EBS DB (광고 스케줄) |
| `rotation_interval_seconds` | EBS DB (Brand Pack) |

### 21.3 Brand Pack 의 Override 흐름

대회마다 Brand Pack 이 바뀌면 — 다른 모든 카테고리 (Player Card, 팟, 시계 등) 의 색상도 동시에 바뀐다. Brand Pack 은 **Player Card.riv 안의 색상 변수도** 함께 채운다.

```
   대회 = WSOP 2026
        |
        v
   EBS DB.brand_pack["wsop_2026"]
        |
        | 모든 .riv 파일에 동시 주입
        v
   +----------------+----------------+----------------+
   | player_card.riv| pot.riv        | clock.riv      |
   | brand_color_*  | brand_color_*  | brand_color_*  |
   +----------------+----------------+----------------+
```

<a id="ch22"></a>

## Ch.22 — 운영자 전용 표식

### 22.1 시청자에게 보이지 않는 영역

이 카테고리는 **PGM 채널 (시청자 송출) 에 절대 나가지 않는다**. OPS 채널 (운영자 모니터) 에만 표시된다.

```
  +======================================================+
  |  [PGM 화면 그대로 + 아래 추가 정보]                    |
  |                                                      |
  |  ----------------------------------------            |
  |                                                      |
  |  RFID Status:                                        |
  |    Antenna 1: OK    Antenna 6: OK                    |
  |    Antenna 2: OK    Antenna 7: slow                  |
  |    Antenna 3: disconnected   ...                     |
  |                                                      |
  |  Engine 응답 상태: OK                                  |
  |  Last Action:   {액션} by P{N}                        |
  |  Mock Mode:     OFF                                  |
  |                                                      |
  |  [DEBUG TOGGLE]  [ERROR LOG]  [MOCK MODE]            |
  +======================================================+
              ASCII MOCK · 운영자 화면 하단 debug 영역
```

### 22.2 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| Rive Asset (debug 패널 도형) | Rive Asset (`ops_overlay.riv`) |
| `rfid_status[1..11]` | RFID (안테나 진단) |
| `engine_responsive` | Game Engine (heartbeat) |
| `last_action_summary` | Command Center |
| `mock_mode_active` | Command Center (운영자 토글) |

### 22.3 채널 분리

| 채널 | 출력 |
|------|------|
| **PGM (Program)** | Ch.12-21, 23 만 |
| **OPS (Operator)** | PGM + Ch.22 (debug) |
| **BAK (Backup)** | PGM 동일 |
| **REC (Recording)** | PGM 동일 |

분리는 **하드웨어 SDI (Serial Digital Interface — 방송용 디지털 영상 전송 표준) 라우터** 에서 보장.

<a id="ch23"></a>

## Ch.23 — 우승 화면

### 23.1 핸드 종료 — Showdown

```
  +======================================================+
  |                                                      |
  |          🏆  HAND WINNER  🏆                          |
  |                                                      |
  |        {Player Name}                                 |
  |        {Hand Description}                            |
  |                                                      |
  |        Won: {Pot Amount}                             |
  |                                                      |
  |  [팟 → 우승자 Player Card 흡수 애니메이션]              |
  +======================================================+
              ASCII MOCK · 핸드 종료 우승자 표시
```

### 23.2 토너먼트 종료 — Champion

```
  +======================================================+
  |                                                      |
  |        ★★★★★★★★★★★★★★★★★★★★★★★★★★★                  |
  |                                                      |
  |             {TOURNAMENT NAME} CHAMPION               |
  |                                                      |
  |             {Player Name}                            |
  |                                                      |
  |             Prize: ${Amount}                         |
  |                                                      |
  |             [Trophy Image]                           |
  |                                                      |
  |        ★★★★★★★★★★★★★★★★★★★★★★★★★★★                  |
  +======================================================+
              ASCII MOCK · 토너먼트 챔피언 (전화면)
```

### 23.3 데이터 소스 매핑

| 변수 | 데이터 소스 |
|------|------|
| 그래픽 형태 | Rive Asset (`winner.riv`) |
| `winner_seat` / `winner_player_id` | Game Engine |
| `winner_name` | EBS DB (lookup) |
| `winning_hand_description` | Game Engine |
| `winning_pot_amount` | Game Engine |
| `trophy_image` | EBS DB (Brand Pack) |


---

# Part V — 살아 움직이는 법

<a id="ch24"></a>

## Ch.24 — State Machine

### 24.1 Rive State Machine 의 정체

`.riv` 파일 안에는 — 그래픽이 가질 수 있는 **상태들** 과 **상태 사이를 이동하는 규칙** 이 정의되어 있다. 디자이너가 Rive Editor 에서 시각적으로 그린다.

### 24.2 Player Card 의 State Machine 예시

```
   player_card.riv 의 상태 머신
   +--------------------------------------------+
   |                                            |
   |   [hidden]                                 |
   |      |                                     |
   |   on_seat (true)                           |
   |      v                                     |
   |   [entering] (페이드 인 + 슬라이드)          |
   |      |                                     |
   |   onActionComplete                         |
   |      v                                     |
   |   [idle] ---- is_to_act --> [highlighted]  |
   |      ^                          |          |
   |      +--- !is_to_act ------------+          |
   |      |                                     |
   |   is_folded (true)                         |
   |      v                                     |
   |   [folded] (회색 + dim)                     |
   |      |                                     |
   |   is_eliminated (true)                     |
   |      v                                     |
   |   [exiting] (페이드 아웃)                    |
   +--------------------------------------------+
```

### 24.3 누가 State 를 바꾸는가

State 의 전환은 **Rive Variable 의 값 변화** 가 trigger 한다. 5 데이터 소스 중 책임 소스가 자기 변수를 갱신하면 — Rive 가 자동으로 적절한 상태로 이동한다.

| State 전환 | trigger 변수 | 책임 작가 |
|-----------|------------|----------|
| hidden → entering | `on_seat` (true) | RFID + Lobby seat-map |
| idle → highlighted | `is_to_act` (true) | Game Engine |
| idle → folded | `is_folded` (true) | Command Center |
| idle → exiting | `is_eliminated` (true) | Game Engine |

> 디자이너는 변수 trigger 만 정의한다. 실제로 누가 그 trigger 를 누르는지는 디자이너의 관심 밖.

<a id="ch25"></a>

## Ch.25 — 게임 흐름과 그래픽 전이

### 25.1 5 단계 (Hold'em 기준)

```
  +-------------+    +-------------+    +-------------+
  |  Preflop    |    |    Flop     |    |    Turn     |
  | (홀카드만)   | -> | (커뮤니티 3) | -> | (커뮤니티 4) | ->
  +-------------+    +-------------+    +-------------+

  +-------------+    +-------------+
  |   River     |    |  Showdown   |
  | (커뮤니티 5) | -> | (모든 카드   |
  +-------------+    |   공개)      |
                     +-------------+
```

### 25.2 단계 전이 시 일어나는 일

| 전이 | 변수 변화 | 그래픽 변화 |
|------|----------|----------|
| Preflop → Flop | `phase = "flop"`, `community_card[1..3]` 활성화 | 커뮤니티 카드 3 장 Flip |
| Flop → Turn | `phase = "turn"`, `community_card[4]` 활성화 | Turn 카드 Flip + Equity 갱신 |
| Turn → River | `phase = "river"`, `community_card[5]` 활성화 | River Flip + Equity 갱신 |
| River → Showdown | `phase = "showdown"`, 모든 `show_hole[i]` 활성화 | 모든 홀카드 공개 + Hand Strength 라벨 |
| Showdown → 우승 | `winner_seat` 결정 | 팟 → 우승자 흡수 |

### 25.3 베팅 라운드 종료 sweep

각 단계마다 베팅 라운드가 있다. 라운드 종료 시:

```
   베팅 라운드 종료 (Game Engine 판정)
        |
        v
   bet_round[i] = 0  (모든 좌석 리셋)
   pot_main += sum(이전 bet_round)
        |
        v
   Rive 가 변수 변화를 감지하여:
   - 모든 베팅 라인 -> 팟 sweep 애니메이션
   - 팟 카운트업 tween
        |
        v
   다음 단계 (Flop / Turn / River) 카드 등장
```

<a id="ch26"></a>

## Ch.26 — Entry / Emphasis / Exit

모든 그래픽 요소는 **3 막극** 으로 움직인다.

### 26.1 3 막의 정의

| 막 | 의미 | Rive 구현 |
|----|------|----------|
| **Entry** | 등장 (페이드 + 슬라이드 + 스케일) | Timeline 애니메이션 (한 번 재생) |
| **Emphasis** | 강조 (펄싱, 색상, 흔들림) | State Machine `highlighted` 상태 |
| **Exit** | 퇴장 (페이드 + 축소) | Timeline 애니메이션 (한 번 재생) |

### 26.2 요소별 패턴

| 요소 | Entry | Emphasis | Exit |
|------|-------|----------|------|
| Player Card | 슬라이드 + 페이드 | `is_to_act` 펄싱 | `is_eliminated` 페이드 |
| 카드 (홀카드) | Flip (뒤→앞) | 우승 시 황금 글로우 | 핸드 종료까지 유지 |
| Pot 박스 | 스케일 0→1 | 베팅 추가 카운트업 | 우승자 흡수 |
| 액션 표식 | Slide-in | 색상 깜빡임 | Slide-out |
| ALL-IN 박스 | 전화면 스케일 | 펄싱 | 페이드 |
| 우승 화면 | 황금 빛 등장 | 유지 | 페이드 |

---

# Part VI — 무대 구조

<a id="ch27"></a>

## Ch.27 — 9 단 z-layer

### 27.1 9 단 구조

```
  z = 0   [카메라 영상 (배경막)]              <- 가장 뒤
  z = 1   [테이블 boundary 표시]
  z = 2   [Player Card 배경 박스]
  z = 3   [카드 (홀카드 + 커뮤니티)]
  z = 4   [칩 스택 + 베팅 라인]
  z = 5   [팟 박스]
  z = 6   [블라인드 / 레벨 / 시계]
  z = 7   [브랜딩 (로고, 워터마크)]
  z = 8   [액션 표식 / ALL-IN 박스]
  z = 9   [모달 / 우승 화면 / 시스템 알림]    <- 가장 앞
```

### 27.2 왜 9 단인가

| 기준 | 이유 |
|------|------|
| 시각 위계 | 시청자 시선 흐름 (배경 → 콘텐츠 → 알림) |
| 차폐 | 모달 등장 시 그 아래 흐림 |
| 격리 | layer 별로 캐싱 / culling 가능 |

> 9 단은 1 차 가설. 외부 개발팀이 GPU 성능 / 디자이너 워크플로우에 따라 8 단 또는 10 단으로 조정 가능.

### 27.3 차폐의 사례

```
  ALL-IN 발생 시:
  z = 0 ~ 7  -> blur (배경 흐림)
  z = 8      -> ALL-IN 박스 (선명)
  z = 9      -> 시스템 알림 (있다면 더 위)
```

<a id="ch28"></a>

## Ch.28 — Safe Zone 과 시각 위계

### 28.1 3 단 안전 영역

```
  +==========================================================+   <- Frame (1920x1080)
  |                                                          |
  | +======================================================+ |   <- Action Safe (94%)
  | |                                                      | |
  | | +==================================================+ | |   <- Title Safe (90%)
  | | |                                                  | | |
  | | |     [모든 텍스트 + 핵심 그래픽은 여기 안]           | | |
  | | |                                                  | | |
  | | +==================================================+ | |
  | |                                                      | |
  | |     [중요한 그래픽은 여기 안]                          | |
  | |                                                      | |
  | +======================================================+ |
  |                                                          |
  |   [모서리는 잘릴 수 있음 — 장식만 배치]                    |
  +==========================================================+
              ASCII MOCK · 3 단 Safe Zone
```

### 28.2 영역별 정책

| 영역 | 사용 |
|------|------|
| Frame 100% | 카메라 영상, 배경 그라데이션 |
| Action Safe 94% | 보조 그래픽, 워터마크, 작은 로고 |
| Title Safe 90% | 핵심 텍스트, Player Card, Pot, 시계 |

> 94% / 90% 는 방송 안전 영역 업계 표준 (SMPTE / EBU 계열) 을 준용한 1 차 가설. 정확한 표준 ID 는 외부 방송 PD 검증 후 frontmatter `standards:` 항목에 명시.

### 28.3 투명도 위계 (1 차 제안)

| 상태 | 투명도 |
|------|:------:|
| 활성 (To Act) | 100% |
| 일반 표시 | 90% |
| 보조 정보 (배경 박스) | 60% |
| 폴드된 플레이어 | 50% |
| 비활성 (이번 핸드 미참여) | 30% |
| 차폐 시 (ALL-IN 동안) | 20% |

---

# Part VII — 부록

<a id="ch29"></a>

## Ch.29 — 용어 사전

| 용어 | 의미 |
|------|------|
| **Overlay** | 카메라 영상 위에 덧씌우는 그래픽 층 |
| **Rive** | 본 시스템이 사용하는 벡터 그래픽 + 애니메이션 도구 |
| **`.riv` 파일** | Rive Editor 에서 export 한 그래픽 산출물 |
| **Variable Binding** | `.riv` 안의 변수에 외부 데이터를 주입하는 메커니즘 |
| **State Machine** | Rive 의 상태 전이 그래프 |
| **Brand Pack** | 대회별 컬러 / 폰트 / 로고 한 벌 (EBS DB 저장) |
| **PGM** | Program — 시청자가 보는 송출 채널 |
| **OPS** | Operator — 운영자가 보는 채널 (PGM + debug) |
| **BAK** | Backup — PGM 장애 시 대체 채널 |
| **REC** | Recording — 아카이브 채널 |
| **SDI** | Serial Digital Interface — 방송용 디지털 영상 전송 표준 |
| **Z-layer** | 그래픽 깊이 순서 (0=가장 뒤, 9=가장 앞) |
| **Safe Zone** | 화면 모서리 잘림 방지 영역 |
| **Hand Clock** | 한 핸드의 진행 시간 |
| **Level Clock** | 레벨의 남은 시간 |
| **Time Bank** | 큰 결정 시 추가 시간 풀 |
| **ITM** | In The Money — 상금권 진입 |
| **Bubble** | 마지막 1 명 탈락 = 상금권 결정 순간 |
| **Equity** | 끝까지 갔을 때의 승률 |
| **Showdown** | 최종 카드 공개 단계 |
| **Sweep** | 베팅 라인 → 팟 흐름 애니메이션 |

<a id="ch30"></a>

## Ch.30 — FAQ

**Q1. Overlay 가 안 보이면 시청자는 무엇을 보나요?**
A. 카메라 영상만 봅니다. 카드도 액션도 모르는 상태로 화면을 봅니다. 그래서 Overlay 는 선택이 아니라 필수입니다.

**Q2. 디자이너가 Player Card 를 다듬으면 EBS 전체를 다시 빌드해야 하나요?**
A. 아니오. `player_card.riv` 한 파일만 교체하면 됩니다 (경로 A). 또는 Rive Cloud 로 publish 하여 EBS 가 자동 fetch 합니다 (경로 B).

**Q3. Rive 변수에 데이터가 안 들어가면 화면은 어떻게 되나요?**
A. 그 변수가 채워질 때까지 — 디자이너가 정의한 default 값으로 표시됩니다 (예: `player_name = "TBD"`). Default 값을 모든 변수에 정의하는 것이 디자이너의 의무입니다.

**Q4. Mixed Game (게임 종목 회전) 에서 그래픽은 어떻게 바뀌나요?**
A. `game_type` 변수가 바뀌면 — 각 `.riv` 의 State Machine 이 게임별 상태로 이동합니다. 예: Stud 일 때는 community_card 가 hidden, hole_card 가 5 장으로 늘어남.

**Q5. Brand Pack 을 바꾸면 모든 그래픽이 동시에 바뀌나요?**
A. 네. Brand Pack 의 색상 / 폰트 변수는 모든 `.riv` 에 동시 주입됩니다. 디자이너는 `.riv` 안에서 색상 / 폰트를 하드코드하지 않고 변수로 빼야 합니다.

**Q6. 모바일에서도 Overlay 가 보이나요?**
A. 네. 모든 그래픽은 Title Safe 90% 안에 배치되어 16:9 모바일에서도 잘리지 않습니다. 단, OPS 전용 (Ch.22) 은 모바일에 보이지 않습니다.

<a id="ch31"></a>

## Ch.31 — 송출 준비 체크리스트

```
  [ ] 1. Rive 에셋 준비
       [ ] 12 카테고리 .riv 파일 모두 export 완료
       [ ] 변수 명명 규칙 준수 (Ch.5.3)
       [ ] State 명명 규칙 준수 (Ch.24.3)
       [ ] Default 값 모두 정의
       [ ] Safe Zone 90% 안에 핵심 배치
  [ ] 2. EBS DB 준비
       [ ] 대회 정보 입력
       [ ] Brand Pack 업로드 + 변수 매핑
       [ ] 선수 프로필 일괄 import
       [ ] Sponsor 슬롯 / 회전 설정
  [ ] 3. 통합 경로 선택
       [ ] 경로 A (Export-Import) — 빌드에 .riv 번들링
       [ ] 경로 B (Cloud API) — 인증 + override 정책 명시
  [ ] 4. RFID
       [ ] 11 안테나 신호 확인
       [ ] Mock 카드로 카드 인식 검증
  [ ] 5. Command Center
       [ ] 8 액션 키 응답 확인
       [ ] Time Bank trigger 검증
       [ ] HAND END / NEW HAND 흐름 검증
  [ ] 6. Game Engine
       [ ] 게임 종목 룰 검증 (Hold'em / Omaha / Mixed 등)
       [ ] 팟 / 사이드 팟 계산 검증
       [ ] Equity 계산 검증
  [ ] 7. 합류 확인
       [ ] 12 카테고리 모두 5 데이터 소스의 변수 채워짐
       [ ] State Machine 전이 검증
       [ ] Brand Pack 적용 검증
  [ ] 8. 채널 분리
       [ ] PGM / OPS / BAK / REC 분리 확인 (SDI 라우터)
  [ ] 9. 본 송출 시작
```

---

## Changelog

| 날짜 | 버전 | 변경 | 결정 근거 |
|------|------|------|----------|
| 2026-05-07 | v0.3.0 | Reference 톤 정리 — 13 fortune cookie 격언 제거 (Ch.5.4 잉크병 박스 / Ch.7-11 비유 격언 / Ch.12-26 한 마디 섹션). "다섯 작가" 메타포 40 → 6 (Part I Ch.1 도입만 유지). "의상" 31 → 0. "그릇/vessel" 6 → 0. 표 헤더 "다섯 작가 매핑" 14 회 → "데이터 소스 매핑". 챕터 제목 "Variable Binding 의 마법" → "Variable Binding". | 사용자 비평 — 자기 반복적, 문학적 가치 0. 방향 A (Reference 톤) 선택 |
| 2026-05-07 | v0.2.0 | 전면 재설계 — Voldemort 룰 (시간 약속 / human error / 다른 PRD cross-ref 모두 제거). 5 데이터 소스 중심 재구조. Rive Editor ↔ EBS 통합 2 경로. Variable Binding 메커니즘. SUPERSEDED by v0.3.0 | — |
| 2026-05-07 | v0.1.0 | 최초 작성 (SUPERSEDED) | — |

---

## 작성 메모

> 본 문서는 reference manual 입니다. 5 데이터 소스 (Rive Asset / EBS DB / Command Center / RFID / Game Engine) 가 12 카테고리 그래픽 요소의 변수를 어떻게 채우는지를 표 + ASCII mockup 으로 명세합니다. 외부 인계 시 contract 문서로 사용 가능합니다.
>
> 이미지가 필요한 영역은 모두 ASCII mockup + `<!-- IMG_TODO: ... -->` 마커로 표시. 사용자 / 외부 디자이너가 후처리.
