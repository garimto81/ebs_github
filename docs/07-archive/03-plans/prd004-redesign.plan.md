# PRD-0004 전면 재설계 계획

**Plan ID**: prd004-redesign
**Created**: 2026-02-18
**Target**: `docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` (v13.0 → v14.0)

## 목표

PRD-0004-EBS-Server-UI-Design.md를 **"원본 PokerGFX → 오버레이 분석 → EBS 설계"** 의 3단계 내러티브 흐름으로 전면 재구성한다.

현재 PRD-0004는 "결과물(EBS 설계)"만 보여주고, PokerGFX-UI-Analysis.md는 "분석"만 보여준다. 두 문서의 인과관계가 단절되어 있다.

재설계 후에는 **단일 문서** 안에서 화면별로 "무엇을 보았고 → 무엇을 발견했고 → 어떻게 설계했는지"가 자연스럽게 흐른다.

## 재설계 원칙

1. **내러티브 우선**: 각 화면 챕터는 "원본 → 분석 → 설계"의 자연스러운 이야기 구조를 따른다
2. **데이터 무손실**: 기존 PRD-0004의 184개 Element Catalog, Feature Mapping, Interaction Patterns 등 모든 스펙 데이터를 그대로 유지한다
3. **이미지 3종 세트**: 각 화면마다 원본 스크린샷, 오버레이 분석, EBS 목업 3개 이미지를 순서대로 배치한다
4. **변환 근거 명시**: "PokerGFX #N → EBS X-NN" 매핑으로 분석 요소가 어떻게 설계 요소로 전환되었는지 추적 가능하게 한다
5. **PokerGFX-UI-Analysis.md는 독립 유지**: 분석 문서는 그대로 남기되, PRD-0004가 분석 내용을 내부에 통합 서술한다

## 신규 문서 구조

### 프롤로그 (신규)

```
1장: 이 문서의 목적과 읽는 법
  - 3단계 접근법 설명 (원본 관찰 → 체계적 분석 → 설계 반영)
  - 이미지 범례 (원본 스크린샷, 번호 오버레이, EBS 목업)
  - PokerGFX Server 3.111 소개 (분석 대상)
```

### 1장: 전체 화면 구조 (기존 유지 + 보강)

```
1장: 전체 화면 구조
  1.1 PokerGFX 화면 구조 (원본에서 관찰한 것)
    - 7탭 구조, 2-column 레이아웃
    - 요소 총 268개 (11개 화면)
  1.2 EBS 화면 구조 (분석에서 도출한 설계)
    - 5탭 + GFX 4서브탭 구조 (Commentary 배제, GFX 1/2/3 통합)
    - 요소 총 184개 (11개 화면)
    - 네비게이션 맵 (mermaid)
  1.3 구조 변환 요약표
    - PokerGFX 화면 → EBS 화면 매핑
    - 요소 수 변화 + 변환 이유
  1.4 설계 원칙 (기존 유지)
  1.5 설계 기초 (기존 유지: 시간 모델, 주의력 분배, 자동화 그래디언트)
  1.6 공통 레이아웃 (기존 유지)
```

### 2~9장: 화면별 챕터 (핵심 변경)

**각 챕터의 통일 구조:**

```
N장: [화면명]

  N.1 PokerGFX 원본
    - 원본 스크린샷 이미지
    - 이 화면이 PokerGFX에서 하는 역할 (1~2줄)

  N.2 분석
    - 오버레이 이미지 (번호 박스)
    - 분석 테이블 (PokerGFX-UI-Analysis.md에서 가져온 기능 테이블)
    - 설계 시사점 (분석에서 발견한 핵심 인사이트)

  N.3 EBS 설계
    - EBS 목업 이미지
    - 변환 요약 (PokerGFX 요소 N개 → EBS 요소 M개, 주요 변경 사항)
    - Design Decisions (기존 유지)
    - Workflow (기존 유지, mermaid)
    - Element Catalog (기존 유지, 전체 테이블)
    - Interaction Patterns (기존 유지)
    - Navigation (기존 유지)
```

### 화면별 이미지 매핑 (정확한 파일 경로)

| 화면 | 원본 스크린샷 | 오버레이 | EBS 목업 |
|------|-------------|---------|----------|
| Main Window | `../../images/pokerGFX/스크린샷 2026-02-05 180630.png` | `02_Annotated_ngd/01-main-window.png` | `images/mockups/ebs-main.png` |
| Sources | `../../images/pokerGFX/스크린샷 2026-02-05 180637.png` | `02_Annotated_ngd/02-sources-tab.png` | `images/mockups/ebs-sources.png` |
| Outputs | `../../images/pokerGFX/스크린샷 2026-02-05 180645.png` | `02_Annotated_ngd/03-outputs-tab.png` | `images/mockups/ebs-outputs.png` |
| GFX 1 → Layout | `../../images/pokerGFX/스크린샷 2026-02-05 180649.png` | `02_Annotated_ngd/04-gfx1-tab.png` | `images/mockups/ebs-gfx-layout.png` |
| GFX 2 → Visual+Display | `../../images/pokerGFX/스크린샷 2026-02-05 180652.png` | `02_Annotated_ngd/05-gfx2-tab.png` | `images/mockups/ebs-gfx-visual.png` + `ebs-gfx-display.png` |
| GFX 3 → Numbers | `../../images/pokerGFX/스크린샷 2026-02-05 180655.png` | `02_Annotated_ngd/06-gfx3-tab.png` | `images/mockups/ebs-gfx-numbers.png` |
| Commentary (배제) | `../../images/pokerGFX/스크린샷 2026-02-05 180659.png` | `02_Annotated_ngd/07-commentary-tab.png` | 없음 (배제) |
| Rules | 없음 (PokerGFX에 독립 Rules 탭 없음, GFX 2의 일부) | 없음 | `images/mockups/ebs-rules.png` |
| System | `../../images/pokerGFX/스크린샷 2026-02-05 180624.png` | `02_Annotated_ngd/08-system-tab.png` | `images/mockups/ebs-system.png` |
| Skin Editor | `../../images/pokerGFX/스크린샷 2026-02-05 180715.png` | `02_Annotated_ngd/09-skin-editor.png` | `images/mockups/ebs-skin-editor.png` |
| Graphic Editor (Board) | `../../images/pokerGFX/스크린샷 2026-02-05 180720.png` | `02_Annotated_ngd/10-graphic-editor-board.png` | `images/mockups/ebs-graphic-editor.png` |
| Graphic Editor (Player) | `../../images/pokerGFX/스크린샷 2026-02-05 180728.png` | `02_Annotated_ngd/11-graphic-editor-player.png` | `images/mockups/ebs-graphic-editor.png` |

### GFX 탭 특수 처리 (가장 복잡한 변환)

GFX 1/2/3 → Layout/Visual/Display/Numbers 재편은 단일 챕터가 아닌 **5장 GFX 탭** 내에서 서술:

```
5장: GFX 탭 (4개 서브탭)

  5.1 PokerGFX의 GFX 1/2/3 원본
    - GFX 1 원본 스크린샷 + 오버레이 (29개 요소)
    - GFX 2 원본 스크린샷 + 오버레이 (21개 요소)
    - GFX 3 원본 스크린샷 + 오버레이 (23개 요소)
    - 총 73개 요소의 기능적 분류 문제점

  5.2 분석: 기능 추가의 산물 → 기능적 분류로 재편
    - GFX 1/2/3은 기능이 추가되면서 자연 발생한 구조
    - 기능적 분류: "어디에(Layout) → 어떤 연출로(Visual) → 무엇을(Display) → 어떤 형식으로(Numbers)"
    - 73개 → 51개로 정리 (중복 제거, 배제, 통합)

  5.3 EBS GFX 설계 개요
    - 4서브탭 구조 다이어그램
    - 변환 매핑 테이블

  5.4 Layout 서브탭 (기존 유지)
  5.5 Visual 서브탭 (기존 유지)
  5.6 Display 서브탭 (기존 유지)
  5.7 Numbers 서브탭 (기존 유지)
  ...
```

### Commentary 배제 서술

```
별도 섹션 (1장 내 또는 부록):
  - Commentary 원본 스크린샷 + 오버레이 (8개 요소)
  - 배제 결정 이유: 기존 프로덕션에서 사용하지 않는 기능
  - SV-021, SV-022 배제 → 149개 중 147개 커버 (98.7%)
```

### 10~11장 + 부록 (기존 유지)

10장 Action Tracker, 11장 시스템 상태 UI, 부록 A~E는 기존 그대로 유지한다. 이 영역은 분석→설계 내러티브와 직접 관련이 없는 시스템 레벨 스펙이다.

## 실행 전략

### 단계 1: 프롤로그 + 1장 작성
신규 프롤로그와 1장 구조 변환 요약 작성

### 단계 2: 2~4장 작성 (Main, Sources, Outputs)
직선적 매핑 (1:1 화면 대응)

### 단계 3: 5장 GFX 탭 작성
가장 복잡한 GFX 1/2/3 → Layout/Visual/Display/Numbers 재편 서술

### 단계 4: 6~9장 작성 (Rules, System, Skin, Graphic Editor)

### 단계 5: 10~11장 + 부록 (기존 이관)

### 단계 6: Commentary 배제 + 변경 이력

## 영향 파일

| 파일 | 변경 |
|------|------|
| `docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` | **전면 재작성** |
| `docs/01_PokerGFX_Analysis/PokerGFX-UI-Analysis.md` | 변경 없음 (독립 유지) |
| 이미지 파일 | 변경 없음 (참조만) |

## 위험 요소 + 대응 방안

1. **데이터 무손실 검증**
   - 위험: 184개 Element Catalog, 149개 Feature Mapping이 누락될 수 있음
   - 검증 방법: 재작성 완료 후 grep으로 Element ID 전수 확인
     - `grep -c "^| [A-Z]-" PRD-0004-EBS-Server-UI-Design.md` → 184개 이상
     - 기존 v13.0의 부록 C Feature Mapping 테이블을 신규 문서와 diff 대조
     - 화면별 Element Catalog 행 수를 부록 A 집계표와 크로스 체크
   - 완료 기준: 부록 A 집계표의 합계 = 184개, 부록 C 커버리지 = 147/149 (98.7%)

2. **이미지 경로 정확성**
   - 위험: 원본 스크린샷 파일명에 한글이 포함되어 URL 인코딩 필요
   - 대응: 모든 한글 스크린샷 경로에 `%20` URL 인코딩 적용 (기존 UI-Analysis.md 패턴 따름)

3. **문서 길이**
   - 위험: 분석 콘텐츠 통합으로 1000줄 → ~1400줄 예상
   - 대응: 분석 테이블은 핵심 컬럼만 포함 (원본 UI-Analysis.md의 전체 테이블이 아닌, 기능명+설명+EBS복제 3컬럼으로 축약). 상세 분석은 PokerGFX-UI-Analysis.md 링크로 참조

4. **Rules 탭 원본 부재**
   - 위험: PokerGFX에 독립 Rules 탭이 없어 원본→분석→설계 3단계 서술 불가
   - 대응: Rules 챕터에서 "GFX 2에서 규칙 요소를 분리한 경위" 서술. GFX 2 오버레이에서 해당 요소(#8~#14)를 참조

---

## 화면별 요소 증감 분석

### 요소 수 변화 요약표

| 화면 | PokerGFX 요소 수 | EBS 요소 수 | 증감 | 주요 변화 |
|------|:----------------:|:-----------:|:----:|----------|
| Main Window | 10 | 20 | +10 | Connection Status, Hand Counter, Delay Progress *(추후 개발)*, Quick Lock 신규 |
| Sources 탭 | 12 | 19 | +7 | Output Mode Selector 신규; Fill & Key 전용 설정 분리 |
| Outputs 탭 | 13 | 20 | +7 | Fill & Key Channel Map, Key Color, Fill/Key Preview 신규 |
| GFX 1 탭 | 29 | 13 (Layout) | -16 | Visual(12), Display(14), Numbers(12)로 분산 |
| GFX 2 탭 | 21 | 12 (Visual) + 14 (Display) | +5 | 게임 규칙 6개 → Rules 탭 독립 |
| GFX 3 탭 | 23 | 12 (Numbers) | -11 | 핵심 기능 유지, Strip eliminated 통합 |
| Commentary 탭 | 8 | 0 | -8 | **전체 배제** (EBS에서 사용 안 함) |
| System 탭 | 28 | 24 | -4 | 라이선스/Serial# 관련 4개 제거 |
| Skin Editor | 37 | 26 | -11 | 국기 관련 P2 통합; 핵심 기능 유지 |
| Graphic Editor (Board) | 39 | 18 (통합) | -21 | Board+Player 단일 에디터로 통합 |
| Graphic Editor (Player) | 48 | 8 (Player 전용) | -40 | 공유 기능 제거, Player 전용만 유지 |
| **합계** | **268** | **184** | **-84** | 논리적 재편으로 중복 제거 |

### GFX 1/2/3 → Layout/Visual/Display/Numbers 분류 상세

**GFX 1 (29개) 분류**:

| GFX 1 항목 (번호) | EBS 배치 | 이유 |
|-----------------|---------|------|
| Board Position (2), Player Layout (3) | Layout G-01, G-02 | 배치 결정 |
| Reveal Players (4), How to show Fold (5), Reveal Cards (6) | Visual G-14~G-16 | 연출 방식 |
| Leaderboard Position (7) | Layout G-06 | 배치 결정 |
| Transition In (8), Transition Out (9) | Visual G-17, G-18 | 연출 방식 |
| Heads Up Layout/Camera/Custom Y (10~12) | Layout G-07~G-09 | 배치 결정 |
| Skin Info/Editor/Media Folder (13~15) | Layout에 포함 | 스킨은 배치 레이어 |
| Sponsor Logo 3개, Vanity (16~19) | Layout G-10~G-13 | 배치 요소 |
| X/Top/Bot Margin (20~22) | Layout G-03~G-05 | 배치 파라미터 |
| Heads Up History (23), Indent/Bounce (24~25) | Visual G-19, G-20, G-25 | 연출 방식 |
| Show Leaderboard/PIP/Stats (26~28) | Visual G-22~G-24 | 핸드 후 연출 |
| Action Clock (29) | Visual G-21 | 시각 연출 |

**GFX 2 (21개) 분류**:

| GFX 2 항목 (번호) | EBS 배치 | 이유 |
|-----------------|---------|------|
| Show knockout rank (2), Chipcount% (3), Eliminated (4) | Display G-26~G-28 | 표시 내용 |
| Cumulative Winnings (5), Hide Leaderboard (6), Max BB (7) | Display G-29~G-31 | 표시 내용 |
| Move button Bomb Pot (8), Limit Raises (9) | Rules R-01, R-02 | 게임 규칙 |
| Straddle sleeper (10), Sleeper final action (11) | Rules R-04, R-05 | 게임 규칙 |
| Add seat # (12), Show as eliminated (13) | Display G-32, G-33 | 표시 내용 |
| Allow Rabbit Hunting (14) | Rules R-03 | 게임 규칙 |
| Unknown cards blink (15), Clear previous action (17) | Display G-34, G-35 | 표시 동작 |
| Hilite Nit game (16), Order players (18) | Display G-36, G-39 | 표시 순서/강조 |
| Show hand equities (19), Hilite winning hand (20) | Display G-37, G-38 | 표시 시점 |
| Ignore split pots (21) | Rules R-06 | 계산 규칙 |

---

## 화면별 내러티브 스크립트 (집행자 참조용)

### Main Window

- **원본**: Preview(좌) + 상태/버튼(우) 2-column. 10개 요소. CPU/GPU/Lock이 단일 행에 압축. RFID 상태가 시스템 행에 포함.
- **분석 인사이트**: RFID 상태(3번)가 CPU/GPU와 같은 행에 묻혀 있음. Lock 아이콘 존재감 약. 버튼 7개 우선순위 구분 없이 균등 노출.
- **EBS 변화**: 20개 확장. M-05 RFID Status 독립 분리. M-17 Hand Counter, M-18 Connection Status 신규. M-10 Delay Progress *(추후 개발)* 신규.

### Sources 탭

- **원본**: 12개 단일 스크롤. Fill & Key/Chroma Key/Internal 모드 구분 없음. ATEM 설정 항상 노출.
- **분석 인사이트**: External Switcher(10번)가 모드 무관 상시 노출 → 혼란. Chroma Key(7번)가 목록 중간 배치.
- **EBS 변화**: S-00 Output Mode Selector 최상단 추가. ATEM 설정은 Fill & Key 모드에서만 표시. 19개로 증가하나 조건부 표시로 인지 부하 감소.

### Outputs 탭

- **원본**: 13개. Live/Delay 2열 구조 직관적. Fill & Key DeckLink 포트 매핑 불명확. Secure Delay 단순 숫자 입력. (Delay 열은 추후 개발)
- **분석 인사이트**: Key & Fill(4~5번)의 DeckLink 포트 할당 상세 부재. 2열 구조 EBS 계승 가치 있음.
- **EBS 변화**: O-18~O-20 Fill & Key 전용 섹션 신규. 기존 2열 구조 유지. 20개로 확장.

### GFX 탭 (핵심 재편)

- **GFX 1 원본**: 29개. 레이아웃(2~3번) + 연출(4~6번) + Transition + 스킨 + 스폰서 + 마진 + 핸드 후 표시 혼재.
- **GFX 2 원본**: 21개. 리더보드 + 게임 규칙(8~11, 14, 21번) + 표시 설정 혼재.
- **GFX 3 원본**: 23개. 수치 형식 위주. 가장 응집도 높음.
- **재편 원칙**: "어디에(Layout) → 어떻게(Visual) → 무엇을(Display) → 어떤 형식으로(Numbers)"
- **EBS 변화**: 73개 → 51개 + Rules 6개. 논리적 작업 흐름 기반 재편.

### Commentary (배제)

- **원본**: 8개. 원격 해설자 접속, 인증, PIP, 통계 전용.
- **EBS 배제 이유**: EBS는 이 워크플로우를 사용하지 않음. 기술 한계가 아닌 운영 결정. 향후 Phase에서 필요 시 추가 가능.
- **문서 처리**: 배제 챕터로 기록 (완전 삭제 아님). SV-021, SV-022 배제 = 147/149 (98.7%) 커버.

### System 탭

- **원본**: 28개. RFID 안테나 3종(22~24번)이 하단. 라이선스 관련 4개(6~9번) 포함.
- **분석 인사이트**: RFID 안테나가 하단이나 실제 준비 첫 번째 설정. 라이선스 항목 EBS 불필요.
- **EBS 변화**: RFID 상단 이동(Y-03~Y-07). 라이선스 4개 제거. AT 접근 정책 독립 그룹(Y-13~Y-15). 24개.

### Skin Editor

- **원본**: 37개. 별도 창. 국기 3개(24~26번)가 카드/플레이어 설정 사이에 끼어 흐름 단절.
- **EBS 변화**: 26개. 국기 P2 통합. 에디터 계층 (GFX → Skin → Graphic) 명시.

### Graphic Editor

- **원본**: Board(39개) + Player(48개) = 87개. 공통 기능(Position/Animation/Text/Background) 60% 이상 중복.
- **EBS 변화**: 단일 에디터 통합 (Board↔Player 모드 전환). 공통(10개) + Player 전용(8개) = 18개.

---

## 완료 기준

- [ ] 프롤로그 추가 (3단계 접근법 설명, 이미지 범례)
- [ ] 1장 1.6 신규 섹션: 전체 재편 요약 (탭 변화 표, GFX 재편 원칙, Commentary 배제)
- [ ] 2~9장 각 챕터 앞: "N.1 PokerGFX 원본" + "N.2 분석" 섹션 추가
- [ ] 5장 GFX: GFX 1/2/3 원본 각각 서술 + 재편 내러티브
- [ ] Commentary 배제 챕터 추가 (원본+오버레이 이미지 + 배제 근거)
- [ ] 기존 Element Catalog 184개 전체 유지 확인
- [ ] 버전 v14.0.0, last_updated 업데이트
- [ ] 변경 이력 최하단 추가
