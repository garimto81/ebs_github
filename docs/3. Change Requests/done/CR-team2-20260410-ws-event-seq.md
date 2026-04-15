# CCR-DRAFT: WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/api/API-05-websocket-events.md, contracts/api/API-01-backend-api.md
- **변경 유형**: add
- **변경 근거**: WSOP+ Architecture(`SignalR Real-Time Stream Server + MSK Event Stream 이중 구조`)를 참고하면, 실시간 방송 환경에서는 네트워크 순간 단절·백그라운드 복귀·WebSocket 재연결 후 **놓친 이벤트를 안전하게 재생**해야 한다. 현재 API-05 계약에는 이벤트 순번이 없어 클라이언트가 gap 감지 및 replay를 구현할 수 없다. 상태가 GameState/TableState처럼 순서에 민감하면 ad-hoc 재동기화로는 오결정 위험이 있다.

## 변경 요약

1. 모든 `cc_event` / `lobby_monitor` 이벤트 페이로드에 `seq`(int, per-table monotonic) 필드 추가
2. 클라이언트가 gap 감지 시 호출할 REST endpoint `GET /api/v1/tables/{table_id}/events?since={seq}&limit=N` 신설

## Diff 초안

**API-05 (이벤트 공통 envelope)**:
```diff
 ## 이벤트 공통 envelope
 
 ```json
 {
   "type": "hand_started",
   "table_id": "tbl-001",
+  "seq": 12345,                   // 테이블당 단조증가 (BIGINT). 재연결 시 gap 감지용
   "ts": "2026-04-10T12:34:56.789Z",
+  "server_time": "2026-04-10T12:34:56.789Z",   // 시계 보정용 서버 기준
   "payload": { ... }
 }
 ```
+
+### Seq 보장 규칙
+- 테이블별 독립 시퀀스. 테이블 생성 시 0으로 리셋.
+- `audit_events.seq` 컬럼이 SSOT. WebSocket 브로드캐스트는 DB 커밋 후 수행.
+- 재시작/HA failover 시 DB에서 `MAX(seq)`를 읽어 이어간다.
+- 이벤트 순서 보장 범위: **같은 테이블 내부만**. 테이블 간 순서는 `ts` 기반.
```

**API-01 (신규 replay 엔드포인트)**:
```diff
+### GET /api/v1/tables/{table_id}/events
+
+**용도**: WebSocket 재연결 후 누락 이벤트 재생.
+
+**Query**:
+- `since` (int, required): 마지막으로 수신한 seq. 응답은 `seq > since`만 포함.
+- `limit` (int, default 500, max 2000): 페이징.
+
+**Response 200**:
+```json
+{
+  "table_id": "tbl-001",
+  "events": [
+    { "type": "seat_assigned", "seq": 12346, "ts": "...", "payload": {...} },
+    ...
+  ],
+  "last_seq": 12500,
+  "has_more": false
+}
+```
+
+**권한**: Admin / Operator(해당 테이블 할당). Viewer 허용.
+**Rate Limit**: 10 req/sec per table per client.
```

## 영향 분석

- **Team 2 (자기)**: `audit_events` 테이블 `seq BIGINT` 컬럼(table_id별 partial index). Redis `Table:seq:{id}` 아토믹 증가. Replay 엔드포인트 구현. 약 12시간. **DATA-04 CCR에 포함**.
- **Team 1 (Lobby)**: WebSocket 구독 훅에 `lastEventSeq` 추적, 재연결 시 `since` 쿼리로 replay 호출, gap 감지 로직. 약 6시간.
- **Team 4 (CC Flutter)**: Riverpod StreamProvider 에 seq gap 감지 → REST replay → GameState 재적용. 약 8시간.
- **마이그레이션**: 기존 이벤트 envelope 확장이므로 기존 소비자 영향 0 (ignoring unknown field). Phase 1 초기에 도입 권장.

## 대안 검토

1. **Kafka/MSK 직접 구독** (WSOP+ 사용) — 인프라 부담 큼. Phase 3+ 고려.
2. **이벤트 ID(UUID)만** — 순서 재구성 불가. 탈락.
3. **클라이언트 타임스탬프 기반** — 서버 시계 skew + NTP jitter로 부정확. 탈락.
4. **테이블당 단조 seq + REST replay (채택)** — 단순, DB 원자성 활용, 메모리 오버헤드 최소.

## 검증 방법

- **단위**: 동일 테이블에 이벤트 100건 발생 → 소비자가 수신한 seq 연속성 확인
- **통합**: CC가 WebSocket 강제 끊기 → 5초 후 재연결 → `since` 쿼리로 누락 이벤트 5건 복구 → GameState 일치
- **부하**: 동시 5테이블 각 100 이벤트/분 → seq 중복/역순 0건

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby WS 훅)
- [ ] Team 4 기술 검토 (CC gap handler)
- [ ] 종속 CCR (`data-idempotency-audit` — `audit_events.seq` 컬럼) 동시 승인
