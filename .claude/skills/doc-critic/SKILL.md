---
name: doc-critic
description: 문서 품질 심층 검증 (18세 일반인 기준, critic 평가 + 자동 재설계)
version: 1.0.0
team_pattern: true
agents:
  - doc-critic
  - architect
triggers:
  keywords:
    - "/doc-critic"
    - "doc-critic"
    - "문서 검증"
    - "문서 비평"
model_preference: opus
---

# /doc-critic — 문서 품질 심층 검증

18세 일반인 기준으로 문서의 목차 구조와 단락별 이해도를 critic 평가하고, 실패 시 자동 재설계한다.

## 사용법

```
/doc-critic <파일경로>            # 검증 + FAIL 단락 자동 재작성 (기본)
/doc-critic <파일경로> --dry-run  # 검증 보고서만 (수정 안 함)
```

## 실행 흐름

```
Phase 1 → Phase 2 → Phase 3 → Phase 4

  [1 구조 분석]    문서 읽기, 단락 분리, 목차 추출
       |
  [2 목차 Critic]  맥락 흐름 검증, 비약 탐지
       |           FAIL → 재설계 → 재평가 (1회)
       |
  [3 단락 Critic]  각 단락 이해도 5점 평가
       |           FAIL → 재설계 → 재평가 (1회)
       |
  [4 보고서]       전체 평가 요약, 개선 전/후 비교
```

## Phase 1: 구조 분석 (Lead 직접 실행)

대상 문서를 읽고 기본 구조를 파악한다.

```
Step 1.1: 대상 파일 Read
Step 1.2: ## / ### 기준으로 섹션 분리
Step 1.3: 현재 목차 구조 추출 (섹션 제목 리스트)
Step 1.4: 기초 통계 측정
  - 전체 줄 수
  - 섹션 수
  - 시각 자료 수 (```mermaid, 표, 이미지 링크)
  - 평균 섹션 길이
```

## Phase 2: 목차 Critic (Agent Teams)

```
# Step 2.1: 팀 생성
TeamCreate(team_name="doc-critic-{filename}")

# Step 2.2: doc-critic 에이전트 — 목차 평가
Agent(
  subagent_type="doc-critic",
  name="toc-critic",
  description="목차 구조 비약 탐지 및 맥락 흐름 검증",
  team_name="doc-critic-{filename}",
  prompt="아래 문서의 목차를 18세 일반인 관점에서 평가하세요.

  [문서 경로]: {filepath}
  [현재 목차]:
  {toc_list}

  평가 항목:
  1. 맥락 연결성: 이전 섹션 → 다음 섹션 전환이 자연스러운가?
  2. 비약 탐지: 설명 없이 새 개념이 갑자기 등장하는가?
  3. 직관성: 목차만 읽어도 전체 흐름 예측 가능한가?
  4. 난이도 순서: 쉬운 것 → 어려운 것 순서인가?

  판정: 비약 0개 = PASS / 비약 1개+ = FAIL
  FAIL 시 재설계 권고안 필수 포함."
)

# Step 2.3: 결과 수신 + 종료
SendMessage(to="toc-critic", message={type: "shutdown_request"})
```

### 목차 FAIL 시 재설계 루프 (최대 1회)

```
IF toc_result == FAIL:
  # Step 2.4: 목차 재설계 (Lead 또는 general-purpose)
  권고안 기반으로 목차 재배치안 생성

  # Step 2.5: 재설계 목차 재평가
  Agent(
    subagent_type="doc-critic",
    name="toc-critic-retry",
    description="재설계 목차 재평가",
    team_name="doc-critic-{filename}",
    prompt="재설계된 목차를 동일 기준으로 재평가하세요.
    [재설계 목차]: {new_toc}
    동일 4개 항목 평가 + PASS/FAIL 판정."
  )
  SendMessage(to="toc-critic-retry", message={type: "shutdown_request"})
```

## Phase 3: 단락별 Critic (Agent Teams)

```
# Step 3.1: doc-critic 에이전트 — 전체 단락 평가
Agent(
  subagent_type="doc-critic",
  name="section-critic",
  description="단락별 이해도 심층 평가",
  team_name="doc-critic-{filename}",
  prompt="아래 문서의 각 단락을 18세 일반인 관점에서 평가하세요.

  [문서 경로]: {filepath}

  각 단락마다 4개 항목 평가:
  1. 이해도 (5점 척도, 4점 이상 = PASS, 3점 이하 = FAIL)
  2. 시각 비율 (300자+ 단락에 시각 자료 0개 = FAIL)
  3. 전문 용어 (설명 없는 전문 용어 1개+ = FAIL)
  4. 문장 길이 (평균 40자 초과 = FAIL)

  FAIL 단락에는 반드시 구체적 개선 지시 포함:
  - 어떤 용어를 어떻게 풀어써야 하는지
  - 어떤 시각 자료를 추가해야 하는지
  - 어떤 문장을 어떻게 분리해야 하는지"
)

# Step 3.2: 결과 수신
SendMessage(to="section-critic", message={type: "shutdown_request"})
```

### 단락 FAIL 시 재설계 루프 (최대 1회)

```
IF fail_sections exist:
  # Step 3.3: FAIL 단락 재작성 (general-purpose 에이전트)
  Agent(
    subagent_type="general-purpose",
    name="doc-rewriter",
    description="FAIL 단락 재작성",
    team_name="doc-critic-{filename}",
    model="sonnet",
    prompt="아래 단락들을 개선 지시에 따라 재작성하세요.

    기준: 18세 일반인이 사전 지식 없이 이해할 수 있어야 함.

    원칙:
    - 전문 용어는 반드시 쉬운 말로 풀어쓰기
    - 긴 문장은 2개로 분리
    - 300자 이상 단락에는 표 또는 다이어그램 추가
    - 추상적 설명 대신 구체적 예시 사용

    [FAIL 단락 목록 + 개선 지시]:
    {fail_sections_with_instructions}

    각 단락을 Edit tool로 원본 파일에 직접 수정하세요.
    파일 경로: {filepath}"
  )
  SendMessage(to="doc-rewriter", message={type: "shutdown_request"})

  # Step 3.4: 재작성 결과 재평가
  Agent(
    subagent_type="doc-critic",
    name="section-critic-retry",
    description="재작성 단락 재평가",
    team_name="doc-critic-{filename}",
    prompt="재작성된 단락들을 동일 기준으로 재평가하세요.
    [파일 경로]: {filepath}
    [재작성 섹션]: {rewritten_sections}
    동일 4개 항목 평가 + PASS/FAIL 판정."
  )
  SendMessage(to="section-critic-retry", message={type: "shutdown_request"})
```

## Phase 4: 최종 보고서 (Lead 직접 출력)

```
# Step 4.1: 전체 평가 요약 테이블 출력 (터미널)

  +-----+----------------+--------+------+------+------+------+
  | #   | 섹션명         | 이해도 | 시각 | 용어 | 문장 | 종합 |
  +-----+----------------+--------+------+------+------+------+
  | 1   | 개요           | 5/5    | PASS | PASS | PASS | PASS |
  | 2   | 아키텍처       | 2/5    | FAIL | FAIL | FAIL | FAIL |
  +-----+----------------+--------+------+------+------+------+

# Step 4.2: 개선 전/후 비교 출력
# Step 4.3: 잔여 이슈 목록 (2차 평가에서도 FAIL인 항목)
# Step 4.4: 팀 정리
TeamDelete()
```

## 옵션 정리

| 옵션 | 동작 | 기본값 |
|------|------|:------:|
| (없음) | 검증 + FAIL 단락 자동 재작성 + 재평가 | ✅ |
| `--dry-run` | 검증 보고서만 출력, 파일 수정 안 함 | - |

## 제약 사항

- 재설계 루프는 목차/단락 각각 최대 1회 (무한 루프 방지)
- doc-critic 에이전트는 READ-ONLY (분석만, 수정 금지)
- 재작성은 general-purpose 에이전트가 수행
- `--dry-run` 시에만 재작성 스킵 (보고서만 출력)
- 문서 파일이 존재하지 않으면 에러 출력 후 종료
