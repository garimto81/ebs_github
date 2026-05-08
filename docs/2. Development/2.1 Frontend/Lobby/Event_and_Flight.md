---
title: Event and Flight
owner: team1
tier: internal
legacy-id: BS-02-02
last-updated: 2026-05-07
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-02-02 EventFlightStatus enum 완결 (WSOP LIVE parity)"
confluence-page-id: 3818881488
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818881488/EBS+Event+and+Flight
---
# BS-02-02 Event/Flight 상태 — `EventFlightStatus` enum

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | WSOP LIVE parity — `EventFlightStatus` 공유 enum, `isRegisterable`/`dayIndex`/`is_pause` (CCR-017) |
| 2026-05-07 | v3 cascade | Lobby_PRD v3.0.0 정체성 정합 — 진입 시점 ②(어긋났을 때) ③(게임 바뀔 때) 매핑 framing 추가. enum 본문 변경 0 (additive only). |

---

## 개요

> **진입 시점 매핑 (Lobby_PRD v3.0.0 cascade, 2026-05-07)**: 본 문서가 정의하는 `EventFlightStatus` 전이는 운영자가 Lobby 를 거치는 4 진입 중 **②(어긋났을 때 — Late Reg 종료 / Day 전환 비상) 와 ③(게임이 바뀔 때 — Day1→Day2 / Mix 게임 회전 / Flight Completed)** 시점에 직접 매핑된다. 카탈로그: `Overview.md §4 진입 시점 카탈로그`.

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

### 3.1 계산 공식 (2026-04-15 명시)

WSOP LIVE Blind Type별 Tournament Clock 문서의 정의를 EBS 에 그대로 채택. 클라이언트는 매 `clock_tick` 이벤트마다 본 공식으로 남은 시간을 계산한다.

```text
late_reg_remaining_sec =
    sum(blind_levels[0..N-1].duration_sec)         # 1번째~N번째 레벨 누적 시간
  + (blind_levels[N].duration_sec - elapsed_in_current_level)  # 현재 레벨 잔여
  - sum(applied_pauses_in_current_period)          # is_pause 였던 누적 시간 차감
```

여기서:
- `N` = `late_reg_until_level` (Late Reg 가 종료되는 레벨 번호, Flight 메타). Level 1~N 동안 Late Reg 가 열려있음
- `elapsed_in_current_level` = 현재 레벨이 시작된 시각부터 경과한 초. **`is_pause == true` 인 동안 증가 중단**
- `applied_pauses_in_current_period` = 현재 Late Reg 기간 누적 일시정지 시간

**Edge cases**:
- `current_level > N` → `late_reg_remaining_sec = 0` (Late Reg 종료됨)
- `current_level == N` → 현재 레벨 잔여만 계산
- Day 2 이후 시작 (Late Reg = Start of Day 2 모드) → `current_day_index >= 2` 일 때 즉시 0
- `Late Reg Override` 발동 시 (Clock_Control `[Adjust Late Reg]`) → `late_reg_until_level` 이 동적으로 변경. 다음 `clock_level_changed` 이벤트로 갱신

### 3.2 Day 2 등록 가능 여부 모드

WSOP LIVE 의 두 모드를 EBS 에서도 지원:

| 모드 | 설명 | EBS 필드 |
|------|------|---------|
| **Levels 기준** (기본) | Level 1~N 동안 Late Reg 가능 | `late_reg_mode = "levels"`, `late_reg_until_level = N` |
| **Start of Day 2** | Day 1 종료 + Day 2 시작 직전까지 등록 가능 | `late_reg_mode = "day_start"`, `late_reg_until_day = 2` |

UI 표시: `late_reg_mode` 에 따라 "Level N 까지" 또는 "Day 2 시작까지" 로 인간 친화 표시.

### 3.3 Restricted 판정 보강

`isRegisterable` 필드는 위 공식의 `late_reg_remaining_sec > 0` 결과 + `status in {Announce, Registering, Running}` AND.

기존 §2 의 "Restricted = `Announce && dayIndex >= 1`" 은 다음과 동치:
- `Announce` 면 등록 불가 (아직 시작 안 함)
- `dayIndex >= 1` (Day 2+) 이면 Day 1 의 결과를 가진 플레이어만 진행. 신규 등록 시점 이미 종료된 케이스가 일반적

세부는 `Registration.md §1.3 Entry Type 별 등록 규칙` 참조.

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

### `GET /api/v1/Events/{id}/Flights`

```json
{
  "flights": [
    {
      "id": "fl_01HVQK...",
      "eventId": "ev_...",
      "displayName": "Day 1A",
      "status": 1,
      "statusLabel": "Announce",
      "isRegisterable": true,
      "dayIndex": 0,
      "isPause": false
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
- `../BS-03-settings/`Settings/Rules.md` (legacy-id: BS-03-04) §5` — `BlindDetailType` + Late Reg 계산
- `Backend_HTTP.md` (legacy-id: API-01) — `/Events`, `/Flights` REST
- `CCR-017` — 본 문서 신설 근거 (WSOP LIVE parity)
