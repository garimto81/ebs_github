---
title: Activate Broadcast
owner: team1
tier: internal
legacy-id: BS-08-03
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-08-03 방송 활성화 플로우 기획 완결"
---
# BS-08-03 Activate + Broadcast — 멀티 CC 동기화

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Activate FSM + WebSocket broadcast + GameState 가드 (CCR-011, CCR-015) |

---

## 개요

Admin이 업로드·편집된 스킨을 **실제 방송에 활성화(activate)**하는 흐름을 정의한다. Activate 시 Backend는 `active_skin_id`를 DB에 기록하고 모든 CC/Overlay 인스턴스에 `SkinUpdated` WebSocket 이벤트를 broadcast한다. 다중 CC는 500ms 이내에 동시 리로드되어 시청자에게 매끄러운 전환을 제공한다.

> **범위**: GEA-01~06 (BS-00 §7.4).

---

## 1. Activate FSM

```
ready (스킨 선택, 프리뷰 완료)
  ↓ user clicks Activate (GEA-01)
  ↓
game_state_check
  ↓ GET /api/v1/GameState
  ├→ IDLE → confirming
  └→ RUNNING → warning_dialog (GEA-02)
                ├→ user cancels → ready
                └→ user forces → confirming (X-Game-State: IDLE override)
  ↓
confirming
  ↓ user confirms
  ↓
activating
  ↓ PUT /Skins/{id}/Activate (If-Match ETag + X-Game-State)
  ├→ 201 → broadcasting
  ├→ 412 ETag 충돌 (GEA-03) → conflict_refetch → ready
  └→ 409 GameState 불일치 → ready (경고 재표시)
  ↓
broadcasting
  ↓ 서버가 SkinUpdated WS broadcast (GEA-05)
  ↓ 모든 CC/Overlay가 500ms 이내 수신 (GEA-06)
  ↓
activated
  ↓ UI 토스트 "Activated" (GEA-04)
```

---

## 2. GameState 가드 (GEA-02)

### 2.1 왜 필요한가

라이브 방송 중에 스킨을 교체하면 시청자에게 **시각적 단절**이 발생한다. Admin이 실수로 Activate를 눌러도 경고 다이얼로그를 거쳐 명시적 override를 요구해야 한다.

### 2.2 클라이언트 동작

```
Activate 버튼 클릭
  ↓
GET /api/v1/GameState (Lobby 측 최신 상태 조회)
  ↓
if state == "RUNNING":
  다이얼로그 표시:
    제목: "방송 진행 중입니다"
    본문: "현재 Table {id}에서 Hand {handId}가 진행 중입니다.
           스킨을 교체하면 시청자에게 급격한 시각 전환이 발생합니다.
           핸드 종료 후 Activate를 권장합니다."
    버튼: [취소] [강제 Activate]
  if user clicks 강제 Activate:
    X-Game-State = "IDLE" 헤더로 요청 (override)
  else:
    return to ready
else:
  X-Game-State = "IDLE" 헤더로 정상 요청
```

### 2.3 서버 재확인

클라이언트가 `X-Game-State: IDLE` 을 보내도 서버는 DB의 실제 GameState와 대조한다. 불일치 시 409 Conflict + `Warning` 헤더 반환. Admin이 2차 확인을 거치도록 강제.

---

## 3. PUT /Skins/{id}/Activate (API-07 §6)

### 3.1 요청

```http
PUT /api/v1/Skins/{id}/Activate HTTP/1.1
Authorization: Bearer {adminJwt}
If-Match: W/"{etag}"
X-Game-State: IDLE | RUNNING
Idempotency-Key: {uuid4}
```

### 3.2 응답 201

```json
{
  "activeSkinId": "sk_01HVQK...",
  "seq": 42,
  "broadcastedAt": "2026-04-10T10:30:00Z"
}
```

- `seq`: 단조증가 (CCR-015 준수). Overlay 재연결 시 replay 기준.
- `broadcastedAt`: 서버 시각, 감사 로그용.

### 3.3 응답 412 (ETag 충돌, GEA-03)

- 다른 Admin이 동시 편집/Activate → 내가 본 ETag가 stale
- 클라이언트: 최신 상태 refetch 다이얼로그 → "다시 시도" 또는 "취소"

### 3.4 응답 409 (GameState 불일치)

- 서버 판단 GameState가 클라이언트 선언과 다름
- `Warning` 헤더 예시: `Warning: 199 - "GameState mismatch: server=RUNNING, client=IDLE"`
- 클라이언트: 경고 다이얼로그 재표시

---

## 4. Broadcast — `SkinUpdated` WebSocket 이벤트

Backend는 Activate 성공 시 모든 구독자에게 `SkinUpdated` 이벤트를 발행한다. 상세 페이로드는 `API-05 §Events SkinUpdated` 참조.

```json
{
  "type": "SkinUpdated",
  "seq": 42,
  "payload": {
    "skinId": "sk_01HVQK...",
    "version": 3,
    "transitionType": "fade",
    "broadcastedAt": "2026-04-10T10:30:00Z"
  }
}
```

### 4.1 Consumer 동작 (CC/Overlay, Team 4)

```
WS 수신: SkinUpdated
  ↓
GET /api/v1/Skins/{skinId} (`.gfskin` bytes 다운로드)
  ↓
BS-07-03 §3 로드 FSM 수행 (in-memory ZIP 해제 + 검증)
  ↓
BS-07-03 §5 전환 FSM 수행 (transition_type에 따라)
  ↓
Overlay 재렌더 (최대 500ms)
```

### 4.2 Replay (GEA-05 + CCR-015)

Overlay가 재연결 또는 network gap 후 복구:

1. `GET /api/v1/Skins/Active` → current `active_skin_id` 확인
2. `GET /api/v1/Events/replay?from_seq={lastSeq}&channel=cc_event` → 놓친 이벤트 재생
3. `SkinUpdated` 이벤트를 만나면 §4.1 Consumer 동작 실행

---

## 5. 성능 목표

| 항목 | 목표 |
|------|------|
| Activate 요청 → 201 응답 | < 500 ms |
| WS broadcast 지연 (서버→다중 구독자) | < 100 ms |
| Overlay 재렌더 완료 (N=8 CC) | < 500 ms (GEA-06) |
| `.gfskin` 다운로드 (50MB, LAN) | < 2 s |

---

## 6. 요구사항 매핑

| ID | 섹션 |
|----|------|
| GEA-01 Activate 버튼 + ETag PUT | §1 activating |
| GEA-02 GameState 경고 다이얼로그 | §2 |
| GEA-03 ETag 충돌 refetch | §3.3 |
| GEA-04 성공 토스트 | §1 activated |
| GEA-05 WS broadcast 발행 | §4 |
| GEA-06 다중 CC 500ms 동기화 | §5 |

---

## 7. 연관 문서

- `Graphic_Editor_API.md §6` (legacy-id: API-07) — PUT activate
- `WebSocket_Events.md` (legacy-id: API-05) — SkinUpdated 이벤트 (CCR-015)
- `BS-07-03-skin-loading.md §3 §5` — 로드/전환 FSM (재사용)
- `BS-08-04-rbac-guards.md` — Activate 권한 gate
