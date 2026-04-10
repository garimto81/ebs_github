# EBS 인터페이스 설계서

> **Version**: 1.0.0
> **Date**: 2026-02-17
> **문서 유형**: 인터페이스 상세 설계서
> **관련 문서**: [EBS PRD v23.0.0](pokergfx-prd-v2.md)

---

## Part 1: 인터페이스 멘탈 모델

### 1.1 방송 워크스테이션

포커 방송 시스템의 UI를 이해하려면 물리적 환경을 먼저 알아야 한다. GFX 운영자는 하나의 워크스테이션에서 주 장치(GfxServer)를 중심으로 작업한다:

- **메인 모니터** (GfxServer): 시스템 설정과 모니터링. 마우스/키보드 조작. **주 장치**
- **터치스크린/키보드** (Action Tracker): 실시간 게임 진행 입력. 터치 또는 키보드 입력 모두 지원

준비 단계에서 GfxServer로 시스템을 구성하고, 본방송에서는 Action Tracker가 주 인터페이스로 전환된다. GfxServer는 모니터링 역할로 전환된다.

### 1.2 3단계 시간 모델

방송 시스템 사용은 3개의 시간 단계로 나뉜다. 각 단계에서 사용하는 화면과 기능이 다르다.

| 단계 | 시간 | 주 화면 | 조작 방식 | 긴장도 |
|------|------|---------|----------|--------|
| **준비** (Setup) | 30~60분 | GfxServer | 마우스/키보드 | 낮음 |
| **본방송** (Live) | 수 시간 | Action Tracker | 터치 | **높음** |
| **후처리** (Post) | 10~30분 | GfxServer | 마우스/키보드 | 낮음 |

본방송 중 GfxServer는 "설정 도구"에서 "모니터링 대시보드"로 역할이 전환된다.

### 1.3 주의력 분배

| 장치 | 비중 | 주시 내용 |
|------|:----:|----------|
| **Action Tracker** | 85% | 현재 핸드 진행, 베팅 입력, 특수 상황 |
| **GfxServer** | 15% | RFID 상태, 에러 알림, 프리뷰 |

이 분배가 UI 설계의 핵심 제약 조건이다. Action Tracker는 주변 시야에서도 상태를 파악할 수 있어야 하고, GfxServer는 문제가 생겼을 때만 주의를 끌어야 한다.

### 1.4 자동화 그래디언트

시스템은 가능한 많은 작업을 자동 처리하되, 판단이 필요한 작업만 인간에게 맡긴다.

| 완전 자동 (RFID) | 반자동 (운영자 확인) | 수동 입력 |
|:---:|:---:|:---:|
| 카드 인식 | New Hand 시작 | 베팅 금액 |
| 승률 계산 | Showdown 선언 | 특수 상황 (Chop, Run It 2x) |
| 핸드 평가 | GFX 표시/숨기기 | 수동 카드 입력 (RFID 실패 시) |
| 오버레이 렌더링 | 카메라 전환 | 스택 수동 조정 |
| 핸드 히스토리 저장 | -- | 방송 자막/로고 변경 |

> **반자동이란**: 시스템이 데이터를 자동으로 준비하지만, 최종 실행에는 운영자의 확인(클릭/터치)이 필요한 단계.

### 1.5 정보 보안 경계

같은 게임 데이터가 2가지 보안 수준으로 표시된다. Dual Canvas 아키텍처의 존재 이유다.

| 대상 | Canvas | 홀카드 | Security Delay |
|------|--------|--------|---------------|
| 현장 모니터 | Venue Canvas | 숨김 | 없음 |
| 시청자 | Broadcast Canvas | 공개 | Buffer 적용 가능 |

Outputs 설정에서 Trustless Mode를 활성화하면 Venue Canvas에 어떤 상황에서도 홀카드가 표시되지 않는다.

---

## Part 2: GfxServer 탭별 상세

### 2.1 공통 레이아웃

GfxServer(PokerGFX Server 3.111)는 WinForms 기반 단일 창 애플리케이션이다. 실제 스크린샷에서 확인한 구조:

**상단 영역** (고정):
- 좌측 60%: GPU 프리뷰 영역 (파란색 Chroma Key 배경, 렌더링 결과 실시간 표시)
- 우측 상단: CPU/GPU 상태 표시등 (녹색/빨간색 사각형) + 비활성화 아이콘(빨간 원) + 잠금 아이콘(빨간 자물쇠)
- 우측: Secure Delay 체크박스, Preview 체크박스(체크 시 GPU 프리뷰 활성화)
- 우측: 녹화 상태 표시(빨간 점)
- 우측: 주요 액션 버튼 세로 배치

**주요 액션 버튼** (우측, 수직 배치):

| 버튼 | 기능 |
|------|------|
| Reset Hand | 현재 핸드 초기화 |
| 설정 (톱니바퀴) | 시스템 설정 다이얼로그 |
| 잠금 (자물쇠) | 화면 잠금 |
| Register Deck | 새 덱 등록 (RFID 카드 매핑) |
| Launch Action Tracker | AT 앱 실행 |
| Studio | 스튜디오 모드 전환 |
| Split Recording | 분할 녹화 시작/중지 |
| Tag Player | 플레이어 태그 지정 |

**탭 영역** (하단): Sources, Outputs, GFX 1, GFX 2, GFX3, Commentary, System 7개 탭. 탭 전환 시 하단 콘텐츠만 변경되며 상단 프리뷰 + 액션 버튼은 유지된다.

![서버 메인 윈도우 와이어프레임](images/prd/server-01-main-window.png)

> *참고: 실제 스크린샷 180630 기준. 타이틀바 "PokerGFX Server 3.111 (C) 2011-24"*

### 2.2 Main Window

상단 공통 영역이 곧 Main Window 역할을 한다. 탭을 선택하지 않은 초기 상태에서도 GPU 프리뷰, 상태 표시, 액션 버튼이 항상 표시된다.

**상태 표시줄** (우측 상단):
- CPU 표시등: 정상(녹색)/과부하(빨간색) 사각형
- GPU 표시등: 정상(녹색)/과부하(빨간색) 사각형
- 비활성화 아이콘: 빨간 원(비활성 시), 정상 시 녹색
- 잠금 아이콘: 빨간 자물쇠(잠금 시), 정상 시 녹색
- Secure Delay: 체크박스 (보안 딜레이 활성화/비활성화)
- Preview: 체크박스 (GPU 프리뷰 표시 토글, 기본 체크됨)
- 녹화 상태: 빨간 점 (녹화 중 표시)

### 2.3 Sources 탭

비디오 입력 소스를 등록하고 속성을 조절한다. 실제 스크린샷 180637 기준.

![Sources 탭 와이어프레임](images/prd/server-02-sources.png)

**비디오 소스 목록** (상단 테이블):

| 열 | 설명 |
|----|------|
| Device | 장치명 (예: "DAWN-KO-DT (Adobe Premiere I)", "Integrated Camera") |
| Format / Input / URL | 입력 형식 (예: "YUY2 2592x1944@24.00p 4:3", "\<Auto/Not Specified\>") |
| Action | Preview/Settings 버튼 |
| L/R | 좌/우 미러 토글 (X 표시) |
| Cycle | 순환 설정 |
| Status | ON/OFF |

**카메라 제어** (우측 패널):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Board Cam Hide GFX | 체크박스 | 체크됨 |
| Auto Camera Control | 체크박스 | 체크됨 |
| Mode | 드롭다운 | Static |
| Heads Up Split Screen | 체크박스 | 체크됨 |
| Follow Players | 체크박스 | 해제 |
| Follow Board | 체크박스 | 해제 |
| Linger on Board | 스핀박스 (초) | 3초 |
| Post Bet | 드롭다운 | Default |
| Post Hand | 드롭다운 | Default |

**하단 설정**:
- Background key colour + Chroma Key 체크박스 (체크됨)
- Audio: No Audio Input 드롭다운, Sync(0 mS), Level 슬라이더
- External Switcher Source: 드롭다운 (-- None --), ATEM Control 체크박스 + IP
- Board Sync: 스핀박스 (0 mS)
- Crossfade: 스핀박스 (300 mS)
- Add Network Camera 버튼
- Player: 드롭다운 + View 버튼

### 2.4 Outputs 탭

방송 출력 대상을 설정하고 보안 모드를 구성한다. 실제 스크린샷 180645 기준.

![Outputs 탭 와이어프레임](images/prd/server-03-outputs.png)

**비디오 포맷** (좌측 상단):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Video Size | 드롭다운 | 1920 x 1080 |
| 9x16 Vertical | 체크박스 | 해제 |
| Frame Rate | 스핀박스 + 드롭다운 | 60.00 / 60 |

**Live/Delay 이중 출력** (좌측 중앙):

| 설정 | Live | Delay |
|------|------|-------|
| Video Preview | 드롭다운 (Disabled) | 드롭다운 (Disabled) |
| Audio Preview | 드롭다운 (No audio preview) | 드롭다운 (No audio preview) |
| Output Device | 드롭다운 (Disabled) | 드롭다운 (Disabled) |
| Key & Fill | 체크박스 | 체크박스 |

- Virtual Camera: 드롭다운 (Disabled / NDI / Virtual Webcam)

**Security Delay** (우측):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Secure Delay | 스핀박스 (분) | 30 Min |
| Dynamic Delay | 체크박스 + 스핀박스 | 해제, 0 Min |
| Auto Stream | 스핀박스 (분) | 0 Min |
| Show Countdown | 체크박스 | 체크됨 |
| Countdown Lead-Out Video | 드롭다운 | --- No intro --- |
| Countdown Background | 이미지 선택 버튼 | (빈 영역) |

**녹화/스트리밍** (하단):
- Recording Mode: 드롭다운 (Video with GFX 등)
- Twitch Account: 연동 버튼
- ChatBot / Channel Title: 체크박스

### 2.5 GFX1 탭 -- 게임 제어

게임 레이아웃, 카드 공개 방식, 스킨, 스폰서 등을 설정한다. 가장 기능이 많은 탭. 실제 스크린샷 180649 기준.

![GFX1 탭 와이어프레임](images/prd/server-04-gfx1-game.png)

**레이아웃 설정** (좌측):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Board Position | 드롭다운 | Right |
| Player Layout | 드롭다운 | Vert/Bot/Spill |
| Reveal Players | 드롭다운 | Action On |
| How to show a Fold | 드롭다운 + 스핀박스 | Immediate, 1.5초 |
| Reveal Cards | 드롭다운 | Immediate |
| Leaderboard Position | 드롭다운 | Centre |
| Transition In Animation | 드롭다운 + 스핀박스 | Pop, 0.5초 |
| Transition Out Animation | 드롭다운 + 스핀박스 | Slide, 0.4초 |
| Heads Up Layout Left / Right | 드롭다운 | Only in split screen mode |
| Heads Up Camera | 드롭다운 | Camera behind dealer |
| Heads Up Custom Y pos | 체크박스 + 스핀박스 | 0.50% |

**스킨/미디어** (우측 상단):
- 현재 스킨 표시: "Titanium, 1.41 GB"
- Skin Editor 버튼: 스킨 에디터 다이얼로그 열기
- Media Folder 버튼: 미디어 폴더 열기

**스폰서 로고** (우측 중앙):
- "Click to add Leaderboard sponsor logo" + X(삭제)
- "Click to add Board sponsor logo" + X(삭제)
- "Click to add Strip sponsor logo" + X(삭제)
- Vanity: 텍스트 입력 (예: "TABLE 2")
- Replace Vanity with Game Variant: 체크박스

**마진/옵션** (우측 하단):

| 설정 | 기본값 |
|------|--------|
| X Margin | 0.04% |
| Top Margin | 0.05% |
| Bot Margin | 0.04% |
| Show Heads Up History | 해제 |
| Indent Action Player | 체크됨 |
| Bounce Action Player | 체크됨 |
| Show leaderboard after each hand | 해제 |
| Show PIP Capture after each hand | 해제 |
| Show player stats in the ticker after each hand | 해제 |
| Show Action Clock at | 10초 |

### 2.6 GFX2 탭 -- 통계

플레이어 통계와 표시 옵션을 체크박스/드롭다운으로 구성한다. 실제 스크린샷 180652 기준.

![GFX2 탭 와이어프레임](images/prd/server-05-gfx2-stats.png)

**리더보드 설정** (좌측 상단):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Show knockout rank in Leaderboard | 체크박스 | 해제 |
| Show Chipcount % in Leaderboard | 체크박스 | 체크됨 |
| Show eliminated players in Leaderboard stats | 체크박스 | 체크됨 |
| Show Chipcount with Cumulative Winnings | 체크박스 | 해제 |
| Hide leaderboard when hand starts | 체크박스 | 체크됨 |
| Max BB multiple to show in Leaderboard | 스핀박스 | 200 |

**게임 규칙 설정** (좌측 하단):

| 설정 | 기본값 |
|------|--------|
| Move button after Bomb Pot | 해제 |
| Limit Raises to Effective Stack size | 해제 |
| Straddle not on the button or UTG is sleeper | 해제 |
| Sleeper straddle gets final action | 해제 |

**표시 옵션** (우측):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Add seat # to player name | 체크박스 | 해제 |
| Show as eliminated when player loses stack | 체크박스 | 체크됨 |
| Allow Rabbit Hunting | 체크박스 | 해제 |
| Unknown cards blink in Secure Mode | 체크박스 | 체크됨 |
| Hilite Nit game players when | 드롭다운 | At Risk |
| Clear previous action & show 'x to call' / 'option' on action player | 체크박스 | 체크됨 |
| Order players from the first | 드롭다운 | To the left of the button |
| Show hand equities | 드롭다운 | After 1st betting round |
| Hilite winning hand | 드롭다운 | Immediately |
| When showing equity and outs, ignore split pots | 체크박스 | 해제 |

### 2.7 GFX3 탭 -- 방송 연출

Outs, Score Strip, 통화, Chipcount Precision 등 방송 표시 형식을 설정한다. 실제 스크린샷 180655 기준.

![GFX3 탭 와이어프레임](images/prd/server-06-gfx3-broadcast.png)

**Outs/Strip** (좌측):

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Show Outs | 드롭다운 | Heads Up or All In Showdown |
| Outs Position | 드롭다운 | Left |
| True Outs | 체크박스 | 체크됨 |
| Score Strip | 드롭다운 | Off |
| Order Strip by | 드롭다운 | Chip Count |
| Show eliminated players in Strip | 체크박스 | 해제 |
| Show Blinds | 드롭다운 | Never |
| Show hand # with blinds | 체크박스 | 체크됨 |

**통화/표시** (좌측 하단):

| 설정 | 기본값 |
|------|--------|
| Currency Symbol | W |
| Trailing Currency Symbol | 해제 |
| Divide all amounts by 100 | 해제 |

**Chipcount Precision** (우측 상단):

| 요소 | 정밀도 |
|------|--------|
| Leaderboard | Exact Amount |
| Player Stack | Smart Amount ('k' & 'M') |
| Player Action | Smart Amount ('k' & 'M') |
| Blinds | Smart Amount ('k' & 'M') |
| Pot | Smart Amount ('k' & 'M') |
| Twitch Bot | Exact Amount |
| Ticker | Exact Amount |
| Strip | Exact Amount |

**How to display amounts** (우측 하단):

| 요소 | 기본값 |
|------|--------|
| Chipcounts | Amount |
| Pot | Amount |
| Bets | Amount |

### 2.8 Commentary 탭

해설자 연결 및 권한을 설정한다. 다른 탭에 비해 단순한 구성. 실제 스크린샷 180659 기준.

| 설정 | 컨트롤 | 기본값 |
|------|--------|--------|
| Commentary Mode | 드롭다운 | Disabled |
| Password | 텍스트 입력 | (Min. 10 characters to activate) |
| Statistics only (no video or audio) | 체크박스 | 해제 |
| Allow commentator to control leaderboard graphic | 체크박스 | 해제 |
| Commentator camera as well as audio | 체크박스 | 해제 |
| Configure Picture In Picture | 버튼 | -- |
| Allow commentator camera to go full screen | 체크박스 | 체크됨 |

Commentary Mode를 Enabled로 변경하고 10자 이상 비밀번호를 설정해야 해설자가 접속할 수 있다. 해설자는 별도 클라이언트 앱에서 서버에 접속한다.

### 2.9 System 탭

서버 시작 후 가장 먼저 확인하는 화면. 테이블 정보, 라이선스, 하드웨어 진단, RFID/AT 옵션을 관리한다. 실제 스크린샷 180624 기준.

![System 탭 와이어프레임](images/prd/server-08-system.png)

**Table 설정** (좌측 상단):

| 설정 | 컨트롤 |
|------|--------|
| Name | 텍스트 입력 (예: "GGP") + Update 버튼 |
| Pwd | 비밀번호 입력 (예: "CCC") + Update 버튼 |
| Reset | 버튼 (테이블 설정 초기화) |
| Calibrate | 버튼 (RFID 보정) |

**License** (중앙 상단):
- Serial # 표시 (예: 674)
- Check for Updates 버튼
- Updates & support: Evaluation mode 버튼
- PRO license: Evaluation mode 버튼

**시스템 옵션** (좌측 하단):

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| MultiGFX | 다중 GFX 서버 모드 (Master/Slave) | 해제 |
| Sync Stream | 스트림 동기화 | 해제 |
| Sync Skin | 스킨 동기화 | 해제 |
| No Cards | 카드 없이 운영 (데모용) | 해제 |
| Disable GPU Encode | GPU 인코딩 비활성화 | 해제 |
| Ignore Name Tags | 이름 태그 무시 | 체크됨 |

**RFID/AT 옵션** (중앙 하단):

| 옵션 | 기본값 |
|------|--------|
| UPCARD antennas read hole cards in draw & flop games | 해제 |
| Disable muck antenna when in Action Tracker mode | 해제 |
| Disable Community Card antenna for the flop | 해제 |
| Auto Start PokerGFX Server with Windows | 해제 |
| Allow Action Tracker access | 체크됨 |
| Action Tracker Predictive Bet Input | 해제 |
| Action Tracker Kiosk | 해제 |

**진단 정보** (우측):
- Open Table Diagnostics 버튼
- 하드웨어 정보 표시:
  - CPU: Intel(R) Core(TM) i9-14900HX
  - GPU: NVIDIA GeForce RTX 5070 Laptop GPU
  - OS: Windows 11 Pro 64-bit
  - Encoder: NVIDIA
- View System Log 버튼
- Secure Delay Folder 버튼
- Export Folder 버튼
- Stream Deck: 드롭다운 (Disabled/Enabled)

---

## Part 3: 스킨 에디터 상세

### 3.1 Skin Editor 다이얼로그

GFX1 탭의 Skin Editor 버튼으로 열리는 독립 다이얼로그 창. 방송 외형을 커스터마이징한다. 실제 스크린샷 180715 기준.

![Skin Editor 와이어프레임](images/prd/server-09-skin-editor.png)

**상단 정보**:
- Name: 텍스트 입력 (예: "Titanium")
- Details: 텍스트 입력 (예: "Modern, layered skin with neutral colours. Titanium is the default sk...")
- Remove Partial Transparency when Chroma Key Enabled: 체크박스
- Designed for 4K (3840 x 2160): 체크박스

**Adjustments**:
- Adjust Size: 슬라이더 (전체 스킨 크기 비율 조정)
- 색상 조정 안내: "To adjust colours, select an Element from the list below then click 'Adjust Colours'"

**Elements** (9개 요소 버튼 그리드):

| 행 1 | 행 2 | 행 3 |
|------|------|------|
| Board | Blinds | Outs |
| Strip | Hand History | Action Clock |
| Leaderboard | Split Screen Divider | Ticker |
| Field | -- | -- |

각 버튼 클릭 시 해당 요소의 Graphic Editor가 열린다.

**Cards** (우측 상단):
- 4개 슈트(스페이드, 하트, 다이아몬드, 클럽) 카드 이미지 프리뷰
- Add / Replace / Delete 버튼
- Import Card Back 버튼

**Flags**:
- Edit Flags 버튼
- "Country flag does not force player photo mode": 체크박스 (체크됨)
- Hide flag after: 스핀박스 (0.0초, 0=Do not hide)

**Text**:
- Font 1: 드롭다운 (예: "Gotham") + 파일 선택 버튼
- Font 2: 드롭다운 (예: "Gotham") + 파일 선택 버튼
- Text All Caps: 체크박스 (체크됨)
- Text Reveal Speed: 슬라이더
- Language: 버튼

**Player**:
- Variant: 드롭다운 (예: "HOLDEM (2 Cards)")
- Player Set: Uses 드롭다운 (예: "2 Card Games")
- Override Card Set: 체크박스
- Edit / New / Delete 버튼
- Crop player photo to circle: 체크박스

**하단 버튼바** (6개):

| IMPORT | EXPORT | SKIN DOWNLOAD CENTRE | RESET TO DEFAULT | DISCARD | USE |
|--------|--------|---------------------|-----------------|---------|-----|

- USE: 현재 스킨 적용 (강조 표시)
- DISCARD: 변경 취소
- RESET TO DEFAULT: 공장 초기값 복원
- SKIN DOWNLOAD CENTRE: 온라인 스킨 다운로드
- IMPORT/EXPORT: `.vpt/.skn` 파일 가져오기/내보내기

### 3.2 Graphic Editor -- Board

Board, Pot, Blinds, Table Name 등 보드 영역 요소의 위치와 스타일을 편집하는 WYSIWYG 에디터. 실제 스크린샷 180720 기준.

![GE Board 와이어프레임](images/prd/server-10-ge-board.png)

**캔버스 크기**: 296 x 197 픽셀

**상단 도구**:
- Import Image 버튼: 배경 이미지 가져오기
- AT Mode: 드롭다운 (Flop Game 등)

**Element 선택** (우측 상단):
- 드롭다운: Card 1, Card 2, Card 3, Card 4, Card 5, Pot, Blinds, Table Name 등

**Transform 패널**:

| 속성 | 설명 | 예시 |
|------|------|------|
| Left | X 좌표 | 288 |
| Top | Y 좌표 | 0 |
| Width | 폭 | 56 |
| Height | 높이 | 80 |
| Z | Z-order (레이어 순서) | 1 |
| Anchor | 기준점 (Right/Left/Top) | Right, Top |

**Animation 패널**:
- AnimIn: X(비활성화 토글) + 슬라이더
- AnimOut: X(비활성화 토글) + 슬라이더
- Transition In: 드롭다운 (-- Default --)
- Transition Out: 드롭다운 (-- Default --)

**Text 패널**:
- Text Visible: 체크박스
- Font: 드롭다운 (Font 1 - Gotham)
- Colour / Hilite Col: 색상 선택
- Alignment: 드롭다운 (Left)
- Drop Shadow: 체크박스 + 방향 드롭다운 (North)
- Rounded Corners: 스핀박스 (0)
- Margins X/Y: 스핀박스 (0, 0)

**배경/색상**:
- "Click to add Background Image" 영역
- Adjust Colours 버튼
- Triggered by Language text: 체크박스
- OK / Cancel 버튼

**하단 WYSIWYG 프리뷰**: 실시간 보드 레이아웃
- Card 1~5: 스페이드 A, 2, 3, 4, 5 예시
- POT 100,000
- 50,000 / 100,000 블라인드
- TABLE 2 바니티

### 3.3 Graphic Editor -- Player

플레이어 박스의 구성 요소(카드, 이름, 스택, 액션, Equity, 포지션, 국기)를 편집하는 에디터. Board Editor와 동일한 UI 구조. 실제 스크린샷 180728 기준.

![GE Player 와이어프레임](images/prd/server-11-ge-player.png)

**캔버스 크기**: 465 x 120 픽셀

**상단 도구**:
- Player Set: 드롭다운 (예: "2 Card Games")
- Import Image 버튼
- AT Mode: 드롭다운 (with photo 등)

**Element 선택**: Card 1, Card 2, Name, Stack, Action, Equity, Position, Flag 등

**Transform/Animation/Text 패널**: Board Editor와 동일 구조

**하단 WYSIWYG 프리뷰**: 플레이어 박스 템플릿
- 플레이어 사진 (실루엣, 원형/사각형)
- 카드 이미지 (A, 2 스페이드 예시)
- NAME 레이블 + 국기 (호주)
- ACTION 레이블
- STACK 레이블
- POS (포지션)
- 50% (Equity)

### 3.4 Graphic Editor 공통 워크플로우

Skin Editor의 Elements 버튼 → Graphic Editor 열기 → Element 선택 → Transform/Animation/Text 편집 → WYSIWYG 프리뷰 실시간 확인 → OK 적용 또는 Cancel 취소.

Properties(Transform, Text, Animation)에서 숫자를 변경하면 하단 프리뷰가 즉시 갱신된다. 프리뷰에서 요소를 직접 클릭하면 Element 드롭다운이 해당 요소로 전환되고 노란색 선택 테두리가 표시된다.

---

## Part 4: Action Tracker 상세

### 4.1 Action Tracker 개요

Action Tracker는 GfxServer와 별도로 실행되는 독립 앱이다. 별도 태블릿 또는 터치스크린에서 운영하며, 딜러 또는 전담 운영자가 사용한다. 서버와 TCP :8888 연결로 실시간 액션을 전송한다.

GfxServer의 System 탭에서 "Allow Action Tracker access"가 체크되어야 AT 접속이 허용된다. "Launch Action Tracker" 버튼으로 같은 머신에서 직접 실행할 수도 있다.

### 4.2 화면 구성

![Action Tracker 와이어프레임](images/prd/ui-live-action-tracker.png)

**구성 영역**:
- **상단**: 연결 상태 (서버 IP, 연결 여부, 지연 시간)
- **좌석 그리드**: 10인 좌석 (2x5 또는 타원 배치) -- 각 좌석에 이름, 스택, 카드 상태, 현재 액션 표시
- **보드 카드**: 5장 카드 슬롯 (Flop 3 + Turn + River)
- **팟 표시**: 현재 메인 팟 + 사이드 팟
- **하단 액션 버튼**: FOLD, CHECK, CALL, BET, RAISE, ALL-IN
- **특수 컨트롤**: HIDE GFX, TAG, CHOP, RUN IT 2x, MISS DEAL, UNDO

### 4.3 액션 입력 흐름

하나의 핸드는 다음 시퀀스로 진행된다:

1. **New Hand**: 운영자가 New Hand 버튼 터치 → 서버가 핸드 번호 할당, 블라인드 차감
2. **카드 딜**: RFID가 자동 인식 (운영자 개입 불필요). 실패 시 수동 입력 모드 전환
3. **프리플롭 베팅**: 각 플레이어 순서대로 Fold/Check/Call/Bet/Raise/All-In 입력
4. **플롭**: 보드 카드 3장 RFID 인식 → 승률 재계산
5. **턴**: 보드 카드 1장 추가
6. **리버**: 보드 카드 1장 추가
7. **쇼다운**: Showdown 버튼 → 핸드 평가 → 승자 결정 → 팟 분배

각 단계에서 현재 상태에 맞는 버튼만 활성화된다.

**핸드 진행 상태별 버튼 활성화**:

| 상태 | 활성 버튼 | 비활성 버튼 |
|------|----------|-----------|
| New Hand 대기 | New Hand | 모든 액션 |
| 카드 딜 중 | (자동) | -- |
| 베팅 라운드 | Fold, Check/Call, Bet/Raise, All-in | New Hand |
| Showdown | Show, Muck | 베팅 액션 |

**특수 상황 처리**:

| 상황 | 버튼 | 동작 |
|------|------|------|
| 오버레이 숨기기 | HIDE GFX | 방송 화면에서 모든 GFX 일시 제거 |
| 중요 핸드 표시 | TAG HAND | 현재 핸드에 태그 추가 |
| 팟 분배 | CHOP | 팟을 여러 플레이어에게 분할 |
| 더블 런아웃 | RUN IT 2x | 두 번째 보드 생성 |
| 미스딜 | MISS DEAL | 현재 핸드 무효화, 카드 재분배 |
| 되돌리기 | UNDO | 마지막 액션 취소 (최대 5단계) |
| 스택 수정 | ADJUST STACK | 특정 플레이어 칩 수동 변경 |

### 4.4 에러/로딩/비활성 상태

**에러 상태**:

| 에러 유형 | 시각적 표시 | 자동 복구 | 수동 개입 |
|----------|-----------|----------|----------|
| RFID 인식 실패 | 해당 좌석 빨간색, 5초 카운트다운 | 5초 재시도 | 수동 카드 입력 창 자동 표시 |
| 네트워크 끊김 | 상단 연결 상태 회색, 재연결 아이콘 회전 | 30초 자동 재연결 | "수동 재연결" 버튼 활성화 |
| 잘못된 카드 | 해당 좌석 빨간 테두리, "WRONG CARD" 경고 | -- | 카드 제거 후 올바른 카드 재입력 |
| 서버 크래시 | AT 전체 다운 | GAME_SAVE 자동 복원 | 복원 실패 시 수동 재입력 |

**로딩 상태**:

| 로딩 단계 | 예상 시간 | UI 표시 |
|----------|:--------:|---------|
| 서버 연결 | 1~3초 | "Connecting to Server..." 스피너 |
| 게임 상태 동기화 | 0.5~1초 | "Syncing Game State..." |
| GAME_SAVE 복원 | 1~2초 | "Restoring... Hand #[번호]" 프로그레스 바 |

**비활성 상태**:

| 조건 | 비활성 요소 | 시각적 표시 |
|------|-----------|-----------|
| 게임 미시작 | 모든 액션 버튼 | 회색 처리, "Start Game First" |
| All-in 플레이어 | RAISE 버튼 | 회색 처리, 터치 무반응 |
| RFID 오프라인 | Auto 모드 관련 | "RFID Offline" 경고 |
| 서버 미연결 | 전체 UI | 회색 처리, "No Connection" 배너 |

---

## Part 5: Viewer Overlay 상세

### 5.1 오버레이 구성 요소

방송 시청자가 보는 화면에 겹쳐지는 그래픽 요소. GPU에서 실시간 렌더링되어 비디오 소스 위에 합성된다.

| 요소 | 설명 |
|------|------|
| **플레이어 박스** | 홀카드, 이름, 스택, 액션, Equity, 포지션, 국기 |
| **보드 카드** | 커뮤니티 카드 5장 (Flop 3 + Turn + River) |
| **팟 표시** | 메인 팟 + 사이드 팟 |
| **블라인드/핸드 번호** | SB/BB 금액, 현재 핸드 번호 |
| **리더보드** | 칩카운트 순위, 탈락자 표시 |
| **스트립** | 하단 플레이어 요약 바 |
| **액션 클락** | 플레이어 의사결정 시간 제한 |
| **스코어 스트립** | 상/하단 스코어 바 |
| **티커** | 뉴스/정보 스크롤 텍스트 |
| **스폰서 로고** | Leaderboard/Board/Strip 위치 |
| **Lower Third** | 하단 자막 (이벤트명, 바니티) |

### 5.2 오버레이 해부도

![방송 오버레이 구성](images/prd/prd-broadcast-overlay.png)

**정보 계층 설계**:

| 계층 | 요소 | 시선 우선순위 |
|------|------|:--------:|
| **1차** (즉시 인지) | 플레이어 홀카드, 승률 | 가장 높음 |
| **2차** (맥락 파악) | 팟 사이즈, 베팅 액션, 보드 카드 | 중간 |
| **3차** (참고 정보) | 이벤트명, 블라인드, 핸드 번호, 로고 | 낮음 |

1차 정보는 크고 밝게, 3차 정보는 작고 투명하게 표시한다.

**오버레이 요소별 표시 조건**:

| 요소 | 위치 | 정보 계층 | 표시 조건 |
|------|------|:--------:|----------|
| 플레이어 홀카드 | 각 플레이어 근처 | 1차 | Broadcast Canvas만 |
| 승률 | 홀카드 옆 | 1차 | 2인 이상 활성 |
| 팟 사이즈 | 보드 상단 | 2차 | 항상 |
| 베팅 액션 | 현재 플레이어 | 2차 | 액션 발생 시 |
| 보드 카드 | 화면 중앙 | 2차 | Flop 이후 |
| 플레이어 이름/칩 | 각 플레이어 하단 | 2차 | 항상 |
| 이벤트명/블라인드 | 상단 | 3차 | 항상 |
| 로고 | 상단/하단 코너 | 3차 | 항상 |
| 폴드 표시 | 폴드 플레이어 | -- | 폴드 시 회색 처리 |

### 5.3 Dual Canvas 비교

| 구분 | Venue Canvas (현장용) | Broadcast Canvas (방송용) |
|------|---------------------|----------------------|
| **대상** | 현장 관객, 스태프 | TV/스트림 시청자 |
| **홀카드** | 숨김 (Showdown 전까지) | 공개 (홀카드 + 승률) |
| **승률** | 표시 안 함 | 표시 |
| **보드 카드** | 즉시 표시 | 즉시 표시 |
| **팟/베팅** | 즉시 표시 | 즉시 표시 |
| **보안** | Trustless Mode 적용 | Security Delay Buffer 적용 가능 |

현장 대형 화면에 홀카드가 표시되면 플레이어가 상대방 카드를 볼 수 있다. Venue Canvas는 이를 원천 차단한다.

### 5.4 게임 상태별 화면 변화

| 상태 | 오버레이 변화 |
|------|-------------|
| **Pre-Flop** | 홀카드 표시 (Broadcast만), 초기 승률, "PRE-FLOP" 인디케이터 |
| **Flop** | 보드 카드 3장 등장 애니메이션, 승률 재계산, 팟 갱신 |
| **Turn/River** | 보드 카드 추가, 승률 변동, 큰 베팅 시 강조 |
| **All-in** | 승률 바 확대 표시, 남은 카드 자동 전개 옵션 |
| **Showdown** | Venue Canvas에도 카드 공개, 승자 하이라이트 애니메이션 |

---

## Part 6: GfxServer 모니터링 대시보드

### 6.1 본방송 모드 전환

본방송이 시작되면 GfxServer는 "설정 도구"에서 "모니터링 대시보드"로 전환된다. 운영자 주의력의 15%만 할당되므로, 문제 발생 시에만 시선을 끌어야 한다.

![모니터링 대시보드 와이어프레임](images/prd/ui-live-dashboard.png)

### 6.2 모니터링 요소

- **RFID 상태 그리드**: 12대 리더 실시간 상태. 정상(녹색), 경고(노란색), 장애(빨간색)
- **Canvas 프리뷰**: Venue/Broadcast 캔버스 썸네일
- **시스템 메트릭**: CPU, GPU, Memory, FPS. 임계치 초과 시 경고
- **에러 로그**: 최근 에러만 표시, 심각도별 색상 구분

### 6.3 알림 우선순위

| 우선순위 | 상태 | 피드백 방식 |
|:-------:|------|-----------|
| 1 | **긴급 에러** (서버 크래시, GPU 과부하) | 전체 화면 모달 + 경고음 |
| 2 | **복구 가능 에러** (RFID 실패, 네트워크 끊김) | 해당 영역 빨간색 + 카운트다운 |
| 3 | **경고** (FPS 저하, 카드 중복) | 노란색 배너 |
| 4 | **로딩** (Skin 로딩, RFID 초기화) | 회전 스피너 |
| 5 | **정보** (게임 상태 변경, 핸드 종료) | 상태바 텍스트 변경 |

정상 상태에서는 아무 알림도 표시되지 않아야 한다.

---

## Part 7: 시스템 에러/로딩/비활성 상태

### 7.1 에러 상태 설계

방송 중 발생 가능한 에러와 UI 피드백. 모든 에러는 복구 가능해야 하며, 방송을 중단시키지 않는다.

| 에러 유형 | 시각적 표시 | 자동 복구 | 수동 개입 |
|----------|-----------|----------|----------|
| **RFID 인식 실패** | RFID 상태 그리드 빨간색, 5초 카운트다운 | 5초 재시도 | 수동 카드 입력 창 표시 |
| **네트워크 끊김** | 클라이언트 상태 회색, 재연결 아이콘 회전 | 30초 자동 재연결 | "수동 재연결" 버튼 |
| **잘못된 카드** | AT 해당 좌석 빨간 테두리, "WRONG CARD" | -- | 카드 제거 후 재입력 |
| **서버 크래시** | 전체 다운, 자동 재시작 | GAME_SAVE 복원 | 복원 실패 시 수동 재입력 |
| **License 만료** | 시작 시 차단, 모달 다이얼로그 | -- | 라이선스 갱신 |
| **GPU 과부하** | FPS 그래프 빨간색 (30fps 이하), 경고음 | -- | 해상도 낮춤 또는 GFX 숨김 |

### 7.2 로딩 상태 설계

| 로딩 단계 | 예상 시간 | UI 표시 |
|----------|:--------:|---------|
| **서버 시작** | 3~5초 | 스플래시 화면 "Checking License..." |
| **RFID 초기화** | 2~4초 | "Connecting RFID Readers... (0/12)" |
| **Skin 로딩** | 1~3초 | "Loading Skin: [파일명]..." |
| **비디오 소스 검색** | 2~5초 | "Scanning NDI Sources..." |
| **테스트 스캔** | 0.2초 | "200ms OK" 또는 "FAIL" |
| **GAME_SAVE 복원** | 1~2초 | "Restoring... Hand #[번호]" |

예상 로딩 시간이 1초 이상인 경우에만 프로그레스 인디케이터를 표시한다.

### 7.3 비활성 상태 설계

| 조건 | 비활성 요소 | 시각적 표시 | 이유 |
|------|-----------|-----------|------|
| 게임 진행 중 | 게임 시작 버튼 | 회색 처리 | 중복 시작 방지 |
| Auto 모드 활성 | 수동 카드 입력 | 회색, "Auto Mode ON" | RFID 우선 |
| Trustless Mode ON | Venue "Show Hole Cards" | 회색, 체크 불가 | 보안 정책 강제 |
| 에디터 빈 캔버스 | Properties 패널 | 회색, "No Element Selected" | 선택 없음 |
| 클라이언트 미연결 | AT 전송 버튼 | 회색, "No Client" | 전송 대상 없음 |
| RFID 오프라인 | Auto 모드 라디오 | 회색, "RFID Offline" | 하드웨어 장애 |
| License Basic | Advanced 기능 | 회색, "Upgrade to PRO" | 라이선스 제한 |

**비활성 vs 숨김**: "이 기능이 존재하지만 지금은 사용 불가"이면 비활성 표시. "이 모드에서 존재하지 않는 기능"이면 숨김 처리.

---

## Part 8: 예외 처리 흐름

방송 중 발생할 수 있는 예외 상황과 복구 경로.

**RFID 인식 실패**:
1. 카드 배치 → RFID 미인식 (5초 대기)
2. 자동 재인식 시도
3. 성공 → 정상 복귀 / 실패 → 수동 카드 입력 (52장 그리드) → 정상 복귀

**네트워크 끊김**:
1. TCP 연결 끊김 감지
2. KeepAlive 기반 자동 재연결 (30초)
3. 성공 → 정상 복귀 / 실패 → 운영자 알림, 수동 재연결 → 정상 복귀

**잘못된 카드 인식**:
1. RFID가 잘못된 카드 감지
2. 카드 제거 → 올바른 카드 재입력 → 정상 복귀

**서버 크래시**:
1. 자동 재시작
2. GAME_SAVE에서 마지막 저장점 복원 → 정상 복귀

모든 예외 경로는 "정상 진행"으로 돌아온다. 어떤 장애가 발생해도 방송을 계속할 수 있도록 설계되어야 한다.

---

## 부록: 다이어그램 목록

이 문서에서 참조하는 모든 이미지 경로 목록.

**와이어프레임 목업** (기존 파일 재사용):

| 이미지 | 경로 |
|--------|------|
| 서버 메인 윈도우 | `images/prd/server-01-main-window.png` |
| Sources 탭 | `images/prd/server-02-sources.png` |
| Outputs 탭 | `images/prd/server-03-outputs.png` |
| GFX1 게임 제어 | `images/prd/server-04-gfx1-game.png` |
| GFX2 통계 | `images/prd/server-05-gfx2-stats.png` |
| GFX3 방송 연출 | `images/prd/server-06-gfx3-broadcast.png` |
| System 탭 | `images/prd/server-08-system.png` |
| Skin Editor | `images/prd/server-09-skin-editor.png` |
| GE Board | `images/prd/server-10-ge-board.png` |
| GE Player | `images/prd/server-11-ge-player.png` |
| Action Tracker | `images/prd/ui-live-action-tracker.png` |
| 모니터링 대시보드 | `images/prd/ui-live-dashboard.png` |
| 게임 제어 (Live) | `images/prd/ui-live-game-control.png` |
| 스킨 에디터 (Setup) | `images/prd/ui-setup-skin-editor.png` |
| Viewer Overlay | `images/prd/ui-viewer-overlay.png` |
| 방송 오버레이 | `images/prd/prd-broadcast-overlay.png` |

**실제 스크린샷** (참조용):

| 스크린샷 | 대응 탭 | 경로 |
|---------|--------|------|
| 180624 | System | `images/screenshots/스크린샷 2026-02-05 180624.png` |
| 180630 | Main Window | `images/screenshots/스크린샷 2026-02-05 180630.png` |
| 180637 | Sources | `images/screenshots/스크린샷 2026-02-05 180637.png` |
| 180645 | Outputs | `images/screenshots/스크린샷 2026-02-05 180645.png` |
| 180649 | GFX1 | `images/screenshots/스크린샷 2026-02-05 180649.png` |
| 180652 | GFX2 | `images/screenshots/스크린샷 2026-02-05 180652.png` |
| 180655 | GFX3 | `images/screenshots/스크린샷 2026-02-05 180655.png` |
| 180659 | Commentary | `images/screenshots/스크린샷 2026-02-05 180659.png` |
| 180715 | Skin Editor | `images/screenshots/스크린샷 2026-02-05 180715.png` |
| 180720 | GE Board | `images/screenshots/스크린샷 2026-02-05 180720.png` |
| 180728 | GE Player | `images/screenshots/스크린샷 2026-02-05 180728.png` |

**어노테이션 이미지** (별도 생성):

| 이미지 | 경로 |
|--------|------|
| Main Window 어노테이션 | `images/annotated/01-main-window.png` |
| Sources 탭 어노테이션 | `images/annotated/02-sources-tab.png` |
| Outputs 탭 어노테이션 | `images/annotated/03-outputs-tab.png` |
| GFX1 탭 어노테이션 | `images/annotated/04-gfx1-tab.png` |
| GFX2 탭 어노테이션 | `images/annotated/05-gfx2-tab.png` |
| GFX3 탭 어노테이션 | `images/annotated/06-gfx3-tab.png` |
| Commentary 탭 어노테이션 | `images/annotated/07-commentary-tab.png` |
| System 탭 어노테이션 | `images/annotated/08-system-tab.png` |
| Skin Editor 어노테이션 | `images/annotated/09-skin-editor.png` |
| GE Board 어노테이션 | `images/annotated/10-graphic-editor-board.png` |
| GE Player 어노테이션 | `images/annotated/11-graphic-editor-player.png` |
