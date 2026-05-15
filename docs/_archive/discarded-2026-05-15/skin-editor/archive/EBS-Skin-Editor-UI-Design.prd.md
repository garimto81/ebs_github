---
doc_type: "prd"
doc_id: "PRD-SE-UID-001"
version: "1.1.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-23"
depends_on:
  - "PRD-0006: pokergfx-vs-ebs-skin-editor.prd.md (SE/GE 설계 정본)"
  - "PRD-0007-S2: ebs-ui-design-strategy.md (5대 설계 원칙)"
  - "PRD-CMDS-001: prd-compact-mockup-design-system.prd.md (720×480 디자인 시스템)"
discarded: "2026-05-15: absorbed into Lobby Settings"
---

# EBS Skin Editor — UI Design PRD

> **이 문서의 목적**: EBS Skin Editor의 완성된 UI 설계를 **비개발자/기획자 관점**에서 10장 구조로 설명한다.
> 1~7장은 개념/원칙, **8~10장은 실제 화면 본론**(SE 메인, GE 8종, 설계 결정)이다.

---

## 1장. 왜 Skin Editor가 필요한가

### PokerGFX — 업계 표준 벤치마크

PokerGFX는 북미 포커 방송의 사실상 표준이다. Skin Editor, Graphic Editor, Console을 갖춘 완성도 높은 소프트웨어이며, 대부분의 메이저 대회가 이 도구로 방송을 제작한다.

### 내재화 전략 — "같은 걸 우리 것으로"

EBS Skin Editor는 PokerGFX를 **대체**하려는 것이 아니라 **내재화**하려는 프로젝트다.

| 단계 | 목표 | 설명 |
|------|------|------|
| **1단계: 복제** | 기능 동등성 확인 | PokerGFX SE의 기능을 어디까지 동일하게 구현할 수 있는지 검증 |
| **2단계: 적용** | 우리 톤앤매너 | 복제 완료 후, WSOP 브랜드와 운영 방식에 맞게 커스터마이징 |
| **3단계: 확장** | 자체 기능 추가 | PokerGFX에 없는 WSOPLIVE 통합, AI 분석 등 차별화 기능 |

> **핵심**: 대부분의 기능은 PokerGFX에서 **그대로 가져온다**. 이후 우리 방식에 알맞게 변경하는 작업을 거친다.

### 내재화가 필요한 이유

| 관점 | 외부 도구(PokerGFX) | 내재화(EBS SE) |
|------|:---:|:---:|
| 라이선스 | 연간 갱신, 기능 게이팅 | 자산 내재화, 영구 소유 |
| 커스터마이징 | 스킨 수준만 변경 | WSOPLIVE 통합, 자유 확장 |
| 데이터 소유 | Export 기능 라이선스 종속 | 데이터 파이프라인 직접 통제 |

### 누가 사용하는가

| Persona | 역할 | 주요 관심사 |
|---------|------|------------|
| 방송 디자이너 | 스킨 색상, 폰트, 이미지 조합 | "이 대회 브랜드에 맞는 화면" |
| 방송 감독 | 디자인 확인, 최종 승인 | "방송 화면이 의도대로인가" |
| 기술 운영자 | Console에 스킨 로드, 문제 해결 | "파일 포맷이 호환되는가" |

### 사용 타이밍

```
  대회 1주 전          전날            당일
  ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ 디자이너 │    │ 감독     │    │ 운영자   │
  │ SE에서   │───>│ 프리뷰로 │───>│ Console  │
  │ 스킨 제작│    │ 최종확인 │    │ 에 로드  │
  └──────────┘    └──────────┘    └──────────┘
```

## 2장. 스킨이란 무엇인가

### "방송의 드레스코드"

스킨은 포커 방송 화면의 **모든 시각적 설정 묶음**이다. 같은 게임 데이터라도 스킨이 다르면 화면이 완전히 달라진다. 대회마다 옷을 갈아입히듯, 방송 화면에 드레스코드를 입힌다.

### 스킨이 제어하는 5가지

| # | 영역 | 비유 | 예시 |
|:-:|------|------|------|
| 1 | 위치 | 무대 위 소품 배치 | 카드 5장의 x, y 좌표 |
| 2 | 글씨 | 간판의 서체 | 폰트, 크기, 색상, 그림자 |
| 3 | 그림 | 무대 배경막 | Board 배경 이미지, 로고 |
| 4 | 움직임 | 등퇴장 연출 | Fade, Slide, Pop, Expand |
| 5 | 색감 | 조명 필터 | Hue, Tint, Color Replace |

### 스킨이 제어하지 않는 것

| 영역 | 담당 도구 | 이유 |
|------|----------|------|
| 게임 규칙 (Blind 구조, 타이머) | Console | 매 방송 변경되는 운영 설정 |
| 카메라 (PIP, 카메라 전환) | Console | 하드웨어 연동 |
| 실시간 데이터 (칩 카운트, 승률) | Console | 런타임 데이터 |

> **핵심 구분**: 스킨 = **디자인 기본값** (시즌마다), Console = **런타임 오버라이드** (매 방송)

### .gfskin 파일 — "옷이 담긴 캐리어"

```
  .gfskin (ZIP 파일)
  ├── skin.json ─── 설정값 (폰트, 좌표, 색상…)
  ├── board.png ─── Board 배경 이미지
  ├── player.png ── Player 배경 이미지
  └── logo.png ──── 스폰서 로고
```

PokerGFX는 `.skn`(암호화 바이너리) 포맷을 사용한다. EBS는 이를 개방형 `.gfskin`(ZIP + JSON) 포맷으로 내재화하여, 향후 자체 도구 연동과 자동화 파이프라인 확장이 가능하도록 했다.

## 3장. 세 도구의 관계

### Console ↔ SE ↔ GE

```
  +------------------+    +------------------+    +-----------------+
  |    Console       |    |  Skin Editor(SE) |    | Graphic Editor  |
  |  "방송 조종석"   |    | "디자인 작업실"  |    |   (GE)          |
  |                  |    |                  |    | "픽셀 작업대"   |
  | 매 방송 사용     |<──>| 시즌마다 사용    |<──>| 디자인 변경 시  |
  | 런타임 제어      |    | 스킨 조합/관리   |    | 요소별 미세조정 |
  +------------------+    +------------------+    +-----------------+
```

### 책임 분리 — "진짜 리모컨은 하나"

하나의 설정이 두 곳에서 편집되면 혼란이 생긴다. EBS는 **모든 설정에 주인(SSOT)을 하나만 지정**한다.

| 설정 영역 | SSOT (주인) | 다른 곳에서는 |
|----------|:-----------:|-------------|
| 색상, 폰트, 배치 | **Skin** | Console이 로드만 |
| Blind 구조, 칩 표시 | **Console** | SE에 없음 |
| 통계 ON/OFF | **Console** | SE에 없음 |
| Transition 효과 | **Skin** | Console이 런타임 override |

### 사용 빈도

```
  빈도 높음 ◀──────────────────────▶ 빈도 낮음

  Console          SE              GE
  (매 방송)     (시즌마다)    (디자인 변경 시)
  ━━━━━━━━━     ━━━━━━━━     ━━━━━━━
```

### 작업 시퀀스

```
  디자이너     SE        GE       .gfskin    Console     방송 화면
     |          |         |          |          |           |
     |--제작--->|         |          |          |           |
     |          |--편집-->|          |          |           |
     |          |<-저장---|          |          |           |
     |          |--Export--------->  |          |           |
     |          |         |          |--Load--->|           |
     |          |         |          |          |--송출---->|
```

## 4장. 사용자 여정

### 5단계 워크플로우

```
  ① 기획        ② 소재 준비     ③ SE 조합
  +---------+   +-----------+   +-------------+
  | 브랜드  |   | 배경 PNG  |   | SE에서      |
  | 컬러칩  |-->| 로고 PNG  |-->| 요소 배치   |
  | 폰트 선정|   | 폰트 파일 |   | 색상/폰트   |
  +---------+   +-----------+   +------+------+
                                       |
                                       v
                ⑤ Console 적용   ④ GE 미세조정
                +-----------+   +-------------+
                | .gfskin   |   | Board GE    |
                | 로드 →    |<--| Player GE   |
                | 방송 시작 |   | 요소별 px   |
                +-----------+   +-------------+
```

### 3가지 시나리오

| 시나리오 | 시작점 | 경로 | 소요 |
|---------|-------|------|------|
| **신규 생성** | 빈 스킨 | SE → GE(8종) → Export | 2~4시간 |
| **기존 수정** | .gfskin Import | SE → 색상/폰트 변경 → Export | 30분 |
| **빠른 시작** | 기본 스킨 복제 | SE → 로고만 교체 → Export | 10분 |

## 5장. UI 디자인 원칙

> 원칙 원문: [ebs-ui-design-strategy.md](ebs-ui-design-strategy.md) §1장

### 원칙 1 — WYSIWYG-First: "보이는 대로 결과"

Canvas가 항상 보여야 하는 이유: 디자이너가 숫자를 입력하고 "방송에서 어떻게 보일까?" 추측하는 것은 비효율적이다. 폰트를 바꾸면 Canvas에서 즉시 바뀐다.

```
  ┌─ SE 메인 ──────────────────────────────┐
  │                                        │
  │  ┌──────┐  ┌─────────┐  ┌──────────┐  │
  │  │요소  │  │ 설정    │  │ 설정     │  │
  │  │Grid  │  │ (Text)  │  │ (Cards)  │  │
  │  │      │  │ 폰트 →  │  │          │  │
  │  │      │  │ 변경!   │  │          │  │
  │  └──────┘  └────┬────┘  └──────────┘  │
  │                 │                      │
  │  ──── GE에서 Canvas가 즉시 반영 ────  │
  └────────────────────────────────────────┘
```

### 원칙 2 — 3열 구조: 자연스러운 눈의 흐름

사람의 시선은 좌상→우하로 이동한다 (Gutenberg Diagram). SE와 GE 모두 이 흐름을 따른다.

```
  ★★★★ 시선 시작      ★★★ 중앙      ★★ 우측
  ┌─────────┬───────────┬──────────┐
  │ Element │ Text/Font │ Cards    │
  │ Grid    │ (가장     │          │
  │ (진입점)│  자주     │          │
  │         │  편집)    │          │
  └─────────┴───────────┴──────────┘
         ↓ 시선 방향 ↓         ↓
```

### 원칙 3 — 접힘 패턴: "하나만 열어 집중"

720×480px이라는 제한된 화면에서 모든 설정을 동시에 보여줄 수 없다. 자주 쓰는 설정은 펼쳐두고, 나머지는 접어둔다.

| 상태 | 대상 | 이유 |
|------|------|------|
| ▼ 펼침 | Text/Font, Cards, Player/Flags | 매번 편집하는 핵심 설정 |
| ▶ 접힘 | Vanity 등 | 간헐적으로만 편집 |

### 원칙 4 — Spatial Consistency: "같은 것은 같은 자리에"

SE에서 "Text" 설정이 가운데 열에 있으면, GE에서도 Text 패널은 같은 위치에 있다. 도구를 오갈 때 "어디에 있더라?"를 다시 찾지 않아도 된다.

### 원칙 5 — Density Balance: 빈 공간 없이

3열 중 한 열만 비어 있으면 시선이 불균형해진다. 열 간 정보 밀도 편차를 20% 이내로 유지하여, 어느 열을 봐도 균일한 밀도를 느낀다.

## 6장. 시각적 언어

> 상세 토큰: [prd-compact-mockup-design-system.prd.md](prd-compact-mockup-design-system.prd.md)

### 어두운 테마 — 방송 제어실의 조명

방송 제어실은 어둡다. 모니터 수십 개가 켜진 환경에서 밝은 UI는 눈을 피로하게 한다. EBS는 VS Code Dark+ 계열의 어두운 배경(`#1e1e1e`)을 사용한다.

### 최소 색상 — "액자는 그림보다 눈에 띄면 안 된다"

UI 자체가 화려하면 Canvas(방송 프리뷰)가 묻힌다. 회색 계열 UI 위에 Canvas만 컬러풀하게 보이도록 설계했다.

| 역할 | 색상 | 용도 |
|------|------|------|
| 배경 | `#1e1e1e` | 앱 전체 배경 |
| 패널 | `#252526` | 다이얼로그 배경 |
| 표면 | `#2d2d30` | 입력 필드 배경 |
| 강조 | `#0e639c` | 선택된 요소, 토글 ON |
| 텍스트 | `#cccccc` | 기본 텍스트 |

### 공간 밀도 — 720×480의 도전

| 제약 | 값 | 의미 |
|------|-----|------|
| 전체 viewport | 720×480px | 16:9 비율, 스크롤 없음 |
| 최소 폰트 | 9px | 가독성 하한 |
| 간격 단위 | 1~4px | 일반 앱(8~16px)의 1/4 |

일반 웹 앱의 여유로운 간격 대신, 모든 공간을 밀도 있게 사용한다. 스크롤은 금지 — 접힘/펼침으로 공간을 관리한다.

### Zone 색상 — 학습과 개발을 위한 구분

목업에는 3가지 표시 모드가 있다.

| 모드 | 용도 | 표시 |
|------|------|------|
| Clean | 실제 UI 확인 | 순수 UI만 |
| Default | 개발 참조 | Element ID 표시 |
| Annotated | 영역 학습 | Zone별 색상 테두리 |

```
  ┌──────────────────────────────────────┐
  │ ■ Metadata(파란)  ■ Elements(초록)  │
  │ ■ Settings(주황)  ■ Actions(빨강)   │
  └──────────────────────────────────────┘
```

## 7장. 정보 계층 전략

### Progressive Disclosure — 리모컨 비유

TV 리모컨을 생각해보자.

```
  ┌─────────────────────────────┐
  │  T1: 앞면 버튼              │
  │  전원, 채널, 볼륨           │  ← 매일 사용 (80%)
  │  ─────────────────────────  │
  │  T2: 뚜껑 안 버튼          │
  │  입력 전환, 자막            │  ← 가끔 사용 (15%)
  │  ─────────────────────────  │
  │  T3: 설명서                 │
  │  서비스 모드, 공장 초기화   │  ← 거의 안 씀 (5%)
  └─────────────────────────────┘
```

EBS도 동일한 3단계로 정보를 노출한다.

| Tier | 접근 | SE에서 | GE에서 |
|:----:|------|--------|--------|
| T1 | 항상 보임 | Element Grid, Text/Font | Canvas, Transform |
| T2 | 1클릭 (접힌 섹션 펼치기) | Cards, Player/Flags | Animation, Text |
| T3 | Advanced (숨김) | Vanity | Background |

### 사용자 레벨별 접근 깊이

| 레벨 | Tier 사용 | 커버리지 | 전형적 작업 |
|------|:---------:|:--------:|------------|
| 초보 | T1만 | 80% | 폰트/색상 변경 |
| 중급 | T1 + T2 | 95% | 카드 표시, 플래그 |
| 전문가 | T1 + T2 + T3 | 100% | Vanity 텍스트, 고급 설정 |

> **설계 의도**: 초보자는 T1만으로 핵심 편집을 완료할 수 있다. T2/T3를 모른다고 방송이 불가능한 것은 아니다.

## 8장. SE 메인 화면

### 화면 이미지

| Clean | Annotated |
|:-:|:-:|
| ![SE Clean](images/ebs-skin-editor-clean.png) | ![SE Annotated](images/ebs-skin-editor-annotated.png) |
| *순수 UI* | *■ Metadata(01~05) ■ Elements(06,27~30) ■ Settings(07~26) ■ Actions(21~26)* |

### 4-Zone 구조

SE 메인 화면은 4개 Zone으로 구성된다.

```
  ┌─────────────────────────────────────────────┐
  │ ① Metadata (01~05)                          │
  ├───────┬─────────────────────┬───────────────┤
  │       │                     │               │
  │  ②    │  ③ Settings         │  ③ Settings   │
  │ Elem  │  Text/Font (펼침)   │  Cards (펼침) │
  │ Grid  │  Player/Flags(펼침) │  Vanity       │
  │ (06)  │                     │               │
  │       ├─────────────────────┤               │
  │       │ ④ Actions (21~26)   │               │
  ├───────┴─────────────────────┴───────────────┤
  └─────────────────────────────────────────────┘
```

| Zone | ID 범위 | 구성 | 역할 |
|:----:|:-------:|------|------|
| ① Metadata | 01~05 | Name, Details, Remove Alpha, 4K, Scale | 스킨 기본 정보 |
| ② Elements | 06, 27~30 | 7버튼 Grid + Adjust Colours | GE 진입점 |
| ③ Settings | 07~26 | Text/Font, Cards, Player/Flags + Vanity | 스킨 고유 설정 |
| ④ Actions | 21~26 | IMPORT, EXPORT, SAVE, RELOAD, USE, CLOSE | 파일 작업 |

### Settings 구성 (v3.0.0)

3개 펼침 섹션 + Vanity 인라인. Console 전용 필드(D1~D4)를 제거하고 **스킨 고유 설정만** 유지한다.

| 섹션 | 상태 | 주요 컨트롤 | 편집 빈도 |
|------|:----:|------------|:---------:|
| Text/Font | ▼ 펼침 | 폰트 선택, 크기, 색상, 정렬 | 매번 |
| Cards | ▼ 펼침 | 카드 표시, 딜러 버튼 | 자주 |
| Player/Flags | ▼ 펼침 | 플레이어 표시, 국기 | 자주 |
| Vanity | 인라인 | Vanity 텍스트 | 간헐적 |

> **v3.0.0 스코프 재정의**: Chipcount Precision, Statistics, Card Display, Layout은 Console 전용으로 이관. Colour Tools(Hue/Tint/Color Replace)는 각 GE 모드의 "Adjust Colours" 모달로 이관.

### Element Grid — 7버튼

| # | 버튼 | GE 모드 | Canvas |
|:-:|------|:-------:|:------:|
| 1 | Board | Board | 296×197 |
| 2 | Player | Player | 465×120 |
| 3 | Blinds | Blinds | 790×52 |
| 4 | Outs | Outs | 465×84 |
| 5 | History | History | 345×33 |
| 6 | Leaderboard | Leaderboard | 800×103 |
| 7 | Field | Field | 270×90 |

> PokerGFX 10버튼에서 SSD, Ticker, Action Clock을 제외. Ticker는 별도 시스템, Action Clock은 Console 운영 설정으로 분리.

## 9장. Graphic Editor 8종 화면

GE는 단일 다이얼로그에서 모드 탭으로 8종 화면을 전환한다. 모든 모드가 동일한 패널 구조(Canvas + Elements + Transform + Text/Animation/Background + Actions)를 공유하며, Canvas 크기와 서브요소만 다르다.

### 8종 요약

| # | 모드 | Canvas | 서브요소 | 패턴 | Import Mode |
|:-:|------|:------:|:--------:|:----:|:-----------:|
| 1 | Board | 296×197 | 14 | A | 3종 |
| 2 | Player | 465×120 | 가변 | C | Layout 3종 |
| 3 | Blinds | 790×52 | 4~6 | B | Ante 변형 |
| 4 | Outs | 465×84 | 3 | C | — |
| 5 | History | 345×33 | 1~3 | B | 4종 섹션 |
| 6 | Leaderboard | 800×103 | 9 | C | 3종 섹션 |
| 7 | Field | 270×90 | 3 | A | — |
| 8 | Strip | 270×90 | 6 | A | — |

> **패턴**: A = 3-Column Figma식, B = Canvas Top + 2×2 Grid, C = Canvas Top + 3열. 상세: [pokergfx-vs-ebs-skin-editor.prd.md §3](pokergfx-vs-ebs-skin-editor.prd.md)

### 9.1 Board

| Clean | Annotated |
|:-:|:-:|
| ![Board](images/ebs-ge-board.png) | ![Board Ann.](images/ebs-ge-board-annotated.png) |

Canvas 296×197. 커뮤니티 카드 5장, 팟/블라인드 정보, 스폰서 로고를 배치한다.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1~5 | Card 1~5 | Image |
| 6 | Sponsor Logo | Image |
| 7 | Branding | Text |
| 8 | Pot Amount | Text |
| 9 | Pot Label | Text |
| 10 | Blinds Label | Text |
| 11 | Blinds Amount | Text |
| 12 | Hand Label | Text |
| 13 | Hand Number | Text |
| 14 | Game Variant | Text |

Import Mode 3종: Auto / AT Mode (Flop Game) / AT Mode (Draw/Stud Game) — 각각 다른 배경 이미지를 로드한다.

### 9.2 Player

| Clean | Annotated |
|:-:|:-:|
| ![Player](images/ebs-ge-player.png) | ![Player Ann.](images/ebs-ge-player-annotated.png) |

Canvas 465×120 (기본). 플레이어 이름, 칩 스택, 포지션, 홀카드, 사진을 배치한다. 서브요소 수는 게임 Variant에 따라 가변 (Holdem N=2, Omaha N=4).

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1~N | Card 1~N | Image |
| N+1 | Name | Text |
| N+2 | Action | Text |
| N+3 | Stack | Text |
| N+4 | Odds | Text |
| N+5 | Position | Text |
| N+6 | Photo | Image |
| N+7 | Flag | Image |

**Layout Type 3종** — 드롭다운으로 캔버스 구성을 전환한다.

| Layout | Canvas | 설명 |
|:-------|:------:|------|
| horizontal_with_photo | 465×120 | 수평 + 사진 (기본) |
| vertical_only | 465×84 | 수직, Photo/Flag 제거 |
| compact | 270×90 | 최소 구성, Card도 제거 |

배경 이미지 6상태 (기본/액션 중/자동/사진 포함/AT 기본/AT 사진) + Drop Shadow 8방향.

### 9.3 Blinds

| Clean | Annotated |
|:-:|:-:|
| ![Blinds](images/ebs-ge-blinds.png) | ![Blinds Ann.](images/ebs-ge-blinds-annotated.png) |

Canvas 790×52. 블라인드 레벨과 핸드 번호를 표시하는 하단 스트립.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1 | Blinds | Text |
| 2 | Amount | Text |
| 3 | Hand Label | Text |
| 4 | Hand Number | Text |

**Ante 변형**: Ante 활성 시 배경이 자동 전환되고, Ante Msg + Ante Amt 2개 요소가 추가되어 총 6개.

### 9.4 Outs

| Clean | Annotated |
|:-:|:-:|
| ![Outs](images/ebs-ge-outs.png) | ![Outs Ann.](images/ebs-ge-outs-annotated.png) |

Canvas 465×84. 아웃 카드, 이름, 아웃 수를 표시한다.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1 | Card 1 | Image |
| 2 | Name | Text |
| 3 | # Outs | Text |

### 9.5 Hand History

| Clean | Annotated |
|:-:|:-:|
| ![History](images/ebs-ge-history.png) | ![History Ann.](images/ebs-ge-history-annotated.png) |

Canvas 345×33. 핸드 히스토리를 Header/반복 섹션/Footer 구조로 표시한다.

**Import Mode 4종** — 각 섹션별로 다른 배경과 서브요소를 편집한다.

| Mode | 서브요소 |
|------|:--------:|
| Header | Pre-Flop (1개) |
| Repeating header | 반복 헤더 (1개) |
| Repeating detail | Name + Action (2개) |
| Footer | Footer 텍스트 (1개) |

### 9.6 Leaderboard

| Clean | Annotated |
|:-:|:-:|
| ![LB](images/ebs-ge-leaderboard.png) | ![LB Ann.](images/ebs-ge-leaderboard-annotated.png) |

Canvas 800×103. 리더보드 패널로, 사진/국기/스폰서 로고와 3열 데이터를 표시한다.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1 | Player Photo | Image |
| 2 | Player Flag | Image |
| 3 | Sponsor Logo | Image |
| 4 | Title | Text |
| 5 | Left | Text |
| 6 | Centre | Text |
| 7 | Right | Text |
| 8 | Footer | Text |
| 9 | Event Name | Text |

**Import Mode 3종**: Header (4요소) / Repeating section (5요소) / Footer (3요소). Transition 기본값: Expand.

### 9.7 Field

| Clean | Annotated |
|:-:|:-:|
| ![Field](images/ebs-ge-field.png) | ![Field Ann.](images/ebs-ge-field-annotated.png) |

Canvas 270×90. 총 참가자 수와 잔여 인원을 표시하는 카운터.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1 | Total | Text |
| 2 | Remain | Text |
| 3 | Field | Text |

Transition 기본값: Pop.

### 9.8 Strip

| Clean | Annotated |
|:-:|:-:|
| ![Strip](images/ebs-ge-strip.png) | ![Strip Ann.](images/ebs-ge-strip-annotated.png) |

Canvas 270×90. 하단 스트립에 플레이어 통계(VPIP, PFR)와 로고를 표시한다.

| # | 서브요소 | 타입 |
|:-:|---------|:----:|
| 1 | Name | Text |
| 2 | Count | Text |
| 3 | Position | Text |
| 4 | VPIP | Text |
| 5 | PFR | Text |
| 6 | Logo | Image |

> 8종 상세(서브요소 좌표, Import Mode 비교, 오버레이 영향): [pokergfx-vs-ebs-skin-editor.prd.md §4](pokergfx-vs-ebs-skin-editor.prd.md)

## 10장. 설계 결정 10선

PokerGFX를 내재화하면서 내린 핵심 설계 결정 10가지를 요약한다.

| # | 결정 | 내재화 전 | 내재화 후 | 사유 |
|:-:|------|----------|----------|------|
| 1 | GE 통합 | 2개 별도 클래스 (87% 중복) | 단일 다이얼로그 + mode 탭 | 코드 중복 87% 제거 |
| 2 | Element Grid 축소 | 10버튼 | 7버튼 (SSD, Ticker, Action Clock 제외) | 범위 정리 — Ticker 별도, Clock 운영 설정 |
| 3 | Settings 표면화 | 3섹션 플랫 + 48필드 숨김 | 3섹션 접이식 + Vanity 인라인 | 숨겨진 필드 UI 노출 후 Console 이관 |
| 4 | 파일 포맷 전환 | .skn (AES + Binary) | .gfskin (ZIP + JSON) | 개방형 포맷, 보안 취약점 해소 |
| 5 | Canvas 위치 변경 | 하단 배치 | 좌측 상단 (WYSIWYG 우선) | 편집 결과 즉시 확인 |
| 6 | 패널 접이식 전환 | 플랫 (모두 노출) | 접이식 (핵심 펼침, 나머지 접힘) | 720×480 공간 최적화 |
| 7 | 테마 전환 | 다크 (회색/검정) | B&W Refined Minimal | 모던 UI 표준, Canvas 대비 강화 |
| 8 | Console-Skin SSOT | 동일 필드 양쪽 노출 | Skin = 디자인 기본값, Console = override | 데이터 충돌 방지 |
| 9 | Colour Tools 이관 | 메인 인라인 | GE "Adjust Colours" 모달 복원 | 원본 패턴 회귀, GE 프리뷰 제공 |
| 10 | SE 스코프 재정의 | 9개 Settings (48필드) | 3개 Settings + Vanity (스킨 고유만) | Console D1~D4 중복 제거 |

> 각 결정의 상세 배경과 위험 요인: [pokergfx-vs-ebs-skin-editor.prd.md §7](pokergfx-vs-ebs-skin-editor.prd.md)

## 참조 링크

| 문서 | 내용 | 참조 시점 |
|------|------|----------|
| [pokergfx-vs-ebs-skin-editor.prd.md](pokergfx-vs-ebs-skin-editor.prd.md) | SE/GE 설계 정본 — AS-IS vs TO-BE 상세 비교, GE 8종 목업 | UI 구조 상세가 필요할 때 |
| [ebs-ui-design-strategy.md](ebs-ui-design-strategy.md) | 5대 설계 원칙, 레이아웃 아키텍처, 검증 지표 | 설계 근거가 필요할 때 |
| [prd-compact-mockup-design-system.prd.md](prd-compact-mockup-design-system.prd.md) | 720×480 디자인 시스템, CSS 토큰, 컨트롤 사양 | 구현 사양이 필요할 때 |
| [EBS-UI-Design-Console.md](../../ebs-console/docs/EBS-UI-Design-Console.md) | Console 탭 구조, 오버레이 그래픽 설계 | Console과의 관계가 필요할 때 |
| [PRD-EBS_Foundation.md](../../../ebs/docs/00-prd/PRD-EBS_Foundation.md) | EBS 비전, 전체 시스템 구조 | 비즈니스 맥락이 필요할 때 |

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-23 | v1.1.0 | 8~10장 삽입 — SE 메인 화면, GE 8종 화면, 설계 결정 10선 (pokergfx-vs-ebs-skin-editor.prd.md에서 EBS 영역 추출) | PRODUCT | 개념/원칙만 있던 문서에 실제 화면 본론 추가 |
| 2026-03-23 | v1.0.0 | 최초 작성 — 7장 구조 | - | - |
