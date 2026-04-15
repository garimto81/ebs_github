---
title: Statistics
owner: team4
tier: internal
legacy-id: BS-05-07
last-updated: 2026-04-15
---

# BS-05-07 Statistics Screen (AT-04)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-04 Statistics 화면 UI·통계 카탈로그·방송 제어 (CCR-027) |
| 2026-04-13 | UI-02 redesign | Hand History Winner/Loser 표시 변경, 10핸드/페이지, Session/Total Hands 추가 |
| 2026-04-15 | 역할 재정의 | CC 는 통계를 **계산하지 않는다**. engine(team3) 이 계산한 값을 수신·표시·방송송출 트리거만 담당. 계산식 섹션 삭제, 통신 스키마·UI 바인딩으로 재작성 |

---

## 개요

AT-04는 운영자가 현재 테이블의 플레이어 통계와 핸드 히스토리를 실시간 확인하고, **방송용 통계 GFX** 의 송출 여부를 제어하는 화면이다.

**역할 경계 (중요)**: CC 는 통계를 **계산하지 않는다**. 모든 수치(VPIP, PFR, 3Bet, AF, WTSD, Hands count) 는 team3 Game Engine 이 핸드 이벤트로부터 파생·집계한다. CC 는:

1. engine/BO 로부터 **계산된 값을 수신** (REST GET 또는 WebSocket push).
2. 아래 §3 레이아웃에 **바인딩하여 표시**.
3. 운영자의 **방송 GFX Push 트리거** 를 서버로 전달.

계산 로직·공식·엣지 케이스(핸드 이력 누락, 세션 전환, 최소 샘플 수) 는 본 문서 범위가 아니다. team3 Game Engine 문서(`docs/2. Development/2.3 Game Engine/Behavioral_Specs/`) 가 계산 SSOT.

> **참조**: `BS-05-00 §6 AT 화면 카탈로그`, `BS-02-lobby §테이블 통계`, 계산식은 team3 Game Engine, 전송은 `API-01-backend-api §통계 엔드포인트`.

---

## 1. 역할 & 페르소나

| 항목 | 내용 |
|------|------|
| **역할** | 플레이어 통계 조회 + 방송 GFX Push 트리거 |
| **페르소나** | Operator 이상 (Viewer 접근 불가) |
| **사용 시점** | 핸드 진행 중 수시 확인, 방송 중 GFX Push |
| **갱신 주기** | 핸드 완료 시 (`HandCompleted` WebSocket 이벤트 기반) |

---

## 2. 진입 경로

- **AT-01 Main** → M-01 Toolbar → Menu → "Statistics"
- 키보드 단축키: 미지정 (운영 중 충돌 방지)

---

## 3. 화면 구성

```
┌──────────────────────────────────────────────────────┐
│ ← Back                                  Statistics   │
│                                                      │
│ Table: [WSOP FT 2026] Hand#: 248 / 1500              │
│                                                      │
│ ┌────────────────────────────────────────────────┐   │
│ │ Seat │ Player    │ VPIP │ PFR │ 3Bet │ AF │ Gfx│   │
│ ├──────┼───────────┼──────┼─────┼──────┼────┼────┤   │
│ │ 1    │ Alice     │ 24%  │ 18% │ 7%   │2.1 │ ▶  │   │
│ │ 2    │ Bob       │ 32%  │ 22% │ 9%   │3.4 │ ▶  │   │
│ │ ... (10 seats)                                │   │
│ └────────────────────────────────────────────────┘   │
│                                                      │
│ [Refresh] [Export CSV]   [Push Table Stats to GFX]   │
└──────────────────────────────────────────────────────┘
```

---

## 4. 통계 카탈로그 (6 지표) — 수신·표시 명세

> 계산식은 team3 Game Engine 소유. CC 는 아래 `바인딩 필드` 를 읽어 `표시 포맷` 대로 렌더링만 수행.

| 통계 | 약어 | 바인딩 필드 (REST / WS payload) | 표시 포맷 | 비어있을 때 |
|------|------|--------------------------------|-----------|-------------|
| **VPIP** | Voluntarily Put $ In Pot | `players[i].vpip` (float 0.0~1.0) | `{n*100 | round}` + `%` | `—` |
| **PFR** | Pre-Flop Raise | `players[i].pfr` (float 0.0~1.0) | `{n*100 | round}` + `%` | `—` |
| **3Bet** | 3-Bet % | `players[i].three_bet` (float 0.0~1.0) | `{n*100 | round}` + `%` | `—` |
| **AF** | Aggression Factor | `players[i].af` (float, 0~∞) | `{n | round(1)}` | `—` |
| **Hands** | 총 플레이 핸드 | `players[i].hands_played` (int) | 정수, 천단위 콤마 | `0` |
| **WTSD** | Went To Showdown % | `players[i].wtsd` (float 0.0~1.0) | `{n*100 | round}` + `%` | `—` |

**일반 규칙**:
- 샘플 수 부족(`hands_played < 20`) 시 engine 이 해당 필드에 `null` 을 실어 전송. CC 는 위 `비어있을 때` 열을 렌더.
- 소수 반올림은 engine 책임(CC 는 반올림 추가 처리 금지) — 바로 표시.
- 10 좌석 미만 테이블은 `players` 배열 길이만큼만 렌더, 빈 행은 숨김.

---

## 5. 방송 GFX Push

운영자가 각 플레이어 행의 **▶ 버튼**을 누르면 해당 플레이어의 통계가 Overlay에 송출된다.

- `[Push Table Stats to GFX]` — 전체 10좌석 통계를 한 번에 송출
- 각 행의 `▶` — 개별 플레이어 통계를 송출
- GFX 송출은 WebSocket `PushPlayerStats` 프로토콜 (BO → Overlay)

---

## 6. 서버 프로토콜 (수신·트리거 계약)

### 6.1 엔드포인트 카탈로그

| 동작 | 방향 | API / Event |
|------|:----:|-------------|
| 화면 진입 시 최초 snapshot | GET | `GET /api/v1/tables/{id}/statistics` |
| 실시간 갱신 | WS push | `HandEnded` (WebSocket_Events §3.1) 수신 후 CC 가 **자동으로** GET 재호출. 전용 stats push 이벤트는 사용 안 함(§6.2 참조). |
| 핸드 히스토리 | GET | `GET /api/v1/tables/{id}/hands?page={n}&size=10` |
| GFX Push (운영자 트리거) | POST | `POST /api/v1/tables/{id}/gfx/push-stats` |
| CSV 내보내기 | GET | `GET /api/v1/tables/{id}/statistics/export?format=csv` |

### 6.2 갱신 주기 규약

- **진입 시**: GET 1회 (snapshot).
- **핸드 종료 시**: `HandEnded` WS 이벤트 수신 → CC 가 같은 GET 을 재호출 → 결과로 화면 바인딩 갱신.
- **스트리트 진행 중**: 갱신 없음 (지표 변동 없음).
- **강제 갱신**: 운영자가 `[Refresh]` 버튼 클릭 시 즉시 GET.
- **전용 stats push WebSocket 이벤트는 도입하지 않는다** — engine 이 계산 결과를 항상 REST snapshot 으로 유지하고, CC 가 "언제 pull 할지" 만 알면 충분하다는 원칙.

### 6.3 GET 응답 스키마 (요약)

```json
{
  "table_id": 5,
  "hand_number": 248,
  "session_hands": 40,
  "total_hands": 1500,
  "avg_pot": 3450,
  "players": [
    {
      "seat_no": 1,
      "player_id": "p_0042",
      "name": "Alice",
      "vpip": 0.24,
      "pfr": 0.18,
      "three_bet": 0.07,
      "af": 2.1,
      "hands_played": 248,
      "wtsd": 0.31
    }
  ]
}
```

샘플 수 부족 시 해당 필드만 `null`. 통계 전체 스키마는 team2 Backend `API-01 §통계 엔드포인트` 가 정본.

---

## 7. RBAC

| Role | 조회 | GFX Push | Export |
|------|:----:|:--------:|:------:|
| Admin | ✓ | ✓ | ✓ |
| Operator | ✓ | ✓ | ✓ |
| Viewer | ✗ | ✗ | ✗ |

---

## 8. Hand History 표시

각 핸드는 **Winner 행과 Loser 행**을 모두 표시한다. Winner와 Loser는 동일한 요소를 가진다:

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Result | `WIN` / `LOSE` | 결과 구분 태그 |
| Seat 번호 | `seat_no` | **숫자만** (예: "S1", "S3") |
| 이름 | `player.name` | 해당 시점의 이름 |
| 카드 | `player.hole_cards` | 카드 이미지/텍스트. 미공개 시 "—" |
| Pot | `hand.total_pot` | Winner 행에만 표시, Loser 행은 빈칸 |

**표시 규칙**:
- Chop(Split pot): 여러 WIN 행으로 표시
- All folded pre-flop: Winner 1행 + 카드 "—" + "All folded" 주석
- 10핸드/페이지 페이지네이션 ([Prev] / [Next])
- 핸드 탭 시 하단에 Board 카드 표시

**데이터 소스**: `GET /tables/{id}/hands?page={n}&size=10` → 응답에 `winners[]`, `losers[]` 배열 포함.

---

## 9. 통계 하단 표시

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Session Hands | `table.session_hands` | **이번 세션 핸드 수** (신규) |
| Total Hands | `table.total_hands` | **전체 누적 핸드 수** (신규) |
| Avg Pot | `table.avg_pot` | 콤마 포맷 |

---

## 10. 연관 문서

- `BS-05-00 §6` — AT 화면 카탈로그
- `BS-02-lobby` — Lobby의 테이블 통계 뷰 (별도 화면)
- `API-01-backend-api` — 통계 엔드포인트 상세
