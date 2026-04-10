---
doc_type: "design-spec"
doc_id: "PRD-0004-ElementCatalog"
version: "1.1.0"
status: "draft"
parent_doc: "PRD-0004-core.md"
last_updated: "2026-03-03"
---

# PRD-0004: Element Catalog

> 개발자가 React 컴포넌트를 구현할 때 참조하는 요소 사전.
> **읽는 법**: 탭 → 서브그룹 → 요소 순서로 찾는다. 각 요소의 ID는 문서 간 교차 참조에 사용된다.
>
> 관련 문서:
> - [core.md](PRD-0004-core.md) — 범위, 우선순위, 변환 원칙
> - [pokergfx-analysis.md](PRD-0004-pokergfx-analysis.md) — PokerGFX 원본 289개 매핑
> - [feature-interactions.md](PRD-0004-feature-interactions.md) — 탭/기능 간 상호작용 상세

---

## 요소 총괄 테이블

| 탭 | v1.0 Keep | v2.0 Defer | Drop | 합계 |
|:---|:---------:|:----------:|:----:|:----:|
| Main Window | 14 | 0 | 4 | 18 |
| I/O (Sources+Outputs) | 20 | 5 | 24 | 49 |
| GFX | 19 | 5 | 4 | 28 |
| Rules | 9 | 2 | 1 | 12 |
| Display | 13 | 14 | 3 | 30 |
| System | 13 | 2 | 14 | 29 |
| **합계** | **88** | **28** | **50** | **166** |

> AT 연동(12장)과 Skin/Graphic Editor(13장)는 별도 카운트. Skin Editor 26개 + Graphic Editor 18개 = 44개 전체 v2.0 Defer.

---

## Main Window

시스템 전체를 한눈에 모니터링하고, 5개 설정 탭으로 분기하는 중앙 통제실. 본방송 중 운영자 주의력의 15%가 여기에 할당된다.

> ![Main Window - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180630.png)
>
> ![Main Window - 분석 오버레이](02_Annotated_ngd/01-main-window.png)

### Element Catalog (14개 Keep)

#### 상태 표시 그룹

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| M-01 | Title Bar | AppBar | Keep | — | — | 앱 이름 + 버전 + 윈도우 컨트롤 | 4.1 #1 |
| M-02 | Preview Panel | Canvas | Keep | — | 16:9 종횡비 | 출력 해상도(O-01)와 동일 종횡비, Chroma Key Blue 배경, GFX 오버레이 실시간 렌더링. 출력 Full HD(1920x1080) 기준 리사이징 | 4.1 #2 |
| M-03 | CPU Indicator | ProgressBar | Keep | — | 0~100% | CPU 사용률 + 색상 코딩 (Green<60%, Yellow<85%, Red>=85%) | 4.1 #3 |
| M-04 | GPU Indicator | ProgressBar | Keep | — | 0~100% | GPU 사용률 + 동일 색상 코딩 | 4.1 #3 |
| M-05 | RFID Status | Icon+Badge | Keep | — | 7색 상태 | Green=정상, Grey=보안 링크, Blue=미등록, Black=중복, Magenta=중복, Orange=응답없음, Red=미연결 | 4.1 #3 |
| M-06 | RFID Connection Icon | Icon | Keep | — | — | 연결 시 녹색 USB/WiFi 아이콘, 미연결 시 경고 아이콘 | 4.1 #3 |

#### 보안 제어 그룹

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| M-07 | Lock Toggle | IconButton | Keep | — | — | 잠금 시 모든 탭 설정 변경 불가 | 4.1 #3 |

#### 액션 버튼 그룹

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| M-11 | Reset Hand | ElevatedButton | Keep | — | — | 현재 핸드 초기화, 확인 다이얼로그 | 4.1 #5 |
| M-12 | Settings | IconButton | Keep | — | — | 전역 설정 다이얼로그 (테마, 언어, 단축키) | 4.1 #5 |
| M-13 | Register Deck | ElevatedButton | Keep | — | — | 52장 RFID 일괄 등록, 진행 다이얼로그 | 4.1 #6 |
| M-14 | Launch AT | ElevatedButton | Keep | — | — | Action Tracker 실행/포커스 전환 (F8) | 4.1 #7 |

#### Tab Navigation

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| M-08 | Tab Bar | TabBar | Keep | — | 5탭 | I/O, GFX, Rules, Display, System | PGX |
| M-09 | Status Bar | StatusBar | Keep | — | — | 하단 상태 표시줄 | PGX |
| M-10 | Shortcut Bar | ToolBar | Keep | — | — | 단축키 안내 바 | PGX |

> **Drop**: ~~#4~~ Secure Delay+Preview (Output 파이프라인에서 처리), ~~#8~~ Studio (방송 워크플로우 무관), ~~#9~~ Split Recording (SV-030 Drop 확정), ~~#10~~ Tag Player (AT에서 처리)

---

## I/O 탭 (Sources+Outputs 통합)

Sources와 Outputs를 단일 탭으로 통합한 입출력 파이프라인 설정 화면. 2섹션: Input(상단) + Output(하단). PokerGFX 원본의 Output Mode Selector(S-00)는 Drop 확정 (EBS에서 불필요 — ATEM 수동 전환). EBS에서는 Fill & Key 모드를 기본으로 고정하고, Chroma Key는 S-11에서 개별 제어.

> ![Sources 탭 - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180637.png)
>
> ![Sources 탭 - 분석 오버레이](02_Annotated_ngd/02-sources-tab.png)
>
> ![Outputs 탭 - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180645.png)
>
> ![Outputs 탭 - 분석 오버레이](02_Annotated_ngd/03-outputs-tab.png)

### Element Catalog

#### Input 섹션 (12개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| S-01 | Video Sources Table | DataTable | Keep | — | — | NDI/캡처카드/네트워크 카메라 목록 | S-01 |
| S-03 | L Column | DataColumn | Keep | — | — | 좌측 비디오 소스 할당 (X 표시) | S-03 |
| S-04 | Format/Input/URL | DataColumn | Keep | — | — | 소스 포맷 및 입력 URL 표시 | S-04 |
| S-11 | Chroma Key Enable | Checkbox | Keep | — | — | 크로마키 활성화 | S-11 |
| S-12 | Background Colour | ColorPicker | Keep | #0000FF | — | 배경색 설정 | S-12 |
| S-13 | Switcher Source | Dropdown | Keep | — | — | ATEM 스위처 연결. Fill & Key 모드에서만 표시 | S-13 |
| S-14 | ATEM Control | Checkbox | Keep | — | — | ATEM 스위처 제어 활성화. Fill & Key 모드에서만 표시 | S-14 |
| S-25 | R Column | DataColumn | Keep | — | — | 우측 비디오 소스 할당 (X 표시) | S-25 |
| S-26 | Cycle Column | DataColumn | Keep | — | — | 소스 순환 표시 시간 (초, 0=제외) | S-26 |
| S-27 | Status Column | DataColumn | Keep | — | — | 소스 활성/비활성 (ON/OFF) | S-27 |
| S-28 | Action (Preview/Settings) | DataColumn | Keep | — | — | Preview 토글 + Settings 버튼 | S-28 |
| S-29 | ATEM IP | TextField | Keep | — | — | ATEM 스위처 IP 주소 입력. Fill & Key 모드에서만 표시 | S-29 |

> **v2.0 Defer**: S-02(Add Network Camera), S-07~S-08(카메라 모드/헤즈업 — Auto Camera Control 전제)
> **Drop**: S-00(Output Mode Selector — EBS에서 불필요, ATEM 수동 전환), S-05~S-06(Board Cam Hide GFX/Auto Camera Control), S-09~S-10(Follow Players/Board), S-15~S-16(Board Sync/Crossfade), S-17~S-18(Audio Input Source/Audio Sync), S-19~S-24(추가 감축)

#### Output 섹션 (8개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| O-01 | Video Size | Dropdown | Keep | — | 1080p/4K | 출력 해상도 | O-01 |
| O-02 | 9x16 Vertical | Checkbox | Keep | — | — | 세로 모드 (모바일) | O-02 |
| O-03 | Frame Rate | Dropdown | Keep | — | 30/60fps | 프레임레이트 선택 | O-03 |
| O-04 | Live Video/Audio/Device | DropdownGroup | Keep | — | — | Live 파이프라인 3개 드롭다운 (DeckLink/NDI) | O-04 |
| O-05 | Live Key & Fill | Checkbox | Keep | — | — | Live Fill & Key 출력. 외부 키잉 지원 장치 선택 시 활성화 | O-05 |
| O-18 | Fill & Key Color | ColorPicker | Keep | #FF000000 | — | Key 신호 배경색. EBS 신규 | O-18 |
| O-19 | Fill/Key Preview | DualPreview | Keep | — | — | Fill 신호와 Key 신호 나란히 미리보기. EBS 신규 | O-19 |
| O-20 | DeckLink Channel Map | ChannelMap | Keep | — | — | Live Fill/Key → DeckLink 포트 매핑. EBS 신규 | O-20 |

> **v2.0 Defer**: O-06~O-07(Delay 파이프라인)
> **Drop**: O-08~O-12(Delay 관련), O-14(Virtual Camera), O-15(Recording Mode), O-16~O-17(Streaming)

---

## GFX 탭 (GFX 1 핵심 유지)

GFX 1 탭을 직접 계승하는 배치/연출 설정 화면. 보드와 플레이어 그래픽의 위치, 카드 공개 방식, 등장/퇴장 애니메이션, 스킨 정보를 설정한다. 4서브그룹: Layout > Card & Player > Animation > Branding.

> ![GFX 1 탭 - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180649.png)
>
> ![GFX 1 탭 - 분석 오버레이](02_Annotated_ngd/04-gfx1-tab.png)

### Element Catalog

#### Layout 서브그룹 (6개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-01 | Board Position | Dropdown | Keep | — | Left/Right/Centre/Top | 보드 카드 위치. 항상 화면 하단 배치 | GFX1 #2 |
| G-02 | Player Layout | Dropdown | Keep | — | Horizontal/Vert-Bot-Spill/Vert-Bot-Fit/Vert-Top-Spill/Vert-Top-Fit | 플레이어 배치 모드 | GFX1 #4 |
| G-03 | X Margin | NumberInput | Keep | 0.04 | 0.0~1.0 | 좌우 여백 % (정규화 좌표) | GFX1 #41 |
| G-04 | Top Margin | NumberInput | Keep | 0.05 | 0.0~1.0 | 상단 여백 % | GFX1 #44 |
| G-05 | Bot Margin | NumberInput | Keep | 0.04 | 0.0~1.0 | 하단 여백 % | GFX1 #47 |
| G-06 | Leaderboard Position | Dropdown | Keep | — | Centre/Left/Right | 리더보드 위치 | GFX1 #14 |

#### Card & Player 서브그룹 (5개)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-14 | Reveal Players | Dropdown | Keep | — | Immediate/On Action/After Bet/On Action + Next | 카드 공개 시점 | GFX1 #6 |
| G-15 | How to Show Fold | Dropdown+NumberInput | Keep | — | Immediate/Delayed + 초 | 폴드 표시 방식 + 지연 시간 | GFX1 #8,#10 |
| G-16 | Reveal Cards | Dropdown | Keep | — | Immediate/After Action/End of Hand/Showdown Cash/Showdown Tourney/Never | 카드 공개 연출 | GFX1 #12 |
| G-22 | Show Leaderboard | Checkbox+Settings | Keep | — | — | 핸드 후 리더보드 자동 표시 + 설정 | GFX1 #53,#54 |
| G-23 | Show PIP Capture | Checkbox+Settings | Defer | — | — | 핸드 후 PIP 표시. GC-023 Defer | GFX1 #55,#56 |

#### Animation 서브그룹 (4개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-17 | Transition In | Dropdown+NumberInput | Keep | — | TBD | 등장 애니메이션 + 시간(초). SV-014 Keep | GFX1 #16 |
| G-18 | Transition Out | Dropdown+NumberInput | Keep | — | TBD | 퇴장 애니메이션 + 시간(초). SV-014 Keep | GFX1 #20 |
| G-19 | Indent Action Player | Checkbox | Keep | — | — | 액션 플레이어 들여쓰기 | GFX1 #46 |
| G-20 | Bounce Action Player | Checkbox | Keep | — | — | 액션 플레이어 바운스 효과. SV-015 Keep | GFX1 #52 |

#### Branding 서브그룹 (8개)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-10 | Sponsor Logo 1 | ImageSlot | Keep | — | — | Leaderboard 위치 스폰서 로고. SV-016 Keep | GFX1 #35 |
| G-11 | Sponsor Logo 2 | ImageSlot | Keep | — | — | Board 위치 스폰서 로고 | GFX1 #36 |
| G-12 | Sponsor Logo 3 | ImageSlot | Keep | — | — | Strip 위치 스폰서 로고 | GFX1 #37 |
| G-13 | Vanity Text | TextField+Checkbox | Keep | — | — | 테이블 표시 텍스트 + Game Variant 대체 옵션 | GFX1 #39~#40 |
| G-13s | Skin Info | Label | Keep | — | — | 현재 스킨명 + 용량 | GFX1 #32 |
| G-14s | Skin Editor | TextButton | Defer | — | — | 별도 창 스킨 편집기 실행. SV-027 Defer | GFX1 #33 |
| G-15s | Media Folder | TextButton | Defer | — | — | 스킨 미디어 폴더 탐색기. SV-028 Defer | GFX1 #34 |
| G-22s | Show Player Stats | Checkbox+Settings | Defer | — | — | 핸드 후 티커 통계 표시. GC-017 Defer | GFX1 #57,#58 |

> **v2.0 Defer (추가)**: G-25(Heads Up History)
> **Drop**: G-07~G-09(Heads Up Layout/Camera/Custom Y), G-21(Show Action Camera — SV-017)

---

## Rules 탭 (GFX 2에서 규칙 추출)

GFX 2에서 "게임 규칙" 성격의 요소를 추출한 전담 탭. Bomb Pot, Straddle 위치 규칙, 플레이어 표시 방식이 여기에 모인다. 규칙 변경이 그래픽 표시에 직접 영향을 미치므로 방송 시작 전 확인 필요. 2서브그룹: Game Rules(상단) + Player Display(하단).

> ![GFX 2 탭 - PokerGFX 원본 (Rules 원본)](../../../images/pokerGFX/스크린샷%202026-02-05%20180652.png)
>
> ![GFX 2 탭 - 분석 오버레이 (Rules 원본)](02_Annotated_ngd/05-gfx2-tab.png)

### Element Catalog

#### Game Rules 서브그룹 (4개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-52 | Move Button Bomb Pot | Checkbox | Keep | — | — | 봄팟 후 딜러 버튼 이동 여부 | GFX2 #8 |
| G-53 | Limit Raises | Checkbox | Keep | — | — | 유효 스택 기반 레이즈 제한 | GFX2 #9 |
| G-55 | Straddle Sleeper | Dropdown | Keep | — | TBD | 스트래들 위치 규칙 (버튼/UTG 이외 = 슬리퍼) | GFX2 #10 |
| G-56 | Sleeper Final Action | Dropdown | Keep | — | TBD | 슬리퍼 스트래들 최종 액션 여부 | GFX2 #11 |

> **v2.0 Defer**: G-54(Allow Rabbit Hunting — 래빗 헌팅 허용. v1.0 방송 필수 기능 기준 미달)

#### Player Display 서브그룹 (5개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-32 | Add Seat # | Checkbox | Keep | — | — | 플레이어 이름에 좌석 번호 추가 | GFX2 #12 |
| G-33 | Show as Eliminated | Checkbox | Keep | — | — | 스택 소진 시 탈락 표시 | GFX2 #13 |
| G-35 | Clear Previous Action | Checkbox | Keep | — | — | 이전 액션 초기화 + 'x to call'/'option' 표시 | GFX2 #17 |
| G-36 | Order Players | Dropdown | Keep | — | TBD | 플레이어 정렬 순서 (To the left of the button 등) | GFX2 #18 |
| G-38 | Hilite Winning Hand | Dropdown | Keep | — | Immediately/After Delay | 위닝 핸드 강조 시점 | GFX2 #20 |

> **v2.0 Defer**: G-39(Hilite Nit Game — 고급 운영 기능)
> **Drop**: G-34(Unknown Cards Secure Mode — RFID 보안 링크 전제)

---

## Display 탭 (GFX 1/2/3에서 표시 추출)

"어떤 형식으로 수치를 표시할지"를 결정하는 전담 탭. GFX 3 전체와 GFX 2의 Leaderboard 옵션을 통합한다. 통화 기호, 정밀도, BB 모드, 블라인드 표시 시점이 여기에 모인다. 4서브그룹: Blinds > Precision > Mode > Outs.

> ![GFX 3 탭 - PokerGFX 원본 (Display 원본)](../../../images/pokerGFX/스크린샷%202026-02-05%20180655.png)
>
> ![GFX 3 탭 - 분석 오버레이 (Display 원본)](02_Annotated_ngd/06-gfx3-tab.png)

### Element Catalog

#### Blinds 서브그룹 (5개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-45 | Show Blinds | Dropdown | Keep | — | Never/When Changed/Always | 블라인드 표시 조건 | GFX3 #8 |
| G-46 | Show Hand # | Checkbox | Keep | — | — | 블라인드 표시 시 핸드 번호 동시 표시 | GFX3 #9 |
| G-47 | Currency Symbol | TextField | Keep | ₩ | — | 통화 기호 | GFX3 #10 |
| G-48 | Trailing Currency | Checkbox | Keep | — | — | 통화 기호 후치 여부 (₩100 vs 100₩) | GFX3 #11 |
| G-49 | Divide by 100 | Checkbox | Keep | — | — | 전체 금액을 100으로 나눠 표시 | GFX3 #12 |

#### Precision 서브그룹 (5개, v1.0 Keep)

> 영역별 독립 수치 형식(리더보드=정확 금액, 방송 화면=k/M 축약)이 방송 품질에 직결. SV-018 Keep.

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-50a | Leaderboard Precision | Dropdown | Keep | — | Exact Amount/Smart k-M/Divide | 리더보드 수치 형식 | GFX3 #13 |
| G-50b | Player Stack Precision | Dropdown | Keep | Smart k-M | TBD | 플레이어 스택 표시 형식 | GFX3 #14 |
| G-50c | Player Action Precision | Dropdown | Keep | Smart Amount | TBD | 액션 금액 형식 | GFX3 #15 |
| G-50d | Blinds Precision | Dropdown | Keep | Smart Amount | TBD | 블라인드 수치 형식 | GFX3 #16 |
| G-50e | Pot Precision | Dropdown | Keep | Smart Amount | TBD | 팟 수치 형식 | GFX3 #17 |

> **Drop**: G-50f(Twitch Bot Precision), G-50g(Ticker Precision), G-50h(Strip Precision) — 해당 기능 자체가 Drop

#### Mode 서브그룹 (3개, v1.0 Keep)

> SV-019 Keep. 토너먼트에서 BB 배수 표시는 시청자 이해도 향상 기본 기능.

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-51a | Chipcounts Mode | Dropdown | Keep | — | Amount/BB | 칩카운트 표시 모드 | GFX3 #21 |
| G-51b | Pot Mode | Dropdown | Keep | — | Amount/BB | 팟 표시 모드 | GFX3 #22 |
| G-51c | Bets Mode | Dropdown | Keep | — | Amount/BB | 베팅 표시 모드 | GFX3 #23 |

#### Outs 서브그룹 (3개, v2.0 Defer)

> Equity 엔진과 밀접하게 연관. True Outs(G-42)는 정밀 계산 알고리즘 전제. v2.0 Defer.

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| G-40 | Show Outs | Dropdown | Defer | — | Never/Heads Up/All In/Always | 아웃츠 표시 조건 | GFX3 #2 |
| G-41 | Outs Position | Dropdown | Defer | — | Left/Right | 아웃츠 화면 표시 위치 | GFX3 #3 |
| G-42 | True Outs | Checkbox | Defer | — | — | 정밀 아웃츠 계산 알고리즘 활성화 | GFX3 #4 |

> **v2.0 Defer (추가)**: G-26~G-31(Leaderboard 옵션 6개 — Knockout Rank/Chipcount %/Eliminated/Cumulative Winnings/Hide/Max BB Multiple), G-37(Show Hand Equities), G-43~G-44b(Score Strip/Order Strip By/Show Eliminated in Strip), G-57(Ignore Split Pots)

---

## System 탭 (기존 유지 + 확장)

RFID 리더 연결, Action Tracker 접근 정책, 시스템 진단, 고급 설정을 관리하는 탭. RFID 섹션을 상단으로 이동하고 라이선스 관련 항목 4개를 제거. 5구역: Table(최상단) + RFID(상단) + AT(중단) + Diagnostics(하단) + Startup.

> ![System 탭 - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180624.png)
>
> ![System 탭 - 분석 오버레이](02_Annotated_ngd/08-system-tab.png)

### Element Catalog

#### Table 서브그룹 (2개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| Y-01 | Table Name | TextField | Keep | — | — | 테이블 식별 이름 | #2 |
| Y-02 | Table Password | TextField | Keep | — | — | AT 접속 비밀번호 | #6 |

#### RFID 서브그룹 (5개, v1.0 Keep)

> RFID 연결이 방송 시작의 첫 번째 전제 조건. 상단 배치.

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| Y-03 | RFID Reset | TextButton | Keep | — | — | RFID 시스템 초기화 (재시작 없이 연결 재설정) | #3 |
| Y-04 | RFID Calibrate | TextButton | Keep | — | — | 안테나별 캘리브레이션 (1회 설정) | #3 |
| Y-05 | UPCARD Antennas | Checkbox | Keep | — | — | UPCARD 안테나로 홀카드 읽기 활성화 | #16 |
| Y-06 | Disable Muck | Checkbox | Keep | — | — | AT 모드 시 muck 안테나 비활성 | #17 |
| Y-07 | Disable Community | Checkbox | Keep | — | — | 커뮤니티 카드 안테나 비활성 | #18 |

#### AT 서브그룹 (2개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| Y-13 | Allow AT Access | Checkbox | Keep | — | — | AT 접근 허용. 비활성 시 AT Auto 모드만 가능 | #20 |
| Y-14 | Predictive Bet | Checkbox | Keep | — | — | 베팅 예측 자동완성 (초기 입력 기반) | #21 |

#### Diagnostics 서브그룹 (3개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| Y-09 | Table Diagnostics | TextButton | Keep | — | — | 안테나별 상태/신호 강도 별도 창 | #23 |
| Y-10 | System Log | TextButton | Keep | — | — | 로그 뷰어 (실시간 이벤트/오류 로그) | #25 |
| Y-12 | Export Folder | FolderPicker | Keep | — | — | JSON 핸드 히스토리 내보내기 폴더 지정 | #27 |

#### Startup 서브그룹 (1개, v1.0 Keep)

| ID | 요소 | 컴포넌트 | v1.0 | 기본값 | 유효 범위 | 비고 | 원본 |
|:--:|------|---------|:----:|--------|----------|------|:----:|
| Y-22 | Auto Start | Checkbox | Keep | — | — | OS 시작 시 EBS Server 자동 실행 | #19 |

> **v2.0 Defer**: Y-08(Hardware Panel — CPU/GPU/OS 자동 감지), Y-24(버전 업데이트)
> **Drop**: Y-11(Secure Delay Folder), Y-15(Kiosk Mode), Y-16~Y-21(MultiGFX/Sync Stream/Sync Skin/No Cards/Disable GPU/Ignore Name Tags), Y-23(Stream Deck), Y-25(WiFi — EBS 유선 환경)
> **Drop (라이선스 4개)**: PokerGFX 라이선스 키/활성화 코드/라이선스 서버/시리얼 번호 — EBS 자체 시스템에서 불필요

---

## Action Tracker 연동

Action Tracker(AT)는 GfxServer와 완전히 분리된 별도 앱. GfxServer Settings Window가 준비 단계의 설정 도구라면, AT는 본방송 중 실시간 게임 진행을 입력하는 운영 도구다 (본방송 주의력 85%).

AT 실행 단축키: `F8` (= M-14 Launch AT 버튼)

### GfxServer 연결 요소

| GfxServer 요소 | AT와의 관계 |
|---------------|------------|
| **M-14 Launch AT** | AT 앱 실행 / 포커스 전환 (F8) |
| **Y-13 Allow AT Access** | "Track the Action" 시작 허용. 비활성 시 Auto 모드만 |
| **Y-14 Predictive Bet** | 베팅 자동완성 활성화 |

### AT 26개 기능-GfxServer 매핑

| AT Feature ID | AT 기능 | GfxServer 연결 요소 |
|:------------:|---------|-------------------|
| AT-001 | Network 연결 상태 | WebSocket 서버 주소 (Y 그룹 네트워크 설정) |
| AT-002 | Table 연결 상태 | Y-01 Table Name, Y-02 Password |
| AT-003 | Stream 상태 | ~~O-15, O-16 Drop 확정~~ — v2.0 재설계 필요 |
| AT-004 | Record 상태 | ~~O-15 Drop 확정~~ — v2.0 재설계 필요 |
| AT-005 | 게임 타입 선택 | Game Engine 내부 / G-45 Show Blinds 연동 |
| AT-006 | Blinds 표시 | G-45 Show Blinds, G-46 Show Hand # |
| AT-007 | Hand 번호 추적 | G-46 Show Hand # (화면 동기) |
| AT-008 | 10인 좌석 레이아웃 | G-02 Player Layout |
| AT-009 | 플레이어 상태 표시 | G-14 Reveal Players, G-15 How to Show Fold |
| AT-010 | Action-on 하이라이트 | G-19 Indent Action Player, G-20 Bounce Action Player |
| AT-011 | 포지션 표시 | Player Overlay H (포지션 코드) |
| AT-012~017 | 액션 버튼 / 베팅 입력 | Server GameState 내부 처리 |
| AT-018 | Min/Max 범위 표시 | G-53 Limit Raises (유효 스택 기반) |
| AT-019~020 | Community Cards 표시/업데이트 | RFID 자동 / AT 수동 입력 폴백 |
| AT-021 | HIDE GFX | GfxServer Preview Canvas 즉시 숨김 신호 |
| AT-022 | TAG HAND | Hand History DB 연동 (v2.0 Defer) |
| AT-023 | ADJUST STACK | Player Overlay G (Stack 표시) 즉시 반영 |
| AT-024 | CHOP | Server GameState 팟 분배 로직 (v2.0 Defer) |
| AT-025 | RUN IT 2x | G-52 Move Button Bomb Pot 연동 (v2.0 Defer) |
| AT-026 | MISS DEAL | M-11 Reset Hand 동등 처리 (v2.0 Defer) |

---

## Skin/Graphic Editor (v2.0 Defer 전체)

> **v2.0 Defer 대상 전체**. v1.0에서 G-14s(Skin Editor 버튼)는 비활성(회색) 노출, 클릭 불가.

> ![Skin Editor - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180715.png)
>
> ![Skin Editor - 분석 오버레이](02_Annotated_ngd/09-skin-editor.png)
>
> ![Graphic Editor Board - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180720.png)
>
> ![Graphic Editor Board - 분석 오버레이](02_Annotated_ngd/10-graphic-editor-board.png)
>
> ![Graphic Editor Player - PokerGFX 원본](../../../images/pokerGFX/스크린샷%202026-02-05%20180728.png)
>
> ![Graphic Editor Player - 분석 오버레이](02_Annotated_ngd/11-graphic-editor-player.png)

Skin Editor와 Graphic Editor는 방송 그래픽 테마 편집 도구. 본방송 중에는 사용하지 않는 사전 준비 작업이므로 탭이 아니라 별도 창으로 분리.

| 도구 | 진입 경로 | 역할 |
|------|----------|------|
| Skin Editor | Main Window Skin 버튼 (별도 창) | 스킨 전체 테마 편집 — 색상, 폰트, 카드 이미지, 레이아웃 |
| Graphic Editor | Skin Editor에서 요소 클릭 (별도 창) | 개별 요소 픽셀 단위 편집 — 위치, 크기, 애니메이션 |

### Skin Editor (26개, SK-01~SK-26)

변환 요약: PokerGFX 37개 → EBS 26개.

| # | 그룹 | 요소 | 설명 |
|:-:|------|------|------|
| SK-01 | Info | Name | 스킨 이름 |
| SK-02 | Info | Details | 설명 텍스트 |
| SK-03 | Info | Remove Transparency | 크로마키 투명도 제거 |
| SK-04 | Info | 4K Design | 4K(3840x2160) 기준 디자인 선언. 체크 시 Graphic Editor 좌표계 전환 |
| SK-05 | Info | Adjust Size | 크기 슬라이더 |
| SK-06 | Elements | 10 Buttons | Strip~Field 각 요소 → Graphic Editor 진입 버튼 |
| SK-07 | Text | All Caps | 대문자 변환 |
| SK-08 | Text | Reveal Speed | 텍스트 등장 속도 |
| SK-09 | Text | Font 1/2 | 1차/2차 폰트 |
| SK-10 | Text | Language | 다국어 설정 |
| SK-11 | Cards | Card Preview | 4수트 + 뒷면 미리보기 |
| SK-12 | Cards | Add/Replace/Delete | 카드 이미지 관리 |
| SK-13 | Cards | Import Card Back | 뒷면 이미지 |
| SK-14 | Player | Variant | 게임 타입 선택 |
| SK-15 | Player | Player Set | 게임별 세트 |
| SK-16 | Player | Edit/New/Delete | 세트 관리 |
| SK-17 | Player | Crop to Circle | 원형 크롭 |
| SK-18 | Player | Country Flag | 국기 모드 |
| SK-19 | Player | Edit Flags | 국기 이미지 편집 |
| SK-20 | Player | Hide Flag After | 자동 숨김 (초) |
| SK-21 | Actions | Import | 스킨 가져오기 |
| SK-22 | Actions | Export | 스킨 내보내기 |
| SK-23 | Actions | Download | 온라인 다운로드 |
| SK-24 | Actions | Reset | 기본 초기화 |
| SK-25 | Actions | Discard | 변경 취소 |
| SK-26 | Actions | Use | 현재 적용 |

### Graphic Editor (18개 = 공통 10 + Player 전용 8)

변환 요약: PokerGFX 87개(Board 39 + Player 48) → EBS 18개. Board/Player 단일 에디터 통합.

#### Board/공통 편집 기능 (10개)

| 기능 | 설명 |
|------|------|
| Element 선택 | 드롭다운으로 편집 대상 선택 |
| Position (LTWH) | Left/Top/Width/Height. Design Resolution(SK-04) 기준 픽셀 정수값 |
| Anchor | 해상도 변경 시 요소 기준점. TopLeft/TopRight/BottomLeft/BottomRight/Center/TopCenter/BottomCenter |
| Coordinate Display | 현재 출력 해상도 기준 실제 픽셀값 미리보기 (읽기 전용) |
| Z-order | 레이어 겹침 순서 |
| Angle | 요소 회전 |
| Animation In/Out | 등장/퇴장 + 속도 슬라이더 |
| Transition | Default/Pop/Expand/Slide |
| Text | 폰트, 색상, 강조색, 정렬, 그림자 |
| Background Image | 요소 배경 |

#### Player Overlay 요소 (8개)

| 코드 | 요소 | 설명 |
|:----:|------|------|
| A | Player Photo | 프로필 이미지 |
| B | Hole Cards | 홀카드 2~5장 |
| C | Name | 플레이어 이름 |
| D | Country Flag | 국적 국기 |
| E | Equity % | 승률 |
| F | Action | 최근 액션 |
| G | Stack | 칩 스택 |
| H | Position | 포지션 (D/SB/BB) |

---

## 공통 레이아웃 및 좌표계

모든 탭이 공유하는 기본 구조: **Title Bar → Preview Panel(좌, 16:9 Chroma Key) + Status/액션 버튼(우) → Tab Navigation → Tab Content Area**

### Design Resolution vs Output Resolution vs Preview Scaling

| 개념 | 정의 | 설정 위치 |
|------|------|----------|
| Design Resolution | Graphic Editor에서 좌표를 입력하는 기준 해상도. SK-04(4K Design) 설정에 따라 1920x1080 또는 3840x2160 | SK-04 |
| Output Resolution | 실제 방송 송출 해상도. O-01(Video Size)에서 설정 | O-01 |
| Preview Scaling | UI 내 Preview Panel이 출력 해상도 비율을 유지하며 UI 공간에 맞게 표시 | M-02 |

### 앱 윈도우 크기 정책

- 최소 앱 윈도우: 1280x720 (이하에서는 스크롤 발생)
- 최대: 운영자 모니터 크기에 따라 가변
- Preview(좌) : Control(우) 기본 비율 = 6:4
- 기준 크기: 800x365px (Title Bar 28px + Preview 270px + Status Bar 22px + Shortcut Bar 24px + Watermark 22px)

### GFX 좌표계 원칙

| 단위 | 범위 | 사용 항목 | 해상도 변경 시 처리 |
|------|------|----------|------------------|
| 정규화 좌표 (float) | 0.0~1.0 | Margin % (G-03~G-05). 예: 0.04 = 4% | 변환 불필요. `margin_pixel = margin_normalized x output_width` |
| 기준 픽셀 (int) | 0~1920 또는 0~1080 | Graphic Editor LTWH. Design Resolution 기준 | 스케일 팩터 자동 적용. 예: 1080p L=100 → 4K L=200 |

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-03 | v1.1.0 | Sources Input 섹션 오버레이 1:1 확장 (7→12개): S-03/S-04/S-14 그룹핑 해제, S-25~S-29 신규 추가. I/O Keep 15→20, 합계 83→88 | 오버레이 #1~#32(30개)와 Element Catalog 불일치 해소 |
| 2026-03-02 | v1.0.0 | 최초 작성 — PRD-0004 v28.0.0 6~13장 + Appendix A에서 추출 | 개발자 참조 문서 분리 |

---

**Version**: 1.1.0 | **Updated**: 2026-03-03
