# PokerGFX Clone PRD - Wave 3: 네트워크, 외부통합, 데이터 모델, 서비스 아키텍처

**Version**: 1.0.0
**Date**: 2026-02-13
**Scope**: 섹션 9-12 (네트워크 프로토콜, 외부 서비스, 데이터 모델, Service Architecture)

---

## 9. 네트워크 프로토콜 (net_conn.dll)

### 9.1 프로토콜 스택

원본 시스템은 4-Layer 프로토콜 스택으로 구성된다. Clone에서는 이 구조를 유지하되, 전송 계층을 현대화한다.

![4-Layer Protocol Stack](../images/mockups/protocol-stack.png)

| Layer | 원본 구현 | Clone 구현 |
|:-----:|----------|-----------|
| **4 - Application** | IRemoteRequest/IRemoteResponse 모델 (113+ 명령) | gRPC message 타입 + 레거시 호환 어댑터 |
| **3 - Serialization** | JSON (Newtonsoft.Json) + CSV 레거시 공존 | Protocol Buffers (주요) + JSON 호환 |
| **2 - Security** | AES-256 Rijndael (PBKDF1, 하드코딩 키) | AES-256-GCM (Argon2id 키 유도, 외부 설정) |
| **1 - Transport** | Raw TCP (SOH 0x01 구분자) + UDP Discovery | gRPC over HTTP/2 (주요) + 레거시 TCP 어댑터 |

### 9.2 직렬화 이중성

원본은 프로토콜 마이그레이션 과도기의 흔적으로 두 가지 직렬화 방식이 공존한다.

| 방식 | 버전 | 구현 | Clone 전략 |
|------|------|------|-----------|
| **JSON** | v2.0+ | `Newtonsoft.Json.JsonConvert.SerializeObject()` | Protocol Buffers로 전환 |
| **CSV** | v1.x 레거시 | `ToString()` + `string[] cmd` 생성자 | 제거 (JSON 전용 유지 후 protobuf 전환) |

대부분 Model 클래스에 CSV/JSON 양쪽 직렬화 코드가 공존하며, Clone에서는 CSV 레거시를 완전히 제거하고 JSON 단일 포맷 → 최종적으로 protobuf로 전환한다.

### 9.3 서버 발견 프로토콜

#### 원본 UDP Discovery

1. Client → Broadcast UDP (port 9000): `_id_tx` 문자열 전송
2. Server → Unicast UDP Response: `_id_tx` 문자열 응답 (수신 소스 포트 9002)
3. Client → TCP Connect (port 9001): AES 암호화 세션 수립
4. Server → 즉시 `ConnectResponse(License)` + `IdtxResponse(IdTx)` 전송

**서버 측 상세**:
- `SERVER_UDP_PORT = 9000`으로 바인딩
- 10,000바이트 수신 버퍼 (`remote_udp_buff`)
- 수신된 UDP 패킷이 `_id_rx` 문자열을 포함하면 응답 전송

**클라이언트 측 상세**:
- `udp_timer`: 1초 간격 브로드캐스트 반복
- ID 문자열에 쉼표(`,`) 포함 시 서브스트링으로 서버 ID 추출
- `_promiscuous` 모드: 발견 즉시 자동 TCP 연결

**Discovery 시퀀스**:
```
Client                                    Server
  |                                         |
  |---- UDP Broadcast (_id_tx) ----------->| :9000
  |                                         |
  |<---- UDP Response (_id_tx) ------------|
  |                                         |
  |---- TCP Connect ---------------------->| :9001
  |                                         |
  |<---- ConnectResponse(License) ---------|  <- 즉시
  |<---- IdtxResponse(id_tx) -------------|  <- 즉시
  |                                         |
  |---- IdtxRequest(id_tx) -------------->|  <- ID 교환
  |---- ConnectRequest ------------------>|  <- 연결 완료 신호
```

#### [Clone] 재구현 전략

UDP Discovery를 mDNS/DNS-SD 기반 현대적 서비스 발견으로 전환한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| 프로토콜 | UDP Broadcast (port 9000) | mDNS/DNS-SD (`_pokergfx._tcp.local`) |
| 발견 주기 | 1초 간격 브로드캐스트 | mDNS 표준 타이밍 (수백ms~수초) |
| 레거시 호환 | - | UDP Discovery 어댑터 병행 운용 옵션 |
| 구현 | 커스텀 소켓 코드 | `MdnsService` (Zeroconf 라이브러리) |

### 9.4 암호화 상세

#### 원본 AES-256 구현

| 속성 | 값 |
|------|-----|
| **알고리즘** | Rijndael (AES-256) |
| **모드** | CBC (기본값, 명시적 설정 없음) |
| **키 유도** | PasswordDeriveBytes (PBKDF1) |
| **Password** | `"45389rgjkonlgfds90439r043rtjfewp9042390j4f"` |
| **Salt** | `"dsafgfdagtds4389tytgh"` (UTF-8 → bytes) |
| **IV** | `"4390fjrfvfji9043"` (UTF-8 → 16 bytes) |
| **패딩** | 암호화: PKCS7, 복호화: None (수동 패딩 제거) |
| **Wire Format** | `AES(JSON_bytes) → Base64 + SOH(0x01)` |
| **커스텀 키** | `enc.init(pwd)`로 배포별 키 설정 가능 |
| **스레드 안전** | `Monitor.Enter/Exit` (lock)으로 동기화 |

**키 유도 과정**:
```csharp
// 원본 키 유도 로직
static void init(string pwd) {
    byte[] saltBytes = Encoding.ASCII.GetBytes("dsafgfdagtds4389tytgh");
    var pdb = new PasswordDeriveBytes(pwd, saltBytes);
    _key = pdb.GetBytes(32);  // 256-bit key
}
```

**암호화 흐름**:
1. 입력 문자열 → UTF-8 바이트 변환
2. AES-256-CBC 암호화 (PKCS7 패딩)
3. 결과 → Base64 인코딩
4. Base64 문자열 + SOH(0x01) 구분자로 전송

**복호화 흐름**:
1. SOH 구분자까지 누적된 Base64 문자열 수신
2. Base64 → 바이트 디코딩
3. AES-256-CBC 복호화 (패딩 None, 수동 NULL 종료자 제거)
4. UTF-8 문자열로 변환

#### [Clone] 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| 알고리즘 | AES-256-CBC | AES-256-GCM (AEAD) |
| 키 유도 | PBKDF1 (deprecated) | Argon2id |
| IV 관리 | 고정 IV (모든 메시지 동일) | 메시지별 랜덤 nonce |
| HMAC | 없음 (Padding Oracle 취약) | GCM 내장 인증 태그 |
| 키 자료 관리 | 소스 코드 하드코딩 | 외부 설정 파일 (SecretManager/환경변수) |
| 레거시 호환 | - | 원본 AES+PBKDF1 어댑터 유지 (기존 클라이언트 호환) |

**Password, Salt, IV 값은 레거시 호환 모드에서 그대로 보존하되, 새 프로토콜에서는 외부 설정 기반으로 관리한다.**

### 9.5 RemoteRegistry (Command Routing)

#### 원본 구현

- Singleton 인스턴스 (`Lazy<RemoteRegistry>`: Thread-safe lazy initialization)
- 현재 AppDomain의 모든 어셈블리를 Reflection으로 스캔
- `IRemoteRequest`/`IRemoteResponse` 인터페이스 구현 타입 자동 등록
- 수신 JSON의 `Command` 필드로 역직렬화 타입 결정
- 중복 키 시 예외 발생

**역직렬화 프로세스**:
```
JSON string
  -> JObject.Parse()
  -> JObject["Command"] -> command string
  -> RemoteRegistry.TryGetRequestType(command, out Type)
  -> JsonConvert.DeserializeObject(json, type)
  -> cast to IRemoteRequest
```

#### [Clone] 재구현 전략

Reflection 기반 런타임 스캔을 Source Generator 기반 컴파일 타임 Command Routing으로 전환한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| 등록 방식 | Reflection + `Activator.CreateInstance` | Source Generator `[CommandRoute("AUTH")]` 어트리뷰트 |
| 타이밍 | 런타임 (AppDomain 스캔) | 컴파일 타임 (코드 생성) |
| 성능 | 초기 로딩 시 모든 타입 인스턴스 생성 | 딕셔너리 리터럴 (zero allocation) |
| 타입 안전 | 런타임 예외 | 컴파일 타임 에러 |

### 9.6 프로토콜 명령어 (113+ 카테고리별)

#### 9.6.1 연결 관리 (Connection) - 9개

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `CONNECT` | Req/Resp | License(ulong) | TCP 연결 수립, 서버 라이선스 전달 |
| `DISCONNECT` | Req/Resp | - | 연결 해제 |
| `AUTH` | Req/Resp | Password, Version | 패스워드 인증 + 버전 교환 |
| `KEEPALIVE` | Req | - | 연결 유지 (클라이언트 → 서버, 3초 간격) |
| `IDTX` | Req/Resp | IdTx(string) | 상대방 식별자 교환 |
| `HEARTBEAT` | Req/Resp | - | 양방향 생존 확인 |
| `IDUP` | Resp | - | ID 업데이트 알림 |

**Keepalive 매커니즘**:

| 구분 | 서버 (server_obj) | 클라이언트 (client_obj) |
|------|:--:|:--:|
| 간격 | 10초 (KEEPALIVE_INTERVAL) | 3초 |
| 동작 | 타이머 만료 시 `close()` | 타이머마다 `KeepAliveRequest` 전송 |
| 리셋 | 데이터 수신 시 타이머 재생성 | N/A |
| 실패 | 연결 종료 → `nc_closed` 이벤트 | `_persist`면 자동 재연결 |

#### 9.6.2 게임 상태 (Game State) - 10+개

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `GAME_STATE` | Resp | GameType, InitialSync | 게임 타입 변경 + 초기 동기화 |
| `GAME_INFO` | Req/Resp | 75+ 필드 | 테이블 전체 상태 |
| `GAME_TYPE` | Req | GameType | 게임 유형 변경 요청 |
| `GAME_VARIANT` | Req | Variant | 게임 변형 선택 |
| `GAME_VARIANT_LIST` | Req/Resp | - | 지원 변형 목록 조회 |
| `GAME_CLEAR` | Req | - | 테이블 리셋 |
| `GAME_TITLE` | Req | Title | 게임 제목 설정 |
| `GAME_SAVE_BACK` | Req | - | 게임 상태 저장 |
| `NIT_GAME` | Req | Amount | Nit 금액 설정 |

**GameInfoResponse (75+ 필드)** 주요 카테고리:

| 카테고리 | 필드 | 타입 |
|---------|------|------|
| **블라인드** | Ante, Small, Big, Third, ButtonBlind, BringIn, BlindLevel, NumBlinds | int |
| **좌석 위치** | PlDealer, PlSmall, PlBig, PlThird, ActionOn, NumSeats, NumActivePlayers | int |
| **베팅** | BiggestBet, SmallestChip, BetStructure, Cap, MinRaiseAmt, PredictiveBet | int/bool |
| **게임 타입** | GameClass, GameType, GameVariant, GameTitle | int/string |
| **보드** | OldBoardCards, CardsOnTable, NumBoards, CardsPerPlayer, ExtraCardsPerPlayer | string/bool/int |
| **상태** | HandInProgress, EnhMode, GfxEnabled, Streaming, Recording, ProVersion, NextHandOk | bool |
| **디스플레이** | ShowPanel, StripDisplay, TickerVisible, FieldVisible, PlayerPicW, PlayerPicH | int/bool |
| **특수** | RunItTimes, RunItTimesRemaining, BombPot, SevenDeude, CanChop, IsChopped | int/bool |
| **드로우** | DrawCompleted, DrawingPlayer, StudDrawInProgress, StudCommunityCard, AnteType | int/bool |

#### 9.6.3 플레이어 관리 (Player) - 21+개

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `PLAYER_INFO` | Req/Resp | Player, Name, Stack, Stats (20 필드) | 플레이어 전체 정보 |
| `PLAYER_CARDS` | Req/Resp | Player, Cards(string) | 홀카드 정보 |
| `PLAYER_BET` | Req/Resp | Player, Amount | 베팅 금액 |
| `PLAYER_BLIND` | Req | Player, Amount | 블라인드 설정 |
| `PLAYER_ADD` | Req | Seat, Name | 신규 플레이어 착석 |
| `PLAYER_DELETE` | Req | Seat | 플레이어 퇴장 |
| `PLAYER_COUNTRY` | Req | Player, Country | 국기 설정 |
| `PLAYER_DEAD_BET` | Req | Player, Amount | 데드 베팅 |
| `PLAYER_PICTURE` | Resp | Player, Picture | 프로필 사진 |
| `DELAYED_PLAYER_INFO` | Req/Resp | - | 지연 방송용 플레이어 정보 |

**PlayerInfoResponse (20 필드)**:

| 필드 | 타입 | 설명 |
|------|------|------|
| Player | int | 좌석 번호 (0-9) |
| Name | string | 표시 이름 |
| LongName | string | 풀 네임 |
| HasCards | bool | 카드 보유 여부 |
| Folded | bool | 폴드 상태 |
| AllIn | bool | 올인 상태 |
| SitOut | bool | 자리비움 |
| Bet | int | 현재 베팅액 |
| DeadBet | int | 데드 베팅 |
| Stack | int | 칩 스택 |
| NitGame | int | Nit 금액 |
| HasPic | bool | 프로필 사진 여부 |
| HasExtraCards | bool | 추가 카드 여부 |
| Country | string | 국가 코드 |
| Vpip | int | VPIP |
| Pfr | int | PFR |
| Agr | int | AGR |
| Wtsd | int | WTSD |
| CumWin | int | 누적 수익 |

#### 9.6.4 카드/보드 (Cards & Board) - 6개

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `BOARD_CARD` | Req/Resp | Cards | 커뮤니티 카드 |
| `CARD_VERIFY` | Req | - | RFID 카드 검증 요청 |
| `FORCE_CARD_SCAN` | Req | - | 강제 카드 스캔 |
| `DRAW_DONE` | Req/Resp | - | 드로우 라운드 완료 |
| `EDIT_BOARD` | Req/Resp | - | 보드 카드 편집 |

#### 9.6.5 디스플레이/UI (Display) - 13개

| 명령 | 방향 | 설명 |
|------|------|------|
| `FIELD_VISIBILITY` | Req/Resp | 필드 표시/숨김 제어 |
| `FIELD_VAL` | Req/Resp | 필드 값 설정 |
| `GFX_ENABLE` | Req/Resp | 그래픽 오버레이 활성화/비활성화 |
| `ENH_MODE` | Req/Resp | Enhanced 모드 (분석 표시 강화) |
| `SHOW_PANEL` | Req | 패널 표시 제어 |
| `STRIP_DISPLAY` | Req | 하단 스트립 표시 |
| `BOARD_LOGO` | Req/Resp | 보드 로고 이미지 |
| `PANEL_LOGO` | Req/Resp | 패널 로고 이미지 |
| `ACTION_CLOCK` | Req | 액션 타이머 제어 |
| `DELAYED_FIELD_VISIBILITY` | Req/Resp | 지연 방송 필드 제어 |
| `DELAYED_GAME_INFO` | Req/Resp | 지연 방송 게임 정보 |

#### 9.6.6 미디어/카메라 (Media) - 9개

| 명령 | 방향 | 설명 |
|------|------|------|
| `MEDIA_LIST` | Req/Resp | 미디어 파일 목록 |
| `MEDIA_PLAY` | Req | 미디어 재생 |
| `MEDIA_LOOP` | Req | 미디어 루프 재생 |
| `CAM` | Req | 카메라 전환 |
| `PIP` | Req | Picture-in-Picture 제어 |
| `CAP` | Req/Resp | 캡처 설정 |
| `GET_VIDEO_SOURCES` | Req | 비디오 소스 목록 요청 |
| `VIDEO_SOURCES` | Resp | 비디오 소스 응답 |
| `SOURCE_MODE` | Resp | 소스 모드 응답 |

#### 9.6.7 RFID/리더 - 1개

| 명령 | 방향 | 설명 |
|------|------|------|
| `READER_STATUS` | Resp | RFID 리더 상태 |

#### 9.6.8 베팅/재무 (Betting & Financial) - 5개

| 명령 | 방향 | 설명 |
|------|------|------|
| `PAYOUT` | Req | 팟 지급 |
| `MISS_DEAL` | Req | 미스딜 처리 |
| `CHOP` | Resp | 팟 분할 |
| `FORCE_HEADS_UP` | Req/Resp | 헤즈업 강제 전환 |
| `FORCE_HEADS_UP_DELAYED` | Req/Resp | 지연 방송 헤즈업 |

#### 9.6.9 데이터 전송 (Data Transfer) - 4개

| 명령 | 방향 | 설명 |
|------|------|------|
| `SKIN_CHUNK` | Req/Resp | 스킨 파일 청크 전송 |
| `COMM_DL` | Req/Resp | 커뮤니케이션 다운로드 |
| `AT_DL` | Req/Resp | 안테나 테이블 다운로드 |
| `VTO` | Req/Resp | 가상 테이블 오브젝트 |

#### 9.6.10 기록/로그 (History & Logging) - 4개

| 명령 | 방향 | 설명 |
|------|------|------|
| `HAND_HISTORY` | Req/Resp | 핸드 히스토리 |
| `HAND_LOG` | Resp | 핸드 로그 |
| `GAME_LOG` | Resp | 게임 로그 |
| `COUNTRY_LIST` | Req/Resp | 국가 목록 |

### 9.7 TCP Wire Format 상세

#### 메시지 프레이밍

```
TCP 스트림 바이트 레이아웃:
[Base64(AES(JSON_1))][0x01][Base64(AES(JSON_2))][0x01][Base64(AES(...))]
                      ^SOH                       ^SOH
```

**수신 프로세스** (server_obj):
1. `NetworkStream.BeginRead`로 비동기 수신
2. 수신된 바이트 배열을 순회
3. `0x01` (SOH, Start of Heading) 만나면 `StringBuilder` 내용을 완성된 메시지로 처리
4. 그 외 바이트는 `StringBuilder`에 `Append`
5. 완성된 메시지: `enc.decrypt()` → `deserializeIRemoteRequest()` → `process_rem_str()`
6. Keepalive 타이머 리셋 (10초)
7. 0바이트 수신 시 연결 종료

**전송 프로세스** (server_obj):
1. `IRemoteResponse` → `JsonConvert.SerializeObject()` 직렬화
2. JSON 문자열 → `enc.encrypt()` AES 암호화 (결과는 Base64)
3. 암호화 문자열 + `0x01` 구분자 결합
4. `Encoding.ASCII.GetBytes()` 변환
5. `NetworkStream.BeginWrite()` 비동기 전송

#### CSV Wire Format 규칙 (레거시)

형식: `COMMAND,field1,field2,...\n`

| 규칙 | 상세 |
|------|------|
| 구분자 | 쉼표 (`,`) |
| 이스케이프 | `,` → `~` |
| Boolean | `"1"` / `"0"` |
| 압축 | GZip suffix (대용량 메시지) |

### 9.8 IClientNetworkListener 콜백 (16개)

클라이언트 애플리케이션이 서버 이벤트를 수신하기 위해 구현해야 하는 인터페이스:

| 콜백 | 트리거 |
|------|--------|
| `NetworkQualityChanged(NetworkQuality)` | 연결 품질 변경 (Good, Fair, Poor) |
| `OnConnected(client_obj, ConnectResponse)` | TCP 연결 수립 |
| `OnDisconnected(DisconnectResponse)` | 연결 해제 |
| `OnAuthReceived(AuthResponse)` | 인증 결과 수신 |
| `OnReaderStatusReceived(ReaderStatusResponse)` | RFID 리더 상태 |
| `OnHeartBeatReceived(HeartBeatResponse)` | Heartbeat 수신 |
| `OnDelayedGameInfoReceived(DelayedGameInfoResponse)` | 지연 게임 정보 |
| `OnGameInfoReceived(GameInfoResponse)` | 실시간 게임 정보 |
| `OnMediaListReceived(MediaListResponse)` | 미디어 목록 |
| `OnCountryListReceived(CountryListResponse)` | 국가 목록 |
| `OnPlayerPictureReceived(PlayerPictureResponse)` | 플레이어 사진 |
| `OnGameVariantListReceived(GameVariantListResponse)` | 게임 변형 목록 |
| `OnPlayerInfoReceived(PlayerInfoResponse)` | 플레이어 정보 |
| `OnDelayedPlayerInfoReceived(DelayedPlayerInfoResponse)` | 지연 플레이어 정보 |
| `OnVideoSourcesReceived(VideoSourcesResponse)` | 비디오 소스 |
| `OnSourceModeReceived(SourceModeResponse)` | 소스 모드 |

### 9.9 Master-Slave Architecture

![Master-Slave Network Topology](../images/mockups/master-slave.png)

#### 동기화 항목

| 항목 | 방향 | 설명 |
|------|------|------|
| 게임 상태 | Master → Slave | 실시간 GameInfo/PlayerInfo 스트리밍 |
| 핸드 로그 | Master → Slave | 핸드 히스토리 전파 |
| 스킨 파일 (.vpt) | Master → Slave | 청크 단위 다운로드 (`SKIN_CHUNK`) |
| 그래픽 설정 | Master → Slave | ConfigurationPreset 동기화 |
| ATEM 스위처 주소 | Master → Slave | `_masterExtSwitcherAddress` |
| Twitch 채널 | Master → Slave | `_masterTwitchChannel` |

#### slave 클래스 (34+ 필드)

| 카테고리 | 필드 | 설명 |
|---------|------|------|
| **연결 상태** | `_connected`, `_authenticated`, `_synced`, `_passwordSent` | 연결 상태 머신 |
| **마스터 설정** | `_masterExtSwitcherAddress`, `_masterTwitchChannel` | 마스터 서버 설정 |
| **스킨 관리** | `_skinPosition`, `downloadSkinCrc`, `downloadSkinList`, `_slaveSkinProgress` | 스킨 동기화 |
| **스트리밍** | `_isMasterStreaming`, `_isAnySlaveStreaming` | 스트리밍 상태 |
| **캐싱** | `_cachedIsAnySlaveStreaming`, `_lastSlaveStreamingCheck`, `_slaveStreamingCacheDuration` | 성능 캐시 |
| **캐싱(연결)** | `_cachedIsConnected`, `_cachedIsAuthenticated`, `_lastConnectionStatusCheck`, `_connectionStatusCacheDuration` | 연결 상태 캐시 |
| **쓰로틀링** | `_lastGameStateUpdate`, `_minUpdateInterval` | 게임 상태 업데이트 주기 |
| **쓰로틀링(로그)** | `_lastHandLogUpdate`, `_lastGameLogUpdate`, `_minLogUpdateInterval` | 로그 업데이트 주기 |
| **쓰로틀링(GFX)** | `_lastGraphicsRefresh`, `_graphicsRefreshThrottle` | 그래픽 갱신 주기 |

#### [Clone] Master-Slave 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| 전송 | 커스텀 TCP + AES | gRPC bidirectional streaming |
| 동기화 | 전체 GameInfo 전송 | Delta sync (변경분만 전송) |
| 스킨 전송 | 청크 분할 + 커스텀 프로토콜 | gRPC server streaming + 해시 기반 캐시 |
| 쓰로틀링 | 수동 타이머 + 캐시 | `System.Threading.RateLimiting` |

### 9.10 일반적인 세션 흐름

```
Client (Remote)                           Server (VPT)
     |                                        |
     |---- UDP Broadcast (id_tx) ----------->| :9000
     |<---- UDP Response (id_tx) ------------|
     |                                        |
     |==== TCP Connect =====================>| :9001
     |                                        |
     |<---- ConnectResponse(License=0x...)---|  <- 즉시
     |<---- IdtxResponse(IdTx="...") --------|  <- 즉시
     |                                        |
     |---- IdtxRequest(IdTx="...") --------->|  <- ID 교환
     |---- ConnectRequest ------------------>|  <- 연결 완료 신호
     |                                        |
     |---- AuthRequest(Password,Version) --->|  <- 인증
     |<---- AuthResponse --------------------|
     |                                        |
     |<---- GameStateResponse(HOLDEM,true) --|  <- 초기 동기화
     |<---- GameInfoResponse(75+ fields) ----|  <- 전체 상태
     |<---- PlayerInfoResponse x N ----------|  <- 각 플레이어
     |<---- PlayerCardsResponse x N ---------|  <- 각 홀카드
     |                                        |
     | - - - KeepAlive (3초 간격) - - - - - >|
     |                                        |
     |<---- [실시간 업데이트 스트림] ---------|
     |      GameInfoResponse (변경시)         |
     |      PlayerInfoResponse (변경시)       |
     |      BoardCardResponse (보드 변경)     |
     |      PlayerCardsResponse (카드 공개)   |
     |                                        |
     |---- DisconnectRequest --------------->|
     |<---- DisconnectResponse ---------------|
     |==== TCP Close ========================|
```

### 9.11 [Clone] 네트워크 프로토콜 종합 재구현 전략

| 구성요소 | 원본 | Clone | 비고 |
|---------|------|-------|------|
| 주요 프로토콜 | 커스텀 TCP + SOH | gRPC over HTTP/2 | 양방향 스트리밍 지원 |
| 레거시 호환 | - | 원본 AES+TCP 프로토콜 어댑터 | 기존 클라이언트 호환 |
| 키 유도 | PBKDF1 | Argon2id | 보안 강화 |
| 명령 라우팅 | Reflection RemoteRegistry | Source Generator 기반 | 컴파일 타임 안전 |
| CSV 레거시 | 공존 | 제거 (JSON 전용 → protobuf) | 기술 부채 해소 |
| 서버 발견 | UDP Broadcast | mDNS/DNS-SD + 레거시 호환 모드 | 현대적 대안 |
| AES 파라미터 | 하드코딩 (Password, Salt, IV) | 설정 기반 외부 관리 | 하드코딩 제거 |
| 메시지 무결성 | 없음 | AES-GCM 인증 태그 | Padding Oracle 방어 |

---

## 10. 외부 서비스 통합

### 10.1 ATEM Switcher

#### 원본 구현

- COM Interop (Blackmagic Desktop Video SDK)
- 프로그램/프리뷰 전환, Mix Effect 블록 제어
- 입력 모니터링, 카메라 자동 전환 (게임 이벤트 연동)

**state_enum**:

| 값 | 상태 | 설명 |
|:--:|------|------|
| 0 | NotInstalled | SDK 미설치 |
| 1 | Disconnected | 연결 해제 |
| 2 | Connected | 연결됨 |
| 3 | Paused | 일시 중지 |
| 4 | Reconnect | 재연결 중 |
| 5 | Terminate | 종료 |

#### [Clone] 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| SDK | COM Interop (레거시) | Blackmagic SDK .NET 8 호환 래퍼 |
| 패턴 | 정적 클래스 직접 호출 | ATEM Service (DI 주입) |
| 상태 관리 | enum + 수동 전환 | State Machine 패턴 (Stateless 라이브러리) |

### 10.2 비디오 캡처 장치

| 타입 | 설명 | 원본 구현 |
|------|------|----------|
| Decklink | Blackmagic Design 캡처 카드 (SDI/HDMI) | DirectShow COM Interop |
| USB | USB 웹캠 | DirectShow |
| NDI | NewTek NDI 네트워크 소스 | NDI SDK |
| URL | RTMP/RTSP/HLS 스트림 | 네트워크 수신 |

`video_capture_device_type`: `unknown`, `dshow`, `NDI`, `BMD`, `network`

### 10.3 API Endpoints (9개)

| 서비스 | URL | 용도 |
|--------|-----|------|
| **PokerGFX API** | `https://api.pokergfx.io/api/v1/` | 버전 체크, 다운로드, 텔레메트리 |
| **Analytics Batch** | `https://api.pokergfx.io/api/v1/analytics/batch` | 텔레메트리 배치 전송 |
| **WCF Service** | `http://videopokertable.net/wcf.svc` | 라이선스 RPC |
| **Download** | `https://videopokertable.net/Download.aspx` | 업데이트 다운로드 |
| **Login** | `https://www.pokergfx.io` | 로그인/인증 |
| **Twitch OAuth** | `https://id.twitch.tv/oauth2/authorize` | Twitch 인증 |
| **Twitch API** | `https://api.twitch.tv/kraken/channels/` | 채널 정보 |
| **Twitch Validate** | `https://id.twitch.tv/oauth2/validate` | 토큰 검증 |
| **AWS S3** | `captures.pokergfx.io` | 스크린샷 업로드 |
| **Bugsnag** | `https://notify.bugsnag.com` | 크래시 리포팅 |

#### [Clone] API 재구현 전략

Clone에서는 자체 API 서버를 구축하되, 외부 서비스 통합은 현대적 대안으로 교체한다.

| 원본 서비스 | Clone 대체 | 비고 |
|------------|-----------|------|
| PokerGFX API | 자체 ASP.NET Core API | 자체 버전 관리/텔레메트리 |
| WCF Service | gRPC 또는 REST API | WCF deprecated |
| Bugsnag | Sentry 또는 Application Insights | 오픈소스/Azure 네이티브 |
| AWS S3 | Azure Blob Storage 또는 S3 (선택) | 클라우드 유연성 |

### 10.4 Twitch Integration

#### 원본 구현

IRC 프로토콜 기반 채팅봇:
- 엔드포인트: `irc.chat.twitch.tv:6667`
- OAuth 인증 → `JOIN #channel` → `PRIVMSG` 파싱
- `PING/PONG` keepalive
- 시청자 채팅 명령어 → 게임 정보 응답
- OAuth Callback: `http://videopokertable.net/twitch_oauth.aspx`
- `keepalive_timer`: IRC 연결 유지

#### [Clone] 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| 프로토콜 | IRC (`irc.chat.twitch.tv:6667`) | Twitch EventSub API (WebSocket) |
| 인증 | OAuth2 (Kraken API, deprecated) | OAuth2 (Helix API, 현행) |
| 채팅 | PRIVMSG 파싱 | EventSub `channel.chat.message` |
| 채널 정보 | `/kraken/channels/` | `/helix/channels` |

### 10.5 LiveApi (HTTP REST)

#### 원본 구현

TCP 기반 HTTP 인터페이스:
- 외부 시스템에서 VPT 서버 제어
- 실시간 게임 데이터 조회
- `keepaliveTimer` + `KEEPALIVE_INTERVAL`로 연결 유지
- `enabled` 플래그로 활성화/비활성화

#### [Clone] 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| 프레임워크 | 커스텀 TCP HTTP | ASP.NET Core Minimal API |
| 인증 | 없음 (추정) | JWT Bearer 인증 |
| 문서화 | 없음 | OpenAPI (Swagger) 자동 생성 |
| 실시간 데이터 | Keepalive 폴링 | SignalR Hub (WebSocket) |

### 10.6 Third-Party SDK/Library

| 라이브러리 | 용도 | 원본 참조 | Clone 대안 |
|-----------|------|----------|-----------|
| **SharpDX** | DirectX 11 래퍼 | GPU 렌더링 | Vortice.Windows (maintained) |
| **MFormats SDK** (Medialooks) | 비디오 캡처/렌더링 (상용, CompanyID `13751`) | 비디오 파이프라인 | FFmpeg.AutoGen 또는 LibVLCSharp |
| **BearSSL** (C# port) | TLS 1.0-1.2 | RFID TLS | SslStream (.NET 내장) |
| **Costura.Fody** | 어셈블리 내장 패키징 (60개 DLL) | 배포 | Single-file publish (.NET 8) |
| **Newtonsoft.Json** | JSON 직렬화 | 전체 | System.Text.Json |
| **FluentValidation** | 입력 검증 (Phase 3) | CQRS 검증 | 유지 (이미 현대적) |
| **EO.WebEngine** | 내장 Chromium (OAuth 웹 뷰) | OAuth UI | WebView2 (Edge 기반) |
| **EntityFramework 6.0** | SQL Server 데이터 저장소 | 데이터 접근 | EF Core 8 |

### 10.7 KEYLOK USB Dongle

#### 원본 구현

DRM Layer 3 하드웨어 동글.

**DongleType enum**:

| 값 | 타입 | 설명 |
|:--:|------|------|
| 0 | Unknown | 미식별 |
| 1 | Fortress | Fortress 동글 (구형) |
| 2 | Keylok3 | KEYLOK 3세대 |
| 3 | Keylok2 | KEYLOK 2세대 |

**P/Invoke API (23+ 명령)**:

| 코드 | 기능 |
|------|------|
| ValidateCode1-3 | 동글 유효성 검증 |
| ClientIDCode1-2 | 클라이언트 ID 확인 |
| ReadCode1-3 | 데이터 읽기 인증 |
| WriteCode1-3 | 데이터 쓰기 인증 |
| KLCheck | 동글 존재 확인 |
| ReadAuth / WriteAuth | 읽기/쓰기 인증 |
| GetSN / GetLongSN | 시리얼 번호 조회 |
| ReadBlock / WriteBlock | 메모리 블록 읽기/쓰기 |
| GetExpDate / SetExpDate | 만료일 조회/설정 |
| GetMaxUsers / SetMaxUsers | 최대 사용자 조회/설정 |
| GetDongleType | 동글 타입 조회 |
| DoRemoteUpdate | 원격 업데이트 |
| LEDOn / LEDOff | LED 제어 |
| LaunchAntiDebugger | 디버거 탐지 |

**KLClientCodes**: 동일 코드 상수의 별도 복사본 (ValidateCode1/2/3, ClientIDCode1/2, ReadCode1/2/3, WriteCode1/2/3, KLCheck, ReadAuth, GetSN, WriteAuth, ReadBlock, WriteBlock)

#### [Clone] 재구현 전략

| 항목 | 원본 | Clone |
|------|------|-------|
| DRM 방식 | KEYLOK USB 동글 (P/Invoke) | 소프트웨어 라이선스 시스템 |
| 라이선스 검증 | 하드웨어 시리얼 + 메모리 블록 | JWT 기반 토큰 + 서버 검증 |
| 오프라인 지원 | 동글 물리 존재 확인 | 시간 제한 오프라인 토큰 |
| Anti-Debug | `LaunchAntiDebugger` | 제거 (불필요) |

---

## 11. 데이터 모델

### 11.1 핵심 Enum 카탈로그 (62+ 타입)

Clone에서는 모든 Enum의 정수 값을 정확히 보존하여 프로토콜 호환성을 유지해야 한다.

#### game enum (22개 변형)

```
holdem=0, holdem_sixplus_straight_beats_trips=1,
holdem_sixplus_trips_beats_straight=2, pineapple=3,
omaha=4, omaha_hilo=5, omaha5=6, omaha5_hilo=7,
omaha6=8, omaha6_hilo=9, courchevel=10, courchevel_hilo=11,
draw5=12, deuce7_draw=13, deuce7_triple=14, a5_triple=15,
badugi=16, badeucy=17, badacey=18, stud7=19, stud7_hilo8=20, razz=21
```

**게임 계열 분류**: `game_class { flop=0, draw=1, stud=2 }`

#### GfxMode enum

| 값 | 모드 | 설명 |
|:--:|------|------|
| 0 | Live | 실시간 방송 (딜러/테이블 화면, 홀카드 미노출) |
| 1 | Delay | 시간차 방송 (시청자용, 홀카드 노출) |
| 2 | Comm | 해설석 모드 (해설자 모니터, 홀카드 노출) |

#### LicenseType enum

```
Basic=1, Professional=4, Enterprise=5
```

#### DongleType enum

```
Unknown=0, Fortress=1, Keylok3=2, Keylok2=3
```

#### lang_enum (130개 UI 표시 라벨)

```
check=0, all_in=1, call=2, raise_to=3, bet=4, stack=5, pot=6, fold=7,
dealer=8, bb=9, sb=10, straddle=11, ante=12,
player_of_the_year=13, ...
(총 130개 - strip_pfr=129까지)
```

#### hand_class enum (10개 핸드 등급)

| 값 | 핸드 |
|:--:|------|
| 0 | High Card |
| 1 | One Pair |
| 2 | Two Pair |
| 3 | Three of a Kind |
| 4 | Straight |
| 5 | Flush |
| 6 | Full House |
| 7 | Four of a Kind |
| 8 | Straight Flush |
| 9 | Royal Flush |

#### card_type enum (53값)

52장의 카드 + 1개 unknown/blank 값.

#### AnimationState enum (16 states)

```
FadeIn=0, Glint=1, GlintGrow=2, GlintRotateFront=3,
GlintShrink=4, PreStart=5, ResetRotateBack=6, ResetRotateFront=7,
Resetting=8, RotateBack=9, Scale=10, SlideAndDarken=11,
SlideDownRotateBack=12, SlideUp=13, Stop=14, Waiting=15
```

#### 기타 핵심 Enum 전체

| Enum | 값 | 용도 |
|------|-----|------|
| `game_class` | flop=0, draw=1, stud=2 | 게임 계열 |
| `skin_auth_result` | no_network=0, permit=1, deny=2 | 스킨 인증 |
| `state_enum` (ATEM) | NotInstalled=0, Disconnected=1, Connected=2, Paused=3, Reconnect=4, Terminate=5 | ATEM 연결 |
| `reader_state` | disconnected, connected, negotiating, ok | RFID 상태 |
| `wlan_state` | off, on, connected_reset, ip_acquired, not_installed | WiFi 상태 |
| `module_type` | skyetek, v2 | RFID 모듈 |
| `connection_type` | usb, wifi | 연결 타입 |
| `BetStructure` | NoLimit=0, FixedLimit=1, PotLimit=2 | 베팅 구조 |
| `AnteType` | std_ante, button_ante, bb_ante, bb_ante_bb1st, live_ante, tb_ante, tb_ante_tb1st (7값) | 앤티 유형 |
| `OfflineLoginStatus` | LoginSuccess, LoginFailure, CredentialsExpired, CredentialsFound, CredentialsNotFound (5값) | 오프라인 상태 |
| `board_pos_type` | Top, Middle, Bottom (3값) | 보드 위치 |
| `show_type` | Always, OnAction, Never (3값) | 표시 유형 |
| `transition_type` | None, Fade, Slide, Wipe (4+값) | 전환 효과 |
| `chipcount_precision_type` | Exact, Rounded, Abbreviated (3값) | 칩 정밀도 |
| `timeshift` | Live, Delayed | 시간 이동 |
| `record` | live, live_no_overlay, delayed, delayed_no_overlay (4값) | 녹화 대상 |
| `platform` | 2값 | 렌더링 플랫폼 |
| `fold_hide_type` | Immediate, Delayed, Never | 폴드 숨김 |
| `card_reveal_type` | Manual, Auto, RFID | 카드 공개 |
| `leaderboard_pos_enum` | Left, Right, None | 리더보드 위치 |
| `heads_up_layout_mode` | Standard, Custom | 헤드업 레이아웃 |
| `heads_up_layout_direction` | LeftRight, TopBottom | 헤드업 방향 |
| `nit_display_type` | Standard, Hidden | NIT 표시 |
| `order_players_type` | BySeat, ByChips, ByAction | 플레이어 순서 |
| `equity_show_type` | None, Percentage, Fraction | 에퀴티 표시 |
| `hilite_winning_hand_type` | None, Cards, Full | 승리 하이라이트 |
| `outs_show_type` | None, Count, Cards | 아웃츠 표시 |
| `outs_pos_type` | Top, Bottom, Side | 아웃츠 위치 |
| `strip_display_type` | Standard, Compact | 스트립 표시 |
| `order_strip_type` | BySeat, ByChips | 스트립 정렬 |
| `auto_blinds_type` | None, OnChange, Always | 자동 블라인드 |
| `chipcount_disp_type` | Standard, BB, Currency | 칩 표시 |

### 11.2 config_type (282 필드)

전체 시스템 설정을 담는 거대 DTO. 저장 경로: `%APPDATA%\RFID-VPT`, 파일 확장자: `.pgfxconfig`

| 도메인 | 주요 필드 | 설명 |
|--------|----------|------|
| **비디오** | `fps`, `video_w`, `video_h`, `video_bitrate`, `video_encoder` | 출력 비디오 |
| **카메라** | camera 관련 (복수) | 입력 소스 |
| **스트리밍** | `stream_push_url`, `stream_username`, `stream_pwd` | RTMP 스트리밍 |
| **Twitch** | chatbot 연동 필드 | Twitch 통합 |
| **YouTube** | `youtube_username`, `youtube_pwd`, `youtube_title`, `youtube_tags`, `youtube_category` | YouTube 라이브 |
| **그래픽** | `skin`, `font`, `transition`, `animation` | UI 렌더링 |
| **RFID** | `rfid_board_delay`, `card_auth_package_crc` | 카드 인식 |
| **보안** | `settings_pwd`, `capture_encryption`, `kiosk_mode` | 접근 제어 |
| **Commentary** | `delayed_commentary`, external delay | 해설 지연 |
| **통계** | `auto_stat_vpip`, `auto_stat_pfr`, `auto_stat_agr`, `auto_stat_wtsd` | 자동 통계 |
| **Chipcount** | `chipcount_precision_type` 외 12개 | 칩카운트 정밀도 |

#### [Clone] 재구현 전략

282 필드의 모놀리식 config_type을 도메인별 Record 타입으로 분할한다.

| 원본 도메인 | Clone Record 타입 | 필드 수 (추정) |
|-----------|------------------|:------:|
| 비디오 | `VideoConfig` | ~20 |
| 카메라 | `CameraConfig` | ~15 |
| 스트리밍 | `StreamConfig` | ~10 |
| Twitch/YouTube | `SocialConfig` | ~15 |
| 그래픽 | `GraphicsConfig` | ~30 |
| RFID | `RfidConfig` | ~10 |
| 보안 | `SecurityConfig` | ~8 |
| Commentary | `CommentaryConfig` | ~5 |
| 통계 | `StatisticsConfig` | ~20 |
| Chipcount | `ChipDisplayConfig` | ~15 |
| 기타 | `MiscConfig` | ~30+ |

### 11.3 Player 데이터 모델

| 필드 | 타입 | 설명 |
|------|------|------|
| PlayerNum | int | 좌석 번호 |
| Name | string | 플레이어 이름 |
| LongName | string | 긴 이름 |
| Country | string | 국가 코드 |
| Stack | int | 칩 스택 |
| Cards | card[] | 홀카드 |
| SittingOut | bool | 자리비움 |
| VPIPPercent | int | VPIP 통계 |
| AggressionFrequencyPercent | int | 공격성 통계 |
| PreFlopRaisePercent | int | PFR 통계 |
| WentToShowDownPercent | int | WTSD 통계 |
| CumulativeWinningsAmt | int | 누적 수익 |
| EliminationRank | int | 탈락 순위 |

### 11.4 Hand 데이터 모델

**Hand**: HandNum, Description, StartDateTimeUTC, RecordingOffsetStart, Duration, GameClass, GameVariant, BetStructure, AnteAmt, BombPotAmt, NumBoards, RunItNumTimes, FlopDrawBlinds, StudLimits, `List<Player>`, `List<Event>`

**Event**: EventType, DateTimeUTC, PlayerNum, BetAmt, NumCardsDrawn, BoardNum, Pot, BoardCards

**FlopDrawBlinds**: BlindLevel, AnteType, SmallBlindAmt, BigBlindAmt, ThirdBlindAmt, ButtonPlayerNum, SmallBlindPlayerNum, BigBlindPlayerNum, ThirdBlindPlayerNum

### 11.5 PlayerStrength

`PlayerStrength { Num: int, Strength: ulong }` - 핸드 강도 (64비트 bitmask, hand_eval 연동)

### 11.6 GameTypeData (게임 상태 DTO - 79+ 필드)

게임의 전체 상태를 담는 직렬화 가능 데이터 객체:

| 카테고리 | 주요 필드 | 설명 |
|---------|----------|------|
| **게임 설정** | `_gfxMode`, `_game_variant`, `bet_structure`, `_ante_type`, `num_boards`, `hand_num` | 게임 기본 정보 |
| **블라인드/베팅** | `_small`, `_big`, `_third`, `_ante`, `cap`, `bomb_pot`, `seven_deuce_amt`, `smallest_chip`, `blind_level`, `_bring_in`, `_low_limit`, `_high_limit`, `num_raises_this_street`, `min_raise_amt`, `button_blind` | 베팅 구조 상세 |
| **게임 상태** | `hand_in_progress`, `hand_ended`, `dist_pot_req`, `_next_hand_ok`, `_chop`, `card_scan_warning`, `resetting`, `cum_win_done`, `tag_hand`, `_enh_mode`, `_dotfus_tampered` | 상태 플래그 |
| **플레이어 포지션** | `action_on`, `pl_dealer`, `pl_small`, `pl_big`, `pl_third`, `_first_to_act`, `_first_to_act_preflop`, `_first_to_act_postflop`, `last_bet_pl`, `starting_players`, `pl_buy`, `pl_stud_first_to_act` | 좌석 위치 |
| **Run It** | `run_it_times`, `run_it_times_remaining`, `run_it_times_num_board_cards` | Run It Twice |
| **Stud/Draw** | `stud_draw_in_progress`, `stud_community_card`, `stud_start_ok`, `draws_completed`, `drawing_player` | Stud/Draw 게임 상태 |
| **NIT Game** | `nit_game_waiting_to_start`, `nit_winner_safe`, `nit_game_amt` | NIT 사이드 게임 |

### 11.7 WCF DTO

| DTO | 방향 | Methods | 주요 필드 |
|-----|------|:-------:|----------|
| **client_ping** | Slave → Master | 49 | 시스템 성능 (cpu/gpu), 미디어 상태, RFID 연결, 라이선스 시리얼, 변조 감지, 설정 동기화 |
| **server_ping** | Master → Slave | 23 | 현재 액션, 카드 인증 패키지, 기능 플래그 (live_api, live_data_export) |

### 11.8 ConfigurationPreset (99+ 필드)

모든 그래픽 출력 설정을 포함하는 메가 DTO:

| 카테고리 | 주요 필드 |
|---------|----------|
| **레이아웃** | `board_pos`, `gfx_vertical`, `gfx_bottom_up`, `gfx_fit`, `heads_up_layout_mode`, `heads_up_layout_direction`, `heads_up_custom_ypos`, margins |
| **표시** | `at_show`, `fold_hide`, `fold_hide_period`, `card_reveal`, `show_rank`, `show_seat_num`, `show_eliminated`, `show_action_on_text`, `rabbit_hunt`, `dead_cards`, `indent_action` |
| **전환 효과** | `trans_in`/`trans_out` (type + time) |
| **통계** | VPIP, PFR, AGR, WTSD, Position, CumWin, Payouts (`auto_stat_*`, `ticker_stat_*`), `auto_stats_time`, `auto_stats_first_hand`, `auto_stats_hand_interval` |
| **칩 정밀도** | 8개 영역: `cp_leaderboard`, `cp_pl_stack`, `cp_pl_action`, `cp_blinds`, `cp_pot`, `cp_twitch`, `cp_ticker`, `cp_strip` |
| **통화** | `currency_symbol`, `show_currency`, `trailing_currency_symbol`, `divide_amts_by_100` |
| **로고** | `panel_logo`, `board_logo`, `strip_logo` (`byte[]`) |
| **기타** | `vanity_text`, `game_name_in_vanity`, `media_path`, `action_clock_count` |

### 11.9 [Clone] 데이터 모델 종합 재구현 전략

| 구성요소 | 원본 | Clone | 비고 |
|---------|------|-------|------|
| Enum | C# 3.x 스타일 | C# 12 (string conversion, flags) | 정수 값 보존 필수 |
| config_type 282 필드 | 단일 모놀리식 클래스 | 도메인별 Record 타입 분할 | `VideoConfig`, `CameraConfig` 등 |
| Player | mutable class | immutable record 타입 | `record Player(...)` |
| client_ping/server_ping | WCF DTO (49/23 methods) | gRPC message 타입 | Protocol Buffers 정의 |
| GameTypeData | 79+ 필드 class | 도메인별 분할 + 합성 루트 | Domain Aggregate 패턴 |
| ConfigurationPreset | 99+ 필드 class | 카테고리별 분할 record | 직렬화 호환 유지 |
| DB 모델 | EntityFramework 6.0 | EF Core 8 + Value Objects | Code-First Migration |

---

## 12. Service Architecture

### 12.1 3세대 아키텍처 개요

원본 시스템은 시간 경과에 따른 3단계 아키텍처 진화를 보여준다. Clone에서는 Phase 3 패턴으로 통일하되, Phase 2의 안정적 인터페이스 추상화를 유지한다.

```
Phase 1: God Class (Legacy)
  main_form.cs (329 methods, 150+ fields), config.cs, gfx.cs, render.cs
  특징: 모든 로직이 WinForms 이벤트 핸들러에 집중

      |  리팩토링
      v

Phase 2: Service Interface Layer
  GameTypes/ (26 files) + Services/ (7) + Interfaces/ (7)
  특징: Interface 분리, DI 도입, 게임 로직 서비스화

      |  현대화
      v

Phase 3: DDD + CQRS (Modern)
  Features/ (56 files) + SystemMonitors/ (5)
  특징: Feature Slice, CQRS Command/Handler, FluentValidation
  Microsoft.Extensions.DI 기반
```

**공존 증거**:
- `GameType.cs`가 `ILicenseService` (Phase 3)를 필드로 참조
- `gfx.cs`가 Phase 2 인터페이스 (`IGamePlayersService` 등)를 필드로 보유
- `Program.cs`가 `IServiceProvider` (Microsoft DI)와 `Bugsnag.Client` 보유

### 12.2 GameTypes Service Layer (Phase 2)

10개 인터페이스 + 11개 구현:

| Interface | Implementation | Methods | 역할 |
|-----------|---------------|:-------:|------|
| `IGameConfigurationService` | `GameConfigurationService` | 16 | 게임 설정 (Fitphd: 150+ params) |
| `IGameCardsService` | `GameCardsService` | 41 | 카드 표시, 에퀴티, 아웃츠 |
| `IGamePlayersService` | `GamePlayersService` | 54 | 플레이어 표시, KEYLOK 연동 |
| `IGameGfxService` | `GameGfxService` | 11 | GFX 모드 관리 |
| `IGameVideoService` | `GameVideoService` | 12 | 비디오 녹화 |
| `IGameVideoLiveService` | `GameVideoLiveService` | 19 | 라이브 비디오 스트림 |
| `IGameSlaveService` | `GameSlaveService` | 17 | Slave 통신 |
| `IHandEvaluationService` | `HandEvaluationService` | 7 | 핸드 강도 조회 |
| `ITagsService` | `TagsService` | 16 | 핸드 태깅, 통계 |
| `ITimersService` | `TimersService` | 10 | 타이머 관리 |

**주목할 발견**: `GamePlayersService`에 KEYLOK 동글의 `KBLOCK()` 연산이 직접 포함되어 있다. 이는 라이선스 검증이 게임 서비스와 밀접하게 결합되어 있음을 의미한다.

**GameConfigurationService**의 `Fitphd()` 메서드는 150+ 파라미터를 받아 전체 게임 설정을 적용하는 메가 메서드이다.

### 12.3 Root Services Layer

| Interface | Implementation | 역할 |
|-----------|---------------|------|
| `IVideoMixerService` | `VideoMixerService` | mmr.dll 브리지, 녹화 상태 |
| `IUpdatePlayerService` | `UpdatePlayerService` | 플레이어 레이아웃 엔진 |
| `IActionTrackerService` | `ActionTrackerService` | 외부 프로세스 액션 추적 |
| `IEffectsService` | `EffectsService` | 시각 효과 |
| `IGraphicElementsService` | `GraphicElementsService` | 그래픽 요소 레지스트리 |
| `ITransmisionEncodingService` | `TransmisionEncodingService` | 출력 인코딩 |

**UpdatePlayerService** (가장 복잡): 화면에 플레이어 위치를 계산하고 배치하는 레이아웃 엔진. `_horizontalSpacingFactor`, `_columnCount`, `_verticalSpacingFactor` 등의 레이아웃 파라미터와 `_graphicElementsService`, `_gamePlayersService` 등 다수 서비스 의존성을 가진다.

**ActionTrackerService**: 외부 프로세스(`Process`)를 사용하여 딜러 액션을 추적. 별도 분석 프로세스와 IPC 통신.

### 12.4 Features Layer (Phase 3 - DDD/CQRS)

![Features 디렉토리 구조](../images/mockups/features-directory.png)

```
Features/
├── Login/                          # CQRS 패턴 로그인
│   ├── ILoginHandler.cs           # Command Handler 인터페이스
│   ├── LoginHandler.cs            # Command Handler 구현
│   ├── Models/
│   │   ├── LoginCommand.cs        # CQRS Command 객체
│   │   └── LoginResult.cs         # 결과 DTO
│   ├── Validators/
│   │   └── LoginCommandValidator.cs  # FluentValidation
│   └── Configuration/
│       └── LoginConfiguration.cs  # 설정
│
└── Common/
    ├── Authentication/             # 원격 인증
    ├── Licensing/                  # 라이선스 관리 (28 파일)
    ├── Dongle/                    # USB 동글 DRM
    ├── OfflineSession/            # 오프라인 로그인
    ├── IdentityInformationCache/  # 신원 정보 캐시
    └── ConfigurationPresets/      # 설정 프리셋
```

**Login CQRS 흐름**:

```
LoginCommand (Email + Password + CurrentVersion)
       |
       v
LoginCommandValidator (FluentValidation)
       |  <- 검증 실패 시 ValidationResult 반환
       v
LoginHandler (5 deps: IValidator, IOfflineSessionService,
             IAuthenticationService, IIdentityInformationCacheService,
             AppVersionValidationHandler)
       |
       v
LoginResult (IsSuccess + ErrorMessage + ValidationResult + VersioningResult)
```

**Licensing 시스템** (28 파일): `ILicenseService` → `LicenseService` → `LicenseBackgroundService` (타이머 기반 주기적 원격 검증) + `IDongleService` → `DongleService` → `KeylokDongle`

### 12.5 DI 등록

`ServiceCollectionExtensions.AddCommonLayer(IServiceCollection, IConfiguration)`
→ IEncryptionService, IDownloadLinksService, IAppVersionsService 등록

**Entry Point** (`Program.cs`):
```csharp
static IServiceProvider ServiceProvider;     // Microsoft DI
static IConfiguration Configuration;          // Microsoft Configuration
static Bugsnag.Client Bugsnag;               // 글로벌 크래시 리포팅
```

### 12.6 [Clone] Service Architecture 종합 재구현 전략

| 구성요소 | 원본 | Clone | 비고 |
|---------|------|-------|------|
| Phase 2 서비스 인터페이스 | 10개 Interface + 11개 Implementation | 그대로 유지 | 안정적 추상화 보존 |
| Phase 3 CQRS | 수동 Handler 패턴 | MediatR 도입 | `IRequest<T>` → `IRequestHandler<T>` |
| FluentValidation | 수동 호출 | MediatR Pipeline Behavior로 자동화 | `ValidationBehavior<TRequest, TResponse>` |
| DI 등록 | 수동 `AddCommonLayer()` | Scrutor 자동 등록 | Convention 기반 스캔 |
| God Class (main_form) | 329 methods, 150+ fields | ViewModel + Service 분리 (MVVM) | WPF 또는 Avalonia UI |
| GameConfigurationService.Fitphd() | 150+ 파라미터 메가 메서드 | 도메인별 Config Apply 분리 | `ApplyVideoConfig()`, `ApplyCameraConfig()` 등 |
| GamePlayersService + KEYLOK 결합 | 게임 서비스에 DRM 로직 포함 | 라이선스 검증을 별도 Middleware로 분리 | Cross-Cutting Concern |
| ActionTrackerService | 외부 Process IPC | In-Process Service 또는 gRPC 통신 | 프로세스 관리 단순화 |
| Bugsnag | Bugsnag.Client | Sentry SDK 또는 Application Insights | 오픈소스 대안 |
| EntityFramework 6.0 | EF 6 (레거시) | EF Core 8 | Migration 자동화 |

---

*PokerGFX Clone PRD Wave 3 - 네트워크 프로토콜, 외부 서비스 통합, 데이터 모델, Service Architecture*
