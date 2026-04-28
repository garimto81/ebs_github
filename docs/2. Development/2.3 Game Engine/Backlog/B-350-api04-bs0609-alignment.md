---
id: B-350
title: "API-04 §6.0 (21종) ↔ BS-06-09 (19종) OutputEvent 정합 검증 — 누락 3 OE + 번호 shift 분석"
status: DONE
priority: P1
created: 2026-04-28
completed: 2026-04-28
parent: B-349 §3
related-prs:
  - "PR #9 (Phase 2 Triggers 도메인)"
  - "PR #19 (Deprecation shim, OPEN)"
  - "PR #23 (B-349 §3-6 — §3.4.1 정합 매트릭스 + 본 Backlog 등재, MERGED)"
  - "PR (B-351/352/353 — Triggers §3.4 재정렬 + output_event.dart + cross-team 코드, 본 PR)"
authority:
  - "API-04 §6.0 (Overlay_Output_Events.md) — 외부 권위 (subscriber 코드 의존)"
  - "Triggers 도메인 §3.4 (Triggers_and_Event_Pipeline.md) — API-04 정렬 완료"
---

## 2026-04-28 완료

본 Backlog 의 모든 수락 기준이 본 PR (B-351/352/353) 에서 충족:

- ✅ 정합 분석 (PR #23 §3.4.1)
- ✅ Triggers 도메인 §3.4 OE 카탈로그 21종 재정렬 (본 PR Chunk B)
- ✅ B-352 engine code 검증: `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart` 18 클래스 + payload 확장 = 21 OE 정합 (본 PR Chunk A, dart analyze 0 issues)
- ✅ 옛 BS-06-09 OE-11~18 → API-04 OE-14~21 재번호 (본 PR)
- ✅ 누락 3 OE (CardRevealed/CardMismatchDetected/SevenDeuceBonusAwarded) 카탈로그 추가 (본 PR)
- ✅ OE-19 (BS-06-09) → OE-03 displayToPlayers payload 확장 통합 (본 PR)

후속 작업 (별도 PR):
- B-354 (NEW): legacy-id-redirect.json OE-level 매핑 추가 (PR #19 머지 후)
- B-353 §docs: cross-team 90+ docs 갱신 (각 팀 자율 PR)

---

# [B-350] API-04 ↔ BS-06-09 OutputEvent 정합 (P1)

## 문제

도메인 마스터 통합 (PR #9) 이후 다음 두 OutputEvent 카탈로그가 서로 다른 항목 수와 번호를 사용:

| 출처 | 항목 수 | 위치 |
|------|:------:|------|
| **API-04 §6.0** (외부 SSOT) | **21** | `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` |
| **BS-06-09** (행동 명세 view) | 19 | `docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md §3.4` |

## 정합 분석

### 1. 누락 OE (BS-06-09 → API-04)

API-04 에 있으나 BS-06-09 §3.4 에 없는 3 OE:

| API-04 OE | 이름 | 카테고리 | 트리거 | 우선 흡수 위치 |
|:---------:|------|---------|--------|---------------|
| **OE-11** | `CardRevealed` | 카드 | 홀/보드 카드 공개 (Rive reveal) | BS-06-12 §2/§3 권위 (Triggers 도메인 §3.5 T2/T6/T7/T8) — atomic flop / SeatHoleCardCalled 가 emit |
| **OE-12** | `CardMismatchDetected` | 에러 | RFID ↔ 수동 입력 카드 불일치 | Triggers 도메인 §3.16.2 (CC + RFID 다른 카드) + Variants 도메인 §3.17 매트릭스 7 |
| **OE-13** | `SevenDeuceBonusAwarded` | 특별 | 7-2 offsuit 으로 팟 우승 시 보너스 발행 | Variants 도메인 §3.9 7-2 Side Bet 매트릭스 권위 |

### 2. 번호 shift (BS-06-09 OE-11~18 = API-04 OE-14~21)

| BS-06-09 번호 | 이름 | API-04 번호 | 정합 결정 |
|:------------:|------|:-----------:|----------|
| OE-11 | HandTabled (Rule 71) | OE-14 | API-04 권위 |
| OE-12 | HandRetrieved (Rule 110) | OE-15 | API-04 권위 |
| OE-13 | HandKilled (Rule 71 예외) | OE-16 | API-04 권위 |
| OE-14 | MuckRetrieved (Rule 109) | OE-17 | API-04 권위 |
| OE-15 | FlopRecovered (Rule 89) | OE-18 | API-04 권위 |
| OE-16 | DeckIntegrityWarning (Rule 78) | OE-19 | API-04 권위 |
| OE-17 | DeckChangeStarted (Rule 78) | OE-20 | API-04 권위 |
| OE-18 | GameTransitioned (Mixed Omaha) | OE-21 | API-04 권위 |

> **번호 권위 결정**: API-04 가 외부 SSOT (`team1` Frontend, `team4` CC 가 구독). BS-06-09 의 번호는 행동 명세 작성 시 임시 부여된 것이며, 외부 코드 호환성을 위해 API-04 번호로 정렬한다.

### 3. OE-19 (BS-06-09) 의 정체

| BS-06-09 OE-19 | 정의 |
|---------------|------|
| 이름 | `PotUpdated` 확장 필드 |
| payload | `{main, sides, total, display_to_players}` |
| Rule | WSOP Rule 101 |

**판정**: OE-19 는 **별도 OE 가 아니다**. OE-03 `PotUpdated` 의 payload 에 `display_to_players: bool` 플래그를 추가한 **확장 스키마** (Rule 101 적용). 따라서 BS-06-09 의 19 카운트는 **18 OE + 1 payload 확장** 으로 분해되며, 실제 OE 수는 **18**.

API-04 21 종에 OE-03 `PotUpdated` 의 payload 확장이 별도 entry 가 아니라 OE-03 자체의 payload schema 로 통합되어 있다.

### 4. 정합 매트릭스 (최종)

| API-04 권위 OE | API-04 이름 | BS-06-09 매핑 | WSOP Rule |
|:--------------:|-----------|:-------------:|:----------|
| OE-01 | StateChanged | OE-01 ✓ | — |
| OE-02 | ActionProcessed | OE-02 ✓ | — |
| OE-03 | PotUpdated (incl. `display_to_players`) | OE-03 + OE-19 (payload 확장 view) | Rule 101 (Spread Limit hide) |
| OE-04 | BoardUpdated | OE-04 ✓ | — |
| OE-05 | ActionOnChanged | OE-05 ✓ | — |
| OE-06 | WinnerDetermined | OE-06 ✓ | — |
| OE-07 | Rejected | OE-07 ✓ | — |
| OE-08 | UndoApplied | OE-08 ✓ | — |
| OE-09 | HandCompleted | OE-09 ✓ | — |
| OE-10 | EquityUpdated | OE-10 ✓ | — |
| **OE-11** | **CardRevealed** | **MISSING** (BS-06-12 §2/§3 의 SeatHoleCardCalled / FlopRevealed 가 그 sub) | — |
| **OE-12** | **CardMismatchDetected** | **MISSING** (Triggers §3.16.2 / Variants §3.17.M7 에 시나리오만) | — |
| **OE-13** | **SevenDeuceBonusAwarded** | **MISSING** (Variants §3.9 / Betting §5.12 에 알고리즘만) | — |
| OE-14 | HandTabled | BS-06-09 OE-11 (번호 shift) | Rule 71 |
| OE-15 | HandRetrieved | BS-06-09 OE-12 | Rule 110 |
| OE-16 | HandKilled | BS-06-09 OE-13 | Rule 71 예외 |
| OE-17 | MuckRetrieved | BS-06-09 OE-14 | Rule 109 |
| OE-18 | FlopRecovered | BS-06-09 OE-15 | Rule 89 |
| OE-19 | DeckIntegrityWarning | BS-06-09 OE-16 | Rule 78 |
| OE-20 | DeckChangeStarted | BS-06-09 OE-17 | Rule 78 |
| OE-21 | GameTransitioned | BS-06-09 OE-18 | Mixed Omaha (CCR-051) |

## 결정

### 권위 분리

- **외부 API 계약 (subscriber 호환)**: API-04 §6.0 21 OE 권위
- **행동 명세 view**: BS-06-09 (Triggers 도메인 §3.4) 는 API-04 의 sub-view — 본 PR 에서 cross-ref + 누락 3 OE 보강

### 보강 작업 (본 PR Chunk A)

1. **Triggers 도메인 §3.4 끝에 §3.4.1 OutputEvent 카탈로그 권위 정합 추가**:
   - API-04 ↔ BS-06-09 매핑 표 (위 §4 매트릭스)
   - OE-11/12/13 (CardRevealed/CardMismatchDetected/SevenDeuceBonusAwarded) 항목 정의 (행동 측면 view, payload + 트리거 + 권위 위임 cross-ref)
   - OE-19 (BS-06-09) 가 OE-03 의 payload 확장임을 명시
   - 번호 shift 명시: "BS-06-09 OE-11~18 ↔ API-04 OE-14~21 (3 칸)"

2. **부록 C (Output Event 카탈로그 권위) 보강**: 기존 §부록 C 가 외부 SSOT 위치만 가리킴 → 본 정합 매트릭스 cross-ref 추가

### 향후 작업 (별도 PR)

- **B-351**: Triggers 도메인 §3.4 의 OE 번호를 API-04 권위로 전체 재번호 (큰 변경 — 별도 PR + cross-team review)
- **B-352**: 코드 (`lib/core/output/output_event_buffer.dart`) 의 OE 번호가 API-04 와 정합하는지 검증 (engine 측 enum 검사)

## 수락 기준

- [x] 정합 분석 (본 문서)
- [x] Triggers 도메인 §3.4.1 OutputEvent 카탈로그 권위 정합 보강 (본 PR Chunk A)
- [ ] B-351 OE 번호 재정렬 (별도 PR)
- [ ] B-352 engine code 검증 (별도 PR)

## 관련

- B-349 (Domain Master Rollout) §3 — 본 작업의 parent
- PR #9 (Triggers 도메인 마스터)
- API-04 §6.0 (Overlay_Output_Events.md) — 외부 권위
- WSOP Rules 71/78/89/101/109/110 — 정합 매트릭스 보존
