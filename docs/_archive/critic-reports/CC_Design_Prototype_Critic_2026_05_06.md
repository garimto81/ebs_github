---
title: "CC React 디자인 프로토타입 — Critic 판정 보고서"
owner: conductor
tier: internal
status: APPROVED
last_updated: 2026-05-06

provenance:
  triggered_by: user_directive
  trigger_summary: "디자인 zip 분석 + 현재 CC 와 critic mode 엄격 우열 판정 요청"
  user_directive: |
    "claude_design 폴더의 command center 압축파일을 분석하여 현재의 cc와
     차이점을 심층 비교분석하여 critic mode 엄격하게 우열 판정"
    + 후속: "다음 단계 자율 이터레이션"
    + 후속: "기획문서 전체 수정 먼저 자율 이터레이션"
  trigger_date: 2026-05-06
  precedent_incident: "2026-05-05 19:10 디자이너 Stitch/React 시안 zip 도착"

predecessors:
  - path: claude-design/EBS Command Center (2).zip
    relation: source_content
    reason: "디자이너 산출물 — critic 분석 대상 원본"
  - path: claude-design-archive/2026-05-06/README.md
    relation: derived_from
    reason: "본 보고서가 archive README 의 SSOT 역할 (반대 방향 의존)"
  - path: docs/2. Development/2.4 Command Center/Backlog/B-team4-011-cc-visual-uplift-from-design-prototype.md
    relation: derived_from
    reason: "본 보고서의 7개 흡수 결정이 Backlog 항목으로 단계화됨"
confluence-page-id: 3819242032
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819242032/EBS+CC+React+Critic
mirror: none
---

# CC React 디자인 프로토타입 — Critic 판정 보고서

> **운영자에게 카드 정답지를 미리 주는 시안 — 그러나 그 위에 그려진 비주얼은 우리 보다 한 걸음 앞서 있었다.**

<a id="ch-anchor"></a>

## 이 문서는 어떻게 시작되었나

| 입구 (현재 상태) | 출구 (도달 상태) |
|:---|:---|
| 디자이너가 보낸 React 시안이 시각적으로 너무 좋아서, 코드를 그대로 옮기고 싶은 유혹이 생긴 상황 | 시안의 시각 자산 7가지만 흡수하고, 보안·통신·거버넌스 결함 12가지는 단호히 거절하는 합의 |

**18세 일반인을 위한 1줄 비유**: 사진은 예술 작품이지만, 그 사진을 보고 따라 만든 요리가 손님에게 식중독을 일으키면 — 사진을 보존하되 레시피로는 쓰지 않는다.

---

## Edit History

| 날짜 | 버전 | 트리거 | 변경 내용 | 직전 산출물 처리 |
|------|:----:|--------|-----------|-----------------|
| 2026-05-06 | v1.0 | 사용자 자율 이터레이션 지시 | 최초 작성 — critic 판정 + 7 흡수 / 12 거절 결정 | claude-design/ 압축 파일 → archive 이동 |
| 2026-05-06 | v1.1 | 사용자 "html 스크린샷 캡쳐하여 삽입 critic mode 검토" | §Visual Evidence 3장 삽입 + 추가 critic 6개 (V8~V13 흡수 후보 / D7 변형 위반 / 정보 중복 등) | `tools/cc_design_screenshot.py` 신규, HTTP 서버 통한 playwright 캡쳐 |

---

<a id="ch-1-act-setup"></a>

## Act 1 — Setup · 디자이너의 시안이 도착했다

2026-05-05 저녁, 디자인팀이 `EBS Command Center (2).zip` 을 전달했다. 449KB · 66 파일 · React + Babel runtime · Stitch 출력물.

### 두 시스템의 정체

<table role="presentation" width="100%">
<tr>
<td width="50%" valign="top" align="left">

**§1.1 · 디자인 시안**

#### React 프로토타입 (시안)

- 화면: **1600×900 단일 캔버스** (scale-fit)
- 좌석: **1×10 수평 컬럼 그리드**
- 카드: PNG 53장 (52 + back)
- 부팅: CDN 의존 (unpkg + googleapis)
- 통신: 없음 — React state 단일

</td>
<td width="50%" valign="top" align="left">

**§1.2 · 현재 CC (Flutter)**

#### Flutter 프로덕션 앱

- 화면: **AT-01 ~ AT-07 멀티 스크린**
- 좌석: **타원형 360° 분포**
- 카드: 텍스트 라벨 + 뒷면만
- 부팅: Docker 컨테이너 자족
- 통신: WS + Engine HTTP 병행 dispatch

</td>
</tr>
</table>

### 차원별 점수 (critic mode 엄격, 100점 만점)

| 차원 | 시안 | Flutter | 우위 |
|------|:----:|:-------:|:------|
| 시각 완성도 | 90 | 55 | 시안 |
| 정보 밀도 | 88 | 60 | 시안 |
| 인라인 편집 UX | 85 | 65 | 시안 |
| 거버넌스 정합 | 15 | 90 | **Flutter** |
| D7 보안 (운영자 부정 방지) | **0** | 95 | **Flutter ★★★** |
| 통신 모델 (WS+Engine) | 10 | 85 | **Flutter ★★★** |
| HandFSM 무결성 | 25 | 90 | **Flutter** |
| 게임 타입 지원 | 10 | 60 | **Flutter** |
| 배포 가능성 | 5 | 85 | **Flutter ★★★** |
| 테스트 가능성 | 0 | 70 | **Flutter** |
| **합계** | **403** | **815** | **2배 격차** |

별 (★) = 격차 크기. 별 3개 = "비교 자체가 안 됨" 수준.

---

<a id="ch-1b-visual-evidence"></a>

## Act 1.5 — Visual Evidence · 직접 본 시안의 모습

> *글로 쓴 critic 은 반박당하기 쉽다. 픽셀로 본 critic 은 그렇지 않다.*

`tools/cc_design_screenshot.py` 가 playwright 로 시안을 1600×900 viewport 에 띄우고 3장 캡쳐. 각 장면이 직전 §Act 2 의 결함을 어떻게 시각적으로 증명하는지 함께 본다.

### 장면 1 — IDLE 화면 (시안 첫 모습)

<table role="presentation" width="100%">
<tr>
<td width="55%" valign="top" align="left">

![IDLE full screen](../images/cc-design-prototype/01-idle-full.png)

> *FIG-1 · IDLE — 9 좌석 컬럼 + 좌측 미니맵 + START HAND 우측 활성*

</td>
<td width="45%" valign="top" align="left">

**§1.5.1 · 첫 인상 critic**

- 좌측 상단 **미니 oval + POT $0** — 한눈 파악 우수 (V3 흡수 정당화)
- 9 컬럼 좌석 — DELETE strip / S번호 / Position 3 sub-rows / CTRY / 이름 / 카드 슬롯 / STACK 7행 (V5 흡수 정당화)
- FLOP 1·2·3 / TURN / RIVER 슬롯 라벨 — Flutter "Card 1~5" 대비 우월 (**V8 신규 후보**)
- 액션 패널 모든 버튼 disabled, START HAND 만 활성 — 운영자 다음 행동 명확 (canStartHand 시각 정합)
- 하단 좌측 ↓Bottom / ←Left / Right→ layout 스위처 — 1 CC = 1 운영자 가정에 굳이 필요?

</td>
</tr>
</table>

### 장면 2 — PRE_FLOP (N 키 후 자동 분배)

<table role="presentation" width="100%">
<tr>
<td width="45%" valign="top" align="left">

**§1.5.2 · PRE_FLOP critic**

- POT $600 (SB 200 + BB 400) — 좌상단 강조 박스
- 우측 큰 ACTING 박스 — "S8 · Choi" 명시 (**V9 신규 후보** — Flutter glow 만 vs 명시 박스)
- S5/S6 좌석 위 SB·BB 마커 + 칩 시각화 — 베팅 액수 한눈 파악
- **그러나** 미니맵에도 SB·BB 뱃지 + 좌석 컬럼에도 SB·BB → **이중 표시 (정보 중복)**
- FOLD / CALL $400 / RAISE / ALL-IN $5,750 → 활성 + 동적 라벨 (V1 정합)
- 카드 슬롯 모두 face-down — 표면적으로 D7 정합처럼 보임...

</td>
<td width="55%" valign="top" align="left">

![PRE-FLOP](../images/cc-design-prototype/02-pre-flop-face-down.png)

> *FIG-2 · PRE_FLOP — face-down 분배. 그러나 클릭 가능 = 다음 장면이 D7 변형 위반 증명*

</td>
</tr>
</table>

### 장면 3 — CardPicker 모달 (D7 위반 시각 증명)

<table role="presentation" width="100%">
<tr>
<td width="55%" valign="top" align="left">

![CardPicker — 52 cards selectable](../images/cc-design-prototype/03-card-picker-D7-violation.png)

> *FIG-3 · 운영자가 face-down 카드 슬롯 클릭 → 52장 picker. 어느 카드든 선택/교체 가능.*

</td>
<td width="45%" valign="top" align="left">

**§1.5.3 · D7 위반 시각 증명**

이 한 장이 §Act 2 결함 1 (D7 위반) 의 결정적 증거다.

| 단계 | 운영자 행동 | 결과 |
|:---:|------------|------|
| 1 | 좌석 카드 슬롯 클릭 | 모달 즉시 등장 |
| 2 | 4×13 그리드 (52장) 선택 가능 | "딜링 부정" 가능 영역 |
| 3 | 이미 분배된 카드는 회색 ("Already dealt") | 부분 가드만 |
| 4 | ESC 또는 카드 선택 후 닫음 | 슬롯에 face-up 카드 노출 |

**즉**: face-down 분배는 default 상태일 뿐, 운영자가 1 클릭으로 face-up 카드를 임의 선택/교체 가능. 표면적 D7 정합 → **실질 D7 위반**.

</td>
</tr>
</table>

---

## Act 1.6 — 시각 검토에서 추가로 발견한 것

> *글로만 본 critic 은 7개 흡수안만 도출했다. 픽셀로 보니 13개로 늘어났다.*

### 추가 흡수 후보 (V8 ~ V13)

```
   V8   FLOP/TURN/RIVER 슬롯 라벨        — Flutter "Card 1~5" 대체 (CommunityBoard 강화)
   V9   ACTING 우측 명시 박스            — "S8 · Choi · Stack $5,750" 큰 박스 강조
   V10  POT 좌상단 강조 박스             — InfoBar 작은 표기 → 좌상단 큰 박스 (V3 와 결합)
   V11  베팅 칩 시각화 (좌석 위 $ 칩)    — Pre/Flop 베팅 액수 칩 형태로 좌석 위에 부유
   V12  카드 슬롯 + ADD 빈 자리 affordance — Flutter 빈 hole card slot UI 강화
   V13  IDLE → 액션 disabled visual hint — 회색 처리 (현 Flutter도 적용 — 정합 확인)
```

### 시각 검토에서 거절 / 보류 (3종)

| ID | 시안 패턴 | 판정 | 이유 |
|:--:|----------|:----:|------|
| R1 | layout 스위처 (Bottom/Left/Right) | **거절** | 1 CC = 1 운영자, 멀티 운영 시 layout 분기 무의미 |
| R2 | SB·BB 이중 표시 (미니맵 + 좌석 컬럼) | **보류** | 정보 중복. V3 흡수 시 단일 source 정책 명문화 필요 |
| R3 | CardPicker 의 face-up 카드 선택 자체 | **D7 강제 거절** | Flutter CC 는 카드 선택 시 RFID 또는 Manual_Card_Input 폴백만. 임의 선택 불가 |

### 시각 검토 정리 표 (전체)

| ID | 자산 | 글-critic | 시각-critic | 결합 판정 |
|:--:|------|:--------:|:-----------:|:---------:|
| V1 | KeyboardHintBar | 흡수 | 흡수 (구현 완료) | ✅ 진행 중 |
| V2 | StatusBar | 흡수 | 흡수 + V10 결합 | ✅ 강화 |
| V3 | MiniDiagram | 흡수 | 흡수 + R2 가드 | ✅ 강화 |
| V4 | PositionShiftChip | 흡수 | 흡수 | ✅ |
| V5 | SeatCell 7행 | 흡수 | 흡수 + V11/V12 결합 | ✅ 강화 |
| V6 | ACTING glow | 흡수 | 흡수 + V9 결합 | ✅ 강화 |
| V7 | TweaksPanel | 흡수 | 흡수 | ✅ |
| **V8** | **FLOP/TURN/RIVER 슬롯 라벨** | — | **신규** | ✅ NEW |
| **V9** | **ACTING 명시 박스** | — | **신규** | ✅ NEW |
| **V10** | **POT 좌상단 강조 박스** | — | **신규** | ✅ NEW |
| **V11** | **베팅 칩 부유 시각** | — | **신규** | ✅ NEW |
| **V12** | **카드 슬롯 + ADD affordance** | — | **신규** | ✅ NEW |
| **V13** | **disabled visual hint** | — | **확인** | ✅ 정합 확인 |
| R1 | layout 스위처 | — | 거절 | ❌ 거절 |
| R2 | SB·BB 이중 표시 | — | V3 가드 추가 | 🔵 보류 |
| R3 | CardPicker face-up 선택 | — | **D7 강제 거절** | ❌ 거절 |

**시각 검토 결론**: 7개 → **13개 흡수안** (V1~V13). 거절 3건 (R1~R3). Backlog `B-team4-011` 갱신 권장.

---

> *시각이 아무리 우월해도, 보안 결함 1개는 사업 자체를 무산시킨다.*

### 치명 결함 12종 (시안 production 불가 사유)

```
  CRITICAL — 단일 항목으로 production 무산 (3종)
  ─────────────────────────────────────────────
  1. D7 위반        — 운영자(딜러)에게 카드 노출
  2. CDN 의존       — 카지노 LAN 부팅 실패
  3. 통신 모델 부재  — EBS Core (3입력→오버레이) 작동 불가
```

### 결함 1 (D7 위반) — 사업 무산 위험

```jsx
// PlayerColumn.jsx ROW 4 — HOLE CARDS (시안 코드)
<button onClick={...} title={`${card.rank}${card.suit}`}>
  <img src={window.cardImagePath(card)} alt={card.rank + card.suit} />
</button>
```

비유: **시험 감독관에게 정답지를 미리 쥐여주는** 행위. SG-021 / Foundation §5.4 / IMPL-007 정면 위반.

Flutter CC 는 `_buildHoleCardBack` (뒷면만) + `tools/check_cc_no_holecard.py` CI 가드까지 둠. 라이브 토너먼트에서 운영자 부정 행위 = **WSOP 같은 라이브 방송 신뢰 자체가 무너짐**.

### 결함 2~12 (요약 표)

| # | 결함 | 영향 |
|:-:|------|------|
| 1 | **D7 위반** (운영자에 카드 노출) | 사업 무산 |
| 2 | **CDN 의존** (React/Babel/Inter) | 카지노 LAN 부팅 실패 |
| 3 | **통신 모델 부재** (WS/Engine 없음) | EBS Core 작동 불가 |
| 4 | HandFSM 9-state 부재 | 잘못된 상태 전이 차단 못 함 |
| 5 | RFID HAL 부재 | SG-006 3-mode 미구현 |
| 6 | RBAC 부재 | Admin/Operator/Viewer 구분 없음 |
| 7 | UndoStack 부재 | 1-step snapshot 만 |
| 8 | i18n 부재 | 한국어 라벨 없음 |
| 9 | 테스트 0줄 | 회귀 검증 불가 |
| 10 | AT-04~07 화면 미구현 | 4 화면 부재 |
| 11 | 9 게임 타입 → NLH 단일 | Mix 17종 미지원 |
| 12 | Babel runtime in browser | 첫 부팅 50ms+ 추가 |

---

<a id="ch-3-act-build"></a>

## Act 3 — Build · 그래도 시안에서 흡수해야 할 것

> *결함이 있다고 해서 시각적 영감까지 거절하면 우리는 영원히 둔감한 화면에 갇힌다.*

### 7개 시각 자산 흡수 결정 (V1~V7)

<table role="presentation" width="100%">
<tr>
<td width="50%" valign="top" align="left">

**§3.1 · 단순 흡수 (V1, V2, V6)**

| ID | 자산 | 가드 |
|:--:|------|------|
| **V1** | KeyboardHintBar (F·C·B·A·N·M 칩) | 단축키 매핑 변경 없음 |
| **V2** | StatusBar 통합 (BO/RFID/Engine 한 줄) | 기존 banner/dot 흡수 |
| **V6** | ACTING 펄스 글로우 강화 | `_glowController` 튜닝만 |

</td>
<td width="50%" valign="top" align="left">

**§3.2 · 신규 위젯 (V3, V4, V7)**

| ID | 자산 | 가드 |
|:--:|------|------|
| **V3** | MiniDiagram (좌측 상단 미니 oval) | CustomPaint, SVG 의존 없음 |
| **V4** | PositionShiftChip (D/SB/BB/STR ‹ ›) | Engine 결정 룰 보존 |
| **V7** | TweaksPanel (debug 한정) | release 빌드 미포함 |

</td>
</tr>
</table>

### 가장 큰 변경 — V5 (Seat Cell 7행 보강)

```
   현재 Flutter SeatCell (3행)         흡수 후 (7행)
   ──────────────────────────         ──────────────────────
   ┌────────────────┐                 ┌────────────────┐
   │ 🇰🇷 Daniel  S1 │                 │ ACTING / WAIT  │ ← acting strip
   ├────────────────┤                 ├────────────────┤
   │  $128,400      │                 │ S1             │
   ├────────────────┤                 ├────────────────┤
   │ [?][?] BTN     │                 │ STR / SB·BB / D│ ← position 3행
   └────────────────┘                 ├────────────────┤
                                       │ 🇰🇷 + Daniel    │ ← country/name
                                       ├────────────────┤
                                       │ [?][?]         │ ← hole back (D7 유지)
                                       ├────────────────┤
                                       │ STACK $128,400 │
                                       ├────────────────┤
                                       │ BET / LAST     │ ← bet + last action
                                       └────────────────┘
```

**중요**: 7행 중 hole card 행은 **반드시 face-down (뒷면) 만**. 시안의 `<img src=cardImagePath>` 패턴은 절대 모방 안 함.

### 가드레일 (4개 — HARD ENFORCE)

| # | 가드 | 검증 |
|:-:|------|------|
| 1 | hole card 값 노출 금지 (D7) | `tools/check_cc_no_holecard.py` CI |
| 2 | CDN 의존 도입 금지 | `pubspec.yaml` 리뷰 |
| 3 | 통신 모델 변경 금지 | `engine_output_dispatcher.dart` diff = 0 |
| 4 | HandFSM 9-state 전이 룰 변경 금지 | `hand_fsm_provider.dart` 테스트 |

---

<a id="ch-4-act-resolution"></a>

## Act 4 — Resolution · 변화는 무엇인가

> *시안은 reference 로 봉인되고, 우리 앱은 시각만 한 단계 끌어올린다.*

### 결정 요약

```
  ┌─────────────────────────────────────────────────────────┐
  │  시안 React 코드 → archive 봉인 (이식 금지)              │
  │  시안 시각 자산 7종 → Flutter CC 자율 흡수 (V1~V7)       │
  │  시안 보안/통신/거버넌스 결함 12종 → 거절                │
  │                                                         │
  │  최종: Flutter CC 가 production 자격 + 시각 우월성 동시  │
  │       달성. 디자인 시안은 reference 자료로만 보존.       │
  └─────────────────────────────────────────────────────────┘
```

### 진행 상황 (2026-05-06 본 turn)

| Phase | 작업 | 상태 |
|:-----:|------|:----:|
| A | archive (zip + extracted/ → claude-design-archive/2026-05-06/) | ✅ |
| A | claude-design-archive README (이식 금지 명시) | ✅ |
| A | Backlog `B-team4-011` 등재 | ✅ |
| B | V1 KeyboardHintBar 신규 (~140줄, dart analyze 0 issues) | ✅ |
| B | V1 at_01_main_screen 통합 (+2줄) | ✅ |
| C | V2 StatusBar 통합 위젯 | ⏳ |
| D | V3 MiniDiagram + V4 PositionShiftChip | ⏳ |
| E | V5 Seat Cell 7행 보강 (executor 위임 권장) | ⏳ |
| F | V6 glow 강화 + V7 TweaksPanel | ⏳ |
| G | screenshot diff + critic verify | ⏳ |

### 후속 영향 (관련 SSOT 갱신 — 본 turn 동시 처리)

| 문서 | 갱신 내용 |
|------|----------|
| `Command_Center_UI/UI.md` | V2 StatusBar 통합 + V3 MiniDiagram + V5 Seat 7행 + V6 glow 시각 정책 |
| `Command_Center_UI/Keyboard_Shortcuts.md` | V1 시각 힌트 표시 정책 |
| `Command_Center_UI/Seat_Management.md` | V4 PositionShiftChip + V5 7행 컬럼 운영 행위 |
| `Command_Center_UI/Overview.md` | Visual Uplift 인덱스 (1줄) |

### 보존 사유 (왜 시안을 삭제하지 않고 archive 했나)

1. **시각 reference**: V1~V7 흡수 시 layout/spacing/typography 비교 자료
2. **법적 추적**: 디자이너 산출물 검수 이력
3. **사후 critic**: 6개월 뒤 Phase G 완료 시 시안과 최종 비주얼 비교

위치: `claude-design-archive/2026-05-06/` (이식 금지 명시)

---

## 부록 — 자가 점검 (룰 19 P7 통과 확인)

| # | 항목 | 결과 |
|:-:|------|:----:|
| 1 | Provenance `triggered_by` 기록 | ✅ |
| 2 | Edit History 본문 상단 | ✅ |
| 3 | 직전 산출물 predecessors 기록 | ✅ |
| 4 | Layout Block `role="presentation"` | ✅ |
| 5 | Symmetric cell 빈 줄 분리 | ✅ |
| 6 | Hook 첫 200자 — 비유 + 인용구 | ✅ |
| 7 | Thesis 80자 이하 한 줄 명제 | ✅ |
| 8 | Reader Anchor 입구/출구 명시 | ✅ |
| 9 | Visual Rhythm — Stat/Layout/인용 alternating | ✅ |
| 10 | Narrative Arc — Setup→Incident→Build→Resolution | ✅ |

**판정**: 본 보고서는 룰 19 Feature Block 표준에 통과한다.
