---
title: Prize Pool & Payout Management
owner: team1
tier: feature
last-updated: 2026-04-16
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "Prize Pool & Payout 기획 완결"
---
# Prize Pool & Payout Management

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "Prize Pool / Payout Assignment / Payments" (Confluence p1647181953) 기반 |

---

## 개요

Flight Admin 화면 내 Prize Pool / Payout Assignment / Payments 3-탭 구조. Late Registration 종료 후 Prize Pool 생성, ITM 구간 Payout 확정, 지급 상태 추적까지의 워크플로우를 제공한다. WSOP LIVE Staff App §04 "Prize Pool / Payout Assignment / Payments" 와 동일한 구조를 채택한다.

---

## 1. 기능 범위

| 기능 | 설명 |
|------|------|
| **Prize Pool 생성** | Late Registration 종료 후 `Create Prize Pool List` 버튼 활성화. Payout Structure 기반 상금 리스트 생성 |
| **Prize Pool 편집** | Rank별 Prize 수동 수정, CSV Upload/Download, Difference 검증 (0이 아니면 Publish 비활성화) |
| **Publish** | Save 클릭 시 확인 모달 → 상금 확정. Published at / Staff 표시 |
| **Payout Assignment** | ITM 탈락 순서대로 아래→위 적재. Confirm / Edit / Combine (Simultaneous Elimination) |
| **Bubble 구간** | ITM 인원 + 10명까지 노출. Prize $0 → Confirm 시 리스트에서 제거 |
| **Payments** | Cashier 지급 완료 내역 읽기 전용. Payment Method (Cash/Wire/Check), Tax, Payout Amount |
| **CSV Export** | Prize Pool / Payout Assignment / Payments 각 탭에서 CSV Download |

---

## 2. 화면 구조

### 2.1 Prize Pool 탭

| 필드 | 컨트롤 | 기본값 | 비고 |
|------|--------|--------|------|
| Rank | 읽기 전용 | 1~N | 자동 생성 |
| Prize | Input (number) | Payout Structure 기반 | 수정 가능 |
| Total Prize | 읽기 전용 | `Total Entries × Buy-in` | |
| Sum | 읽기 전용 | `SUM(Prize)` | |
| Difference | 읽기 전용 | `Total Prize - Sum` | 0이 아니면 빨간색 |

버튼: `Create Prize Pool List` (Late Reg 종료 전 비활성화), `CSV Upload`, `CSV Download`, `Cancel`, `Save`

### 2.2 Payout Assignment 탭

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Rank | 읽기 전용 | ITM 최하위부터 적재 |
| Player | 읽기 전용 + 화살표 (순위 이동) | Confirmed 순위로는 이동 불가 |
| Payout | Input (미확정) / 읽기 전용 (확정) | |
| Assign Date | 읽기 전용 | Confirm 시점 + Staff명 |
| Status | Confirmed / Paid | |

버튼: `Combine` (Simultaneous Elimination), `CSV Download`, `Confirm` (최하위 미확정 순위에만 표시)

### 2.3 Payments 탭

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| No. | 읽기 전용 | 처리 순서 |
| Date | 읽기 전용 | 처리 시각 |
| Player | 읽기 전용 | |
| Payment Method | 읽기 전용 | Cash / Wire Transfer / Check |
| Staff | 읽기 전용 | 처리 Staff명 |
| Type | 읽기 전용 | Prize / Bounty |
| Prize/Bounty | 읽기 전용 | 획득 상금 |
| Tax | 읽기 전용 | 세금 차감액 |
| Payout Amount | 읽기 전용 | Prize - Tax |

---

## 3. 데이터 흐름

| 동작 | API | 비고 |
|------|-----|------|
| Prize Pool 조회 | `GET /flights/:id/payout-structure` | Backend_HTTP §5.13.1 |
| Prize Pool 수정 | `PUT /flights/:id/payout-structure` | `prize_pool_changed` WS 이벤트 |
| Prize Pool 생성/Publish | 미정의 | 미결: CCR 필요 |
| Payout Confirm | 미정의 | 미결: CCR 필요 |
| Payout Combine | 미정의 | 미결: CCR 필요 |
| Payments 목록 | 미정의 | 미결: CCR 필요 |

---

## 4. RBAC

| 동작 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| Prize Pool 조회 | O | O | O |
| Prize Pool 생성/편집/Publish | O | X | X |
| Payout Confirm/Edit/Combine | O | X | X |
| Payments 조회 | O | O (읽기) | O (읽기) |
| CSV Download | O | O | X |

---

## 5. WSOP LIVE Parity

| WSOP LIVE 기능 | EBS 적용 | 비고 |
|---------------|:-------:|------|
| Prize Pool 3-탭 구조 | Apply | |
| CSV Upload/Download | Apply | |
| Difference 검증 (빨간색) | Apply | |
| Simultaneous Elimination (Combine) | Apply | |
| Bubble 구간 (ITM + 10) | Apply | |
| Place Card 발송 (App/Mail) | Remove | EBS에 Player App 없음 |
| Casino Chip Payment Method | Remove | EBS 운영 환경에 해당 없음 |
| Paid 상태 Payout 수정 불가 | Apply | |

---

## 6. 미결 사항

- 미결: CCR 필요 — Prize Pool Create/Publish, Payout Confirm/Combine, Payments 목록 API 엔드포인트 미정의
- 미결: CCR 필요 — Bounty Tournament의 Payout 분리 표시 방식
- 미결: CCR 필요 — Tax 계산 로직 (국가별 세율 적용 여부)
