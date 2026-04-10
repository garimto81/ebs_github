# net_conn.dll 네트워크 프로토콜 심층 분석

> PokerGFX RFID-VPT 시스템의 클라이언트-서버 통신 프로토콜 역공학 결과

## 목차

1. [아키텍처 개요](#1-아키텍처-개요)
2. [전송 계층](#2-전송-계층)
3. [암호화 체계](#3-암호화-체계)
4. [메시지 프레이밍](#4-메시지-프레이밍)
5. [직렬화 및 명령 레지스트리](#5-직렬화-및-명령-레지스트리)
6. [프로토콜 명령 전체 목록](#6-프로토콜-명령-전체-목록)
7. [연결 수명 주기](#7-연결-수명-주기)
8. [핵심 데이터 구조](#8-핵심-데이터-구조)
9. [보안 취약점](#9-보안-취약점)

---

## 1. 아키텍처 개요

net_conn.dll은 PokerGFX 시스템의 모든 네트워크 통신을 담당하는 핵심 라이브러리다. 단일 서버(vpt_server.exe)와 다수 클라이언트(원격 디스플레이, 모바일 컨트롤러) 간의 양방향 통신을 구현한다.

### 클래스 계층

```
net_conn.dll (168 파일)
├── 전송 계층
│   ├── server              # TCP 서버 (정적 클래스)
│   ├── server_obj          # 개별 TCP 클라이언트 연결
│   ├── client<T>           # UDP Discovery + TCP 클라이언트 관리자
│   └── client_obj          # 개별 TCP 클라이언트 연결 (클라이언트 측)
├── 보안
│   └── enc                 # AES-256 암호화/복호화
├── 프로토콜
│   ├── RemoteRegistry      # 명령 문자열 → 타입 매핑 (Singleton)
│   ├── IClientNetworkListener  # 16개 클라이언트 콜백 인터페이스
│   └── IServerNetworkListener  # 서버 콜백 인터페이스 (빈 마커)
├── 모델 (100+ 파일)
│   ├── IRemoteRequest      # 요청 인터페이스 (Command, ToString)
│   ├── IRemoteResponse     # 응답 인터페이스 (Command, ToString)
│   └── [Request/Response 쌍들...]
└── 유틸리티
    ├── Common              # 안전한 int 파싱
    └── NetworkQuality      # 연결 품질 열거형 (Good, Fair, Poor)
```

### 통신 모델

```
┌──────────────┐         UDP:9000          ┌──────────────┐
│              │ ◄──── Broadcasting ────►   │              │
│  vpt_server  │                           │   Client(s)  │
│  (server)    │         TCP:9001          │  (client<T>) │
│              │ ◄──── Persistent ────►    │              │
└──────────────┘     (AES Encrypted)       └──────────────┘
```

---

## 2. 전송 계층

### 2.1 UDP Discovery (포트 9000)

서버와 클라이언트가 LAN에서 서로를 자동 검색하는 메커니즘이다.

**서버 측 (server.cs)**:
- `SERVER_UDP_PORT = 9000`으로 바인딩
- 10,000바이트 수신 버퍼 (`remote_udp_buff`)
- 수신된 UDP 패킷이 `_id_rx` 문자열을 포함하면 응답
- 응답으로 `_id_tx` 문자열을 ASCII 인코딩하여 전송
- 수신 소스 포트: 9002 (하드코딩)

```csharp
// 서버 UDP 응답 로직 (재구성)
void remote_udp_rec_callback(IAsyncResult ar) {
    int bytesRead = remote_udp.EndReceiveFrom(ar, ref endpoint);
    if (bytesRead > 0) {
        string received = Encoding.ASCII.GetString(remote_udp_buff, 0, bytesRead);
        if (received == "" || received.Contains(_id_rx)) {
            IPEndPoint sender = (IPEndPoint)endpoint;
            byte[] response = Encoding.ASCII.GetBytes(_id_tx);
            remote_udp.SendTo(response, sender);
        }
    }
    rec_remote_udp(); // 다음 패킷 대기
}
```

**클라이언트 측 (client\`1.cs)**:
- `SERVER_UDP_PORT = 9000` 대상으로 브로드캐스트
- `udp_timer`: 1초 간격으로 브로드캐스트 반복
- 수신 시 `process_remote_udp()` 호출
- ID 문자열에 쉼표(`,`, char 44) 포함 시 서브스트링으로 서버 ID 추출
- 새 서버 발견 시 `_svr` 리스트에 추가하고 `list_changed` 이벤트 발생
- `_promiscuous` 모드: 발견 즉시 자동 TCP 연결

**Discovery 시퀀스**:
```
Client                                    Server
  │                                         │
  │──── UDP Broadcast (_id_tx) ────────────►│ :9000
  │                                         │
  │◄──── UDP Response (_id_tx) ─────────────│
  │                                         │
  │──── TCP Connect ──────────────────────► │ :9001
  │                                         │
  │◄──── ConnectResponse(License) ──────────│
  │◄──── IdtxResponse(id_tx) ───────────────│
  │                                         │
  │──── IdtxRequest(id_tx) ────────────────►│
  │──── ConnectRequest ────────────────────►│
```

### 2.2 TCP 통신 (포트 9001)

**서버 측 (server.cs + server_obj.cs)**:
- `SERVER_TCP_PORT = 9001`
- `svr_tcp`: Listen 소켓, backlog=0 (즉시 수락)
- 비동기 Accept 패턴 (`BeginAccept`/`EndAccept`)
- 새 연결 시 `server_obj` 인스턴스 생성
- 클라이언트 리스트 관리: `_client: List<server_obj>`
- 연결 시 즉시 `ConnectResponse` (license 포함)와 `IdtxResponse` 전송

**서버 객체 (server_obj.cs)**:
- `TCP_BUFF_SIZE`: TCP 버퍼 크기 (static)
- `TCP_LINE_DELIMITER = 1`: SOH (Start of Heading, 0x01) 구분자
- `KEEPALIVE_INTERVAL = 10000`: 10초 Keepalive 타이머
- `authenticated`: 인증 상태 플래그
- `disconnect_sent`: 중복 disconnect 방지 플래그
- `rem_sb: StringBuilder`: 수신 버퍼 (SOH까지 누적)

**클라이언트 객체 (client_obj.cs)**:
- `keepalive_timer`: 3초 간격 Keepalive 전송
- `_persist`: true면 연결 끊어져도 자동 재연결
- `_isClosing`: volatile 플래그 (스레드 안전 종료)
- `_cleanupLock`: Monitor 기반 동기화
- `BackgroundWorker` 사용: 수신/전송 모두 비동기

### 2.3 연결 관리

**서버의 메시지 라우팅 (server.cs)**:
```csharp
// send() 오버로드 - 타겟 필터링
void send(IRemoteResponse msg, string client_type, bool only_authenticated) {
    for (int i = 0; i < _client.Count; i++) {
        if (_client[i] != null) {
            bool matchType = (client_type == "" || _client[i].rem_id == client_type);
            bool matchAuth = (!only_authenticated || _client[i].authenticated);
            if (matchType && matchAuth) {
                _client[i].send(msg);
            }
        }
    }
}
```

**Keepalive 매커니즘**:
| 구분 | 서버 (server_obj) | 클라이언트 (client_obj) |
|------|:--:|:--:|
| 간격 | 10초 | 3초 |
| 동작 | 타이머 만료 시 `close()` | 타이머마다 `KeepAliveRequest` 전송 |
| 리셋 | 데이터 수신 시 타이머 재생성 | N/A |
| 실패 | 연결 종료 → `nc_closed` 이벤트 | `_persist`면 자동 재연결 |

---

## 3. 암호화 체계

### enc.cs - AES-256 Rijndael

net_conn 프로토콜의 모든 TCP 메시지는 AES 암호화된다.

**하드코딩된 암호화 키 자료**:

| 파라미터 | 값 | 용도 |
|---------|-----|------|
| Default Password | `45389rgjkonlgfds90439r043rtjfewp9042390j4f` | PasswordDeriveBytes 시드 |
| Salt | `dsafgfdagtds4389tytgh` | PBKDF1 salt (ASCII 인코딩) |
| IV | `4390fjrfvfji9043` | 초기화 벡터 (16바이트, ASCII) |
| Key Size | 32바이트 (256비트) | AES-256 |

**키 유도 과정** (재구성):
```csharp
static void init(string pwd) {
    byte[] saltBytes = Encoding.ASCII.GetBytes("dsafgfdagtds4389tytgh");
    var pdb = new PasswordDeriveBytes(pwd, saltBytes);
    _key = pdb.GetBytes(32);  // 256-bit key
}
```

**암호화 설정**:
- 알고리즘: `RijndaelManaged` (AES-256)
- 모드: CBC (기본값, 명시적 설정 없음)
- 패딩:
  - 암호화 (`csp_enc`): `PaddingMode.PKCS7` (값 3)
  - 복호화 (`csp_dec`): `PaddingMode.None` (값 1)
- 스레드 안전: `Monitor.Enter/Exit` (lock)으로 동기화

**encrypt() 알고리즘** (재구성):
```csharp
static string encrypt(string s) {
    lock (sync_object) {
        if (_key == null) init("45389rgjkonlgfds90439r043rtjfewp9042390j4f");
        using (var ms = new MemoryStream())
        using (var cs = new CryptoStream(ms, csp_enc.CreateEncryptor(get_key(), get_IV()), CryptoStreamMode.Write)) {
            byte[] inputBytes = Encoding.UTF8.GetBytes(s);
            cs.Write(inputBytes, 0, inputBytes.Length);
            cs.FlushFinalBlock();
            return Convert.ToBase64String(ms.ToArray());
        }
    }
}
```

**decrypt() 알고리즘** (재구성):
```csharp
static string decrypt(string s) {
    lock (sync_object) {
        if (_key == null) init("45389rgjkonlgfds90439r043rtjfewp9042390j4f");
        byte[] cipherBytes = Convert.FromBase64String(s);
        byte[] output = new byte[cipherBytes.Length];
        using (var ms = new MemoryStream(cipherBytes))
        using (var cs = new CryptoStream(ms, csp_dec.CreateDecryptor(get_key(), get_IV()), CryptoStreamMode.Read)) {
            cs.Read(output, 0, output.Length);
            cs.FlushFinalBlock();
        }
        string result = Encoding.UTF8.GetString(output);
        int nullIdx = result.IndexOf('\0');
        if (nullIdx >= 0 && nullIdx < result.Length) {
            result = result.Substring(0, nullIdx);  // NULL 종료자 제거
        }
        return result;
    }
}
```

---

## 4. 메시지 프레이밍

### Wire Format

```
[AES-256 Encrypted JSON (Base64)] [SOH (0x01)]
```

**수신 프로세스 (server_obj.remote_tcp_rec_callback)**:

1. `NetworkStream.BeginRead`로 비동기 수신
2. 수신된 바이트 배열을 순회
3. `0x01` (SOH) 만나면 지금까지 누적된 `StringBuilder` 내용을 완성된 메시지로 처리
4. 그 외 바이트는 `StringBuilder`에 `Append`
5. 완성된 메시지: `enc.decrypt()` → `deserializeIRemoteRequest()` → `process_rem_str()`
6. Keepalive 타이머 리셋 (10초)
7. 0바이트 수신 시 연결 종료

```
TCP 스트림 예시:
[Base64EncodedAES_1][0x01][Base64EncodedAES_2][0x01][Base64E...]
                    ^SOH                      ^SOH
```

**전송 프로세스 (server_obj.send)**:

1. `IRemoteResponse`를 `Newtonsoft.Json.JsonConvert.SerializeObject()`로 직렬화
2. JSON 문자열을 `enc.encrypt()`로 AES 암호화 (결과는 Base64)
3. `StringBuilder`에 암호화된 문자열 + `0x01` (SOH) 구분자 추가
4. `Encoding.ASCII.GetBytes()`로 변환
5. `NetworkStream.BeginWrite()`로 비동기 전송

### 직렬화 포맷

- **현재 (v2.0+)**: JSON (Newtonsoft.Json)
  - 요청: `{ "Command": "AUTH", "Password": "...", "Version": "..." }`
  - 응답: `{ "Command": "GAME_STATE", "GameType": "HOLDEM", "InitialSync": true }`
- **레거시 (v1.x)**: CSV 구분자 기반
  - `AuthRequest.ToString()` → `"AUTH,password,version"`
  - 대부분의 Model 클래스에 CSV 기반 `ToString()`과 `string[] cmd` 생성자 공존
  - 이는 프로토콜 마이그레이션 과도기의 흔적

---

## 5. 직렬화 및 명령 레지스트리

### RemoteRegistry (Singleton)

모든 명령 문자열을 해당 .NET 타입에 매핑하는 Reflection 기반 레지스트리.

```csharp
// RemoteRegistry 생성자 로직 (재구성)
private RemoteRegistry() {
    _commandRequestTypeMap = new Dictionary<string, Type>();
    _commandResponseTypeMap = new Dictionary<string, Type>();

    Type requestInterface = typeof(IRemoteRequest);
    Type responseInterface = typeof(IRemoteResponse);

    foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies()) {
        Type[] types;
        try {
            types = assembly.GetTypes();
        } catch (ReflectionTypeLoadException ex) {
            types = ex.Types.Where(t => t != null).ToArray();
        }

        foreach (Type type in types) {
            if (type == null || type.IsAbstract) continue;
            if (!requestInterface.IsAssignableFrom(type) &&
                !responseInterface.IsAssignableFrom(type)) continue;

            object instance = Activator.CreateInstance(type);

            if (instance is IRemoteRequest req) {
                string cmd = req.Command;
                if (!string.IsNullOrEmpty(cmd) && !_commandRequestTypeMap.ContainsKey(cmd))
                    _commandRequestTypeMap.Add(cmd, type);
                else
                    throw new Exception($"The request key {cmd} already exist and it would be duplicated.");
            }

            if (instance is IRemoteResponse resp) {
                string cmd = resp.Command;
                if (!string.IsNullOrEmpty(cmd) && !_commandResponseTypeMap.ContainsKey(cmd))
                    _commandResponseTypeMap.Add(cmd, type);
                else
                    throw new Exception($"The response key {cmd} already exist and it would be duplicated.");
            }
        }
    }
}
```

**핵심 특성**:
- `Lazy<RemoteRegistry>`: Thread-safe lazy initialization
- Reflection으로 현재 AppDomain의 모든 어셈블리 스캔
- `IRemoteRequest`/`IRemoteResponse` 구현 타입 자동 등록
- 기본 생성자로 인스턴스 생성 → `Command` 속성 읽기
- 중복 키 시 예외 발생

### 역직렬화 프로세스

**서버 측 (server_obj.deserializeIRemoteRequest)**:
```
JSON string
  → JObject.Parse()
  → JObject["Command"] → command string
  → RemoteRegistry.TryGetRequestType(command, out Type)
  → JsonConvert.DeserializeObject(json, type)
  → cast to IRemoteRequest
```

**클라이언트 측 (client_obj.deserializeIRemoteResponse)**:
동일 패턴이나 `TryGetResponseType` 사용.

---

## 6. 프로토콜 명령 전체 목록

디컴파일된 Models 디렉토리에서 추출한 113+ Request/Response 쌍:

### 6.1 연결 관리 (Connection)

| 명령 | 방향 | 필드 | 설명 |
|------|------|------|------|
| `CONNECT` | Req/Resp | License(ulong) | TCP 연결 수립, 서버 라이선스 전달 |
| `DISCONNECT` | Req/Resp | - | 연결 해제 |
| `AUTH` | Req/Resp | Password, Version | 패스워드 인증 + 버전 교환 |
| `KEEPALIVE` | Req | - | 연결 유지 (클라이언트→서버) |
| `IDTX` | Req/Resp | IdTx(string) | 상대방 식별자 교환 |
| `HEARTBEAT` | Req/Resp | - | 양방향 생존 확인 |
| `IDUP` | Resp | - | ID 업데이트 알림 |

### 6.2 게임 상태 (Game State)

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `GAME_STATE` | Resp | GameType, InitialSync | 게임 타입 변경 + 초기 동기화 |
| `GAME_INFO` | Req/Resp | 75+ 필드 | 테이블 전체 상태 (아래 상세) |
| `GAME_TYPE` | Req | GameType | 게임 유형 변경 요청 |
| `GAME_VARIANT` | Req | Variant | 게임 변형 선택 |
| `GAME_VARIANT_LIST` | Req/Resp | - | 지원 변형 목록 조회 |
| `GAME_CLEAR` | Req | - | 테이블 리셋 |
| `GAME_TITLE` | Req | Title | 게임 제목 설정 |
| `GAME_SAVE_BACK` | Req | - | 게임 상태 저장 |
| `NIT_GAME` | Req | Amount | Nit (소극적 플레이) 금액 설정 |

### 6.3 플레이어 관리 (Player)

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `PLAYER_INFO` | Req/Resp | Player, Name, Stack, Stats... | 플레이어 전체 정보 (20 필드) |
| `PLAYER_CARDS` | Req/Resp | Player, Cards(string) | 홀카드 정보 |
| `PLAYER_BET` | Req/Resp | Player, Amount | 베팅 금액 |
| `PLAYER_BLIND` | Req | Player, Amount | 블라인드 설정 |
| `PLAYER_ADD` | Req | Seat, Name | 신규 플레이어 착석 |
| `PLAYER_DELETE` | Req | Seat | 플레이어 퇴장 |
| `PLAYER_COUNTRY` | Req | Player, Country | 국기 설정 |
| `PLAYER_DEAD_BET` | Req | Player, Amount | 데드 베팅 |
| `PLAYER_PICTURE` | Resp | Player, Picture | 프로필 사진 |
| `DELAYED_PLAYER_INFO` | Req/Resp | - | 지연 방송용 플레이어 정보 |

### 6.4 카드/보드 (Cards & Board)

| 명령 | 방향 | 주요 필드 | 설명 |
|------|------|----------|------|
| `BOARD_CARD` | Req/Resp | Cards | 커뮤니티 카드 |
| `CARD_VERIFY` | Req | - | RFID 카드 검증 요청 |
| `FORCE_CARD_SCAN` | Req | - | 강제 카드 스캔 |
| `DRAW_DONE` | Req/Resp | - | 드로우 라운드 완료 |
| `EDIT_BOARD` | Req/Resp | - | 보드 카드 편집 |

### 6.5 디스플레이/UI (Display)

| 명령 | 방향 | 설명 |
|------|------|------|
| `FIELD_VISIBILITY` | Req/Resp | 필드 표시/숨김 제어 |
| `FIELD_VAL` | Req/Resp | 필드 값 설정 |
| `GFX_ENABLE` | Req/Resp | 그래픽 오버레이 활성화/비활성화 |
| `ENH_MODE` | Req/Resp | Enhanced 모드 (분석 표시 강화) |
| `SHOW_PANEL` | Req | 패널 표시 제어 |
| `STRIP_DISPLAY` | Req | 하단 스트립(티커) 표시 |
| `BOARD_LOGO` | Req/Resp | 보드 로고 이미지 |
| `PANEL_LOGO` | Req/Resp | 패널 로고 이미지 |
| `ACTION_CLOCK` | Req | 액션 타이머 제어 |
| `DELAYED_FIELD_VISIBILITY` | Req/Resp | 지연 방송 필드 제어 |
| `DELAYED_GAME_INFO` | Req/Resp | 지연 방송 게임 정보 |

### 6.6 미디어/카메라 (Media)

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

### 6.7 리더/RFID

| 명령 | 방향 | 설명 |
|------|------|------|
| `READER_STATUS` | Resp | RFID 리더 상태 |

### 6.8 베팅/재무 (Betting & Financial)

| 명령 | 방향 | 설명 |
|------|------|------|
| `PAYOUT` | Req | 팟 지급 |
| `MISS_DEAL` | Req | 미스딜 처리 |
| `CHOP` | Resp | 팟 분할 |
| `FORCE_HEADS_UP` | Req/Resp | 헤즈업 강제 전환 |
| `FORCE_HEADS_UP_DELAYED` | Req/Resp | 지연 방송 헤즈업 |

### 6.9 데이터 전송 (Data Transfer)

| 명령 | 방향 | 설명 |
|------|------|------|
| `SKIN_CHUNK` | Req/Resp | 스킨 파일 청크 전송 |
| `COMM_DL` | Req/Resp | 커뮤니케이션 다운로드 |
| `AT_DL` | Req/Resp | 안테나 테이블 다운로드 |
| `VTO` | Req/Resp | 가상 테이블 오브젝트 |

### 6.10 기록/로그 (History & Logging)

| 명령 | 방향 | 설명 |
|------|------|------|
| `HAND_HISTORY` | Req/Resp | 핸드 히스토리 |
| `HAND_LOG` | Resp | 핸드 로그 |
| `GAME_LOG` | Resp | 게임 로그 |
| `COUNTRY_LIST` | Req/Resp | 국가 목록 |

---

## 7. 연결 수명 주기

### 7.1 서버 측 연결 핸들링

```
tcp_accept(IAsyncResult)
   │
   ├── EndAccept → Socket
   ├── new server_obj(license, socket, id_tx, rx_str_delegate)
   │     ├── NetworkStream 생성
   │     ├── keepalive_timer = 10초
   │     ├── remote_tcp_rec_data() 비동기 수신 시작
   │     ├── send(ConnectResponse { License })
   │     └── send(IdtxResponse { IdTx })
   ├── server_obj.closed += nc_closed
   └── _client.Add(server_obj)
```

### 7.2 메시지 처리 파이프라인 (서버 측)

```
remote_tcp_rec_callback(IAsyncResult)
   │
   ├── state.stream.EndRead → bytesRead
   │
   ├── if (bytesRead == 0) → close() → 연결 종료
   │
   ├── keepalive_timer 리셋 (10초)
   │
   ├── for each byte:
   │     ├── byte == 0x01 (SOH)?
   │     │     ├── message = rem_sb.ToString()
   │     │     ├── decrypted = enc.decrypt(message)
   │     │     ├── request = deserializeIRemoteRequest(decrypted)
   │     │     ├── process_rem_str(request)
   │     │     └── rem_sb = new StringBuilder()
   │     └── else: rem_sb.Append((char)byte)
   │
   └── finally: remote_tcp_rec_data() → 다음 수신 대기
```

### 7.3 process_rem_str 라우팅

```csharp
void process_rem_str(IRemoteRequest remote_str) {
    if (remote_str == null) return;

    if (remote_str is IdtxRequest idtx) {
        // 상대방 ID 저장
        _rem_id = idtx.IdTx;
        // CONNECT 이벤트 발생 → 응답 전송
        var responses = _rx_str.Invoke(this, new ConnectRequest());
        if (responses != null) send(responses);
    }
    else if (remote_str.Command != "KEEPALIVE") {
        // 일반 명령 처리 → 응답 전송
        var responses = _rx_str.Invoke(this, remote_str);
        if (responses != null) send(responses);
    }
    // KEEPALIVE는 무시 (타이머 리셋만 수행됨)
}
```

### 7.4 연결 종료

**서버 측 (server_obj.close)**:
1. `keepalive_timer.Dispose()`
2. `_stream.Close()`
3. `_remote_tcp.Close()`
4. `disconnect_sent = true` (중복 방지)
5. `_rx_str(this, new DisconnectRequest())` → 앱에 통지
6. `closed(this)` → 서버의 `nc_closed` 호출

**클라이언트 측 (client_obj.close)**:
1. `_isClosing = true` (volatile, Monitor lock)
2. `keepalive_timer` 중지 및 Dispose
3. `_stream.Close()` + `_stream.Dispose()`
4. `remote_tcp.Close()`
5. 참조 null 처리

---

## 8. 핵심 데이터 구조

### 8.1 GameInfoResponse (75+ 필드)

테이블의 완전한 상태를 나타내는 가장 큰 프로토콜 메시지.

| 카테고리 | 필드명 | 타입 | 설명 |
|---------|--------|------|------|
| **블라인드** | Ante, Small, Big, Third | int | 블라인드 구조 |
| | ButtonBlind, BringIn | int | 특수 블라인드 |
| | BlindLevel, NumBlinds | int | 블라인드 레벨 |
| **좌석 위치** | PlDealer, PlSmall, PlBig, PlThird | int | 딜러/블라인드 좌석 |
| | ActionOn, NumSeats, NumActivePlayers | int | 현재 액션/좌석 |
| **베팅** | BiggestBet, SmallestChip | int | 베팅 정보 |
| | BetStructure, Cap, MinRaiseAmt | int | 베팅 구조 |
| | PredictiveBet | bool | 예측 베팅 모드 |
| **게임 타입** | GameClass, GameType, GameVariant | int/string | 게임 분류 |
| | GameTitle | string | 표시 이름 |
| **보드** | OldBoardCards, CardsOnTable | string/bool | 보드 카드 |
| | NumBoards, CardsPerPlayer, ExtraCardsPerPlayer | int | 카드 수 |
| **상태** | HandInProgress, EnhMode | bool | 진행/모드 |
| | GfxEnabled, Streaming, Recording | bool | 출력 상태 |
| | ProVersion, NextHandOk | bool | 라이선스/제어 |
| **디스플레이** | ShowPanel, StripDisplay, TickerVisible | int/bool | UI 제어 |
| | FieldVisible, FieldRemain, FieldTotal | bool/int | 필드 정보 |
| | PlayerPicW, PlayerPicH | int | 사진 크기 |
| **특수** | RunItTimes, RunItTimesRemaining | int | Run It Twice |
| | BombPot, SevenDeude | int | 특수 핸드 |
| | CanChop, IsChopped | bool | 팟 분할 |
| | CardVerifyMode, CardVerifyList | bool/string | 카드 검증 |
| | HandTag, HandCount | string/int | 핸드 추적 |
| | Payout, RegStr | string | 지급/등록 |
| **드로우** | DrawCompleted, DrawingPlayer | int | 드로우 게임 |
| | StudDrawInProgress, StudCommunityCard | bool | Stud 게임 |
| | StartHandStud, FinalBettingRound | bool | Stud 단계 |
| | LowLimit, HighLimit | int | 리밋 구조 |
| | AnteType | int | 안테 유형 |
| | CanSelectRunItTimes, CanTriggerNextBoard | bool | UI 제어 |
| | CardRescan | bool | 카드 재스캔 |

### 8.2 PlayerInfoResponse (20 필드)

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
| **통계** | | |
| Vpip | int | VPIP (자발적 팟 참여율) |
| Pfr | int | PFR (프리플롭 레이즈) |
| Agr | int | AGR (공격성) |
| Wtsd | int | WTSD (쇼다운 진행률) |
| CumWin | int | 누적 수익 |

### 8.3 IClientNetworkListener (16 콜백)

```csharp
public interface IClientNetworkListener {
    void NetworkQualityChanged(NetworkQuality quality);
    void OnConnected(client_obj netClient, ConnectResponse cmd);
    void OnDisconnected(DisconnectResponse cmd);
    void OnAuthReceived(AuthResponse cmd);
    void OnReaderStatusReceived(ReaderStatusResponse cmd);
    void OnHeartBeatReceived(HeartBeatResponse cmd);
    void OnDelayedGameInfoReceived(DelayedGameInfoResponse cmd);
    void OnGameInfoReceived(GameInfoResponse cmd);
    void OnMediaListReceived(MediaListResponse cmd);
    void OnCountryListReceived(CountryListResponse cmd);
    void OnPlayerPictureReceived(PlayerPictureResponse cmd);
    void OnGameVariantListReceived(GameVariantListResponse cmd);
    void OnPlayerInfoReceived(PlayerInfoResponse cmd);
    void OnDelayedPlayerInfoReceived(DelayedPlayerInfoResponse cmd);
    void OnVideoSourcesReceived(VideoSourcesResponse cmd);
    void OnSourceModeReceived(SourceModeResponse cmd);
}
```

---

## 9. 보안 취약점

### 9.1 하드코딩된 암호화 키

| 취약점 | 심각도 | 상세 |
|--------|--------|------|
| 고정 Password | **Critical** | `"45389rgjkonlgfds90439r043rtjfewp9042390j4f"` - 바이너리에 평문 |
| 고정 Salt | **Critical** | `"dsafgfdagtds4389tytgh"` - 바이너리에 평문 |
| 고정 IV | **Critical** | `"4390fjrfvfji9043"` - 모든 메시지에 동일 IV 사용 |
| PBKDF1 | **High** | `PasswordDeriveBytes`는 PBKDF1 (deprecated), iteration 미지정 |

**영향**: 바이너리에서 키 자료를 추출하면 모든 통신을 복호화할 수 있다.

### 9.2 프로토콜 취약점

| 취약점 | 심각도 | 상세 |
|--------|--------|------|
| CBC without HMAC | **High** | 메시지 무결성 검증 없음 → Padding Oracle 공격 가능 |
| 동일 IV | **High** | 모든 메시지에 동일 IV → CBC의 보안 보장 무력화 |
| 인증 후 암호화 | **Medium** | `AUTH` 명령도 암호화되지만, 인증 전에도 메시지 수신 가능 |
| 라이선스 평문 | **Medium** | `ConnectResponse.License`가 ulong으로 평문 전달 |
| 네트워크 발견 | **Low** | UDP 브로드캐스트로 서버 위치 노출 |
| Keepalive DoS | **Low** | 유효하지 않은 연결으로 서버 리소스 소진 가능 |

### 9.3 복호화 키 재구성

바이너리에서 추출한 정보로 AES 키를 완전히 재구성할 수 있다:

```python
# Python 재현 (암호화 키 유도)
from Crypto.Protocol.KDF import PBKDF1
import hashlib

password = b"45389rgjkonlgfds90439r043rtjfewp9042390j4f"
salt = b"dsafgfdagtds4389tytgh"

# .NET PasswordDeriveBytes는 PBKDF1 기반
# 기본 iteration: 100, hash: SHA1
key = PBKDF1(password, salt, dkLen=32, count=100, hashAlgo=hashlib.sha1)
iv = b"4390fjrfvfji9043"  # 16 bytes

# 이 key와 iv로 AES-256-CBC 복호화 가능
```

---

## 부록: 프로토콜 타임라인 다이어그램

### 일반적인 세션 흐름

```
Client (Remote)                           Server (VPT)
     │                                        │
     │──── UDP Broadcast (id_tx) ────────────►│ :9000
     │◄──── UDP Response (id_tx) ─────────────│
     │                                        │
     │════ TCP Connect ══════════════════════►│ :9001
     │                                        │
     │◄──── ConnectResponse(License=0x...) ───│  ← 즉시
     │◄──── IdtxResponse(IdTx="...") ─────────│  ← 즉시
     │                                        │
     │──── IdtxRequest(IdTx="...") ──────────►│  ← ID 교환
     │──── ConnectRequest ──────────────────►│  ← 연결 완료 신호
     │                                        │
     │──── AuthRequest(Password,Version) ───►│  ← 인증
     │◄──── AuthResponse ─────────────────────│
     │                                        │
     │◄──── GameStateResponse(HOLDEM,true) ───│  ← 초기 동기화
     │◄──── GameInfoResponse(75+ fields) ─────│  ← 전체 상태
     │◄──── PlayerInfoResponse × N ───────────│  ← 각 플레이어
     │◄──── PlayerCardsResponse × N ──────────│  ← 각 홀카드
     │                                        │
     │ ─ ─ ─ KeepAlive (3초 간격) ─ ─ ─ ─ ─►│
     │                                        │
     │◄──── [실시간 업데이트 스트림] ──────────│
     │      GameInfoResponse (변경시)          │
     │      PlayerInfoResponse (변경시)        │
     │      BoardCardResponse (보드 변경)       │
     │      PlayerCardsResponse (카드 공개)     │
     │                                        │
     │──── DisconnectRequest ────────────────►│
     │◄──── DisconnectResponse ───────────────│
     │════ TCP Close ════════════════════════║│
```
