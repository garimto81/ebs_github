# Reader Panel Workflow — Phase 3.5 상세

> 본 문서는 `/chapter-doc` SKILL.md 의 Phase 3.5 (Reader Panel) 상세 워크플로우 정의.

## Phase 3.5 진입 조건

글로벌 chapter-doc Phase 1.3 (Multi-perspective Validation) ALL APPROVE 직후 자동 진입.

```
Phase 1.3 (validation) ALL APPROVE
   ↓
Phase 3.5 (Reader Panel) ← 본 단계
   ↓
Phase 4 (저장 + 커밋)
```

## 단계별 흐름

### Step 3.5.1 — Audience 자동 매칭

target 문서의 frontmatter `audience-target` 필드 기반 Primary Reader 자동 선택.

```python
# 의사코드
audience = frontmatter["audience-target"]
primary_persona = persona_map[audience]  # references/reader-agent-personas.md
secondary_persona = persona_map["18세 일반인"]  # 항상 secondary
```

`audience-target` 필드 누락 시:
- tier=external → "외부 개발팀" default
- tier=internal → "PM" default
- 그 외 → "18세 일반인" 단일 (Secondary 만)

### Step 3.5.2 — Reader Agent 병렬 호출

```
Agent Teams 패턴:

TeamCreate(team_name="reader-panel-{slug}")

Agent(
  subagent_type="general-purpose",  # Reader 페르소나 주입은 prompt로
  name="reader-primary",
  description="Primary Reader 사후 독후감 평가",
  team_name="reader-panel-{slug}",
  model="opus",
  prompt="""
  당신은 {primary_persona} 입니다.

  배경: {persona_background}
  관심사: {persona_interests}

  아래 문서를 처음부터 끝까지 read 한 후, 사후 독후감을 작성하세요.

  [문서 경로]: {filepath}
  [문서 RVP]:
    audience: {rvp.audience}
    cost_of_not_reading: {rvp.cost}
    key_thesis_5: {rvp.thesis}

  ## 평가 절차

  1. 문서 전체 read (Read tool 사용)
  2. 5 객관 지표 평가:
     - recall: 문서 read 직후 핵심 thesis 5개 회상 가능? (n/5)
     - ambiguity: 모호 지점 식별 (정확한 위치 + 인용)
     - cognitive: 5 챕터 연속 산문 발견? 인지 부담 점수 (n/5)
     - identity: 각 챕터 메시지 ↔ 챕터 정체성 매칭 (n/5)
     - artifice: 작위적 삽입 식별 (정확한 위치 + 인용)
  3. 사후 독후감 작성 (5-10줄 narrative):
     - 어디서 멈추고 싶었는가?
     - 어디서 어색했는가?
     - 어디서 작위적 느낌을 받았는가?
     - 끝까지 readable 했는가?
  4. Verdict 판정:
     - APPROVE / MINOR / MAJOR / REJECT
     - 판정 사유 1줄

  출력 형식: references/evaluation-schema.md 참조 (JSON)
  """
)

Agent(
  subagent_type="general-purpose",
  name="reader-secondary",
  description="Secondary Reader 사후 독후감 평가",
  team_name="reader-panel-{slug}",
  model="opus",
  prompt="""
  (위와 동일하되 secondary_persona 주입)
  """
)
```

→ Primary + Secondary 병렬 평가 (2 agent 동시)

### Step 3.5.3 — Aggregator (다수결 + 가중)

```python
# 의사코드
def aggregate(primary_verdict, secondary_verdict):
    verdicts = [primary_verdict, secondary_verdict]

    # 1. REJECT 우선 (즉시 escalation)
    if "REJECT" in verdicts:
        return ("REJECT", "사용자 escalation 필수")

    # 2. 둘 다 APPROVE → APPROVE
    if all(v == "APPROVE" for v in verdicts):
        return ("APPROVE", "Phase 4 진행")

    # 3. 하나라도 MAJOR → MAJOR
    if "MAJOR" in verdicts:
        return ("MAJOR", "writer 재호출 (max 3 iter)")

    # 4. 하나라도 MINOR → MINOR
    if "MINOR" in verdicts:
        return ("MINOR", "자율 minor edit + Phase 4")

    return ("APPROVE", "default")
```

**가중 룰** (옵션):
- Primary verdict 가 Secondary 보다 가중치 ↑ (1.5x)
- 단, identity / artifice 위반은 가중치 무관 즉시 MAJOR

### Step 3.5.4 — Verdict 별 후속 처리

#### APPROVE
```
ReadingPanel APPROVE 보고 출력 → Phase 4 진입
```

#### MINOR (자율 처리)
```
1. MINOR 항목 추출 (예: ambiguity 1-2 항목, cognitive 1점 부족)
2. writer 재호출 (해당 챕터/단락만):
   Agent(
     subagent_type="general-purpose",
     name="writer-minor-fix",
     prompt="""
     아래 MINOR 항목만 수정하세요. 다른 부분 변경 금지.
     [MINOR 항목]: {minor_items}
     [개선 지시]: {minor_instructions}
     Edit tool로 직접 수정.
     """
   )
3. 재평가 없이 Phase 4 진입 (MINOR 는 재평가 스킵)
```

#### MAJOR (재 iteration)
```
1. MAJOR 항목 추출 (identity / artifice / 다수 지표 FAIL)
2. iteration counter +1
3. iteration > 3 → 강제 REJECT 처리 (Circuit Breaker)
4. writer 재호출 (전체 챕터 재작성):
   Agent(
     subagent_type="general-purpose",
     name="writer-major-fix",
     prompt="""
     아래 MAJOR 항목을 해소하기 위해 챕터를 재작성하세요.
     [MAJOR 항목]: {major_items}
     [Reader 독후감]: {primary_critique}
     [개선 plan]: {improvement_plan}
     """
   )
5. Phase 1.3 재진입 (validation 재 실행)
6. Phase 3.5 재진입 (Reader Panel 재 평가)
```

#### REJECT (사용자 escalation)
```
1. REJECT 보고 출력
2. Reader 독후감 전체 출력 (Primary + Secondary)
3. iteration history 출력 (몇 번 재시도 했는지)
4. 사용자 결정 요청:
   Path A: 본 plan 강행 (Phase 4 진행)
   Path B: 다른 audience 로 재평가
   Path C: 작업 보류
```

## State File

```json
// .claude/state/auto/doc-{slug}.json (기존 + 확장)

{
  "subtype": "PAIR",
  "rvp": { ... },
  "reader_panel": {
    "iteration": 1,
    "max_iteration": 3,
    "primary_audience": "외부 개발팀",
    "secondary_audience": "18세 일반인",
    "history": [
      {
        "iter": 1,
        "primary": { "verdict": "MAJOR", "scores": {...}, "critique": "..." },
        "secondary": { "verdict": "MINOR", "scores": {...}, "critique": "..." },
        "aggregated": "MAJOR",
        "action": "writer-major-fix"
      }
    ],
    "final_verdict": null
  }
}
```

## 비용 추적

| 단계 | LLM call |
|------|:--------:|
| Step 3.5.2 Primary | 1 |
| Step 3.5.2 Secondary | 1 |
| Step 3.5.4 MINOR fix (조건부) | +1 |
| Step 3.5.4 MAJOR fix + 재평가 | +3 (writer + Primary + Secondary) |
| **최악 case** (3 iter MAJOR) | **+11** |
| **평균 case** (1 iter APPROVE) | **+2** |

## 적용 제외 (HARD SKIP)

다음 경우 Phase 3.5 자동 스킵:
- 문서 줄수 < 100 (소형)
- subtype = LLM_ONLY (.spec.json — 인간이 읽는 문서 아님)
- frontmatter `reader-panel: false` 명시
- `--no-panel` 플래그
- backlog / changelog / generated 영역
- !quick / !hotfix magic word

## 참조

- 페르소나 정의: `reader-agent-personas.md`
- 평가 schema: `evaluation-schema.md`
- SKILL.md: `../SKILL.md`
- 글로벌 chapter-doc: `C:/claude/plugins/aiden-auto/skills/auto/references/chapter-doc.md`
