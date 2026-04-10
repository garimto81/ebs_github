---
name: auto
description: PDCA Orchestrator - Agent Teams + PDCA 통합 워크플로우
version: 18.0.0
triggers:
  keywords:
    - "/auto"
    - "auto"
    - "autopilot"
    - "ulw"
    - "ultrawork"
    - "ralph"
model_preference: opus
auto_trigger: true
team_pattern: true
agents:
  - executor
  - executor-high
  - architect
  - planner
  - critic
  - writer
  - qa-tester
  - researcher
  - analyst
---

# /auto - PDCA Orchestrator (v18.0 - Agent Teams 통합)

> **핵심**: `/auto "작업"` = **PDCA 문서화(필수)** + Ralph 루프 + Ultrawork 병렬 + **이중 검증**
> **실행 패턴**: 모든 에이전트 호출은 Agent Teams 라이프사이클을 따릅니다.

## Agent Teams 기본 패턴

모든 에이전트 호출은 아래 라이프사이클을 따릅니다:

```
TeamCreate(team_name="auto-{feature}")
  → Agent(subagent_type="...", name="...", description="...", team_name="auto-{feature}", ...)
  → SendMessage(to="...", message={type: "shutdown_request"})
  → TeamDelete()
```

### 사용되는 에이전트

| 에이전트 | 모델 | 용도 |
|----------|------|------|
| `executor` | sonnet | 기능 구현 |
| `executor-high` | opus | 복잡한 구현 |
| `architect` | opus | 분석 및 검증 |
| `planner` | opus | 계획 수립 |
| `critic` | opus | 계획 검토 |
| `writer` | haiku | 문서/보고서 생성 |
| `qa-tester` | sonnet | 테스트 실행 |
| `researcher` | sonnet | 리서치 |
| `analyst` | opus | 데이터 분석 |

## ⚠️ 필수 실행 규칙 (CRITICAL)

**이 스킬이 활성화되면 반드시 아래 워크플로우를 실행하세요!**

### Phase 0: PDCA 문서화 (필수)

**모든 작업은 PDCA 사이클을 따릅니다:**

```
┌─────────────────────────────────────────────────────────────┐
│                    PDCA 필수 워크플로우                       │
│                                                             │
│  Plan ──▶ Design ──▶ Do ──▶ Check ──▶ Act                  │
│   │         │        │        │        │                    │
│   ▼         ▼        ▼        ▼        ▼                    │
│ 계획문서  설계문서   구현    갭검증   개선반복               │
│                              │                              │
│                    ┌────────┴────────┐                     │
│                    │    병렬 검증     │                     │
│                    │  Architect      │                     │
│                    │  gap-check      │                     │
│                    └─────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

**Step 0.1: Plan 문서 생성 (Ralplan 연동)**

**복잡도 점수 판단 (MANDATORY - 5점 만점):**

작업 설명을 분석하여 아래 5개 조건을 평가합니다. 각 조건 충족 시 1점.

| # | 조건 | 1점 기준 | 0점 기준 |
|:-:|------|---------|---------|
| 1 | **파일 범위** | 3개 이상 파일 수정 예상 | 1-2개 파일 |
| 2 | **아키텍처** | 새 패턴/구조 도입 | 기존 패턴 내 수정 |
| 3 | **의존성** | 새 라이브러리/서비스 추가 | 기존 의존성만 사용 |
| 4 | **모듈 영향** | 2개 이상 모듈/패키지 영향 | 단일 모듈 내 변경 |
| 5 | **사용자 명시** | `ralplan` 키워드 포함 | 키워드 없음 |

**에러/수정 컨텍스트 보정 (Error Context Adjustment):**

에러 수정, 디버그, 버그 픽스 작업인 경우 아래 추가 조건으로 복잡도를 보정합니다:

| # | 조건 | +1점 기준 | 0점 기준 |
|:-:|------|----------|---------|
| E1 | **수정 실패 이력** | 1회 이상 수정 시도 실패 | 첫 시도 |
| E2 | **근본 원인 깊이** | 크로스 모듈 또는 race condition | 단일 함수 내 버그 |
| E3 | **회귀 위험** | 공유 코드/API 경계 수정 | 격리된 모듈 |

최종 복잡도 = max(기본 점수, 기본 점수 + 에러 보정)
→ 에러 보정 후 score >= 3이면 Ralplan 실행 (수정 전략에 대한 Planner+Critic 합의)

> 검증 프로토콜 상세: `.claude/references/verification-protocol.md`

**판단 규칙 (Ultra Plan 4-티어):**
- **`--ultra` / `--ultrathink` 명시** → Ultra Plan 실행 (5-Phase 파이프라인)
- **score == 5 또는 Ultra 키워드 감지** → Ultra Plan 자동 실행 (`--no-ultra` 없는 경우)
- **score >= 3 (그 외)** → Ralplan 실행 (Planner + Architect + Critic 합의)
- **score < 3** → Planner 단독 실행
- **score ≤ 1 + 텍스트 전용 작업** → Gemma 4 로컬 위임 (Ollama 정상 시)
- **`!quick` Magic Word** → 모든 ceremony 생략 (최우선)

**Gemma 4 로컬 위임 (score ≤ 1, 텍스트 전용):**
- 조건: score ≤ 1 AND delegation_keywords 매칭 (`요약`, `번역`, `분석`, `설명`, `정리`, `summarize`, `translate` 등) AND excluded_patterns 불일치 (코드/구현/git 작업 아님)
- Ollama 상태 확인: `GemmaClient.is_available()` (2초 타임아웃)
- 성공 시: `GemmaClient.chat()` → 결과 출력 + "Local Model (Gemma 4)" 라벨
- 실패 시: 기존 경로로 fallback (Planner 단독)
- Config: `.claude/ml/config.py` `GEMMA_DELEGATION_CONFIG` 참조

**Ultra Plan 자동 트리거 키워드** (대소문자 무시, 한/영 감지):
`architecture`, `migration`, `DB 스키마`, `schema change`, `auth`, `authentication`,
`authorization`, `payment`, `production 배포`, `breaking change`, `critical`,
`security audit`, `전면 리팩토링`, `full refactor`

> Ultra Plan 상세 프로토콜: `.claude/references/ultra-plan-protocol.md`

**ML 보조 판단 (자동, Shadow Mode 이후 활성):**

ML 복잡도 예측기가 활성화된 경우 (`.claude/ml/.ml_session_state.json` 존재):
1. ML 예측값과 수동 점수를 모두 판단 로그에 출력
2. Shadow Mode: ML 예측만 기록, 수동 점수로 라우팅
3. Hybrid Mode: ML confidence ≥ 0.8 → ML 점수 사용, 아니면 수동 점수
4. Primary Mode: ML 점수 우선, confidence < 0.5 → 수동 fallback

**판단 로그 출력 (항상 필수):**
```
═══ 복잡도 판단 ═══
파일 범위: {0|1}점 ({근거})
아키텍처: {0|1}점 ({근거})
의존성:   {0|1}점 ({근거})
모듈 영향: {0|1}점 ({근거})
사용자 명시: {0|1}점
총점: {score}/5 → {Ralplan 실행|Planner 단독}
═══════════════════
```
ML 보조가 활성인 경우 추가 출력:
```
ML 예측: {ml_score}/5 (confidence: {conf}) [{shadow|hybrid|primary}]
```

**Ultra Plan 실행 (5-Phase 파이프라인)**

> 트리거: `--ultra`/`--ultrathink` 명시 또는 score==5 또는 Ultra 키워드 감지 (`--no-ultra` 없는 경우)
> 상세 프로토콜: `.claude/references/ultra-plan-protocol.md`

```
# ━━━ Phase 0.0: Deep Discovery (3 Explore 병렬) ━━━
TeamCreate(team_name="ultra-{feature}")

Agent(
  subagent_type="Explore",
  name="explore-codebase",
  description="기존 구현/유틸/패턴 탐색",
  team_name="ultra-{feature}",
  prompt="'{feature}' 관련 기존 구현을 탐색하라.
  재활용 가능한 함수, 기존 추상화, 유사 구현 보고.
  출력: (1) 재활용 후보 목록 (2) 중복 위험 (3) 기존 패턴"
)

Agent(
  subagent_type="Explore",
  name="explore-history",
  description="git 이력 분석",
  team_name="ultra-{feature}",
  prompt="git log --all --grep 및 git log -p 로 과거 유사 작업 탐색.
  실패한 시도, 롤백, 재시도 이력 보고.
  출력: (1) 유사 PR/커밋 목록 (2) 실패/롤백 이력 (3) 교훈"
)

Agent(
  subagent_type="Explore",
  name="explore-external",
  description="외부 패턴 조회",
  team_name="ultra-{feature}",
  prompt="context7 MCP로 관련 라이브러리/프레임워크 최신 문서 조회.
  업계 표준 패턴, 안티패턴, known issues 보고.
  출력: (1) 표준 패턴 (2) 안티패턴 (3) 주의사항"
)

# 3개 병렬 shutdown 대기
SendMessage(to="explore-codebase", message={type: "shutdown_request"})
SendMessage(to="explore-history", message={type: "shutdown_request"})
SendMessage(to="explore-external", message={type: "shutdown_request"})
# 타임아웃 처리: 3개 중 2개 성공 → 진행. 1개만 성공 → warn + 진행. 0개 → Ralplan 폴백.

# ━━━ Phase 0.1α: 확장 Ralplan (5인 합의, ultrathink 주입) ━━━
Agent(
  subagent_type="planner",
  name="ultra-planner",
  description="[Ultra] 전략 수립",
  team_name="ultra-{feature}",
  model="opus",
  prompt="[Discovery]
  - Codebase: {explore_codebase_result}
  - History: {explore_history_result}
  - External: {explore_external_result}

  ultrathink

  '{feature}'의 최적 구현 전략을 도출하라.
  기존 자산 재활용을 최우선 고려. 과거 실패 반복 금지."
)

Agent(
  subagent_type="architect",
  name="ultra-architect",
  description="[Ultra] 기술 타당성",
  team_name="ultra-{feature}",
  model="opus",
  prompt="[Planner 초안] {planner_output}
  [Discovery] {discovery_bundle}

  ultrathink

  기술적 타당성 검증: 아키텍처 정합성, 결합도, 성능/확장성 영향."
)

Agent(
  subagent_type="critic",
  name="ultra-critic",
  description="[Ultra] 엣지 케이스",
  team_name="ultra-{feature}",
  model="opus",
  prompt="[Planner 초안] {planner_output}
  [Architect 검토] {architect_output}

  ultrathink

  엣지 케이스와 반례를 찾아라: 경계 조건, 동시성, 예외 처리 누락."
)

Agent(
  subagent_type="pre-mortem-analyst",
  name="pre-mortem",
  description="[Ultra] 실패 시나리오 5개 도출",
  team_name="ultra-{feature}",
  model="opus",
  prompt="[계획 초안] {planner_output}
  [Discovery] {discovery_bundle}

  ultrathink

  이 계획이 6개월 후 실패했다고 가정하고 실패 시나리오 5개 도출.
  각각 선행 지표와 예방 조치 포함. 축 분산 필수."
)

Agent(
  subagent_type="alternative-explorer",
  name="alt-explorer",
  description="[Ultra] 대안 3개 탐색",
  team_name="ultra-{feature}",
  model="opus",
  prompt="[기본 안] {planner_output}
  [Discovery] {discovery_bundle}

  ultrathink

  본질적으로 다른 접근 3개 제안 (Minimalist / Future-proof / Paradigm shift).
  각 대안의 트레이드오프 표와 추천 근거 명시."
)

SendMessage(to="ultra-planner", message={type: "shutdown_request"})
SendMessage(to="ultra-architect", message={type: "shutdown_request"})
SendMessage(to="ultra-critic", message={type: "shutdown_request"})
SendMessage(to="pre-mortem", message={type: "shutdown_request"})
SendMessage(to="alt-explorer", message={type: "shutdown_request"})

# ━━━ Phase 0.1β: Consolidation (planner + ultrathink) ━━━
Agent(
  subagent_type="planner",
  name="ultra-consolidator",
  description="[Ultra] 5인 합의 통합 및 최종 Plan 작성",
  team_name="ultra-{feature}",
  model="opus",
  prompt="아래 입력을 통합해 docs/01-plan/{feature}.plan.md를 작성하라.

  [입력]
  - Discovery: {discovery_bundle}
  - Planner: {planner_output}
  - Architect: {architect_output}
  - Critic: {critic_output}
  - Pre-mortem: {pre_mortem_output}
  - Alternatives: {alt_explorer_output}

  ultrathink

  [필수 섹션 7개]
  ## 배경
  ## 구현 범위
  ## 영향 파일
  ## 위험 요소
  ## 고려된 대안            (3개 대안 + 트레이드오프 표 + 선택 이유)
  ## 실패 시나리오          (5개 시나리오 + 선행 지표 + 예방 조치)
  ## Discovery 요약         (Codebase/History/External 핵심 발견사항)"
)
SendMessage(to="ultra-consolidator", message={type: "shutdown_request"})
```
→ `docs/01-plan/{feature}.plan.md` 생성 (Ultra Plan 5-Phase 결과)

# ── Embedded Critic Gate: Plan-Ultra ──
# 참조: .claude/references/embedded-critic-protocol.md (plan-ultra 기준)
IF NOT --skip-critic:
  Agent(
    subagent_type="doc-critic",
    name="quick-critic-plan-ultra",
    description="Ultra Plan 빠른 검증",
    team_name="ultra-{feature}",
    prompt="[QUICK VALIDATION MODE]
    대상: docs/01-plan/{feature}.plan.md
    문서 유형: plan-ultra

    평가 기준 (5개):
    1. 기본 4섹션(배경/범위/영향/위험) 존재
    2. '고려된 대안' 섹션에 3개+ 대안 + 트레이드오프 표
    3. '실패 시나리오' 섹션에 5개+ 시나리오 + 선행 지표/예방 조치
    4. 'Discovery 요약' 섹션 존재
    5. 섹션 간 논리 흐름, 설명 없는 전문 용어 0건

    VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK"
  )
  SendMessage(to="quick-critic-plan-ultra", message={type: "shutdown_request"})

  IF VERDICT == REJECT AND FEEDBACK exists:
    Agent(
      subagent_type="planner",
      name="ultra-rewriter",
      description="Ultra Plan 개선 (critic 피드백 반영)",
      team_name="ultra-{feature}",
      model="opus",
      prompt="docs/01-plan/{feature}.plan.md를 아래 피드백에 따라 수정하라:
      {FEEDBACK}

      ultrathink"
    )
    SendMessage(to="ultra-rewriter", message={type: "shutdown_request"})
    Agent(
      subagent_type="doc-critic",
      name="quick-critic-plan-ultra-retry",
      description="Ultra Plan 재검증",
      team_name="ultra-{feature}",
      prompt="[재검증] docs/01-plan/{feature}.plan.md — 동일 5개 기준 평가.
      VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK 출력."
    )
    SendMessage(to="quick-critic-plan-ultra-retry", message={type: "shutdown_request"})

# Ultra Plan 완료 → Phase 0.2 (Design) 으로 진행
# TeamDelete()는 auto-{feature} 팀이 Phase 끝까지 유지되므로 여기서 호출하지 않음

---

**score >= 3 (Ultra 아님): Ralplan 실행 (Agent Teams — Planner + Critic 2인 합의)**

> **에러 컨텍스트 감지**: 작업 설명에 "에러", "수정", "fix", "bug", "debug", "오류", "실패" 키워드가 포함되거나, `/debug` D4에서 진입한 경우 에러 컨텍스트로 판단합니다.

```
# Step A: Ralplan 팀 생성 (Planner → Critic 합의, Architect는 Check Phase에서 검증)
TeamCreate(team_name="ralplan-{feature}")

Agent(
  subagent_type="planner",
  name="planner",
  description="계획 수립",
  team_name="ralplan-{feature}",
  model="opus",
  prompt="작업에 대한 구현 계획을 수립하세요: {작업 설명}
  docs/01-plan/ 내 기존 Plan과 범위 겹침 여부 확인 필수.
  포함: 구현 범위, 영향 파일, 위험 요소, 아키텍처 결정"
  # 에러 컨텍스트일 경우 아래 프롬프트로 교체:
  # prompt="[ERROR FIX PLANNING] 작업에 대한 수정 전략을 수립하세요: {작업 설명}
  # 포함: 수정 전략(접근 방식+근거), 영향 범위(수정 파일+의존 모듈),
  # 회귀 위험+완화 방안, 외부 검증 신호(테스트/빌드/린트)"
)

Agent(
  subagent_type="critic",
  name="critic",
  description="계획 비판",
  team_name="ralplan-{feature}",
  model="opus",
  prompt="planner 결과를 비판적으로 검토하세요.
  누락된 엣지 케이스, 과도한 복잡성, 더 나은 대안 제시.
  아키텍처 일관성도 함께 검증."
  # 에러 컨텍스트일 경우 아래 프롬프트로 교체:
  # prompt="[FIX STRATEGY CRITIQUE] planner 수정 전략을 검증하세요.
  # 1. 수정이 근본 원인을 해결하는가? (증상 대응 아닌지)
  # 2. 더 안전한 대안은? 3. 회귀 위험 평가(1-5)
  # 4. 외부 검증 신호 충분한가?
  # 검증 프로토콜: .claude/references/verification-protocol.md"
)

# Planner에게 시작 지시
SendMessage(to="planner", summary="계획 수립 시작", message="작업 설명: {작업}")
# Critic 검토
SendMessage(to="critic", summary="계획 비판 요청", message="planner 결과: {결과}")

# 합의 후 정리
SendMessage(to="planner", message={type: "shutdown_request"})
SendMessage(to="critic", message={type: "shutdown_request"})
TeamDelete()

# Step B: 합의 결과를 PDCA Plan 문서로 기록
TeamCreate(team_name="auto-{feature}")

Agent(
  subagent_type="executor",
  name="plan-writer",
  description="[PDCA Plan] Ralplan 결과 문서화",
  team_name="auto-{feature}",
  model="sonnet",
  prompt="Ralplan 합의 결과를 docs/01-plan/{feature}.plan.md에 기록하세요.

  포함 항목:
  - 복잡도 점수: {score}/5 (각 조건별 판단 근거)
  - 합의된 아키텍처 결정사항
  - 구현 범위 및 제외 항목
  - 예상 영향 파일 목록
  - 위험 요소 및 완화 방안
  - Planner/Architect/Critic 각 관점 요약
  - 관련 PRD: {PRD-NNNN 또는 '없음'}
  - 기존 Plan 중복 확인: {중복 없음 또는 겹치는 Plan 파일명}"
)

SendMessage(to="plan-writer", message={type: "shutdown_request"})
# TeamDelete()는 auto-{feature} 팀이 Phase 끝까지 유지되므로 여기서 호출하지 않음

# ── Embedded Critic Gate: Plan (Ralplan 경로) ──
# 참조: .claude/references/embedded-critic-protocol.md
IF NOT --skip-critic:
  Agent(
    subagent_type="doc-critic",
    name="quick-critic-plan",
    description="Plan 빠른 검증",
    team_name="auto-{feature}",
    prompt="[QUICK VALIDATION MODE]
    대상 문서: docs/01-plan/{feature}.plan.md
    문서 유형: plan

    평가 기준 (3개 항목만):
    1. 필수 섹션 4개 존재 (배경, 구현 범위, 영향 파일, 위험 요소)
    2. 섹션 간 논리 흐름 — 비약 0건
    3. 설명 없는 전문 용어 0건

    VERDICT: APPROVE | REJECT
    CONFIDENCE: HIGH | MEDIUM | LOW
    RISK_SCORE: 1-5
    FEEDBACK: [REJECT 시 구체적 개선 지시]"
  )
  SendMessage(to="quick-critic-plan", message={type: "shutdown_request"})

  IF VERDICT == REJECT AND FEEDBACK exists:
    Agent(
      subagent_type="executor",
      name="plan-rewriter",
      description="Plan 개선 (critic 피드백 반영)",
      team_name="auto-{feature}",
      model="sonnet",
      prompt="docs/01-plan/{feature}.plan.md를 아래 피드백에 따라 수정하세요:
      {FEEDBACK}
      수정 후 동일 파일에 저장."
    )
    SendMessage(to="plan-rewriter", message={type: "shutdown_request"})
    # 재검증 (1회, 결과 확정 — 추가 rewrite 없음)
    Agent(
      subagent_type="doc-critic",
      name="quick-critic-plan-retry",
      description="Plan 재검증",
      team_name="auto-{feature}",
      prompt="[재검증] docs/01-plan/{feature}.plan.md — 동일 3개 기준 평가.
      VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK 출력."
    )
    SendMessage(to="quick-critic-plan-retry", message={type: "shutdown_request"})
```
→ `docs/01-plan/{feature}.plan.md` 생성 (Ralplan 합의 결과 포함)

**score < 3: Planner 단독 실행**
```
TeamCreate(team_name="auto-{feature}")

Agent(
  subagent_type="planner",
  name="solo-planner",
  description="[PDCA Plan] 기능 계획",
  team_name="auto-{feature}",
  model="opus",
  prompt="기능 계획을 수립하세요. (복잡도 점수: {score}/5, 판단 근거 포함)"
)

SendMessage(to="solo-planner", message={type: "shutdown_request"})

# ── Embedded Critic Gate: Plan (solo-planner 경로) ──
# 참조: .claude/references/embedded-critic-protocol.md
IF NOT --skip-critic:
  Agent(
    subagent_type="doc-critic",
    name="quick-critic-plan",
    description="Plan 빠른 검증",
    team_name="auto-{feature}",
    prompt="[QUICK VALIDATION MODE]
    대상 문서: docs/01-plan/{feature}.plan.md
    문서 유형: plan

    평가 기준 (3개 항목만):
    1. 필수 섹션 4개 존재 (배경, 구현 범위, 영향 파일, 위험 요소)
    2. 섹션 간 논리 흐름 — 비약 0건
    3. 설명 없는 전문 용어 0건

    VERDICT: APPROVE | REJECT
    CONFIDENCE: HIGH | MEDIUM | LOW
    RISK_SCORE: 1-5
    FEEDBACK: [REJECT 시 구체적 개선 지시]"
  )
  SendMessage(to="quick-critic-plan", message={type: "shutdown_request"})

  IF VERDICT == REJECT AND FEEDBACK exists:
    Agent(
      subagent_type="executor",
      name="plan-rewriter",
      description="Plan 개선 (critic 피드백 반영)",
      team_name="auto-{feature}",
      model="sonnet",
      prompt="docs/01-plan/{feature}.plan.md를 아래 피드백에 따라 수정하세요:
      {FEEDBACK}"
    )
    SendMessage(to="plan-rewriter", message={type: "shutdown_request"})
    Agent(
      subagent_type="doc-critic",
      name="quick-critic-plan-retry",
      description="Plan 재검증",
      team_name="auto-{feature}",
      prompt="[재검증] docs/01-plan/{feature}.plan.md — 동일 3개 기준 평가.
      VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK 출력."
    )
    SendMessage(to="quick-critic-plan-retry", message={type: "shutdown_request"})
```
→ `docs/01-plan/{feature}.plan.md` 생성 (단독 Planner 결과)

**Step 0.2: Design 문서 생성 (Plan 게이트 검증 포함)**

**Plan→Design 전환 게이트 (MANDATORY):**
Design 생성 전 Plan 문서에 아래 4개 필수 섹션이 존재하는지 확인합니다.
누락 시 Plan 문서를 먼저 보완한 후 Design으로 진행합니다.

| # | 필수 섹션 | 확인 방법 |
|:-:|----------|----------|
| 1 | 배경/문제 정의 | `## 배경` 또는 `## 문제 정의` 헤딩 존재 |
| 2 | 구현 범위 | `## 구현 범위` 또는 `## 범위` 헤딩 존재 |
| 3 | 예상 영향 파일 | 파일 경로 목록 포함 (`.py`, `.ts`, `.md` 등) |
| 4 | 위험 요소 | `## 위험` 또는 `위험 요소` 헤딩 존재 |

```
# Plan 게이트 검증 (3단계 강제 원칙 — 단계1 논리적 완성)
# 참조: .claude/references/verification-protocol.md "3단계 강제 원칙"
plan_path = "docs/01-plan/{feature}.plan.md"
plan_content = Read(plan_path)

# 4개 필수 섹션 존재 확인 (정량 검증)
gate_checks = {
  "배경/문제 정의": plan_content에 "## 배경" 또는 "## 문제 정의" 헤딩 존재,
  "구현 범위":     plan_content에 "## 구현 범위" 또는 "## 범위" 헤딩 존재,
  "영향 파일":     plan_content에 .py/.ts/.md/.json 등 파일 경로 1개 이상 포함,
  "위험 요소":     plan_content에 "## 위험" 또는 "위험 요소" 헤딩 존재
}

missing = [k for k, v in gate_checks.items() if not v]
if missing:
  # Plan 보완 (1회 허용)
  Agent(
    subagent_type="executor",
    name="plan-補完",
    description="Plan 누락 섹션 보완",
    team_name="auto-{feature}",
    model="sonnet",
    prompt="Plan 문서 {plan_path}에 누락 섹션이 있습니다: {missing}. 보완하세요."
  )
  SendMessage(to="plan-補完", message={type: "shutdown_request"})
  # 재검증 (1회만)
  plan_content = Read(plan_path)
  missing = [재검증]
  if missing:
    AskUserQuestion("Plan 게이트 통과 실패. 누락: {missing}. 수동 보완이 필요합니다.")
    STOP  # 사용자 개입 없이 진행 불가

# Plan 게이트 통과 → Design 생성
Agent(
  subagent_type="architect",
  name="designer",
  description="[PDCA Design] 기능 설계",
  team_name="auto-{feature}",
  model="opus",
  prompt="docs/01-plan/{feature}.plan.md를 참조하여 설계 문서를 작성하세요.
  Plan Reference 필드에 Plan 문서 경로를 명시하세요."
)

SendMessage(to="designer", message={type: "shutdown_request"})

# ── Embedded Critic Gate: Design ──
# 참조: .claude/references/embedded-critic-protocol.md
IF NOT --skip-critic:
  Agent(
    subagent_type="doc-critic",
    name="quick-critic-design",
    description="Design 빠른 검증",
    team_name="auto-{feature}",
    prompt="[QUICK VALIDATION MODE]
    대상 문서: docs/02-design/{feature}.design.md
    문서 유형: design

    평가 기준 (3개 항목만):
    1. 목차 연결성 + 비약 탐지 (맥락 연결, 비약 0건, 직관적 흐름, 난이도 순서)
    2. 300자+ 섹션에 시각 자료(mermaid, 표, 이미지) 1개 이상 존재
    3. 설명 없는 전문 용어 0건

    VERDICT: APPROVE | REJECT
    CONFIDENCE: HIGH | MEDIUM | LOW
    RISK_SCORE: 1-5
    FEEDBACK: [REJECT 시 구체적 개선 지시]"
  )
  SendMessage(to="quick-critic-design", message={type: "shutdown_request"})

  IF VERDICT == REJECT AND FEEDBACK exists:
    Agent(
      subagent_type="architect",
      name="design-rewriter",
      description="Design 개선 (critic 피드백 반영)",
      team_name="auto-{feature}",
      model="opus",
      prompt="docs/02-design/{feature}.design.md를 아래 피드백에 따라 수정하세요:
      {FEEDBACK}"
    )
    SendMessage(to="design-rewriter", message={type: "shutdown_request"})
    Agent(
      subagent_type="doc-critic",
      name="quick-critic-design-retry",
      description="Design 재검증",
      team_name="auto-{feature}",
      prompt="[재검증] docs/02-design/{feature}.design.md — 동일 3개 기준 평가.
      VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK 출력."
    )
    SendMessage(to="quick-critic-design-retry", message={type: "shutdown_request"})
```
→ `docs/02-design/{feature}.design.md` 생성

**Design 산출물 게이트 (3단계 강제 원칙 — 단계2 문서화):**
```
# Do 진입 전 Design 문서 존재 확인 (MANDATORY)
design_path = "docs/02-design/{feature}.design.md"
if not file_exists(design_path):
  ❌ 차단: Design 문서가 존재하지 않습니다. Step 0.2를 먼저 완료하세요.
  STOP  # Design 없이 구현 진입 불가
```

**Step 0.3: Do (구현)**
- 기존 /auto 워크플로우 (Ralplan + Ultrawork)

**Step 0.4: Check (단일 Architect 통합 검증)**
```
# 기능 완성도 + 설계-구현 갭을 단일 Architect가 통합 검증
Agent(
  subagent_type="architect",
  name="check-architect",
  description="기능 완성도 + 설계-구현 갭 통합 검증",
  team_name="auto-{feature}",
  model="opus",
  prompt="구현 완료를 통합 검증하세요:
  1. 기능 동작, 테스트 통과, 코드 품질 확인
  2. docs/02-design/{feature}.design.md와 실제 구현의 일치도 검증
  gap 점수(0-100%)를 산출하고, 90% 미만이면 불일치 항목을 나열하세요."
)

SendMessage(to="check-architect", message={type: "shutdown_request"})
```
- check-architect: 기능 완성도 + 설계-구현 90% 일치 통합 검증

**Step 0.5: Act (자동 실행 - CRITICAL)**

**PDCA 완료 시 자동 실행 규칙 (Recommended 출력 금지):**

```
┌─────────────────────────────────────────────────────────────┐
│              Act Phase 자동 실행 로직                         │
│                                                             │
│   Check 결과                      자동 실행                  │
│   ─────────────────────────────────────────────────────────  │
│   gap < 90%         →  executor (최대 5회 반복 개선)         │
│   gap >= 90%        →  writer (완료 보고서 자동 생성)        │
│   Architect REJECT  →  executor (피드백 반영 수정)           │
│   모든 조건 충족     →  완료 보고서 자동 생성                  │
│                                                             │
│   ⚠️ "Recommended: ..." 출력 후 종료 = 금지                  │
│   ⚠️ 자동 실행 후 결과 출력 = 필수                            │
└─────────────────────────────────────────────────────────────┘
```

**Case 1: gap < 90%**
```
Agent(
  subagent_type="executor",
  name="gap-fixer",
  description="[PDCA Act] 갭 자동 개선",
  team_name="auto-{feature}",
  model="sonnet",
  prompt="설계-구현 갭을 90% 이상으로 개선하세요. 최대 5회 반복."
)

SendMessage(to="gap-fixer", message={type: "shutdown_request"})
```

**Case 2: gap >= 90%**
```
Agent(
  subagent_type="writer",
  name="report-writer",
  description="[PDCA Report] 완료 보고서 생성",
  team_name="auto-{feature}",
  model="haiku",
  prompt="PDCA 사이클 완료 보고서를 생성하세요.

  포함 항목:
  - Plan 요약: docs/01-plan/{feature}.plan.md
  - Design 요약: docs/02-design/{feature}.design.md
  - 구현 결과 및 변경 파일 목록
  - Check 결과 (gap 점수, Architect 판정)
  - 교훈 및 개선 사항

  출력 위치: docs/04-report/{feature}.report.md"
)

SendMessage(to="report-writer", message={type: "shutdown_request"})

# ── Embedded Critic Gate: Report ──
# 참조: .claude/references/embedded-critic-protocol.md
IF NOT --skip-critic:
  Agent(
    subagent_type="doc-critic",
    name="quick-critic-report",
    description="Report 빠른 검증",
    team_name="auto-{feature}",
    prompt="[QUICK VALIDATION MODE]
    대상 문서: docs/04-report/{feature}.report.md
    문서 유형: report

    평가 기준 (3개 항목만):
    1. PDCA 4개 Phase(Plan, Design/Do, Check, Act) 모두 참조됨
    2. 평균 문장 길이 40자 이하
    3. 정량 지표(숫자, 퍼센트, 기간) 1개 이상 포함

    VERDICT: APPROVE | REJECT
    CONFIDENCE: HIGH | MEDIUM | LOW
    RISK_SCORE: 1-5
    FEEDBACK: [REJECT 시 구체적 개선 지시]"
  )
  SendMessage(to="quick-critic-report", message={type: "shutdown_request"})

  IF VERDICT == REJECT AND FEEDBACK exists:
    Agent(
      subagent_type="writer",
      name="report-rewriter",
      description="Report 개선 (critic 피드백 반영)",
      team_name="auto-{feature}",
      model="haiku",
      prompt="docs/04-report/{feature}.report.md를 아래 피드백에 따라 수정하세요:
      {FEEDBACK}"
    )
    SendMessage(to="report-rewriter", message={type: "shutdown_request"})
    Agent(
      subagent_type="doc-critic",
      name="quick-critic-report-retry",
      description="Report 재검증",
      team_name="auto-{feature}",
      prompt="[재검증] docs/04-report/{feature}.report.md — 동일 3개 기준 평가.
      VERDICT/CONFIDENCE/RISK_SCORE/FEEDBACK 출력."
    )
    SendMessage(to="quick-critic-report-retry", message={type: "shutdown_request"})
```

**Case 3: Architect REJECT**
```
Agent(
  subagent_type="executor",
  name="feedback-applier",
  description="[PDCA Act] Architect 피드백 반영",
  team_name="auto-{feature}",
  model="sonnet",
  prompt="Architect 거부 사유를 해결하세요: {rejection_reason}"
)

SendMessage(to="feedback-applier", message={type: "shutdown_request"})
# 해결 후 Check Phase 재실행
```

**Case 4: Ralph 루프 수정안 검증 (2회차+ 실패 시)**

Ralph 루프에서 조건 실패 → 수정 시도 시:
- 1회차 실패: executor 직접 재시도 (기존 동작 유지)
- 2회차+ 실패: Critic 수정안 검증 후 재시도

```
Agent(
  subagent_type="critic",
  name="fix-critic",
  description="[PDCA Act] 수정안 적정성 검증",
  team_name="auto-{feature}",
  model="opus",
  prompt="수정안을 검증하세요:
  - 실패 원인: {failure_reason}
  - 제안된 수정: {proposed_fix}
  - 이전 시도: {attempt_count}회
  
  검증 프로토콜: .claude/references/verification-protocol.md
  VERDICT: APPROVE | REJECT (REJECT 시 대안 제시 필수)"
)

SendMessage(to="fix-critic", message={type: "shutdown_request"})

# APPROVE → executor 재시도
# REJECT → critic 대안 반영 후 executor 재시도
```

> 최대 2회 Critic 라운드. 2회 REJECT 시 경고 포함 진행.

**자동 실행 후 출력 형식:**
```
═══════════════════════════════════════════════════
 ✅ PDCA 사이클 완료
═══════════════════════════════════════════════════
 Check 결과: gap 94% (≥90% 통과)
 Act 실행: report-writer → docs/04-report/{feature}.report.md

 📄 보고서 생성 완료
═══════════════════════════════════════════════════
```

**❌ 금지 패턴:**
```
# 이렇게 출력하고 끝내면 안됨!
💡 Recommended: /pdca report vercel-bp-integration (완료 리포트 자동화)
```

→ Recommended가 있으면 **즉시 자동 실행** 후 결과 출력

**PDCA 완료 후 팀 정리:**
```
# 모든 Phase 완료 후 auto 팀 삭제
TeamDelete()
```

### Phase 1: 옵션 라우팅 (있을 경우)

| 옵션 | 실행할 스킬 | 설명 |
|------|-------------|------|
| `--gdocs` | `Skill(skill="prd-sync")` | Google Docs PRD 동기화 |
| `--mockup` | `Skill(skill="mockup-hybrid", args="...")` | 목업 생성 |
| `--debate` | `Skill(skill="ultimate-debate", args="...")` | 3AI 토론 |
| `--research` | `Skill(skill="research", args="...")` | 리서치 모드 |
| `--slack <채널>` | Slack 채널 분석 후 컨텍스트 주입 | 채널 히스토리 기반 작업 |
| `--gmail` | Gmail 메일 분석 후 컨텍스트 주입 | 메일 기반 작업 |
| `--daily` | `Skill(skill="daily")` | daily v3.0 9-Phase Pipeline (Config Bootstrap 내장) |
| `--daily --slack` | `Skill(skill="daily")` | 동일 Pipeline + Phase 6 Slack Lists 갱신 |
| `--interactive` | 각 Phase 전환 시 사용자 승인 요청 | 단계적 승인 모드 |
| `--con <page_id> [file]` | `lib/confluence/md2confluence.py` 실행 | Confluence 페이지 발행 |
| `--skip-critic` | 문서 생성 후 embedded critic 게이트 생략 | 빠른 프로토타이핑 시 |
| `--ultra` | Ultra Plan 5-Phase 파이프라인 강제 활성화 | 복잡/중요 작업 심층 계획 |
| `--ultrathink` | `--ultra`의 alias | — |
| `--no-ultra` | score=5여도 Ultra Plan 비활성화 (Ralplan 사용) | Ultra 자동 트리거 회피 |

**옵션 체인 예시:**
```
/auto --gdocs --mockup "화면명"
→ Step 1: Skill(skill="prd-sync")
→ Step 2: Skill(skill="mockup-hybrid", args="화면명")

/auto --slack C09N8J3UJN9 "EBS 프로젝트"
→ Step 1: Slack 채널 히스토리 수집
→ Step 2: 메시지 분석 및 컨텍스트 생성
→ Step 3: 컨텍스트 기반 메인 워크플로우 실행

/auto --gmail "클라이언트 메일 분석 후 응답 초안 작성"
→ Step 1: Gmail 인증 확인
→ Step 2: 안 읽은 메일 또는 검색 결과 수집
→ Step 3: 메일 분석 및 컨텍스트 생성
→ Step 4: 컨텍스트 기반 메인 워크플로우 실행

/auto --con 123456 "PRD 발행"
→ Step 1: 발행 대상 파일 결정 (PRD/Plan 자동 탐지 또는 명시 경로)
→ Step 2: python lib/confluence/md2confluence.py <file> <page_id>
→ Step 3: 결과 보고 (성공/실패 + 페이지 버전)
```

**옵션 실패 시**: 에러 메시지 출력하고 **절대 조용히 스킵하지 않음**

### `--slack` 옵션 워크플로우

Slack 채널의 모든 메시지를 분석하여 프로젝트 컨텍스트로 활용합니다.

**Step 1: 인증 확인**
```bash
cd C:\claude && python -m lib.slack status --json
```
- `"authenticated": false` → 에러 출력 후 중단

**Step 2: 채널 히스토리 수집**
```bash
python -m lib.slack history "<채널ID>" --limit 100 --json
```
- 메시지 100개 단위로 수집
- 필요 시 페이지네이션 (oldest 파라미터)

**Step 3: 메시지 분석 (Agent Teams)**
```
TeamCreate(team_name="auto-slack")

Agent(
  subagent_type="analyst",
  name="slack-analyst",
  description="Slack 채널 메시지 분석",
  team_name="auto-slack",
  model="opus",
  prompt="SLACK CHANNEL ANALYSIS

채널: <채널ID>
메시지 수: <N>개

분석 항목:
1. 주요 토픽 및 프로젝트 목표
2. 핵심 결정사항 및 합의점
3. 공유된 문서 링크 정리
4. 참여자 역할 및 책임
5. 미해결 이슈 및 질문
6. 기술 스택 및 도구 언급

출력: 구조화된 컨텍스트 문서"
)

SendMessage(to="slack-analyst", message={type: "shutdown_request"})
TeamDelete()
```

**Step 4: 컨텍스트 파일 생성**

`.omc/slack-context/<채널ID>.md` 생성:
```markdown
# Slack Channel Context: <채널명>

## 프로젝트 개요
[분석된 프로젝트 목표]

## 핵심 결정사항
[주요 합의점 목록]

## 관련 문서
[Google Docs 등 링크 목록]

## 기술 스택
[언급된 기술 목록]

## 미해결 이슈
[추적 필요한 항목]

## 원본 메시지 (최근 50개)
[타임스탬프별 메시지]
```

**Step 5: 메인 워크플로우 실행**
- 생성된 컨텍스트 파일을 Read하여 Ralplan에 전달
- 작업 실행 시 Slack 컨텍스트 참조

### `--gmail` 옵션 워크플로우

Gmail 메일을 분석하여 프로젝트 컨텍스트로 활용합니다.

**사용 형식:**
```bash
/auto --gmail                           # 안 읽은 메일 분석
/auto --gmail "검색어"                   # Gmail 검색 쿼리로 필터링
/auto --gmail "작업 설명"                # 메일 기반 작업 실행
/auto --gmail "from:client" "응답 초안"  # 검색 + 작업 조합
```

**Step 1: 인증 확인 (MANDATORY)**
```bash
cd C:\claude && python -m lib.gmail status --json
```
- `"authenticated": true, "valid": true` → 계속 진행
- `"authenticated": false` → **에러 출력 후 중단**:
  ```
  ❌ Gmail 인증이 필요합니다.
  실행: python -m lib.gmail login
  ```

**Step 2: 메일 수집**

| 입력 패턴 | 실행 명령 |
|----------|----------|
| `--gmail` (검색어 없음) | `python -m lib.gmail unread --limit 20 --json` |
| `--gmail "from:..."` | `python -m lib.gmail search "from:..." --limit 20 --json` |
| `--gmail "subject:..."` | `python -m lib.gmail search "subject:..." --limit 20 --json` |
| `--gmail "newer_than:7d"` | `python -m lib.gmail search "newer_than:7d" --limit 20 --json` |

**Gmail 검색 쿼리 문법:**
| 조건 | 예시 |
|------|------|
| 발신자 | `from:boss@company.com` |
| 제목 | `subject:meeting` |
| 최근 N일 | `newer_than:7d` |
| 첨부파일 | `has:attachment` |
| 안 읽음 | `is:unread` |
| 라벨 | `label:work` |

**Step 3: 메일 분석 (Agent Teams)**
```
TeamCreate(team_name="auto-gmail")

Agent(
  subagent_type="analyst",
  name="gmail-analyst",
  description="Gmail 메일 분석",
  team_name="auto-gmail",
  model="opus",
  prompt="GMAIL ANALYSIS

메일 수: <N>개
메일 데이터:
<JSON 메일 목록>

분석 항목:
1. 주요 요청사항 및 할일 추출
2. 중요 발신자 및 우선순위 분류
3. 회신 필요한 메일 식별 (긴급도 표시)
4. 첨부파일 목록 및 처리 필요 여부
5. 키워드 및 프로젝트 연관성 분석
6. 잠재적 이슈 및 리스크 식별

출력: 구조화된 이메일 분석 문서 (마크다운)"
)

SendMessage(to="gmail-analyst", message={type: "shutdown_request"})
TeamDelete()
```

**Step 4: 컨텍스트 파일 생성**

`.omc/gmail-context/<timestamp>.md` 생성:
```markdown
# Gmail Context: <날짜>

## 요약
- 총 메일: N개
- 긴급 회신 필요: N개
- 할일 추출: N개

## 긴급 (회신 필요)
| 발신자 | 제목 | 날짜 | 요청사항 |
|--------|------|------|----------|
| ... | ... | ... | ... |

## 할일 추출
- [ ] 항목 1 (발신자, 제목, 기한)
- [ ] 항목 2

## 메일 목록 (우선순위순)
### 높음
- **제목** from 발신자 (날짜)
  > 스니펫...

### 보통
- ...

## 첨부파일
- filename.pdf (발신자, 제목)

## 관련 링크
- [링크명](URL)
```

**Step 5: 후속 작업 분기**

| 사용자 요청 | 실행 |
|------------|------|
| 검색만 | 분석 결과 출력 후 종료 |
| "응답 초안" | 각 메일에 대한 회신 초안 생성 |
| "할일 생성" | TaskCreate로 TODO 항목 생성 |
| "요약 전송" | 분석 결과를 이메일로 전송 |
| 구체적 작업 | 메인 워크플로우 실행 (메일 컨텍스트 포함) |

**예시 실행:**
```
/auto --gmail "from:client newer_than:3d" "각 메일에 응답 초안 작성"

→ Step 1: 인증 확인 ✓
→ Step 2: python -m lib.gmail search "from:client newer_than:3d" --limit 20 --json
→ Step 3: Agent Teams analyst가 메일 분석
→ Step 4: .omc/gmail-context/2026-02-02.md 생성
→ Step 5: 각 메일별 응답 초안 생성
→ 결과 출력
```

### `--daily` 옵션 워크플로우 (v3.0)

`/auto --daily`는 daily v3.0 스킬을 직접 호출합니다. 모든 로직(Config Bootstrap, 증분 수집, AI 분석, 액션 추천)은 daily 스킬 내부에서 처리됩니다.

**사용 형식:**
```bash
/auto --daily                    # 9-Phase Pipeline 전체 실행
/auto --daily --slack            # 동일 + Phase 6 Slack Lists 갱신
/auto --daily ebs                # EBS 전용 브리핑
```

**라우팅:**
```
/auto --daily
    │
    └─► Skill(skill="daily") 직접 호출
        └─► daily v3.0 Phase 0~8 자체 실행
            Phase 0: Config Bootstrap (auto-generate .project-sync.yaml)
            Phase 1: Expert Context Loading (프로젝트 전문가 학습)
            Phase 2: Incremental Collection (Gmail/Slack/GitHub 증분)
            Phase 3: Attachment Analysis (PDF/Excel AI 분석)
            Phase 4: Cross-Source Analysis (크로스소스 연결)
            Phase 5: Action Recommendation (액션 초안 생성)
            Phase 6: Project-Specific Ops (vendor/dev 타입별)
            Phase 7: Gmail Housekeeping (라벨/정리)
            Phase 8: State Update (커서/캐시 저장)
```

**상세 워크플로우:** `.claude/skills/daily/SKILL.md` (v3.0) 참조

### `--interactive` 옵션 워크플로우

각 PDCA Phase 전환 시 사용자에게 확인을 요청하여 단계적 승인을 받습니다.

**사용 형식:**
```bash
/auto --interactive "작업 설명"        # 모든 Phase에서 승인 요청
/auto --interactive --skip-plan "작업"  # Plan 건너뛰고 Design부터 시작
```

**동작 방식:**

각 Phase 전환 시 `AskUserQuestion`을 호출하여 사용자 선택을 받습니다:

| Phase 전환 | 선택지 | 기본값 |
|-----------|--------|:------:|
| Plan 완료 → Design | 진행 / 수정 / 건너뛰기 | 진행 |
| Design 완료 → Do | 진행 / 수정 / 건너뛰기 | 진행 |
| Do 완료 → Check | 진행 / 수정 | 진행 |
| Check 결과 → Act | 자동 개선 / 수동 수정 / 완료 | 자동 개선 |

**Phase 전환 시 출력 형식:**

```
═══════════════════════════════════════════════════
 Phase [현재] 완료 → Phase [다음] 진입 대기
═══════════════════════════════════════════════════
 산출물: docs/01-plan/{feature}.plan.md
 소요 에이전트: planner (opus), critic (opus)
 핵심 결정: [1줄 요약]
═══════════════════════════════════════════════════
```

**--interactive 미사용 시** (기본 동작): 모든 Phase를 자동으로 진행합니다.

### `--con` 옵션 워크플로우

Markdown 문서를 Confluence Storage Format으로 변환하여 지정 페이지에 발행한다.
Mermaid 다이어그램은 3-Stage Fallback (mermaid.ink → mmdc → Playwright)으로 PNG 변환 후 첨부파일로 업로드.

**사용 형식:**
```bash
/auto "작업" --con <page_id>              # PRD/Plan 자동 탐지 발행
/auto "작업" --con <page_id> <file.md>    # 지정 파일 발행
/auto "작업" --con <page_id> --dry-run    # 업로드 없이 미리보기
```

**실행 흐름:**

1. 환경변수 확인 (`ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN`)
2. 발행 대상 파일 결정:
   - 명시적 파일 경로 → 해당 파일
   - 미지정 → `docs/00-prd/{feature}.prd.md` 또는 `docs/01-plan/{feature}.plan.md` 자동 탐지
3. 실행:
   ```bash
   cd C:\claude && python lib/confluence/md2confluence.py <file> <page_id>
   ```
4. 결과 보고 (성공: 페이지 버전 + URL / 실패: 에러 메시지)

**에러 처리:**

| 에러 | 처리 |
|------|------|
| 인증 실패 (401) | 환경변수 확인 안내 + 중단 |
| 페이지 미존재 (404) | page_id 확인 안내 + 중단 |
| Mermaid 렌더링 실패 | 3-Stage Fallback 후에도 실패 시 에러 보고 + 중단 |
| pandoc 미설치 | 설치 안내 (`scoop install pandoc`) + 중단 |

**상세**: `secretary/.claude/skills/confluence/SKILL.md` 참조

## Ralph 루프 워크플로우 (CRITICAL)

**autopilot = Ralplan + Ultrawork + Ralph 루프**

### 실행 흐름

```
Ralplan (계획 합의)
       │
       ▼
Ultrawork (병렬 실행)
       │
       ▼
Architect 검증
       │
       ▼
┌──────────────────────────────────────┐
│         Ralph 루프 (5개 조건)          │
│                                      │
│  조건 1: TODO == 0                   │
│  조건 2: 기능 동작                    │
│  조건 3: 테스트 통과                  │
│  조건 4: 에러 == 0                   │
│  조건 5: Architect 승인              │
│                                      │
│  ANY 실패? ──YES──▶ 자동 재시도       │
│              NO ──▶ 완료 선언         │
└──────────────────────────────────────┘
```

**5개 조건 모두 충족될 때까지 자동으로 반복합니다.**

### Phase 2: 메인 워크플로우 (Ralph + Ultrawork + Team Coordinator)

**작업이 주어지면 (`/auto "작업내용"`):**

**Step 2.0: 복잡도 기반 라우팅 (10점 만점 확장)**

Step 0.1의 5점 만점 복잡도 점수를 10점으로 확장합니다:

| 점수 (10점) | 라우팅 경로 | 설명 |
|:-----------:|------------|------|
| 0-3 | 기존 경로 | Ralplan/Planner 단독 |
| 4-5 | Team Coordinator → Dev 단독 | 단일 기능 구현 |
| 6-7 | Team Coordinator → Dev + Quality | 기능 + 품질 검증 |
| 8-9 | Team Coordinator → Dev + Quality + Research | 복잡한 기능 + 조사 |
| 10 | Team Coordinator → 4팀 전체 | 대규모 프로젝트 |

**5점 → 10점 변환**: `score_10 = score_5 * 2` (기본). `"teamwork"` 키워드 포함 시 자동 10점.

**score < 4 (기존 경로 보존):**

1. **Ralplan 호출** (score >= 3인 경우):
   ```
   TeamCreate(team_name="ralplan-{feature}")

   Agent(subagent_type="planner", name="planner", description="계획 수립",
         team_name="ralplan-{feature}", model="opus", prompt="작업내용")
   Agent(subagent_type="architect", name="arch-reviewer", description="계획 검증",
         team_name="ralplan-{feature}", model="opus", prompt="...")
   Agent(subagent_type="critic", name="critic", description="계획 비판",
         team_name="ralplan-{feature}", model="opus", prompt="...")

   # Planner → Architect → Critic 합의 도달까지 반복
   SendMessage(to="planner", summary="시작", message="...")
   # ... 합의 후 정리
   SendMessage(to="planner", message={type: "shutdown_request"})
   SendMessage(to="arch-reviewer", message={type: "shutdown_request"})
   SendMessage(to="critic", message={type: "shutdown_request"})
   TeamDelete()
   ```

2. **Ultrawork 모드 활성화**:
   - 모든 독립적 작업은 **병렬 실행**
   - Agent Teams 패턴으로 여러 Agent 동시 스폰
   - 10+ 동시 에이전트 허용

3. **에이전트 라우팅**:

   | 작업 유형 | 에이전트 | 모델 |
   |----------|----------|------|
   | 간단한 조회 | `Explore` (면제 타입) | haiku |
   | 기능 구현 | `executor` | sonnet |
   | 복잡한 분석 | `architect` | opus |
   | UI 작업 | `designer` | sonnet |
   | 테스트 | `qa-tester` | sonnet |
   | 빌드 에러 | `build-fixer` | sonnet |

**score >= 4 (Team Coordinator — Agent Teams):**

```
TeamCreate(team_name="teamwork-{feature}")

# 복잡도에 따라 팀 배치
# score 4-5: Dev만
Agent(subagent_type="architect", name="dev-lead", description="Dev Team Lead",
      team_name="teamwork-{feature}", model="opus",
      prompt="Team Coordinator를 통해 멀티팀 워크플로우를 실행하세요.
      프로젝트: {작업 설명}
      복잡도: {score}/10
      투입 팀: Dev")

# score 6-7: + Quality 추가
Agent(subagent_type="qa-tester", name="quality-lead", description="Quality Team Lead",
      team_name="teamwork-{feature}", model="sonnet",
      prompt="Quality Team으로 품질 검증을 수행하세요.")

# score 8-9: + Research 추가
Agent(subagent_type="researcher", name="research-lead", description="Research Team Lead",
      team_name="teamwork-{feature}", model="sonnet",
      prompt="Research Team으로 리서치를 수행하세요.")

# 팀 간 조율
SendMessage(to="dev-lead", summary="리서치 결과 전달", message="...")
SendMessage(to="quality-lead", summary="구현 결과 검증", message="...")

# 완료 후 정리
SendMessage(to="dev-lead", message={type: "shutdown_request"})
SendMessage(to="quality-lead", message={type: "shutdown_request"})
SendMessage(to="research-lead", message={type: "shutdown_request"})
TeamDelete()
```

**인과관계 보존**: Team Coordinator는 Tier 3 WORK의 하위에서 동작합니다. 기존 Tier 0-5 Discovery는 그대로 유지.

4. **Architect 검증** (완료 전 필수):
   ```
   Agent(
     subagent_type="architect",
     name="final-verifier",
     description="구현 완료 검증",
     team_name="auto-{feature}",
     model="opus",
     prompt="구현 완료 검증: [작업 설명]"
   )

   SendMessage(to="final-verifier", message={type: "shutdown_request"})
   ```

5. **완료 조건**:
   - Architect 승인 받음
   - 모든 TODO 완료
   - 빌드/테스트 통과 확인 (fresh evidence)

### Phase 3: 자율 발견 모드 (`/auto` 단독 실행)

작업이 명시되지 않으면 5계층 발견 시스템 실행:

| Tier | 이름 | 발견 대상 | 실행 |
|:----:|------|----------|------|
| 0 | CONTEXT | context >= 90% | 체크포인트 생성 |
| 1 | EXPLICIT | 사용자 지시 | 해당 작업 실행 |
| 2 | URGENT | 빌드/테스트 실패 | `/debug` 실행 |
| 3 | WORK | pending TODO, 이슈 | 작업 처리 |
| 4 | SUPPORT | staged 파일, 린트 에러 | `/commit`, `/check` |
| 5 | AUTONOMOUS | 코드 품질 개선 | 리팩토링 제안 |

### Phase 4: /work --loop 통합 (장기 계획)

> **상태**: 설계 완료, 구현 예정 (2026-03 목표)

`/work --loop`의 자율 반복 기능을 `/auto --work`로 흡수합니다.

**통합 매핑:**

| 기존 | 신규 | 동작 |
|------|------|------|
| `/work --loop` | `/auto --work` | PDCA 없이 빠른 자율 반복 실행 |
| `/work "작업"` | `/work "작업"` | 단일 작업 실행 (변경 없음) |

**`/auto --work` 모드:**
- PDCA 문서화 생략 (빠른 실행)
- Ralplan 대신 단순 Planner 호출
- Ralph 루프 5개 조건 검증 유지
- Context 90% 임계값 관리 유지

**마이그레이션:**
1. `/work --loop` 사용 시 `/auto --work`로 자동 redirect
2. 기존 /work 커맨드는 단일 작업 실행으로 역할 유지
3. `.claude/rules/08-skill-routing.md` 인과관계 그래프 업데이트

## 세션 관리

```bash
/auto status    # 현재 상태 확인
/auto stop      # 중지 (상태 저장)
/auto resume    # 재개
```

## 금지 사항

- ❌ 옵션 실패 시 조용히 스킵
- ❌ Architect 검증 없이 완료 선언
- ❌ 증거 없이 "완료됨" 주장
- ❌ 테스트 삭제로 문제 해결
- ❌ team_name 없이 실행형 Agent 호출
- ❌ Task() 또는 Skill(oh-my-claudecode:...) 사용

## 상세 워크플로우

추가 세부사항: `.claude/commands/auto.md`

## 변경 이력

### v18.0.0 (Agent Teams 전환)

| 기능 | 설명 | 활성화 |
|------|------|:------:|
| **Agent Teams 전면 전환** | 모든 Task()/Skill(OMC) 호출을 TeamCreate/Agent/SendMessage 패턴으로 교체 | ✅ |
| **OMC 의존 제거** | omc_delegate, omc_agents, bkit_agents YAML 제거 | ✅ |
| **로컬 에이전트 매핑** | oh-my-claudecode:* → 로컬 에이전트 타입으로 전환 | ✅ |
| **팀 라이프사이클 명시** | TeamCreate → Agent → SendMessage(shutdown) → TeamDelete | ✅ |

### v17.0.0 (daily v3.0 - 9-Phase Pipeline)

| 기능 | 설명 | 활성화 |
|------|------|:------:|
| **daily v3.0 통합** | 9-Phase Pipeline으로 --daily 전면 재설계 | ✅ |
| **Secretary 의존 제거** | Gmail/Slack/GitHub 직접 수집으로 교체 | ✅ |
| **Project Context Discovery 내부화** | Config Bootstrap이 daily v3.0 Phase 0으로 이전 | ✅ |

### v16.2.0 (Act Phase 자동 실행)

| 기능 | 설명 | 활성화 |
|------|------|:------:|
| **Act 자동 실행** | "Recommended" 출력 금지, 즉시 자동 실행 | ✅ 필수 |
| **완료 보고서 자동** | gap >= 90% 시 writer 자동 호출 | ✅ 기본 |
