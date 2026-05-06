---
name: chapter-doc
description: 인간이 읽는 기획 문서 작성 (Reader Panel 강화 모드). /auto chapter-doc + 사후 독후감 평가 강화. 5 audience 패널이 처음부터 끝까지 read 후 critic mode 독후감 작성하여 작위 침투 / 정체성 변질 / 인지 부담 사전 차단. 직전 사고 (무인화 7곳 작위 삽입) 면역 시스템.
version: 1.0.0
team_pattern: true
agents:
  - planner
  - writer
  - reader-panel
  - doc-critic
  - architect
  - content-critic
  - document-specialist
triggers:
  keywords:
    - "/chapter-doc"
    - "chapter-doc"
model_preference: opus
---

# /chapter-doc — 인간이 읽는 기획 문서 (Reader Panel 강화)

## 목적

`/auto` 의 chapter-doc 워크플로우 + **Reader Panel 강화 모드** 추가.
직전 사고 (Foundation v3.1 무인화 7곳 작위 침투) 같은 **"작가는 만족하지만 독자는 불편한" 문서를 사전 차단**.

## 직전 사고 검증

| 사고 위치 (Foundation v3.1) | 가상 독자 반응 | doc-critic 잡았나? | Reader Panel 잡았나? |
|----------------------------|--------------|:------:|:------:|
| §1.4 마지막 단락 작위 framing | "왜 미래 얘기가 갑자기?" | ❌ (단락 PASS) | ✅ (정체성 위반) |
| §1.6 미션 챕터 정체성 변질 | "미션 챕터인데 진화 로드맵?" | ❌ (단락 PASS) | ✅ (정체성 위반) |
| §7.3 Vision Layer 통째 80줄 | "Ch.7 = 현재인데 왜 미래?" | ❌ (단락 PASS) | ✅ (정체성 위반) |

→ 단락 단위 검증 (doc-critic) 으로는 못 잡는 **macro level 작위** 를 잡는 시스템.

## 사용법

```
/chapter-doc <문서 작성 요청>          # 작성 + Reader Panel 평가 (default)
/chapter-doc <기존 파일> --review-only # 기존 문서를 Reader Panel 평가만
/chapter-doc <요청> --no-panel         # Reader Panel 스킵 (글로벌 chapter-doc 만)
```

## 적용 범위 (HARD ENFORCE)

| 문서 종류 | 본 skill 적용 | 이유 |
|----------|:----:|------|
| `tier=external` PRD (외부 인계) | ✅ 강제 | 외부 stakeholder 가 read |
| 200줄+ 기획/Plan/Report | ✅ 권장 | macro 작위 위험 ↑ |
| `tier=internal` 200줄+ | ⭐ 선택 | 내부 SSOT 도 인간 read |
| `tier=internal` 100줄 이하 | ❌ 스킵 | 비용 vs 가치 부적합 |
| backlog / changelog / generated | ❌ 스킵 | 자동 생성 영역 |
| LLM_ONLY (.spec.json) | ❌ 스킵 | 인간이 읽는 문서 아님 |

## 워크플로우 (글로벌 chapter-doc + Phase 3.5 신설)

```
[글로벌 chapter-doc 워크플로우 (보존)]
  Phase -2  Triage
  Phase -1  기존 docs 스캔
  Phase  0  종류 + subtype 결정
  Phase 0.5 RVP 정의 (audience / cost / thesis5 / questions5)
  Phase  1  본문 작성 (planner / writer / Multi-perspective Validation)
            ├ critic (doc-critic, micro)
            ├ content-critic (챕터별 ★)
            ├ architect
            ├ document-specialist
            └ spec-validator (PAIR/LLM_ONLY)
            ↓ ALL APPROVE
  ─────────────────────────────────────────────
  Phase 3.5 NEW — Reader Panel (macro 평가)
            ├ Reader-Primary (audience-target 매칭)
            │   ├ 처음부터 끝까지 read
            │   ├ 5 객관 지표 평가
            │   ├ 사후 독후감 (감상문 narrative)
            │   └ Verdict: APPROVE/MINOR/MAJOR/REJECT
            ├ Reader-Secondary (보조 audience, 18세 일반인 default)
            │   └ 동일 평가
            └ Aggregator (다수결)
                ├ 2 APPROVE → Phase 4
                ├ 1 MINOR → 자율 minor edit + Phase 4
                ├ 1 MAJOR → Phase 1 재진입 (max 3 iter)
                └ 1 REJECT → 사용자 escalation
  ─────────────────────────────────────────────
  Phase 4   저장 + 커밋 + Confluence sync + PR
  Phase Cleanup  사례 등록 + 인덱스 동기화
```

상세: `references/reader-panel-workflow.md`

## Reader Agent 정의

### Primary Reader (audience-target 자동 매칭)

frontmatter `audience-target` 필드 기반 자동 선택:

| audience-target | Primary Reader 페르소나 |
|-----------------|----------------------|
| 외부 개발팀 | 신규 합류 시니어 개발자 (도메인 경험 X) |
| 경영진 | CFO/CEO 비전공 |
| PM | 다른 프로덕트 PM |
| 18세 일반인 | doc-critic 페르소나 |
| 운영자/Operator | 카지노 현장 스태프 |

### Secondary Reader (default = 18세 일반인)

모든 문서에 보조 평가자 추가. Primary 와 다른 시점에서 검증.

상세: `references/reader-agent-personas.md`

## 평가 지표 (5종 객관 지표)

| 지표 | 측정 방법 | PASS 기준 |
|------|---------|----------|
| **recall** | 문서 read 직후 핵심 thesis 5 회상 | 4/5 이상 |
| **ambiguity** | 모호 지점 식별 (목록) | 5 항목 이하 |
| **cognitive** | 5 챕터 연속 산문 / 인지 부담 | 4/5 이상 |
| **identity** | 각 챕터 메시지 ↔ 챕터 정체성 매칭 | 5/5 (위반 0) |
| **artifice** | 작위적 삽입 식별 (목록) | 0 항목 |

상세: `references/evaluation-schema.md`

## Verdict 룰 (3-tier + REJECT)

| Verdict | 조건 | 후속 |
|---------|------|------|
| **APPROVE** | 5 지표 모두 PASS | Phase 4 진입 |
| **MINOR** | 1 ~ 2 지표 약한 FAIL (수정 가능) | 자율 minor edit + Phase 4 |
| **MAJOR** | 3+ 지표 FAIL 또는 identity/artifice 위반 | Phase 1 재진입 (max 3) |
| **REJECT** | 5 지표 모두 FAIL 또는 회복 불가 | 사용자 escalation |

## Circuit Breaker (CLAUDE.md Iron Law 4 정합)

| 상황 | 대응 |
|------|------|
| MAJOR iteration 3회 도달 | 사용자 escalation (강제) |
| 같은 챕터 MAJOR 3회 반복 | 사용자 escalation (강제) |
| Reader-Primary REJECT | 즉시 사용자 escalation |
| Reader 평가 자체 실패 (timeout) | Phase 4 그대로 진입 + 경고 |

## 기존 도구와의 분담

| 계층 | 도구 | 역할 |
|:---:|------|------|
| L1 자가 점검 | 룰 19 P7 (10항목) | 형식/구조 (작가 본인) |
| L2 micro 평가 | doc-critic skill | 단락별 이해도 (18세 일반인) |
| L2 챕터 평가 | content-critic agent | 챕터별 ★ + 강/약 문장 인용 |
| **L3 macro 평가** | **본 skill (Reader Panel)** | **전체 문서 narrative + 작위/정체성** |
| L4 사용자 검증 | 사용자 review | MAJOR/REJECT escalation 시만 |

→ doc-critic = micro, Reader Panel = macro. **보완적 (대체 X)**.

## CLAUDE.md Core Philosophy 정합

| 원칙 | 본 skill 정합 방식 |
|------|------------------|
| 사용자 진입점 최소화 | `/chapter-doc` 명시 호출 자체가 사용자 의도 표명 → 그 외 모든 단계 자율 |
| A/B/C 옵션 나열 금지 | Verdict 자동 판정 + 자율 iteration |
| 자율 iteration 최대화 | max 3 iter 안에서 자율, REJECT 만 escalation |
| 결과만 보고 | iteration 진행 사일런트, 최종 결과만 사용자 보고 |

## 비용 통제

- Primary + Secondary = 2 agent × 1 call = **+2 LLM call** per 문서
- max 3 iter = 최악의 경우 **+6 LLM call**
- 적용 범위 한정 (tier=external 또는 200줄+) → 월 ~30 호출 이내

## 출력 형식

### 성공 시 (APPROVE)

```
✅ Reader Panel APPROVE — {파일}

Primary Reader ({audience}): APPROVE
  recall: 5/5 / ambiguity: 0 / cognitive: 5/5 / identity: 5/5 / artifice: 0
  독후감: "{1줄 요약}"

Secondary Reader (18세 일반인): APPROVE
  ...

→ Phase 4 진행 (저장 + 커밋 + Confluence sync)
```

### 실패 시 (MAJOR/REJECT)

```
⚠️ Reader Panel MAJOR — {파일}

Primary Reader: MAJOR
  identity 위반 2건:
    - §X.Y "{인용}" — 챕터 정체성과 충돌
  artifice 위반 1건:
    - §X.Z "{인용}" — 작위적 삽입 의심
  독후감: "{문제 단락}"

→ writer 재호출 (iteration {N}/3)
```

### REJECT 시

```
❌ Reader Panel REJECT — {파일}

iter 3/3 도달. 사용자 결정 필요:
  Path A: 본 plan으로 진행 강행
  Path B: 다른 audience 로 재평가
  Path C: 작업 보류
```

## 관련 룰

- `19-feature-block-document.md` (P7 Reader Experience Standard)
- `13-requirements-prd.md` (PRD subtype)
- `12-large-document-protocol.md` (대형 문서 청킹)
- `20-doc-discovery-pre-work.md` (변경 영향 추적)

## 참조

- `references/reader-panel-workflow.md` — Phase 3.5 상세 워크플로우
- `references/reader-agent-personas.md` — 5 audience 페르소나 정의
- `references/evaluation-schema.md` — 5 지표 + verdict 판정 룰
- 글로벌 chapter-doc: `C:/claude/plugins/aiden-auto/skills/auto/references/chapter-doc.md`
- doc-critic skill: `.claude/skills/doc-critic/SKILL.md`

## 직전 사고 SSOT (영구 학습)

직전 사고 (Foundation v3.1, 2026-05-06):
- 무인화 7 곳 작위 침투 (§1.4, §1.6×2, §5.4, §7.3, §9.1, §9.2, §9.3)
- 룰 19 P7 자가 점검 10/10 통과시켰는데도 사고
- 사용자 critic 으로만 발견됨

→ 본 skill 의 정당화 근거. Reader Panel 이 있었다면 §1.4/§1.6/§7.3 의 정체성 위반 3 건 자동 차단.

사례: `~/.claude/projects/C--claude-ebs/memory/case_studies/2026-05-06_foundation_uninhabited_artifact.md` (등록 예정)
