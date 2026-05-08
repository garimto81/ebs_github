---
title: CR-team4-20260410-api05-messagepack
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-api05-messagepack
---

# CCR-DRAFT: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/api/`WebSocket_Events.md` (legacy-id: API-05)
- **변경 유형**: modify
- **변경 근거**: 현재 API-05는 모든 WebSocket 메시지를 **JSON envelope** 형식으로 정의한다. 그러나 WSOP LIVE 프로덕션 앱(Fatima.app)은 **SignalR + MessagePack**을 사용하여 PayLoad를 30~50% 압축하고 있다(출처: `wsoplive/.../Mobile-Dev/자료조사/Flutter(Riverpod) + SignalR(MessagePack) 연동.md`). EBS가 JSON을 고수하면 (1) 초당 수십 이벤트 발생 시 대역폭 부담, (2) 조직 내 검증된 MessagePack 라이브러리 Fork 자산 재사용 실패, (3) 향후 WSOP+ 통합 시 프로토콜 변환 레이어 필요라는 비용이 발생한다. 본 CCR은 SignalR 전환까지는 가지 않더라도 **JSON의 대안으로 MessagePack 직렬화를 선택 가능하게** 만드는 최소 변경을 제안한다 (Option C: MessagePack 채택, SignalR 미채택 타협안).

## 변경 요약

API-05에 **직렬화 협상(Serialization Negotiation)** 메커니즘 추가:

1. **§직렬화 협상**: WebSocket 연결 시 JSON / MessagePack 중 선택
2. **§MessagePack 스키마**: 기존 JSON envelope을 MessagePack 바이너리로 1:1 매핑
3. **§Team 2 서버 구현**: FastAPI `websockets` 라이브러리에서 MessagePack 지원
4. **§클라이언트 구현**: Flutter `messagepack` 패키지, JS `@msgpack/msgpack`
5. **§Fallback 정책**: MessagePack 실패 시 JSON으로 자동 downgrade

**중요**: 본 CCR은 **SignalR로의 전환은 요구하지 않는다**. 현행 WebSocket 프로토콜을 유지하면서 payload 직렬화만 선택 가능하게 만든다. 이전 critic 분석에서 제시한 Option C (MessagePack만 채택) 전략.

## 변경 내용

### 1. API-05 §직렬화 협상 (신규 섹션)

```markdown
## 직렬화 협상

### 배경

초당 수십 이벤트가 발생하는 라이브 방송 환경에서 JSON payload의 **메타데이터 오버헤드**(key 이름, 공백, 콤마)는 대역폭에 부담을 준다. MessagePack은 동일 데이터를 평균 30~50% 작게 직렬화하며, WSOP LIVE Fatima.app이 프로덕션 운영 중이다.

EBS는 **JSON과 MessagePack을 모두 지원**하며, 연결 시 클라이언트가 선호하는 포맷을 선언한다.

### 연결 시 협상

WebSocket URL query param에 `format` 추가:

| 연결 | URL |
|------|-----|
| CC → BO (JSON) | `ws://{host}/ws/cc?table_id={id}&token={t}&format=json` |
| CC → BO (MessagePack) | `ws://{host}/ws/cc?table_id={id}&token={t}&format=msgpack` |
| Lobby → BO (JSON) | `ws://{host}/ws/lobby?token={t}&format=json` |
| Lobby → BO (MessagePack) | `ws://{host}/ws/lobby?token={t}&format=msgpack` |

**기본값**: `format` 생략 시 `json`. 이는 기존 클라이언트와의 하위 호환성 보장.

### 협상 검증

- BO는 클라이언트 요청한 `format`을 지원하는지 확인
- 지원: WebSocket Upgrade 완료, 이후 모든 메시지는 해당 포맷
- 미지원: WebSocket handshake 거부 (HTTP 406 Not Acceptable)
- BO 초기 구현: JSON만 지원 가능. MessagePack은 Phase 2에서 활성화.

### 혼합 금지

한 연결 내에서 format 전환 불가. 전환이 필요하면 연결 재수립.
```

### 2. API-05 §MessagePack 스키마 (신규 섹션)

```markdown
## MessagePack 스키마

### 매핑 원칙

기존 JSON envelope:

```json
{
  "type": "HandStarted",
  "payload": { "hand_id": 42, "table_id": 5, ... },
  "timestamp": "2026-04-08T14:30:00.123Z",
  "source_id": "cc-table-5",
  "message_id": "msg-uuid-1234"
}
```

MessagePack 바이너리:

```
fixmap 5 elements
  fixstr "type" → fixstr "HandStarted"
  fixstr "payload" → fixmap N elements (payload fields)
  fixstr "timestamp" → fixstr "2026-04-08T14:30:00.123Z"
  fixstr "source_id" → fixstr "cc-table-5"
  fixstr "message_id" → fixstr "msg-uuid-1234"
```

- 필드 이름과 값은 JSON과 **1:1 동일**
- MessagePack 바이너리 크기는 JSON 대비 평균 30~50% 감소 (필드 이름이 짧은 경우)

### 타입 매핑

| JSON 타입 | MessagePack 타입 |
|----------|-----------------|
| string | fixstr / str8 / str16 / str32 |
| int | positive/negative fixint / int8~64 |
| float | float32 / float64 |
| boolean | true / false |
| null | nil |
| object | fixmap / map16 / map32 |
| array | fixarray / array16 / array32 |

### 특수 케이스

- **Timestamp**: 문자열(ISO 8601)로 유지. MessagePack extension type 미사용 (상호 운용성 우선).
- **UUID**: 문자열로 유지.
- **Binary data** (향후 image/file): MessagePack bin8/16/32 사용.

### 검증 방법

- Python: `msgpack` 라이브러리 (FastAPI 통합)
- Dart: `messagepack` 패키지
- JavaScript: `@msgpack/msgpack` 패키지
- 각 클라이언트의 직렬화 결과가 상호 decode 가능한지 Cross-compat 테스트 필수
```

### 3. API-05 §서버 구현 (신규 섹션)

```markdown
## 서버 구현 (Team 2 FastAPI)

### 의존성

```python
# requirements.txt
msgpack==1.0.7
```

### WebSocket 핸들러

```python
from fastapi import WebSocket, Query
import msgpack
import json

@app.websocket("/ws/cc")
async def ws_cc(
    websocket: WebSocket,
    table_id: int = Query(...),
    token: str = Query(...),
    format: str = Query("json"),
):
    # 직렬화 포맷 협상
    if format not in {"json", "msgpack"}:
        await websocket.close(code=1008, reason="unsupported format")
        return
    
    await websocket.accept()
    
    # 직렬화/역직렬화 함수 선택
    if format == "msgpack":
        def encode(obj): return msgpack.packb(obj, use_bin_type=True)
        def decode(data): return msgpack.unpackb(data, raw=False)
    else:
        def encode(obj): return json.dumps(obj).encode()
        def decode(data): return json.loads(data)
    
    try:
        while True:
            if format == "msgpack":
                data = await websocket.receive_bytes()
            else:
                data = await websocket.receive_text()
            
            message = decode(data)
            # ... 이벤트 처리
            
            response = { "type": "Ack", "payload": {...}, ... }
            if format == "msgpack":
                await websocket.send_bytes(encode(response))
            else:
                await websocket.send_text(encode(response).decode())
    except WebSocketDisconnect:
        pass
```

### 성능 목표

- JSON 대비 payload 30%+ 감소
- 직렬화/역직렬화 오버헤드: 1ms 이하 (작은 메시지 기준)
- 메모리 사용: msgpack이 JSON 대비 동등 또는 약간 낮음
```

### 4. API-05 §클라이언트 구현 (신규 섹션)

```markdown
## 클라이언트 구현

### Flutter CC (Team 4)

#### 의존성

```yaml
# pubspec.yaml
dependencies:
  web_socket_channel: ^2.4.0
  messagepack: ^0.2.1
```

#### 사용 예

```dart
import 'package:web_socket_channel/io.dart';
import 'package:messagepack/messagepack.dart';

class BOConnector {
  IOWebSocketChannel? _channel;
  final bool useMsgpack;
  
  BOConnector({this.useMsgpack = true});
  
  Future<void> connect({
    required String host,
    required int tableId,
    required String token,
  }) async {
    final format = useMsgpack ? "msgpack" : "json";
    final url = Uri.parse(
      "ws://$host/ws/cc?table_id=$tableId&token=$token&format=$format"
    );
    _channel = IOWebSocketChannel.connect(url);
    
    _channel!.stream.listen((data) {
      if (useMsgpack) {
        final decoded = Unpacker(data).unpackMap();
        _handleEvent(decoded);
      } else {
        final decoded = jsonDecode(data);
        _handleEvent(decoded);
      }
    });
  }
  
  void send(Map<String, dynamic> event) {
    final data = useMsgpack
        ? (Packer()..packMap(event)).takeBytes()
        : jsonEncode(event);
    _channel!.sink.add(data);
  }
}
```

### Web Lobby (Team 1)

#### 의존성

```json
// package.json
{
  "dependencies": {
    "@msgpack/msgpack": "^3.0.0"
  }
}
```

#### 사용 예

```typescript
import { encode, decode } from "@msgpack/msgpack";

class BOConnector {
  ws: WebSocket;
  useMsgpack: boolean;
  
  constructor(host: string, token: string, useMsgpack = true) {
    this.useMsgpack = useMsgpack;
    const format = useMsgpack ? "msgpack" : "json";
    this.ws = new WebSocket(
      `ws://${host}/ws/lobby?token=${token}&format=${format}`
    );
    this.ws.binaryType = "arraybuffer";  // MessagePack 바이너리 수신
    
    this.ws.onmessage = (e) => {
      let event;
      if (this.useMsgpack) {
        event = decode(new Uint8Array(e.data));
      } else {
        event = JSON.parse(e.data);
      }
      this.handleEvent(event);
    };
  }
  
  send(event: any) {
    const data = this.useMsgpack ? encode(event) : JSON.stringify(event);
    this.ws.send(data);
  }
}
```

### Phase 도입 전략

- **Phase 1 (초기)**: 모든 클라이언트 `format=json` 사용 (기본값). Backend는 json만 처리.
- **Phase 2 (최적화)**: Team 2가 msgpack 지원 추가. Team 4 CC가 `useMsgpack=true`로 전환.
- **Phase 3 (확장)**: Team 1 Lobby도 msgpack 전환.
```

### 5. API-05 §Fallback 정책 (신규 섹션)

```markdown
## Fallback 정책

### msgpack 연결 실패 시

클라이언트가 `format=msgpack`으로 연결 시도했으나 서버가 거부(HTTP 406)하면:

1. 경고 로그 "MessagePack 미지원 서버, JSON으로 fallback"
2. `format=json`으로 재연결 시도
3. 정상 연결되면 JSON 모드로 운영

### 직렬화 오류 발생 시

메시지 처리 중 msgpack 디코딩 실패 시:

1. 해당 메시지 무시
2. 에러 로그에 원본 바이트 기록
3. 다음 메시지 계속 처리
4. 연속 10회 실패 시 연결 재수립

### 설정 토글

- `team4-cc/src/lib/foundation/configs/features.dart`에 `enableMsgpack` 플래그
- Runtime에서 JSON ↔ MessagePack 전환 가능 (디버깅용)
- 프로덕션 기본값: `enableMsgpack = true` (Phase 2 이후)
```

## Diff 초안

```diff
 # `WebSocket_Events.md` (legacy-id: API-05)

 ## 1. 연결 아키텍처

 ### 1.1 연결 토폴로지
 ...
 
 ### 1.3 WebSocket JWT 인증 방식
 ...

+### 1.4 직렬화 협상
+
+URL query param `format`으로 JSON/MessagePack 선택:
+- ws://{host}/ws/cc?table_id={id}&token={t}&format=json (기본)
+- ws://{host}/ws/cc?table_id={id}&token={t}&format=msgpack
+
+Phase 1: json만. Phase 2: msgpack 병행. 혼합 금지.

 ## 2. 메시지 포맷

 ### 2.1 JSON Envelope
 ...

+### 2.2 MessagePack 스키마
+
+JSON envelope과 1:1 매핑. 필드 이름/값 동일.
+평균 30~50% 크기 감소. timestamp는 문자열 유지 (상호운용성).
+
+타입 매핑: string → str, int → int, float → float, 등.

+## 6. 서버 구현
+
+FastAPI에서 format query param 처리, msgpack/json 분기.
+(Python example 코드)

+## 7. 클라이언트 구현
+
+Flutter: messagepack 패키지
+Web: @msgpack/msgpack 패키지
+(Dart/TS example 코드)

+## 8. Fallback 정책
+
+msgpack 실패 시 json으로 자동 downgrade. 연속 10회 오류 시 재연결.
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**:
  - Phase 1에서는 변경 없음 (JSON 기본값)
  - Phase 3에서 `@msgpack/msgpack` 패키지 도입 + WebSocket 바이너리 모드 전환
  - 기존 JSON 처리 코드는 유지 (fallback으로 사용)
- **예상 작업 시간 (Phase 3)**: 8시간

### Team 2 (Backend)
- **영향**:
  - Phase 1: 변경 없음 (기존 JSON 핸들러 유지)
  - Phase 2: `msgpack` 라이브러리 추가, WebSocket 핸들러에 format 분기 추가
  - FastAPI `websockets` 라이브러리 호환성 확인 필요
- **예상 작업 시간 (Phase 2)**: 12시간

### Team 4 (self)
- **영향**:
  - `messagepack: ^0.2.1` 패키지 추가
  - `BOConnector` 구현에 format 협상 추가
  - JSON/MsgPack 양방향 처리 로직
  - Fallback 정책 구현
- **예상 작업 시간**: 10시간

### 마이그레이션
- 없음 (Phase 도입, 기존 JSON 호환성 유지)

## 대안 검토

### Option 1: 현행 JSON 고수
- **장점**: 변경 없음
- **단점**: 
  - WSOP Fatima.app의 MessagePack 자산 재사용 실패
  - 장기적 대역폭 부담
  - WSOP+ 통합 시 프로토콜 변환 레이어 필요
- **채택**: ❌

### Option 2: SignalR + MessagePack 완전 전환 (이전 Critic의 Option A)
- **장점**: 
  - WSOP Fatima.app과 100% 동일 스택
  - 내장 재연결, Sticky Session 등 SignalR 기능 활용
- **단점**: 
  - Python FastAPI + SignalR 조합은 비주류 (`pysignalr` 불안정)
  - Team 2 서버 스택 대폭 변경 → 대규모 재작업
  - 현 시점 Phase 1 일정에 과도한 부담
- **채택**: ❌ (장기 목표로만 고려)

### Option 3: JSON 유지 + MessagePack 선택 가능 (본 제안, Option C)
- **장점**:
  - 현행 WebSocket 프로토콜 유지 (Python FastAPI 호환)
  - MessagePack 이점(30~50% 압축) 확보
  - Phase 도입으로 점진적 전환
  - 기존 JSON 클라이언트와 하위 호환
- **단점**: 서버와 클라이언트 양쪽 dual-format 로직
- **채택**: ✅

## 검증 방법

### 1. 직렬화 일관성 (Cross-compat)
- [ ] Python msgpack과 Dart messagepack이 동일 객체를 동일 바이너리로 encode
- [ ] 서로 encode한 바이너리를 상대가 정상 decode
- [ ] JavaScript @msgpack/msgpack도 동일 바이너리 상호 운용

### 2. 페이로드 크기 측정
- [ ] 대표 이벤트 10종(HandStarted, PlayerAction, CardDetected, ...) 각각에 대해 JSON vs MessagePack 크기 비교
- [ ] 목표: 평균 30% 이상 감소

### 3. 성능 벤치마크
- [ ] 초당 100 메시지 전송 시 CPU/메모리 사용량 측정
- [ ] msgpack이 JSON 대비 동등하거나 더 나은 성능 확인

### 4. Fallback 시나리오
- [ ] 서버가 msgpack 미지원 상태에서 클라이언트 `format=msgpack` 요청 → HTTP 406 → json fallback 확인
- [ ] 연결 중 의도적 바이너리 손상 주입 → 10회 오류 후 재연결 확인

### 5. 기존 JSON 호환성
- [ ] Team 1 Lobby가 `format=json`(기본값)으로 연결 → 기존 동작 그대로
- [ ] Phase 1 완료 후 Phase 2 도입 시 기존 클라이언트 영향 없음

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Phase 3 전환 계획)
- [ ] Team 2 기술 검토 (FastAPI msgpack 라이브러리, Phase 2 구현)
- [ ] Team 4 기술 검토 (messagepack Dart 패키지, Fallback)
