---
name: auto
description: >
  This skill should be used when the user requests automated PDCA workflows, autopilot execution, or multi-phase build-verify-close cycles.
version: 23.0.0
triggers:
  keywords:
    - "/auto"
    - "auto"
    - "autopilot"
    - "/work"
    - "자동화"
    - "자동 실행"
auto_trigger: true
---

# /auto - PDCA Orchestrator (v25.0 — OOP Coupling/Cohesion)

> **핵심**: `/auto "작업"` = Phase 0-4 자동 진행. `/auto` 단독 = 자율 발견 모드. `/work`는 `/auto`로 통합됨.
> **Agent Teams 단일 패턴**: TeamCreate → Agent(subagent_type+name+description+team_name) → SendMessage → TeamDelete. Skill() 호출 0개.
> **Plugin Fusion (v24.0)**: 프로젝트 타입 자동 감지 → 플러그인 활성화 → Phase별 스킬 주입. 추가 옵션 불필요.
> **OOP Quality (v25.0)**: Contract-Based Phase Interface + ContextProvider DI + OOP Design Quality Gate + Unified Verification + D0-D4 책임 분리.
> **코드 블록/상세 prompt**: `REFERENCE.md` 참조. 이 파일은 판단 로직과 흐름만 기술.

---

## Phase 0→4 실행 흐름

```
  Phase 0        Phase 1           Phase 2            Phase 3          Phase 4
  INIT    ──→    PLAN       ──→    BUILD       ──→    VERIFY    ──→    CLOSE
  옵션 파싱       PRD 생성         구현 실행           QA 사이클        보고서
  팀 생성         사전 분석         코드 리뷰           E2E 검증         팀 정리
  복잡도 판단     계획+설계 수립    Architect Gate      최종 판정         커밋
  플러그인 감지
```

---

## Contract-Based Phase Interface (v25.0)

Phase 간 자료 결합도(1단계)를 보장하기 위해 표준화된 Contract를 사용합니다. 각 Contract는 다음 Phase가 필요로 하는 **최소 원시 데이터**만 포함합니다.

```
  Phase 0         Phase 1          Phase 2          Phase 3          Phase 4
  INIT     ─────> PLAN     ─────> BUILD     ─────> VERIFY    ─────> CLOSE
     |               |               |               |               |
     v               v               v               v               v
  InitContract   PlanContract    BuildContract   VerifyContract  (보고서)
```

| Contract | 핵심 필드 | 역할 |
|----------|----------|------|
| **InitContract** | feature, mode, complexity_score, plugins[], iron_laws, options, team_name | Phase 0 결정 사항 구조화 |
| **PlanContract** | prd_path, plan_path, requirements[], affected_files[], acceptance_criteria[] | Plan 내부 구조 대신 추출된 데이터 전달 |
| **BuildContract** | changed_files[], test_results, build_status, lint_status, gap_match_rate, review_verdict | 구현 결과 요약 |
| **VerifyContract** | qa_cycles, qa_final_status, e2e_status, architect_final_verdict, unresolved_issues[] | 검증 결과 요약 |

> Contract JSON 스키마 상세: `REFERENCE.md` Contract Definitions 섹션 참조.

---

## Phase 0: INIT (옵션 + 팀 + 복잡도)

### 옵션

#### 흐름 제어 옵션

| 옵션 | 효과 |
|------|------|
| `--skip-prd` | Phase 1 PRD 스킵 |
| `--skip-analysis` | Phase 1 사전 분석 스킵 |
| `--no-issue` | 이슈 연동 스킵 |
| `--strict` | E2E 1회 실패 즉시 중단 |
| `--skip-e2e` | E2E 검증 전체 스킵 |
| `--dry-run` | 판단만 출력 (Phase 0-1까지만 실행) |
| `--eco` | 비용 절감: Opus→Sonnet (~30%) |
| `--eco-2` | 중간 절감: Opus→Sonnet + 비핵심 Sonnet→Haiku (~50%) |
| `--eco-3` | 최대 절감: Opus→Sonnet + 전체 Sonnet→Haiku (~70%, 프로토타이핑 전용) |
| `--worktree` | feature worktree에서 작업 |
| `--interactive` | Phase 전환 시 사용자 확인 |

#### 실행 옵션 (Step 2.0 처리)

| 옵션 | 효과 |
|------|------|
| `--mockup [파일]` | 3-Tier 목업 생성. 상세: mockup-hybrid SKILL.md, REFERENCE.md Step 2.0 |
| `--mockup-q` | Quasar White Tone Minimal 목업 생성. 상세: mockup-hybrid SKILL.md |
| `--gdocs` | Google Docs PRD 동기화 |
| `--critic` | 약점/문제점 분석 → 웹 리서치 → 최선 솔루션 제안 |
| `--debate` | 3-AI 병렬 분석 합의 |
| `--research` | 코드베이스/외부 리서치 |
| `--daily` | 일일 대시보드 (9-Phase Pipeline) |
| `--slack <채널>` | Slack 채널 분석 |
| `--gmail` | Gmail 분석 |
| `--con <page_id> [파일]` | Confluence 발행. 상세: confluence SKILL.md, REFERENCE.md `--con` 섹션 |
| `--jira <cmd> <target>` | Jira 조회/분석. 상세: jira SKILL.md, REFERENCE.md `--jira` 섹션 |
| `--figma <url> [connect\|rules\|capture\|auth]` | Figma 디자인 연동. 상세: figma SKILL.md |
| `--anno [파일]` | Screenshot→HTML→Annotation 워크플로우. 상세: REFERENCE.md Step 2.0 |

### 팀 생성 (MANDATORY)

`TeamCreate(team_name="pdca-{feature}")`. 실패 시 `TeamDelete()` → 재시도 1회. 재실패 시 중단.

> 커스텀 에이전트 미인식 시 Fallback 매핑: `REFERENCE.md` 에이전트 Fallback 매핑 섹션 참조.

### 복잡도 판단 (6점 만점)

상세 채점 기준: `REFERENCE.md` (팩터 6: Appetite 선언 포함)

| 점수 | 모드 | 특성 |
|:----:|:----:|------|
| 0-1 | LIGHT | 단일 실행, QA 1회, 최소 검증 |
| 2-3 | STANDARD | 자체 루프, QA 3회, 이중 검증 |
| 4-6 | HEAVY | Planner-Critic, QA 5회, 전체 검증 |

### EscalationContract (자동 승격 정량화)

승격은 **Phase 경계에서만** 발생합니다. Phase 도중 모드 전환은 금지입니다.

| 조건 | 트리거 | 승격 |
|------|--------|------|
| `build_failures >= 2` | Phase 2 impl-manager 루프 내 | LIGHT → STANDARD |
| `affected_files >= 5` | Phase 0 초기 분석 시 | LIGHT → STANDARD 또는 HEAVY |
| `qa_cycles > 3` | Phase 3 QA 루프 내 | STANDARD → HEAVY |
| `architect_rejects >= 2` | Phase 2.3/3.2 | 승격 없음, 사용자 알림 |

### Phase 0.4: Plugin Activation Scan

프로젝트 루트 파일 감지 + 복잡도 모드 기반으로 플러그인을 자동 활성화한다. 상세 매핑: `references/plugin-fusion-rules.md`

**Project Type Detection:**

| 감지 파일 | 활성화 플러그인 |
|-----------|----------------|
| `package.json` + react dep | frontend-design, code-review, typescript-lsp |
| `package.json` + quasar dep | frontend-design, code-review, typescript-lsp |
| `tsconfig.json` | typescript-lsp, code-review |
| `next.config.*` | frontend-design, code-review |
| `pyproject.toml` \| `setup.py` | code-review |
| `.claude/` 존재 | claude-code-setup, superpowers |

**Complexity-Tier Escalation:**

| 모드 | 추가 활성 |
|------|----------|
| LIGHT (0-1) | typescript-lsp (TS 프로젝트 시) |
| STANDARD (2-3) | + code-review, superpowers (Iron Laws 주입) |
| HEAVY (4-6) | + feature-dev, claude-code-setup |

**Iron Laws (superpowers 흡수, 전 Phase 적용):**

| # | Iron Law | 적용 위치 |
|:-:|----------|----------|
| 1 | TDD: 실패 테스트 없이 프로덕션 코드 작성 금지 | Phase 2.1 impl-manager |
| 2 | Debugging: Root cause 조사 없이 수정 금지 | Phase 3.1 QA FAIL |
| 3 | Verification: 증거 없이 완료 선언 금지 | Phase 2.3, 3.3 Gate |

> 감지 코드 및 주입 prompt: `REFERENCE.md` Phase 0.4 섹션 참조.

### 커밋 정책

Phase 완료 후 `git status --short` 확인 → 변경사항 있으면 커밋.

| 트리거 | 커밋 메시지 패턴 |
|--------|----------------|
| Phase 2 Architect APPROVE | `feat({feature}): 구현 완료` |
| Phase 3 최종 검증 통과 | `fix({feature}): QA 수정사항 반영` |
| Phase 4 보고서 생성 | `docs(report): {feature} PDCA 완료 보고서` |
| 조기 종료 | `wip({feature}): 진행 중 변경사항 보존` |

---

## Phase 1: PLAN (PRD → 분석 → 계획+설계)

### Step 1.0: Requirement Gathering (STANDARD/HEAVY만)

LIGHT는 건너뛰고 Step 1.1로 직행.

1. 사용자 요청 의도 명확화 — 암묵적 요구사항 탐색
2. 기존 관련 문서 탐색 (docs/00-prd/, docs/01-plan/)
3. 관련 이슈/PR 탐색 (GitHub)
4. Appetite 결정: "이 작업에 얼마나 투자?" (Small 2주 / Big 6주)

산출물: Intent Analysis + Appetite 선언 → Step 1.1 PRD 생성에 반영

### Step 1.1: PRD (요구사항 문서화)

`--skip-prd`로 스킵 가능. 상세 prompt/템플릿: `REFERENCE.md`

1. `docs/00-prd/` 기존 PRD 탐색
2. prd-writer teammate (executor-high) → PRD 생성/수정
3. **사용자 승인** (AskUserQuestion, max 수정 3회)
4. 산출물: `docs/00-prd/{feature}.prd.md`

### Step 1.2: 사전 분석

`--skip-analysis`로 스킵 가능.

병렬 explore(haiku) x2: 문서 탐색 + 이슈 탐색. 결과 5줄 요약.
analyst(sonnet) x1: 사용자 요청 의도 심층 분석 (명시적/암묵적 요구, 범위 경계, 위험 시나리오).

### Step 1.3: 계획 수립 (Graduated Plan Review)

| 모드 | 실행 |
|------|------|
| LIGHT | planner + Lead Quality Gate |
| STANDARD | planner + Critic-Lite 단일 검토 |
| HEAVY | Planner-Critic Loop (max 5회) |

**Lead Quality Gate** (LIGHT): plan 파일 존재+내용 있음, 파일 경로 1개+ 언급. 미충족 시 1회 재요청.
**Critic-Lite** (STANDARD): Adversarial 약점 공격 1회 → DESTROYED/QUESTION/SURVIVED. DESTROYED 시 1회 수정. QUESTION 시 사용자 질문 후 수정.
**Planner-Critic Loop** (HEAVY): Planner → Architect 타당성 → Critic adversarial 공격 → 문서 재설계 → 반복 (max 5회). QUESTION 시 즉시 중단+사용자 질문. 5회 후 미통과 시 강제 진행 금지 — 사용자에게 보고하여 판단 요청 (요구사항 재정의 / 미해결 수용 / 작업 중단). 상세: `REFERENCE.md`

산출물: `docs/01-plan/{feature}.plan.md`

### Step 1.4: 설계 통합 + OOP Design Quality Gate (STANDARD/HEAVY만)

LIGHT는 스킵. STANDARD/HEAVY: 계획 문서에 **아키텍처 결정 섹션** 포함 (별도 design.md 불필요).
필수 포함 (7개):
1. 컴포넌트 구조 (기존)
2. 데이터 흐름 (기존)
3. 인터페이스 설계 (기존)
4. 위험 요소 (기존)
5. **[NEW] 결합도 분석** — 모듈 간 의존성 유형 명시 (목표: 자료/스탬프 결합도)
6. **[NEW] 응집도 분석** — 각 모듈의 응집도 유형 명시 (목표: 기능적/순차적 응집도)
7. **[NEW] SOLID 원칙 적용 점검** — SRP, DIP, ISP 위반 여부

**OOP Design Scorecard** (Plan→Build Gate에 포함):

| 항목 | 기준 | PASS | FAIL |
|------|------|:---:|:---:|
| 모듈 간 결합도 | 자료/스탬프 (1-2단계) | 모든 모듈 2단계 이하 | 3단계 이상 존재 |
| 모듈 내 응집도 | 기능적/순차적 (1-2단계) | 모든 모듈 2단계 이하 | 5단계 이상 존재 |
| SRP 준수 | 1모듈 = 1책임 | 각 모듈 책임 1개 | 다중 책임 모듈 존재 |
| DIP 준수 | 추상화 의존 | 구체 클래스 직접 의존 없음 | 구체 클래스 의존 |
| ISP 준수 | 필요한 인터페이스만 | 미사용 메서드 노출 없음 | Fat Interface 존재 |

**STANDARD/HEAVY**: Scorecard 전체 PASS 필수 (FAIL 시 planner 1회 재설계).
**LIGHT**: Scorecard 생략 가능 (단, 결합도 3단계 이상 경고).

> **Plan→Build Gate** (STANDARD/HEAVY): 4개 필수 섹션 확인 (배경, 구현 범위, 영향 파일, 위험 요소) + OOP Scorecard PASS. 미충족 시 planner 1회 보완.

### Step 1.5: 이슈 연동

`--no-issue`로 스킵. 없으면 생성, 있으면 코멘트.

---

## Phase 2: BUILD (구현 → 코드 리뷰 → Architect Gate)

> **핵심 변경 (v23.0)**: Code Review가 BUILD 내부에 통합. 구현 완료 즉시 리뷰 → 수정 → Architect 판정.

### Step 2.0: 옵션 처리 (구현 진입 전)

| 옵션 | 처리 | 옵션 | 처리 |
|------|------|------|------|
| `--gdocs` | prd-sync | `--slack <채널>` | Slack 분석 |
| `--mockup [파일]` | 3-Tier 목업 (Step 1-4) | `--gmail` | Gmail 분석 |
| `--critic` | 약점 분석 + 웹 솔루션 (3-Phase) | `--daily` | daily |
| `--debate` | ultimate-debate | `--research` | research |
| `--interactive` | Phase별 승인 | | |
| `--con <page_id>` | Confluence 발행 | `--jira <cmd> <target>` | Jira 조회/분석 |
| `--figma <url>` | Figma 구현 | `--figma connect <url>` | Figma 컴포넌트 매핑 |
| `--figma capture` | HTML→Figma 캡처 | `--figma auth` | Figma 인증 확인 |
| `--figma rules` | 디자인 시스템 규칙 | | |
| `--anno [파일]` | Anno 워크플로우 (5-Step) | `--anno` (전체) | 6장 일괄 처리 |

옵션 실패 시: 에러 출력, **절대 조용히 스킵 금지**. 상세: `REFERENCE.md`

#### `--mockup` 서브스텝 (4-Step)

| Step | 내용 | 실행 주체 |
|------|------|----------|
| 1 | MockupRouter.route() — 3-Tier 라우팅 + 기본 HTML 생성 | Lead (Python 호출) |
| 2 | HTML 선택 시 → designer(sonnet) 스폰 (B&W Refined Minimal 스타일링) | designer 에이전트 |
| 3 | Playwright PNG 캡처 | Lead (Bash) |
| 4 | 문서 임베드 (대상 문서 있을 때만) | Lead (Edit) |

#### `--anno` 서브스텝 (5-Step)

| Step | 내용 | 실행 주체 |
|------|------|----------|
| 1 | Vision AI(Claude) 스크린샷 분석 → UI 요소 목록 | Lead (직접) |
| 2 | designer(sonnet) 스폰 → 구조 중심 HTML 생성 (`data-element-*` 필수) | designer 에이전트 |
| 3 | Playwright 캡처 → 원본 비교 (시각 검증) | anno_workflow.py |
| 4 | `querySelectorAll('[data-element-id]')` → bbox JSON | anno_workflow.py |
| 5 | annotate_screenshot.py → annotated PNG | anno_workflow.py |

### Step 2.1: 구현

| 모드 | 실행 방식 |
|------|----------|
| LIGHT | executor-high — 단일 실행, TDD 필수 |
| STANDARD | impl-manager (executor-high) — 4조건 자체 루프 (max 10회) |
| HEAVY | impl-manager (executor-high) — 4조건 자체 루프 + 병렬 가능 |

**impl-manager 4조건** (STANDARD/HEAVY — 모든 조건 충족 시 IMPLEMENTATION_COMPLETED):

| # | 조건 | 검증 방법 |
|:-:|------|----------|
| 1 | TODO == 0 | plan.md 체크리스트 전체 완료 |
| 2 | 빌드 성공 | 빌드 명령 exit code 0 |
| 3 | 테스트 통과 | pytest/jest exit code 0 |
| 4 | 에러 == 0 | lint + type check 클린 |

> 코드 품질 리뷰 책임은 **code-reviewer 단독**으로 단일화 (v25.0 SRP 적용).

상세 impl-manager prompt: `REFERENCE.md`

### Step 2.2: Code Review (STANDARD/HEAVY 필수)

구현 완료 후 **즉시** code-reviewer 실행. Vercel BP 규칙 동적 주입 (React/Next.js 시).

**Hybrid Review** (code-review 플러그인 활성 시, STANDARD/HEAVY):
1. 내부 code-reviewer → APPROVE/REVISE 1차 판정
2. code-review 플러그인 5-agent 병렬 → 추가 이슈 수집 (CLAUDE.md Compliance, Shallow Bug Scan, Git Blame Context, PR Comment Patterns, Code Comment Compliance)
3. 두 결과 병합 → 최종 판정

| 판정 | 처리 |
|------|------|
| APPROVE | Step 2.3 Architect Gate 진입 |
| REVISE + 수정 목록 | executor로 수정 → code-reviewer 재검토 (max 2회) |

> LIGHT 모드: code-reviewer 스킵. Step 2.1 완료 후 바로 Phase 3 진입.

### Step 2.3: Architect Verification Gate + Gap Analysis (STANDARD/HEAVY 필수)

architect (READ-ONLY) → 구현이 Plan 요구사항과 일치하는지 외부 검증.
Architect APPROVE 후 gap-detector → 7개 항목 정량 비교 (Match Rate >= 90% 필수).

| VERDICT | 처리 |
|---------|------|
| APPROVE | Step 2.3b Gap Analysis → 커밋 → Phase 3 진입 |
| REJECT + DOMAIN | Step 2.4 Domain-Smart Fix |

2회 REJECT → 사용자 알림 후 Phase 3 진입 허용.

### Step 2.4: Domain-Smart Fix (Architect REJECT 시)

| DOMAIN | 에이전트 |
|--------|---------|
| UI, component, style | designer |
| build, compile, type | build-fixer |
| test, coverage | executor |
| security | security-reviewer |
| 기타 | executor |

수정 완료 → Step 2.3 Architect 재검증 (max 2회).

---

## Phase 3: VERIFY (QA → E2E → 최종 판정)

### Step 3.1: QA 사이클

| 모드 | QA 횟수 | 실패 시 |
|------|:-------:|---------|
| LIGHT | 1회 | 보고만 (STANDARD 승격 검토) |
| STANDARD | max 3회 | Systematic Debugging D0-D4 → Domain-Smart Fix → 재실행 |
| HEAVY | max 5회 | Systematic Debugging D0-D4 → Domain-Smart Fix → 재실행 |

QA Runner (sonnet): 6종 검증 (lint, type, unit, integration, build, security). 상세: `REFERENCE.md`

**QA FAIL 시 Systematic Debugging** (superpowers 흡수, Iron Law #2):
- D0: 증상 수집 → D1: 가설 수립 → D2: 가설 검증 → D3: Root Cause 확정 → D4: 수정+검증
- Root cause 조사 없이 수정 금지 (Architect 단순 진단 대체)

**4종 Exit Conditions:**

| 우선순위 | 조건 | 처리 |
|:--------:|------|------|
| 1 | Environment Error | 즉시 중단 + 환경 문제 보고 |
| 2 | Same Failure 3x | 조기 종료 + root cause 보고 |
| 3 | Max Cycles | 미해결 이슈 보고 |
| 4 | Goal Met | Step 3.2 진입 |

### Step 3.2: E2E 검증 (STANDARD/HEAVY + 프레임워크 존재 시)

`--skip-e2e`로 스킵. `playwright.config.*` / `cypress.config.*` / `vitest.config.*` 존재 시 활성.

e2e-runner (sonnet) 백그라운드 실행 → 결과 수집.
E2E_FAILED 시: Architect 진단 → Domain-Smart Fix → 재실행 (max 2회). `--strict`: 1회 실패 즉시 중단.

### Step 3.3: 최종 검증

architect (READ-ONLY) → Plan 대비 구현 일치 검증. APPROVE/REJECT 판정.

| 결과 | 처리 |
|------|------|
| APPROVE | 유의미 변경 커밋 → Phase 4 |
| REJECT (gap < 90%) | executor로 갭 수정 → Phase 3 재실행 |

### Step 3.4: TDD 커버리지

신규 코드 80% 이상, 전체 커버리지 감소 불가. 상세: `REFERENCE.md`

> **Phase 3↔4 루프 가드**: Phase 4→Phase 3 재진입 최대 3회. 초과 시 커밋 + 미해결 이슈 보고.

---

## Phase 4: CLOSE (보고서 + 팀 정리)

### Step 4.0: Deployment Readiness Check (STANDARD/HEAVY만)

LIGHT는 건너뛰고 Step 4.1로 직행.

- [ ] 환경별 배포 대상 확인 (dev/staging/production)
- [ ] Breaking changes 여부
- [ ] 롤백 계획
- [ ] 모니터링 포인트

산출물: 배포 체크리스트 (Step 4.1 보고서에 포함)

### Step 4.1: 보고서 생성

writer teammate → `docs/04-report/{feature}.report.md`. 티어: LIGHT=writer(haiku), STANDARD/HEAVY=executor-high(opus).

### Step 4.2: 커밋 + Safe Cleanup

1. 유의미 변경 커밋: `docs(report): {feature} PDCA 완료 보고서`
2. 모든 teammate `shutdown_request` 순차 전송 (응답 대기 max 5초)
3. `TeamDelete()` 실행
4. 실패 시 Python `shutil.rmtree()` fallback

> 세션 crash recovery: `session_init.py` hook이 고아 팀 자동 정리.

---

## 복잡도 기반 모드 분기

| Phase | LIGHT (0-1) | STANDARD (2-3) | HEAVY (4-6) |
|-------|:-----------:|:--------------:|:-----------:|
| **0 INIT** | TeamCreate | TeamCreate | TeamCreate |
| **1 PLAN** | PRD + planner 계획 | PRD + planner 계획 + Critic-Lite + 설계 통합 | PRD + Planner-Critic Loop + 설계 통합 |
| **2 BUILD** | executor 단일 (TDD) | impl-manager 4조건 + code-reviewer (OOP 체크) + Architect Gate (OOP Score) | impl-manager 4조건 + code-reviewer (OOP 체크) + Architect Gate (OOP Score) |
| **3 VERIFY** | QA 1회 + Architect | QA 3회 + E2E + Architect + 진단 루프 | QA 5회 + E2E + Architect + 진단 루프 |
| **4 CLOSE** | writer (haiku) | executor-high (opus) | executor-high (opus) |

## 자율 발견 모드 (`/auto` 단독)

Tier 0 CONTEXT → 1 EXPLICIT → 2 URGENT → 3 WORK → 4 SUPPORT → 5 AUTONOMOUS 순서. 상세: `REFERENCE.md`

## 세션 관리

`/auto status` (상태 확인) / `/auto stop` (중지+TeamDelete) / `/auto resume` (재개+TeamCreate). 상세: `REFERENCE.md`

> **완전 frozen 시**: 별도 PowerShell 창에서 `python C:\claude\.claude\scripts\emergency_stop.py` 실행.

## 금지 사항

- 옵션 실패 시 조용히 스킵
- Architect 검증 없이 완료 선언
- 증거 없이 "완료됨" 주장
- 테스트 삭제로 문제 해결
- TeamDelete 없이 세션 종료
- architect로 파일 생성 시도 (READ-ONLY)
- Skill() 호출 (Agent Teams 단일 패턴)
- Team-Lead가 `shutdown_response` 호출 (세션 종료됨)
- 코드 블록 상세/prompt는 `REFERENCE.md` 참조
