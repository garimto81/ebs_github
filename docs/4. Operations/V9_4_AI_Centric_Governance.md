---
title: V9.4 AI-Centric Governance — SSOT-first Judgment + 전문 질문 금지
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.4
related: ["V9_3_Intent_Execution_Boundary.md", "team-policy.json", "../../CLAUDE.md"]
---

# V9.4 AI-Centric Governance

> **사용자 통찰 (2026-04-29) — 5단계 cascade**:
> 1. "SSOT 기반으로 판단할 수 없으면 SSOT 를 수정 설계해야 하는 영역이야"
> 2. "이 프로젝트는 비전문 개발자가 AI 의 전문 영역의 힘을 빌려 기획 및 프로토타입을 설계 — 실제 개발과 아트 디자이너에게 전달"
> 3. "전문 영역의 질문을 하는 것 자체가 프로젝트 실패. 사용자는 이점을 인지하고 위험 감수, AI 자율성을 최대 존중하여 AI-centric 한 방식으로 기획을 처리"
> 4. "기술 진행 도중 사용자에게 관점을 묻거나 판단 요청 절대 금지. 잘못되어도 괜찮으니 위험을 감수."
> 5. **"사용자가 입력하는 영역은 0. 모든 것을 모니터링만 하고, 관리 감독만 하는 거야."**

## 🎯 결과물 중심주의 (Output-Centric)

**결과물 = 2가지만**:

1. **기획 문서** (`docs/`) — 외부 개발팀이 재구현 가능한 무결한 문서
2. **최종 프로토타입** (`team1~4/`) — 기획 문서가 동작함을 증명하는 검증 도구

모든 AI 활동의 정당화 근거 = 위 2 결과물의 quality. governance / 도구 / cycle 은 모두 수단이며 그 자체가 목표 아님.

### 결과물 중심 vs 과정 중심

| 차원 | ❌ 과정 중심 (구) | ✅ 결과물 중심 (V9.4) |
|------|------------------|----------------------|
| Governance churn | 1주 7 버전 (V5→V9.3) | 결과물 quality 가 동일하면 churn 0 |
| PR 분량 | 작고 잦은 commit | 결과물 진전 단위 |
| 사용자 보고 | 진행 단계마다 | 결과물 milestone 만 |
| Metric | merge throughput | 기획 문서 무결성 + 프로토타입 동작 |

### 결과물 quality 척도

**기획 문서**:
- Re-implementability: 외부 개발팀이 read-only 로 동일 시스템 구현 가능
- WSOP LIVE 정렬 (CLAUDE.md 원칙 1)
- SSOT 일관성 (충돌 0)

**최종 프로토타입**:
- 기획 문서의 모든 기능 동작 증명
- 외부 인계 가능 상태 (Docker / 빌드 / 테스트)

---

## 🎚 V9.4 Final: Zero-Input AI-Centric

**사용자 인터페이스 = 0 입력 + 모니터링/감독 only**:

```
┌─────────────────────────────────┐
│   사용자 (Read-Only Oversight)   │
│                                 │
│   📖 모니터링: AI 산출물 read    │
│   👁 감독: 부적합 시 거부권 발동 │
│   ⛔ 입력: 0 (기획도 AI 작성)    │
└─────────────────────────────────┘
              │
              │ AI 가 모든 것 자율 작성·진행
              ▼
┌─────────────────────────────────┐
│   AI (Full Autonomy)             │
│                                 │
│  ✍ 기획 overview 자율 작성       │
│  🔍 SSOT 검색 / 보강             │
│  🔧 코드 / PR / 머지 / 충돌      │
│  🛡 거버넌스 / 검증 / 인계 보장  │
└─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│   최종 결과물 (Handoff Ready)    │
│   📦 외부 개발팀 / 아트 디자이너 │
└─────────────────────────────────┘
```

## 🎯 V9.3 → V9.4 진화

| 차원 | V9.3 | V9.4 |
|------|------|------|
| 사용자 영역 | 의도 + 일부 가치 판단 | **입력(overview 문서) + 출력(최종 결과물) 만** |
| 중간 개입 | "큰 방향성" 만 질문 가능 | **0 개입 — 어떤 기술 질문도 금지** |
| AI 영역 | 코드 + PR + 머지 | **모든 기술 진행 + SSOT 보강 + 위험 감수 결정** |
| 전문 질문 발생 시 | "사용자 의도 영역" 표시 | **금지. SSOT 보강 또는 보수적 default 자율** |
| Default 처리 | 사용자 confirm 대기 | **AI 가 즉시 자율 결정 (잘못해도 OK)** |
| 패러다임 | Intent-Execution Separation | **AI-Centric Zero-Friction** |

## 🔒 사용자 인터페이스 = 2 점 (입력 + 출력)

```
┌─────────────────────────┐                                ┌─────────────────────────┐
│   사용자 입력            │                                │   사용자 출력            │
│                         │                                │                         │
│  📄 기획 overview        │ ━━━━ 중간 개입 0 ━━━━━━━>  │  📦 최종 결과물          │
│  (읽기 쉬운 직관적 문서) │  (AI 가 모든 기술 자율 진행)   │  (인계 가능 산출물)      │
│                         │                                │                         │
└─────────────────────────┘                                └─────────────────────────┘
```

**중간 영역 = AI 100% 자율**:
- 코드 / PR / 머지 / 충돌 / 거버넌스 / SSOT / 검증
- 잘못된 결정도 AI 가 자가 회복 (revert / 정정 cycle)
- 사용자에게 진행 상황 보고는 OK, 판단 요청은 금지

## 🤖 SSOT-First Judgment Process

```
AI 가 결정 필요한 시점
       │
       ▼
   SSOT 우선순위 검색
   (Foundation > team-policy > Risk_Matrix > APIs > Backlog)
       │
   ┌───┴───┐
   │       │
  답 있음  답 모호 / 없음
   │       │
   ▼       ▼
 자율 진행  SSOT 보강 PR 자율 생성
            │
            ▼
        보강 후 자율 진행
```

**사용자 질문은 마지막 수단.** 그것도 큰 방향성 / 외부 visible / destructive 만.

## 🚫 전문 영역 질문 금지 (Anti-Pattern)

| ❌ 금지 질문 | ✅ 올바른 처리 |
|--------------|----------------|
| "team2-work 의 e00d9da0 cherry-pick 할까요?" | SSOT 검색 → 답 있으면 자율, 없으면 SSOT 보강 |
| "이 worktree 작업 살릴까 폐기할까?" | SSOT 검색 → 작업의 기획 가치 판단 → 자율 결정. 기준 모호 시 보수적 default (폐기 + branch ref 보존) |
| "rebase 충돌 어떻게 해결할까요?" | SSOT 우선순위로 자율 해결 (`conflict_resolution.ssot_priority`) |
| "Settings 5탭 스펙 어느 게 맞나요?" | Settings docs frontmatter / Foundation 검색 → 자율 판단 |

## 🔍 사용자 의도 질문 표준 (V9.4)

질문이 정말 필요한 경우 (큰 방향성 / 외부 visible / destructive):

### 금지 용어 (forbidden_terms)

```
worktree, commit hash, cherry-pick, squash, branch, PR number,
merge, rebase, 내부 식별자 (B-XXX, SG-XXX, TDB-XXX, V9.x),
Mode A/B, Type C, scope_check, self-bootstrap
```

### 필수 형식 (required_form)

```
배경 1줄 + 옵션 2~3개 + 영향 1줄. 평이한 한국어. 비전문 개발자 친화.
```

### 예시

| ❌ Bad | ✅ Good |
|--------|---------|
| "PR #79 머지 OK?" | "이 변경을 main 에 적용할까요? (Yes/No)" |
| "Mode A 채택?" | "지금 처럼 한 명이서 작업할 때 ceremony 면제할까요?" |
| "team1-spec-gaps squash?" | "Settings 5탭 검증 문서를 살릴까요? main 의 현재 문서가 더 자세하면 폐기 권장" |

## 📊 V10 자동 trigger 조건 (V9.4 갱신)

`team-policy.json.governance_model.freeze.auto_v10_trigger_conditions`:

| Metric | Threshold | 의미 |
|--------|-----------|------|
| `user_intent_question_count_per_week` | > 5 | V9.4 anti-pattern 발동 — SSOT 보강 부족 |
| `forbidden_terms_in_user_facing_messages` | > 0 | 전문 용어 노출 검출 — 즉시 V10 후보 |
| `broken_main_incident_count` | > 1 | AI 자율 결정 risk 회수 한계 |
| `ai_autonomous_merge_ratio` | < 0.7 | 자율 영역 부족 |

## 🛡 위험 감수 (사용자 명시)

> "사용자는 이점을 확실히 인지하고 위험을 감수하여, 최대한의 AI 자율성을 존중"

이는 V9.4 의 정당화 근거:

- AI 자율 결정의 결과 책임은 사용자
- broken main / 잘못된 폐기 / governance 오류 등은 revert 또는 cycle 정정
- 위험 < 마찰: 사용자 마찰 (전문 질문) > 자율 실수의 비용
- 30일 metric 으로 V10 자동 trigger 가능 — 시스템 자가 진화

## 🎨 인계 가능성 (출구 전략)

V9.4 의 모든 자율 결정은 **인계 가능성** 을 보장해야 함:

- 산출물은 외부 개발팀 / 아트 디자이너가 이해 가능
- 거버넌스 변경은 다음 사용자 (또는 인계받은 팀) 가 추적 가능
- SSOT 보강 PR 은 의도 추적 가능한 commit message + 본문

## 🔗 관련

- `team-policy.json` `governance_model.intent_execution_boundary` (v9.4)
- `team-policy.json` `governance_model.intent_execution_boundary.ssot_first_judgment`
- `team-policy.json` `governance_model.intent_execution_boundary.user_intent_question_standard`
- `CLAUDE.md` §"프로젝트 의도" (2026-04-29 cascade)
- `V9_3_Intent_Execution_Boundary.md` (전 단계)
- `Reports/v93_metrics.yml` (30일 측정 frame)
