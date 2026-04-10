# PokerGFX 보조 모듈 심층 분석

## 개요

| 모듈 | 파일 수 | 크기 | 역할 | 핵심 기술 |
|------|---------|------|------|----------|
| **analytics.dll** | 7 types | 23KB | 텔레메트리/모니터링 | SQLite store-and-forward, AWS S3 |
| **RFIDv2.dll** | 26 types | 57KB | RFID 카드 리더 통신 | TCP/WiFi + USB HID, BearSSL TLS |
| **boarssl.dll** | 102 types | 207KB | TLS 암호화 라이브러리 | TLS 1.0-1.2, ChaCha20, ECDSA, AES |

---

## 1. analytics.dll (텔레메트리 시스템)

### 1.1 아키텍처

```
AnalyticsService (Singleton)
    ├── SQLiteAnalyticsStore (로컬 큐)
    │   └── analytics.db (SQLite)
    ├── HttpClient → https://api.pokergfx.io
    │   └── ProcessQueueLoop (백그라운드 업로드)
    └── AnalyticsScreenshots
        ├── Timer (15분 간격)
        └── AWS S3 업로드
```

### 1.2 AnalyticsService (Singleton)

**필드 구조:**
| 필드 | 타입 | 설명 |
|------|------|------|
| `_instance` | static AnalyticsService | Singleton 인스턴스 |
| `BaseUrl` | static string | `"https://api.pokergfx.io"` |
| `_version` | string | 애플리케이션 버전 |
| `_licenseNumber` | ulong | 라이선스 번호 (텔레메트리 키) |
| `_store` | SQLiteAnalyticsStore | 로컬 SQLite 큐 |
| `_client` | HttpClient | HTTP 업로드 클라이언트 |
| `_cts` | CancellationTokenSource | 백그라운드 태스크 취소 |
| `_flushInterval` | TimeSpan | 큐 flush 간격 |
| `_batchSize` | int | 배치 크기 |
| `_backgroundTask` | Task | ProcessQueueLoop 태스크 |

**Initialize 메서드:**
```csharp
void Initialize(ulong licenseNumber, string version, string databaseLocation,
                int timeBetweenSentInSeconds, int batchSize)
{
    // Singleton 체크
    if (_instance != null) { Console.WriteLine("Already initialized"); return; }
    _instance = new AnalyticsService();
    _instance._flushInterval = TimeSpan.FromSeconds(timeBetweenSentInSeconds);
    _instance._batchSize = batchSize;
    _instance._store = new SQLiteAnalyticsStore(databaseLocation);
    _instance._store.Initialize();
    _instance._client = new HttpClient { BaseAddress = new Uri("https://api.pokergfx.io") };
    _instance._client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    _instance._cts = new CancellationTokenSource();
    _instance._backgroundTask = Task.Run(ProcessQueueLoop);
    AppDomain.CurrentDomain.ProcessExit += (s,e) => { /* cleanup */ };
}
```

### 1.3 추적 이벤트 타입

| 메서드 | Type 필드 | 용도 |
|--------|-----------|------|
| `TrackFeature(name, data)` | `"feature"` | 기능 사용 추적 |
| `TrackClick(buttonName, data)` | `"click"` | 버튼 클릭 추적 |
| `TrackSession(name, isStart, data)` | `"session"` | Session_Start / Session_End |
| `TrackDuration(name, duration, data)` | `"duration"` | 작업 소요 시간 (ms) |
| `Track(AnalyticsData)` | (가변) | 일반 추적 |

**세션 추적 상세:**
- `isStart=true` → Name = `"Session_Start"`, UTC 시각 ISO 8601 ("o" 포맷)
- `isStart=false` → Name = `"Session_End"`, UTC 시각 ISO 8601

### 1.4 데이터 흐름 (Store-and-Forward)

```
Track() 호출
  → _Enqueue(): licenseNumber 검증 → payload에 Version/LicenseNum 설정 → SQLite Enqueue
  → ProcessQueueLoop (백그라운드):
      while (!cancelled)
          await Task.Delay(_flushInterval)
          await FlushQueueOnce()
              → store.Dequeue(_batchSize)
              → HttpClient.POST("https://api.pokergfx.io", JSON)
              → 성공 시 큐에서 제거
  → Dispose: Cancel + WaitAny(task, 5초 타임아웃) + HttpClient.Dispose
```

### 1.5 AnalyticsScreenshots

**필드 구조:**
| 필드 | 타입 | 설명 |
|------|------|------|
| `_screenshotTimer` | static Timer | 15분 타이머 (900,000ms) |
| `_store` | SQLiteAnalyticsStore | 메타데이터 저장 |
| `save_path` | string | `Environment.SpecialFolder(35) + "RFID-VPT"` |
| `BucketName` | static string | AWS S3 버킷 |
| `KeyPrefix` | static string | S3 키 prefix |
| `AwsAccessKey` | static string | AWS Access Key (하드코딩) |
| `AwsSecretKey` | static string | AWS Secret Key (하드코딩) |
| `EncryptionKey` | string | 파일 암호화 키 |
| `LicenseNumber` | ulong | 라이선스 번호 |
| `CustomerID` | int | 고객 ID |
| `ScreenshotsEnabled` | bool | 기본값: true |
| `RequestScreenCapture` | Func<string, Task<bool>> | 캡처 요청 delegate |

**타이머 설정:**
- 간격: **900,000ms (15분)**
- AutoReset: true (반복)
- 시작 시 즉시 1회 캡처 (`CaptureScreenshotAsync()`)

**파일명 생성:**
```csharp
string GenerateFilename(string timestamp, int custID, ulong licenseNumber)
    → "{timestamp}_{custID}_{licenseNumber}"
```

**스크린샷 폴더:** `{save_path}/datas`

**암호화:** `EncryptFile(inputFilePath, outputFilePath)` → 현재 `return false` (stub)

**S3 업로드:** `UploadToS3(filePath, filename)` → async, AWS SDK 사용

### 1.6 SQLiteAnalyticsStore

- DB 경로: `{save_path}/analytics.db`
- `Initialize()`: 테이블 생성
- `Enqueue(payload)`: 큐에 추가
- `Dequeue(batchSize)`: 배치 조회

### 1.7 AnalyticsPayload / AnalyticsData

**AnalyticsPayload:**
- Type (string): "feature", "click", "session", "duration"
- Name (string): 이벤트 이름
- Data (IEnumerable<AnalyticsKeyValue>): 키-값 쌍
- Version (string): 앱 버전
- LicenseNum (ulong): 라이선스 번호

**AnalyticsKeyValue:**
- Name (string)
- Value (string)

### 1.8 보안 취약점

| 심각도 | 취약점 | 세부 |
|--------|--------|------|
| **CRITICAL** | AWS 키 하드코딩 | `AwsAccessKey`, `AwsSecretKey` 정적 필드 |
| **HIGH** | API 인증 없음 | LicenseNum만으로 식별 (토큰/API 키 없음) |
| **MEDIUM** | 암호화 미구현 | `EncryptFile` → `return false` (stub) |
| **LOW** | 평문 SQLite | 로컬 분석 데이터 암호화 없음 |

---

## 2. RFIDv2.dll (RFID 카드 리더)

### 2.1 듀얼 트랜스포트 아키텍처

```
reader_module (통합 관리)
    ├── skye_module (SkyeTek 구형)
    │   └── USB HID only
    └── v2_module (Rev2 신형)
        ├── TCP/WiFi (네트워크)
        │   └── BearSSL TLS 1.2
        └── USB (폴백)
```

### 2.2 Enum 정의

**module_type:**
| 값 | 이름 | 설명 |
|----|------|------|
| 0 | skyetek | SkyeTek 구형 리더 |
| 1 | v2 | Rev2 신형 리더 |

**connection_type:**
| 값 | 이름 | 설명 |
|----|------|------|
| 0 | usb | USB HID 연결 |
| 1 | wifi | WiFi/TCP 연결 |

**reader_state:**
| 값 | 이름 | 설명 |
|----|------|------|
| 0 | disconnected | 연결 해제 |
| 1 | connected | TCP 연결됨 |
| 2 | negotiating | TLS 핸드셰이크 중 |
| 3 | ok | 정상 동작 |

**wlan_state:**
| 값 | 이름 | 설명 |
|----|------|------|
| 0 | off | WiFi 꺼짐 |
| 1 | on | WiFi 켜짐 |
| 2 | connected_reset | 연결 후 리셋 |
| 3 | ip_acquired | IP 획득 완료 |
| 4 | not_installed | WiFi 미설치 |

### 2.3 v2_module 핵심 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `on_tag_event` | tag_event_delegate | 카드 감지 콜백 |
| `on_calibrate` | calibrate_delegate | 칼리브레이션 콜백 |
| `on_state_changed` | state_changed_delegate | 상태 변경 콜백 |
| `on_firmware_update_event` | firmware_update_delegate | 펌웨어 업데이트 콜백 |
| `BASE32` | List<char> | Base32 인코딩 문자셋 |
| `KEEPALIVE_INTERVAL` | static int | Keepalive 간격 |
| `NEGOTIATE_INTERVAL` | static int | 협상 타임아웃 |
| `HW_REV` | protected int | 하드웨어 리비전 |
| `_antenna` | protected byte | 현재 안테나 번호 |
| `_tag_type` | protected int | 태그 타입 |
| `_config` | protected config_type | 설정 타입 |
| `_firmware_version` | protected int | 펌웨어 버전 |
| `_state` | reader_state | 현재 상태 |
| `_pwd` | internal string | 인증 비밀번호 |
| `_pubkey` | internal byte[] | 공개키 (ED25519 추정) |
| `ms` | module_stream | 통신 스트림 |
| `cs` | Stream | 암호화 스트림 (TLS) |
| `tls_session_parameters` | SSLSessionParameters | TLS 세션 재개용 |
| `tag_list` | List<List<tag>> | 안테나별 태그 목록 |
| `init_done_event` | AutoResetEvent | 초기화 완료 이벤트 |

**하드웨어 리비전별 안테나:**

| 리비전 | 물리 안테나 | 가상 안테나 | 기본 칼리브레이션 맵 |
|--------|-----------|-----------|---------------------|
| Rev1 | REV1_MAX_PHYS_ANTENNAS | REV1_MAX_VIRT_ANTENNAS | REV1_DEFAULT_CAL_MAP |
| Rev2 | REV2_MAX_PHYS_ANTENNAS | REV2_MAX_VIRT_ANTENNAS | REV2_DEFAULT_CAL_MAP |

### 2.4 텍스트 명령 프로토콜 (22개)

리더와 ASCII 텍스트 기반으로 통신:

| 명령 코드 | 기능 | 방향 |
|-----------|------|------|
| 01 | 상태 조회 | → Reader |
| 02 | 버전 조회 | → Reader |
| 03 | 설정 조회 | → Reader |
| 08 | 안테나 선택 | → Reader |
| 09 | 안테나 상태 | ← Reader |
| 0A | 카드 읽기 | → Reader |
| 0B | 카드 쓰기 | → Reader |
| 0C | 칼리브레이션 시작 | → Reader |
| 0D | 칼리브레이션 결과 | ← Reader |
| 20 | WiFi SSID 설정 | → Reader |
| 21 | WiFi 비밀번호 설정 | → Reader |
| 22 | WiFi 연결 | → Reader |
| 23 | WiFi 해제 | → Reader |
| 24 | WiFi 상태 조회 | → Reader |
| 25 | WiFi IP 조회 | → Reader |
| 26 | WiFi 스캔 | → Reader |

### 2.5 TLS 인증 흐름

```
1. TCP 연결 (WiFi 또는 유선)
   → reader_state.connected
2. TLS 핸드셰이크 (BearSSL)
   → reader_state.negotiating
   → Password (_pwd) + Public key (_pubkey) 인증
   → SSLSessionParameters 저장 (세션 재개 지원)
3. 정상 동작
   → reader_state.ok
4. Keepalive 유지
   → keepalive_timer (KEEPALIVE_INTERVAL 간격)
```

### 2.6 tag / tag_info

**tag 클래스:**
- UID, 카드 데이터
- 안테나 위치 정보

**tag_info:**
- 태그 상세 메타데이터

**TagEventTelemetry:**
- 진단 데이터 (이벤트 타입, 타임스탬프)

### 2.7 네트워크 인프라 (net.cs, client_obj.cs)

**state 클래스:**
- `buff`: byte[1000] 수신 버퍼
- `stream`: NetworkStream

**client_obj:** TCP 클라이언트 래퍼

### 2.8 보안 이슈

| 심각도 | 취약점 | 세부 |
|--------|--------|------|
| **HIGH** | WiFi 비밀번호 평문 | 명령 21로 평문 전송 |
| **HIGH** | 펌웨어 서명 없음 | firmware_update에 검증 로직 미확인 |
| **MEDIUM** | UDP discovery 스푸핑 | 브로드캐스트 기반 발견 |
| **LOW** | Base32 UID 인코딩 | 예측 가능한 패턴 |

---

## 3. boarssl.dll (BearSSL TLS 구현)

### 3.1 아키텍처

BearSSL C 라이브러리의 C# 포팅. RFID 리더와의 TLS 통신에 사용.

```
boarssl.dll (207KB, 102 types)
├── SSLTLS/           # TLS 프로토콜 엔진
│   ├── SSLEngine.cs  # 핵심 TLS 상태 머신
│   ├── SSLClient.cs  # 클라이언트 구현
│   ├── SSLServer.cs  # 서버 구현
│   ├── SSL.cs        # 프로토콜 상수
│   ├── InputRecord/OutputRecord  # 레코드 I/O
│   └── RecordEncrypt*/RecordDecrypt*  # 암호화/복호화
├── Crypto/           # 암호화 알고리즘
│   ├── AES.cs, DES.cs  # 블록 암호
│   ├── ChaCha20.cs     # 스트림 암호
│   ├── Poly1305.cs     # MAC
│   ├── GHASH.cs        # GCM MAC
│   ├── RSA.cs, ECDSA.cs  # 비대칭
│   ├── EC.cs, ECCurve*.cs  # 타원 곡선
│   ├── SHA*.cs, MD5.cs  # 해시
│   └── HMAC.cs, HMAC_DRBG.cs  # MAC/RNG
├── Asn1/             # ASN.1 파서
├── X500/             # X.500 이름
├── XKeys/            # 키 파서
└── _global/          # 유틸리티
```

### 3.2 TLS 프로토콜 상수 (SSL.cs)

**지원 버전:**
| 상수 | 프로토콜 |
|------|----------|
| `SSL30` | SSL 3.0 (deprecated) |
| `TLS10` | TLS 1.0 |
| `TLS11` | TLS 1.1 |
| `TLS12` | TLS 1.2 |

**레코드 타입:**
- `CHANGE_CIPHER_SPEC` (20)
- `ALERT` (21)
- `HANDSHAKE` (22)
- `APPLICATION_DATA` (23)

**핸드셰이크 메시지:**
- `HELLO_REQUEST`, `CLIENT_HELLO`, `SERVER_HELLO`
- `CERTIFICATE`, `SERVER_KEY_EXCHANGE`, `CERTIFICATE_REQUEST`
- `SERVER_HELLO_DONE`, `CERTIFICATE_VERIFY`
- `CLIENT_KEY_EXCHANGE`, `FINISHED`

**Alert 코드:** CLOSE_NOTIFY, UNEXPECTED_MESSAGE, BAD_RECORD_MAC, HANDSHAKE_FAILURE 등 17개

### 3.3 Cipher Suites

**RSA 기반:**
- `RSA_WITH_NULL_MD5/SHA/SHA256`
- `RSA_WITH_RC4_128_MD5/SHA`
- `RSA_WITH_3DES_EDE_CBC_SHA`
- `RSA_WITH_AES_128_CBC_SHA/SHA256`
- `RSA_WITH_AES_256_CBC_SHA/SHA256`

**DH/ECDH 기반:**
- `DH_DSS/RSA_WITH_3DES_EDE_CBC_SHA`
- `DH_DSS/RSA_WITH_AES_128/256_CBC_SHA/SHA256`
- `ECDH_ECDSA/RSA_WITH_AES_128/256_CBC_SHA/SHA256`
- `ECDHE_ECDSA/RSA_WITH_AES_128/256_CBC_SHA/SHA256/GCM_SHA256/SHA384`

**ChaCha20 기반:**
- `ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256`
- `ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256`

### 3.4 암호화 구현

**레코드 암호화 클래스:**

| 클래스 | 알고리즘 | 용도 |
|--------|----------|------|
| `RecordEncryptPlain` | 없음 | 평문 (핸드셰이크 초기) |
| `RecordEncryptCBC` | AES-CBC + HMAC | 레거시 TLS |
| `RecordEncryptGCM` | AES-GCM | 현대 TLS |
| `RecordEncryptChaPol` | ChaCha20-Poly1305 | AEAD |
| `RecordDecryptPlain` | 없음 | 평문 |
| `RecordDecryptCBC` | AES-CBC + HMAC | 레거시 |
| `RecordDecryptGCM` | AES-GCM | 현대 |
| `RecordDecryptChaPol` | ChaCha20-Poly1305 | AEAD |

**블록 암호:**
- `AES.cs`: AES-128/192/256
- `DES.cs`: 3DES-EDE (레거시)
- `BlockCipherCore.cs`: 공통 인터페이스

**스트림 암호:**
- `ChaCha20.cs`: ChaCha20 스트림 암호
- `Poly1305.cs`: Poly1305 MAC

**해시:**
- `MD5.cs`: MD5 (레거시)
- `SHA1.cs`: SHA-1 (레거시)
- `SHA2Small.cs` → `SHA224.cs`, `SHA256.cs`
- `SHA2Big.cs` → `SHA384.cs`, `SHA512.cs`

**비대칭 암호:**
- `RSA.cs`, `RSAPublicKey.cs`, `RSAPrivateKey.cs`
- `ECDSA.cs`, `ECPublicKey.cs`, `ECPrivateKey.cs`
- `DSAUtils.cs`: DSA 유틸리티

**타원 곡선:**
- `EC.cs`: 타원 곡선 핵심
- `ECCurve.cs`: 추상 커브
- `ECCurvePrime.cs`: NIST P-256/P-384/P-521
- `ECCurve25519.cs`: Curve25519
- `ECCurveType.cs`: 커브 타입 enum
- `MutableECPoint*.cs`: 가변 EC 포인트 연산
- `NIST.cs`: NIST 표준 커브 상수

**기타:**
- `HMAC.cs`: HMAC 구현
- `HMAC_DRBG.cs`: 결정론적 난수 (RFC 6979)
- `RFC6979.cs`: 결정론적 ECDSA nonce
- `GHASH.cs`: GCM용 Galois Hash
- `BigInt.cs`, `ModInt.cs`: 큰 정수/모듈러 산술
- `RNG.cs`: 난수 생성기

### 3.5 TLS 세션 관리

**SSLSessionParameters:**
- 세션 ID, 마스터 시크릿
- 협상된 cipher suite
- RFIDv2의 `tls_session_parameters` 필드에 저장 (세션 재개)

**SSLSessionCacheLRU:**
- LRU 캐시 기반 세션 저장

**PRF (Pseudo-Random Function):**
- `PRF.cs`: TLS PRF 구현 (키 도출)

### 3.6 인증서 처리

**ASN.1 파서:**
- `AsnElt.cs`: ASN.1 요소 파싱
- `AsnIO.cs`: ASN.1 I/O
- `AsnOID.cs`: OID 매핑
- `PEMObject.cs`: PEM 포맷 파싱

**X.500 이름:**
- `X500Name.cs`: Distinguished Name 파싱
- `DNPart.cs`: DN 구성 요소

**인증서 검증:**
- `CertValidator.cs`: 인증서 체인 검증
- `InsecureCertValidator`(!) -- 모든 인증서 수락 (MITM 취약)

**키 파서:**
- `XKeys/KF.cs`: 키 포맷 파서 (PEM/DER)

### 3.7 보안 이슈

| 심각도 | 취약점 | 세부 |
|--------|--------|------|
| **CRITICAL** | InsecureCertValidator | 인증서 검증 우회 (MITM 가능) |
| **HIGH** | TLS 1.0/1.1 지원 | POODLE, BEAST 취약점 |
| **MEDIUM** | RC4 cipher suite | RC4 bias 공격 |
| **MEDIUM** | 3DES cipher suite | Sweet32 공격 |
| **LOW** | SSL 3.0 상수 존재 | 사용 여부 불명 |

---

## 4. 모듈 간 통합 시나리오

### 4.1 RFID 카드 읽기 (TLS 암호화)

```
[vpt_server] main_form
    │
    ├── [RFIDv2] reader_module.start()
    │       │
    │       ├── v2_module: TCP 연결 (WiFi)
    │       │       │
    │       │       └── [boarssl] SSLClient: TLS 1.2 핸드셰이크
    │       │               ├── Password + ED25519 공개키 인증
    │       │               ├── ECDHE_ECDSA_WITH_AES_128_GCM (추정)
    │       │               └── 세션 파라미터 캐시
    │       │
    │       ├── 카드 감지: tx("0A" + antenna)
    │       │       └── [boarssl] RecordEncryptGCM → TLS record
    │       │
    │       └── 응답 수신: rx()
    │               └── [boarssl] RecordDecryptGCM → 평문
    │
    ├── on_tag_event 콜백 → main_form 처리
    │
    └── [analytics] AnalyticsService.TrackFeature("card_read", data)
            └── SQLiteAnalyticsStore.Enqueue()
                    └── ProcessQueueLoop → POST https://api.pokergfx.io
```

### 4.2 스크린샷 캡처 사이클

```
AnalyticsScreenshots
    │
    ├── Timer (15분) → CaptureScreenshotAsync()
    │       │
    │       ├── RequestScreenCapture delegate 호출
    │       │       └── main_form에서 스크린 캡처
    │       │
    │       ├── GenerateFilename("{timestamp}_{custID}_{license}")
    │       │
    │       ├── EncryptFile() → return false (미구현)
    │       │
    │       └── UploadToS3(filePath, filename)
    │               └── AWS SDK: S3.PutObject(BucketName, KeyPrefix/filename)
    │
    └── 결과 → _store (SQLite 로깅)
```

---

## 5. 디컴파일 파일 목록

### analytics/ (7 files)
```
analytics/
├── analytics/
│   ├── AnalyticsService.cs       # Singleton 텔레메트리 서비스 (365줄)
│   ├── AnalyticsScreenshots.cs   # 스크린샷 캡처/S3 업로드 (295줄)
│   ├── AnalyticsData.cs          # 데이터 모델
│   ├── AnalyticsKeyValue.cs      # 키-값 쌍
│   ├── AnalyticsPayload.cs       # 업로드 페이로드
│   └── SQLiteAnalyticsStore.cs   # SQLite 큐
└── _global/
    └── QueueItem.cs              # 큐 아이템
```

### RFIDv2/ (26 files)
```
RFIDv2/
├── RFIDv2/
│   ├── v2_module.cs              # Rev2 리더 (핵심)
│   ├── skye_module.cs            # SkyeTek 리더
│   ├── reader_module.cs          # 통합 관리자
│   ├── modules.cs                # 모듈 팩토리
│   ├── module_stream.cs          # 통신 스트림
│   ├── net.cs                    # TCP 네트워크
│   ├── client_obj.cs             # TCP 클라이언트
│   ├── _config_net.cs            # 네트워크 설정
│   ├── poll_node.cs              # 폴링 노드
│   ├── tag.cs                    # 태그 데이터
│   ├── tag_info.cs               # 태그 메타데이터
│   ├── reader_state.cs           # 상태 enum
│   ├── connection_type.cs        # 연결 타입 enum
│   ├── module_type.cs            # 모듈 타입 enum
│   ├── wlan_state.cs             # WiFi 상태 enum
│   ├── rx_delegate.cs            # 수신 delegate
│   ├── rx_type.cs                # 수신 타입
│   ├── tag_event_delegate.cs     # 태그 이벤트 delegate
│   ├── calibrate_delegate.cs     # 칼리브레이션 delegate
│   ├── state_changed_delegate.cs # 상태 변경 delegate
│   ├── firmware_update_delegate.cs # 펌웨어 delegate
│   └── Diagnostics/
│       └── TagEventTelemetry.cs  # 진단
├── _global/
│   ├── transport_event_type.cs
│   ├── transport_event_delegate.cs
│   ├── config_type.cs
│   └── state.cs                  # 네트워크 state (1000바이트 버퍼)
```

### boarssl/ (102 files)
```
boarssl/
├── SSLTLS/     (33 files) - TLS 프로토콜 엔진
├── Crypto/     (37 files) - 암호화 알고리즘
├── Asn1/       (5 files)  - ASN.1 파서
├── X500/       (2 files)  - X.500 이름
├── XKeys/      (1 file)   - 키 파서
└── _global/    (24 files) - 유틸리티 + 정적 배열
```
