# PRD-0004 매뉴얼 v3.2.0 설명 통합 업데이트 계획

## 배경

### 요청 내용
PRD-0004-EBS-Server-UI-Design.md (v20.0.0, 1,740줄)의 Element Catalog 설명에 PokerGFX 매뉴얼 v3.2.0 공식 설명을 통합한다.

### 해결하려는 문제
- PRD-0004의 현재 설명은 역설계/OCR 기반 추론으로 작성됨
- 참조 문서(`PokerGFX-Manual-v3.2.0-Element-Reference.md`)에 공식 매뉴얼 원문이 수록되어 있으나 PRD-0004에 미반영
- M-05 RFID Status가 3색(Green/Red/Yellow)으로만 기술되어 있으나 공식 7색 체계가 존재

### 참조 문서
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/PokerGFX-Manual-v3.2.0-Element-Reference.md` (393줄, v1.0.0)

---

## 구현 범위

### 포함 항목
1. PRD ID가 매핑된 요소의 공식 설명 추가/보완
2. M-05 RFID Status 7색 상태 확장
3. 버전 v20.0.0 → v21.0.0 업데이트
4. 변경 이력 항목 추가

### 제외 항목
- N/A (PRD ID 없는) 요소의 신규 추가 — PRD-0004 구조 변경 없음
- AT 전용 요소 — 별도 PRD (action-tracker.prd.md) 범위
- 새로운 섹션 생성
- 기존 한글 설명 대체 — 보완만 수행

---

## 영향 파일

### 수정 예정 파일
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md`

### 신규 생성 파일
- 없음

---

## 업데이트 대상 항목 전체 목록

### 카테고리 1: M-05 RFID Status 확장 (최우선)

현재 PRD-0004 182줄:
```
| M-05 | RFID Status | Icon+Badge | Green=Connected, Red=Disconnected, Yellow=Calibrating |
```

공식 7색 체계로 확장:
| 색상 | 공식 설명 | 매뉴얼 페이지 |
|------|----------|:----------:|
| Green | RFID Reader is operating normally. | p.34 |
| Grey | Server is establishing a secure link with the RFID Reader. | p.34 |
| Blue | RFID Reader operating normally, unregistered cards on table. | p.34 |
| Black | RFID Reader operating normally, duplicate rank/suit detected. | p.34 |
| Magenta | RFID Reader operating normally, duplicate cards detected. | p.34 |
| Orange | RFID Reader connected but not responding. | p.34 |
| Red | RFID Reader is not connected. | p.34 |

### 카테고리 2: Main Window 요소 (M-*)

| PRD ID | 요소명 | PRD-0004 위치 (줄 근처) | 업데이트 내용 |
|--------|--------|:---:|-------------|
| M-03 | CPU Indicator | ~180 | 공식 설명 추가: "CPU and GPU usage. If they turn red, usage is too high..." (p.34) |
| M-04 | GPU Indicator | ~181 | 동일 공식 설명 추가 (M-03과 동일 원문) |
| M-05 | RFID Status | ~182 | **7색 확장** (카테고리 1 참조) |
| M-07 | Lock Toggle | ~203 | 공식 설명 추가: "Click the Lock symbol... to password protect the Settings Window." (p.33) |

### 카테고리 3: Sources 탭 요소 (S-*)

| PRD ID | 요소명 | PRD-0004 위치 (줄 근처) | 업데이트 내용 |
|--------|--------|:---:|-------------|
| S-01 | Device Table | ~430 | 공식 설명 추가: "list of available video sources... USB cameras, video capture cards... NDI sources" (p.35) |
| S-02 | Add Button | ~431 | 공식 설명 추가: "Network cameras can't be auto detected... click 'Add network camera'" (p.35) |
| S-03 | Settings | ~432 | 공식 설명 추가: "edit the properties of the video source" (p.35) |
| S-05 | Board Cam Hide GFX | ~434 | 공식 설명 추가: "all player graphics will be made invisible while board cam is active" (p.36) |
| S-07 | Cycle Mode | ~436 | 공식 설명 추가: "display video sources in rotation... 'Cycle' mode" (p.35) |
| S-08 | Heads Up Split | ~437 | 공식 설명 추가: "both players are covered by separate cameras, a split screen view" (p.37) |
| S-09 | Follow Players | ~438 | 공식 설명 추가: "video will switch to ensure that the player whose turn it is to act is always displayed" (p.37) |
| S-10 | Follow Board | ~439 | 공식 설명 추가: "video will switch to the community card close-up" (p.36) |
| S-11/S-12 | Chroma Key | ~440-441 | 공식 설명 추가: "outputting graphics on a solid colour background" (p.39) |
| S-13 | External Switcher | ~442 | 공식 설명 추가: "disables the built-in multi-camera switching features" (p.38) |
| S-14 | ATEM Control | ~443 | 공식 설명 추가: "automatically switch camera inputs to follow the action" (p.40) |
| S-15 | Board Sync | ~444 | 공식 설명 추가: "Delays the detection of community cards by the specified number of milliseconds" (p.38) |
| S-16 | Crossfade | ~445 | 공식 설명 추가: "Crossfade setting is zero, camera sources transition with a hard cut" (p.38) |
| S-17 | Audio Input | ~446 | 공식 설명 추가: "Select the desired audio capture device and volume" (p.38) |

### 카테고리 4: Outputs 탭 요소 (O-*)

| PRD ID | 요소명 | PRD-0004 위치 (줄 근처) | 업데이트 내용 |
|--------|--------|:---:|-------------|
| O-01 | Video Size | ~542 | 공식 설명 추가: "Select the desired resolution and frame rate" (p.42) |
| O-02 | 9x16 Vertical | ~543 | 공식 설명 추가: "supports vertical video natively... stream POV-style content" (p.43) |
| O-04 | Live Device | ~545 | 공식 설명 추가: "Sends the live and/or delayed video and audio feed to a Blackmagic Decklink device output... or NDI stream" (p.42) |
| O-05 | Key & Fill | ~546 | 공식 설명 추가: "separate key & fill signals to be sent to 2 SDI connectors" (p.43) |
| O-14 | Virtual Camera | ~549 | 공식 설명 추가: "Sends video and audio feed to POKERGFX VCAM virtual camera device" (p.43) |
| O-16 | Twitch ChatBot | ~551 | 공식 설명 추가: "fully functional ChatBot compatible with Twitch... !event, !blinds, !players..." (p.47) |

### 카테고리 5: GFX 1 탭 요소 (G-01 ~ G-16)

| PRD ID | 요소명 | PRD-0004 위치 (줄 근처) | 업데이트 내용 |
|--------|--------|:---:|-------------|
| G-01 | Board Position | ~706 | 공식 설명 추가: "Position of the Board graphic... LEFT, CENTRE and RIGHT" (p.48) |
| G-02 | Player Layout | ~707 | 공식 설명 추가: 5가지 레이아웃 모드 공식 설명 (Horizontal, Vert/Bot/Spill, Vert/Bot/Fit, Vert/Top/Spill, Vert/Top/Fit) (p.48) |
| G-03 | X Margin | ~708 | 공식 설명 추가: "controls the size of the horizontal margins... 0 and 1" (p.49) |
| G-04/G-05 | Y Margin | ~709-710 | 공식 설명 추가: "controls the size of the vertical margins" (p.49) |
| G-06 | Leaderboard Position | ~711 | 공식 설명 추가: "Selects the position of the Leaderboard graphic" (p.49) |
| G-07 | Heads Up Layout | ~712 | 공식 설명 추가: "Overrides the player layout when players are heads-up... board graphic positioned at bottom centre" (p.48) |
| G-09 | Heads Up Custom Y | ~714 | 공식 설명 추가: "specify the vertical position of player graphics when Heads Up layout is active" (p.48) |
| G-10 | Sponsor Logo 1 | ~715 | 공식 설명 추가: "Displays a sponsor logo at the top of the Leaderboard" (p.50) |
| G-11 | Sponsor Logo 2 | ~716 | 공식 설명 추가: "Displays a sponsor logo to the side of the Board" (p.50) |
| G-12 | Sponsor Logo 3 | ~717 | 공식 설명 추가: "Displays a sponsor logo at the left-hand end of the Strip" (p.50) |
| G-13 | Vanity Text | ~718 | 공식 설명 추가: "Custom text displayed on the Board Card / Pot graphic" + "Replace Vanity" (p.49) |
| G-14 | Reveal Players | ~724 | 공식 설명 추가: "Determines when players are shown: Immediate / On Action / After Bet / On Action + Next" (p.50) |
| G-15 | How to Show Fold | ~725 | 공식 설명 추가: Immediate vs Delayed 공식 설명 (p.51) |
| G-16 | Reveal Cards | ~726 | 공식 설명 추가: 6가지 모드(Immediate/After Action/End of Hand/Showdown Cash/Showdown Tourney/Never) (p.51) |

### 카테고리 6: System 탭 요소 (Y-*)

| PRD ID | 요소명 | PRD-0004 위치 (줄 근처) | 업데이트 내용 |
|--------|--------|:---:|-------------|
| Y-01 | Table Name | ~305 | 공식 설명 추가: "optional name for this table... required when using MultiGFX mode" (p.60) |
| Y-02 | Table Password | ~306 | 공식 설명 추가: "Password for this table" (p.60) |
| Y-03 | RFID Reset | ~307 | 공식 설명 추가: "Resets the RFID Reader connection, as if PokerGFX had been closed and restarted" (p.60) |
| Y-04 | Calibrate | ~308 | 공식 설명 추가: "Perform the once-off table calibration procedure" (p.60) |
| Y-05 | UPCARD Antennas | ~309 | 공식 설명 추가: "Enables all antennas configured for reading UPCARDS in STUD games to also detect hole cards" (p.59) |
| Y-06 | Disable Muck | ~310 | 공식 설명 추가: "Causes the muck antenna to be disabled when in Action Tracker mode" (p.59) |
| Y-09 | Table Diagnostics | ~313 | 공식 설명 추가: "Displays a diagnostic window... physical table configuration along with how many cards are currently detected on each antenna" (p.60) |
| Y-12 | Export Folder | ~315 | 공식 설명 추가: "specify the location for writing the JSON hand history files" (p.60) |
| Y-13 | Allow AT Access | ~316 | 공식 설명 추가: "'Track the action' can only be started from Action Tracker if this option is enabled" (p.58) |
| Y-14 | Predictive Bet | ~317 | 공식 설명 추가: "auto-complete bets and raises based on the initial digits entered, min raise amount and stack size" (p.60) |
| Y-15 | Kiosk Mode | ~318 | 공식 설명 추가: "Action Tracker is automatically started on the same PC on the secondary display in kiosk mode" (p.58) |
| Y-16 | MultiGFX | ~319 | 공식 설명 추가: "Forces PokerGFX to sync to another primary PokerGFX running on a different, networked computer" (p.58) |
| Y-17 | Sync Stream | ~320 | 공식 설명 추가: "forces secure delay to start and stop in synchronization with the primary server" (p.58) |
| Y-18 | Sync Skin | ~321 | 공식 설명 추가: "Causes the secondary MultiGFX server skin to auto update" (p.58) |
| Y-19 | No Cards | ~322 | 공식 설명 추가: "no hole card information will be shared with any secondary server" (p.58) |
| Y-21 | Ignore Name Tags | ~324 | 공식 설명 추가: "player ID tags are ignored; player names are entered manually" (p.59) |
| Y-22 | Auto Start | ~325 | 공식 설명 추가: "Automatically start the PokerGFX Server when Windows starts" (p.58) |
| Y-24 | Check for Updates | ~327 | 공식 설명 추가: "Force the Server to check to see if there's a software update available" (p.58) |

---

## 업데이트 전략

### 설명 포맷 (통일)

기존 한글 설명 뒤에 `(매뉴얼: "공식 원문 인용", p.XX)` 형식으로 추가한다.

**적용 전**:
```
| M-03 | CPU Indicator | ProgressBar | CPU 사용률 + 색상 코딩 (Green<60%, Yellow<85%, Red>=85%) | #3 | P1 |
```

**적용 후**:
```
| M-03 | CPU Indicator | ProgressBar | CPU 사용률 + 색상 코딩 (Green<60%, Yellow<85%, Red>=85%). 매뉴얼: "The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably." (p.34) | #3 | P1 |
```

### M-05 특수 처리

M-05는 설명 컬럼 자체를 확장하여 7색 상태를 기술한다:

**적용 전**:
```
| M-05 | RFID Status | Icon+Badge | Green=Connected, Red=Disconnected, Yellow=Calibrating | #3 | P0 |
```

**적용 후**:
```
| M-05 | RFID Status | Icon+Badge | RFID 리더 상태 7색 표시. Green=정상 운용, Grey=보안 링크 수립 중, Blue=정상 운용+미등록 카드 감지, Black=정상 운용+동일 카드 중복 감지, Magenta=정상 운용+중복 카드 감지, Orange=연결됨+응답 없음(CPU 과부하/USB 문제), Red=미연결. 매뉴얼 p.34 | #3 | P0 |
```

### G-02 Player Layout 특수 처리

5가지 레이아웃 모드의 공식 설명이 있으므로 설명에 주요 모드 목록을 보완한다.

### G-16 Reveal Cards 특수 처리

6가지 모드의 공식 설명이 있으므로 설명에 모드 목록을 보완한다.

---

## 위험 요소

### Risk 1: 대형 문서 Edit 시 토큰 초과
- PRD-0004는 1,740줄의 대형 문서
- 단일 Edit로 전체를 수정하면 토큰 한계 초과 가능
- **완화**: Map-Reduce 청킹 — 섹션별 Edit 순차 수행 (아래 실행 순서 참조)

### Risk 2: 테이블 포맷 깨짐
- Markdown 테이블의 파이프(`|`) 안에 공식 영문 인용을 추가하면 열 폭이 급격히 늘어남
- **완화**: 인용 원문은 핵심 부분만 발췌 (50자 이내로 축약). 전체 원문은 참조 문서 링크로 대체

### Risk 3: 기존 설명과 공식 설명의 충돌
- 역설계 기반 추론이 공식 설명과 다를 수 있음
- **완화**: 기존 설명을 대체하지 않고 "매뉴얼:" 접미사로 병기. 명백한 오류(M-05 3색→7색)만 기존 설명 수정

### Edge Case 1: 참조 문서의 PRD ID가 PRD-0004에 없는 경우
- O-05 Key & Fill이 참조 문서에서 Sources 탭(S-11/S-12 아래)과 Outputs 탭(O-05/O-07) 양쪽에 등장
- **처리**: PRD-0004의 해당 요소 위치에만 반영. 동일 설명이 중복되면 주 위치에만 추가

### Edge Case 2: 참조 문서의 N/A 항목 중 PRD-0004 기능에 해당하는 것
- 참조 문서에서 N/A로 표기된 항목 중 일부는 PRD-0004에 이미 다른 ID로 존재할 수 있음
- 예: "Linger on Board" (N/A) — PRD-0004 Sources 탭 설명에 이미 반영된 개념
- **처리**: N/A 항목은 이번 업데이트에서 추가하지 않음. 기존 ID가 있는 항목만 업데이트

---

## 태스크 목록

### Task 1: M-05 RFID Status 7색 확장
- **파일**: `C:/claude/ebs/docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md`
- **위치**: 182줄 근처 (Element Catalog 상태 표시 그룹)
- **수행 방법**: Edit 도구로 M-05 행의 설명 컬럼을 7색 상태로 확장
- **Acceptance Criteria**: M-05 설명에 Green/Grey/Blue/Black/Magenta/Orange/Red 7색이 모두 기술됨

### Task 2: Main Window 요소 업데이트 (M-03, M-04, M-07)
- **파일**: 동일
- **위치**: 180~203줄 근처 (Element Catalog)
- **수행 방법**: 각 요소의 설명 컬럼에 `매뉴얼: "..." (p.XX)` 추가
- **Acceptance Criteria**: M-03, M-04, M-07 설명에 매뉴얼 공식 원문 인용 포함

### Task 3: System 탭 요소 업데이트 (Y-01 ~ Y-24, 18개)
- **파일**: 동일
- **위치**: 305~327줄 근처 (System Element Catalog)
- **수행 방법**: 각 요소의 설명 컬럼에 공식 설명 추가
- **Acceptance Criteria**: Y-01, Y-02, Y-03, Y-04, Y-05, Y-06, Y-09, Y-12, Y-13, Y-14, Y-15, Y-16, Y-17, Y-18, Y-19, Y-21, Y-22, Y-24 — 18개 요소 모두 매뉴얼 인용 포함

### Task 4: Sources 탭 요소 업데이트 (S-01 ~ S-17, 14개)
- **파일**: 동일
- **위치**: 430~447줄 근처 (Sources Element Catalog)
- **수행 방법**: 각 요소의 설명 컬럼에 공식 설명 추가
- **Acceptance Criteria**: S-01, S-02, S-03, S-05, S-07, S-08, S-09, S-10, S-11, S-12, S-13, S-14, S-15, S-16, S-17 — 14개 요소 모두 매뉴얼 인용 포함

### Task 5: Outputs 탭 요소 업데이트 (O-01 ~ O-16, 6개)
- **파일**: 동일
- **위치**: 542~551줄 근처 (Outputs Element Catalog)
- **수행 방법**: 각 요소의 설명 컬럼에 공식 설명 추가
- **Acceptance Criteria**: O-01, O-02, O-04, O-05, O-14, O-16 — 6개 요소 모두 매뉴얼 인용 포함

### Task 6: GFX 1 탭 요소 업데이트 — Layout 그룹 (G-01 ~ G-13, 12개)
- **파일**: 동일
- **위치**: 706~718줄 근처 (GFX 1 Layout Element Catalog)
- **수행 방법**: 각 요소의 설명 컬럼에 공식 설명 추가. G-02는 5가지 모드, G-13은 Replace Vanity 추가 설명 포함
- **Acceptance Criteria**: G-01, G-02, G-03, G-04, G-05, G-06, G-07, G-09, G-10, G-11, G-12, G-13 — 12개 요소 모두 매뉴얼 인용 포함

### Task 7: GFX 1 탭 요소 업데이트 — Visual 그룹 (G-14 ~ G-16, 3개)
- **파일**: 동일
- **위치**: 724~726줄 근처 (GFX 1 Visual Element Catalog)
- **수행 방법**: G-14 Reveal Players (4가지 모드), G-15 Fold (2가지 모드), G-16 Reveal Cards (6가지 모드) 공식 설명 추가
- **Acceptance Criteria**: G-14, G-15, G-16 설명에 모든 모드의 공식 설명 포함

### Task 8: 버전 업데이트 및 변경 이력 추가
- **파일**: 동일
- **위치**: 1~8줄 (frontmatter), 1716~1740줄 (변경 이력 + 버전 태그)
- **수행 방법**:
  - frontmatter `version: "20.0.0"` → `"21.0.0"`, `last_updated: "2026-02-25"` → `"2026-02-26"`
  - 변경 이력 테이블에 v21.0.0 행 추가
  - 최하단 버전 태그 업데이트
- **Acceptance Criteria**: frontmatter, 변경 이력 테이블, 최하단 태그 모두 v21.0.0 / 2026-02-26

---

## 섹션별 Edit 순서 (Map-Reduce 청킹 계획)

대형 문서 프로토콜(300줄+ 문서)에 따라 섹션별 순차 Edit를 수행한다.

```
  [Round 1] Task 1: M-05 RFID 7색 확장 (182줄)
       |
       v
  [Round 2] Task 2: M-03, M-04, M-07 (180~203줄)
       |
       v
  [Round 3] Task 3: Y-* 요소 18개 (305~327줄)
       |
       v
  [Round 4] Task 4: S-* 요소 14개 (430~447줄)
       |
       v
  [Round 5] Task 5: O-* 요소 6개 (542~551줄)
       |
       v
  [Round 6] Task 6: G-01~G-13 Layout (706~718줄)
       |
       v
  [Round 7] Task 7: G-14~G-16 Visual (724~726줄)
       |
       v
  [Round 8] Task 8: 버전 + 변경 이력 (1~8줄 + 1716~1740줄)
```

**순서 근거**: 줄 번호 오름차순으로 Edit. 앞쪽 Edit가 줄 수를 변경해도 뒤쪽 Edit에 영향을 최소화하기 위해 Task 1(182줄)부터 시작하고 Task 8(1716줄)에서 종료. 단, Task 8의 frontmatter(1~8줄)는 줄 수 변경이 없으므로 마지막에 처리해도 안전.

**Edit 크기 제한**: 각 Round의 Edit는 old_string이 고유하도록 충분한 컨텍스트를 포함한다. 하나의 Round에서 여러 Edit가 필요한 경우(예: Task 3의 18개 요소) 독립적인 행을 개별 Edit로 처리하거나, 테이블 전체를 하나의 Edit로 처리한다.

---

## 커밋 전략

```
docs(prd-0004): 매뉴얼 v3.2.0 공식 설명 통합 (v21.0.0)

- M-05 RFID Status 3색→7색 확장
- M/S/O/G/Y 요소 56개에 매뉴얼 공식 설명 추가 (M:4, S:14, O:6, G:15, Y:18, S-11/S-12 및 G-04/G-05 합산 기준)
- 참조: PokerGFX-Manual-v3.2.0-Element-Reference.md
```

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-02-26 | v1.0.0 | 최초 작성 |
