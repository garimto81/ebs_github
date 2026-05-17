---
title: 정본 프로토타입 기반 UI/UX 리뉴얼 기획 (Frontend Design Renewal Plan) [SUPERSEDED]
owner: conductor
tier: internal
last-updated: 2026-05-17
status: SUPERSEDED (v2 → v5)
superseded_by: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
superseded_reason: "본 plan v2 (UI/UX-only scope) 의 framing 자체가 PokerGFX 정본 분석 결과 부족 — 사용자 3 decisions 가 UI/UX 가 아닌 7-Layer architecture 결정으로 재정의됨. v5 ultrathink rewrite 에서 8 decisions (3 reframed + 5 hidden) + PRD +630줄 + 신규 docs 3 + SG ticket 15 권고. 본문 보존 (Removal ≠ Answer)."
confluence-sync: none
mirror: none
type: renewal_plan
scope: frontend_design_only
provenance:
  triggered_by: user_directive
  trigger_date: 2026-05-15
  trigger_text: "이 정본을 토대로 어떻게 리뉴얼해야할지 리뉴얼 기획 문서 작성하여 보고"
  scope_refinement_text: "You only need to make the frontend design (UI/UX) exactly the same as the original; the remaining functional and technical elements can be handled as is from the prototype. The problem is the currently terrible design and UX."
  source_audit: docs/4. Operations/Reports/2026-05-15-prototype-accurate-original-gap-audit.md
  ground_truth_zips:
    - C:\Users\AidenKim\Downloads\EBS Lobby (1).zip
    - C:\Users\AidenKim\Downloads\EBS Command Center (2).zip
  memory_link: prototype_accurate_original_2026_05_15.md
---

## 🎯 한 줄 요약 (v2 — UI/UX-only scope)

> **사용자 명시 범위 (2026-05-15)**: 정본과 **frontend design (UI/UX) 만** 완전 일치. 기능/기술/데이터 모델/엔진 연동/Hand FSM 등은 현재 Flutter 그대로 둠. 사용자 평가 = "currently terrible design and UX".
>
> 핵심 전략 = **시각·레이아웃·디자인 토큰·UX 인터랙션만 정본 기준으로 재구현**. mockup HTML 은 deprecated 처리. 5 Phase 자율 진행, 사용자 결정 영역 1-2 회.

### 비유로 설명 (v2)

> 정본 = **건축가의 완성 모형** (외관/마감/색상/레이아웃이 완벽).
> 현재 docs/ HTML = **옛 외관 도면** (다른 색·다른 비례, 폐기 예정).
> 현재 Flutter = **이미 작동하는 건물** (배관·전기·기능은 이미 OK, **외관/인테리어만 모형과 다름**).
>
> 리뉴얼 = "건물 내부 시스템(기능/기술) 은 건드리지 않고, **외관·인테리어·UI 만 모형(정본) 과 픽셀 단위로 일치**시키기".

### 사용자 명시 정책 (HARD CONSTRAINT)

| 영역 | 본 cycle 범위? |
|------|:--------------:|
| 시각 디자인 (색·폰트·spacing·shadows) | ✅ **범위 내** |
| 레이아웃 (PlayerColumn 1×10, KPI strip, breadcrumb 등) | ✅ **범위 내** |
| 컴포넌트 시각 구조 (7-row, scard 카드, badge 등) | ✅ **범위 내** |
| 시각 인터랙션 (호버, 클릭, 트랜지션, 모달 디자인) | ✅ **범위 내** |
| 화면 전환 UX (탭, 필터, 검색 UI) | ✅ **범위 내** |
| Hand FSM 7-state 로직 | ❌ **범위 밖** (기능) |
| 키보드 단축키 매핑 (N/F/C/B/A/M) | ❌ **범위 밖** (기능) |
| seat.sync (AUTO/MANUAL_OVERRIDE/CONFLICT) 모델 | ❌ **범위 밖** (데이터) |
| Engine connection / BO API 호출 | ❌ **범위 밖** (기술) |
| Riverpod provider 구조 | ❌ **범위 밖** (기술) |
| overlay/ 출력 layer | ❌ **범위 밖** (기능) |
| Miss Deal 복원 로직 | ❌ **범위 밖** (기능) |
| Launch CC 모달의 백엔드 액션 | ❌ **범위 밖** (기능) |
| **Launch CC 모달의 시각 디자인** | ✅ **범위 내** |
| 데이터 schema 필드 추가 | ❌ **범위 밖** |
| 데이터 필드의 **표시 방식** (chip bar, flag chip, mono font 등) | ✅ **범위 내** |

### 메트릭 표 (v2 — UI/UX 정합 기준만)

| 항목 | 현재 | 목표 (리뉴얼 후) |
|------|:----:|:----------------:|
| 정본 위치 | Downloads/ (git 외부) | `docs/1. Product/Prototype/originals/` (git 추적) ✅ Phase 0 완료 |
| Lobby mockup A 시각 정합도 | 25% | **deprecated** (정합도 평가 X) |
| CC mockup B 시각 정합도 | 20% | **deprecated** |
| Flutter Lobby C **UI/UX 정합도** | 불명 (대략 40-50% 추정) | **≥ 95%** (시각·레이아웃·토큰만) |
| Flutter CC D **UI/UX 정합도** | 불명 (대략 30-40% 추정) | **≥ 95%** (시각·레이아웃·토큰만) |
| C, D 기능/기술 정합도 | 70%+ | **현재 그대로 유지** (변경 안 함) |
| 디자인 토큰 (OKLCH + Inter + JetBrains Mono) | Flutter 미반영 | **완전 매핑** |
| 스크린샷 비교 ΔE (색차) | — | **< 5** |
| 시각 컴포넌트 1:1 매핑 표 | — | **완료** |
| 사용자 결정 진입점 | — | **1-2 회** (브랜드 결정 + 최종 승인) |

---

## Part 1 — 컨텍스트 (Why)

### 1.1 본 리뉴얼이 필요한 이유

```
   현재 상태 (2026-05-15)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   Downloads/                              docs/                  team1/4-cc/
   ┌────────────┐                          ┌────────────┐         ┌──────────┐
   │ 정본 ZIP   │ ← user designated         │ mockup HTML│         │ Flutter  │
   │ (외부)     │   accurate original       │  A, B      │         │ C, D     │
   │            │                          │ 정합도     │         │ 정합도   │
   │ React JSX  │                          │ 25% / 20%  │         │ 68% / 72%│
   │ + 카드 PNG │                          │ (정적 HTML)│         │ (작동)   │
   └────────────┘                          └────────────┘         └──────────┘
        │                                        │                    │
        │ git 추적 외부                          │ "wrong" 선언됨     │ 정본 기준
        │ SHA 무결성만 기록                     │ deprecated 후보    │ 70% drift
        ▼                                        ▼                    ▼
        
        문제: SSOT chain 단절. 정본·docs·구현 어디가 진짜인지 협업자 혼동.
        프로젝트 인텐트 "개발 문서 + 프로토타입 100% 일관성" 위반.
```

### 1.2 직전 cycle 발견 (Gap Audit 보고서)

본 문서는 [`2026-05-15-prototype-accurate-original-gap-audit.md`](../Reports/2026-05-15-prototype-accurate-original-gap-audit.md) 의 후속.

**발견 요약**:
- **P0 차단 결함 5 건** — 정본 미러 부재, Lobby 브랜드 충돌 (WPS vs WSOP), CC mockup 85% 기능 부재, Flutter PlayerColumn 일치 미검증, mockup 화면 누락
- **P1 흐름 차단 9 건** — 키보드 단축키 불일치, Hand FSM 단순화, Sync 모델 미검증, Tweaks 미구현, Launch CC 모달 매핑 미검증 등
- **P2 시각 drift 14 건** + **P3 개선 권고 8 건**

### 1.3 본 리뉴얼의 본질

> "리뉴얼 = 정본을 SSOT 로 박는 작업 + 정본 기준 drift 정정". 신규 기능 추가 아님.

| 본 리뉴얼은 | 본 리뉴얼이 아닌 것 |
|------------|--------------------|
| 정본을 git 으로 가져오기 | 새 기능 추가 |
| 옛 mockup HTML 폐기 표식 | 옛 mockup 삭제 (보존 — "Removal ≠ Answer") |
| Flutter 의 정본 vs drift 정정 | Flutter 전면 재작성 |
| 디자인 토큰 OKLCH 통일 | 새 UI/UX 디자인 |
| docs/ PRD 정본 reflect | 신규 PRD 작성 (별도 cycle) |

---

## Part 2 — 목표 (Goals) vs 비목표 (Non-Goals)

### 2.1 Goals (본 리뉴얼이 달성하는 것 — v2 UI/UX-only)

| # | Goal | 검증 가능 조건 |
|---|------|--------------|
| G1 | 정본 ZIP 의 git 등록 (SSOT 단일화) | ✅ **Phase 0 완료** |
| G2 | docs/ HTML mockup 의 deprecated 명시 | A, B 두 파일에 frontmatter `status: deprecated` + 정본 링크 |
| G3 | Flutter Lobby C 의 **UI/UX 정합 ≥ 95%** | 시각 1:1 매핑표 + 스크린샷 ΔE < 5 |
| G4 | Flutter CC D 의 **UI/UX 정합 ≥ 95%** | 시각 1:1 매핑표 + 스크린샷 ΔE < 5 |
| G5 | 디자인 토큰 정본 매핑 (OKLCH→sRGB + Inter + JetBrains Mono) | Flutter ThemeData ↔ 정본 tokens.css 1:1 매핑표 |
| G6 | 정본 컴포넌트 시각 구조 재현 (PlayerColumn 7-row, KPI strip 5-card, scard 카드, breadcrumb 등) | 컴포넌트별 시각 회귀 테스트 통과 |
| G7 | 정본 ↔ Flutter widget **시각 1:1 매핑 reference** (외부 인계용) | `docs/1. Product/Prototype/component_visual_mapping.md` |
| G8 | 사용자 진입점 최소화 | 본 리뉴얼 cycle 사용자 결정 ≤ 2 회 |

### 2.1b 명시적으로 본 cycle 에서 다루는 시각 항목 (Inclusive list)

| 카테고리 | 항목 |
|---------|------|
| **색상** | OKLCH 토큰 → sRGB 매핑 (--bg-0..3, --fg-0..3, --line, --accent, --bg-felt, --pos-d/sb/bb, semantic ok/warn/err/info, card-bg/red/black, status badge 색) |
| **폰트** | Inter (UI), JetBrains Mono (숫자/모노), font-variant-numeric: tabular-nums |
| **Spacing** | --r-sm/md/lg/xl (4/8/12/16 px radius), padding/gap 정본 매칭 |
| **Shadows / Glow** | --shadow-card, --shadow-pop, --glow-action (accent glow ring) |
| **레이아웃 (Lobby)** | TopBar 4-cluster, Rail 3-section, Breadcrumb 다단, KPI strip 5-card, Levels strip, scard 카드 그리드, dtable, seg control |
| **레이아웃 (CC)** | 1600×900 scale-fit canvas, StatusBar 3-zone, TopStrip MiniDiagram+Board+Acting, PlayerGrid 1×10, PlayerColumn 7-row, ActionPanel 3-zone, Layout switcher (bottom/left/right) |
| **시각 컴포넌트** | Badge (b-running/registering/announced/completed), Status pill, Featured/marquee 강조 (★ + golden row), seat states (s-a/e/r/d/w), cc-cell (live/idle/err), rfid-cell (rdy/off/err), chipsbar, flag-chip, state-pill |
| **모달 디자인** | Launch CC modal (sheet-bg + sheet), CardPicker grid, Numpad keypad, MissDealModal, FieldEditor — **시각 디자인만**, 액션 핸들러는 현재 유지 |
| **인터랙션 시각 피드백** | hover state, active state, focus ring, click pulse, action-on glow, folded opacity, transition timing |
| **반응형** | scale-fit (CC), data-density compact/default/cozy (Lobby), responsive table |
| **Empty/Loading states** | empty seat (+ ADD PLAYER), no data dashes, muted text |

### 2.1c 명시적으로 본 cycle 에서 다루지 않는 항목 (Exclusive list, 사용자 명시)

| 카테고리 | 항목 |
|---------|------|
| **상태 관리** | Riverpod provider 구조, BLoC, freezed entity (현재 그대로) |
| **비즈니스 로직** | Hand FSM 7-state, Miss Deal 복원, Pot/biggestBet 계산, 라운드 종료 감지, action 처리 |
| **데이터 모델 필드 변경** | seat.sync, equity %, connection.engine, blinds 구조 — 현재 그대로 |
| **백엔드 통신** | BO API 호출, WebSocket, Engine connection, dispatcher |
| **출력 layer** | overlay/, NDI, dual_output_manager, security_delay_buffer, rive_overlay_canvas |
| **운영 흐름** | Launch CC 실제 운영자 할당 로직, RFID 페어링, multi-table 관리 |
| **키보드 단축키 매핑** | 현재 Flutter 단축키 그대로 (정본 N/F/C/B/A/M 통일 ❌ 본 cycle 에서 안 함) |
| **테스트 인프라** | unit/integration test 로직 (시각 스냅샷 테스트만 신규 추가) |
| **빌드/CI/배포** | Docker compose, Playwright CI, deployment pipeline |

### 2.2 Non-Goals (본 리뉴얼이 다루지 않는 것 — v2)

| # | Non-Goal | 이유 |
|---|---------|------|
| NG1 | mockup HTML 파일 삭제 | "Removal ≠ Answer" 정책. deprecated 표식만 |
| NG2 | 정본 자체 수정 | 정본은 사용자가 지정한 SSOT — Claude 자율 수정 금지 |
| NG3 | 신규 화면/기능 추가 | 정본 미정의 영역은 별도 PRD cycle |
| NG4 | Lobby 브랜드 (WPS vs WSOP) 통일 결정 | 비즈니스 의미 차원 — 사용자 결정 영역 |
| NG5 | 일정 / 예산 / MVP 우선순위 | 본 프로젝트 인텐트 범위 밖 |
| NG6 | 시장 분석 / 경쟁사 분석 | 본 프로젝트 인텐트 범위 밖 |
| NG7 | **Flutter 기능/기술/엔진/데이터 모델 정합** | **사용자 명시 (2026-05-15): "기능적/기술적 요소는 현재 그대로"** |
| NG8 | Hand FSM 7-state Flutter 매핑 | NG7 (기능) |
| NG9 | 키보드 단축키 N/F/C/B/A/M 통일 | NG7 (기능) |
| NG10 | seat.sync (AUTO/MANUAL_OVERRIDE/CONFLICT) 모델 추가 | NG7 (데이터) |
| NG11 | Engine connection / BO API / WebSocket 정정 | NG7 (기술) |
| NG12 | overlay/ 영역 정본화 | 정본 미정의 |
| NG13 | graphic_editor / staff 정본화 | 정본 미정의 |
| NG14 | 정본 ZIP 의 React 18 → 19 업그레이드 | NG2 |
| NG15 | 정본 LAN 호환 옵션 (unpkg → 로컬 vendor) | 본 cycle 범위 축소 — 별도 cycle |

---

## Part 3 — 정본 SSOT 정의 (Source of Truth)

### 3.1 정본 = 두 React ZIP 만

```
   정본 SSOT (단일 reference 진실)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   ┌──────────────────────────────────────────┐
   │  EBS Lobby (1).zip                       │
   │  SHA256: CC277B32…                       │
   │  130,457 bytes, 8 JSX/CSS + 2 screenshots│
   │                                          │
   │  → 9 화면, OKLCH, WPS · EU 2026 브랜드  │
   └──────────────────────────────────────────┘
   
   ┌──────────────────────────────────────────┐
   │  EBS Command Center (2).zip              │
   │  SHA256: 237B26FF…                       │
   │  356,559 bytes, 9 JSX/CSS + 52 카드 PNG │
   │                                          │
   │  → 1600×900, 10 좌석 PlayerColumn 1×10   │
   │  → 7-state Hand FSM, 6 키보드 단축키     │
   └──────────────────────────────────────────┘
   
   메모리 영구 등록: prototype_accurate_original_2026_05_15.md
```

### 3.2 정본의 SSOT 권한

| 항목 | 정본 권한 | 현재 |
|------|:---------:|:-----:|
| 화면 정의 | ✅ 절대 | mockup, Flutter 가 추종 |
| 컴포넌트 트리 | ✅ 절대 | Flutter widget 트리가 매핑 |
| 인터랙션 명세 | ✅ 절대 | 키보드 단축키 / FSM / 모달 모두 정본 따름 |
| 디자인 토큰 (색/폰트/spacing) | ✅ 절대 | OKLCH + Inter + JetBrains Mono |
| 데이터 모델 (필드 명세) | ✅ 절대 | GameState / Seat / Connection / Card / Series / Event 등 |
| 운영 흐름 (Miss Deal / Launch CC) | ✅ 절대 | Flutter 의 동등 흐름 구현 강제 |
| **정본 자체 변경** | ❌ 금지 | 사용자만 가능 (Claude 자율 X) |

### 3.3 정본 SSOT chain (단방향)

```
   정본 ZIP (Downloads + docs/Prototype/originals 미러)
              │
              │ derivative-of (단방향)
              ▼
   docs/1. Product/{Lobby,Command_Center}_PRD.md
              │
              │ derivative-of
              ▼
   docs/2. Development/2.{1,4}/Overview.md (정본 기술 명세)
              │
              │ implements
              ▼
   team1-frontend/lib/features/**  +  team4-cc/src/lib/features/**
              │
              │ verified-against
              ▼
   integration-tests/playwright/**  (정본 동작 e2e)
```

**원칙**: 위에서 아래로만 흐름. drift 발생 시 항상 정본 기준으로 아래쪽 정정.

---

## Part 4 — 리뉴얼 전략 (5 Phase 자율 진행)

### 4.1 Phase 구조 다이어그램

```
   Phase 0     Phase 1       Phase 2          Phase 3        Phase 4
   ──────     ───────      ────────       ────────       ────────
   
   정본 등록   mockup       Flutter         디자인          검증 + 인계
   (SSOT      deprecation   drift 정정      토큰 통일      
    단일화)
   
   ┌──────┐  ┌──────┐    ┌────────┐    ┌────────┐    ┌──────────┐
   │ ZIP  │  │ A, B │    │ C, D   │    │ OKLCH  │    │ 1:1 매핑 │
   │ → git│→ │ depr.│ →  │ widget │ →  │ Inter  │ →  │ docs +   │
   │ +SHA │  │ mark │    │ 정합   │    │ JBMono │    │ 인계 ref │
   └──────┘  └──────┘    └────────┘    └────────┘    └──────────┘
      │         │            │              │              │
      자율      자율         자율           자율           자율 + 
                                                          사용자 1회
                                                          (최종 승인)
   
   사용자 결정 영역 (총 2 회):
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ① Phase 1 직후: Lobby 브랜드 결정 (WPS vs WSOP)
   ② Phase 4 종료: 최종 승인 + PR 머지
```

### 4.2 각 Phase 의 자율 vs 사용자 결정 분리

| Phase | 자율 영역 (Claude) | 사용자 결정 영역 |
|-------|-------------------|-----------------|
| **0** | git 등록 위치 결정, SHA manifest, frontmatter 작성, .gitattributes | — |
| **1** | mockup A, B 에 deprecated frontmatter 추가, 정본 링크 삽입 | 브랜드 결정 (WPS vs WSOP) — **결정 #1** |
| **2** | Flutter widget 트리 비교, drift 항목별 SG ticket 발행, 비파괴 정정 | — |
| **3** | OKLCH ↔ Flutter Color 매핑, Inter/JBMono 폰트 등록 | — |
| **4** | 1:1 매핑 reference 문서 작성, e2e 검증, PR 생성 | PR 최종 승인 — **결정 #2** |

---

## Part 5 — Phase 별 상세 액션

### 5.1 Phase 0: 정본 등록 (SSOT 단일화)

**목표**: 정본 ZIP 을 git 으로 가져와 모든 협업자가 받을 수 있게 함.

**액션**:

| # | 액션 | 산출물 | 비파괴? |
|---|------|--------|:------:|
| 0.1 | `docs/1. Product/Prototype/originals/` 디렉토리 생성 | 폴더 | ✅ |
| 0.2 | 정본 ZIP 2개를 위 경로로 복사 (원본 Downloads 보존) | `EBS Lobby (1).zip`, `EBS Command Center (2).zip` | ✅ |
| 0.3 | `originals/_manifest.json` 생성 (SHA256 + frontmatter 메타) | manifest | ✅ |
| 0.4 | `originals/README.md` 생성 (정본 사용 규칙 + 추출 방법 + 영구 등록 메모리 링크) | README | ✅ |
| 0.5 | `.gitattributes` 에 `*.zip filter=lfs diff=lfs merge=lfs -text` 추가 (git LFS) | gitattributes | ✅ |
| 0.6 | `.gitignore` 에 `work/prototype-audit/` 명시 (이미 untracked 상태 명문화) | gitignore | ✅ |

**검증**:
- `git ls-files docs/1. Product/Prototype/originals/` 가 ZIP 2개 표시
- SHA256 manifest 와 실제 ZIP SHA 일치
- 사용자 결정 진입점 = 0 회

### 5.2 Phase 1: mockup HTML 의 deprecated 처리

**목표**: 정본 가장한 HTML mockup 을 deprecated 로 명시 (삭제 ≠ 답).

**액션**:

| # | 액션 | 대상 파일 |
|---|------|----------|
| 1.1 | `docs/1. Product/visual/ebs-lobby-mockup.html` 에 frontmatter `status: deprecated` + HTML 주석으로 정본 링크 + 폐기 사유 | A |
| 1.2 | `docs/1. Product/References/foundation-visual/cc-mockup.html` 에 동일 처리 | B |
| 1.3 | 두 파일의 mirror 사본 (`docs/2. Development/2.1 Frontend/Lobby/visual/`) 도 deprecated 표식 | A mirror |
| 1.4 | `docs/1. Product/visual/README.md` 에 "정본은 `Prototype/originals/`. 본 폴더의 HTML 은 deprecated 참조" 명시 | 인덱스 |

**브랜드 결정 진입점 (사용자 결정 #1)**:

> **Lobby 브랜드 충돌**: 정본 = "WPS · EU 2026" (World Poker Series). docs/ mockup 및 PRD = "WSOP / WSOP Europe / WSOP Circuit".
> 
> 본 cycle 자율 영역으로 결정 가능한 사실: 두 표현은 명백히 다른 브랜드. 이건 비즈니스 의미 차원이므로 사용자 결정 영역.
> 
> 옵션 (사용자에게 제시):
> - **(a)** 정본 따라 모든 docs/구현 = "WPS" 통일 (PRD + Flutter seed data + breadcrumb 모두 정정)
> - **(b)** 정본을 "WSOP" 로 다시 작성해 달라고 사용자에게 요청 (정본 자체 변경 = Claude 자율 불가, 사용자만 가능)
> - **(c)** 둘 다 허용 (정본은 "WPS" 데모, 실제 PRD/Flutter 는 "WSOP" — 브랜드 무관 운영 구조 의도)

**검증**:
- A, B (+ mirror) 모두 deprecated 표식
- README.md 가 정본 우선 명시
- 사용자 결정 #1 응답 후 Phase 2 진입

### 5.3 Phase 2: Flutter **UI/UX** 정합 (C, D) — v2

**목표**: Flutter UI/UX 정합도 ≥ 95% (시각·레이아웃·토큰만). **기능/기술 항목은 절대 변경 안 함.**

**서브-Phase 2A — Lobby UI (team1)** — 시각 항목만:

| # | 액션 | 카테고리 |
|---|------|:--------:|
| 2A.v1 | TopBar 4-cluster (Show/Flight/Level/Next) 시각 레이아웃 정본 매칭 | 레이아웃 |
| 2A.v2 | TopBar 우측 Active CC pill + clock + user-pill **시각 디자인** (기능 X) | 컴포넌트 |
| 2A.v3 | Rail 3-section (Navigate/WPS·EU 2026/Tools) + 8 RailItem 시각 (icon+label+badge) | 레이아웃 |
| 2A.v4 | Breadcrumb chev-separator + 다단 trail 디자인 | 컴포넌트 |
| 2A.v5 | KPI strip 5-card 일관 패턴 (모든 화면 동일 구조) | 레이아웃 |
| 2A.v6 | Series 카드 (scard) — banner accent (OKLCH per series) + body + foot | 컴포넌트 |
| 2A.v7 | Events dtable (featured 행 golden + 5-status badge + EBS-only 컬럼 hide) | 컴포넌트 |
| 2A.v8 | Flights dtable + kpi-strip | 컴포넌트 |
| 2A.v9 | Tables 화면 — 9-seat 한 줄 + seg control (Grid/Floor Map/CC Focus) + levels-strip + waitlist drawer | 레이아웃 |
| 2A.v10 | Players dtable (chipsbar 시각화 + flag-chip + state-pill + VPIP/PFR/AGR mono) | 컴포넌트 |
| 2A.v11 | Hand History split layout (list + detail pane) | 레이아웃 |
| 2A.v12 | Login screen card (E brand mark + Entra ID 버튼 + Keep signed in) | 컴포넌트 |
| 2A.v13 | Launch CC modal **시각 디자인** (sheet-bg + sheet + kpi-strip + foot buttons) — 기능 X | 모달 |
| 2A.v14 | Status badge 5종 (running/registering/announced/completed/created) — 시각 색·dot | 컴포넌트 |
| 2A.v15 | seat states 시각 (s-a/e/r/d/w 색·라벨) | 컴포넌트 |

**서브-Phase 2B — CC UI (team4)** — 시각 항목만:

| # | 액션 | 카테고리 |
|---|------|:--------:|
| 2B.v1 | 1600×900 design canvas + scale-fit (transform scale) | 레이아웃 |
| 2B.v2 | StatusBar 3-zone (left: BO/RFID/Engine dots + Op + Table / center: Hand# + Phase + Game+Blinds / right: Players + icons) — **시각만** | 레이아웃 |
| 2B.v3 | TopStrip 3-zone (MiniDiagram + community board + acting/phase indicator) | 레이아웃 |
| 2B.v4 | **PlayerGrid 1×10 horizontal** + PlayerColumn 7-row (Status strip / Seat# / PosBlock / Country·Name / HoleCards / Stack / Bet / LastAction) | **레이아웃 핵심** |
| 2B.v5 | PosBlock 3 stacked rows (STRADDLE / SB·BB / D + ‹/› arrows) — **시각만** | 컴포넌트 |
| 2B.v6 | ActionPanel 3-zone (left: layout switcher + Undo + Miss Deal / center: FOLD/CHECK·CALL/BET·RAISE/ALL-IN / right: START/FINISH HAND) — **시각만** | 레이아웃 |
| 2B.v7 | CardPicker 모달 시각 (52 카드 grid + dealt-key tracking 색) — **시각만** | 모달 |
| 2B.v8 | Numpad 시각 (BET/RAISE amount 입력 패드) — **시각만** | 모달 |
| 2B.v9 | MissDealModal 시각 (pot + handNumber + phase 표시 + confirm/cancel) — **시각만** | 모달 |
| 2B.v10 | FieldEditor 시각 (모든 필드 통합 편집 모달 디자인) — **시각만** | 모달 |
| 2B.v11 | Engine state banner 시각 (online/degraded/offline + Reconnect button) — **시각만** | 컴포넌트 |
| 2B.v12 | Action-on glow ring (--glow-action: accent + accent-soft halo) | 시각 효과 |
| 2B.v13 | Folded opacity (0.35), Acting border, Bet badge, Fold badge, AllIn badge | 시각 상태 |
| 2B.v14 | Hand FSM phase **시각 표시** (StatusBar 의 "PRE FLOP" 라벨 색·강조) — **로직 X** | 시각 |
| 2B.v15 | Kbd-hint bar (N/F/C/B/A/M 시각 안내 — 실제 동작은 현재 Flutter 단축키 유지) | 시각 |

**원칙 (자율 결정)**:
- **시각 (CSS / Color / spacing / layout / shadow / typography)** = 본 cycle 자율 수정
- **로직 (provider / handler / FSM / 통신)** = 절대 미수정
- 시각 변경이 로직 수정 없이 불가능한 경우 → 본 cycle out-of-scope 로 분리, SG ticket 만 발행

**산출물**: SG ticket → Conductor_Backlog 등재. 실제 시각 PR 은 별도 cycle (사용자 결정 #2 후).

### 5.4 Phase 3: 디자인 토큰 통일

**목표**: 정본 OKLCH + Inter + JetBrains Mono 를 Flutter ThemeData 로 매핑.

**액션**:

| # | 액션 | 산출물 |
|---|------|--------|
| 3.1 | 정본 tokens.css 의 모든 변수를 Flutter Color/TextStyle 로 1:1 매핑 표 | `docs/2. Development/2.5 Shared/design_tokens_mapping.md` |
| 3.2 | OKLCH → sRGB 변환 (Flutter 가 OKLCH 직접 지원 X) | 변환 표 + 정확도 검증 |
| 3.3 | Inter + JetBrains Mono 폰트 자산을 `team1-frontend/assets/fonts/` + `team4-cc/src/assets/fonts/` 에 등록 | pubspec.yaml + 폰트 파일 |
| 3.4 | Flutter ThemeData 의 ColorScheme + TextTheme 정본 토큰 반영 | theme.dart 정정 PR |
| 3.5 | 의미 색 (--ok/--warn/--err/--info, --pos-d/sb/bb) → semantic Flutter color 매핑 | semantic_colors.dart |

**위험 + 완화**:
- OKLCH → sRGB 변환 오차: hue 변경 시 시각 차이 — 정본 hue 65 (broadcast amber) / 165 (felt green) 기준점 고정. 사용자 시각 검증 항목 포함.

**검증**:
- design_tokens_mapping.md 가 정본 tokens.css 의 모든 변수 매핑
- Flutter 화면 캡처 ↔ 정본 캡처 ΔE < 5 (색차 기준)

### 5.5 Phase 4: 검증 + 인계 reference 작성

**목표**: 정본 ↔ Flutter 1:1 매핑 reference 문서 + e2e 검증.

**액션**:

| # | 액션 | 산출물 |
|---|------|--------|
| 4.1 | 정본 컴포넌트 ↔ Flutter widget 1:1 매핑 표 (외부 인계용) | `docs/1. Product/Prototype/component_mapping_reference.md` |
| 4.2 | 정본 화면 ↔ Flutter route 1:1 매핑 | screens_mapping.md |
| 4.3 | 정본 인터랙션 ↔ Flutter provider/event 1:1 매핑 | interactions_mapping.md |
| 4.4 | 정본 데이터 모델 ↔ Flutter entity 1:1 매핑 | data_models_mapping.md |
| 4.5 | Playwright e2e 시나리오 (정본 흐름 기반) — Phase 2 정정 후 통과 확인 | integration-tests/playwright/scenarios/ |
| 4.6 | 본 Renewal Plan 의 `status: DRAFT` → `status: APPROVED` 갱신 | frontmatter 정정 |

**사용자 결정 진입점 #2 (Phase 4 종료 시점)**:

> 모든 매핑 reference 작성 + e2e 통과 후, 사용자에게 단일 PR (또는 PR set) 제시 → 최종 승인 → 머지.

**검증**:
- 1:1 매핑 표 모든 칸이 채워짐 (정본 항목 누락 X)
- e2e 시나리오 ≥ 90% 통과
- 사용자 결정 #2 = "approve and merge" 한 번

---

## Part 6 — 영향 받는 파일 (전체 변경 범위)

### 6.1 신규 생성 (Phase 0)

```
   docs/1. Product/Prototype/
   ├── originals/
   │   ├── EBS Lobby (1).zip                    (정본 미러, git LFS)
   │   ├── EBS Command Center (2).zip           (정본 미러, git LFS)
   │   ├── _manifest.json                       (SHA256 + 메타)
   │   └── README.md                            (사용 규칙)
   ├── component_mapping_reference.md           (Phase 4)
   ├── screens_mapping.md                       (Phase 4)
   ├── interactions_mapping.md                  (Phase 4)
   └── data_models_mapping.md                   (Phase 4)
   
   docs/2. Development/2.5 Shared/
   └── design_tokens_mapping.md                 (Phase 3)
```

### 6.2 수정 (Edit, additive only) — v2 UI/UX 한정

| 파일 | 변경 | Phase | 카테고리 |
|------|------|:-----:|:--------:|
| `.gitattributes` | `*.zip filter=lfs ...` 추가 | 0 ✅ | SSOT |
| `.gitignore` | `work/prototype-audit/` 명시 | 0 ✅ | SSOT |
| `docs/1. Product/visual/ebs-lobby-mockup.html` | frontmatter `status: deprecated` + 정본 링크 | 1 | 메타 |
| `docs/1. Product/References/foundation-visual/cc-mockup.html` | 동일 | 1 | 메타 |
| `docs/2. Development/2.1 Frontend/Lobby/visual/ebs-lobby-mockup.html` (mirror) | 동일 | 1 | 메타 |
| `docs/1. Product/visual/README.md` (없으면 생성) | 정본 우선 명시 | 1 | 메타 |
| `team1-frontend/lib/foundation/theme.dart` (또는 ThemeData 위치) | OKLCH → sRGB ColorScheme + Inter/JBMono TextTheme | 3 | **시각** |
| `team1-frontend/pubspec.yaml` | Inter + JetBrains Mono 폰트 등록 | 3 | **시각** |
| `team1-frontend/assets/fonts/` | Inter + JetBrains Mono 폰트 파일 | 3 | **시각** |
| `team1-frontend/lib/features/lobby/widgets/lobby_shell.dart` | TopBar 4-cluster + Rail 3-section 시각 (기능 미수정) | 2A | **시각** |
| `team1-frontend/lib/features/lobby/widgets/lobby_kpi_strip.dart` | 5-card 일관 패턴 시각 | 2A | **시각** |
| `team1-frontend/lib/features/lobby/widgets/lobby_status_badge.dart` | 5-status badge 시각 (dot + label) | 2A | **시각** |
| `team1-frontend/lib/features/lobby/widgets/seat_grid.dart` | 9-seat 한 줄 + s-a/e/r/d/w 시각 | 2A | **시각** |
| `team1-frontend/lib/features/lobby/widgets/waitlist_drawer.dart` | wl-row 시각 (drag hint) | 2A | **시각** |
| `team1-frontend/lib/features/lobby/screens/series_screen.dart` | scard banner (OKLCH per series accent) | 2A | **시각** |
| `team1-frontend/lib/features/lobby/screens/lobby_events_screen.dart` | dtable + tabs + featured row | 2A | **시각** |
| `team1-frontend/lib/features/lobby/screens/lobby_players_screen.dart` | chipsbar + flag-chip + state-pill | 2A | **시각** |
| `team4-cc/src/lib/foundation/theme.dart` (또는 ThemeData 위치) | 동일 OKLCH 매핑 + 폰트 | 3 | **시각** |
| `team4-cc/src/pubspec.yaml` | Inter + JetBrains Mono 등록 | 3 | **시각** |
| `team4-cc/src/assets/fonts/` | 폰트 파일 | 3 | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/seat_cell.dart` | **PlayerColumn 7-row 시각 재구성** (기능 미수정) | 2B | **시각 핵심** |
| `team4-cc/src/lib/features/command_center/widgets/cc_status_bar.dart` | StatusBar 3-zone 시각 | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/action_panel.dart` | 3-zone + 4 액션 + lifecycle 버튼 시각 (기능 미수정) | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/mini_table_diagram.dart` | TopStrip 좌측 시각 정합 | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/keyboard_hint_bar.dart` | N/F/C/B/A/M 시각 안내 (실제 단축키는 NG9) | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/miss_deal_modal.dart` | 모달 시각 디자인 (기능 미수정) | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/engine_connection_banner.dart` | 배너 시각 + Reconnect 버튼 디자인 | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/screens/at_03_card_selector.dart` | CardPicker 52-card grid 시각 | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/screens/at_07_player_edit_modal.dart` | FieldEditor 모달 시각 | 2B | **시각** |
| `team4-cc/src/lib/features/command_center/screens/at_01_main_screen.dart` | 1600×900 scale-fit canvas + PlayerGrid 1×10 + TopStrip + ActionPanel 배치 | 2B | **시각** |
| `docs/1. Product/Prototype/component_visual_mapping.md` (신규) | 시각 1:1 매핑 reference | 4 | 인계 |
| `docs/2. Development/2.5 Shared/design_tokens_mapping.md` (신규) | OKLCH ↔ Flutter Color 매핑 | 3 | **시각** |
| 본 Renewal Plan 자체 | `status: DRAFT → APPROVED` | 4 | 운영 |

### 6.2b **수정하지 않는** Flutter 파일 (v2 사용자 명시 NG7)

| 파일 | 이유 |
|------|------|
| `team*/lib/features/**/providers/*.dart` | Riverpod 상태 관리 (NG7 기술) |
| `team*/lib/features/**/services/*.dart` | 비즈니스 로직 (NG7 기능) |
| `team4-cc/src/lib/features/command_center/services/keyboard_shortcut_handler.dart` | 키보드 매핑 (NG9 기능) |
| `team4-cc/src/lib/features/command_center/services/multi_table_manager.dart` | 멀티 테이블 로직 (NG7) |
| `team4-cc/src/lib/features/command_center/services/stub_engine.dart` | 엔진 로직 (NG7) |
| `team4-cc/src/lib/features/overlay/**` | 출력 layer (NG12) |
| `team4-cc/src/lib/features/command_center/providers/hand_fsm_provider.dart` | Hand FSM (NG8) |
| `team4-cc/src/lib/features/command_center/providers/seat_provider.dart` | seat.sync (NG10) |
| `team*/lib/data/**`, `team*/lib/models/**`, `team*/lib/repositories/**` | 데이터 / 모델 (NG7) |
| `team*/lib/rfid/**` | RFID 통신 (NG7) |
| `team2-backend/**` | 백엔드 (NG7) |
| `team3-engine/**` | 게임 엔진 (NG7) |

### 6.3 수정 안 함 (불변)

| 파일 | 이유 |
|------|------|
| 정본 ZIP (`Downloads/`, `originals/`) | 정본 자체 — 사용자만 수정 가능 |
| 옛 mockup HTML A, B 의 본문 내용 | "Removal ≠ Answer" — 메타데이터만 추가 |
| docs/_archive/ | 폐기 보존 영역 |
| memory/ MEMORY.md 본문 (이미 인덱스 추가됨) | Phase 0 완료 |

### 6.4 SG ticket 발행 예상 (Phase 2) — v2 UI/UX-only

| SG # | 내용 | 우선순위 |
|------|------|:--------:|
| SG-renewal-ui-01 | Flutter CC **PlayerColumn 1×10 + 7-row** 시각 재구현 (seat_cell 변경) | **P0** |
| SG-renewal-ui-02 | OKLCH → Flutter Color sRGB 매핑 (전 토큰) | **P0** |
| SG-renewal-ui-03 | Inter + JetBrains Mono 폰트 등록 (C + D) | **P0** |
| SG-renewal-ui-04 | Flutter CC 1600×900 scale-fit canvas | P1 |
| SG-renewal-ui-05 | Flutter Lobby TopBar + Rail + Breadcrumb 시각 정합 | P1 |
| SG-renewal-ui-06 | Flutter Lobby KPI strip 5-card 일관 패턴 | P1 |
| SG-renewal-ui-07 | Flutter Lobby Series scard (OKLCH banner) | P1 |
| SG-renewal-ui-08 | Flutter Lobby dtable (featured + status badge + EBS-only cols) | P1 |
| SG-renewal-ui-09 | Flutter Lobby Tables 9-seat row + seg control + waitlist drawer | P1 |
| SG-renewal-ui-10 | Flutter CC ActionPanel 3-zone 시각 | P1 |
| SG-renewal-ui-11 | Flutter CC StatusBar 3-zone 시각 | P1 |
| SG-renewal-ui-12 | Flutter CC TopStrip (MiniDiagram + board + acting indicator) | P1 |
| SG-renewal-ui-13 | Flutter CC 4 모달 시각 (CardPicker / Numpad / MissDeal / FieldEditor) | P2 |
| SG-renewal-ui-14 | Engine state banner + glow-action ring + acting border | P2 |
| SG-renewal-ui-15 | seat states (s-a/e/r/d/w) + cc-cell + rfid-cell 시각 | P2 |
| SG-renewal-ui-16 | 시각 회귀 스냅샷 테스트 인프라 (Playwright + golden file) | P2 |
| SG-renewal-ui-17 | 시각 1:1 매핑 reference 문서 (component_visual_mapping.md) | P2 |

---

## Part 7 — 위험 + 완화

| 위험 | 발생 가능성 | 영향 | 완화 |
|------|:----------:|:----:|------|
| 정본 ZIP 사용자가 향후 갱신 | 중간 | SHA256 mismatch | manifest 의 SHA 와 비교 → 자동 감지 + 사용자 확인 |
| git LFS 미사용 환경 | 낮음 | ZIP push 실패 | LFS 설치 안내 + 대안으로 `_manifest.json` 만 추적 |
| OKLCH → sRGB 변환 오차 | 중간 | 시각 색차 | hue 65 / 165 기준점 고정 + ΔE 측정 + 사용자 시각 검증 |
| Flutter widget 1:1 매핑 시 빠지는 항목 | 중간 | 정합도 95% 미달 | gap-detector agent 자율 호출 — 누락 0 확인 |
| 사용자 브랜드 결정 #1 지연 | 중간 | Phase 1 종료 후 stall | Phase 0, 2-4 는 결정 독립적 — 병렬 진행 |
| Lobby 브랜드 c) 옵션 선택 시 정본·구현 분리 | 낮음 | 운영 혼란 | "브랜드 무관 운영 구조" 명시 — PRD 에 별도 섹션 |
| Flutter 정정 PR 이 너무 큼 | 높음 | 리뷰 어려움 | SG ticket 별 분할 PR (8 PR 권장) |
| 정본의 React 18 micro-version 변경 | 낮음 | dependency drift | unpkg URL 의 version pin = `react@18.3.1` (정본 entry HTML 명시) |
| LAN 호환 옵션 추가 시 정본 수정 위반 | 중간 | NG2 위반 | 별도 `originals-lan-bundle/` 폴더로 분리 (정본 ZIP 자체는 미변경) |

---

## Part 8 — 검증 기준 (Renewal 완료 판단)

본 리뉴얼이 완료되었다고 판단하는 객관적 기준 — **v2 UI/UX-only**:

| # | 기준 | 측정 방법 | 카테고리 |
|---|------|---------|:--------:|
| V1 | 정본 ZIP 이 git 추적 | `git ls-files docs/1. Product/Prototype/originals/*.zip` ✅ | SSOT |
| V2 | manifest SHA = 실제 SHA | 자동 hash 비교 ✅ | SSOT |
| V3 | docs/ mockup A, B 모두 deprecated 표식 | grep `status: deprecated` | 정리 |
| V4 | Flutter Lobby C **UI/UX** 정합 ≥ 95% | 시각 1:1 매핑 + 스크린샷 ΔE < 5 | **UI** |
| V5 | Flutter CC D **UI/UX** 정합 ≥ 95% | 시각 1:1 매핑 + 스크린샷 ΔE < 5 | **UI** |
| V6 | 디자인 토큰 ΔE < 5 | 정본 vs Flutter 캡처 색차 (OKLCH→sRGB) | **UI** |
| V7 | 시각 1:1 매핑 reference 문서 | `docs/1. Product/Prototype/component_visual_mapping.md` 존재 | **UI** |
| V8 | 시각 회귀 스냅샷 테스트 통과 ≥ 90% | Playwright golden file 결과 | **UI** |
| V9 | Phase 2 SG ticket 모두 closed | Conductor_Backlog 상태 | 운영 |
| V10 | 본 Plan status = APPROVED | frontmatter | 운영 |
| V11 | 사용자 결정 진입점 ≤ 2 회 | 본 cycle audit | 운영 |
| V12 | **기능/기술/데이터 모델 변경 = 0** | git diff (Phase 2 PR set) | **HARD CONSTRAINT** |

**V12 는 hard constraint**: 시각 PR 중 기능 코드 변경 발견 시 → 즉시 split (시각만 머지, 기능 변경은 별도 cycle).

→ **V1-V12 모두 PASS** = 리뉴얼 완료. V12 FAIL = 시각 PR 분리 강제. 다른 항목 FAIL = circuit breaker.

---

## Part 9 — Out of Scope (본 리뉴얼이 다루지 않는 영역)

| 영역 | 이유 | 후속 cycle |
|------|------|-----------|
| 정본 자체 React → Vue/Svelte 변환 | 정본 = 정본, 변환 불가 | — |
| 정본의 React 18 → 19 업그레이드 | 정본 자체 변경 금지 | 사용자 결정 영역 |
| Lobby 브랜드 (WPS vs WSOP) 통일 결정 | 비즈니스 의미 차원 | 사용자 결정 #1 답변 후 별도 PRD cycle |
| overlay/ 영역 (D 의 추가 기능) 정본화 | 정본 미정의 | 별도 정본 또는 spec cycle |
| graphic_editor / staff (C 의 추가 기능) 정본화 | 정본 미정의 | 별도 정본 또는 spec cycle |
| RFID 등록 화면 (D 의 at_05) 정본화 | 정본 미정의 | 별도 정본 또는 spec cycle |
| Multi-table manager (D) 정본화 | 정본 = 단일 테이블 | 정본 확장 PRD cycle |
| Settings 8 페이지 (C 확장) 정본 매핑 | 정본 = 단일 Settings | 별도 정본 확장 또는 단순화 결정 |
| 일정 / 예산 / MVP 우선순위 | 본 프로젝트 인텐트 범위 밖 | 오너 결정 |
| 시장 분석 / 출시 일정 | 본 프로젝트 인텐트 범위 밖 | — |

---

## Part 10 — 사용자 결정 영역 명세 (총 2 회)

본 리뉴얼 cycle 의 사용자 진입점은 **최소 0, 최대 2 회**.

### 결정 #1 (Phase 1 종료 시) — Lobby 브랜드 충돌

> **무엇이 문제인가**: 정본 = "WPS · EU 2026" (World Poker Series), docs/mockup + PRD = "WSOP" (World Series of Poker). 둘은 다른 브랜드.
>
> **사용자가 결정해야 하는 이유**: 비즈니스 의미 차원. Claude 자율 결정 불가 (본 프로젝트 인텐트 범위 밖).
>
> **옵션** (Claude 가 자율 추천 X, 사용자가 선택):

```
   (a) "정본 따라 모두 WPS 통일"
        ↳ docs/PRD/Flutter seed data/breadcrumb 모두 정정
        ↳ 가장 깔끔. 사용자 진입점 1회로 종료.
   
   (b) "정본을 WSOP 로 재작성"
        ↳ 사용자가 직접 정본 ZIP 갱신 (Claude 자율 불가, NG2 위반)
        ↳ 정본 갱신 후 본 cycle 재진입.
   
   (c) "브랜드 무관 운영 구조" (정본 = WPS 데모, PRD/구현 = WSOP 가능)
        ↳ "Lobby = 브랜드 가변 운영 도구" 라는 명시적 정책 추가
        ↳ PRD 에 "브랜드 매개변수화" 섹션 신규.
```

### 결정 #2 (Phase 4 종료 시) — 최종 승인

> 모든 매핑 reference + e2e 통과 + 정합도 95% 달성 후, 사용자에게 단일 PR(또는 PR set) 제시 → "approve and merge" 한 번.

### 결정 #1 응답이 없을 때

> Phase 0 ✅ 완료. Phase 1-4 의 거의 모든 시각 작업 (PlayerColumn, KPI strip, OKLCH 토큰, 폰트, dtable, 모달 등) 은 브랜드 무관 → 결정 독립적 자율 진행.
> 결정 #1 답변 후에만 진행되는 항목 = **Series scard 의 seed data 브랜드 표기 + Breadcrumb 의 "WPS · EU 2026" / "WSOP" 텍스트** 만.

---

## 부록 A — 정본 컴포넌트 ↔ Flutter widget 1:1 매핑 표 (초안)

### A.1 Lobby 매핑

| 정본 (React JSX) | Flutter widget (C) | 정합 상태 |
|------------------|-------------------|:---------:|
| `App` | `lobby_shell.dart` | ✅ (확인됨) |
| `TopBar` | `lobby_shell` 내부 또는 별도 widget | ⚠ 검증 필요 |
| `Rail` + `RailItem` | nav_provider + 사이드바 widget | ⚠ 검증 필요 |
| `Breadcrumb` | breadcrumb widget (확인 필요) | ⚠ |
| `LoginScreen` | `auth/screens/login_screen.dart` | ✅ |
| `SeriesScreen` | `lobby/screens/series_screen.dart` | ✅ |
| `EventsScreen` | `lobby/screens/lobby_events_screen.dart` | ✅ |
| `FlightsScreen` | `lobby/screens/lobby_flights_screen.dart` | ✅ |
| `TablesScreen` | `lobby/screens/lobby_tables_screen.dart` | ✅ |
| `PlayersScreen` | `lobby/screens/lobby_players_screen.dart` | ✅ |
| `HandHistoryScreen` | `hand_history/screens/hand_history_screen.dart` | ✅ |
| `AlertsScreen` | ❌ 별도 화면 미발견 (lobby_status_badge 통합?) | ❌ |
| `SettingsScreen` | `settings/screens/settings_layout.dart` (8 페이지로 확장) | ⚠ 정본 단일 vs 확장 결정 필요 |
| `TweaksPanel` | ❌ 미발견 | ❌ Phase 2A.2 |
| Launch CC Modal | `cc_session_provider` 와 매핑? | ⚠ Phase 2A.1 |
| `Badge` | `lobby_status_badge.dart` | ✅ |
| `Icon` | Flutter Icon (Material) | ⚠ 정본 라인 스트로크 vs Material 차이 |

### A.2 CC 매핑

| 정본 (React JSX) | Flutter widget (D) | 정합 상태 |
|------------------|-------------------|:---------:|
| `App` (1600×900 scale-fit) | `at_01_main_screen.dart` + scale-fit 매핑 필요 | ⚠ |
| `StatusBar` | `cc_status_bar.dart` | ✅ |
| `TopStrip` | (MiniDiagram + community board + acting indicator 통합) | ⚠ 검증 필요 |
| `MiniDiagram` | `mini_table_diagram.dart` | ✅ |
| `PlayerGrid` (1×10) | (10 seat_cell 의 horizontal grid?) | ⚠ Phase 2B.1 |
| **`PlayerColumn`** (7-row click-to-edit) | `seat_cell.dart` | ❌ 핵심 — Phase 2B.1 |
| `PosBlock` (STRADDLE/SB·BB/D) | `position_shift_chip.dart` | ⚠ 검증 필요 |
| `ActionPanel` | `action_panel.dart` | ✅ |
| `CardPicker` | `at_03_card_selector.dart` | ✅ |
| `Numpad` | (action_panel 통합?) | ⚠ 검증 필요 |
| `MissDealModal` | `miss_deal_modal.dart` | ✅ |
| `FieldEditor` (모든 필드 통합 모달) | `at_07_player_edit_modal.dart` (일부?) | ⚠ Phase 2B.5 |
| `TweaksPanel` | ❌ 미발견 | ❌ Phase 2B.7 |
| Keyboard hint bar | `keyboard_hint_bar.dart` | ✅ |
| Engine state banner | `engine_connection_banner.dart` | ✅ |

### A.3 정합 상태 범례

- ✅ = 직접 매핑 확인됨
- ⚠ = 매핑 가능성 있으나 spot-check 필요 (Phase 2 액션)
- ❌ = 매핑 부재 — 구현 또는 정본 추가 필요

---

## 부록 B — 사용 도구 + 자동화

| 도구 | 용도 | Phase |
|------|------|:-----:|
| `tools/doc_discovery.py --impact-of` | 영향 파일 추출 | 모든 |
| `tools/spec_drift_check.py --all` | 코드 ↔ 정본 drift 자동 감지 | 2 |
| `tools/reimplementability_audit.py` | PRD frontmatter 정합 | 1, 4 |
| `tools/contract_drift_audit.py` | API 경로 정합 | 2A |
| Playwright (`integration-tests/playwright/`) | e2e 검증 | 4 |
| `gap-detector` agent | 정합도 측정 (95% 기준) | 4 |
| `architect` agent | PR 최종 검토 (사용자 결정 #2 전) | 4 |
| `code-reviewer` agent | 정정 PR 품질 검토 | 2, 3 |
| `verifier` agent | e2e fresh evidence | 4 |
| `iteration-spec-validator` | reimplementability + drift 통합 score | 4 |

---

## 부록 C — 자가 점검 체크리스트

| 항목 | 상태 |
|------|:----:|
| frontmatter (provenance / source_audit / memory_link) 완전 | ✅ |
| 한 줄 요약 + 비유 + 메트릭 표 | ✅ |
| Part 1-10 + 부록 A-C 모두 작성 | ✅ |
| ASCII 다이어그램 ≥ 2 곳 | ✅ (3 곳) |
| Goals / Non-Goals 분리 | ✅ |
| 정본 SSOT 권한 명시 | ✅ |
| Phase 별 자율 vs 사용자 결정 분리 | ✅ |
| 사용자 결정 진입점 ≤ 2 회 명시 | ✅ |
| 영향 받는 파일 (신규/수정/불변) 분리 | ✅ |
| SG ticket 발행 예상 명시 | ✅ |
| 위험 + 완화 표 | ✅ |
| 검증 기준 V1-V11 측정 가능 | ✅ |
| Out of scope 명시 | ✅ |
| 1:1 매핑 표 초안 (부록 A) | ✅ |
| 자동화 도구 매핑 (부록 B) | ✅ |
| 추측 금지 (구현 안 된 기능 가정 X) | ✅ |
| "확인 필요" 항목 명시 (gap-audit 보고서 미검증 항목 인정) | ✅ |

---

## 메타 정보

- **본 리뉴얼 기획 작성 일자**: 2026-05-15
- **선행 보고서**: [Gap Audit 보고서](../Reports/2026-05-15-prototype-accurate-original-gap-audit.md)
- **정본 SSOT 메모리**: `prototype_accurate_original_2026_05_15.md`
- **본 Plan 의 위상**: PRD 와 운영 Plan 의 중간. Renewal 의 거버넌스 문서.
- **본 Plan 의 status flow**: DRAFT → (사용자 결정 #1 응답) → IN_PROGRESS → (Phase 4 완료) → APPROVED
- **본 Plan 의 영구 보존**: `docs/4. Operations/Plans/` 영구 보관. Phase 별 진행 시 본 Plan 갱신 (status + 진행 표).


