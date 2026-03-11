---
doc_type: "design"
doc_id: "DESIGN-OVR-v3"
version: "1.0.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-11"
last_updated: "2026-03-11"
prd_ref: "EBS-UI-Design-v3 v9.0.0 §4"
---

# 오버레이 그래픽 — Flutter/Rive 기반 설계

오버레이는 메인 방송 영상 위에 **덧입히는 부가 그래픽**이다. 화면 중앙은 메인 영상이 차지하고, 오버레이는 가장자리(좌/우/상/하)에 배치한다. 폴드한 플레이어는 즉시 제거하여 **액티브 플레이어만** 표시한다.

## 핵심 혁신

| PokerGFX (레거시) | EBS v3.0 (혁신) | 벤치마크 |
|-------------------|-----------------|:--------:|
| 불투명 박스 배경 | Glassmorphism (반투명 프로스트 + backdrop-blur) | BM-2 GGPoker |
| 고정 정보량 | 적응형 정보 밀도 (프리플랍=기본, 리버=최대) | BM-2 GGPoker |
| 정적 텍스트 | 네온/글로우 이벤트 강조 (올인, 빅 팟) | BM-2 GGPoker |
| 일반 폰트 크기 | Bold 타이포 핵심 수치 (팟, 스택) 시각 강조 | BM-2 GGPoker |
| 고정 배치 (10인 전원 표시) | Flutter/Rive 기반 가장자리 배치 (액티브만 표시) | EBS 독자 설계 |

## 배제 4종 (PokerGFX 15종 → EBS 11종)

| 배제 오버레이 | 사유 |
|-------------|------|
| Commentary Header | SV-021 Drop — Commentary 기능 EBS 배제 |
| PIP Commentary | SV-022 Drop — 동일 사유 |
| Countdown | SEC-002 Drop — Blinds Graphic + AT 타이머로 대체 |
| Action Clock | SV-017 Drop |

## 4.1 오버레이 설계 철학

### 부가 그래픽 원칙

오버레이는 메인 영상을 보조하는 요소이다. 메인 영상이 화면의 중심을 차지하고, 오버레이는 시청자의 시선을 방해하지 않는 **가장자리 영역**에 배치한다.

| 원칙 | 설명 |
|------|------|
| 메인 영상 우선 | 화면 중앙(약 60% 영역)은 메인 카메라 영상 전용. 오버레이 침범 금지 |
| 가장자리 배치 | Player Graphic은 좌/우/하단 가장자리에만 배치 |
| 액티브 플레이어만 표시 | 폴드한 플레이어는 **즉시 제거** (기존: opacity 0.4 유지 → 신규: 완전 제거) |
| 3인 기본 | 대부분의 실전 핸드는 플랍 이후 2~4인. **3인 액티브가 디폴트 레이아웃** |
| 최소 정보량 | 필수 정보(이름, 스택, 카드, 액션)만 표시. 시각 잡음 최소화 |

### 표시 규칙

| 이벤트 | 오버레이 동작 |
|--------|-------------|
| 핸드 시작 | 모든 참여 플레이어 Player Graphic 표시 |
| 플레이어 폴드 | 해당 Player Graphic **즉시 페이드아웃 제거** (300ms) |
| 쇼다운 진입 | 남은 액티브 플레이어만 유지 |
| 핸드 종료 | 위너 하이라이트 2초 → 전체 클리어 |

## 4.2 전체 배치도 (1920x1080)

기본 레이아웃: 3인 액티브 플레이어. 화면 중앙은 **메인 영상 영역**으로 비워둔다.

### 9-Position 그리드 시스템

Player Graphic 그룹과 Board Graphic은 각각 **독립적으로** 9개 위치 중 하나에 배치된다. Strip(상단 바), Blinds(하단 바), Ticker(최하단)는 위치 고정으로 9-grid 대상이 아니다.

| 위치 코드 | 설명 | 기준점 |
|-----------|------|--------|
| TOP-LEFT | 좌상단 | anchor: top-left |
| TOP-CENTER | 중상단 | anchor: top-center |
| TOP-RIGHT | 우상단 | anchor: top-right |
| MID-LEFT | 좌중단 | anchor: mid-left |
| CENTER | 중단 | anchor: center |
| MID-RIGHT | 우중단 | anchor: mid-right |
| BOT-LEFT | 좌하단 | anchor: bottom-left |
| BOT-CENTER | 중하단 | anchor: bottom-center |
| BOT-RIGHT | 우하단 | anchor: bottom-right |

**기본 세팅**: Player Graphic 그룹 = **BOT-LEFT (좌하단)**, Board Graphic = **BOT-RIGHT (우하단)**

> <img src="mockups/v3/ebs-overlay-layout-grid.png" alt="오버레이 방송 화면 — 9-Grid 포지션 시스템 기본 세팅 (1920x1080) White Minimal 목업" style="max-width: 960px;">
>
> *9-Grid 기본 세팅: Player Graphic x3 좌하단 + Board Graphic 우하단. 점선은 3x3 그리드 경계선. 각 셀에 포지션 코드 표시. Strip/Blinds/Ticker는 고정 위치.*

### 배치 프리셋 (9-grid 기반 재해석)

기존 배치 A/B/C는 9-grid 좌표계로 표현된 프리셋으로 관리한다.

| 프리셋 | Player Graphic 위치 | Board Graphic 위치 | 적합한 상황 |
|--------|--------------------|--------------------|-----------|
| **배치 A — 하단 집중** | BOT-LEFT | BOT-LEFT (세로 스택) | 범용, 정면 카메라 |
| **배치 B — 센터형** | BOT-LEFT | BOT-CENTER | 중앙 강조, 정면 앵글 |
| **배치 C — 일렬형** | MID-LEFT | BOT-LEFT (수직 정렬) | 좌측 집중, 우측 완전 개방 |
| **배치 D — 좌우 반전** | BOT-RIGHT | BOT-LEFT | 좌측 앵글 확보, 와이드샷 |
| **기본값 (Default)** | BOT-LEFT | BOT-RIGHT | 일반 방송 |

#### 배치 A: 하단 집중형

> *배치 A: Player Graphic x3을 좌하단 세로 스택 배치. Strip 상단 바 + Blinds 바 + Ticker는 고정.*

#### 배치 B: 센터형

> <img src="mockups/v3/ebs-overlay-layout-b.png" alt="오버레이 방송 화면 배치 B (센터형) White Minimal 목업" style="max-width: 960px;">
>
> *배치 B: Player Graphic을 좌하단(BOT-LEFT) 세로 스택, Board Graphic을 중하단(BOT-CENTER)에 배치. 양쪽 대칭 구도.*

#### 배치 C: 일렬형

> <img src="mockups/v3/ebs-overlay-layout-c.png" alt="오버레이 방송 화면 배치 C (일렬형) White Minimal 목업" style="max-width: 960px;">
>
> *배치 C: Board Graphic을 좌하단(BOT-LEFT), Player Graphic을 좌중단(MID-LEFT) 수직 정렬. 우측 상단 완전 개방.*

#### 배치 D: 좌우 반전형

> <img src="mockups/v3/ebs-overlay-layout-d.png" alt="오버레이 방송 화면 배치 D (좌우 반전형) White Minimal 목업" style="max-width: 960px;">
>
> *배치 D: Board Graphic을 좌하단(BOT-LEFT), Player Graphic을 우하단(BOT-RIGHT) 배치. 기본값의 좌우 반전.*

### 배치 커스터마이징 (미세 조정)

9-grid 위치 선택 후 픽셀 단위로 오프셋과 크기를 미세 조정할 수 있다.

| 속성 | 타입 | 설명 | 기본값 예시 |
|------|------|------|-----------|
| grid_position | enum | 9-grid 위치 코드 (위 표 참조) | BOT-LEFT |
| offset_x | int | grid 기준점에서 X 오프셋 (px) | 20 |
| offset_y | int | grid 기준점에서 Y 오프셋 (px) | -20 |
| width | int | 요소 너비 (px) | 280 |
| height | int | 요소 높이 (px) | 180 |
| visible | bool | 표시 여부 | true |
| z-index | int | 레이어 순서 (높을수록 앞) | 100 |

## 4.3 렌더링 엔진

오버레이는 **Flutter/Rive** 기반으로 개발한다. Rive 애니메이션 런타임을 활용하여 60fps 이상의 부드러운 상태 전이와 이벤트 연출을 구현한다.

| 항목 | 사양 |
|------|------|
| 렌더링 엔진 | Flutter (데스크톱) + Rive (애니메이션) |
| 출력 | NDI / DeckLink 포트 (Fill & Key 지원) |
| 프레임레이트 | 60fps 기본, GPU 가속 시 120fps 목표 |
| 투명도 | Alpha 채널 네이티브 지원 |
| 스킨 시스템 | Rive 파일(.riv) 기반 커스텀 스킨 |

> 구체적 코드 구조, 상태 관리 패턴, API 설계 등 개발 명세는 별도 기술 문서에서 다룬다.

## 4.4 Player Graphic
핵심 오버레이. 액티브 플레이어에게만 표시된다.

### 서브 컴포넌트

> <img src="mockups/v3/ebs-player-graphic.png" alt="Player Graphic 컴포넌트 White Minimal 목업 — Standard 280×180" style="max-width: 960px;">
>
> *Player Graphic Standard: 사진(A) + 이름/플래그/포지션(B~G) + 스택(Bold) + 홀카드 + 액션 + 에퀴티 바(H).*

| ID | 서브 컴포넌트 | 내용 | 표시/숨김 |
|:--:|-------------|------|:---------:|
| A | 사진 | 80x80px 원형 크롭. 미등록 시 이니셜 아바타 | 설정 가능 |
| B | 이름 | 플레이어명. 최대 16자, 초과 시 말줄임 | 항상 표시 |
| C | 스택 | 칩 스택. **Bold 타이포** (BM-2). smart precision | 항상 표시 |
| D | 홀카드 | 2~7장 (게임 타입별). 카드 등장/공개 애니메이션 | 항상 표시 |
| E | 액션 | BET/CALL/RAISE/FOLD/ALL-IN 텍스트 + 금액 | 액션 시 |
| F | 국기 | 16x12px 국기 아이콘 | 설정 가능 |
| G | 포지션 | BTN/SB/BB/UTG 등 뱃지 | 항상 표시 |
| H | 에퀴티 바 | 올인 시 승률 프로그레스 바 | 올인 시 |

### 템플릿 변형 3종

| 변형 | 크기 | 구성 | 적합한 상황 |
|------|------|------|-----------|
| Standard | 280x180px | 전체 서브 컴포넌트 (A~H) | 기본. 3~4인 이하 |
| Compact | 220x120px | 사진 제외, 이름+스택+카드+액션 | 5~6인 |
| Minimal | 160x80px | 이름+카드만 | 7인 이상, 화면 공간 부족 시 |

### Glassmorphism 스타일 (BM-2)

- 배경: `rgba(13, 13, 26, 0.65)` + `backdrop-filter: blur(12px)`
- 테두리: `1px solid rgba(255, 255, 255, 0.08)`
- 그림자: `0 4px 30px rgba(0, 0, 0, 0.3)`

### 상태별 시각 전환

| 상태 | 시각 효과 |
|------|----------|
| Idle | 이름 + 스택만. 카드 슬롯 비활성 |
| Action-on | 밝은 테두리 + 미세 펄스 |
| Acted | 액션 텍스트 애니메이션 등장 |
| Fold | **즉시 페이드아웃 제거** (300ms 트랜지션) |
| All-in | **네온 글로우** (BM-2) + 에퀴티 바 표시 |
| Showdown | 카드 공개 + 위너 하이라이트 |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 120~400 | 너비 (px) |
| height | 60~250 | 높이 (px) |
| template | standard / compact / minimal | 템플릿 변형 |
| show_photo | bool | 사진 표시 여부 |
| show_flag | bool | 국기 표시 여부 |
| show_equity | bool | 에퀴티 바 표시 여부 |

## 4.5 Board Graphic
커뮤니티 카드 5슬롯 + POT + 사이드팟.

### 서브 컴포넌트

> <img src="mockups/v3/ebs-board-graphic.png" alt="Board Graphic 컴포넌트 White Minimal 목업 — Standard 480×200" style="max-width: 960px;">
>
> *Board Graphic Standard: 5슬롯 카드 + POT(Bold 28pt) + Side Pot + 위닝 핸드명.*

| 서브 컴포넌트 | 내용 |
|-------------|------|
| 카드 슬롯 (5) | Flop 3장 + Turn 1장 + River 1장. 순차 등장 애니메이션 |
| POT | 메인 팟 금액. **Bold 28pt** (BM-2). smart precision |
| 사이드팟 | 복수 사이드팟 금액. 일반 크기 |
| 위닝 핸드명 | "Full House", "Straight" 등. 쇼다운 시 표시 |

### 템플릿 변형 2종

| 변형 | 크기 | 구성 | 적합한 상황 |
|------|------|------|-----------|
| Standard | 480x200px | 전체 서브 컴포넌트 | 기본 |
| Compact | 360x120px | 카드 + POT만 (사이드팟/핸드명 숨김) | 화면 공간 부족 시 |

**Glassmorphism**: Player Graphic과 동일 스타일.

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 280~600 | 너비 (px) |
| height | 80~250 | 높이 (px) |
| template | standard / compact | 템플릿 변형 |
| show_sidepot | bool | 사이드팟 표시 여부 |
| show_handname | bool | 위닝 핸드명 표시 여부 |

## 4.6 Blinds Graphic
SB/BB/Ante/핸드번호/이벤트 로고를 표시하는 정보 바.

> <img src="mockups/v3/ebs-blinds-graphic.png" alt="Blinds Graphic 컴포넌트 White Minimal 목업 — Standard + Compact" style="max-width: 960px;">
>
> *Blinds Graphic: Standard(52px, 로고+SB·BB+Ante+Hand#+Level) + Compact(36px, SB·BB+Ante+Hand# only). 다크 배경 + Glassmorphism shimmer.*

| 구성 | 내용 |
|------|------|
| 블라인드 | SB/BB 금액 (smart precision) |
| Ante | Ante 금액 + 타입 (Standard, Button, BB 등) |
| 핸드 번호 | Hand #247 (자동 증가) |
| 이벤트 로고 | 120x40px 이벤트/스폰서 로고 |
| 레벨 표시 | 블라인드 레벨 번호 (토너먼트) |

**표시 조건**: 매 핸드 자동 표시 (auto_blinds=every_hand).

### 배치 옵션

| 옵션 | 위치 | 좌표 (기본값) |
|------|------|:------------:|
| 상단 | Status Bar 아래 | x=0, y=50 |
| 하단 (기본) | Player Graphic 위 | x=0, y=980 |
| 좌측 | 좌측 세로 배치 | x=0, y=450 |
| 우측 | 우측 세로 배치 | x=1720, y=450 |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 400~1920 | 너비 (px). 전체 너비 가능 |
| height | 30~80 | 높이 (px) |
| show_ante | bool | Ante 표시 여부 |
| show_logo | bool | 이벤트 로고 표시 여부 |
| show_level | bool | 레벨 번호 표시 여부 |

## 4.7 Field Graphic
토너먼트 잔여/전체 플레이어 수를 표시하는 소형 오버레이.

### 레이아웃

> <img src="mockups/v3/ebs-field-graphic.png" alt="Field Graphic 컴포넌트 White Minimal 목업" style="max-width: 960px;">
>
> *Field Graphic: 잔여/전체 플레이어 수 + 평균 스택.*

| 구성 | 내용 |
|------|------|
| 잔여/전체 | 현재 플레이어 수 / 시작 플레이어 수 |
| 평균 스택 | 잔여 플레이어 평균 스택 (선택 표시) |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 150~400 | 너비 (px) |
| height | 30~80 | 높이 (px) |
| show_avg_stack | bool | 평균 스택 표시 여부 |
| template | standard | 템플릿 변형 |

**표시 조건**: 운영자 수동 토글.

## 4.8 Leaderboard
전체 플레이어 순위/스택/통계를 표시하는 풀스크린 또는 사이드 오버레이.

### 레이아웃

> <img src="mockups/v3/ebs-leaderboard.png" alt="Leaderboard 컴포넌트 White Minimal 목업 — Standard" style="max-width: 960px;">
>
> *Leaderboard: 순위 테이블 (1위 반전 강조) + 스택 + 승리 횟수. 10인 초과 시 자동 페이징.*

| 구성 | 내용 |
|------|------|
| 순위 | 스택 기준 내림차순 |
| 플레이어명 | 이름 + 국기 (선택) |
| 스택 | smart precision 적용 |
| 통계 | 승리 횟수, 올인 횟수 등 (컬럼 설정 가능) |
| 페이지네이션 | 10인 초과 시 자동 페이징 (5초 간격) |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 300~800 | 너비 (px) |
| height | 200~900 | 높이 (px) |
| rows_per_page | 5~20 | 페이지당 표시 행 수 |
| columns | array | 표시 컬럼 선택 (rank, name, stack, wins...) |
| auto_page_interval | 3~15 | 자동 페이징 간격 (초) |

**표시 조건**: 운영자 수동 토글. 핸드 진행 중에는 자동 숨김 가능.

## 4.9 Ticker
화면 최하단에 가로 스크롤되는 텍스트 오버레이.

### 레이아웃

> <img src="mockups/v3/ebs-ticker.png" alt="Ticker 컴포넌트 White Minimal 목업" style="max-width: 960px;">
>
> *Ticker: 최하단 가로 스크롤 텍스트 오버레이. 핸드 결과 + 이벤트 메시지.*

| 구성 | 내용 |
|------|------|
| 스크롤 텍스트 | 좌→우 또는 우→좌 연속 스크롤 |
| 구분자 | 메시지 간 `|` 구분 |
| 내용 소스 | 자동 (핸드 결과, 엘리미네이션) + 수동 (운영자 입력 메시지) |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 800~1920 | 너비 (px). 전체 너비 가능 |
| height | 30~60 | 높이 (px) |
| speed | 1~10 | 스크롤 속도 (1=느림, 10=빠름) |
| direction | ltr / rtl | 스크롤 방향 |
| loop | bool | 반복 여부 |
| messages | array | 표시 메시지 목록 |

**표시 조건**: 자동 (핸드 결과 발생 시) + 운영자 수동 토글.

## 4.10 Strip
화면 최상단에 모든 플레이어를 가로 요약하는 바 오버레이.

### 레이아웃

> <img src="mockups/v3/ebs-strip.png" alt="Strip 컴포넌트 White Minimal 목업" style="max-width: 960px;">
>
> *Strip: 상단 바에 전체 플레이어 요약 (이름 · 스택). 폴드 플레이어는 회색+취소선.*

| 구성 | 내용 |
|------|------|
| 플레이어 요약 | 좌석번호:이름 + 스택 (축약) |
| 정렬 | 좌석 순서 또는 스택 내림차순 (설정 가능) |
| 폴드 표시 | 폴드 플레이어는 회색 처리 (Strip에서는 제거하지 않음) |
| 누적 승리 | 승리 횟수 표시 옵션 |

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 800~1920 | 너비 (px). 전체 너비 가능 |
| height | 30~60 | 높이 (px) |
| sort_by | seat / stack | 정렬 기준 |
| show_wins | bool | 누적 승리 표시 여부 |
| fold_style | gray / hide | 폴드 표시 방식 |

**표시 조건**: 운영자 수동 토글.

## 4.11 Cards 에셋 + 게임별 카드 수

### 에셋 규격

| 속성 | 값 |
|------|-----|
| 총 수 | 52장 (조커 미사용) |
| 크기 | 60x84px (1080p 기준) |
| 포맷 | PNG 투명 배경 |
| 명명 | `{rank}{suit}.png` — 예: `Ah.png`, `2c.png` |
| 카드 백 | `back.png` (비공개 상태) |
| 스타일 | 4색 덱 옵션 (♠ 검정, ♥ 빨강, ♦ 파랑, ♣ 초록) |

### 게임별 카드 수

Player Graphic의 홀카드 슬롯은 게임 타입에 따라 변형된다.

| 게임 타입 | 홀카드 수 | 레이아웃 변형 |
|----------|:---------:|-------------|
| Holdem | 2 | 기본 2슬롯 (60x84 x2) |
| PLO4 | 4 | 4슬롯 축소 배치 (48x67 x4) |
| PLO5 | 5 | 5슬롯 축소 배치 (42x59 x5) |
| PLO6 | 6 | 6슬롯 2행 (42x59 x6) |
| 5 Card Draw | 5 | PLO5 동일 |
| 7 Card Stud | 7 | 7슬롯 2행 (38x53 x7) |
| Short Deck | 2 | Holdem 동일 (36장 덱) |

## 4.12 Split Screen Divider

헤즈업(1:1) 대결 시 화면을 좌우로 분할하여 각 플레이어의 카메라 앵글을 동시에 표시하는 오버레이.

| 구성 | 내용 |
|------|------|
| 분할선 | 화면 중앙 수직선 (2px, 반투명 화이트) |
| 좌측 | Player 1 카메라 영역 + Player Graphic |
| 우측 | Player 2 카메라 영역 + Player Graphic |
| 보드 | 하단 중앙에 Board Graphic (양측 공유) |

**표시 조건**: 헤즈업(2인 남았을 때) 자동 활성화 옵션. 운영자 수동 토글.

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| divider_position | 0.3~0.7 | 분할선 위치 (0.5 = 정중앙) |
| divider_color | CSS color | 분할선 색상 |
| divider_width | 1~4px | 분할선 두께 |
| auto_activate | bool | 헤즈업 시 자동 활성화 |

## 4.13 Heads-Up History

헤즈업 대결의 누적 전적을 표시하는 오버레이.

| 구성 | 내용 |
|------|------|
| Player 1 승수 | 좌측 승리 횟수 |
| Player 2 승수 | 우측 승리 횟수 |
| 총 핸드 수 | 대결 핸드 수 |
| 칩 이동 | 시작 대비 칩 변동량 |

**표시 조건**: 헤즈업 모드에서 운영자 수동 토글.

### 커스터마이징 속성

| 속성 | 범위 | 설명 |
|------|------|------|
| x, y | 0~1920, 0~1080 | 배치 좌표 (px) |
| width | 200~600 | 너비 (px) |
| height | 60~200 | 높이 (px) |
| show_chip_movement | bool | 칩 이동량 표시 여부 |

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-11 | v1.0.0 | EBS-UI-Design-v3.prd.md §4에서 분리 | 설계 내용 방대, 개발 시 별도 진행하기에 분리 |

---

**Version**: 1.0.0 | **Updated**: 2026-03-11
