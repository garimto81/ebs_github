---
id: SG-028
title: "v7.5 Autonomous Conflict Triage — decision_owner → autonomous_llm_judgment 전환"
type: governance_shift
status: IN_PROGRESS
owner: conductor
created: 2026-04-28
decision_authority: user
affects_chapter:
  - docs/2. Development/2.5 Shared/team-policy.json
  - docs/4. Operations/Multi_Session_Workflow.md
  - docs/4. Operations/Conflict_Registry.md (NEW)
  - tools/team_v5_merge.py
  - tools/conflict_resolver.py (NEW)
  - .github/workflows/pr-auto-merge.yml
  - CLAUDE.md
protocol: explicit_user_directive
supersedes:
  - SG-024 mode_b decision_authority_source (v7.1)
---

# SG-028 — v7.5 Autonomous Conflict Triage

## 결정 (사용자 명시, 2026-04-28)

Mode B 멀티세션 거버넌스의 의미적 충돌 판정 권한을 **`decision_owner` (CODEOWNERS 기반)** → **`autonomous_llm_judgment`** 로 이전.

근거: 사용자 직접 지시 ("STRATEGIC PIVOT — Implementation of Autonomous Conflict Governance"). Zero-Intervention 원칙 채택.

## 적용 범위 (Mode 분리 보존)

| Mode | trigger | governance | 본 SG 영향 |
|:----:|---------|------------|------------|
| Mode A | Conductor 단독 | `conductor_full_authority` | **변경 없음** (단독 세션, 충돌 발생 자체가 드묾) |
| Mode B (legacy) | 멀티세션 v7.1 | `decision_owner` | **deprecated** (호환 유지 — 옵트아웃 가능) |
| **Mode B autonomous** | 멀티세션 v7.5 default | `autonomous_llm_judgment` ⭐ | **NEW (default in v7.5)** |

`team-policy.json` 의 mode 선택은 멀티세션 활성화 시 default `mode_b_autonomous`. 사용자가 명시적 fallback 원하면 `EBS_GOV_MODE=v71_decision_owner` 환경변수로 회복 가능 (escape hatch — backwards compatibility, 후속 평가 시 제거 검토).

## 4-Step Decision Logic

```
충돌 감지 (rebase 또는 merge conflict)
   │
   ▼
Step 1. SSOT 조회 (team-policy.json contract_ownership 매핑)
   ├─ 충돌 파일이 contract path 내부 → 해당 SSOT doc 적재
   └─ 충돌 파일이 코드 → 가장 가까운 docs/ 매핑 (owns 트리)
   │
   ▼
Step 2. SSOT 우위 판정
   ├─ 한쪽만 SSOT 일치 → 일치하는 쪽 채택 (Overwrite)
   ├─ 양쪽 모두 SSOT 일치 → Step 3 (Win-Win 가능?)
   └─ 양쪽 모두 SSOT 위배 → Step 4 (Tie-breaker)
   │
   ▼
Step 3. Win-Win Merge 시도
   ├─ 두 변경이 직교 (다른 hunk, 다른 함수) → 양쪽 통합
   └─ 직교 아님 → Step 4
   │
   ▼
Step 4. Tie-breaker (Fallback)
   ├─ 1순위 종속성 평가 (side-effect 적은 쪽 우선)
   │   ├─ contract path 변경 vs 비-contract → 비-contract 우선 (영향 적음)
   │   ├─ DB 스키마 / 마이그레이션 → 더 보수적인 쪽 (Abort 경향)
   │   └─ API 시그니처 → subscriber 영향 최소화
   ├─ 2순위 신규 우선 (1순위 동등 시)
   │   └─ HEAD (현재 작업) 채택
   └─ 모든 판정 실패 시: Abort + Spec_Gap_Registry 등록 + 사용자 escalation
```

## 안전 장치

1. **Verification Mandatory**: 결정 적용 후 빌드/lint/test 통과 강제 (`pytest`, `dart analyze`). 실패 시 결정 → Abort 강제 전환 + 롤백.
2. **Audit Trail**: 모든 결정 → `Conflict_Registry.md` 인덱스 + GitHub issue 자동 등록. Conductor 사후 감사.
3. **CI / Local 분리**: workflow (LLM 없음) 에서는 issue 등록 + label 제거만 수행. Local Claude Code session 만 LLM judgment 실행.
4. **사용자 인텐트 보호**: `mode_a_limits` 그대로 유지. 본 SG 는 멀티세션 의미적 판정에만 적용 — 사용자 인텐트 변경 / vendor 메일 / git config / DB drop 등 destructive 영역은 여전히 사용자 명시 필수.

## Risk & Mitigation

| Risk | Mitigation |
|------|------------|
| LLM 오판으로 stable 코드 폐기 | Fallback Step 4 의 종속성 평가 1순위 (Abort 경향 보수적) + Verification Mandatory 후 롤백 |
| 자율 판정 luck of draw 변동 | Audit log 누적 → 패턴 발견 시 SG-028b 후속 튜닝 |
| 멀티세션 이외 영역 권한 침범 | mode_a_limits 보존, conflict_triage 섹션 명시 적용 범위 제한 |
| Escape hatch 가 영구 의존 | 후속 평가 (3 개월 후) 에서 제거 검토 — 본 SG 에 명시 |

## 구현 순서

1. SG-028 backlog 엔트리 (이 문서) — DONE
2. `tools/conflict_resolver.py` 신규 작성
3. `tools/team_v5_merge.py` 라인 137-138 충돌 핸들링 교체
4. `.github/workflows/pr-auto-merge.yml` issue 자동 생성 단계 추가
5. `team-policy.json` v7.1 → v7.5 (governance_model 확장 + conflict_triage 섹션)
6. `Multi_Session_Workflow.md` ## v7.5 섹션 + `Conflict_Registry.md` 신규
7. `CLAUDE.md` governance 모델 ref 갱신
8. PR 생성 (auto-merge 라벨)

## 후속 (12 weeks 후 평가)

- `Conflict_Registry.md` 누적 100건 또는 12 weeks 경과 시 SG-028b 평가
- 평가 항목: 자율 결정의 정확도, 수동 audit override 빈도, escape hatch 사용 횟수
- 결과에 따라: continue / refine fallback rules / rollback to v7.1
