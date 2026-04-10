# EBS 오버레이 매핑 시스템 — 고수준 재설계 제안

> **문서 유형**: 설계 제안 (Design Proposal)
> **작성일**: 2026-02-19
> **참조**: pokergfx.design.md v4.0.0, pokergfx-prd-v2.md v28.0.0
> **상태**: 리뷰 대기 중

---

## 1. 현황 진단

### 1.1 현재 시스템의 근본 문제

설계 문서(`pokergfx.design.md`) 7개 오버레이 영역 분석 결과:

| # | 문제 영역 | 심각도 | 세부 내용 |
|---|-----------|--------|-----------|
| 1 | **VTO 데이터 구조 완전 미정의** | CRITICAL | `PLAYER_INFO_VTO` 명령어는 있으나 VTO 필드 구조 전무 |
| 2 | **Player Panel 배치 알고리즘 없음** | CRITICAL | 10개 좌석 X/Y 좌표 20개 필드가 하드코딩으로만 존재 |
| 3 | **포지셔닝 좌표 단위·앵커 미정의** | HIGH | `float x, y` 픽셀 절대값, 해상도 변경 시 전부 붕괴 |
| 4 | **Graphic Editor 인터랙션 구현 없음** | HIGH | GEB-001~015, GEP-001~015 ID 범위만 예약됨 |
| 5 | **게임 이벤트→애니메이션 트리거 매핑 없음** | MEDIUM | AnimationState 16개 있으나 트리거 조건 전무 |
| 6 | **스킨 런타임 교체 절차 미정의** | MEDIUM | SKIN 청크 전송 명령만 있고 핫스왑 절차 없음 |
| 7 | **반응형·해상도 독립 처리 없음** | HIGH | 1920×1080 고정, 4K 전환 알고리즘 미정의 |

**결론**: 현행 mockup HTML(하드코딩 픽셀 좌표)과 실제 렌더러(`image_element.x/y float`)가 동일한 수준이다. 이는 방송 시스템이 아닌 프로토타입 수준이다.

### 1.2 업계 표준과의 격차

업계 5개 시스템 비교 분석 결과:

```
  현재 EBS 수준               업계 표준 (CasparCG / OBS / Chyron PRIME)
  ──────────────────────────   ────────────────────────────────────────
  픽셀 절대값 float x,y  ────▶  viewport % / 9-point Anchor (해상도 독립)
  원시 요소 List<>       ────▶  시맨틱 컴포넌트 트리 (PlayerPanel 등)
  좌석 좌표 20개 하드코딩 ───▶  Adaptive Layout 엔진 (2~10명 자동 배치)
  VTO 구조 미정의        ────▶  JSON Schema 선언 + WebSocket 실시간 바인딩
  이벤트→애니 미매핑     ────▶  이벤트 버스 + 트리거 선언 테이블
  바이너리 스킨 블랙박스  ────▶  JSON-first 스킨 스키마 (CSS 커스터마이징)
```

---

## 2. 재설계 아키텍처

### 2.1 핵심 원칙: 4계층 분리

```
  ┌────────────────────────────────────────────────────────┐
  │  Layer 4: PRESENTATION LAYER                           │
  │  Skin Template (.vpt) — 선언적 컴포넌트 트리 JSON     │
  │  "PlayerPanel", "BoardArea", "TopBar" 등 의미 단위     │
  ├────────────────────────────────────────────────────────┤
  │  Layer 3: LAYOUT ENGINE                                │
  │  Anchor-Based Positioning (9-point + 정규화 float)     │
  │  Player Count Layout Manager (2~10명 Adaptive)         │
  ├────────────────────────────────────────────────────────┤
  │  Layer 2: DATA BINDING LAYER                           │
  │  VTO JSON Schema → ComponentState 매핑 파이프라인      │
  │  이벤트 버스 → 애니메이션 트리거 선언 테이블           │
  ├────────────────────────────────────────────────────────┤
  │  Layer 1: RENDER LAYER (현행 유지)                     │
  │  DirectX 12 Canvas — image_element / text_element      │
  │  mixer (5-Thread), Dual Canvas (Live / Delayed)        │
  └────────────────────────────────────────────────────────┘
```

Layer 1(렌더러)는 현행 DirectX 12 구현을 유지하고, Layer 2~4를 신규 설계한다.

---

## 3. 제안 세부 설계

### 제안 1: Semantic Component Model

현행 `List<image_element>` 원시 구조 대신 의미론적 컴포넌트 트리 도입:

```
  OverlayScene
  ├── TopBar                          [항상 표시]
  │   ├── EventBadge                  (이벤트명, 블라인드, 핸드 번호)
  │   ├── SponsorLogo                 (이미지)
  │   └── ClockDisplay                (레벨 타이머)
  ├── BoardArea                       [항상 표시]
  │   ├── CommunityCards[0..4]        (최대 5장, 순차 공개)
  │   └── PotDisplay                  (팟 금액, 사이드팟)
  ├── PlayerPanel[N]                  [N = 2..10, 동적]
  │   ├── NamePlate                   (이름, 국기, 좌석번호)
  │   ├── StackDisplay                (칩 카운트)
  │   ├── HoleCards[2]                (Dual Canvas 가시성 규칙 내장)
  │   ├── EquityBar                   (승률 % + 바 fill)
  │   ├── ActionBadge                 (CHECK/RAISE/FOLD/BET/ALL-IN)
  │   ├── DealerButton                (딜러/SB/BB 버튼)
  │   └── HandRankDisplay             (핸드 랭크: "Two Pair" 등)
  └── BottomStrip                     [항상 표시]
      ├── PotCounter                  (메인 팟 카운터)
      └── FieldDisplay                (스테이지, 레벨, 날짜)
```

**구현 방식**:
- 각 컴포넌트는 `ComponentDef` JSON 레코드로 선언
- 렌더러는 `ComponentDef` 트리를 `image_element / text_element` 리스트로 flatten
- 스킨 파일은 컴포넌트 트리 전체를 직렬화

---

### 제안 2: Anchor-Based Positioning System

현행 `float x, y` (픽셀 절대값) → **9-Point Anchor + 정규화 좌표** 전환:

```
  앵커 포인트 9개 (AnchorPoint enum):
  ┌────────────┬─────────────┬─────────────┐
  │  TopLeft   │  TopCenter  │  TopRight   │
  ├────────────┼─────────────┼─────────────┤
  │  MidLeft   │   Center    │  MidRight   │
  ├────────────┼─────────────┼─────────────┤
  │  BotLeft   │  BotCenter  │  BotRight   │
  └────────────┴─────────────┴─────────────┘
```

**좌표 단위: 정규화 float (0.0 ~ 1.0)**

```
  ComponentDef {
    anchor: AnchorPoint          // 기준점
    x: float (0.0~1.0)           // 정규화 X 오프셋
    y: float (0.0~1.0)           // 정규화 Y 오프셋
    width: float (0.0~1.0)       // 정규화 너비
    height: float (0.0~1.0)      // 정규화 높이
  }

  런타임 픽셀 변환:
  pixel_x = anchor_x(RenderConfig.width) + x * RenderConfig.width
  pixel_y = anchor_y(RenderConfig.height) + y * RenderConfig.height

  예시:
  EquityBar → anchor=BotLeft, x=0.02, y=0.88, width=0.96, height=0.04
    1920×1080 → (38px, 950px, 1843px, 43px)
    3840×2160 → (77px, 1901px, 3686px, 86px)  ← 자동 스케일
```

**기존 `image_element.x, y` 필드 변경사항**:
- `x, y`: 픽셀 → 정규화 float (하위호환: 1920×1080 기준값 ÷ 1920)
- 신규 필드 추가: `anchor: AnchorPoint enum`
- 기존 바이너리 스킨 마이그레이션: 픽셀값 ÷ 해상도로 자동 변환

---

### 제안 3: VTO 데이터 바인딩 파이프라인

현재 완전 미정의인 VTO를 다음과 같이 정의:

**VTO JSON Schema (플레이어 단위)**:

```json
{
  "vto_version": "1.0",
  "player_id": 3,
  "seat_index": 2,
  "name": "Daniel Negreanu",
  "country_code": "CA",
  "stack": 212300,
  "hole_cards": ["As", "Kh"],
  "hole_cards_revealed": true,
  "equity": 0.68,
  "action": "RAISE",
  "action_amount": 5000,
  "is_dealer": false,
  "is_small_blind": false,
  "is_big_blind": false,
  "is_active": true,
  "is_folded": false,
  "hand_rank": "Top Two Pair",
  "canvas_visibility": {
    "live_canvas": false,
    "delayed_canvas": true,
    "delay_seconds": 120
  }
}
```

**VTO → ComponentState 매핑 파이프라인**:

```
  서버 (게임 로직)
       │ PLAYER_INFO_VTO 명령어
       ▼
  ┌─────────────────────────────────────────┐
  │  VTO Deserializer                       │
  │  (JSON/Binary → VTO Record)             │
  └────────────────┬────────────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────────────┐
  │  VTO Mapper                             │
  │  vto.name          → NamePlate.text     │
  │  vto.stack         → StackDisplay.value │
  │  vto.hole_cards    → HoleCards.cards    │
  │  vto.equity        → EquityBar.fill_pct │
  │  vto.action        → ActionBadge.text   │
  │  vto.is_folded     → PlayerPanel.folded │
  │  vto.canvas_visibility.live_canvas      │
  │              → HoleCards.live_visible   │
  └────────────────┬────────────────────────┘
                   │
                   ▼
  ComponentState → Flatten → image_element/text_element List
                   │
                   ▼
  DirectX 12 Canvas (현행 렌더러)
```

**GameInfo VTO (보드 단위)**:

```json
{
  "vto_version": "1.0",
  "community_cards": ["Kh", "9s", "4d", null, null],
  "pot_total": 45000,
  "side_pots": [],
  "hand_number": 142,
  "blind_level": { "small": 500, "big": 1000 },
  "event_name": "WSOP Main Event",
  "stage": "Day 3",
  "dealer_seat": 5
}
```

---

### 제안 4: Player Count Layout Manager

현행 좌석 좌표 20개 하드코딩 → **레이아웃 프리셋 + Adaptive 알고리즘**:

```
  LayoutPreset 종류:
  ┌──────────────┬──────────────────────────────────────────────┐
  │ HU_2P        │ Bottom-Center + Top-Center (헤즈업)           │
  │ 3P_TRIANGLE  │ Bottom + Left-Top + Right-Top                │
  │ 4P_SQUARE    │ Bottom-L + Bottom-R + Top-L + Top-R          │
  │ 5P           │ Bottom-C + Left-B + Left-T + Right-T + Right-B│
  │ 6P_HALF      │ Left col 3 + Right col 3 (숏핸드)            │
  │ 6P_ARC       │하단 호형 배치                                 │
  │ 9P_FULL      │ 타원형 9좌석 배치 (풀링)                      │
  │ 10P_FULL     │ 타원형 10좌석 배치                            │
  │ CUSTOM       │ 스킨 오버라이드 (기존 ConfigurationPreset)    │
  └──────────────┴──────────────────────────────────────────────┘

  PlayerCountLayoutManager 알고리즘:
  1. GameInfo.NumActivePlayers 수신
  2. 현재 스킨의 layout_override 확인
     → override 없으면: NumActivePlayers에 따라 LayoutPreset 자동 선택
  3. LayoutPreset에서 각 seat_index별 정규화 좌표 계산
  4. 폴드 플레이어: opacity=0.3, scale=0.85 (축소 표시)
  5. PLAYER_DELETE 이벤트:
     → 남은 플레이어 재배치 (LayoutPreset 재계산)
     → 선택적: SlideUp/SlideDownRotateBack 애니메이션으로 전환
  6. PLAYER_ADD 이벤트:
     → 레이아웃 재계산 후 FadeIn 애니메이션

  좌석 물리 위치 매핑 (9P_FULL 예시, 정규화 좌표):
  ┌────────────────────────────────────────┐
  │         Seat7  Seat6  Seat5            │
  │     Seat8                Seat4         │
  │                                        │
  │     Seat9                Seat3         │
  │         Seat0  Seat1  Seat2            │
  └────────────────────────────────────────┘
```

---

### 제안 5: 게임 이벤트 → 애니메이션 트리거 선언 테이블

현재 AnimationState 16개가 있으나 트리거 조건 없는 문제를 JSON 파일로 해결:

**`poker_events.json` (animation trigger table)**:

```json
{
  "triggers": [
    {
      "event": "RFID_CARD_COMPLETE",
      "condition": "player.hole_cards.length == 2",
      "target": "PlayerPanel[player_id].HoleCards",
      "animation_class": "PlayerCardAnimation",
      "animation_state": "SlideUp",
      "duration_ms": 300
    },
    {
      "event": "DEAL_FLOP",
      "target": "BoardArea.CommunityCards[0,1,2]",
      "animation_class": "BoardCardAnimation",
      "animation_state": "FadeIn",
      "duration_ms": 400,
      "sequence_delay_ms": 150
    },
    {
      "event": "DEAL_TURN",
      "target": "BoardArea.CommunityCards[3]",
      "animation_class": "BoardCardAnimation",
      "animation_state": "FadeIn",
      "duration_ms": 300
    },
    {
      "event": "DEAL_RIVER",
      "target": "BoardArea.CommunityCards[4]",
      "animation_class": "BoardCardAnimation",
      "animation_state": "FadeIn",
      "duration_ms": 300
    },
    {
      "event": "PLAYER_ACTION",
      "condition": "action == 'RAISE' || action == 'BET'",
      "target": "PlayerPanel[player_id].ActionBadge",
      "animation_class": "PanelTextAnimation",
      "animation_state": "GlintGrow",
      "duration_ms": 500
    },
    {
      "event": "PLAYER_ACTION",
      "condition": "action == 'FOLD'",
      "target": "PlayerPanel[player_id]",
      "animation_class": "FlagHideAnimation",
      "animation_state": "SlideAndDarken",
      "duration_ms": 400
    },
    {
      "event": "EQUITY_UPDATED",
      "target": "PlayerPanel[player_id].EquityBar",
      "animation_class": "PanelImageAnimation",
      "animation_state": "Scale",
      "duration_ms": 200
    },
    {
      "event": "POT_UPDATED",
      "target": "BoardArea.PotDisplay",
      "animation_class": "GlintBounceAnimation",
      "animation_state": "Glint",
      "duration_ms": 600
    },
    {
      "event": "HAND_WINNER",
      "target": "PlayerPanel[winner_id]",
      "animation_class": "SequenceAnimation",
      "animation_state": "GlintGrow",
      "duration_ms": 1500
    },
    {
      "event": "NEW_HAND",
      "target": "ALL",
      "animation_class": "SequenceAnimation",
      "animation_state": "PreStart",
      "duration_ms": 800
    }
  ]
}
```

---

### 제안 6: JSON-First Skin Template Schema

현행 바이너리 `.vpt` 논리 스키마를 JSON으로 먼저 정의한 뒤 AES-256-GCM으로 직렬화:

```json
{
  "skin_meta": {
    "name": "WSOP Paradise 2025",
    "version": "1.0.0",
    "author": "PokerGFX Team",
    "base_resolution": [1920, 1080],
    "supports_4k": true,
    "layout_preset": "9P_FULL"
  },
  "canvas": {
    "dual_canvas": {
      "delay_seconds": 120,
      "delay_mode": "Buffer"
    }
  },
  "animation_triggers_file": "poker_events.json",
  "components": {
    "TopBar": {
      "anchor": "TopLeft",
      "x": 0.0, "y": 0.0,
      "width": 1.0, "height": 0.04,
      "EventBadge": {
        "anchor": "TopLeft",
        "x": 0.01, "y": 0.005,
        "font": "PokerGFX-Regular", "size_normalized": 0.013,
        "color": "#FFFFFF"
      },
      "SponsorLogo": {
        "anchor": "TopCenter",
        "x": -0.04, "y": 0.002,
        "width": 0.08, "height": 0.036,
        "asset": "sponsor_logo.png"
      }
    },
    "PlayerPanel": {
      "NamePlate": {
        "anchor": "TopLeft",
        "x": 0.02, "y": 0.05,
        "font": "PokerGFX-Bold", "size_normalized": 0.014,
        "color": "#FFFFFF"
      },
      "StackDisplay": {
        "anchor": "TopLeft",
        "x": 0.02, "y": 0.25,
        "font": "PokerGFX-Bold", "size_normalized": 0.018,
        "color": "#CCCCCC",
        "format": "currency_compact"
      },
      "HoleCards": {
        "anchor": "TopLeft",
        "x": 0.02, "y": 0.50,
        "card_width_normalized": 0.10,
        "card_gap_normalized": 0.01,
        "visibility": {
          "live_canvas": "hide_when_trustless",
          "delayed_canvas": "show_after_delay"
        }
      },
      "EquityBar": {
        "anchor": "BotLeft",
        "x": 0.02, "y": -0.08,
        "width": 0.96, "height": 0.05,
        "fill_color": "#228B22",
        "empty_color": "#555555"
      },
      "ActionBadge": {
        "anchor": "TopRight",
        "x": -0.02, "y": 0.05,
        "font": "PokerGFX-Bold", "size_normalized": 0.013,
        "action_colors": {
          "RAISE": "#FF4444",
          "BET": "#FF8800",
          "CALL": "#4444FF",
          "CHECK": "#44AA44",
          "FOLD": "#888888",
          "ALL_IN": "#FF0000"
        }
      }
    }
  }
}
```

---

## 4. 구현 우선순위 로드맵

```
  PHASE A — Critical (구현 차단 해소, 순서 중요)
  ─────────────────────────────────────────────────
  A1. VTO JSON Schema 명세 작성
      → pokergfx.design.md Section 추가
      → PLAYER_INFO_VTO, STATUS_VTO 페이로드 정의

  A2. Anchor-Based Positioning 좌표계 전환
      → image_element, text_element에 anchor 필드 추가
      → x, y → 정규화 float 변환 (기존 스킨 마이그레이션 스크립트)
      → LayoutEngine 클래스 구현

  A3. Player Count Layout Manager
      → LayoutPreset enum + 좌표 테이블
      → PlayerCountLayoutManager 클래스
      → PLAYER_ADD / PLAYER_DELETE 이벤트 핸들러

  PHASE B — High (설계 품질 향상)
  ─────────────────────────────────────────────────
  B1. Semantic Component Model
      → ComponentDef 기반 클래스 + JSON 역직렬화
      → Flatten 로직 (ComponentDef → image/text element List)
      → 기존 Graphic Editor를 컴포넌트 기반으로 교체

  B2. 이벤트→애니메이션 트리거 선언 테이블
      → poker_events.json 파일 정의
      → AnimationTriggerEngine 이벤트 버스 구현
      → 게임 이벤트 → AnimationClass 디스패치

  B3. JSON-First Skin Template Schema
      → skin_schema.json 정의
      → JSON Serializer / AES-256-GCM 래퍼
      → 기존 .vpt 파이프라인 교체

  PHASE C — Medium (운영 품질)
  ─────────────────────────────────────────────────
  C1. Skin 런타임 핫스왑 절차
      → SKIN 명령어 청크 수신 → 검증 → 로드 → 렌더러 갱신

  C2. Graphic Editor GEB/GEP 명세 완성
      → GEB-001~015, GEP-001~015 각 기능 정의
      → 드래그/리사이즈 인터랙션 (WPF Adorner 또는 MouseMove)
      → Undo/Redo Command Pattern 스택

  C3. easing 함수 세트 정의
      → Linear, EaseIn, EaseOut, EaseInOut, Spring, Bounce
      → AnimationState별 기본 easing 할당
```

---

## 5. 업계 사례 참조

| 시스템 | 포지셔닝 | 데이터 바인딩 | 컴포넌트 모델 | EBS 채택 권장 |
|--------|---------|-------------|------------|--------------|
| **CasparCG** | viewport % (`vw/vh`) | JSON/XML via AMCP 명령 | HTML 레이어별 템플릿 | 포지셔닝 방식 참조 |
| **PokerGFX (원본)** | 픽셀 절대값 (추정) | RFID 실시간 자동 | 좌석별 독립 패널 | 컴포넌트 구조 참조 |
| **Chyron PRIME** | 픽셀 절대값 | JSON Pull/Push + While Loop | 데이터 기반 엘리먼트 | 데이터 파이프라인 참조 |
| **OBS Browser Source** | 픽셀 + 9-point Anchor | WebSocket 실시간 | 씬/소스/필터 계층 | 앵커 시스템 참조 |
| **CSS Anchor Positioning** | 9-point Anchor (W3C 표준) | DOM 바인딩 | 선언적 CSS | 좌표계 설계 기준 |

> **CSS Anchor Positioning**: Chrome 125+ (2024) 네이티브 지원. W3C 표준. 9-point 앵커 + 오프셋 방식이 HTML/DirectX 공통 구현 기준으로 적합.

---

## 6. 다음 단계

즉시 착수 권장:

```bash
# Phase A1 — VTO Schema 명세 (설계 문서 업데이트)
/auto "pokergfx.design.md에 VTO JSON Schema 섹션 추가 — PLAYER_INFO_VTO, GameInfo VTO 구조 명세"

# Phase A2 — 포지셔닝 좌표계 전환 (설계 변경)
/auto "image_element, text_element에 AnchorPoint enum 필드 추가, x/y 정규화 float 전환 설계"

# Phase A3 — 레이아웃 매니저 설계
/auto "PlayerCountLayoutManager 설계 — 2~10명 LayoutPreset 좌표 테이블 정의"
```

---

*참조 문서: pokergfx.design.md v4.0.0 / pokergfx-prd-v2.md v28.0.0*
*업계 리서치: CasparCG, PokerGFX, Chyron PRIME, OBS, NDI, Vizrt*
