---
title: NOTIFY-S1 — RFID 안테나 수 모순 (12 vs 24)
owner: stream:S3 (Command Center)
target: stream:S1 (Foundation)
tier: notify
status: OPEN
last-updated: 2026-05-08
audit-source: docs/4. Operations/orchestration/2026-05-08-consistency-audit/
---

# NOTIFY-S1 — RFID 안테나 수 모순 (12 vs 24)

## 트리거

2026-05-08 Phase 0 정합성 감사 (S3 Command Center) 진행 중 발견. Foundation §Ch.5 §C.2 와 정본 spec `Card_Detection.md §1` 의 안테나 수가 **의미적으로 모순**.

## 모순 위치

| 출처 | 안테나 수 | 분배 |
|------|:---------:|------|
| `docs/1. Product/Foundation.md` Ch.5 §C.2 (line 770~771) | **12** | 좌석 + 보드 중앙 |
| `docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md` §13 | **12** | (Foundation 그대로 추출) |
| `docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md` §1 (line 53~79) | **24** | 좌석 좌측 10 + 좌석 우측 10 + 보드 4 |
| `docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md` §1.2 mermaid | **24** | `seatIndex = antennaId % 10` (좌석당 2 안테나) |
| API-03 §5.1 (Card_Detection 인용) | **24** | 테이블당 최대 |

## 의미적 차이

| 측면 | Foundation 12 | 정본 24 |
|------|--------------|---------|
| 좌석당 안테나 | 1 (가정) | 2 (홀카드 1 + 홀카드 2 분리 인식) |
| 보드 안테나 | 2 (중앙) | 4 (Flop atomic 3 + Turn/River 1) |
| HW 설계 의도 | 좌석/보드 통합 인식 | 좌석 좌우 분리 + 보드 다중 |

**HW 설계 핵심 결정사항** (좌석당 안테나 수, Flop atomic 인식 메커니즘) — S3 가 임의 정정 불가.

## 요청 (S1)

Foundation §Ch.5 §C.2 의 "12 안테나" 가 다음 중 어느 의도인지 확정 + cascade:

- **Option A**: Foundation 12 가 정확 → 정본 Card_Detection §1 의 24 안테나 표기를 12 로 정정 (S1 owns Foundation, Conductor authorizes 정본 수정).
- **Option B**: 정본 24 가 정확 → Foundation §Ch.5 §C.2 + foundation_ssot.md §13 + Foundation §Ch.6 표 (line 901, 919, 1152) 모두 24 로 cascade. S3 는 Foundation 영역 미터치, S1 cascade 후 S3 재감사.

## S3 차단 영역

본 모순은 S3 의 PR (#171, consistency audit 2026-05-08) 머지를 차단하지 않음 — frontmatter / 6 키 / 5-Act / 1×10 cascade 는 정합 완료. RFID 안테나 수만 escalate 항목으로 PR 본문에 명시.

## 참조

- `docs/1. Product/Foundation.md` line 471, 766, 768, 770, 888, 892, 901, 919, 1152
- `docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md` §1 (line 53~127)
- `docs/2. Development/2.4 Command Center/APIs/RFID_HAL_Interface.md` (drift_ignore_rfid=true — 본 NOTIFY 와 무관)
- 본 NOTIFY 의 audit-source 는 `docs/4. Operations/orchestration/2026-05-08-consistency-audit/` Phase 0 감사 spec
