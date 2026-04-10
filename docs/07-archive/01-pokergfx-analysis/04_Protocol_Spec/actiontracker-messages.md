# ActionTracker Network Messages

> PokerGFX ActionTracker (vpt_remote) 클라이언트-서버 프로토콜 메시지 페이로드 스키마.
> 난독화된 C# decompiled 소스에서 추출. 총 **68개** 메시지 (Send 62 + Receive 15 + Dispatch 내부).

**소스 파일**:
- `ClientNetworkService.cs` -- Send* 메서드 (Client -> Server 요청)
- `CoreNetworkListener.cs` -- On*Received 핸들러 (Server -> Client 응답)
- `core.cs` -- 게임 로직에서의 Send* 호출 패턴
- `comm.cs` -- 터치 입력 UI (키패드/알파벳 패드)

---

## 카테고리별 인덱스

| # | 카테고리 | 메시지 수 | 설명 |
|:-:|----------|:---------:|------|
| 1 | [Connection/Session](#1-connectionsession) | 5 | 연결, 인증, heartbeat |
| 2 | [Player Management](#2-player-management) | 10 | 추가, 삭제, 이름, 국적, 사진 |
| 3 | [Betting Actions](#3-betting-actions) | 5 | bet, fold, check/call, blind |
| 4 | [Board/Cards](#4-boardcards) | 7 | 카드 입력, 클리어, RFID 스캔 |
| 5 | [Pot/Chips](#5-potchips) | 3 | 칩 이동, stack 설정 |
| 6 | [Hand Control](#6-hand-control) | 7 | 핸드 시작/리셋, miss deal, chop |
| 7 | [Display/GFX](#7-displaygfx) | 12 | GFX 토글, 스트립, 패널, 필드, 티커 |
| 8 | [Game Configuration](#8-game-configuration) | 6 | 게임 타입, variant, blind 구조 |
| 9 | [Tournament](#9-tournament) | 4 | payout, nit game, field |
| 10 | [System/Hardware](#10-systemhardware) | 8 | RFID 리더, 비디오 소스, 덱 등록 |
| 11 | [Server Responses](#11-server-responses-server--client) | 15 | 서버에서 수신하는 응답 |

**총 메시지**: 68개 (중복 Request 타입 공유 포함)

---

## 1. Connection/Session

### 1.1 ConnectToServer
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | (직접 소켓 연결) |
| 설명 | 서버 객체를 받아 연결 설정 후 heartbeat 시작 |

| 필드 | 타입 | 설명 |
|------|------|------|
| server | `client_obj` | 연결 대상 서버 객체 |

**동작**: `netClient = server` -> `Connect()` -> `IsConnected = true` -> `StartHeartbeat()`

**관련 Feature ID**: AT-001

---

### 1.2 SendAuth
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `AuthRequest` |
| 설명 | 서버 인증. 비밀번호 전송 |

| 필드 | 타입 | 설명 |
|------|------|------|
| pwd | `string` | 인증 비밀번호 |

**난독화 setter**: `rRvkpv8rgC9WDRl3ST8` -> Password 필드 설정 추정

**관련 Feature ID**: AT-001

---

### 1.3 SendHeartBeat
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `HeartBeatRequest` |
| 설명 | 주기적 연결 유지 신호 |

| 필드 | 타입 | 설명 |
|------|------|------|
| Id | `int` | heartbeat 시퀀스 ID (명시적 프로퍼티) |

**관련 Feature ID**: AT-001

---

### 1.4 SendReaderStatus
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ReaderStatusRequest` |
| 설명 | RFID 리더 상태 조회 요청 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 1.5 RegisterAndConnectAutomatically
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | (자동 탐색) |
| 설명 | 서버 자동 탐색 후 리스너 등록 및 연결 |

| 필드 | 타입 | 설명 |
|------|------|------|
| listener | `IClientNetworkListener` | 이벤트 수신 리스너 |

**동작**: `ScanForServers()` -> `AvailableServers` 순회 -> `RegisterListener()` -> `ConnectToServer()`

---

## 2. Player Management

### 2.1 SendPlayerAdd
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerAddRequest` |
| 설명 | 좌석에 선수 추가 (이름/ID 입력) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 (0-based index) |
| pwd | `string` | 선수 식별 문자열 (이름 또는 ID) |

**core.cs 호출 패턴**: alpha 패드 텍스트에서 `,` -> `~` 치환하여 전달

---

### 2.2 SendDeletePlayer
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerDeleteRequest` |
| 설명 | 좌석에서 선수 제거 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |

---

### 2.3 SendPlayerLongName
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerLongNameRequest` |
| 설명 | 선수 전체 이름 설정 (방송용 표시명) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| name | `string` | 전체 이름 |

---

### 2.4 SendPlayerCountry
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerCountryRequest` |
| 설명 | 선수 국적 설정 (국기 표시용) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| country | `string` | 국가 코드 |

---

### 2.5 SendCancelPlayerCountry
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerCountryRequest` |
| 설명 | 선수 국적 제거 (country 필드 없이 전송) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |

**참고**: `SendPlayerCountry`와 동일한 `PlayerCountryRequest` 사용, country 필드 미설정

---

### 2.6 SendPlayerSitOut
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerSitOutRequest` |
| 설명 | 선수 sit-out/sit-in 토글 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| sitOut | `bool` | true=sit out, false=sit in (**주의**: 와이어에는 `!sitOut`으로 반전 전송) |

---

### 2.7 SendPlayerSwap
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerSwapRequest` |
| 설명 | 두 선수 좌석 교환 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 원래 좌석 번호 |
| p2 | `int` | 교환 대상 좌석 번호 |

**core.cs 호출**: `SendPlayerSwap(move_pn, to_int(s.Substring(7)))` -- 문자열에서 대상 좌석 파싱

---

### 2.8 UpdatePlayerPicture
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerPictureRequest` |
| 설명 | 선수 사진 업로드 |

| 필드 | 타입 | 설명 |
|------|------|------|
| pn | `int` | 좌석 번호 |
| base64image | `string` | Base64 인코딩된 이미지 데이터 |

---

### 2.9 RemovePlayerPicture
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerPictureRequest` |
| 설명 | 선수 사진 제거 (이미지 데이터 없이 전송) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |

---

### 2.10 UpdatePictureControl
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerPictureRequest` |
| 설명 | 선수 사진 컨트롤 업데이트 (난독화된 고정 문자열 전송) |

| 필드 | 타입 | 설명 |
|------|------|------|
| pn | `int` | 좌석 번호 |
| (image) | `string` | 난독화된 상수 문자열 (컨트롤 명령 추정) |

---

## 3. Betting Actions

### 3.1 SendPlayerBet
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerBetRequest` |
| 설명 | 선수 베팅 액션 (raise/bet) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 (`action_on` 사용) |
| amount | `int` | 베팅 금액 |

**core.cs 호출 패턴**:
- `SendPlayerBet(action_on, num26)` -- 일반 베팅
- `SendPlayerBet(action_on, num20)` -- 금액 입력 후 베팅
- `SendPlayerBet(action_on, player[action_on].stack + player[action_on].bet)` -- 올인

---

### 3.2 SendPlayerCheckCall
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerBetRequest` |
| 설명 | 체크 또는 콜 (**SendPlayerBet과 동일한 Request 타입 공유**) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| biggest_bet_amt | `int` | 현재 최대 베팅 금액 (콜 시 매칭 금액) |

**참고**: `PlayerBetRequest`를 재사용. 서버에서 현재 베팅 상태와 비교하여 check/call 구분

---

### 3.3 SendPlayerFold
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerFoldRequest` |
| 설명 | 선수 폴드 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |

---

### 3.4 SendPlayerBlind
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerBlindRequest` |
| 설명 | 블라인드 포스트 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| amount | `int` | 블라인드 금액 |

---

### 3.5 SendPlayerWin
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerWinRequest` |
| 설명 | 선수 팟 획득 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| amount | `int` | 획득 금액 |

---

## 4. Board/Cards

### 4.1 SendCardEnter
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerCardsRequest` / `BoardCardRequest` / `EditBoardRequest` (분기) |
| 설명 | 카드 입력 (수동). `_num_pad_tag` prefix에 따라 3가지 Request로 분기 |

| 필드 | 타입 | 설명 |
|------|------|------|
| _num_pad_tag | `string` | 입력 대상 태그 (예: `"P,3"` = Player 3, `"B,1"` = Board 1, `"E,2"` = Edit Board 2) |
| _cards_inp_str | `string` | 카드 문자열 (예: `"AhKs"`) |

**분기 로직** (`_num_pad_tag` prefix):
| Prefix | Request Type | 의미 |
|--------|-------------|------|
| `P` (Player) | `PlayerCardsRequest` | 선수 홀카드 설정 |
| `B` (Board) | `BoardCardRequest` | 보드 카드 설정 |
| `E` (Edit) | `EditBoardRequest` | 보드 카드 수정 |

**내부 필드 구조**:
- `_num_pad_tag.Split(',')[1]` -> int로 파싱하여 `Player`/`Board`/`Edit` 인덱스 설정
- `_cards_inp_str` -> Cards 필드에 그대로 전달

---

### 4.2 SendCardClear
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerCardsRequest` |
| 설명 | 선수 카드 클리어 (Cards 필드 없이 전송) |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |

---

### 4.3 SendForceCardScan
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ForceCardScanRequest` |
| 설명 | RFID 리더에 강제 카드 스캔 명령 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 4.4 SendDraw
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `DrawDoneRequest` |
| 설명 | 드로우 포커 계열 드로우 완료 알림 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 (`drawing_player`) |
| type | `int` | 드로우 타입 |

**core.cs에서 확인된 type 값**:
| type | 의미 (추정) |
|:----:|------|
| 0 | 드로우 시작/초기화 |
| 1 | 첫 번째 드로우 |
| 2 | 두 번째 드로우 |
| 3 | 세 번째 드로우 |
| 4 | 네 번째 드로우 |
| 5 | 드로우 취소/리셋 |

---

### 4.5 SendRunItTimes
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `RunItTimesIncRequest` |
| 설명 | "Run It Twice/Thrice" 보드 추가 (횟수 증가) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청. 호출할 때마다 보드 수 +1 |

---

### 4.6 SendRunItTimesClearBoard
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `RunItTimesClearBoardRequest` |
| 설명 | Run It Times 추가 보드 초기화 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 4.7 SendVerifyDeck
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `CardVerifyRequest` |
| 설명 | 덱 검증 시작 (RFID 카드 52장 확인) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (verify) | `bool` | `true` (검증 모드 진입) |

---

## 5. Pot/Chips

### 5.1 SendPlayerStack
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerStackRequest` |
| 설명 | 선수 스택 수동 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| amount | `int` | 스택 금액 |

---

### 5.2 SendTransferChips
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `TransferChipsRequest` |
| 설명 | 칩 이동 (color-up, 리바이 등) |

| 필드 | 타입 | 설명 |
|------|------|------|
| xfer_cumwin | `bool` | true=cumulative win 모드에서 이동, false=일반 |
| str | `string` | 칩 이동 명세 문자열 (콤마 구분 -> 구분자 변환) |

**core.cs 호출**: `SendTransferChips(xfer_cumwin, text.Replace(',', ...))` -- 콤마 구분 문자열

---

### 5.3 SendChop
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ChopRequest` |
| 설명 | 블라인드 촙 (SB/BB만 남았을 때 팟 분할) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

## 6. Hand Control

### 6.1 SendStartHand
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `StartHandRequest` |
| 설명 | 새 핸드 시작 (카드 딜) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 6.2 SendResetHand
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ResetHandRequest` |
| 설명 | 현재 핸드 리셋 (핸드 번호 유지) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (next) | `bool` | `false` (리셋만, 다음 핸드 아님) |

---

### 6.3 SendNextHand
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ResetHandRequest` |
| 설명 | 다음 핸드로 진행 (핸드 번호 증가) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (next) | `bool` | `true` (다음 핸드로 전환) |

**참고**: `SendResetHand`와 동일한 `ResetHandRequest` 사용. `next` 필드로 구분.

---

### 6.4 SendMissDeal
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `MissDealRequest` |
| 설명 | 미스딜 선언 (핸드 무효) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 6.5 SendGameClear
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameClearRequest` |
| 설명 | 게임 상태 전체 초기화 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 6.6 SendGameSaveBack
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameSaveBackRequest` |
| 설명 | 게임 상태 저장 후 복원 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

### 6.7 SendVpipReset
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ResetVpipRequest` |
| 설명 | VPIP (Voluntarily Put $ In Pot) 통계 리셋 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

## 7. Display/GFX

### 7.1 SendGfxEnable
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GfxEnableRequest` |
| 설명 | 방송 그래픽 ON/OFF 토글 |

| 필드 | 타입 | 설명 |
|------|------|------|
| enable | `bool` | true=활성화 (**주의**: 와이어에는 `!enable`로 반전 전송) |

---

### 7.2 SendShowStrip
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ShowStripRequest` |
| 설명 | 하단 스트립 표시/숨김 |

| 필드 | 타입 | 설명 |
|------|------|------|
| visible | `bool` | `true` -> value `1`, `false` -> value `0` |

**내부**: `visible ? 1 : 0` 으로 int 변환하여 전송

---

### 7.3 SendCumwinStrip
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ShowStripRequest` |
| 설명 | Cumulative Win 스트립 표시 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (mode) | `int` | 고정값 `2` (cumwin 모드) |

**참고**: `SendShowStrip`과 동일한 `ShowStripRequest` 사용. mode 값으로 구분:
| mode | 의미 |
|:----:|------|
| 0 | 스트립 OFF |
| 1 | 스트립 ON (스택) |
| 2 | 스트립 ON (cumulative win) |

---

### 7.4 SendPanelValue
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ShowPanelRequest` |
| 설명 | 패널 표시 타입 설정 (칩카운트, VPIP, PFR 등) |

| 필드 | 타입 | 설명 |
|------|------|------|
| value | `int` | `panel_type` enum 값 |

**`panel_type` enum**:
| 값 | 이름 | 의미 |
|:--:|------|------|
| 0 | none | 패널 숨김 |
| 1 | chipcount | 칩 카운트 |
| 2 | vpip | VPIP 통계 |
| 3 | pfr | PFR 통계 |
| 4 | blinds | 블라인드 정보 |
| 5 | agr | Aggression Rate |
| 6 | wtsd | Went to Showdown |
| 7 | position | 포지션 |
| 8 | cum_win | 누적 수익 |
| 9 | payouts | 토너먼트 상금 |
| 10-19 | pl_stat_1~10 | 커스텀 통계 슬롯 |

---

### 7.5 SendDelayedPanelValue
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ShowDelayedPanelRequest` |
| 설명 | 지연 방송용 패널 표시 타입 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| value | `int` | `panel_type` enum 값 (위와 동일) |

---

### 7.6 SendFieldVisibility
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `FieldVisibilityRequest` |
| 설명 | 필드 (참가자 수) 표시/숨김 |

| 필드 | 타입 | 설명 |
|------|------|------|
| visible | `bool` | true=표시, false=숨김 |

---

### 7.7 SendDelayedFieldVisibility
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `DelayedFieldVisibilityRequest` |
| 설명 | 지연 방송용 필드 표시/숨김 |

| 필드 | 타입 | 설명 |
|------|------|------|
| visible | `bool` | true=표시, false=숨김 |

---

### 7.8 SendFieldValue
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `FieldValRequest` |
| 설명 | 잔여/전체 참가자 수 설정 (토너먼트) |

| 필드 | 타입 | 설명 |
|------|------|------|
| remain | `int` | 남은 참가자 수 |
| total | `int` | 전체 참가자 수 |

---

### 7.9 SendTag
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `TagRequest` |
| 설명 | 태그/라벨 텍스트 설정 (방송 표시용) |

| 필드 | 타입 | 설명 |
|------|------|------|
| tag | `string` | 태그 텍스트 (콤마 -> 틸드 치환 후 전송) |

---

### 7.10 SendClearTag
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `TagRequest` |
| 설명 | 태그 클리어 (빈 TagRequest 전송) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | tag 필드 미설정 |

---

### 7.11 SendTicker
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `TickerRequest` |
| 설명 | 하단 티커 텍스트 설정 (스크롤링 텍스트) |

| 필드 | 타입 | 설명 |
|------|------|------|
| ticker | `string` | 티커 텍스트 |

---

### 7.12 SendTickerLoop
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `TickerLoopRequest` |
| 설명 | 티커 반복 재생 ON/OFF |

| 필드 | 타입 | 설명 |
|------|------|------|
| active | `bool` | true=루프 활성화 (**주의**: 와이어에는 `!active`로 반전 전송) |

---

## 8. Game Configuration

### 8.1 SendGameType
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameTypeRequest` |
| 설명 | 게임 타입 변경 (순환) |

| 필드 | 타입 | 설명 |
|------|------|------|
| gametype | `int` | 게임 타입 ID |

**core.cs 호출**: `(game_type < 3) ? (game_type + 1) : 0` -- 0~3 순환

---

### 8.2 SendGameVariant
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameVariantRequest` |
| 설명 | 게임 변형 선택 (Hold'em, Omaha 등) |

| 필드 | 타입 | 설명 |
|------|------|------|
| tag | `string` | 변형 태그 (서버에서 제공한 목록 중 선택) |

**core.cs 호출**: `game_variant_list[num36].tag` -- variant 목록에서 태그 추출

---

### 8.3 SendGameTitle
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameTitleRequest` |
| 설명 | 게임/이벤트 타이틀 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| title | `string` | 게임 타이틀 텍스트 |

---

### 8.4 SendENHMode
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `ENHModeRequest` |
| 설명 | ENH (Enhanced) 모드 ON/OFF |

| 필드 | 타입 | 설명 |
|------|------|------|
| on | `bool` | true=ENH 모드 활성화 |

**core.cs 호출**: `SendENHMode(on: true)`, `SendENHMode(on: false)`

---

### 8.5 WriteGameInfo
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `WriteGameInfoRequest` |
| 설명 | 게임 정보 전체 갱신 (블라인드 구조, 딜러 위치 등 22개 필드) |

| 필드 | 타입 | 설명 |
|------|------|------|
| _smallest_chip | `int` | 최소 칩 단위 |
| _ante | `int` | 앤티 금액 |
| _small | `int` | 스몰 블라인드 |
| _big | `int` | 빅 블라인드 |
| _pl_dealer | `int` | 딜러 좌석 |
| _pl_small | `int` | SB 좌석 |
| _pl_big | `int` | BB 좌석 |
| _action_on | `int` | 현재 액션 좌석 |
| _num_blinds | `int` | 블라인드 수 |
| _third | `int` | 서드 블라인드 금액 |
| _pl_third | `int` | 서드 블라인드 좌석 |
| _ante_t | `int` | 앤티 타입 (`ante_type` enum) |
| _bring_in | `int` | Bring-in 금액 (Stud 계열) |
| _low_limit | `int` | 하한 (Fixed Limit) |
| _high_limit | `int` | 상한 (Fixed Limit) |
| _button_blind | `int` | 버튼 블라인드 금액 |
| _cap | `int` | 베팅 캡 |
| _bomb_pot | `int` | Bomb Pot 금액 |
| _seven_deuce | `int` | 7-2 게임 보너스 |
| _num_boards | `int` | 보드 수 (Run It Twice 등) |
| bet_structure | `int` | 베팅 구조 (`bet_structure` enum: 0=NL, 1=FL, 2=PL) |
| _blind_level | `int` | 블라인드 레벨 |

**`ante_type` enum**:
| 값 | 이름 | 의미 |
|:--:|------|------|
| 0 | std_ante | 표준 앤티 |
| 1 | button_ante | 버튼 앤티 |
| 2 | bb_ante | BB 앤티 |
| 3 | bb_ante_bb1st | BB 앤티 (BB 우선) |
| 4 | live_ante | 라이브 앤티 |
| 5 | tb_ante | TB 앤티 |
| 6 | tb_ante_tb1st | TB 앤티 (TB 우선) |

---

### 8.6 SendGameVariantList
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GameVariantListRequest` |
| 설명 | 서버에서 지원하는 게임 변형 목록 요청 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 |

---

## 9. Tournament

### 9.1 SendPayout
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PayoutRequest` |
| 설명 | 토너먼트 상금 구조 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| rank | `int` | 등수 |
| amt | `int` | 상금 |

---

### 9.2 SendNitGameAmount
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `NitGameRequest` |
| 설명 | Nit Game (보너스 게임) 금액 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| amount | `int` | Nit Game 상금 |

---

### 9.3 SendNitGameCancel
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `NitGameRequest` |
| 설명 | Nit Game 취소 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (amount) | `int` | 고정값 `0` (취소 의미) |

**참고**: `SendNitGameAmount`와 동일한 `NitGameRequest` 사용. amount=0이 취소 신호.

---

### 9.4 SendNitWon
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerNitRequest` |
| 설명 | Nit Game 승리자 알림 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 승리 좌석 번호 (`nit_game_won_player`) |
| (nit) | `int` | 고정값 `3` (`nit_game_enum.safe` = won) |

---

### 9.5 SendPlayerNit
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `PlayerNitRequest` |
| 설명 | 선수 Nit Game 상태 변경 |

| 필드 | 타입 | 설명 |
|------|------|------|
| player | `int` | 좌석 번호 |
| nit | `core.nit_game_enum` | Nit Game 상태 |

**`nit_game_enum`**:
| 값 | 이름 | 의미 |
|:--:|------|------|
| 0 | not_playing | 미참여 |
| 1 | at_risk | 위험 (핸드 잃으면 지불) |
| 2 | won_hand | 핸드 승리 |
| 3 | safe | 안전 (보너스 획득) |

---

## 10. System/Hardware

### 10.1 SendRegisterDeck
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `RegisterDeckRequest` |
| 설명 | RFID 덱 등록 모드 시작 (52장 순차 스캔) |

| 필드 | 타입 | 설명 |
|------|------|------|
| (register) | `bool` | `true` (등록 모드 진입) |

---

### 10.2 SendRegisterDeckCancel
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `RegisterDeckRequest` |
| 설명 | 덱 등록 취소 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (register) | `bool` | `false` (등록 모드 종료) |

**참고**: `SendRegisterDeck`과 동일한 Request. bool 값으로 구분.

---

### 10.3 SendVerifyExit
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `CardVerifyRequest` |
| 설명 | 카드 검증 모드 종료 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (verify) | `bool` | `false` (검증 모드 종료) |

---

### 10.4 SendVerifyReset
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `CardVerifyRequest` |
| 설명 | 카드 검증 리셋 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (verify) | `bool` | `true` |

---

### 10.5 SendVerifyStart
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `CardVerifyRequest` |
| 설명 | 카드 검증 시작 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (verify) | `bool` | `true` |

**참고**: `SendVerifyDeck`, `SendVerifyReset`, `SendVerifyStart`는 모두 `CardVerifyRequest` 사용. 서버 측에서 상태 머신으로 구분 추정.

---

### 10.6 SendVideoSources
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `SetVideoSourcesRequest` |
| 설명 | 비디오 소스 카메라 번호 설정 |

| 필드 | 타입 | 설명 |
|------|------|------|
| cam_num | `int` | 카메라 번호 (생성자에 2회 전달: `new SetVideoSourcesRequest(cam_num, cam_num)`) |

---

### 10.7 SendSourceMode
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `SetSourceModeRequest` |
| 설명 | 소스 모드 ON/OFF |

| 필드 | 타입 | 설명 |
|------|------|------|
| on | `bool` | true=소스 모드 활성화 |

---

### 10.8 SendGetSourceMode / SendGetVidSources
| 항목 | 값 |
|------|-----|
| Direction | Client -> Server |
| Request Type | `GetSourceModeRequest` / `GetVideoSourcesRequest` |
| 설명 | 현재 소스 모드/비디오 소스 조회 |

| 필드 | 타입 | 설명 |
|------|------|------|
| (없음) | - | 파라미터 없는 요청 (각각 별도 Request) |

---

## 11. Server Responses (Server -> Client)

`CoreNetworkListener`가 `IClientNetworkListener` 인터페이스를 구현하여 서버 응답을 수신.
모든 핸들러는 `core.*` 메서드로 위임.

### Response 메시지 목록

| # | 핸들러 | Response Type | 설명 |
|:-:|--------|---------------|------|
| 1 | `OnConnected` | `ConnectResponse` | 서버 연결 성공 |
| 2 | `OnDisconnected` | `DisconnectResponse` | 서버 연결 해제 |
| 3 | `NetworkQualityChanged` | `NetworkQuality` | 네트워크 품질 변경 (지연, 패킷 손실) |
| 4 | `OnAuthReceived` | `AuthResponse` | 인증 결과 |
| 5 | `OnReaderStatusReceived` | `ReaderStatusResponse` | RFID 리더 상태 |
| 6 | `OnHeartBeatReceived` | `HeartBeatResponse` | Heartbeat 응답 |
| 7 | `OnDelayedGameInfoReceived` | `DelayedGameInfoResponse` | 지연 방송용 게임 정보 |
| 8 | `OnGameInfoReceived` | `GameInfoResponse` | 실시간 게임 정보 |
| 9 | `OnMediaListReceived` | `MediaListResponse` | 미디어 파일 목록 (사운드/이미지) |
| 10 | `OnCountryListReceived` | `CountryListResponse` | 국가 목록 (국기 이미지) |
| 11 | `OnPlayerPictureReceived` | `PlayerPictureResponse` | 선수 사진 데이터 |
| 12 | `OnGameVariantListReceived` | `GameVariantListResponse` | 게임 변형 목록 |
| 13 | `OnPlayerInfoReceived` | `PlayerInfoResponse` | 실시간 선수 정보 |
| 14 | `OnDelayedPlayerInfoReceived` | `DelayedPlayerInfoResponse` | 지연 방송용 선수 정보 |
| 15 | `OnVideoSourcesReceived` | `VideoSourcesResponse` | 비디오 소스 목록 |
| 16 | `OnSourceModeReceived` | `SourceModeResponse` | 소스 모드 상태 |

---

## 추가 조회 메서드

`Send` prefix 없이 존재하는 조회 메서드.

| # | 메서드 | Request Type | 설명 |
|:-:|--------|-------------|------|
| 1 | `GetCountryList()` | `CountryListRequest` | 국가 목록 요청 |
| 2 | `SendGameInfo()` | `GameInfoRequest` | 게임 정보 요청 |
| 3 | `SendPlayerInfo()` | `PlayerInfoRequest` | 선수 정보 요청 |
| 4 | `SendDelayedGameInfo()` | `DelayedGameInfoRequest` | 지연 게임 정보 요청 |
| 5 | `SendDelayedPlayerInfo()` | `DelayedPlayerInfoRequest` | 지연 선수 정보 요청 |
| 6 | `SendMediaList()` | `MediaListRequest` | 미디어 목록 요청 |

---

## 프로토콜 특성 요약

### Request Type 재사용 패턴

| Request Type | 사용하는 메서드들 | 구분 필드 |
|-------------|------------------|----------|
| `ResetHandRequest` | SendResetHand, SendNextHand | `next` (bool) |
| `TagRequest` | SendTag, SendClearTag | tag 유무 |
| `RegisterDeckRequest` | SendRegisterDeck, SendRegisterDeckCancel | `register` (bool) |
| `CardVerifyRequest` | SendVerifyExit, SendVerifyDeck, SendVerifyReset, SendVerifyStart | `verify` (bool) + 상태 머신 |
| `PlayerBetRequest` | SendPlayerBet, SendPlayerCheckCall | amount 값으로 서버 측 구분 |
| `ShowStripRequest` | SendShowStrip, SendCumwinStrip | mode (0/1/2) |
| `NitGameRequest` | SendNitGameAmount, SendNitGameCancel | amount (0=취소) |
| `PlayerNitRequest` | SendNitWon, SendPlayerNit | nit enum 값 |
| `PlayerPictureRequest` | UpdatePlayerPicture, RemovePlayerPicture, UpdatePictureControl | image 유무 |
| `PlayerCountryRequest` | SendPlayerCountry, SendCancelPlayerCountry | country 유무 |
| `PlayerCardsRequest` | SendCardEnter(P분기), SendCardClear | cards 유무 |

### 반전 전송 패턴

일부 bool 필드는 **반전(`!value`)되어 와이어에 전송**됨:

| 메서드 | 파라미터 | 실제 전송 값 |
|--------|---------|-------------|
| `SendGfxEnable(enable)` | `enable` | `!enable` |
| `SendTickerLoop(active)` | `active` | `!active` |
| `SendPlayerSitOut(player, sitOut)` | `sitOut` | `!sitOut` |

### 네트워크 전송 패턴

모든 Send 메서드는 동일한 패턴:
```
netClient.Send( new XxxRequest { field = value, ... } )
```

난독화된 호출: `aOraxwBy1XAbUKfu9RY.gpKTp0ysW(netClient, (IRemoteRequest)val, ...)` = `netClient.Send(request)`

### Dispatch 메서드 (Response 라우팅)

`Dispatch(sender, response)` 메서드가 서버 응답을 Response Type 문자열로 라우팅:
- Response의 타입명을 문자열로 추출
- 첫 글자(prefix)로 1차 분기 (`P`, `G`, `B` 등)
- 문자열 비교로 정확한 핸들러 매칭
- 해당 이벤트 핸들러 호출 (`OnXxxReceived`)

---

## 변경 이력

---
**Version**: 1.0.0 | **Updated**: 2026-02-13

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-13 | 초기 생성. ClientNetworkService.cs, CoreNetworkListener.cs, core.cs, comm.cs 분석 |
