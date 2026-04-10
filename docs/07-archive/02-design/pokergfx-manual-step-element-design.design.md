# PokerGFX 매뉴얼 v3.2.0 기반 Step별 요소 설계

> source: PRD-0004 v21.0.0 + PokerGFX Manual v3.2.0 | created: 2026-02-26

---

## 요약 통계

### Step별 요소 집계

| Step | PRD 요소 수 | Gap 요소(PRD 누락) | Gap 요소(탭 이동) | EBS 신규 요소 | AT 전용 |
|------|:-----------:|:------------------:|:-----------------:|:-------------:|:-------:|
| Step 1: Main Window | 7 (활성) + 2 (DROP) | 2 | 0 | 0 | 0 |
| Step 2: System | 21 | 2 | 0 | 0 | 0 |
| Step 3: Sources | 17 | 3 | 1* | 0 | 0 |
| Step 4: Outputs | 8 (활성) + 3 (DROP) | 7 | 0 | 0 | 0 |
| Step 5: GFX 1 | 28 | 2 | 6** | 0 | 0 |
| Step 6: GFX 2 | 20 | 2 | 4** | 0 | 0 |
| Step 7: GFX 3 | 12 | 1 | 2** | 0 | 0 |
| Step 8: AT (경계) | 0 | 0 | 0 | 0 | 50 |
| Step 9: Skin Editor + Graphic Editor | 26 + 19 = 45 | 6 | 0 | 0 | 0 |
| **합계** | **163** | **25** | **13** | **0** | **50** |

> \* GAP-3-04: Sources 위치 메모(실제 O-05로 배치)
> \*\* 탭 이동 Gap: 매뉴얼 설명 위치와 PRD 배치 탭이 다른 요소. 기능 자체는 PRD에 존재
>
> **[주의] PRD-0004 부록 A 집계(184)와 8개 차이**: 부록 A는 v16.0.0 이전 기준. v21.0.0 현재 Element Catalog에서 제외된 항목:
> - M-08 (Text Display), M-10 (Stats Display) → v16.0.0 Future 처리 (Main Window -2)
> - O-06~O-13 (8개 Output 요소) → v16.0.0 Future 처리, Element Catalog 미포함 (Outputs -6)
> - 부록 A에서 System 24개로 기재되나 현재 Catalog는 23개
> - 합계 차이: 2 + 6 = 8개 → 184 - 8 = **176** (현재 설계 문서 기준)

### 설계 결정 분포 (PRD 요소 163개 기준)

| EBS 결정 | PRD 요소 수 | 비율 |
|:--------:|:-----------:|:----:|
| v1.0 Keep | ~67 | ~41% |
| v2.0 Defer | ~62 | ~38% |
| v3.0 Defer | ~18 | ~11% |
| Drop | 16 | ~10% |
| **합계** | **163** | **100%** |

### Gap 요소 v1.0 Keep 긴급 반영 대상

PRD-0004에 완전 누락된 Gap 요소 중 v1.0 Keep으로 분류된 항목 — 다음 PRD 업데이트 시 반영 필요:

| # | Gap ID | 요소명 | 추가 위치 (PRD) |
|---|--------|--------|----------------|
| 1 | GAP-1-01 | Secure Delay Icon | Main Window 보안 제어 그룹 |
| 2 | GAP-2-02 | Secure Delay Folder | System 탭 Storage 그룹 (신규 그룹 생성) |
| 3 | GAP-4-03 | Secure Delay (toggle) | Outputs 탭 Secure Delay 전용 섹션 (신규) |
| 4 | GAP-4-04 | Secure Delay Active (3 conditions) | Outputs 탭 UX 비헤이비어 명세로 추가 |
| 5 | GAP-4-06 | Delay Countdown | Outputs 탭 Secure Delay 섹션 |
| 6 | GAP-5-07 | Clear Previous Action | GFX 2 이미 G-35로 존재 — 매뉴얼 원문 인용 추가 |
| 7 | GAP-5-08 | Unknown Cards Blink | GFX 2 이미 G-34로 존재 — 매뉴얼 원문 인용 추가 |
| 8 | GAP-7-03 | Display Side Pot Amount | GFX 3 G-50 그룹에 신규 항목 추가 (방송 필수) |

---

## Step 1: Main Window

### 매뉴얼 해당 범위
- 페이지: p.33-34
- Element Reference 섹션: System Status Icons, Settings

### 완전 요소 목록

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | M-03 | CPU Indicator | "The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably." | p.34 | v1.0 Keep | 색상 임계값(Green<60%, Yellow<85%, Red>=85%)은 EBS 자체 수치 |
| 2 | M-04 | GPU Indicator | "The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably." | p.34 | v1.0 Keep | M-03과 동일 매뉴얼 원문 공유 |
| 3 | M-05 | RFID Status | "Green: RFID Reader is operating normally." / "Grey: PokerGFX Server is establishing a secure link with the RFID Reader." / "Blue: operating normally, however there are playing cards on the table that have not yet been registered." / "Black: operating normally, however more than one card of the same rank and suit has been detected." / "Magenta: operating normally, however duplicate cards have been detected on the table." / "Orange: connected but not responding. May indicate an overloaded CPU or USB link." / "Red: RFID Reader is not connected." | p.34 | v1.0 Keep | 7색 상태 표시. EBS에서 동일 상태 코드 적용 |
| 4 | M-07 | Lock Toggle | "Click the Lock symbol next to the Settings button to password protect the Settings Window." | p.33 | v1.0 Keep | EBS: 잠금 시 전 탭 설정 변경 불가 |
| 5 | M-11 | Reset Hand | - | - | v1.0 Keep | 현재 핸드 초기화 + 확인 다이얼로그. 매뉴얼 미수록. PokerGFX 바이너리 resetHandButton 확인 |
| 6 | M-13 | Register Deck | - | - | v3.0 Defer | 52장 RFID 일괄 등록. 매뉴얼 미수록. SV-023 매핑 |
| 7 | M-14 | ~~Launch AT~~ → **Lobby** | - | - | v1.0 Keep | ~~Action Tracker 실행~~ → EBS v10.0.0에서 Lobby 버튼으로 변경. Lobby 화면으로 이동 |
| 8 | ~~M-17~~ | ~~Hand Counter~~ | - | - | **[DROP]** | 현재 세션 핸드 번호 표시. PRD-0004에서 DROP 확정 |
| 9 | ~~M-18~~ | ~~Connection Status~~ | - | - | **[DROP]** | AT/Overlay/DB 연결 상태 표시. PRD-0004에서 DROP 확정 |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-1-01 | Secure Delay Icon | "The icon to the right indicates whether Secure Delay is enabled." | p.34 | v1.0 Keep | 딜레이 활성 상태는 방송 보안 운영 필수 정보. SEC-005(모드 표시)로 기능 흡수 가능 — PRD에서 별도 아이콘 대신 M-10(Secure Delay 상태) 영역으로 통합 설계 예정 |
| 2 | GAP-1-02 | Settings Reset | "Hold the CTRL key while starting the Server to reset all settings to their default values." | p.33 | v2.0 Defer | 설정 전체 초기화 — 방송 필수 아님. 운영 편의 기능으로 v2.0에서 Settings 다이얼로그 내 "Factory Reset" 항목으로 구현 |

### PokerGFX 대비 EBS 변경점

1. **M-17/M-18 DROP**: Hand Counter와 Connection Status Row를 제거. 핸드 번호는 AT에서만 관리하며, 연결 상태는 M-05 RFID Status로 충분.
2. **M-13 Register Deck → v3.0 Defer**: PokerGFX에서는 기본 기능이었으나, EBS v1.0에서는 RFID 하드웨어 미확정으로 v3.0 단계 구현.
3. **GAP-1-01 Secure Delay Icon 통합**: 별도 아이콘 대신 Secure Delay 상태 영역(M-10)으로 통합 설계 — UI 간결화.

---

## Step 2: System

### 매뉴얼 해당 범위
- 페이지: p.58-60 (System 탭), p.101-103 (MultiGFX)
- Element Reference 섹션: System 탭 (Y-*), MultiGFX

### 완전 요소 목록

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | Y-01 | Table Name | "Enter an optional name for this table. This is required when using MultiGFX mode, or there are multiple tables connected to the same local area network." | p.60 | v1.0 Keep | - |
| 2 | Y-02 | Table Password | "Password for this table. Anyone attempting to use Action Tracker with this table will be required to enter this password." | p.60 | v1.0 Keep | - |
| 3 | Y-03 | Reset | "Resets the RFID Reader connection, as if PokerGFX had been closed and restarted." | p.60 | v1.0 Keep | - |
| 4 | Y-04 | Calibrate | "Perform the once-off table calibration procedure, which 'teaches' the table about its physical configuration." | p.60 | v3.0 Defer | SV-024 매핑. RFID 하드웨어 전제 |
| 5 | Y-05 | UPCARD Antennas | "Enables all antennas configured for reading UPCARDS in STUD games to also detect hole cards when playing any flop or draw game." | p.59 | v3.0 Defer | RFID 하드웨어 전제. STUD 게임 전용 |
| 6 | Y-06 | Disable Muck | "Causes the muck antenna to be disabled when in Action Tracker mode." | p.59 | v3.0 Defer | RFID 하드웨어 전제 |
| 7 | Y-07 | Disable Community | - | - | v3.0 Defer | 커뮤니티 카드 안테나 비활성. 매뉴얼 미수록. EBS 신규 |
| 8 | Y-09 | Table Diagnostics | "Displays a diagnostic window that displays the physical table configuration along with how many cards are currently detected on each antenna." | p.60 | v3.0 Defer | RFID 하드웨어 전제 |
| 9 | Y-12 | Export Folder | "When the Developer API is enabled, use this to specify the location for writing the JSON hand history files." | p.60 | v2.0 Defer | Hand History 시스템 전제 |
| 10 | Y-13 | Allow AT Access | "'Track the action' can only be started from Action Tracker if this option is enabled. When disabled, Action Tracker may still be used but only in Auto mode." | p.58 | v1.0 Keep | - |
| 11 | Y-14 | Predictive Bet | "Action Tracker will auto-complete bets and raises based on the initial digits entered, min raise amount and stack size." | p.60 | v1.0 Keep | - |
| 12 | Y-15 | Kiosk Mode | "When the Server starts, Action Tracker is automatically started on the same PC on the secondary display in kiosk mode. In this mode, AT cannot be closed or minimised." | p.58 | v1.0 Keep | - |
| 13 | Y-16 | MultiGFX | "Forces PokerGFX to sync to another primary PokerGFX running on a different, networked computer, making it possible to generate multiple live and delayed video streams with different graphics, from the same table." | p.58 | v3.0 Defer | SV-025 매핑. 다중 테이블 인프라 전제 |
| 14 | Y-17 | Sync Stream | "When in MultiGFX mode, forces secure delay to start and stop in synchronization with the primary server." | p.58 | v3.0 Defer | MultiGFX 전제 |
| 15 | Y-18 | Sync Skin | "Causes the secondary MultiGFX server skin to auto update from the skin that is currently active on the primary server." | p.58 | v3.0 Defer | MultiGFX 전제 |
| 16 | Y-19 | No Cards | "When enabled, no hole card information will be shared with any secondary server." | p.58 | v3.0 Defer | MultiGFX 전제 |
| 17 | Y-20 | Disable GPU | - | - | v2.0 Defer | GPU 인코딩 비활성화. 매뉴얼 미수록 |
| 18 | Y-21 | Ignore Name Tags | "When enabled, player ID tags are ignored; player names are entered manually in Action Tracker." | p.59 | v1.0 Keep | - |
| 19 | Y-22 | Auto Start | "Automatically start the PokerGFX Server when Windows starts. Useful for unattended installations." | p.58 | v2.0 Defer | 운영 편의. 방송 필수 아님 |
| 20 | Y-23 | Stream Deck | - | - | v2.0 Defer | Elgato Stream Deck 매핑. SV-026 매핑. 매뉴얼 미수록 |
| 21 | Y-24 | Version + Check | "Force the Server to check to see if there's a software update available." | p.58 | v2.0 Defer | 업데이트 확인 — 방송 필수 아님 |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-2-01 | Setup WIFI | "Configure WIFI settings on the RFID Reader." | p.60 | v3.0 Defer | RFID 리더 WiFi 설정. RFID 하드웨어 전제. Y-03/Y-04 그룹 내 포함 예정 |
| 2 | GAP-2-02 | Secure Delay Folder | "Click the 'Secure Delay Folder' button to specify a storage folder on a different drive. These files occupy approximately 50 GB of space for a video size of 1920 x 1080." | p.60 | v1.0 Keep | Secure Delay 파일 저장 경로 — 딜레이 기능 운영 필수. Outputs 탭(O-06 그룹) 또는 System 탭 중 위치 결정 필요. 매뉴얼 p.60에서 System 탭 내 배치 확인 — PRD 설명 불일치: Secure Delay 상세 섹션에는 p.60으로, Outputs 탭에는 누락 |

### PokerGFX 대비 EBS 변경점

1. **Y-04 Calibrate → v3.0 Defer**: PokerGFX에서는 기본 기능이었으나, EBS v1.0 RFID 미확정 단계에서는 제외. (SV-024 참조)
2. **GAP-2-01 Setup WIFI**: PokerGFX에 존재하지만 PRD-0004에 누락. EBS의 자체 RFID 리더(ST25R3911B+ESP32)는 WiFi 설정 방식이 상이할 수 있음 → v3.0 단계에서 EBS 하드웨어 스펙에 맞게 재설계.
3. **GAP-2-02 Secure Delay Folder**: 매뉴얼에서는 System 탭(p.60) 위치로 명시. PRD-0004에는 Outputs 탭 Secure Delay 그룹에 미포함. EBS에서는 System 탭 내 별도 Storage 그룹으로 명시 필요.

---

## Step 3: Sources

### 매뉴얼 해당 범위
- 페이지: p.35-40
- Element Reference 섹션: Sources 탭 (S-*)

### 완전 요소 목록

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | S-01 | Device Table | "The Sources tab contains a list of available video sources. These include USB cameras, video capture cards installed in the system and NDI sources detected on the local network." | p.35 | v1.0 Keep | SV-001 매핑 |
| 2 | S-02 | Add Button | "Network cameras can't be auto detected, so to configure one of these as a source click the 'Add network camera' button, scroll down to the new camera at end of the Sources list and enter the stream URL for the camera by clicking in the 'Input / Format / URL' column." | p.35 | v1.0 Keep | - |
| 3 | S-03 | Settings | "To edit the properties of the video source, click on the 'Settings' keyword. A properties window will open enabling additional camera settings to be changed." | p.35 | v1.0 Keep | - |
| 4 | S-05 | Board Cam Hide GFX | "If the 'Hide GFX' option is enabled, all player graphics will be made invisible while the board cam is active." | p.36 | v2.0 Defer | SV-002(Auto Camera) 하위 기능 |
| 5 | S-06 | Auto Camera Control | - | - | v2.0 Defer | SV-002 매핑. 게임 상태 기반 자동 전환. 매뉴얼 미수록 |
| 6 | S-07 | Cycle Mode | "To display video sources in rotation, select 'Cycle' mode instead of 'Static'. Enter the number of seconds that each video source should be displayed in the 'Cycle' column. A value of zero will exclude that source from the rotation." | p.35 | v1.0 Keep | - |
| 7 | S-08 | Heads Up Split | "When play is heads up, and both players are covered by separate cameras, a split screen view showing each player will automatically be displayed." | p.37 | v2.0 Defer | SV-002 하위 기능 |
| 8 | S-09 | Follow Players | "When 'Follow Players' is enabled: If Action Tracker is enabled, the video will switch to ensure that the player whose turn it is to act is always displayed." | p.37 | v2.0 Defer | SV-002 하위 기능 |
| 9 | S-10 | Follow Board | "When 'Follow Board' is enabled, the video will switch to the community card close-up for a few seconds whenever flop, turn or river cards are dealt." | p.36 | v2.0 Defer | SV-002 하위 기능 |
| 10 | S-11 | Chroma Key Enable | "Chroma key is supported by outputting graphics on a solid colour background (usually blue or green). To enable chroma key, enable the 'Chroma Key' checkbox then repeatedly click the 'Background Key Colour' button until the desired colour is selected." | p.39 | v1.0 Keep | SV-005 매핑 |
| 11 | S-12 | Background Colour | "repeatedly click the 'Background Key Colour' button until the desired colour is selected." | p.39 | v1.0 Keep | SV-005 하위 설정 |
| 12 | S-13 | Switcher Source | "When using a camera source for video capture from an external vision switcher, select this capture device using the 'External Switcher Source' dropdown box. This disables the built-in multi-camera switching features." | p.38 | v2.0 Defer | SV-003(ATEM) 연동 |
| 13 | S-14 | ATEM Control | "PokerGFX can control a Blackmagic ATEM Video Switcher to automatically switch camera inputs to follow the action." | p.40 | v2.0 Defer | SV-003 매핑 |
| 14 | S-15 | Board Sync | "Delays the detection of community cards by the specified number of milliseconds. This can be used to compensate for the problem where community card graphics are displayed before the cards are shown being dealt on video." | p.38 | v2.0 Defer | SV-004 매핑 |
| 15 | S-16 | Crossfade | "When the 'Crossfade' setting is zero, camera sources transition with a hard cut. Setting this value to a higher value between 0.1 and 2.0 causes sources to crossfade, resulting in a softer, more fluid transition." | p.38 | v2.0 Defer | SV-004 하위 설정 |
| 16 | S-17 | Audio Input | "Select the desired audio capture device and volume. The Sync setting adjusts the timing of the audio signal to match the video, if required." | p.38 | v1.0 Keep | - |
| 17 | S-18 | Audio Sync | - | - | v1.0 Keep | 오디오 싱크 보정(ms). 매뉴얼 p.38 Audio Input 설명에 포함 |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-3-01 | Linger on Board | "The Linger on Board setting sets the number of seconds the board cam is active before returning to the next view." | p.36 | v2.0 Defer | Follow Board(S-10) 세부 설정. Auto Camera v2.0 구현 시 포함. PRD-0004에 S-10 설명은 있으나 Linger 설정값 항목 누락 |
| 2 | GAP-3-02 | Post Bet | "The 'Post Bet' option determines what happens at the end of each betting round: Player / Default / Board" | p.37 | v2.0 Defer | Auto Camera 하위 설정. v2.0 구현 시 Follow Players 그룹에 포함 |
| 3 | GAP-3-03 | Post Hand | "The 'Post Hand' option determines what happens at the end of the hand: Default / Player / Winner" | p.37 | v2.0 Defer | Auto Camera 하위 설정. v2.0 구현 시 포함 |
| 4 | GAP-3-04 | Key & Fill (Sources) | "Key & Fill is supported on specific Blackmagic devices that support external keying including the Decklink Duo 2, Quad 2, 8K Pro & 4K Extreme 12G." | p.39 | v1.0 Keep | Element Reference에서 O-05로 분류. PRD에서 Sources 탭이 아닌 Outputs 탭에 배치. 매뉴얼 p.39에서 Sources 섹션 내 설명 — PRD 설명 불일치: 매뉴얼 p.39는 Sources 섹션이나 PRD는 Outputs에 배치 |

### PokerGFX 대비 EBS 변경점

1. **GAP-3-01~03 (Linger/Post Bet/Post Hand) → v2.0 Defer**: Auto Camera v2.0 구현 시 S-09/S-10과 함께 그룹화. v1.0에서는 기본 카메라 전환만 지원.
2. **GAP-3-04 Key & Fill 위치**: 매뉴얼 p.39(Sources 섹션)에서 설명하지만 PRD-0004에서 Outputs 탭(O-05)에 배치. EBS 설계에서는 Outputs 탭 배치 유지(하드웨어 출력 설정 그룹화 원칙).

---

## Step 4: Outputs

### 매뉴얼 해당 범위
- 페이지: p.42-47 (Outputs 탭, Twitch), p.44-46 (Secure Delay 상세), p.60 (Secure Delay Folder — System 탭)
- Element Reference 섹션: Outputs 탭 (O-*), Secure Delay 상세

### 완전 요소 목록

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | O-01 | Video Size | "Select the desired resolution and frame rate of the video output." | p.42 | v1.0 Keep | SV-008 매핑 |
| 2 | O-02 | 9x16 Vertical | "PokerGFX supports vertical video natively by enabling the '9x16 Vertical' checkbox in the Outputs settings tab." | p.43 | **Drop** | SV-010 매핑. EBS는 방송 오버레이 전용(가로 16:9 only) |
| 3 | O-03 | Frame Rate | - | - | v1.0 Keep | SV-008 하위. 30/60fps. 매뉴얼 p.42 Size/Frame Rate 설명에 포함 |
| 4 | O-04 | Output Device | "Sends the live and/or delayed video and audio feed to a Blackmagic Decklink device output (if installed), or to an NDI stream on the local network. NOTE: This option is only available with an Enterprise license." | p.42 | v1.0 Keep | SV-006 매핑. Live 파이프라인 3개 드롭다운 |
| 5 | O-05 | Key & Fill | "When an output device that supports external keying is selected, the 'Key & Fill' checkbox is enabled. Activating this feature causes separate key & fill signals to be sent to 2 SDI connectors on the device." | p.43 | v1.0 Keep | SV-006 하위 |
| 6 | O-06 | Delay Video/Audio/Device | - | - | v1.0 Keep | SV-006 매핑. Delay 파이프라인. 매뉴얼 미수록(PRD Future → v1.0으로 상향) |
| 7 | O-07 | Delay Key & Fill | - | - | v1.0 Keep | SV-006 하위. 매뉴얼 미수록 |
| 8 | O-14 | Virtual Camera | "Sends the video and audio feed (live OR delayed, depending on this setting) to the POKERGFX VCAM virtual camera device, for use by 3rd party streaming software such as OBS or XSplit." | p.43 | v2.0 Defer | SV-009 매핑 |
| 9 | O-15 | Recording Mode | - | - | v1.0 Keep | Video / Video+GFX / GFX only. 매뉴얼 미수록 |
| 10 | O-16 | Streaming Platform | "PokerGFX includes a fully functional ChatBot that is compatible with the Twitch video streaming service." | p.47 | **Drop** | SV-011 매핑. Twitch/YouTube SNS 연동은 EBS 범위 외 |
| 11 | O-17 | Streaming Account | - | - | **Drop** | SV-011 하위. OAuth 연결. SNS 연동 배제로 함께 DROP |
### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-4-01 | Video Preview | "Sends the live and/or delayed video feed to an additional video display attached to the graphics card." | p.42 | v2.0 Defer | 모니터 출력 미리보기. 방송 필수 아님. 운영 편의 기능 |
| 2 | GAP-4-02 | Audio Preview | "Sends the live and/or delayed audio feed matching the above video previews to any of the standard Windows audio output devices." | p.42 | v2.0 Defer | 오디오 모니터링. 방송 품질 향상 기능 |
| 3 | GAP-4-03 | Secure Delay (toggle) | "This feature causes a security delay to be introduced to the live video stream. For example, to delay the stream by 20 minutes, enter the value '20'. Start the delay by clicking the 'Secure Delay' checkbox." | p.44 | v1.0 Keep | SEC-001/SEC-010/SEC-011 매핑. PRD-0004에서 O-06/O-07(Future)로 통합됨 — PRD 설명 불일치: 매뉴얼은 Outputs 탭 내 독립 UI로 Secure Delay 제어. EBS에서는 Secure Delay 전용 섹션으로 명시 필요 |
| 4 | GAP-4-04 | When Secure Delay Active (3 conditions) | "(1) The padlock indicator will lock and turn green (2) The live preview window shows hole cards DOWN, but the delayed output shows hole cards UP. (3) The live preview is safe for real time display at the venue" | p.44 | v1.0 Keep | 활성 상태 UX 설명. SEC-005(모드 표시)로 매핑 가능. UI 비헤이비어 명세로 별도 문서화 필요 |
| 5 | GAP-4-05 | Auto Delay | "This feature will turn secure delay on as soon as the first hand is detected, then stop it after a period of inactivity. To enable, set the 'Auto' box to the number of minutes of inactivity." | p.45 | v2.0 Defer | 자동 딜레이 활성/비활성. 방송 품질 향상 기능 |
| 6 | GAP-4-06 | Delay Countdown | "When a secure delay is started, a countdown clock is displayed to viewers that indicates when the video will start." | p.45 | v1.0 Keep | SEC-002(카운트다운 표시) 매핑. 딜레이 시작 시 시청자에게 카운트다운 표시 |
| 7 | GAP-4-07 | Dynamic Delay | "The Dynamic Delay feature automatically skips tourney breaks during a delayed stream by starting with a much longer delay which is progressively reduced every time there's a break." | p.46 | v2.0 Defer | 토너먼트 브레이크 자동 스킵. 운영 편의. 방송 필수 아님 |

### PokerGFX 대비 EBS 변경점

1. **O-02 9x16 Vertical → Drop**: PokerGFX에서는 세로 모드를 지원하지만, EBS는 방송 오버레이 전용(16:9)으로 세로 모드 배제.
2. **O-16/O-17 Twitch/YouTube → Drop**: SNS 스트리밍 연동은 OBS 등 외부 도구에서 처리. EBS 관심사는 오버레이 생성.
3. **GAP-4-03~07 Secure Delay 상세 기능**: 매뉴얼의 7가지 Secure Delay 관련 요소가 PRD-0004에서 O-06/O-07(Future)로 통합됨. EBS에서는 Secure Delay 전용 섹션을 Outputs 탭에 명시하고, Auto Delay는 v2.0, Dynamic Delay는 v2.0으로 배치.

---

## Step 5: GFX 1

### 매뉴얼 해당 범위
- 페이지: p.48-54
- Element Reference 섹션: 레이아웃 설정, 스킨 및 미디어, 애니메이션, 텍스트 및 스폰서, 카드 공개 및 폴드 처리, Outs 및 액션 표시, Action Clock

### 완전 요소 목록

**Layout 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | G-01 | Board Position | "Position of the Board graphic (shows community cards, pot size and optionally blind levels). Choices are LEFT, CENTRE and RIGHT. The Board is always positioned at the bottom of the display." | p.48 | v1.0 Keep | SV-012 매핑. EBS: Top 옵션 추가 |
| 2 | G-02 | Player Layout | "players are arranged horizontally along the bottom of the display..." / "Players are arranged vertically starting from the bottom left corner..." 등 5가지 옵션 | p.48 | v1.0 Keep | SV-013 매핑 |
| 3 | G-03 | X Margin | "This setting controls the size of the horizontal margins. Valid values are between 0 and 1. When in any vertical layout mode, larger values cause all graphics to move towards the centre of the display." | p.49 | v1.0 Keep | - |
| 4 | G-04 | Top Margin | "This setting controls the size of the vertical margins. Valid values are between 0 and 1. Larger values cause all graphics to move towards the centre of the display." | p.49 | v1.0 Keep | - |
| 5 | G-05 | Bot Margin | "This setting controls the size of the vertical margins. Valid values are between 0 and 1. Larger values cause all graphics to move towards the centre of the display." | p.49 | v1.0 Keep | - |
| 6 | G-06 | Leaderboard Position | "Selects the position of the Leaderboard graphic." | p.49 | v1.0 Keep | - |
| 7 | G-07 | Heads Up Layout L/R | "Overrides the player layout when players are heads-up. In this mode, the board graphic is positioned at the bottom centre of the display with each player positioned either side." | p.48 | v1.0 Keep | - |
| 8 | G-08 | Heads Up Camera | - | - | v1.0 Keep | 헤즈업 카메라 위치. 매뉴얼 미수록. EBS 신규 |
| 9 | G-09 | Heads Up Custom Y | "Use this to specify the vertical position of player graphics when Heads Up layout is active." | p.48 | v1.0 Keep | - |
| 10 | G-10 | Sponsor Logo 1 (Leaderboard) | "Displays a sponsor logo at the top of the Leaderboard. NOTE: Pro only." | p.50 | v2.0 Defer | SV-016 매핑 |
| 11 | G-11 | Sponsor Logo 2 (Board) | "Displays a sponsor logo to the side of the Board. NOTE: Pro only." | p.50 | v2.0 Defer | SV-016 매핑 |
| 12 | G-12 | Sponsor Logo 3 (Strip) | "Displays a sponsor logo at the left-hand end of the Strip. NOTE: Pro only." | p.50 | v2.0 Defer | SV-016 매핑 |
| 13 | G-13 | Vanity Text | "Custom text displayed on the Board Card / Pot graphic." + "When this option is enabled, the name of the currently active game variant will be displayed instead of the Vanity text." | p.49 | v1.0 Keep | - |

**Visual 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 14 | G-14 | Reveal Players | "Determines when players are shown: Immediate / On Action / After Bet / On Action + Next" | p.50 | v1.0 Keep | - |
| 15 | G-15 | How to Show Fold | "Immediate: Player is removed immediately." / "Delayed: Player graphic displays 'Fold', then disappears after a few seconds." | p.51 | v1.0 Keep | - |
| 16 | G-16 | Reveal Cards | "Immediate: Hole cards are shown as soon as the player graphic appears." / "After Action: Hole cards are shown after the player's first action." / "End of Hand: Hole cards are shown when all betting for the hand has finished." / "Showdown Cash: Reveals cards of players if they win the hand, or are the first aggressor on the last betting round." / "Showdown Tourney: Reveals cards per Showdown-Cash PLUS cards of all players still in the hand if there's at least one all-in." / "Never: Hole cards are never shown." | p.51 | v1.0 Keep | - |
| 17 | G-17 | Transition In | - | - | v2.0 Defer | SV-014 매핑. 등장 애니메이션. 매뉴얼 미수록 |
| 18 | G-18 | Transition Out | - | - | v2.0 Defer | SV-014 매핑. 퇴장 애니메이션. 매뉴얼 미수록 |
| 19 | G-19 | Indent Action Player | "When this option is enabled, the 'Action On' player is indented towards the centre of the screen." | p.52 | v1.0 Keep | - |
| 20 | G-20 | Bounce Action Player | - | - | v2.0 Defer | SV-015 매핑. 매뉴얼 미수록 |
| 21 | G-21 | Action Clock | "PokerGFX will automatically display the number of seconds players have left to act whenever the timer reaches the number of seconds specified in the Graphics Settings -> Action Clock setting." | p.54 | v1.0 Keep | SV-017 매핑 |
| 22 | G-22 | Show Leaderboard | - | - | v2.0 Defer | 핸드 후 리더보드 자동 표시. 매뉴얼 미수록 |
| 23 | G-23 | Show PIP Capture | - | - | v2.0 Defer | 핸드 후 PIP 표시. 매뉴얼 미수록 |
| 24 | G-24 | Show Player Stats | "Automatically insert updated player chip counts and other statistics in the scrolling ticker at the top or bottom of the display, after each hand." | p.50 | v2.0 Defer | 통계 시스템 전제 |
| 25 | G-25 | Heads Up History | "When players are heads-up, a graphic element appears that shows a history of all actions made by the heads up players in the current hand." | p.52 | v2.0 Defer | - |

**Skin 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 26 | G-13s | Skin Info | - | - | v2.0 Defer | 현재 스킨명+용량 표시. SV-027 매핑 |
| 27 | G-14s | Skin Editor | "Open the Skin Editor" | p.49 | v2.0 Defer | SV-027 매핑. 별도 창 실행 |
| 28 | G-15s | Media Folder | "Configures the location of the Media folder, which contains player photos and other videos." | p.49 | v2.0 Defer | - |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-5-01 | Transition In Animation | "Method and speed used to transition players on to the display. Select from Slide, Fade, Pop and Expand." | p.49 | v2.0 Defer | PRD의 G-17(Transition In)과 동일 기능이나 매뉴얼 원문이 G-17 설명에 미포함. PRD 설명 불일치: G-17에 매뉴얼 원문 인용 없음 |
| 2 | GAP-5-02 | Transition Out Animation | "Method and speed used to transition players off the display. Select from Slide, Fade, Pop and Expand." | p.49 | v2.0 Defer | PRD의 G-18(Transition Out)과 동일. PRD 설명 불일치: G-18에 매뉴얼 원문 인용 없음 |
| 3 | GAP-5-03 | Show Outs | "When play is heads up, all cards remaining in the deck that could improve the worst player's hand are displayed. Never / Heads Up / Heads Up All In" | p.51 | v2.0 Defer | PRD에서 G-40(GFX 3 탭)으로 배치. 매뉴얼 p.51은 GFX 공통 섹션에서 설명. GFX 1에서 설정 위치를 PRD가 GFX 3으로 이동 |
| 4 | GAP-5-04 | Outs Position | "Display Outs either on the left or right hand side of the screen." | p.51 | v2.0 Defer | PRD에서 G-41(GFX 3)으로 배치. 동일한 위치 재배치 이슈 |
| 5 | GAP-5-05 | True Outs | "When enabled, mucked cards are counted when computing pot equity and outs. Disabling this option causes mucked cards to be ignored, so theoretical pot equity and outs are displayed instead." | p.51 | v2.0 Defer | PRD에서 G-42(GFX 3)으로 배치 |
| 6 | GAP-5-06 | Allow Rabbit Hunting | "When a hand has finished that didn't go to a showdown, additional cards placed on the community card antenna will show as 'rabbit hunt' cards." | p.52 | v2.0 Defer | PRD에서 G-54(GFX 2)로 배치. 매뉴얼 p.52에서 GFX 공통으로 설명 |
| 7 | GAP-5-07 | Clear Previous Action | "When the action returns to a player after a bet or raise, the previous action is cleared and 'x TO CALL' or 'OPTION' is displayed." | p.52 | v1.0 Keep | PRD에서 G-35(GFX 2)로 배치. 매뉴얼에서는 GFX 1 섹션에서 설명. 방송 필수 UX |
| 8 | GAP-5-08 | Unknown Cards Blink | "When Secure Delay is enabled, the live preview window always displays hole cards down. When this option is enabled, cards that have not been scanned are indicated by blinking." | p.52 | v1.0 Keep | PRD에서 G-34(GFX 2)로 배치. Secure Delay 운영 필수 피드백 |

### PokerGFX 대비 EBS 변경점

1. **G-40~G-42 (Outs/Position/True Outs) → GFX 3 재배치**: 매뉴얼에서는 GFX 공통 섹션(p.51)에서 설명하나, PRD-0004에서 GFX 3 탭으로 이동. Outs는 칩카운트/통화와 함께 "수치 표시" 그룹에 속하는 방식으로 재조직.
2. **G-10~G-12 스폰서 로고 3슬롯 → v2.0 Defer**: PokerGFX Pro 전용 기능. EBS v1.0에서는 방송 수익화 기능으로 우선순위 낮음.
3. **GAP-5-07/08 (Clear Previous Action, Unknown Cards Blink) → GFX 2로 이동**: PRD-0004에서 GFX 2 탭으로 배치. 매뉴얼 설명 위치(p.52)와 다르나, 기능 그룹화 원칙(Player Display 그룹)에 따른 이동.

---

## Step 6: GFX 2

### 매뉴얼 해당 범위
- 페이지: p.50-53
- Element Reference 섹션: 블라인드 및 리더보드 표시, 카드 공개 및 폴드 처리(일부), 리더보드 및 Strip(일부)

### 완전 요소 목록

**Leaderboard 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | G-26 | Show Knockout Rank | "Displays the rank of eliminated players on the chip count display." | p.53 | v2.0 Defer | - |
| 2 | G-27 | Show Chipcount % | "Shows each player's stack on the Leaderboard as a percentage of total chips on the table." | p.53 | v1.0 Keep | SV-018 매핑 |
| 3 | G-28 | Show Eliminated | "When enabled, players that have left the table or been eliminated are displayed using the alternate colour." | p.53 | v2.0 Defer | - |
| 4 | G-29 | Cumulative Winnings | - | - | v2.0 Defer | 누적 상금. 매뉴얼 미수록. EBS 신규 |
| 5 | G-30 | Hide Leaderboard | - | - | v2.0 Defer | 핸드 시작 시 리더보드 숨김. 매뉴얼 미수록 |
| 6 | G-31 | Max BB Multiple | "Whether to show Big Blind multiples in the chip count display." | p.50 | v1.0 Keep | SV-019 매핑 |

**Player Display 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 7 | G-32 | Add Seat # | "Automatically display the physical seat number in front of the player name in the player graphic." | p.50 | v1.0 Keep | - |
| 8 | G-33 | Show as Eliminated | "Displays the message ELIMINATED on a player graphic if that player's stack is reduced to zero." | p.53 | v2.0 Defer | - |
| 9 | G-34 | Unknown Cards Blink | "When Secure Delay is enabled, the live preview window always displays hole cards down. When this option is enabled, cards that have not been scanned are indicated by blinking." | p.52 | v1.0 Keep | 매뉴얼에서는 GFX 1 섹션(p.52) 설명. PRD에서 GFX 2로 이동 |
| 10 | G-35 | Clear Previous Action | "When the action returns to a player after a bet or raise, the previous action is cleared and 'x TO CALL' or 'OPTION' is displayed." | p.52 | v1.0 Keep | 매뉴얼에서는 p.52 설명. PRD에서 GFX 2로 이동 |
| 11 | G-36 | Order Players | - | - | v1.0 Keep | 플레이어 정렬 순서. 매뉴얼 미수록. EBS 신규 |

**Equity 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 12 | G-37 | Show Hand Equities | - | - | v2.0 Defer | Equity 표시 시점. EQ-001~005 전제. 매뉴얼 미수록 |
| 13 | G-38 | Hilite Winning Hand | - | - | v2.0 Defer | 위닝 핸드 강조. Equity 엔진 전제. 매뉴얼 미수록 |
| 14 | G-39 | Hilite Nit Game | - | - | v2.0 Defer | 닛 게임 강조. 매뉴얼 미수록 |

**Game Rules 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 15 | G-52 | Move Button Bomb Pot | - | - | v2.0 Defer | 봄팟 후 버튼 이동. 매뉴얼 미수록 |
| 16 | G-53 | Limit Raises | "If a player makes a bet that exceeds the size of the largest stack of any other player active in the hand, the bet will be limited to the size of the largest stack." | p.53 | v1.0 Keep | - |
| 17 | G-54 | Allow Rabbit Hunting | "When a hand has finished that didn't go to a showdown, additional cards placed on the community card antenna will show as 'rabbit hunt' cards." | p.52 | v2.0 Defer | 매뉴얼에서 p.52에 설명. PRD에서 GFX 2로 배치 |
| 18 | G-55 | Straddle Sleeper | - | - | v2.0 Defer | 스트래들 위치 규칙. 매뉴얼 미수록 |
| 19 | G-56 | Sleeper Final Action | - | - | v2.0 Defer | 슬리퍼 최종 액션. 매뉴얼 미수록 |
| 20 | G-57 | Ignore Split Pots | - | - | v2.0 Defer | Equity/Outs Split pot 무시. 매뉴얼 미수록 |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-6-01 | Show Blinds | "Blinds and Antes will be displayed for 10 seconds: Never / Every Hand / New Level / With Strip" | p.50 | v1.0 Keep | 블라인드 정보 표시 — 방송 필수. PRD-0004에서 G-45(GFX 3)으로 배치. 매뉴얼에서는 p.50(GFX 공통)에서 설명 |
| 2 | GAP-6-02 | Show Hand # Blinds | "Whether to display the hand number when blinds are shown." | p.50 | v1.0 Keep | PRD-0004에서 G-46(GFX 3)으로 배치. 매뉴얼에서는 p.50에서 설명 |
| 3 | GAP-6-03 | Show leaderboard after each hand | "Automatically show chip counts, and other player statistics in leaderboard between hands." | p.50 | v2.0 Defer | PRD-0004에서 G-22(GFX 1)으로 배치. 통계 시스템 전제 |
| 4 | GAP-6-04 | Show player stats in ticker | "Automatically insert updated player chip counts and other statistics in the scrolling ticker at the top or bottom of the display, after each hand." | p.50 | v2.0 Defer | PRD-0004에서 G-24(GFX 1)으로 배치. 통계 전제 |
| 5 | GAP-6-05 | Show eliminated players in Strip | "When enabled, players with a zero chip count will still be displayed in the Strip (but these players will be greyed-out)." | p.53 | v2.0 Defer | PRD에 미포함. Strip 그룹(G-43/G-44)에 추가 필요 |
| 6 | GAP-6-06 | Show eliminated players in Leaderboard | "When enabled, players that have left the table or been eliminated are displayed using the alternate colour." | p.53 | v2.0 Defer | G-28(Show Eliminated)과 유사하나 Leaderboard 전용. PRD 설명 불일치: G-28은 "Show Eliminated on player graphic"으로 약간 다른 기능 |

### PokerGFX 대비 EBS 변경점

1. **GAP-6-01/02 (Show Blinds, Show Hand # Blinds) → GFX 3으로 이동**: 매뉴얼 p.50에서 설명하나, PRD-0004에서 GFX 3(G-45/G-46)으로 이동. "블라인드 표시"가 "통화/수치 표시" 그룹에 속하는 설계 원칙.
2. **GAP-6-05 Show eliminated players in Strip → PRD 누락**: G-43/G-44(Score Strip/Order Strip by) 그룹에 추가 필요. v2.0 구현 시 Strip 설정 그룹에 포함.

---

## Step 7: GFX 3

### 매뉴얼 해당 범위
- 페이지: p.50-54
- Element Reference 섹션: 칩 카운트 및 통화 표시, 리더보드 및 Strip, Action Clock(일부), Outs(이동됨)

### 완전 요소 목록

**Outs & Strip 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | G-40 | Show Outs | "When play is heads up, all cards remaining in the deck that could improve the worst player's hand are displayed. Never / Heads Up / Heads Up All In" | p.51 | v2.0 Defer | 매뉴얼 p.51(GFX 공통)에서 설명. PRD에서 GFX 3으로 이동 |
| 2 | G-41 | Outs Position | "Display Outs either on the left or right hand side of the screen." | p.51 | v2.0 Defer | 동일 이동 |
| 3 | G-42 | True Outs | "When enabled, mucked cards are counted when computing pot equity and outs. Disabling this option causes mucked cards to be ignored, so theoretical pot equity and outs are displayed instead." | p.51 | v2.0 Defer | Equity 엔진 전제 |
| 4 | G-43 | Score Strip | "The Strip is a graphical element that's displayed across the top of the screen showing players and their chip counts. Select from 'Off', 'Stack' or 'Winnings'." | p.53 | v1.0 Keep | - |
| 5 | G-44 | Order Strip By | "Players in the Strip can be ordered either by physical seating order or chip count order." | p.53 | v1.0 Keep | - |

**Blinds & Currency 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 6 | G-45 | Show Blinds | "Blinds and Antes will be displayed for 10 seconds: Never / Every Hand / New Level / With Strip" | p.50 | v1.0 Keep | 매뉴얼 p.50(GFX 공통)에서 설명. PRD에서 GFX 3으로 이동 |
| 7 | G-46 | Show Hand # | "Whether to display the hand number when blinds are shown." | p.50 | v1.0 Keep | 동일 이동 |
| 8 | G-47 | Currency Symbol | "When this option is enabled, all chip amounts are displayed with the local currency symbol." | p.52 | v1.0 Keep | SV-020 매핑 |
| 9 | G-48 | Trailing Currency | "Displays the currency symbol to the right of the amount, instead of to the left." | p.52 | v1.0 Keep | SV-020 하위 |
| 10 | G-49 | Divide by 100 | "Causes all chip amounts to be divided by 100 before display. This permits the use of very small denomination chips." | p.52 | v1.0 Keep | 한국 운영 환경 필수 (칩 1개=100원 구조) |

**Precision & Mode 그룹**

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 11 | G-50 | Chipcount Precision | "Exact Amount: Exact number of chips." / "Smart Amount: Large amounts are automatically abbreviated with 'k' and 'M'." / "Smart Amount extra precision: same but with up to 3 decimal places." | p.52 | v1.0 Keep | SV-018 매핑. EBS: 8개 영역별(Leaderboard/Player Stack/Action/Blinds/Pot/TwitchBot/Ticker/Strip) |
| 12 | G-51 | Display Mode | "Display chip counts, pots and bets in the player element as chips, BB multiple or both." | p.53 | v1.0 Keep | SV-019 매핑. Amount vs BB 전환 |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-7-01 | Max BB Multiple | "Whether to show Big Blind multiples in the chip count display." | p.50 | v1.0 Keep | PRD에서 G-31(GFX 2)로 배치. 매뉴얼에서는 p.50(GFX 공통) 설명. 기능적으로 BB 표시 그룹(G-51)과 통합하는 것이 일관성 있음 — PRD 설명 불일치: G-31은 GFX 2에 있고 G-51(Display Mode)은 GFX 3에 있어 동일 기능이 분리됨 |
| 2 | GAP-7-02 | Show Chipcount % | "Shows each player's stack on the Leaderboard as a percentage of total chips on the table." | p.53 | v1.0 Keep | PRD에서 G-27(GFX 2)으로 배치. 매뉴얼 p.53에서 칩카운트 표시 섹션에서 설명. PRD 배치가 불일치하나 G-27로 이미 존재 — 중복 등록 아님, 위치 메모 목적 |
| 3 | GAP-7-03 | Display Side Pot Amount | "When a player is all-in, and there is side action, PokerGFX can display both the main and side pot separated by a '/'" | p.53 | v1.0 Keep | PRD에 완전 누락. 올인 상황 팟 표시 — 방송 필수. G-50(Chipcount Precision) 그룹에 추가 필요 |

### PokerGFX 대비 EBS 변경점

1. **G-40~G-42 (Outs) → GFX 3으로 재배치**: 매뉴얼 p.51(GFX 1 섹션)에서 설명하나, PRD-0004에서 "수치 표시" 그룹과 함께 GFX 3으로 이동. Outs와 Chipcount Precision이 같은 "표시 형식" 범주.
2. **G-45/G-46 (Show Blinds/Show Hand #) → GFX 3으로 재배치**: 매뉴얼 p.50에서 설명하나, PRD에서 통화/수치 그룹과 함께 GFX 3 배치. 블라인드 표시 형식이 통화 설정과 연관.
3. **GAP-7-03 Display Side Pot Amount → PRD 완전 누락**: 올인 상황 팟 표시는 방송 필수 요소임. G-50 그룹에 v1.0 Keep으로 추가 필요.

---

## Step 8: Action Tracker (경계 문서)

> Action Tracker는 별도 앱으로, 본 설계 문서의 상세 설계 범위 외. 경계 정의 및 Server-AT 상호작용만 문서화.

### AT 전용 요소 총 수

Element Reference `Action Tracker 인터페이스` 섹션 기준:

| 카테고리 | 요소 수 |
|---------|:------:|
| Auto Mode 요소 | 14 |
| GFX Console 요소 | 11 |
| Hand Pre-Start 요소 | 13 |
| During Hand 요소 | 10 |
| Director Console 요소 | 2 |
| **합계 (AT 전용)** | **50** |

### Server-AT 상호작용 요소

Server UI에서 AT 동작에 영향을 미치는 설정 요소 (단방향: Server → AT):

| # | Server 요소 | AT 영향 | PRD ID |
|---|------------|--------|--------|
| 1 | Y-13 Allow AT Access | AT에서 "Track the Action" 버튼 활성화 여부 제어 | Y-13 |
| 2 | Y-14 Predictive Bet | AT 베팅 입력 자동완성 활성화 | Y-14 |
| 3 | Y-15 Kiosk Mode | AT 시작 시 자동 전체화면 + 종료/최소화 불가 | Y-15 |
| 4 | Y-01 Table Name | AT에서 테이블 이름 표시 + 비밀번호 접속 화면 | Y-01/Y-02 |
| 5 | O-06/O-07 Delay Pipeline | AT의 Stream Indicator 상태에 영향 | O-06/O-07 |

### 별도 PRD 참조

- Action Tracker 상세 설계: `action-tracker.prd.md` (미작성, 별도 작업 필요)
- AT 트리아지 결과: `ebs-console-feature-triage.md` Action Tracker 섹션 (26개 기능, v1.0 Keep 22개)

---

## Step 9: Skin Editor / Graphic Editor

### 매뉴얼 해당 범위
- 페이지: p.64-79
- Element Reference 섹션: Skin System

### 완전 요소 목록 — Skin Editor (SK-*)

| # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 비고 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | SK-01 | Name | - | p.64 | v2.0 Defer | 스킨 이름. SV-027 매핑 |
| 2 | SK-02 | Details | - | p.64 | v2.0 Defer | 스킨 설명 텍스트 |
| 3 | SK-03 | Remove Transparency | - | p.64 | v2.0 Defer | 크로마키 투명도 제거 |
| 4 | SK-04 | 4K Design | - | p.64 | v2.0 Defer | 4K(3840×2160) 기준 스킨 선언 |
| 5 | SK-05 | Adjust Size | - | p.64 | v2.0 Defer | 크기 슬라이더 |
| 6 | SK-06 | Element Buttons (10개) | - | p.64 | v2.0 Defer | Strip/Field/Board/Player/Leaderboard 등 → Graphic Editor 진입 |
| 7 | SK-07 | All Caps | - | p.64 | v2.0 Defer | 텍스트 대문자 변환 |
| 8 | SK-08 | Reveal Speed | - | p.64 | v2.0 Defer | 텍스트 등장 속도 |
| 9 | SK-09 | Font 1/2 | - | p.64 | v2.0 Defer | "Fonts: 커스텀 폰트 지원" (Appendix 기재) |
| 10 | SK-10 | Language | - | p.64 | v2.0 Defer | 다국어 설정. "Language Editor: UI 텍스트 다국어 편집" |
| 11 | SK-11 | Card Preview | - | p.64 | v2.0 Defer | 4수트+뒷면 미리보기 |
| 12 | SK-12 | Add/Replace/Delete | - | p.64 | v2.0 Defer | "Cards / Card Backs: 카드 디자인 편집" |
| 13 | SK-13 | Import Card Back | - | p.64 | v2.0 Defer | 뒷면 이미지 임포트 |
| 14 | SK-14 | Player Variant | - | p.64 | v2.0 Defer | 게임 타입 선택 |
| 15 | SK-15 | Player Set | - | p.64 | v2.0 Defer | 게임별 플레이어 세트 |
| 16 | SK-16 | Edit/New/Delete | - | p.64 | v2.0 Defer | 세트 관리 |
| 17 | SK-17 | Crop to Circle | - | p.64 | v2.0 Defer | "Circular Player Photos: 원형 플레이어 사진 지원" |
| 18 | SK-18 | Country Flag | - | p.64 | v2.0 Defer | "Flags Importer: 국가 국기 이미지 임포트" |
| 19 | SK-19 | Edit Flags | - | p.64 | v2.0 Defer | 국기 이미지 편집 |
| 20 | SK-20 | Hide Flag After | - | p.64 | v2.0 Defer | 자동 숨김(초) |
| 21 | SK-21 | Import | - | p.64 | v2.0 Defer | 스킨 가져오기 |
| 22 | SK-22 | Export | - | p.64 | v2.0 Defer | 스킨 내보내기 |
| 23 | SK-23 | Download | - | p.64 | v2.0 Defer | 온라인 다운로드 |
| 24 | SK-24 | Reset | - | p.64 | v2.0 Defer | 기본 초기화 |
| 25 | SK-25 | Discard | - | p.64 | v2.0 Defer | 변경 취소 |
| 26 | SK-26 | Use | - | p.64 | v2.0 Defer | 현재 적용 |

> 참고: 매뉴얼 p.64-79는 Skin Editor의 세부 조작을 설명하나, 개별 UI 요소에 대한 직접 인용 원문이 Element Reference에 별도 기재되지 않음. Skin System Appendix 섹션의 기능 목록으로 대체.

### 완전 요소 목록 — Graphic Editor

| # | 코드 | 요소명 | 설명 | EBS 결정 | 비고 |
|---|------|--------|------|:--------:|------|
| **Board/공통 기능 (10개)** | | | | | |
| 1 | - | Element 선택 | 드롭다운으로 편집 대상 선택 | v2.0 Defer | SV-028 매핑 |
| 2 | - | Position (LTWH) | Left/Top/Width/Height 픽셀 정수값 | v2.0 Defer | - |
| 3 | - | Anchor | 해상도 변경 시 요소 기준점 (TopLeft~BottomCenter 7종) | v2.0 Defer | EBS 신규 명시 |
| 4 | - | Coordinate Display | 현재 출력 해상도 기준 실제 픽셀값 읽기 전용 | v2.0 Defer | EBS 신규 |
| 5 | - | Z-order | 레이어 겹침 순서 | v2.0 Defer | - |
| 6 | - | Angle | 요소 회전 | v2.0 Defer | - |
| 7 | - | Animation In/Out | 등장/퇴장 + 속도 슬라이더 | v2.0 Defer | - |
| 8 | - | Transition | Default/Pop/Expand/Slide | v2.0 Defer | - |
| 9 | - | Text | 폰트, 색상, 강조색, 정렬, 그림자 | v2.0 Defer | - |
| 10 | - | Background Image | 요소 배경 | v2.0 Defer | - |
| 11 | - | Live Preview | 하단 실시간 프리뷰 | v2.0 Defer | - |
| **Player Overlay 요소 (8개)** | | | | | |
| 12 | A | Player Photo | 프로필 이미지 | v1.0 Keep | SV-029 매핑 |
| 13 | B | Hole Cards | 홀카드 2~5장 | v1.0 Keep | - |
| 14 | C | Name | 플레이어 이름 | v1.0 Keep | - |
| 15 | D | Country Flag | 국적 국기 | v2.0 Defer | SV-029 매핑 |
| 16 | E | Equity % | 승률 | v2.0 Defer | Equity 엔진 전제 |
| 17 | F | Action | 최근 액션 | v1.0 Keep | - |
| 18 | G | Stack | 칩 스택 | v1.0 Keep | - |
| 19 | H | Position | 포지션 (D/SB/BB) | v1.0 Keep | - |

### Gap 요소 (매뉴얼 있음, PRD 없음)

| # | GAP ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 결정 | 근거 |
|---|--------|--------|----------------|:------:|:--------:|------|
| 1 | GAP-9-01 | Chroma Keying (Skin) | "Chroma Keying: 반투명 스킨의 크로마키 처리" | p.64 | v2.0 Defer | SK-03(Remove Transparency)와 관련. 반투명 스킨의 크로마키 처리 방식 — PRD의 SK-03으로 매핑 가능하나 별도 설명 미기재 |
| 2 | GAP-9-02 | UHD 4K Skin | "UHD 4K (3840 x 2160): 4K 스킨 지원" | p.64 | v2.0 Defer | SK-04(4K Design)로 매핑. 4K 스킨 제작 지원 |
| 3 | GAP-9-03 | Ticker Editor | "Ticker Editor: 하단/상단 스크롤 텍스트 편집" | p.64 | v3.0 Defer | SK-06의 Element Buttons 중 하나. WSOP LIVE DB 연동 시 활용 (GC-021 Defer 기준) |
| 4 | GAP-9-04 | Split Screen Divider | "Split Screen Divider: 화면 분할선 편집" | p.64 | v2.0 Defer | SK-06의 Element Buttons 중 하나. Split Screen 기능 연동 |
| 5 | GAP-9-05 | Language Editor | "Language Editor: UI 텍스트 다국어 편집" | p.64 | v3.0 Defer | SK-10(Language)와 연동. GC-025(다국어) v3.0 기준 적용 |
| 6 | GAP-9-06 | Custom Animations | "Custom Animations: 커스텀 애니메이션 지원" | p.64 | v2.0 Defer | Graphic Editor의 Animation In/Out 확장 기능 |

### PokerGFX 대비 EBS 변경점

1. **PokerGFX 87개 → EBS 29개 (Skin 26 + Graphic 19개 중 Board 공통 10 + Player 8 + 신규 1)**: Board(39개)+Player(48개)를 단일 에디터 + 모드 전환으로 통합. 공통 기능(Position, Animation, Text, Background) 60% 이상 중복 제거.
2. **SK-18~SK-20 국기 관련 → P2**: PokerGFX에서 분산되어 있던 국기 3개(24~26번)를 P2 그룹으로 통합.
3. **GAP-9-03 Ticker Editor → v3.0 Defer**: PokerGFX에서는 Skin Editor 내 기본 요소였으나, EBS에서는 WSOP LIVE DB 연동 단계(v3.0)에서 구현.

---

## 부록 A: Gap 요소 전체 목록

매뉴얼에 존재하지만 PRD-0004 Element Catalog에 없거나 다른 Step으로 이동된 요소 전체 목록.

| # | GAP ID | Step | 요소명 | 매뉴얼 페이지 | EBS 결정 | 비고 |
|---|--------|:----:|--------|:------------:|:--------:|------|
| 1 | GAP-1-01 | 1 | Secure Delay Icon | p.34 | v1.0 Keep | SEC-005로 기능 흡수 |
| 2 | GAP-1-02 | 1 | Settings Reset | p.33 | v2.0 Defer | Ctrl+Start 리셋 → Settings 다이얼로그 내 Factory Reset |
| 3 | GAP-2-01 | 2 | Setup WIFI | p.60 | v3.0 Defer | RFID 리더 WiFi 설정. EBS 하드웨어 스펙 확정 후 재설계 |
| 4 | GAP-2-02 | 2 | Secure Delay Folder | p.60 | v1.0 Keep | System 탭 내 Storage 그룹으로 명시 필요 |
| 5 | GAP-3-01 | 3 | Linger on Board | p.36 | v2.0 Defer | Auto Camera v2.0 구현 시 S-10 그룹에 포함 |
| 6 | GAP-3-02 | 3 | Post Bet | p.37 | v2.0 Defer | Auto Camera 하위 설정 |
| 7 | GAP-3-03 | 3 | Post Hand | p.37 | v2.0 Defer | Auto Camera 하위 설정 |
| 8 | GAP-3-04 | 3 | Key & Fill (Sources 위치) | p.39 | v1.0 Keep | PRD에서 Outputs(O-05)으로 배치 — 위치 메모 |
| 9 | GAP-4-01 | 4 | Video Preview | p.42 | v2.0 Defer | 모니터 미리보기 출력 |
| 10 | GAP-4-02 | 4 | Audio Preview | p.42 | v2.0 Defer | 오디오 모니터링 |
| 11 | GAP-4-03 | 4 | Secure Delay (toggle) | p.44 | v1.0 Keep | SEC-001/010/011로 분산 매핑됨. Outputs 탭에 전용 섹션 필요 |
| 12 | GAP-4-04 | 4 | Secure Delay Active (3 conditions) | p.44 | v1.0 Keep | SEC-005(모드 표시) UX 비헤이비어 명세 |
| 13 | GAP-4-05 | 4 | Auto Delay | p.45 | v2.0 Defer | 자동 딜레이 활성/비활성 |
| 14 | GAP-4-06 | 4 | Delay Countdown | p.45 | v1.0 Keep | SEC-002 매핑 |
| 15 | GAP-4-07 | 4 | Dynamic Delay | p.46 | v2.0 Defer | 토너먼트 브레이크 자동 스킵 |
| 16 | GAP-5-01 | 5 | Transition In Animation | p.49 | v2.0 Defer | G-17과 동일. 매뉴얼 원문 G-17 설명에 미포함 |
| 17 | GAP-5-02 | 5 | Transition Out Animation | p.49 | v2.0 Defer | G-18과 동일. 매뉴얼 원문 G-18 설명에 미포함 |
| 18 | GAP-5-03 | 5→3 | Show Outs | p.51 | v2.0 Defer | PRD에서 G-40(GFX 3)으로 재배치 |
| 19 | GAP-5-04 | 5→3 | Outs Position | p.51 | v2.0 Defer | PRD에서 G-41(GFX 3)으로 재배치 |
| 20 | GAP-5-05 | 5→3 | True Outs | p.51 | v2.0 Defer | PRD에서 G-42(GFX 3)으로 재배치 |
| 21 | GAP-5-06 | 5→6 | Allow Rabbit Hunting | p.52 | v2.0 Defer | PRD에서 G-54(GFX 2)로 재배치 |
| 22 | GAP-5-07 | 5→6 | Clear Previous Action | p.52 | v1.0 Keep | PRD에서 G-35(GFX 2)로 재배치 |
| 23 | GAP-5-08 | 5→6 | Unknown Cards Blink | p.52 | v1.0 Keep | PRD에서 G-34(GFX 2)로 재배치 |
| 24 | GAP-6-01 | 6→7 | Show Blinds | p.50 | v1.0 Keep | PRD에서 G-45(GFX 3)으로 재배치 |
| 25 | GAP-6-02 | 6→7 | Show Hand # Blinds | p.50 | v1.0 Keep | PRD에서 G-46(GFX 3)으로 재배치 |
| 26 | GAP-6-03 | 6→5 | Show leaderboard after each hand | p.50 | v2.0 Defer | PRD에서 G-22(GFX 1)으로 재배치 |
| 27 | GAP-6-04 | 6→5 | Show player stats in ticker | p.50 | v2.0 Defer | PRD에서 G-24(GFX 1)으로 재배치 |
| 28 | GAP-6-05 | 6 | Show eliminated players in Strip | p.53 | v2.0 Defer | PRD에 완전 누락. G-43/G-44 그룹에 추가 필요 |
| 29 | GAP-6-06 | 6 | Show eliminated players in Leaderboard | p.53 | v2.0 Defer | G-28(Show Eliminated)과 유사하나 Leaderboard 전용 |
| 30 | GAP-7-01 | 7→6 | Max BB Multiple | p.50 | v1.0 Keep | PRD에서 G-31(GFX 2)으로 배치. GFX 3 BB 그룹과 불일치 |
| 31 | GAP-7-02 | 7→6 | Show Chipcount % | p.53 | v1.0 Keep | PRD에서 G-27(GFX 2)으로 배치. 위치 메모 |
| 32 | GAP-7-03 | 7 | Display Side Pot Amount | p.53 | v1.0 Keep | PRD에 완전 누락. G-50 그룹에 추가 필요. 방송 필수 |
| 33 | GAP-9-01 | 9 | Chroma Keying (Skin) | p.64 | v2.0 Defer | SK-03으로 매핑 가능 |
| 34 | GAP-9-02 | 9 | UHD 4K Skin | p.64 | v2.0 Defer | SK-04로 매핑 가능 |
| 35 | GAP-9-03 | 9 | Ticker Editor | p.64 | v3.0 Defer | WSOP LIVE DB 연동 전제 |
| 36 | GAP-9-04 | 9 | Split Screen Divider | p.64 | v2.0 Defer | SK-06 Element Buttons 중 하나 |
| 37 | GAP-9-05 | 9 | Language Editor | p.64 | v3.0 Defer | SK-10 연동. 다국어 v3.0 |
| 38 | GAP-9-06 | 9 | Custom Animations | p.64 | v2.0 Defer | Graphic Editor Animation 확장 |

### Gap 요소 결정 분포

| EBS 결정 | Gap 수 | 비율 |
|:--------:|:------:|:----:|
| v1.0 Keep | 11 | 29% |
| v2.0 Defer | 22 | 58% |
| v3.0 Defer | 4 | 11% |
| Drop | 0 | 0% |
| **합계** | **37** | **100%** |

> 참고: GAP-3-04, GAP-7-01, GAP-7-02, GAP-6-03/04, GAP-5-03~08, GAP-6-01/02는 "PRD에 없음"이 아니라 "다른 Step으로 이동"된 요소. 실제 PRD 완전 누락 Gap은 GAP-2-01/02, GAP-3-01~03, GAP-4-01~07, GAP-6-05/06, GAP-7-03, GAP-9-01~06 = 20개.

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-02-26 | v3.0.0 | "EBS 신규" 요소 전면 제거. 완전 요소 목록에서 EBS 결정이 "EBS 신규"인 행 삭제(Step1: M-01/02/06/09/12, Step2: Y-08/10, Step3: S-00/04, Step4: O-18/19/20). 모든 Step의 "EBS 신규 요소" 섹션 삭제. 요약 통계 EBS 신규 요소 컬럼 전체 0으로 업데이트. |
| 2026-02-26 | v2.1.0 | 요약 통계 합계 수정 (184→176). PRD-0004 부록 A v16.0.0 이전 기준(184)과 현재 Element Catalog 기준(176) 차이 주석 추가. M-08/M-10/O-06~O-13 Future 처리 설명 추가. |
| 2026-02-26 | v2.0.0 | 모든 Step(1~9) 완전 요소 설계 완성. Gap 요소 37개 식별(PRD 완전 누락 20개 + 탭 이동 13개 + 위치 메모 4개). 설계 결정 완료. |
| 2026-02-26 | v1.0.0 | 최초 작성 (스켈레톤 + Step 1~2 초안) |

---
**Version**: 3.0.0 | **Updated**: 2026-02-26
