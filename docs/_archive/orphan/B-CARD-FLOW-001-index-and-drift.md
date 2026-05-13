---
id: B-CARD-FLOW-001
title: "정비: RFID/커뮤니티 카드 호출 로직 집대성 + 분산 기획 정비"
type: implementation
status: IN_PROGRESS  # PENDING | IN_PROGRESS | DONE
owner: conductor
created: 2026-04-29
spec_ready: true
blocking_spec_gaps: []
implements_chapters:
  - docs/2. Development/2.5 Shared/Card_Flow_Index.md  # NEW (CF-001)
  - docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md  # CF-002+003
  - docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md  # READ-ONLY 권위
plan_file: ~/.claude/plans/rfid-peaceful-seal.md
---

# B-CARD-FLOW-001 — RFID/커뮤니티 카드 호출 로직 정비 cascade

## 배경

사용자(기획자 + production 출시 책임자, SG-023 인텐트) 요청 (2026-04-29):
> "rfid 카드가 호출되는 방식 커뮤니티 카드가 호출되는 방식 및 로직등을 집대성한 문서 및 해당 로직 관련한 모든 기획 문서들을 전수 검사하여 정비"

탐색 결과 (3개 Explore 에이전트 + 1개 Plan 에이전트):

- 카드 파이프라인 도메인 마스터는 **이미 존재** (`Triggers_and_Event_Pipeline.md` §1.4, BS-06-12 흡수, PR #9 머지 2026-04-27)
- 가설 공백 6건 중 **3건은 phantom** (BS-04-00 / BS-04-05 / Backend RFID 카탈로그 모두 이미 존재)
- **진짜 drift 1건**: `Card_Detection.md §3.3` (team4) 가 atomic-flop 규칙과 모순
- **진짜 부재 1건**: 4팀 publisher 를 가로지르는 네비게이션 인덱스

## 전략

**Strategy C+** — 신규 마스터 SSOT 창설 X, 대신:
1. Shared 네비게이션 인덱스 신설 (`Card_Flow_Index.md`)
2. team4 측 drift 정정 (`Card_Detection.md §3.3`)
3. 검증 (spec_drift_check)

**근거**: 신규 마스터 창설 = 분열 위험. WSOP LIVE 도 BS-04 ↔ BS-06 peer 패턴. 거버넌스 변경 0건. freeze 호환.

## 구현 범위 (WBS)

| ID | 제목 | Owner | Type | Priority | Status |
|----|------|-------|------|----------|--------|
| CF-001 | Card_Flow_Index 신설 (4-tier 네비게이션) | conductor | NEW | P1 | ✅ DONE (2026-04-29) |
| CF-002 | Card_Detection §3.3 atomic 정렬 | team4 | EDIT | **P0** | ✅ DONE (2026-04-29) |
| CF-003 | Card_Detection §3.4 4번째 카드 정정 | team4 | EDIT | **P0** | ✅ DONE (2026-04-29, CF-002 와 통합) |
| CF-004 | Flop_Games.md RIM/BombPot xref | conductor | EDIT | P1 | ❌ SUPERSEDED (Confluence 발행 규칙 — Card_Flow_Index 가 단방향 흡수) |
| CF-005 | Card_Detection §1 안테나 시각화 | team4 | EDIT | P2 | PENDING |
| CF-006 | CC Overview backlink | team4 | EDIT | P2 | PENDING |
| CF-007 | RFID_HAL.md backlink | team4 | EDIT | P2 | PENDING |
| CF-008 | legacy-id-redirect.json 검증 | conductor | VERIFY | P1 | ✅ DONE (2026-04-29, BS-06-12 mapping 존재) |
| CF-009 | spec_drift_check.py --rfid --events 실행 | conductor | VERIFY | P1 | PENDING |
| CF-010 | Card_Pipeline_Overview shim 49줄 보존 검증 | team3 | VERIFY | P2 | PENDING |

## 진행 상황

### Phase 1 (P0 drift fix) — ✅ 완료 2026-04-29

`Card_Detection.md §3.3` 을 Triggers_and_Event_Pipeline.md §1.4/§3.5 T9/§4.10 권위에 정렬:
- 1~2장 부분 감지 = `BoardState=FLOP_PARTIAL` PENDING (외부 미발행)
- 30s timeout 후 CC-only `FlopPartialAlert(count, missing)` (T9)
- 4번째 카드 = `AWAITING_TURN` 컨텍스트 분기 (진입 후 = TurnRevealed, 미진입 = reject)

### Phase 2 (P1 인덱스 + 검증) — ✅ 완료 2026-04-29

- CF-001: `docs/2. Development/2.5 Shared/Card_Flow_Index.md` 신설 (~150 줄, 4-tier + Quick Lookup 15 항목)
- CF-008: `docs/_generated/legacy-id-redirect.json` BS-06-12 mapping 존재 확인 (line 122-131)
- CF-004: SUPERSEDED — Flop_Games.md 는 Confluence 발행 대상으로 "다른 문서명 언급 금지" 규칙 적용. Card_Flow_Index 가 Tier 0 + Quick Lookup 으로 단방향 흡수.

### Phase 3+ (P2 보강 + 검증) — PENDING

자율 판단 후 진행 예정.

## 기획 참조 (권위 SSOT)

- `docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md` §1.4 (카드 파이프라인) · §3.5 (T1~T11) · §4.10 (Atomic Flop 예외)
- `docs/2. Development/2.5 Shared/team-policy.json` (decision_owner 매핑)
- `docs/2. Development/2.5 Shared/Card_Flow_Index.md` (Tier 인덱스)

## 수락 기준

- [x] Phase 1 P0 drift 정정 (Card_Detection §3.3)
- [x] Phase 2 인덱스 신설 (Card_Flow_Index)
- [x] Phase 2 legacy-id 검증 (BS-06-12)
- [ ] Phase 3 P2 보강 (안테나 시각화 + backlinks) — 자율 판단 대기
- [ ] Phase 4 spec_drift_check.py --rfid --events D4 PASS
- [ ] Phase 5 단일 commit + main 반영

## 거버넌스

- **Mode A 단일 세션** 권한 (Conductor) 으로 team4 영역 (`docs/2. Development/2.4 Command Center/`) 직접 편집 가능 (CLAUDE.md SG-024 v7.5)
- **거버넌스 변경 0건**: hooks / policy / mode 미수정. tier=`shared-index` 는 docstring 컨벤션
- **2026-05-28 freeze 호환**: 모든 작업이 content/cross-ref 단계

## 관련 항목

- IMPL-002 (Engine Connection UI) — 무관, 영향 없음
- SG-006 (Deck 52 codemap) — RESOLVED, 영향 없음
- SG-011 (RFID HAL drift) — `drift_ignore_rfid: true` 보존, 영향 없음

## 참조

- Plan 파일: `~/.claude/plans/rfid-peaceful-seal.md`
- Master Index: `docs/2. Development/2.5 Shared/Card_Flow_Index.md`
- Drift target: `docs/2. Development/2.4 Command Center/RFID_Cards/Card_Detection.md` §3.3
