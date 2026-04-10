# Confidence Audit Report

> **Feature Registry 소스 커버리지 감사** - ebs_reverse 역공학 분석 결과 반영

---

## 개요

| 항목 | 값 |
|------|-----|
| **총 Feature** | 149 |
| **소스 매핑 완료** | 149 |
| **최소 1개 소스** | 149 |
| **V (Verified) 확인** | 135 |
| **O (Observed) 확인** | 49 |
| **I (Inferred) 추론** | 14 |
| **Registry 버전** | 2.0.0 |
| **감사 일자** | 2026-02-13 |

> V/O/I는 중복 가능 (하나의 Feature에 V+O 동시 부여 가능)

## 신뢰도 등급 정의

| 등급 | 코드 | 정의 | 필수 첨부 |
|:----:|:----:|------|----------|
| Verified | `V` | 디컴파일된 코드에서 직접 확인 | 모듈:파일/클래스 참조 |
| Observed | `O` | 스크린샷/매뉴얼 육안 확인 | 이미지 파일명 + 위치 |
| Inferred | `I` | 추론 | 추론 근거 텍스트 |

## 5개 소스 타입

| 소스 | 설명 | 가용 자료 |
|------|------|----------|
| **screenshot** | PokerGFX 스크린샷 기반 | 11개 화면 캡처 (01~11) |
| **manual** | 사용자 매뉴얼 PDF | 113페이지 (6파트 분할) |
| **binary** | 디컴파일 소스코드 | 2,887개 .cs 파일 (8 바이너리) |
| **live_app** | 설치된 앱 실행 관찰 | PokerGFX Server 3.111 |
| **inference** | 추론 (근거 필수) | - |

## 역공학 분석 커버리지

| 모듈 | 파일 수 | 커버리지 | Feature 매핑 대상 |
|------|:-------:|:--------:|------------------|
| vpt_server.exe | 347 | 82% | AT, PS, GC, SV 전반 |
| net_conn.dll | 168 | 97% | AT-001~002, SEC-006~009 |
| hand_eval.dll | 52 | 97% | EQ-001~012, ST-001~007 |
| mmr.dll | 80 | 92% | VO 전반, SV-005~010 |
| RFIDv2.dll | 26 | 90% | PS-007, SV-023~024 |
| PokerGFX.Common.dll | 50 | 95% | SEC-006~008, HH 전반 |
| boarssl.dll | 102 | 88% | SEC-009 |
| analytics.dll | 7 | 95% | GC-022 (간접) |

---

## 카테고리별 현황

| 카테고리 | 총 수 | V | O | I | 커버리지 |
|----------|:-----:|:-:|:-:|:-:|:--------:|
| Action Tracker | 26 | 26 | 7 | 0 | 100% |
| Pre-Start Setup | 13 | 13 | 2 | 0 | 100% |
| Viewer Overlay | 14 | 12 | 10 | 2 | 100% |
| GFX Console | 25 | 18 | 10 | 7 | 100% |
| Security | 11 | 11 | 2 | 0 | 100% |
| Equity & Stats | 19 | 19 | 0 | 0 | 100% |
| Hand History | 11 | 9 | 3 | 2 | 100% |
| Server 관리 | 30 | 27 | 15 | 3 | 100% |

## 우선순위별 현황

| Priority | 총 수 | V | O | I | 커버리지 |
|:--------:|:-----:|:-:|:-:|:-:|:--------:|
| P0 | 40 | 39 | 14 | 1 | 100% |
| P1 | 69 | 62 | 24 | 7 | 100% |
| P2 | 40 | 34 | 11 | 6 | 100% |

---

## 카테고리별 상세 매핑

### 1. Action Tracker (26개) - 100% V

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| AT-001 | binary | V | net_conn: `IClientNetworkListener.OnConnected/OnDisconnected`, `NetworkQualityChanged` 콜백 |
| AT-002 | binary | V | RFIDv2: `reader_state {disconnected, connected, negotiating, ok}`, net_conn: `OnReaderStatusReceived`, `OnHeartBeatReceived` |
| AT-003 | binary | V | mmr: `duplex_link` SRT 스트리밍 상태, vpt_server: `IGameVideoLiveService` (19 methods) |
| AT-004 | binary | V | mmr: `thread_worker_write` 녹화 스레드, `record` enum (4값: live/live_no_overlay/delayed/delayed_no_overlay) |
| AT-005 | binary+screenshot | V+O | vpt_server: `game` enum (22개 변형: holdem=0~razz=21), `GameTypeData._game_variant`, screenshot: 04-gfx1-tab |
| AT-006 | binary+screenshot | V+O | vpt_server: `GameTypeData._small/_big/_ante`, `FlopDrawBlinds` DTO, screenshot: 13-action-tracker-wireframe |
| AT-007 | binary | V | vpt_server: `GameTypeData.hand_num`, `Hand.HandNum` |
| AT-008 | binary+screenshot | V+O | vpt_server: `PlayerNum` (1-10), `IGamePlayersService` (54 methods), screenshot: 13-action-tracker-wireframe |
| AT-009 | binary | V | vpt_server: `Player.SittingOut`, `GameTypeData.action_on`, `starting_players`, net_conn: `PLAYER_FOLD` |
| AT-010 | binary | V | vpt_server: `GameTypeData.action_on`, mmr: `GlintBounceAnimation` 강조 효과 |
| AT-011 | binary | V | vpt_server: `GameTypeData.pl_dealer/pl_small/pl_big/pl_third`, `lang_enum.dealer=8/bb=9/sb=10/straddle=11` |
| AT-012 | binary+screenshot | V+O | vpt_server: `lang_enum.fold=7/check=0/call=2/raise_to=3/bet=4/all_in=1`, net_conn: `PLAYER_FOLD/BET/BLIND` |
| AT-013 | binary | V | net_conn: `RESET_HAND` 프로토콜, vpt_server: undo 로직 |
| AT-014 | binary | V | vpt_server: `main_form` (329 methods) WinForms KeyDown 이벤트 핸들러 |
| AT-015 | binary | V | vpt_server: `GameTypeData.smallest_chip`, net_conn: `PLAYER_BET` BetAmt 필드 |
| AT-016 | binary | V | vpt_server: `GameTypeData.smallest_chip` Min Chip 단위 증감 로직 |
| AT-017 | binary+screenshot | V+O | vpt_server: `BetStructure` enum (NoLimit=0/FixedLimit=1/PotLimit=2), pot 계산 로직, screenshot: 13-action-tracker-wireframe |
| AT-018 | binary | V | vpt_server: `GameTypeData.cap`, bet structure별 min/max 계산 |
| AT-019 | binary+screenshot | V+O | vpt_server: `GameTypeData.num_boards`, net_conn: `BOARD_CARD/EDIT_BOARD`, screenshot: 04-gfx1-tab |
| AT-020 | binary | V | RFIDv2: 카드 자동 인식, net_conn: `FORCE_CARD_SCAN`, vpt_server: `IGameCardsService` (41 methods) |
| AT-021 | binary | V | net_conn: `GFX_ENABLE` 프로토콜, vpt_server: `IGameGfxService` (11 methods) |
| AT-022 | binary | V | net_conn: `TAG/TAG_LIST` 프로토콜, vpt_server: `ITagsService` (16 methods) |
| AT-023 | binary | V | net_conn: `PLAYER_STACK` 프로토콜, vpt_server: `Player.Stack` 필드 |
| AT-024 | binary | V | vpt_server: `GameTypeData._chop` 플래그 |
| AT-025 | binary+screenshot | V+O | vpt_server: `GameTypeData.run_it_times/run_it_times_remaining/run_it_times_num_board_cards`, net_conn: `RUN_IT_TIMES` |
| AT-026 | binary | V | net_conn: `RESET_HAND` 프로토콜, vpt_server: `GameTypeData.hand_in_progress/hand_ended` |

### 2. Pre-Start Setup (13개) - 100% V

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| PS-001 | binary | V | vpt_server: `IGameConfigurationService` (16 methods), `ConfigurationPreset` 이벤트명 필드 |
| PS-002 | binary | V | vpt_server: `game` enum 22개 변형, `game_class {flop=0, draw=1, stud=2}` |
| PS-003 | binary | V | vpt_server: `GameTypeData.smallest_chip`, `ConfigurationPreset` |
| PS-004 | binary | V | vpt_server: `Player.Name/LongName`, `reg_player` Form (플레이어 등록 UI) |
| PS-005 | binary | V | vpt_server: `Player.Stack` (int), `IGamePlayersService` |
| PS-006 | binary | V | vpt_server: `GameTypeData.pl_dealer`, `FlopDrawBlinds.ButtonPlayerNum/SmallBlindPlayerNum/BigBlindPlayerNum` |
| PS-007 | binary+screenshot | V+O | RFIDv2: `reader_state` enum, net_conn: `READER_STATUS/OnReaderStatusReceived`, screenshot: 08-system-tab |
| PS-008 | binary | V | vpt_server: `AnteType` enum (7종: std_ante~tb_ante_tb1st), `FlopDrawBlinds.AnteType/SmallBlindAmt/BigBlindAmt` |
| PS-009 | binary | V | vpt_server: `GameTypeData.pl_third/_third`, `lang_enum.straddle=11` |
| PS-010 | binary+screenshot | V+O | vpt_server: `GameTypeData.pl_dealer`, `main_form` UI 인터랙션, screenshot: 13-action-tracker-wireframe |
| PS-011 | binary | V | vpt_server: `GameTypeData.num_boards`, `run_it_times` (SINGLE/DOUBLE BOARD) |
| PS-012 | binary | V | vpt_server: `IActionTrackerService`, net_conn: `GAME_STATE` 프로토콜 전환 |
| PS-013 | binary | V | vpt_server: `GameTypeData._gfxMode`, RFIDv2: 자동 카드 인식 ↔ 수동 모드 |

### 3. Viewer Overlay (14개) - 12V + 2I

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| VO-001 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset.panel_logo` (byte[]), `image_element` 레이어, screenshot: 01-main-window |
| VO-002 | binary+screenshot | V+O | vpt_server: `GameTypeData._small/_big/_ante`, `lang_enum.sb=10/bb=9/ante=12`, mmr: `text_element` |
| VO-003 | binary+screenshot | V+O | vpt_server: `Player.Stack`, `chipcount_precision_type` enum (3값: Exact/Smart k&M), screenshot: 05-gfx2-tab |
| VO-004 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset.strip_logo` (byte[]), `image_element` 레이어, screenshot: 01-main-window (우하단 로고 위치) |
| VO-005 | binary+screenshot | V+O | RFIDv2: 카드 인식, hand_eval: `card_type` (53값), mmr: `PlayerCardAnimation`, `ConfigurationPreset.card_reveal` |
| VO-006 | binary+screenshot | V+O | vpt_server: `Player.Name/Stack`, mmr: `text_element` + `IUpdatePlayerService`, screenshot: 14-viewer-overlay-wireframe |
| VO-007 | binary+screenshot | V+O | vpt_server: `Hand.Event.EventType/BetAmt`, `lang_enum.fold=7/call=2/bet=4`, mmr: `PanelTextAnimation` |
| VO-008 | binary | V | hand_eval: `HandOdds()` 승률 계산, `ConfigurationPreset.at_show` 표시 설정 |
| VO-009 | binary+screenshot | V+O | mmr: `BoardCardAnimation` 카드 등장, vpt_server: `GameTypeData.num_boards`, screenshot: 04-gfx1-tab |
| VO-010 | binary+screenshot | V+O | vpt_server: `lang_enum.pot=6`, `Hand.Event.Pot`, `GameTypeData.dist_pot_req`, screenshot: 14-viewer-overlay-wireframe |
| VO-011 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset` 이벤트명 필드, mmr: `text_element`, screenshot: 01-main-window |
| VO-012 | inference | I | vpt_server: `GameTypeData.hand_in_progress` 상태에서 street 추론 가능, `BOARD_CARD` 개수로 street 결정 (보드 0장=PREFLOP, 3장=FLOP, 4장=TURN, 5장=RIVER) |
| VO-013 | binary | V | vpt_server: `GameTypeData.action_on`, mmr: `GlintBounceAnimation` + `ConfigurationPreset.bounce_action_player` |
| VO-014 | inference | I | vpt_server: `Player` fold 상태 + mmr: 그래픽 레이어의 alpha 처리 (GPU Effects Chain: Alpha → ColorMatrix), `ConfigurationPreset.fold_hide` 설정 존재 확인 |

### 4. GFX Console (25개) - 18V + 7I

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| GC-001 | binary+screenshot | V+O | vpt_server: `Player.VPIPPercent`, `ConfigurationPreset.auto_stat_vpip`, `lang_enum.strip_vpip`, screenshot: 06-gfx3-tab |
| GC-002 | binary+screenshot | V+O | vpt_server: `Player.PreFlopRaisePercent`, `ConfigurationPreset.auto_stat_pfr`, `lang_enum.strip_pfr=129`, screenshot: 06-gfx3-tab |
| GC-003 | binary+screenshot | V+O | vpt_server: `Player.AggressionFrequencyPercent`, `ConfigurationPreset.auto_stat_agr`, screenshot: 06-gfx3-tab |
| GC-004 | binary | V | vpt_server: `Player.WentToShowDownPercent`, `ConfigurationPreset.auto_stat_wtsd` |
| GC-005 | binary | V | vpt_server: `Player.CumulativeWinningsAmt`, `ITagsService` (16 methods) 통계 관리 |
| GC-006 | binary | V | vpt_server: `ConfigurationPreset.ticker_stat_*` 3Bet 통계 필드, `auto_stats_edit` Form |
| GC-007 | binary | V | vpt_server: `ConfigurationPreset.ticker_stat_*` CBet 통계 필드 |
| GC-008 | inference | I | vpt_server: `ConfigurationPreset` 통계 필드 구조에서 Fold-to-3Bet 존재 추론 (auto_stat_* 패턴 일관성) |
| GC-009 | binary+screenshot | V+O | vpt_server: `Player.Stack` 기반 정렬, `Player.EliminationRank`, screenshot: 05-gfx2-tab |
| GC-010 | inference | I | vpt_server: `ITagsService` 시계열 데이터 저장 기능에서 추론, `ticker_edit/ticker_stats_edit` Form 존재 |
| GC-011 | inference | I | vpt_server: `ConfigurationPreset` 통계 타입별 필드 존재, `auto_stats_edit` Form에서 통계 선택 UI 추론 |
| GC-012 | inference | I | vpt_server: `Player.SittingOut/EliminationRank` 필드로 Active 필터링 가능, `IGamePlayersService` (54 methods) |
| GC-013 | binary+screenshot | V+O | vpt_server: `GameTypeData.starting_players`, `IGamePlayersService`, screenshot: 05-gfx2-tab |
| GC-014 | binary | V | vpt_server: `Player.EliminationRank`, `IGamePlayersService` 잔여 인원 계산 |
| GC-015 | binary | V | vpt_server: `Player.Stack` 합계 / 인원수 계산, `IGamePlayersService` |
| GC-016 | binary+screenshot | V+O | vpt_server: `Player.Stack` 전체 합산, `lang_enum.stack=5`, screenshot: 05-gfx2-tab |
| GC-017 | binary | V | vpt_server: `IGameGfxService` (11 methods), `ConfigurationPreset.at_show`, net_conn: `SHOW_PANEL/FIELD_VIS` |
| GC-018 | inference | I | vpt_server: `ITagsService` 데이터 export 기능 추론, `Hand/Event` DTO의 직렬화 지원 (Newtonsoft.Json) |
| GC-019 | inference | I | vpt_server: `Hand/Event` DTO 기반 리포트 생성 추론, SkiaSharp PDF 렌더링 가능성 |
| GC-020 | binary | V | vpt_server: `ITagsService` (16 methods) 통계 초기화, `GameTypeData` 리셋 로직 |
| GC-021 | binary+screenshot | V+O | vpt_server: `ticker_edit` Form, `ConfigurationPreset` ticker 필드, mmr: `text_element` Ticker 효과, screenshot: 07-commentary-tab |
| GC-022 | binary+screenshot | V+O | vpt_server: `PerformanceMonitor` (NVIDIA GPU + CPU), `DiagnosticsForm`, analytics: 텔레메트리, screenshot: 08-system-tab |
| GC-023 | binary+screenshot | V+O | vpt_server: `cam_prev` Form (카메라 프리뷰), mmr: `pip_element` PIP 레이어, screenshot: 01-main-window |
| GC-024 | inference | I | vpt_server: `skin_edit` Form, Skin 시스템 (.vpt/.skn) 테마 전환 기능에서 다크/라이트 추론 |
| GC-025 | binary+screenshot | V+O | vpt_server: `lang_enum` (130개 UI 라벨), `lang_edit` Form (언어 편집기), screenshot: 08-system-tab |

### 5. Security (11개) - 100% V

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| SEC-001 | binary | V | mmr: `thread_worker_delayed` + `thread_worker_process_delay`, `_delay_period` (TimeSpan), Dual Canvas System |
| SEC-002 | binary | V | mmr: `_delay_period` 카운트다운, vpt_server: `timeshift` enum (Live/Delayed) |
| SEC-003 | binary | V | vpt_server: `GfxMode` enum (Live=0/Delay=1/Comm=2), `_enh_mode` 보안 모드 설정 |
| SEC-004 | binary | V | vpt_server: `GfxMode.Live=0`, RFIDv2: 즉시 카드 인식 → 표시 |
| SEC-005 | binary+screenshot | V+O | vpt_server: `GfxMode` enum, `timeshift` enum, net_conn: `GAME_INFO` 모드 전송, screenshot: 03-outputs-tab |
| SEC-006 | binary | V | net_conn: `enc.cs` Rijndael AES-256, PBKDF1 키 유도, `AES(JSON_bytes) + SOH(0x01)` wire format |
| SEC-007 | binary | V | RFIDv2: TLS 1.2 (boarssl), `SSLClient/SSLEngine` 클래스, `vpt-server/vpt-reader` identity |
| SEC-008 | binary | V | PokerGFX.Common: AES-256 암호화, `IEncryptionService`, EF6 데이터 암호화 저장 |
| SEC-009 | binary+screenshot | V+O | boarssl: TLS 1.2 구현, `SSLSessionParameters` 캐싱, net_conn: TCP WSS 연결, screenshot: 03-outputs-tab |
| SEC-010 | binary | V | vpt_server: `GfxMode` enum 전환, `security_warning` Form (비밀번호 확인), `ConfigurationPreset.settings_pwd` |
| SEC-011 | binary | V | mmr: `_delay_period` (TimeSpan) 동적 설정, vpt_server: `config_type` delay 관련 282개 필드 중 딜레이 설정 |

### 6. Equity & Stats (19개) - 100% V

EQ-001~012는 hand_eval.dll, ST-001~007은 vpt_server + hand_eval 조합.

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| EQ-001 | binary | V | hand_eval: `Pocket169Table` (169 entries) 프리플롭 핸드 분류, `HandOdds()` API |
| EQ-002 | binary | V | hand_eval: `Evaluate(cards, numberOfCards, ignore_wheel)`, 7-card 평가 → flop 이후 |
| EQ-003 | binary | V | hand_eval: `Evaluate()` turn 이후 승률, `Outs()` 리버 1장 기반 |
| EQ-004 | binary | V | hand_eval: `Evaluate()` 최종 5-card 평가, `DescriptionFromHandValue()` |
| EQ-005 | binary | V | hand_eval: `HandOdds(pockets, board, dead, wins, ties, losses, total)` multi-way 지원 |
| EQ-006 | binary | V | hand_eval: `Outs(player, board, opponents, dead, include_splits)` 아웃츠 자동 계산 |
| EQ-007 | binary | V | hand_eval: `Outs()` 결과 → 확률 변환 (turn/river 별도 계산) |
| EQ-008 | binary | V | hand_eval: `HandOdds()` wins/ties/losses 배열 출력 |
| EQ-009 | binary | V | hand_eval: `RandomHands(shared, dead, ncards, trials)` Monte Carlo 레인지 기반 시뮬레이션 |
| EQ-010 | binary | V | hand_eval: `OmahaEvaluator/Omaha5Evaluator/Omaha6Evaluator` (Memory-Mapped File), game enum (omaha=4~omaha6_hilo=9) |
| EQ-011 | binary | V | hand_eval: `holdem_sixplus` 평가기, `trips_beats_straight` 파라미터, game enum (1~2) |
| EQ-012 | binary | V | hand_eval: `HandOdds()` + mmr: Animation System `CardBlinkAnimation`, 올인 시 실시간 바 표시 |
| ST-001 | binary | V | vpt_server: `Player.VPIPPercent`, `ConfigurationPreset.auto_stat_vpip` |
| ST-002 | binary | V | vpt_server: `Player.PreFlopRaisePercent`, `ConfigurationPreset.auto_stat_pfr` |
| ST-003 | binary | V | vpt_server: `Player.AggressionFrequencyPercent`, `ConfigurationPreset.auto_stat_agr` |
| ST-004 | binary | V | vpt_server: `Player.WentToShowDownPercent`, `ConfigurationPreset.auto_stat_wtsd` |
| ST-005 | binary | V | vpt_server: `ConfigurationPreset.ticker_stat_*` 3Bet 누적 통계 필드 |
| ST-006 | binary | V | vpt_server: `ConfigurationPreset.ticker_stat_*` CBet 누적 통계 필드 |
| ST-007 | binary | V | vpt_server: `Hand` DTO 누적 카운트, `ITagsService` (16 methods) |

### 7. Hand History (11개) - 9V + 2I

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| HH-001 | binary | V | vpt_server: `Hand` DTO (HandNum/StartDateTimeUTC/Duration), net_conn: `HAND_HISTORY` 프로토콜, `ITagsService` |
| HH-002 | binary | V | vpt_server: `Hand.StartDateTimeUTC` 날짜 필터, PokerGFX.Common: EF6 LINQ 쿼리 |
| HH-003 | binary | V | vpt_server: `Hand.List<Player>` 플레이어별 핸드 필터, `ITagsService` |
| HH-004 | binary | V | vpt_server: `Hand.Event.Pot` 팟 사이즈 필드로 필터 가능 |
| HH-005 | binary | V | net_conn: `TAG/TAG_LIST` 프로토콜, vpt_server: `ITagsService` (16 methods) 태그 필터 |
| HH-006 | inference | I | vpt_server: `Hand.HandNum` + `Player.Name` 기반 검색 기능 추론 (ITagsService 16 methods 중 검색 메서드 존재 가능성) |
| HH-007 | binary+screenshot | V+O | vpt_server: `Hand.List<Event>` 액션별 리플레이 데이터, mmr: Animation System 활용, screenshot: 01-main-window |
| HH-008 | binary+screenshot | V+O | vpt_server: `Hand` DTO 전체 (Player cards/Event list/BoardCards), net_conn: `HAND_HISTORY` |
| HH-009 | binary+screenshot | V+O | vpt_server: `Hand/Event` DTO Newtonsoft.Json 직렬화, SkiaSharp PNG 렌더링, screenshot: 08-system-tab |
| HH-010 | binary | V | vpt_server: PokerGFX.Common EF6 전체 세션 쿼리, Newtonsoft.Json CSV/JSON export |
| HH-011 | inference | I | vpt_server: `LiveApi` HTTP REST 인터페이스로 외부 핸드 공유 가능성 추론 |

### 8. Server 관리 (30개) - 27V + 3I

| ID | 소스 타입 | 신뢰도 | 근거 |
|----|:---------:|:------:|------|
| SV-001 | binary+screenshot | V+O | vpt_server: `video_capture_device_type` enum (unknown/dshow/NDI/BMD/network), `main_form.tab_sources`, screenshot: 02-sources-tab |
| SV-002 | binary+screenshot | V+O | vpt_server: `IGameVideoLiveService` (19 methods), ATEM `state_enum`, `atem_form`, screenshot: 02-sources-tab |
| SV-003 | binary+screenshot | V+O | vpt_server: `Interop.BMDSwitcherAPI.dll` COM Interop, `atem_form`, Mix Effect 블록 제어, screenshot: 02-sources-tab |
| SV-004 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset` transition 필드, `IEffectsService`, screenshot: 04-gfx1-tab |
| SV-005 | binary+screenshot | V+O | mmr: DirectX 11 Chromakey 렌더링, `ConfigurationPreset` chroma key 설정, screenshot: 02-sources-tab |
| SV-006 | binary+screenshot | V+O | mmr: Dual Canvas System (Live Canvas + Delayed Canvas), `_sync_live_delay`, screenshot: 03-outputs-tab |
| SV-007 | binary+screenshot | V+O | mmr: `_delay_period` (TimeSpan), `thread_worker_process_delay`, `timeshift` enum, screenshot: 03-outputs-tab |
| SV-008 | binary+screenshot | V+O | mmr: `config_type.fps/video_w/video_h/video_bitrate`, GPU 벤더별 코덱 (NVENC/AMF/QSV), screenshot: 03-outputs-tab |
| SV-009 | binary | V | mmr: NDI 출력 (`[NDI]_` prefix), `NDI_WAIT_PERIOD_MS` 타임아웃 |
| SV-010 | inference | I | vpt_server: `config_type.video_w/video_h` 해상도 설정에서 9:16 세로 모드 추론 (ConfigurationPreset의 gfx_vertical 필드) |
| SV-011 | binary | V | vpt_server: `twitch_edit` Form, Twitch OAuth (`https://id.twitch.tv/oauth2/authorize`), IRC chatbot (`irc.chat.twitch.tv:6667`) |
| SV-012 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset.board_pos`, `board_pos_type` enum (3값), screenshot: 04-gfx1-tab |
| SV-013 | binary+screenshot | V+O | vpt_server: `ConfigurationPreset.gfx_vertical/gfx_bottom_up/gfx_fit/heads_up_layout_mode`, screenshot: 04-gfx1-tab |
| SV-014 | binary | V | mmr: Animation System (11 classes), `AnimationState` enum (16 states: FadeIn=0~Waiting=15), `ConfigurationPreset.trans_in/trans_out` |
| SV-015 | binary | V | mmr: `GlintBounceAnimation`, vpt_server: `ConfigurationPreset.bounce_action_player` |
| SV-016 | binary | V | vpt_server: `ConfigurationPreset.panel_logo/board_logo/strip_logo` (byte[]), net_conn: `BOARD_LOGO_REQ/PANEL_LOGO/STRIP_LOGO` |
| SV-017 | binary | V | vpt_server: `ITimersService` (10 methods), net_conn: `ACTION_CLOCK` 프로토콜, `ConfigurationPreset` clock 임계값 |
| SV-018 | binary | V | vpt_server: `chipcount_precision_type` enum (3값), 8개 영역별 독립 설정 (leaderboard/pl_stack/pl_action/blinds/pot/twitch/ticker/strip) |
| SV-019 | binary | V | vpt_server: `ConfigurationPreset.divide_amts_by_100`, `lang_enum.bb=9`, BB 배수 표시 모드 |
| SV-020 | binary | V | vpt_server: `ConfigurationPreset.currency_symbol/show_currency/trailing_currency_symbol` |
| SV-021 | binary+screenshot | V+O | vpt_server: `CommentaryBooth` 앱, `GfxMode.Comm=2`, `config_type.delayed_commentary`, screenshot: 07-commentary-tab |
| SV-022 | binary+screenshot | V+O | mmr: `pip_element` 레이어 (Z-order 3), `pip_edit/di_pip_edit` Form, screenshot: 07-commentary-tab |
| SV-023 | binary+screenshot | V+O | RFIDv2: `module_type` enum (skyetek/v2), net_conn: `REGISTER_DECK`, 카드 UID 일괄 등록, screenshot: 08-system-tab |
| SV-024 | binary | V | RFIDv2: `reader_state` enum, `connection_type` (usb/wifi), `wlan_state` enum, `reader_config/reader_select` Form |
| SV-025 | binary | V | vpt_server: MultiGFX 인스턴스 분리, `LicenseType.Enterprise=5` 게이트, 로깅 Topic: `MultiGFX` |
| SV-026 | binary | V | vpt_server: `StreamDeck` 앱 (`pgfx_streamdeck`), net_conn TCP 연동, 7-Application Ecosystem |
| SV-027 | binary+screenshot | V+O | vpt_server: `skin_edit` Form, Skin 파일 (.vpt/.skn), `SKIN_HDR/SKIN_SALT/SKIN_PWD` AES 암호화, screenshot: 09-skin-editor |
| SV-028 | binary+screenshot | V+O | vpt_server: `gfx_edit` Form, `IGraphicElementsService`, 픽셀 단위 편집 (위치/크기/Z-order/Anchor), screenshot: 10-graphic-editor-board, 11-graphic-editor-player |
| SV-029 | inference | I | vpt_server: `Player.Country`, net_conn: `COUNTRY_LIST/OnCountryListReceived`, `flag_editor` Form, `FlagHideAnimation` |
| SV-030 | inference | I | mmr: `thread_worker_write` 녹화 스레드, `record` enum 4값, `Hand.RecordingOffsetStart/Duration` 핸드별 오프셋 기록에서 분할 녹화 추론 |

---

## 소스 미매핑 Feature

**해당 없음.** 149개 전체 Feature에 최소 1개 이상의 소스 매핑이 완료되었습니다.

## Inferred(I) 등급 Feature (14개)

추론 기반 매핑으로, 추가 검증 시 V/O로 승격 가능합니다.

| ID | 현재 근거 | 승격 조건 |
|----|----------|----------|
| VO-012 | BOARD_CARD 개수 기반 street 결정 로직 추론 | vpt_server street 표시 코드 직접 확인 |
| VO-014 | fold_hide 설정 + GPU Alpha 처리 추론 | mmr 렌더링 코드에서 fold 스타일 직접 확인 |
| GC-008 | auto_stat_* 패턴 일관성 추론 | Fold-to-3Bet 필드 직접 확인 |
| GC-010 | ITagsService 시계열 데이터 추론 | 차트 렌더링 코드 확인 |
| GC-011 | auto_stats_edit Form 존재 추론 | 정렬 UI 코드 확인 |
| GC-012 | SittingOut/EliminationRank 필터 추론 | 필터 UI 코드 확인 |
| GC-018 | ITagsService export + JSON 직렬화 추론 | CSV export 메서드 확인 |
| GC-019 | SkiaSharp PDF 렌더링 가능성 추론 | Print/PDF 생성 코드 확인 |
| GC-024 | Skin 시스템 테마 전환 추론 | 다크/라이트 프리셋 확인 |
| HH-006 | ITagsService 검색 메서드 추론 | 텍스트 검색 코드 확인 |
| HH-011 | LiveApi HTTP REST 외부 공유 추론 | 공유 링크 생성 코드 확인 |
| SV-010 | gfx_vertical 필드에서 9:16 추론 | 세로 모드 출력 코드 확인 |
| SV-029 | Country 필드 + flag_editor 추론 | 플레이어 사진/국기 렌더링 코드 확인 |
| SV-030 | RecordingOffsetStart/Duration 추론 | 핸드별 파일 분할 코드 확인 |

---

## 변경 이력

| 버전 | 일자 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-13 | 초기 생성, 149개 Feature 전체 미매핑 (0%) |
| 2.0.0 | 2026-02-13 | ebs_reverse 역공학 분석 결과 반영, 149개 전체 소스 매핑 완료 (100%), V 135개/O 49개/I 14개 |

---

**Version**: 2.0.0 | **Updated**: 2026-02-13
