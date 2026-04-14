# BS-02-02 Event/Flight 상태 — `EventFlightStatus` enum

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | WSOP LIVE parity — `EventFlightStatus` 공유 enum, `isRegisterable`/`dayIndex`/`is_pause` (CCR-017) |

---

## 개요

Event와 Flight는 **공유된 enum `EventFlightStatus`** 로 상태를 관리한다. 문자열 상태(`created/active/done`)는 폐기되고 WSOP LIVE 원본의 정수 enum 체계를 따른다.

> **참조**: Flight/Table 엔티티 필드는 `contracts/data/DATA-04-db-schema.md §1.4 §1.5`.

---

## 1. `EventFlightStatus` enum

Event와 Flight가 공유하는 상태 enum. WSOP LIVE 원본은 값 3을 skip한다.

```
EventFlightStatus {
  Created     = 0   // 객체 생성, 운영자에게 비공개
  Announce    = 1   // 공지됨, 플레이어 등록 대기
  Registering = 2   // 등록 중
  Running     = 4   // 진행 중 (3 skip)
  Completed   = 5   // 종료
  Canceled    = 6   // 취소
}
```

| 값 | 이름 | 의미 | Lobby UI 표시 |
|:--:|------|------|----------------|
| 0 | Created | 초기 생성 | "Draft" (Admin만 보임) |
| 1 | Announce | 공지 | "Announced" |
| 2 | Registering | 등록 중 | "Registration Open" |
| 4 | Running | 진행 중 | "Running" + 플레이어 카운트 |
| 5 | Completed | 종료 | "Finished" (아카이브) |
| 6 | Canceled | 취소 | "Canceled" (회색 처리) |

### 전환 규칙

```
Created(0) → Announce(1) → Registering(2) → Running(4) → Completed(5)
                                                       → Canceled(6) (Running 중 취소 허용)
Announce(1) → Canceled(6) (등록 전 취소)
Registering(2) → Running(4) (등록 마감 후 실제 시작)
```

역방향 전환(예: Running → Announce)은 허용되지 않는다.

---

## 2. Flight 전용 메타 필드

Flight는 Event와 동일한 `status`를 갖되, 다음 두 메타 필드를 **추가로** 보유한다:

| 필드 | 타입 | 기본값 | 설명 |
|------|------|:------:|------|
| `isRegisterable` | bool | true | 신규 등록 허용 여부. Late Registration 차단 시 false. |
| `dayIndex` | int | 0 | Event 내부 Day 순서 (0-based). Day 1A=0, Day 1B=0, Day 2=1, Day 3=2, ... |

### 2.1 Restricted 판정

Lobby UI는 Flight를 다음 조건에서 **"Restricted"** 배지로 표시한다:

```
is_restricted = (flight.status == Announce) && (flight.dayIndex >= 1)
```

**의도**: Day 1이 아직 Announce 상태인데 Day 2/3 Flight가 이미 Announce로 넘어간 경우 — 정상 흐름이 아니므로 운영자에게 경고.

---

## 3. Late Registration 타이머와 `is_pause`

Flight는 `is_pause: bool` 필드도 보유한다 (DATA-04 참조). Late Reg 남은 시간 계산 시 `is_pause == true`면 `elapsed_in_current_level` 증가가 **중단**된다. Flight 단위의 일시정지(브레이크/카메라 리셋/중재)에 사용된다.

계산식은 `BS-03-04-rules.md §5.1` 참조.

---

## 4. 마이그레이션 (기존 문자열 → enum)

기존 DB의 Flight `status` 컬럼(TEXT)을 INTEGER로 변환한다:

| 기존 문자열 | 새 값 |
|------------|:-----:|
| `created` | 0 (Created) |
| `pending` | 1 (Announce) |
| `active` | 4 (Running) |
| `done` | 5 (Completed) |

> **주의**: `pending`이 Announce인지 Created인지 시드 데이터별로 확인 필요. 모호하면 Admin에게 문의 후 결정.

---

## 5. API 응답 구조

### `GET /api/v1/events/{id}/flights`

```json
{
  "flights": [
    {
      "id": "fl_01HVQK...",
      "event_id": "ev_...",
      "display_name": "Day 1A",
      "status": 1,
      "status_label": "Announce",
      "is_registerable": true,
      "day_index": 0,
      "is_pause": false
    }
  ]
}
```

- `status` (정수) + `status_label` (클라이언트 표시용 문자열) 동시 반환.
- 클라이언트는 정수로 로직 처리, 문자열은 UI 용.

---

## 6. 이벤트 알림

Flight 상태 변경은 `ConfigChanged` 또는 `FlightStatusChanged` WebSocket 이벤트로 구독자에게 알린다 (API-05 §4, §5).

---

## 7. 연관 문서

- `contracts/data/DATA-04-db-schema.md §1.4 Flight` — 필드 정의
- `../BS-03-settings/BS-03-04-rules.md §5` — `BlindDetailType` + Late Reg 계산
- `contracts/api/API-01-backend-api.md` — `/events`, `/flights` REST
- `CCR-017` — 본 문서 신설 근거 (WSOP LIVE parity)
