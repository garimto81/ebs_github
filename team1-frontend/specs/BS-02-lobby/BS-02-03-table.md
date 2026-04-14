# BS-02-03 Table 상태 — TableFSM + `is_pause` 직교 축

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Table 상태 2축 분리: TableFSM × `is_pause` (CCR-017) |

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

## 6. 연관 문서

- `BS-00-definitions.md §3.1` — TableFSM 정의
- `DATA-04-db-schema.md §1.5` — Table 필드 정의
- `BS-03-04-rules.md §5.1` — Late Reg 타이머 계산
- `CCR-017` — 본 문서 신설 근거
