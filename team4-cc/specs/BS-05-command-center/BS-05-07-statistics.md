# BS-05-07 Statistics Screen (AT-04)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-04 Statistics 화면 UI·통계 카탈로그·방송 제어 (CCR-027) |
| 2026-04-13 | UI-02 redesign | Hand History Winner/Loser 표시 변경, 10핸드/페이지, Session/Total Hands 추가 |

---

## 개요

AT-04는 운영자가 현재 테이블의 플레이어 통계와 핸드 히스토리를 실시간 확인하고, **방송용 통계 GFX**의 송출 여부를 제어하는 화면이다.

> **참조**: `BS-05-00 §6 AT 화면 카탈로그`, `BS-02-lobby §테이블 통계`, `API-01-backend-api §통계 엔드포인트`.

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

## 4. 통계 카탈로그 (6 지표)

| 통계 | 약어 | 계산 | 표시 |
|------|------|------|------|
| **VPIP** | Voluntarily Put $ In Pot | (자발 베팅 핸드) / (총 핸드) × 100 | % |
| **PFR** | Pre-Flop Raise | (프리플롭 레이즈 핸드) / (총 핸드) × 100 | % |
| **3Bet** | 3-Bet % | (3-Bet 발생) / (3-Bet 기회) × 100 | % |
| **AF** | Aggression Factor | (Bet + Raise) / Call | 소수점 2자리 |
| **Hands** | 총 플레이 핸드 | — | 정수 |
| **WTSD** | Went To Showdown % | (쇼다운 도달) / (플롭 도달) × 100 | % |

---

## 5. 방송 GFX Push

운영자가 각 플레이어 행의 **▶ 버튼**을 누르면 해당 플레이어의 통계가 Overlay에 송출된다.

- `[Push Table Stats to GFX]` — 전체 10좌석 통계를 한 번에 송출
- 각 행의 `▶` — 개별 플레이어 통계를 송출
- GFX 송출은 WebSocket `PushPlayerStats` 프로토콜 (BO → Overlay)

---

## 6. 서버 프로토콜

| 동작 | API |
|------|-----|
| 통계 조회 | `GET /api/v1/tables/{id}/statistics` |
| 핸드 히스토리 | `GET /api/v1/tables/{id}/hands?limit=50` |
| GFX Push | `POST /api/v1/tables/{id}/gfx/push-stats` |
| CSV 내보내기 | `GET /api/v1/tables/{id}/statistics/export?format=csv` |

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
