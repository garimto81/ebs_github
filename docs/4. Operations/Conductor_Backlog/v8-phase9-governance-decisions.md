---
title: v8.0 Phase 9 — Governance Decisions Brief (사용자 결정 대기)
owner: conductor
tier: operations
status: pending-user-decision
last-updated: 2026-04-28
related:
  - docs/4. Operations/Plans/v8-team-simplification.plan.md
  - docs/4. Operations/Conductor_Backlog/SG-024-governance-expansion.md
  - docs/4. Operations/Conductor_Backlog/SG-027-multi-session-pipeline.md
  - docs/4. Operations/Active_Work.md (Claim #17 v7.5)
  - 이전 turn v7.6 critic 보고서 (REJECT verdict)
  - work branch: work/conductor/v8-phase1-team-pr-merge (잠정 보류)
confluence-page-id: 3818619180
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818619180/EBS+v8.0+Phase+9+Governance+Decisions+Brief
---

# v8.0 Phase 9 — Governance Decisions Brief

## 1. 왜 Phase 9 가 먼저인가

이전 turn 의 critic 보고서가 P0/P1/P2 단계 분류 후, 사용자가 **Phase 9 (P2 governance 결정) 먼저** 명시. 동시에 Phase 1 의 doc 변경이 revert 됨 (intentional change signal).

**해석**: governance churn (1주 7 버전: v5.0→v5.1→v6.1→v7.1→v7.2→v7.5→v7.6) 이 risk 의 80%. file cleanup 은 mechanical work 로 governance 안정 후 가속 가능. **순서 = governance freeze 먼저, file cleanup 다음**.

```
+----------------------------------------------------+
|                                                    |
|  현재: governance churn (active proposal 4개)      |
|  ├─ v7.5 (Claim #17, SG-028) — 미완성 진행 중     |
|  ├─ v7.6 — critic REJECT 받았으나 공식 미기록      |
|  ├─ v8.0 — Plan 작성됨, Phase 1 revert 됨         |
|  └─ governance freeze 미결정                       |
|                                                    |
|  Phase 9 = 위 4개 결정 → governance 안정          |
|                                                    |
+----------------------------------------------------+
```

## 2. 4 결정 항목 (사용자 명시 필요)

각 항목에 **현황 / 옵션 / critic 권장 / 결정 단어** 명시. Conductor 자율 결정 X — 모두 사용자 영역 (Mode A 한계 `user_intent_change`).

---

### 결정 1 — v7.5 (Claim #17, SG-028 Autonomous Conflict Triage) disposition

**현황**:
- Active_Work.md Claim #17: `started: 2026-04-27T23:59:04Z, eta: 4h, status: active`
- 현재 시각: 2026-04-28 (ETA 초과)
- Scope: `tools/conflict_resolver.py` + `docs/4. Operations/Conductor_Backlog/SG-028-autonomous-triage.md` 등
- **`SG-028-autonomous-triage.md` 파일 부재** (확인됨)
- **`tools/conflict_resolver.py` 파일 부재** (확인됨)
- 즉 v7.5 = "governance shift (decision_owner → autonomous_llm_judgment)" 제안만 있고 구현 없음

**옵션**:

| ID | 결정 | 의미 | 영향 |
|:--:|------|------|------|
| **1A** | **폐기** (권장) | Claim #17 release + SG-028 작성 안 함 + governance shift 시도 중단 | v7.6 critic verdict 와 일관. governance 단순화. |
| 1B | 완성 | SG-028 작성 + tools/conflict_resolver.py 구현 + 1주 시범 | v7.6 critic 의 9개 위반 항목과 충돌. 재검토 필수. |
| 1C | 보류 | Claim #17 stale 표시 + 결정 1개월 연기 | governance churn 지속. 비추천. |

**critic 권장**: **1A 폐기**. 근거: v7.6 critic 보고서가 v7.5 의 진화 방향(autonomous_llm) 자체를 9개 위반 항목으로 reject. v7.5 미완성 상태 cascade = governance double-shift 위험.

**결정 단어**: `1A` / `1B` / `1C`

---

### 결정 2 — v7.6 Autonomous CI/CD Pipeline Agent 공식 reject 기록

**현황**:
- 이전 turn critic 보고서: 9개 위반 항목, 0개 합의 가능, 0/6 dimensions compliance
- Verdict: **REJECT v7.6 as stated**
- 공식 Conductor_Backlog 기록 없음 (memory + conversation 만)

**옵션**:

| ID | 결정 | 의미 |
|:--:|------|------|
| **2A** | **공식 reject 기록** (권장) | `Conductor_Backlog/v7-6-rejection-record.md` 작성 — critic verdict 영구 보존 |
| 2B | reject 보류 | critic 결과 무시, v7.6 옹호 path 가능 유지 |
| 2C | 부분 채택 | v7.6 의 일부 (예: GitHub Issue logging) 만 채택 — critic 항목별 재검토 |

**critic 권장**: **2A 공식 reject 기록**. 근거: 미공식 verdict 는 향후 재발의 risk (memory 만으로는 governance 결정 불충분). 공식 기록이 향후 유사 제안 차단의 reference point.

**결정 단어**: `2A` / `2B` / `2C`

---

### 결정 3 — Worktree cleanup (14개 → 5개)

**현황** (이전 turn 확인):
```
14 active worktree:
  C:/claude/ebs                        [main]
  C:/claude/ebs-conductor-curate       [work/conductor/v6-3-journal-log]
  C:/claude/ebs-conductor-infra        [work/conductor/infra-alignment-cleanup]
  C:/claude/ebs-conductor-p0           [work/conductor/fix-p0-context-and-port]
  C:/claude/ebs-conductor-p1           [work/conductor/p1-sentry-flutter-pin]
  C:/claude/ebs-team1-flutter          [work/team1/n4-cc-url-scheme]
  C:/claude/ebs-team1-harness          [work/team1/harness-e2e-validation]
  C:/claude/ebs-team1-phase5           [work/team1/phase5-e2e-final]
  C:/claude/ebs-team1-spec-gaps        [work/team1/spec-gaps-20260415]
  C:/claude/ebs-team2-work             [work/team2/work]
  C:/claude/ebs-team3-betting          [work/team3/20260428-betting-domain]
  C:/claude/ebs-team3-triggers         [work/team3/20260427-triggers-domain-v2]
  C:/claude/ebs-team3-variants         [work/team3/20260428-variants-domain]
  C:/claude/ebs-team3-work             [work/team3/b-342-foundation-ref-precision]
```

**옵션**:

| ID | 결정 | cleanup 대상 후보 (사용자 결정 필요) |
|:--:|------|----------------|
| 3A | **기준 작업 종료된 worktree만 정리** (권장) | merged PR 의 brand 만 cleanup. 활성 작업 보존. |
| 3B | 팀당 1 worktree 정책 강제 | team1 4개 → 1개, team3 4개 → 1개, conductor 4개 → 1개. 사용자 결정 필요 (어느 작업 보존). |
| 3C | 현행 유지 | 14개 worktree 그대로. 디스크 + cleanup 비용 누적. |

**critic 권장**: **3A** — 자율 안전. 사용자가 어떤 작업이 종료됐는지 가장 잘 앎. Conductor 가 "merged" 만 식별해 사용자에게 cleanup 후보 리스트 제출.

**결정 단어**: `3A` / `3B` / `3C`

---

### 결정 4 — Governance 버전 동결 (v8.0 stable)

**현황**:
- 1주 (2026-04-21 ~ 2026-04-27) 동안 7 버전 변경
- Iron Laws Circuit Breaker 패턴 (3회 동일 실패) 의 governance 적용 시 임계 초과
- v8.0 stable 동결 = 1개월 governance change 금지

**옵션**:

| ID | 결정 | 의미 | 기간 |
|:--:|------|------|:---:|
| **4A** | **v8.0 stable 동결** (권장) | governance change 1개월 금지. Phase 1-8 cleanup 만 진행 | 1개월 (2026-04-28 ~ 2026-05-28) |
| 4B | v8.0 + emergency only | 데이터 손실 같은 emergency 시 변경 허용 | 1개월 |
| 4C | 동결 안 함 | governance churn 지속 허용 | - |

**critic 권장**: **4A v8.0 stable 동결**. 근거: 동결 없이는 Phase 1-8 cleanup 진행 중 또 새 governance 가 추가되어 cleanup 자체가 stale 됨. 동결 = cleanup 완주 보장.

**결정 단어**: `4A` / `4B` / `4C`

---

## 3. 결정 영향도 매트릭스

각 결정의 후속 Phase 영향:

| 결정 조합 | Phase 1 (cleanup) 영향 | Phase 6 (L0 제거) 영향 | Phase 8 (문서 압축) 영향 |
|----------|---------------------|---------------------|---------------------|
| 1A + 2A + 3A + 4A (모두 권장) | 즉시 진행 가능 | 즉시 진행 가능 | 즉시 진행 가능 (governance freeze 의 일관 보존) |
| 1B (v7.5 완성) | 우선순위 후순위 | v7.5 + L0 동시 변경 시 conflict | v7.5 추가 doc 변경 = 압축 후 다시 부풀음 |
| 4C (동결 안 함) | 진행 가능 but stale risk | risk 매우 높음 (1주 안에 governance 또 변경 시) | 압축 후 governance 추가 시 다시 부풀음 |

**최적 조합 (critic 권장)**: `1A + 2A + 3A + 4A`. 이 조합 시 Phase 1-8 cleanup 의 1주 sprint 가능.

## 4. 예외 — 자율 안전 조치 (이번 turn 가능)

사용자 결정 대기 중 Conductor 가 자율 안전하게 진행 가능한 항목:

| 항목 | 자율 안전 근거 | 진행 |
|------|---------------|:---:|
| **본 Decision Brief 문서 작성** | 결정 자체 X, 옵션 정리만 | ✅ done |
| Active_Work Claim #17 stale 표시 (release_reason: stale_pending_decision) | ETA 초과 + status 정리만 | ⚠️ 결정 1A 후 |
| work/conductor/v8-phase1-team-pr-merge 보존 | revert 됐지만 commit 보존 = 재사용 가능 | ✅ done (자동) |
| backup tag 보존 | backup-pre-v8-2026-04-28 = 롤백 path | ✅ done |

## 5. 사용자 confirmation 형식 (다음 turn)

다음 turn 에 4개 결정 단어 명시:

```
결정: 1A 2A 3A 4A    # 모두 권장 (가장 빠른 cleanup path)
또는
결정: 1A 2A 3C 4A    # worktree 보류, 나머지 권장
또는
결정: hold           # 더 검토 후 결정
또는
결정: reject-v8      # v8.0 자체 폐기, v5.1 유지
```

## 6. 결정 후 자동 후속 진행 (Conductor 자율 가능)

사용자 결정 입력 시 다음을 자율 진행:

| 결정 | 자동 후속 |
|------|----------|
| 1A | Active_Work.md `release --id 17 --reason "user-decision: discontinue v7.5"` |
| 2A | `Conductor_Backlog/v7-6-rejection-record.md` 작성 (이전 turn critic 인용) |
| 3A | `git worktree list` + merged PR 매핑 → cleanup 후보 list 제출 (실 cleanup 은 사용자) |
| 4A | `team-policy.json` 에 `governance_freeze: { until: "2026-05-28", scope: "all" }` 추가 |

## 7. 본 Brief 의 약점 (자기 반박)

1. **사용자 의도 정확히 모름**: Phase 1 doc revert 의 정확한 이유 (시기 부적절 / 방식 reject / Phase 9 우선) 가 conversation 에서 명시 안 됨. "Phase 9 먼저" 만 명시.
2. **결정 1A (v7.5 폐기) 의 sunk cost**: Claim #17 작업 시간이 이미 투입됨. 폐기 = sunk cost 인정.
3. **결정 4A (governance 동결) 의 emergency 예외 모호**: 1개월 안에 진짜 emergency 발생 시 절차 미정의. 4B 가 더 현실적일 수 있음.
4. **3A (worktree cleanup 보류)**: 14개 worktree 의 디스크 비용 누적 무시. cleanup 지연 risk.

## Changelog

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-28 | v1.0 | 최초 작성 (Phase 9 우선 결정 의도 cascade) |
