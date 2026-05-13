---
id: B-356
title: "OE 카탈로그 self-inconsistency — OutputEvent_Serialization vs Overlay_Output_Events 정합"
backlog-status: open
priority: P1
created: 2026-05-08
parent: S8 consistency audit 2026-05-08 (D2)
related-files:
  - "docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md"
  - "docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md"
related-issue: "#167 (S8 consistency audit)"
related-foundation: "Foundation §B.1 (21 OutputEvent 카탈로그)"
mirror: none
---

# [B-356] OE 카탈로그 self-inconsistency 정합

## 배경 (S8 audit 2026-05-08, D2 [HIGH])

S8 정합성 감사 V3 (21 OutputEvent 카탈로그 self-consistency) 검증 중,
`OutputEvent_Serialization.md` 와 `Overlay_Output_Events.md` 두 contract 파일이 동일 OE 번호에 다른 의미를 부여하고 있음을 발견.

## Drift 상세

### 1. OE-12 ~ OE-21 매핑 충돌

| OE 번호 | OutputEvent_Serialization.md | Overlay_Output_Events.md (publisher 실측, 2026-04-15) |
|:-------:|------------------------------|------------------------------------------------------|
| OE-12 | HandRetrieved | CardMismatchDetected |
| OE-13 | HandKilled | SevenDeuceBonusAwarded |
| OE-14 | MuckRetrieved | HandTabled |
| OE-15 | FlopRecovered | HandRetrieved |
| OE-16 | DeckIntegrityWarning | HandKilled |
| OE-17 | DeckChangeStarted | MuckRetrieved |
| OE-18 | GameTransitioned | FlopRecovered |
| OE-19 | (PotUpdated, OE-03 통합) | DeckIntegrityWarning |
| OE-20 | (누락) | DeckChangeStarted |
| OE-21 | (별도 §섹션 존재) | GameTransitioned |

### 2. Overlay_Output_Events.md 내부 self-inconsistency

- 변경 이력 (line 18, 2026-04-15): `OE-05 ActionOnChanged`
- 본문 (line 123, frontmatter mapping): `OE-05 CardRevealed(board)`

### 3. 카탈로그 범위 표기 vs 실제 §섹션

- `OutputEvent_Serialization.md` line 42, 256: "OE-01 ~ OE-21" 명시
- 실제 §섹션 갯수: 19개 (OE-19 통합, OE-20 누락)

## 정합 작업 spec

### Phase A: 정본 결정 (publisher 코드 실측)
- `team3-engine/ebs_game_engine/lib/.../output_event.dart` 직접 확인
- 21 OE 번호 → 이름 매핑 권위 산출
- `Overlay_Output_Events.md §6.0` 변경 이력에 따르면 publisher 실측이 정본 (2026-04-15 정합)

### Phase B: OutputEvent_Serialization.md 재정렬
- 모든 §섹션 OE 번호 → publisher 정본으로 매핑
- 본문 예시 / JSON 스키마 / 직렬화 코드 path 동시 정합
- §섹션 갯수 = 정확히 21개 (OE-01 ~ OE-21)

### Phase C: Overlay_Output_Events.md 내부 정합
- 변경 이력 vs 본문 mapping 충돌 해소
- 단일 정본 표기로 통일

### Phase D: B-353/B-354 cross-team citation 일괄 갱신
- 101 cross-team citation 중 OE-XX 인용은 새 매핑으로 redirect

## 수락 기준

- [ ] publisher `output_event.dart` 코드 실측 → 21 OE 매핑 표 작성
- [ ] OutputEvent_Serialization.md §섹션 21개 모두 publisher 매핑 정합
- [ ] Overlay_Output_Events.md 내부 self-inconsistency 0건
- [ ] 두 파일에서 동일 OE 번호 → 동일 이름 100% 일치
- [ ] `tools/validate_redirects.dart` (B-355) 가 cycle/충돌 0건 확인
- [ ] B-353 cross-team citation 101건 중 OE-XX 항목 새 매핑 반영

## 우선순위 사유 (P1)

- OE 카탈로그는 contract tier (Team 3 ↔ Team 4 in-process 통신 계약)
- self-inconsistency 가 있는 한 team 4 (CC) 의 dispatchState 구현이 어느 OE 번호를 신뢰해야 하는지 불명
- 단, 단일 PR 로 완결 불가 (publisher 코드 직접 확인 + 두 파일 22+ 섹션 재정렬 필요) → 별도 작업 분리

## 관련

- Issue: #167 (S8 Game Engine 정합성 감사 2026-05-08)
- 사고 발견 위치: `docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S8-engine.md` V3 검증 항목
- Foundation 권위: §B.1 (21 OutputEvent 카탈로그)
- 후속 PR: TBD (별도 issue 생성 예정 — Engine 작업 phase 활성화 시점)
