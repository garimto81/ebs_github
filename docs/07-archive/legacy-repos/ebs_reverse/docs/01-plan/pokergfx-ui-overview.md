# EBS Server UI 설계 개요

> **Version**: 1.1.0
> **Date**: 2026-02-19
> **문서 유형**: UI 설계 개요
> **관련 문서**: [EBS PRD v26.0.0](pokergfx-prd-v2.md)
> **원본**: PRD-0004-EBS-Server-UI-Design.md v16.0.0

---

## 목차

1. [네비게이션 맵](#1-네비게이션-맵)
2. [설계 기초](#2-설계-기초)
3. [화면 역할 한눈에 보기](#3-화면-역할-한눈에-보기)
4. [UI 요소 전체 집계](#4-ui-요소-전체-집계)
5. [Feature Mapping](#5-feature-mapping)
6. [전역 단축키](#6-전역-단축키)
7. [화면별 상세 설계](#7-화면별-상세-설계)

---

## 1. 네비게이션 맵

포커 방송 한 프레임이 만들어지는 **데이터 파이프라인**을 따라가면, EBS의 모든 화면이 왜 존재하는지 드러난다. 빈 캔버스에서 시작하여 8단계를 거치면 완성된 네비게이션 맵에 도달한다.

### 1.1 8단계 데이터 파이프라인 기반 화면 구조

#### Step 1 — Main Window (중앙 통제실)

모든 것은 Main Window에서 시작한다. 운영자가 시스템 전체를 한눈에 모니터링하고, 5개 설정 영역으로 분기하는 허브다. 본방송 중에는 긴급 조작을 수행하고, 준비 단계에서는 각 탭으로 이동한다.

```
  +------------------------------+
  |   Main Window (중앙 통제실)   |
  +------------------------------+
```

#### Step 2 — Rules (게임의 문법)

같은 포커라도 게임마다 규칙이 다르다. Bomb Pot이 있는 게임에서는 프리플롭 베팅이 없고, Straddle이 허용되면 블라인드 구조가 달라진다. 규칙이 달라지면 그래픽도 달라지므로, 운영자는 Rules(Ctrl+4)에서 게임 규칙을 먼저 정의해야 한다.

```
  +------------------------------+
  |        Main Window           |
  +----------+-------------------+
             |  Ctrl+4
             v
          +-------+
          | Rules |
          +-------+
          (게임 규칙)
```

#### Step 3 — System (하드웨어 연결 확인)

RFID가 카드를 읽으려면 리더가 연결되고 캘리브레이션이 완료되어야 한다. System(Ctrl+5)에서 RFID 리더 상태, 네트워크 연결, 테이블 디바이스를 점검한다.

```
  +------------------------------+
  |        Main Window           |
  +----------+----------+--------+
             |          |
          Ctrl+4      Ctrl+5
             v          v
          +-------+  +--------+
          | Rules |  | System |
          +-------+  +--------+
                     (RFID + 연결 점검)
```

#### Step 4 — Action Tracker (게임 진행 실시간 입력)

규칙이 정의되고 하드웨어가 준비되면 본방송이 시작된다. 본방송 주의력의 85%가 여기에 집중된다. Action Tracker(F8)가 별도 앱인 이유는 터치에 최적화된 인터페이스가 필요하고, 실수로 Main Window 설정을 건드리는 것을 방지해야 하기 때문이다.

```
  +---------------------------------------------+
  |                Main Window                   |
  +----------+-----------+----------+------------+
             |           |          |
          Ctrl+4       Ctrl+5      F8
             v           v          v
          +-------+  +--------+  +-----------------+
          | Rules |  | System |  | Action Tracker  |
          +-------+  +--------+  | (별도 앱, 터치)  |
                                 +-----------------+
```

#### Step 5 — GFX (규칙 + 입력 → 그래픽 생성)

규칙이 정의되고 데이터가 입력되면, 이를 시각적으로 표현해야 한다. GFX(Ctrl+3)는 가장 복잡한 영역이라 4개 서브탭으로 분리된다.

```
  +------------------------------------------------------------+
  |                       Main Window                          |
  +----------+-----------+----------+----------+--------------+
             |           |          |          |
          Ctrl+4       Ctrl+5      F8        Ctrl+3
             v           v          v          v
          +-------+  +--------+  +----+    +-----+
          | Rules |  | System |  | AT |    | GFX |
          +-------+  +--------+  +----+    +--+--+
                                               |
                    +----------+----------+----+----+
                    v          v          v         v
                +------+  +------+  +-------+  +-------+
                |Layout|  |Visual|  |Display|  |Numbers|
                +------+  +------+  +-------+  +-------+
                (어디에) (어떤 연출) (무엇을)  (어떤 형식)
```

#### Step 6 — Outputs (출력 파이프라인)

생성된 그래픽을 내보내야 한다. Fill & Key 채널 매핑, 녹화, 스트리밍 설정도 이 탭에서 관리한다. Outputs(Ctrl+2)에서 Live 단일 출력 파이프라인을 구성한다. (Delay 이중 출력은 추후 개발)

```
  +-----------------------------------------------------------------+
  |                         Main Window                             |
  +--------+---------+-----------+----------+----------+-----------+
           |         |           |          |          |
         Ctrl+2    Ctrl+3      Ctrl+4     Ctrl+5      F8
           v         v           v          v          v
        +------+  +----+------+ +-------+  +------+  +----+
        |Output|  |GFX |      | | Rules |  |System|  | AT |
        +------+  |    +------+ +-------+  +------+  +----+
                  |Layout/Visual|
                  |Display/Number|
                  +--------------+
```

#### Step 7 — Sources (카메라/스위처 연결)

그래픽만으로는 방송이 완성되지 않는다. 카메라 영상과 합성되어야 한다. Sources(Ctrl+1)는 물리적 연결을 담당한다.

#### Step 8 — Skin Editor / Graphic Editor (에필로그)

스킨은 방송 전날 또는 며칠 전에 미리 만들어두는 사전 작업이므로 탭이 아니라 Skin Editor(별도 창)로 분리된다. Graphic Editor는 Skin Editor에서 개별 요소를 클릭하면 열리는 하위 작업 창이다.

### 1.2 최종 네비게이션 맵 (8단계 완성)

```
  +-------------------------------------------------------------------------+
  |                            Main Window                                   |
  |                          (중앙 통제실)                                    |
  +----+--------+--------+--------+--------+--------+-----+------------------+
       |        |        |        |        |        |     |
     Ctrl+1   Ctrl+2   Ctrl+3   Ctrl+4   Ctrl+5   Skin   F8
       |        |        |        |        |        |     |
       v        v        v        v        v        v     v
   +------+  +------+  +-----+  +------+  +------+  +------+  +------+
   |Source|  |Output|  | GFX |  |Rules |  |System|  | Skin |  |  AT  |
   |  s   |  |  s   |  |     |  |      |  |      |  |Editor|  |      |
   |(카메라 +  |(출력  +  +--+--+  |(게임  +  |(RFID +  |(별도  +  |(별도  |
   | 스위처)|  | 파이프)|  |  |  |  | 규칙)|  | 연결)|  |  창) |  | 앱)  |
   +------+  +------+  |  |  |  +------+  +------+  +--+---+  +------+
                        |  |  |                          |
             +----------+  +--+---------+             요소 클릭
             |              |           |                 |
             v              v           v                 v
          +------+      +-------+  +-------+        +--------+
          |Layout|      |Display|  |Numbers|        |Graphic |
          +------+      +-------+  +-------+        | Editor |
          |Visual|                                  |(별도 창)|
          +------+                                  +--------+

  System 탭 내부:
  System --> Y-09 --> [Table Diagnostics (별도 창)]
```

8단계를 거쳐 완성된 이 맵이 EBS의 전체 네비게이션 구조다. 운영자의 하루는 이 맵의 바깥(Skin Editor)에서 시작하여, 안쪽(5개 탭 설정)을 거쳐, Action Tracker에서 끝난다.

---

## 2. 설계 기초

### 2.1 방송 워크스테이션

GFX 운영자는 하나의 워크스테이션에서 GfxServer를 중심으로 작업한다:

- **메인 모니터** (GfxServer): 시스템 설정과 모니터링. 마우스/키보드 조작. 주 장치
- **터치스크린/키보드** (Action Tracker): 실시간 게임 진행 입력. 터치 또는 키보드 입력 모두 지원

준비 단계에서 GfxServer로 시스템을 구성하고, 본방송에서는 Action Tracker가 주 인터페이스로 전환된다. GfxServer는 모니터링 역할로 전환된다.

### 2.2 3단계 시간 모델

방송 시스템 사용은 3개의 시간 단계로 나뉜다.

| 단계 | 시간 | 주 화면 | 조작 방식 | 긴장도 |
|------|------|---------|----------|--------|
| **준비** (Setup) | 30~60분 | GfxServer | 마우스/키보드 | 낮음 |
| **본방송** (Live) | 수 시간 | Action Tracker | 터치 | **높음** |
| **후처리** (Post) | 10~30분 | GfxServer | 마우스/키보드 | 낮음 |

본방송 중 GfxServer는 "설정 도구"에서 "모니터링 대시보드"로 역할이 전환된다.

```
  [준비 단계]          [본방송]              [후처리]
  GfxServer            AT (85%)             GfxServer
  설정 구성    --->    GfxServer (15%)  --->  결과 확인
  (30~60분)           (수 시간)             (10~30분)
  긴장도: 낮음         긴장도: 높음          긴장도: 낮음
```

### 2.3 주의력 분배

이 분배가 UI 설계의 핵심 제약 조건이다.

| 장치 | 비중 | 주시 내용 |
|------|:----:|----------|
| **Action Tracker** | 80% | 현재 핸드 진행, 베팅 입력, 특수 상황 |
| **GfxServer** | 15% | RFID 상태, 에러 알림, 프리뷰 |
| **Stream Deck** | 5% | GFX 숨기기, 카메라 전환 (손끝 감각) |

Action Tracker는 주변 시야에서도 상태를 파악할 수 있어야 하고, GfxServer는 문제가 생겼을 때만 주의를 끌어야 한다.

```
  주의력 분배 (본방송 중):

  +---------+-----------------------------------------------+---------+
  |  AT     |///////////  Action Tracker  ///////////////////|Stream   |
  |  80%    |////////////  (터치, 베팅 입력)  ///////////////|  5%     |
  +---------+-----------------------------------------------+---------+
  | GfxServer 15% (모니터링 대시보드)                                   |
  +---------------------------------------------------------------------+
```

### 2.4 자동화 그래디언트

시스템은 가능한 많은 작업을 자동 처리하되, 판단이 필요한 작업만 인간에게 맡긴다.

```
  [완전 자동]           [반자동]              [수동 입력]
  (RFID 처리)          (운영자 확인)          (운영자 직접)
  +-----------+        +-------------+       +-----------+
  | 카드 인식  |        | New Hand 시작|       | 베팅 금액 |
  | 승률 계산  |  --->  | Showdown 선언|  --->| 특수 상황 |
  | 핸드 평가  |        | GFX 표시/숨김|       | Chop/2x  |
  | 오버레이   |        | 카메라 전환  |       | 수동 카드 |
  | 렌더링    |        |              |       | 스택 조정 |
  +-----------+        +--------------+       +-----------+
```

> **반자동이란**: 시스템이 데이터를 자동으로 준비하지만, 최종 실행에는 운영자의 확인(클릭/터치)이 필요한 단계.

### 2.5 해상도 적응 원칙

EBS Server UI는 다양한 모니터 환경(SD~4K)과 다양한 출력 해상도(480p~4K)를 지원한다.

| 개념 | 정의 | 설정 위치 |
|------|------|----------|
| Design Resolution | Graphic Editor에서 좌표를 입력하는 기준 해상도 (SK-04 설정에 따라 1920×1080 또는 3840×2160) | Skin Editor SK-04 |
| Output Resolution | 실제 방송 송출 해상도 (O-01에서 설정) | Outputs 탭 O-01 |
| Preview Scaling | UI 내 Preview Panel이 출력 해상도 비율을 유지하며 표시되는 방식 | Main Window M-02 |

**앱 윈도우 크기 정책**
- 최소 앱 윈도우: 1280×720 (이하에서는 스크롤 발생)
- Preview(좌) : Control(우) 기본 비율 = 6:4
- Graphic Editor의 모든 위치/크기 값(LTWH)은 Design Resolution 기준 픽셀 단위
- GFX 마진(G-03~G-05)은 정규화 좌표(0.0~1.0) 사용

### 2.6 설계 원칙

| 원칙 | UI 반영 |
|------|---------|
| 운영자 중심 설계 (라이브 중 인지 부하 최소화) | Quick Actions, Lock Toggle, 단축키 |
| 검증된 레이아웃 계승 (PokerGFX 2-column 유지) | Preview(좌) + Control(우) |
| 논리적 기능 통합 (GFX 1/2/3 재편) | Layout/Visual/Display/Numbers 4개 서브탭 |

> **벤치마크 메모**: PokerGFX의 Dual Canvas(Venue/Broadcast 이중 출력), Trustless Mode, Security Delay는 홀카드 보안을 위한 기능이나 EBS v1에서는 구현 범위에서 제외된다.

### 2.7 공통 레이아웃

모든 탭이 공유하는 구조:

```
  +-------------------------------------------------------------------+
  |  Title Bar  [앱명 + 버전]                          [_][□][X]      |
  +----------------------------------+--------------------------------+
  |                                  |  CPU [===] GPU [===]           |
  |                                  |  RFID [●]  Error [●]  Lock [●] |
  |   Preview Panel                  |  [Preview]                      |
  |   (16:9 Chroma Key Blue)         |                                 |
  |   GFX 오버레이 실시간 렌더링       |  [Reset Hand]                  |
  |                                  |  [Register Deck]                |
  |                                  |  [Launch AT]                    |
  |                                  |  [Split Recording]              |
  |                                  |  [Tag Player ▼]                |
  +----------------------------------+--------------------------------+
  | [Sources] [Outputs] [GFX] [Rules] [System]                        |
  +-------------------------------------------------------------------+
  |                    Tab Content Area                                |
  |                                                                    |
  +-------------------------------------------------------------------+
```

---

## 3. 화면 역할 한눈에 보기

9개 화면의 역할과 주 사용 시점을 정리한다.

| 화면 | 역할 | 주 사용 시점 | 주의력 비중 |
|------|------|-------------|:----------:|
| **Main Window** | 시스템 모니터링 + 긴급 조작 | 항상 | 15% |
| **Sources 탭** | 비디오/오디오 입력 장치 설정 | 준비 단계 | - |
| **Outputs 탭** | 출력 파이프라인 (해상도, 장치, 녹화, 스트리밍) | 준비 단계 | - |
| **GFX 탭** | 그래픽 레이아웃/연출/표시/수치 | 준비 단계 + 핸드 간 조정 | - |
| **Rules 탭** | 게임 규칙 (Bomb Pot, Straddle 등) | 준비 단계 | - |
| **System 탭** | RFID, AT 연결, 시스템 진단 | 준비 단계 + 비상 대응 | - |
| **Skin Editor** | 방송 그래픽 테마 편집 | 사전 준비 (별도 창) | - |
| **Graphic Editor** | 개별 요소 픽셀 단위 편집 | 사전 준비 (Skin Editor 하위) | - |
| **Action Tracker** | **실시간 게임 진행 입력** | **본방송** | **85%** |

```
  시간 흐름 기준 화면 사용 순서:

  [사전 준비]       [준비 단계]            [본방송]         [후처리]
  Skin Editor  --> System              --> Action Tracker --> Main Window
  Graphic Editor   Rules                  Main Window        (모니터링)
                   Sources
                   Outputs
                   GFX
```

### 3.1 GFX 탭 4개 서브탭 구조

PokerGFX의 GFX 1/2/3 탭 3개가 EBS에서 논리적 기준으로 4개 서브탭으로 재편된다:

```
  PokerGFX         EBS
  +---------+      +---------+
  | GFX 1  |  --> | Layout  | (어디에 배치: Board Position, Player Layout 등)
  | GFX 2  |  --> | Visual  | (어떤 연출로: Skin, 애니메이션, 스폰서 등)
  | GFX 3  |  --> | Display | (무엇을 표시: Equity, Leaderboard, Outs 등)
  +---------+  --> | Numbers | (어떤 형식으로: 통화, 정밀도, Strip 등)
               +-----------+
```

---

## 4. UI 요소 전체 집계

**PokerGFX Server 3.111**: 11개 화면, 268개 UI 요소
**EBS Server**: 11개 화면(섹션), **184개 UI 요소**

### 4.1 우선순위 정의

| 우선순위 | 정의 | 기준 |
|:--------:|------|------|
| **P0** | 필수 | 없으면 방송이 불가능한 핵심 기능. MVP에 반드시 포함 |
| **P1** | 중요 | 방송은 가능하나 운영 효율/품질에 영향. 초기 배포 후 순차 추가 |
| **P2** | 부가 | 확장성, 편의성, 고급 기능. 시스템 안정화 후 추가 |
| **Future** | 추후 개발 | Delay 파이프라인 등 Phase 2 이후 |

### 4.2 화면별 P0/P1/P2 분포

```
  화면                  요소수   P0   P1   P2
  +-----------------------+----+----+----+----+
  | Main Window          |  20 | 11 |  7 |  2 |
  | Sources 탭           |  19 |  6 | 13 |  0 |
  | Outputs 탭           |  20 |  8 |  4 |  8 |
  | GFX - Layout         |  13 |  2 |  8 |  3 |
  | GFX - Visual         |  12 |  4 |  8 |  0 |
  | GFX - Display        |  14 |  2 | 12 |  0 |
  | GFX - Numbers        |  12 |  5 |  7 |  0 |
  | Rules 탭             |   6 |  0 |  6 |  0 |
  | System 탭            |  24 |  7 | 11 |  6 |
  | Skin Editor          |  26 |  0 | 21 |  5 |
  | Graphic Editor       |  18 |  6 | 11 |  1 |
  +-----------------------+----+----+----+----+
  | 합계                  | 184 | 51 |108 | 25 |
  +-----------------------+----+----+----+----+
```

### 4.3 P0 핵심 요소 요약

MVP에 반드시 포함되어야 하는 51개 P0 요소의 화면별 핵심:

| 화면 | P0 핵심 요소 |
|------|------------|
| Main Window | Preview Panel(M-02), RFID Status(M-05), Reset Hand(M-11), Register Deck(M-13), Launch AT(M-14), Hand Counter(M-17), Connection Status(M-18) 등 11개 |
| Sources | Output Mode(S-00), Device Table(S-01), Chroma Key(S-11~S-12), ATEM Control(S-13~S-14) 등 6개 |
| Outputs | Video Size(O-01), Frame Rate(O-03), Live Pipeline(O-04~O-05), Key Color(O-18), DeckLink Map(O-20) 등 8개 |
| GFX - Visual | Skin Selector(V-01~V-04) 등 4개 |
| GFX - Numbers | Currency(N-01~N-02), Chipcount Precision(N-03~N-07) 등 5개 |
| System | RFID Readers(Y-03~Y-07), AT Access(Y-01~Y-02) 등 7개 |
| Graphic Editor | Transform LTWH, Z-order, Anchor, Coord Display 등 6개 |

---

## 5. Feature Mapping

PokerGFX-Feature-Checklist.md의 149개 기능이 EBS 요소에 대응하는 전체 매핑.

**전체 커버리지: 147/149 (98.7%)**

### 5.1 배제 기능 (2개)

| Feature ID | 기능 | 배제 사유 |
|:----------:|------|----------|
| SV-021 | Commentary 탭 (C-01~C-03) | 기존 포커 방송 프로덕션에서 Commentary 탭 미사용. EBS Phase 1 복제 제외 |
| SV-022 | Commentary PIP (C-07) | 동일 사유 |

### 5.2 GFX ID 크로스 레퍼런스

| PRD-0004 ID | Original PokerGFX ID | 기능 |
|:-----------:|:-------------------:|------|
| G-01 | G1-006 | Board Position |
| G-02 | G1-001 | Player Layout (10-seat) |
| G-14 | G1-004 | Reveal Players |
| G-16 | G1-022 | Transition In/Out |
| G-22 | G2-006 | Leaderboard |
| G-24 | G2-001~005 | Player Stats (VPIP/PFR) |
| G-37 | G1-008 | Hand Equities |
| G-40~G-42 | G1-009 | Outs Display |
| G-45 | G1-012 | Show Blinds |
| G-50 | G3-014 | Chipcount Precision |

### 5.3 카테고리별 Feature Mapping

#### Action Tracker (AT-001~AT-026, 26개)

AT는 별도 앱. GfxServer 상호작용 지점만 매핑한다.

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| AT-001 | M-18 Connection Status (Main Window) |
| AT-002 | Y-01, Y-02 (System) |
| AT-003~004 | O-15, O-16 (Outputs), M-15 (Main) |
| AT-005~006 | Game Engine, G-45 (GFX) |
| AT-007 | M-17 (Main), G-46 (GFX) |
| AT-008~010 | G-02, G-15, G-19, G-20 (GFX) |
| AT-011 | Player Overlay H (Graphic Editor) |
| AT-012~017 | Server GameState / AT 자체 UI |
| AT-018 | R-02 (Rules) |
| AT-019~020 | RFID 자동 / AT 수동 |
| AT-021~026 | Display Domain, Hand History, Server, M-11 (Main) |

#### Pre-Start Setup (PS-001~PS-013, 13개)

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| PS-001 | G-13 (GFX Layout) |
| PS-002 | Game Engine (내부) |
| PS-003 | G-50 (GFX Numbers) |
| PS-004~006 | Player Overlay C, G, H (Graphic Editor) |
| PS-007 | M-05 (Main), Y-03~Y-07 (System) |
| PS-008~009 | G-45 (GFX), R-04 (Rules) |
| PS-010 | G-02 (GFX Layout) |
| PS-011~013 | Outputs Dual Board, M-14 (Main), RFID 자동 |

#### Viewer Overlay (VO-001~VO-014, 14개)

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| VO-001, VO-004 | G-10~G-12 Sponsor Logo (GFX) |
| VO-002, VO-003, VO-010 | G-45, G-50 (GFX Numbers) |
| VO-005 | G-14, G-16 (GFX Visual) |
| VO-006 | Player Overlay C, G (Graphic Editor) |
| VO-007~008 | G-35, G-37 (GFX Display) |
| VO-009, VO-011 | G-01, G-13 (GFX Layout) |
| VO-012 | Game State Machine |
| VO-013~014 | G-19, G-20, G-15 (GFX Visual) |

#### GFX Console (GC-001~GC-025, 25개)

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| GC-001~008 | G-24 Show Player Stats (GFX) |
| GC-009~010, GC-013~016 | G-22 Leaderboard (GFX) |
| GC-011~012 | G-36, G-28 (GFX Display) |
| GC-017 | Display Domain 제어 |
| GC-018~020 | Y-12 (System), M-11 (Main) |
| GC-021 | G-43 Score Strip (GFX) |
| GC-022~025 | M-03, M-04, M-02, M-12 (Main), SK-10 (Skin Editor) |

#### Security (SEC-001~SEC-011, 11개)

SEC-001~005, SEC-010~011 (Dual Canvas / Security Delay / Trustless Mode 관련)은 EBS v1 구현 범위에서 제외된다.

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| SEC-001~005, SEC-010~011 | EBS v1 제외 (Dual Canvas / Security Delay 전제 기능) |
| SEC-006~008 | System RFID / 설정 영속화 |
| SEC-009 | M-18 Connection Status (Main) |

#### Equity & Stats (EQ-001~EQ-012, ST-001~ST-007, 19개)

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| EQ-001~005, EQ-008 | G-37 Show Hand Equities (GFX Display) |
| EQ-006~007 | G-40~G-42 Outs (GFX Numbers) |
| EQ-009~011 | Phase 2 / Game Engine |
| EQ-012 | G-38 Hilite Winning Hand (GFX Display) |
| ST-001~007 | G-24 Show Player Stats (GFX Display) |

#### Hand History (HH-001~HH-011, 11개)

| Feature ID | PRD 연결 지점 |
|:----------:|---------------|
| HH-001~006 | Hand History DB (hands.db) |
| HH-007~008 | M-02 Preview 확장, 별도 다이얼로그 |
| HH-009~011 | Y-12 Export (System), P2 기능 |

#### Server 관리 (SV-001~SV-030, 30개)

| 그룹 | Feature ID | PRD 요소 |
|------|:----------:|----------|
| Sources | SV-001~005 | S-01, S-06, S-11~S-16 |
| Outputs | SV-006~011 | O-01~O-17 |
| GFX | SV-012~020 | G-01, G-02, G-10~G-12, G-17~G-21, G-47~G-51 |
| **배제** | SV-021~022 | ~~Commentary~~ |
| System | SV-023~026 | M-13, Y-04, Y-16, Y-23 |
| Editor | SV-027~029 | SK-01~SK-26, Graphic Editor |
| Main | SV-030 | M-15 Split Recording |

---

## 6. 전역 단축키

EBS Server의 키보드 단축키 12개. 본방송 중 마우스 이동 없이 즉시 조작 가능하도록 설계.

| 단축키 | 동작 | 맥락 |
|--------|------|------|
| `F5` | Reset Hand | 메인 |
| `F7` | Register Deck | 메인 |
| `F8` | Launch AT | 메인 |
| `F11` | Preview 전체 화면 | 메인 |
| `Ctrl+L` | Lock 토글 | 전역 |
| `Ctrl+1` | Sources 탭 | 전역 |
| `Ctrl+2` | Outputs 탭 | 전역 |
| `Ctrl+3` | GFX 탭 | 전역 |
| `Ctrl+4` | Rules 탭 | 전역 |
| `Ctrl+5` | System 탭 | 전역 |
| `Ctrl+S` | 설정 저장 | 전역 |

```
  탭 전환 단축키:

  [Ctrl+1]  [Ctrl+2]  [Ctrl+3]  [Ctrl+4]  [Ctrl+5]
  Sources   Outputs      GFX      Rules     System

  긴급 조작:
  [F5] Reset    [F7] Deck    [F8] AT    [Ctrl+L] Lock
```

---

## 7. 화면별 상세 설계

각 화면의 요소 카탈로그, Interaction Patterns, Design Decisions는 별도 문서를 참조한다.

→ [pokergfx-ui-screens.md](pokergfx-ui-screens.md)

해당 문서는 다음 내용을 포함한다:
- Main Window (M-01~M-20)
- Sources 탭 (S-00~S-18)
- Outputs 탭 (O-01~O-20)
- GFX - Layout / Visual / Display / Numbers (G-01~G-51)
- Rules 탭 (R-01~R-06)
- System 탭 (Y-01~Y-24)
- Skin Editor (SK-01~SK-26)
- Graphic Editor (GE-01~GE-18)

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [pokergfx-prd-v2.md](pokergfx-prd-v2.md) | EBS PRD v26.0.0 (WHAT/WHY — 시스템 아키텍처, 운영 워크플로우) |
| [pokergfx-ui-screens.md](pokergfx-ui-screens.md) | 화면별 상세 UI 요소 카탈로그 (HOW) |
| [pokergfx-ui-design.md](../archive/pokergfx-ui-design.md) | EBS 인터페이스 설계서 v1.0.0 (아카이브) |
| [pokergfx-glossary.md](pokergfx-glossary.md) | 용어 사전 |

---

**Version**: 1.1.0 | **Date**: 2026-02-19 | **원본**: PRD-0004-EBS-Server-UI-Design.md v16.0.0

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| v1.0.0 | 2026-02-19 | 최초 작성. PRD-0004 v16.0.0 기반 이관 |
| v1.1.0 | 2026-02-19 | Dual Canvas / Trustless Mode / Security Delay 관련 내용 제거 (EBS v1 구현 범위 제외). 설계 원칙에 벤치마크 메모 추가. Ctrl+D 단축키 제거. SEC Feature Mapping 축소. |
