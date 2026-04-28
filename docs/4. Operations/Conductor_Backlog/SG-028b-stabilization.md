---
id: SG-028b
title: "v7.5 Post-Merge 안정화 — escape hatch enforcement + claim release fallback bugfix"
type: technical_debt_cleanup
status: IN_PROGRESS
owner: conductor
created: 2026-04-28
parent: SG-028
decision_authority: user
affects_chapter:
  - tools/conflict_resolver.py
  - tools/team_v5_merge.py
protocol: explicit_user_directive
---

# SG-028b — v7.5 Post-Merge 안정화

## 배경

SG-028 (v7.5 Autonomous Conflict Triage) 배포 과정에서 관측된 2건의 기술 부채:

1. **Escape Hatch 미구현**: `team-policy.json` 의 `mode_b_multi_session_legacy` 모드는 문서화만 됐고 코드 enforcement 없음. `EBS_GOV_MODE=v71_decision_owner` 환경변수가 설정되어도 `conflict_resolver.py` 가 자율 apply 를 강행할 수 있는 상태.
2. **Claim Release Fallback 버그**: SG-028 첫 배포에서 `team_v5_merge.py` 가 cherry-pick 으로 인해 잃어버린 claim #17 대신 가장 오래된 active claim #14 (이전 SG-022 작업) 을 잘못 release 하는 사이드 이펙트 발생.

## 결정 (사용자 명시, 2026-04-28)

위 2건을 단일 PR (`fix(governance): SG-028b claim release logic and escape hatch`) 로 청산. SG-028 의 자매 작업.

## Task 1: Escape Hatch Enforcement

### 변경
- `conflict_resolver.py`:
  - `LEGACY_MODE_ENV` / `LEGACY_MODE_VALUE` 상수 (`EBS_GOV_MODE` / `v71_decision_owner`)
  - `_is_legacy_mode()` helper (whitespace tolerant, value-strict)
  - `_legacy_manual_instructions()` — 사용자 안내 문구 SSOT
  - `cmd_analyze`: legacy mode 시 `.conflict_legacy_marker` 작성 + `request.legacy_mode=true` + exit 5
  - `cmd_apply`: legacy mode 시 즉시 거부 + 안내 + exit 5
  - 정상 apply 완료 시 marker 자동 cleanup
- `team_v5_merge.py`:
  - 동일 `_is_legacy_mode()` 보유 (resolver 와 일치)
  - `prepare_branch()` rebase 실패 후 analyze → exit 5 처리 (`triage="legacy_manual"`)
  - `main()` 에서 legacy_manual 시 manual triage 안내 + exit 5
- exit 5 신설 (양쪽 도구 일치): "legacy mode active, manual triage required"

### 안내 메시지 (양쪽 도구 SSOT)
```
[legacy] EBS_GOV_MODE=v71_decision_owner 활성화. 자율 apply 거부.
Manual triage 절차:
  1. 충돌 파일 직접 편집 (Conflict marker 제거)
  2. git add <resolved-files>
  3. git rebase --continue   (또는 git merge --continue)
  4. python tools/team_v5_merge.py   # PR push 단계 재진입

escape hatch 해제: unset EBS_GOV_MODE
```

## Task 2: Claim Release Fallback Bugfix

### 문제 재현 시나리오
1. 팀 세션이 Phase 0 claim 추가 (#17, branch=`work/conductor/v75-autonomous-triage`, scope 매칭)
2. cherry-pick 으로 새 branch (`work/conductor/v75-clean`) 생성 시 #17 commit 유실
3. `team_v5_merge.py` 가 PR 생성 후 `_release_v5_1_claim` 호출
4. 활성 claim 리스트에 #17 있음 (registry orphan branch 에 보존). 그러나 PR URL 매칭 실패 (#17 의 `pr` 필드가 비어있음)
5. **버그**: 폴백으로 `active[oldest]` = #14 (이전 SG-022 conductor 작업) 를 release ← 의도하지 않은 사이드 이펙트

### 수정 — `_match_claim_for_release()` 신규 (extracted pure function)

매칭 우선순위 (oldest 폴백 제거):
1. **PR URL 정확 일치** (`claim.pr == pr_url`)
2. **branch 명 정확 일치** (`claim.branch == branch`)
3. **branch slug segment 매칭** — slug 를 hyphen 으로 split, ≥4 char 인 segment 만 추출. 정규화(alphanum-only lowercase) 후 task / scope 의 substring 검사.

매칭 실패 시 → `None` 반환 (silent skip + 사용자 안내). **절대 oldest 폴백 금지.**

### 정규화 예시
- branch `work/conductor/sg028b-stabilization` → slug `sg028b-stabilization`
  → parts `["sg028b", "stabilization"]`
- task `"SG-028b: v7.5 escape hatch enforcement"` → normalized `"sg028bv75escapehatchenforcement"`
- 검사: `"sg028b"` ⊆ task normalized → ✅ match

## Task 3: Self-Test 검증

### `conflict_resolver.py self-test` 추가 항목 (5건)
1. `EBS_GOV_MODE` 미설정 → False
2. `EBS_GOV_MODE=v71_decision_owner` → True
3. `EBS_GOV_MODE=wrong_value` → False
4. whitespace tolerance (`" v71_decision_owner "`) → True
5. manual instructions 비어있지 않음 + env 명시 + rebase 안내 포함

### `team_v5_merge.py --self-test` 신규 (8건)
1. PR URL 정확 일치
2. branch slug 정규화 매칭
3. **oldest-fallback 부재 검증** (no-match → None, NOT oldest)
4. branch 명 정확 일치
5. 빈 list → None
6. 너무 짧은 slug (<4 chars) → no false positive
7. legacy mode env 감지 (team_v5_merge 측)
8. conflict_resolver self-test downstream PASS

모두 PASS 확인.

## Verification

```bash
$ python tools/conflict_resolver.py self-test
[ok] hunk extraction: 2-7
[ok] SSOT lookup: contract=docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md, publisher=team2
[ok] team-owns lookup: publisher=team1
[ok] legacy mode detection: env-based on/off correct
[ok] legacy manual instructions: 8 lines, env mentioned
[ok] self-test passed

$ python tools/team_v5_merge.py --self-test
[ok] match by PR URL → #18
[ok] match by branch slug 'sg028b-stabilization' → #18
[ok] no oldest-fallback (silent skip on miss)
[ok] match by exact branch name → #100
[ok] empty active list → None
[ok] short slug (<4 chars) → no match (false-positive guard)
[ok] legacy mode env detection (team_v5_merge side)
[ok] conflict_resolver.py self-test PASS (downstream)
[ok] team_v5_merge self-test passed (SG-028b coverage)
```

## 후속

- SG-028 의 12 weeks 사후 평가 (2026-07-28) 시 escape hatch 사용 횟수 확인 → 미사용 시 escape hatch 자체 제거 검토
- claim 시스템에 `branch` 필드 표준화 — 현재는 옵션 필드. 모든 claim 이 명시적으로 branch 보유하도록 `active_work_claim.py add` 시 자동 캡처 (별도 SG)
