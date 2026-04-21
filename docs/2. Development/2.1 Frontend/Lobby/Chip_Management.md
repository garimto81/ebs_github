---
title: Chip Management
owner: team1
tier: feature
last-updated: 2026-04-16
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "WSOP LIVE parity 기획 완결되었으나 §6 미결 3건 (CCR 필요 - Multi-Table Add/Pull/Total Removal 일괄 API, Chip Discrepancy, Color-up/Race-off)"
---
# Chip Management

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "08. Chip Management" (Confluence p1801684299) + "Multi-Table Chip Management" (p2285076509) + "Chip Reporter Admin" (p1666155046) 기반 |

---

## 개요

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

## 6. 미결 사항

- 미결: CCR 필요 — Multi-Table Add/Pull/Total Removal 일괄 API 엔드포인트
- 미결: CCR 필요 — Chip Discrepancy 감지 로직 (클라이언트 vs 서버)
- 미결: CCR 필요 — Color-up / Race-off 워크플로우 상세
