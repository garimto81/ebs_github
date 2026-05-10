---
id: B-354
title: "legacy-id-redirect.json 에 OE-level 매핑 추가 — API-04 OE-XX ↔ BS-06-09 OE-XX 번호 변환"
status: DONE
priority: P2
created: 2026-04-28
completed: 2026-04-29
parent: B-349 §6 + B-350
related-prs:
  - "PR #19 (Deprecation shim + legacy-id-redirect.json 신규, MERGED 2026-04-28)"
  - "PR #25 (B-351/352/353 — output_event.dart + Triggers §3.4 재정렬, MERGED 2026-04-28)"
  - "PR #65 (B-355 — redirect validator infrastructure, MERGED 2026-04-29)"
  - "PR (B-354 본체 — output_events sub-section 주입, 본 PR)"
mirror: none
---

# [B-354] legacy-id-redirect.json OE 매핑 추가 (P2)

## 배경

PR #19 (legacy-id-redirect.json 신규) 가 머지되면, 본 PR 의 B-351 OE 번호 재정렬 결과를 mapping JSON 에 반영해야 한다. 단, PR #19 가 OPEN 상태라 본 PR 에 직접 추가 불가 (conflict 위험).

## 추가 매핑 사양

`docs/_generated/legacy-id-redirect.json` 의 `mappings` 객체에 별도 sub-section `output_events` 추가:

```json
{
  "output_events": {
    "_meta": {
      "authority": "API-04 §6.0 (Overlay_Output_Events.md) 21종",
      "code_authority": "team3-engine/ebs_game_engine/lib/core/actions/output_event.dart",
      "spec_view": "Triggers_and_Event_Pipeline.md §3.4 (재정렬 완료, B-351/352)",
      "_note": "PR #B351 머지 후 본 매핑 활성. OE 번호 권위는 API-04 (subscriber 호환)."
    },
    "api04_to_bs0609_legacy": {
      "OE-01": "OE-01 StateChanged (변경 없음)",
      "OE-02": "OE-02 ActionProcessed (변경 없음)",
      "OE-03": "OE-03 PotUpdated (BS-06-09 의 OE-19 displayToPlayers 통합)",
      "OE-04": "OE-04 BoardUpdated (변경 없음)",
      "OE-05": "OE-05 ActionOnChanged (변경 없음)",
      "OE-06": "OE-06 WinnerDetermined (변경 없음)",
      "OE-07": "OE-07 Rejected (변경 없음)",
      "OE-08": "OE-08 UndoApplied (변경 없음)",
      "OE-09": "OE-09 HandCompleted (변경 없음)",
      "OE-10": "OE-10 EquityUpdated (변경 없음)",
      "OE-11": "(NEW) CardRevealed — BS-06-09 에 없음, API-04 에서 추가",
      "OE-12": "(NEW) CardMismatchDetected — BS-06-09 에 없음",
      "OE-13": "(NEW) SevenDeuceBonusAwarded — BS-06-09 에 없음",
      "OE-14": "BS-06-09 OE-11 HandTabled (3칸 shift)",
      "OE-15": "BS-06-09 OE-12 HandRetrieved",
      "OE-16": "BS-06-09 OE-13 HandKilled",
      "OE-17": "BS-06-09 OE-14 MuckRetrieved",
      "OE-18": "BS-06-09 OE-15 FlopRecovered",
      "OE-19": "BS-06-09 OE-16 DeckIntegrityWarning",
      "OE-20": "BS-06-09 OE-17 DeckChangeStarted",
      "OE-21": "BS-06-09 OE-18 GameTransitioned"
    }
  }
}
```

## 진행 조건 (BLOCKED → READY)

- PR #19 머지 (legacy-id-redirect.json 본문이 main 에 진입)
- PR (B-351/352/353) 머지 (Triggers §3.4 재정렬이 main 에 진입)

두 PR 모두 머지 후 본 Backlog 작업자가 sibling worktree 에서:

1. `legacy-id-redirect.json` 의 `mappings` 객체 내 `output_events` sub-section 추가
2. `_meta.audit_hints` 에 `output_event_mapping_authority` 항목 추가
3. `tools/_create_legacy_id_redirect.py` 같은 idempotent script (있다면 갱신)
4. JSON 유효성 검증 (`python -m json.tool`)
5. PR 단일 commit + push

## 수락 기준

- [ ] `output_events` sub-section 추가됨
- [ ] api04_to_bs0609_legacy 21 매핑 모두 명시
- [ ] JSON 유효성 검증 PASS
- [ ] audit 도구 (ssot_auditor.py 보강 후) 가 본 매핑을 인식 가능

## 관련

- B-349 §6 — 본 작업의 grandparent
- B-350 — 정합 분석 (DONE)
- B-353 — cross-team 인용 카탈로그 (분담 진행 중)
- PR #19 — legacy-id-redirect.json 신규
- PR (B-351/352/353) — OE 번호 재정렬 (본 PR)
