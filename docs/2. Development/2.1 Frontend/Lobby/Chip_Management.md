---
title: Chip Management
owner: team1
tier: feature
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "Conductor Mode A 자율 cascade (2026-05-03) — WSOP LIVE Confluence 미러 SSOT lookup 후 §6 미결 3건 모두 결정 완료. (1) Multi-Table API: wsoplive Multi-Table Chip Management page 2285076509 명세 그대로 채택 (Add/Pull/Total Removal 3 endpoints). (2) Chip Discrepancy: wsoplive Chip Master 개선 page 2258535305 패턴 (Approve/Reject/Cancel + Lost Quantity 추적). (3) Color-up/Race-off: TDA Rules 표준 + EBS 자체 추가 (§5 line 117 이미 명시). 외부 개발팀 인계 가능 SSOT 확정"
---
# Chip Management

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "08. Chip Management" (Confluence p1801684299) + "Multi-Table Chip Management" (p2285076509) + "Chip Reporter Admin" (p1666155046) 기반 |
| 2026-05-07 | v3 cascade | Lobby_PRD v3.0.0 정체성 정합 — 운영자 게이트웨이 흐름 framing 추가 (additive only). |

---

## 개요

> **WSOP LIVE 정보 허브 역할 (Lobby_PRD v3.0.0 cascade, 2026-05-07)**: 운영자가 5 분 게이트웨이 동안 확인하는 **테이블별 Chip Set / Multi-Table 일괄 처리 / Chip Reporter**. Lobby = WSOP LIVE 거울의 한 면.

Flight 내 테이블별 Chip Set 관리 화면. 개별 테이블 칩 수 조회, Multi-Table 일괄 Add/Pull/Total Removal, Chip Reporter 역할 지원. WSOP LIVE Staff App §08 Chip Management 와 동일한 구조를 채택한다.

---

## 1. 기능 범위

| 기능 | 설명 |
|------|------|
| **테이블별 Chip Count** | 각 테이블의 현재 Chip Set 수 표시 |
| **Multi-Table Add Chips** | 선택한 테이블 전체에 동일 수량 Chip Set 일괄 추가 |
| **Multi-Table Pull Chips** | 선택한 테이블 전체에서 동일 수량 Chip Set 일괄 제거 |
| **Total Removal** | 전체 테이블 잔여 Chip Set을 0으로 리셋 (Alter 이동) |
| **Chip Discrepancy 감지** | 테이블별 합산 불일치 시 경고 표시 |
| **Chip Reporter** | 읽기 전용 Staff Role — 테이블 선택 후 플레이어별 칩 수량 입력 |
| **Color-up / Race-off** | 미결: 향후 구현 대상 |

---

## 2. 화면 구조

### 2.1 Chip 대시보드 (Flight 레벨)

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Table No. | 읽기 전용 | 바둑판 또는 리스트 뷰 |
| Current Chip Sets | 읽기 전용 | 테이블당 현재 보유량 |
| Status | Badge | Reserved 테이블은 자물쇠 아이콘 |

상단 버튼: `Add Chips`, `Pull Chips`, `Total Removal`

### 2.2 Multi-Table Add Chips 모달

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Chip Sets per Table | Input (number) | 추가할 수량 |
| Total Add Chip Sets | 읽기 전용 | 선택 테이블 수 x 수량 |
| Select All | Checkbox | |
| Hide Reserved Table | Toggle (기본 Off) | On 시 Reserved 테이블 숨김 |
| Table List | Checkbox 목록 | Reserved 표시 포함 |

### 2.3 Multi-Table Pull Chips 모달

Add Chips와 동일 레이아웃. 제거 수량 입력.

### 2.4 Total Removal 모달

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Chips to Alter | 읽기 전용 | 전체 잔여 Chip Sets 합계 |
| 확인 문구 | 읽기 전용 | "모든 테이블의 잔여 칩이 0으로 변경됩니다" |

버튼: `Cancel`, `Confirm`

### 2.5 Chip Reporter 뷰

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Table 선택 | Dropdown | Chip Reporter에게 할당된 테이블 |
| Seat No. | 읽기 전용 | |
| Player | 읽기 전용 | |
| Chip Count | Input (number) | 입력 가능 (BUST 제외) |

---

## 3. 데이터 흐름

| 동작 | API | 비고 |
|------|-----|------|
| 좌석별 칩 수 조회 | `GET /Tables/:id/seats` → `chip_count` 필드 | Backend_HTTP §5.9 |
| 좌석별 칩 수 수정 | `PATCH /Seats/:id` → `{chipCount}` | Backend_HTTP §5.9 |
| Multi-Table Add/Pull | 미정의 | 미결: CCR 필요 — 일괄 엔드포인트 |
| Total Removal | 미정의 | 미결: CCR 필요 |
| Chip Discrepancy 검증 | 미정의 | 클라이언트 계산 또는 서버 검증 미확정 |

---

## 4. RBAC

| 동작 | Admin | Operator | Chip Reporter | Viewer |
|------|:-----:|:--------:|:------------:|:------:|
| Chip 대시보드 조회 | O | O | O | O |
| Multi-Table Add/Pull/Removal | O | X | X | X |
| 개별 테이블 칩 입력 | O | O (해당 테이블) | O (해당 테이블) | X |
| Chip Reporter 뷰 진입 | X | X | O | X |

---

## 5. WSOP LIVE Parity

| WSOP LIVE 기능 | EBS 적용 | 비고 |
|---------------|:-------:|------|
| Multi-Table Add Chips | Apply | |
| Multi-Table Pull Chips | Apply | |
| Total Removal (Alter 이동) | Apply | |
| Hide Reserved Table 토글 | Apply | |
| Select All 테이블 | Apply | |
| Chip Reporter Role (BUST 제외) | Apply | |
| Color-up / Race-off | Add (향후) | WSOP LIVE에 별도 기획 없음, EBS 자체 추가 예정 |

---

## 6. 결정 사항 (Conductor Mode A 자율 cascade — 2026-05-03)

> ✅ **DONE** — V9.4 AI-Centric. 사용자 도메인 질문 0회. WSOP LIVE Confluence 미러 (`C:/claude/wsoplive/`) SSOT lookup 후 자율 결정.

### 6.1 Multi-Table Add/Pull/Total Removal 일괄 API

**SSOT**: WSOP LIVE Confluence "Multi-Table Chip Management" (page 2285076509)

**채택 spec** (publisher cascade 권고 — team2):

| Endpoint | Method | Purpose | Response |
|----------|:------:|---------|----------|
| `/api/v1/flights/{id}/chips/multi-add` | POST | 선택 테이블 일괄 칩 추가 | 200 + applied_table_ids |
| `/api/v1/flights/{id}/chips/multi-pull` | POST | 선택 테이블 일괄 칩 회수 | 200 + applied_table_ids |
| `/api/v1/flights/{id}/chips/total-removal` | POST | 모든 테이블 잔여 칩 0 + Alter 이동 | 200 + chips_to_alter |

**Request payload** (Add/Pull 공통):
```json
{
  "chip_sets": 10,
  "table_ids": ["t1", "t2"],
  "include_reserved": false
}
```

**WSOP LIVE 정합 항목**:
- Add Chips: 선택 테이블 N × chip_sets 칩 추가
- Pull Chips: 선택 테이블 N × chip_sets 칩 제거
- Total Removal: 모든 테이블 잔여 칩 → Alter (안내 문구 "All tables will change their remaining chips set to 0 and will move to Alter")
- Reserved 테이블 표시 (Hide Reserved Table 토글)

### 6.2 Chip Discrepancy 감지 로직

**SSOT**: WSOP LIVE Confluence "Chip Master 개선" (page 2258535305)

**채택 spec**:

| 단계 | 처리 |
|------|------|
| 클라이언트 입력 | TD 가 Chip Request (Set / Chip 단위) 제출 |
| 서버 검증 | Chip Master approve/reject. Lost Quantity 자동 추적 |
| Discrepancy 표시 | 클라이언트 Total Edit 버튼 → add/remove chip set 등록. Total Chips 버튼 → 실시간 Total Served Chips 표시 |
| Audit | History 탭 (Action Category=Chip Management, Type=Request/Cancel/Approve/Reject) |
| EOD 정합 | EOD Chip Count vs 실제 잔여 칩 비교. 'Chips to Next Day' 버튼으로 다음 flight 이월 |

**EBS 추가 결정** (server-side enforcement):
- 클라이언트 입력 vs 서버 잔여 칩 mismatch ≥ 1 set → `chip_discrepancy` event 발화 → Chip Master 알림
- WebSocket event `chip.discrepancy.detected` (별도 SG-* 후속)

### 6.3 Color-up / Race-off 워크플로우

**SSOT**: TDA Rules 표준 + EBS 자체 추가 (§5 line 117 이미 명시 — "WSOP LIVE에 별도 기획 없음, EBS 자체 추가 예정")

**채택 워크플로우** (publisher cascade 권고):

| 단계 | 처리 |
|------|------|
| Trigger | Blind level 상승 시 작은 chip denomination 폐기 (TD 결정) |
| Color-up | 작은 칩을 큰 denomination 으로 1:1 교환 — 잔여 calculation 시 stack ≥ small_chip_value |
| Race-off | 잔여가 1 큰 칩 미만 시 chip race (1 deck 카드 1장씩 분배, 가장 높은 카드 보유자 승) |
| 실행 | TD 가 Tournaments → Chip Management 화면에서 'Color-up / Race-off' 버튼 클릭 → 모든 active table 일괄 적용 |
| Audit | History 탭 Action Category=Color-up/Race-off, Staff=TD, Detail=before/after chip distribution |

**EBS API endpoint** (publisher cascade — team2):
- `POST /api/v1/flights/{id}/color-up` — Body: `{ "remove_denomination": 25, "convert_to": 100 }`
- `POST /api/v1/flights/{id}/race-off` — Body: `{ "denomination": 25, "method": "deck_card_high" }`

### Cross-references

- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md`: 6.1/6.2/6.3 endpoints 추가 (publisher cascade)
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`: §13 추가 events (chip.discrepancy.detected, table.color_up.applied, table.race_off.applied)
- WSOP LIVE pages: 2285076509 (Multi-Table) + 2258535305 (Chip Master 개선) + 1666155046 (Chip Reporter Admin)
- TDA Rules: poker tournament standard rules
