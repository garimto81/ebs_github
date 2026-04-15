---
title: Table
owner: team1
tier: internal
legacy-id: BS-02-03
last-updated: 2026-04-15
---

# BS-02-03 Table 상태 — TableFSM + `is_pause` 직교 축

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Table 상태 2축 분리: TableFSM × `is_pause` (CCR-017) |
| 2026-04-15 | UI 표시 + WSOP LIVE 통합 | §6 LIVE+is_pause UI 매트릭스 신설 (배지·색·CSS class). §7 WSOP LIVE Table Management 매핑 (Player Add/Move/Stack/Eliminate, Auto/Manual Seating, Seat 색상 코드, Reserved Seat/Table, Breaking Order). team1 발신, Round 2 Phase A. |

---

## 개요

Table은 **GUI status**(TableFSM, 5 상태)와 **`is_pause`**(bool, 일시정지 여부)를 **직교하는 두 축**으로 관리한다. "LIVE이면서 일시정지(브레이크/카메라 리셋/중재)" 같은 케이스를 표현하기 위해 단순 enum 확장 대신 축 분리 방식을 채택한다.

> **참조**: Table 엔티티 필드는 `contracts/data/DATA-04-db-schema.md §1.5`.

---

## 1. TableFSM (GUI status)

```
EMPTY → SETUP → LIVE → PAUSED → CLOSED
```

| 상태 | 의미 | 진입 | 퇴장 |
|------|------|------|------|
| **EMPTY** | 미설정 — 게임 유형/플레이어 없음 | 테이블 생성 시 | 게임 설정 완료 → SETUP |
| **SETUP** | 설정 중 — 게임·좌석 배치 진행 | 게임 설정 시작 | CC Launch → LIVE |
| **LIVE** | 방송 중 — CC가 활성화되어 핸드 진행 | CC Launch 완료 | Pause → PAUSED, Close → CLOSED |
| **PAUSED** | 일시 중단 — 운영자 명시적 Pause | 운영자 Pause | Resume → LIVE, Close → CLOSED |
| **CLOSED** | 종료 — Flight/Event 내 폐쇄 | 운영자 Close | 재사용 시 EMPTY |

> 상세는 `BS-00-definitions.md §3.1 Table 상태`.

---

## 2. `is_pause` 필드 (직교 축)

`is_pause`는 TableFSM과 **독립적으로** 일시정지 상태를 표현한다. 기존 TableFSM의 `PAUSED` 상태는 "운영자 명시적 중단"을 의미하고, `is_pause`는 "진행 가능하나 잠시 멈춤" (브레이크·카메라 리셋·중재 등)을 표현한다.

### 2.1 TableFSM × `is_pause` 조합 매트릭스

| GUI status | `is_pause` | 허용 | 의미 |
|------------|:----------:|:----:|------|
| LIVE | false | ✓ | 정상 진행 |
| LIVE | **true** | ✓ | **진행 가능하나 일시정지** (브레이크/중재) |
| PAUSED | true | ✓ | 운영자 명시적 중단 |
| PAUSED | false | **✗ 거부** | 불변 조합 — 서버가 유효성 검사에서 거부 |
| EMPTY | false | ✓ | 초기 상태 |
| EMPTY | true | ✗ | — |
| SETUP | false | ✓ | 설정 중 |
| SETUP | true | ✗ | — |
| CLOSED | false | ✓ | 종료 |
| CLOSED | true | ✗ | — |

**규칙**:
- EMPTY / SETUP / CLOSED 상태에서는 `is_pause = false` 로 고정.
- LIVE 상태에서는 `is_pause`가 독립적으로 true/false 전환 가능.
- PAUSED 상태는 반드시 `is_pause = true`.
- `PAUSED + is_pause=false` 조합은 **불변** — `PUT /tables/{id}` 가 이 조합을 거부해야 한다 (422 Unprocessable Entity).

### 2.2 LIVE + `is_pause=true`의 의미

브레이크/중재/카메라 리셋 중에도 CC는 연결 유지되고 UI는 접근 가능하다. 단:
- Late Registration 타이머 증가 **중단** (BS-03-04-rules §5.1)
- Blind Level 타이머 증가 **중단**
- Hand 진행 이벤트는 여전히 처리 (Pause가 아니므로 Admin은 "필요 시 진행" 가능)
- Overlay에는 "BREAK" 배지가 표시될 수 있음 (skin 설정에 따라)

---

## 3. API 응답 구조

### `GET /api/v1/tables/{id}`

```json
{
  "id": "tbl_01HVQK...",
  "flight_id": "fl_...",
  "table_no": 5,
  "name": "Feature Table",
  "type": "feature",
  "status": "live",
  "is_pause": true,
  "max_players": 9
}
```

### `PUT /api/v1/tables/{id}` 유효성

```python
# 서버 측 의사 코드
if new_status == "PAUSED" and is_pause == False:
    raise HTTPException(422, "PAUSED 상태는 is_pause=True 여야 합니다")
```

---

## 4. 마이그레이션

기존 테이블은 `is_pause` 컬럼 없음. 기본값 `false`로 추가 (NOT NULL).

```sql
ALTER TABLE tables ADD COLUMN is_pause BOOLEAN NOT NULL DEFAULT false;
```

기존 `status='paused'` row의 `is_pause`를 true로 일괄 업데이트:

```sql
UPDATE tables SET is_pause = true WHERE status = 'paused';
```

---

## 5. 이벤트 알림

Table 상태 변경은 `ConfigChanged` 또는 `TableStatusChanged` WebSocket 이벤트로 구독자에게 알린다.

```json
{
  "type": "TableStatusChanged",
  "payload": {
    "table_id": "tbl_...",
    "old_status": "live",
    "new_status": "live",
    "old_is_pause": false,
    "new_is_pause": true,
    "reason": "break"
  }
}
```

---

## 6. UI 표시 매트릭스 (Lobby 테이블 카드)

각 비즈니스 상태가 Lobby 카드에서 어떻게 표시되는지의 SSOT. CSS class · 색 · 배지 · 클릭 가능성을 명시.

| `status` | `is_pause` | CSS class | 배지 텍스트 | 카드 색 | 클릭 | UI 상태 |
|----------|:---------:|----------|------------|--------|:---:|--------|
| EMPTY | false | `status-empty` | "비어있음" | grey-3 | ✓ Setup 진입 | idle |
| SETUP | false | `status-setup` | "SETUP" + 펄스 | blue-3 | ✓ Setup 계속 | idle / loading |
| LIVE | false | `status-live` | "● LIVE" | green-6 | ✓ CC 진입 | idle |
| LIVE | **true** | `status-break` | "⏸ BREAK" | yellow-7 | ✓ CC 진입 (브레이크 표시) | idle |
| PAUSED | true | `status-paused` | "⏸ PAUSED" | grey-6 | ✓ Resume 가능 | idle |
| CLOSED | false | `status-closed` | "✕ CLOSED" | grey-7 (50% opacity) | ✗ | idle |
| 모든 상태 | — | `+ status-error` | + ⚠ 아이콘 오버레이 | red-1 테두리 | (상태별) | error (WS 단절 등) |
| 모든 상태 | — | `+ status-loading` | Spinner 오버레이 | (상태별) | (상태별) | loading (저장 중) |

**규칙**:
- `+ status-error` / `+ status-loading` 은 비즈니스 상태에 **추가로** 적용되는 modifier 클래스. 단독 사용 금지.
- WebSocket 단절 시 카드 모서리에 회색 배너 "연결 끊김". 재연결 시 자동 해제.
- "BREAK" 와 "PAUSED" 의 시각적 구분: BREAK 는 활기 있는 yellow (운영 중), PAUSED 는 차분한 grey (중단).
- 접근성: 색만으로 구분 금지. 아이콘 + 텍스트 동반.

### 6.1 i18n

| i18n 키 | ko | en | es |
|---------|-----|-----|-----|
| `table.status.empty` | 비어있음 | Empty | Vacía |
| `table.status.setup` | SETUP | SETUP | SETUP |
| `table.status.live` | 라이브 | LIVE | EN VIVO |
| `table.status.break` | 브레이크 | BREAK | DESCANSO |
| `table.status.paused` | 일시정지 | PAUSED | PAUSADA |
| `table.status.closed` | 종료 | CLOSED | CERRADA |

---

## 7. WSOP LIVE Table Management 매핑

본 섹션은 [WSOP LIVE Table Management (Confluence p1615528545)](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1615528545/Table+Management) 의 기능을 EBS 에 반영한 결과를 기록한다. 원본 페이지는 RFID 통합 이외 모든 기능을 그대로 채택. divergence 만 별도 명시.

### 7.1 Player CRUD (Add / Move / Stat 수정 / Eliminate / Kick Out)

| 동작 | 모드 | WSOP LIVE 정의 | EBS 구현 |
|------|------|---------------|---------|
| **Add (Random)** | Random | 자리 미지정, 빈 테이블 없으면 동작 안 함 | `POST /tables/seats/random` — 서버가 Auto Seating 알고리즘 적용 |
| **Add (Manual table only)** | Manual A | 테이블 지정, 시트 랜덤 | `POST /tables/{id}/seats/random` |
| **Add (Manual full)** | Manual B | 테이블 + 시트 모두 지정 | `POST /tables/{id}/seats/{seat_no}` |
| **Move (Random)** | Random | 마지막 테이블 정리 시 사용 | `POST /tables/move-random?from_table_id=...` |
| **Move (Manual table only)** | Manual A | 테이블 지정, 시트 랜덤 | `POST /tables/{id}/seats/random?from_player_id=...` |
| **Move (Manual full)** | Manual B | 테이블 + 시트 지정 | `POST /tables/{id}/seats/{seat_no}?from_player_id=...` |
| **Stat 수정** | — | Add Chips / Remove Chips / Kick Out / Eliminate | `PATCH /seats/{seat_id}` body `{chips, eliminated, kicked_out}` |
| **Eliminate (마지막 1~2명)** | confirm | "There is The Last Player Standing" / "This is The Last Player CANNOT be eliminated" 확인 | 클라이언트 모달 + `POST /tables/{id}/complete` 트리거 |

권한: Floor Manager·Tournament Director (= EBS Admin). Table Dealer 는 칩 변동 + Bust 신청만 (= EBS Operator 해당 테이블 한정).

### 7.2 Auto Seating vs Manual Seating

| 모드 | 동작 |
|------|------|
| **Auto** | Reserve Seat/Table 제외 모두 찰 때까지 자동 배치. 만석 시 Waiting List 등록. 빈 자리 발생 시 첫 대기자 호출 |
| **Manual** | 빈자리가 있어도 Waiting List 만 등록. Admin 이 수동 호출 |

토글 위치: Lobby/Overview.md 의 Flight 탭 내 헤더. `Auto/Manual` 토글 버튼.

**옵션 (Auto 모드)**:
- `Minimum Seats` per table: 기본 1, 최대 = `max_players`
- `Maximum Seats` per table: 기본 unchecked (만석까지 자동 배치 무중단). 체크 시 지정값 도달 후 Auto Seating 중단

### 7.3 Seat 색상 코드

| 색 | 의미 | CSS class |
|----|------|----------|
| 청 | Table Dealer 로그인 중 | `seat-dealer` |
| 백 | 빈 좌석 | `seat-empty` |
| 녹 | 플레이어 착석 | `seat-occupied` |
| 황 | 빈 좌석을 Waiting 플레이어에게 배정한 상태 | `seat-pending` |
| 적 | 플레이어 탈락 (TD 컨펌 대기) | `seat-busted` |
| 짙은 회색 | Reserved | `seat-reserved` |

Reserved Seat 는 클릭 비활성. 적색은 TD 컨펌 후 백색으로 전환.

### 7.4 Table 색상 코드 (Section 뷰에서 테이블 카드 자체)

| 색 | 의미 |
|----|------|
| 짙은 회색 | Reserved 테이블 (Auto Seating 대상 제외) |
| 옅은 회색 | Empty Seat 없음 (만석) |
| 백색 | Empty Seat 있음 |

**Seated 카운트 색**: 테이블당 평균 (소수점 1자리에서 반올림) 대비 차이로 표시
- 백 = 평균값
- 황 = 평균값 ±1
- 적 = 평균값 ±2 이상

밸런싱 알고리즘이 황·적 테이블을 우선 처리.

### 7.5 Reserved Seat / Reserved Table 정책

| 동작 | 규칙 |
|------|------|
| 테이블 Reserve | 테이블 메뉴 `Reserve` 클릭 → Auto Seating 제외. 착석 플레이어 있으면 그 자리만 유지, 나머지 좌석은 Reserved |
| 테이블 Release | `Release` 클릭 → Reserve 해제, Auto Seating 재포함 |
| 좌석 Reserve | 빈 좌석 메뉴 `Reserve` 클릭 → 단일 좌석만 Reserved |
| 좌석 Release | `Release` 클릭 → 일반 빈 좌석으로 전환 |
| Section 일괄 Reserve | `Reserve All Tables` → 섹션 전체 테이블을 Reserved |
| Section 일괄 Release | `Release All Tables` → 섹션 내 Reserved 일괄 해제 |

`Apply status "Reserved" to all added tables` 토글: 신규 추가 테이블의 기본 상태를 Reserved 로 설정.

### 7.6 Breaking Order · Final Table

| 기능 | 정의 |
|------|------|
| **Breaking Order** | 등록 마감 시 게시. 테이블이 깨질 때 다음 테이블 결정 절차. WSOP Rule 66 |
| **Create Final Table** | Active Player == `max_players + 1` 일 때 버튼 활성. 클릭 시 별도 페이지 (기획 중) |
| **Move Poker Room** | 현재 활성 테이블 전체를 다른 Section 으로 이동. 타겟 Section 의 테이블 수가 더 많아야 함. `MOVE WITH KEEP PLAYER'S POSITION ON ALL TABLE` 만 지원 (재배치는 미제공) |

### 7.7 EBS divergence (WSOP LIVE 와 다른 점)

| 항목 | WSOP LIVE | EBS |
|------|-----------|-----|
| RFID | 미사용 (수동 카드) | RFID 통합 (좌석별 UPCARD + Muck + Community 안테나) |
| Section | Poker Room 단위 | Flight 단위에 Section 매핑. EBS 는 단일 Poker Room 가정 (소형 카지노) |
| `Move Poker Room` 의 `FULLY RE-BALANCED SEATING` | 미제공 | 미제공 (동일) |
| Table Color (식별용 12색 팔레트) | 제공 | 제공 (동일 팔레트 채택) |
| Player Note 5건/100자 한도 | 제공 | 제공 (동일) |

---

## 8. 연관 문서

- `BS-00-definitions.md §3.1` — TableFSM 정의
- `DATA-04-db-schema.md §1.5` — Table 필드 정의
- `BS-03-04-rules.md §5.1` — Late Reg 타이머 계산
- `Registration.md` — Tournament Registration · Sit-in · Seating (별도 신규)
- `Clock_Control.md` — Blind Level 수동 제어 · Break · Day Close (별도 신규)
- `Operations.md` — RFID 안테나 진단
- `CCR-017` — Table 2축 분리 신설 근거
- WSOP LIVE Confluence p1615528545 — Table Management 원본
