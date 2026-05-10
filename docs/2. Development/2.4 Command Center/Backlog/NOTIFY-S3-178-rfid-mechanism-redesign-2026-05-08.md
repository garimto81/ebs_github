---
title: NOTIFY-S3-178 — RFID 12 안테나 메커니즘 재설계 (Mock-only 자율 해소)
owner: conductor
target: stream:S3 (Command Center)
tier: notify
status: RESOLVED
issue: 178
resolved-date: 2026-05-08
resolution: "사용자 결정 'RFID = Mock-only' (2026-05-08) → Card_Detection.md §1 자율 재설계 완료. HW 검증 불필요 (cardUid 기반 분리 인식)."
related: NOTIFY-S1-rfid-antenna-count-mismatch-2026-05-08.md
last-updated: 2026-05-08
mirror: none
---

# NOTIFY-S3-178 — RFID 12 안테나 메커니즘 재설계 (Mock-only 자율 해소)

## 🟢 RESOLVED (2026-05-08 — 사용자 결정 + Phase D 자율 처리)

**해소 결정**: 사용자가 2026-05-08 turn 에서 명시 — **"RFID HW 메커니즘 재설계 - 이 프로젝트에서는 rfid 기술을 mock 으로 처리"**. 메모리 `project_rfid_out_of_scope_2026_04_29.md` 와 정합 재확인.

**자율 재설계 완료** (commit Phase D 진행 중):
- §1.1 표: 24 → 12 안테나 분배 (좌석 0~9 + 보드 10/11)
- §1.1 mermaid: 12 안테나 재설계
- §1.2 매핑 룰: `seatIndex = antennaId` (좌석당 1 안테나, cardUid 기반 홀카드 1·2 분리)
- §2.1: Mock 정규 경로 / §2.2: Real 별도 설계 (본 프로젝트 범위 밖)
- §3.1: 보드 안테나 10/11 재배치
- changelog: 2026-05-08 entry 추가 (Mock-only 재설계)

**HW 검증 불필요**: Mock 환경에서 `MockRfidReader.injectCard` 가 cardUid 기반으로 분리 인식 보장. Real HW 도입 시 §2.2 흐름 + 외부 vendor 협업 별도 작업.

**원 NOTIFY 본문 (HW 검증 질문)** = 본 해소로 무효. 아래는 historical reference.

---

## 트리거 (HISTORY)

Issue #178 자율 처리의 부분 cleanup. Conductor Phase C (#168 후속) 자율 iteration 에서 표기 정정 (24 → 12) 만 자율 처리됨. HW 메커니즘 재설계는 본 NOTIFY 로 분리 — 좌석당 안테나 수 변경이 카드 인식 메커니즘 자체에 영향이라고 가정했으나, **사용자 RFID Mock-only 정책 명시로 자율 해소**.

## 자율 처리된 부분 (commit 진행 중)

`docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md`:
- frontmatter `last-updated`: 2026-04-29 → 2026-05-08
- changelog 새 entry 추가 (#178 사유 명시)
- §"정의" 안테나 항목: "좌석별 2개 + 보드 4개" → "Foundation §C.2 정점 SSOT = 12 안테나 (좌석 + 보드 중앙)"
- §1.1 mermaid 직후 비고: "API-03 §5.1 — 테이블당 최대 24개" → "12개"

## 자율 한계 — 본 NOTIFY 처리 항목 (S3 worktree)

### A. §1.1 안테나 ID 규약 표 (line 53-58)

기존 24 안테나 분배:

| 안테나 ID | 위치 | 용도 |
|:---------:|------|------|
| 0~9 | Seat 0~9 좌측 | 홀카드 1번 |
| 10~19 | Seat 0~9 우측 | 홀카드 2번 |
| 20~22 | Board 좌/중/우 | Flop 카드 3장 |
| 23 | Board 추가 | Turn / River 카드 |

→ 12 안테나 분배 후보 (HW 검증 필요):

| 옵션 | 좌석 | 보드 | atomic Flop 가능? | 양 홀카드 분리 인식? |
|:----:|:----:|:----:|:----------------:|:-------------------:|
| (가) 좌석 10 + 보드 2 | 좌석당 1 안테나 | 보드 2 (Flop 합집합 + Turn/River) | △ Flop 3장 분리 인식 한계 | ✗ 양 홀카드 합집합만 |
| (나) 좌석 9 + 보드 3 | 9 좌석 (10번째 미커버) | Flop atomic 가능 | ✓ | ✗ |
| (다) 좌석 0 + 보드 12 | 좌석 무 (Mock 전용) | 보드 폐기 | ✗ HW 불가 | ✗ |

**HW 검증 질문** (사용자/HW 팀 답변 필요):
1. 좌석당 1 안테나로 양 홀카드 (Hold'em 2장) 를 분리 인식 가능한가? UID 기반 cardUid 만으로 분리?
2. Flop 3장 atomic 인식을 보드 안테나 1~3 개로 보장 가능한가?
3. RFID 안테나의 물리적 감지 영역 (좌석당 너비 cm) 으로 12 안테나 = 한 테이블 전체 커버?

### B. §1.1 mermaid 다이어그램 (line 60-77)

24 안테나 분배 (좌석 20 + 보드 4) → 12 안테나 분배로 재설계.

### C. §1.2 좌석 안테나 → 플레이어 매핑 (line 81-86)

기존: `seatIndex = antennaId % 10` (좌석당 2 안테나 가정)
변경: 좌석당 1 안테나면 `seatIndex = antennaId` (또는 별도 매핑)
홀카드 1/2 분리 인식 메커니즘 재정의 (cardUid 기반?)

### D. §3.1 보드 카드 감지 (line 122-127)

기존 보드 안테나 4개 (20~22 Flop, 23 Turn/River) → 보드 안테나 1~3 개로 재배치.
Flop 3장 atomic 인식 메커니즘 재설계 (§3.3 cascade).

### E. Mock HAL 영향

`MockRfidReader.injectCard(suit, rank, antennaId)` 의 antennaId 검증 룰 (0~23 → 0~11) 정정.

## 우선순위

본 issue 차단 = #168 통합 검증 완료를 차단하지 않음. Foundation §C.2 정점 SSOT 표기 정정만 자율 완료 후 HW 메커니즘 재설계는 후속 PR.

## 작업 분배

S3 (Command Center) worktree 가 정본 영역 owner. HW 검증은 외부 HW 팀 협업 필요 (`team4` 영역의 RFID HAL 구현 + 외부 HW 발주).

## 관련

- Issue #178 (RFID 24 → 12 정정)
- NOTIFY-S1-rfid-antenna-count-mismatch-2026-05-08.md (원 발견 source)
- Foundation v4.5 §C.2 (정점 SSOT, 12 안테나)
- Card_Detection.md §1 (자율 정정 entry: 2026-05-08 changelog)
- API-03 RFID_HAL.md §5.1
- Memory: `project_rfid_out_of_scope_2026_04_29.md` (RFID HW = Mock-only, vendor 5/1 발송)
