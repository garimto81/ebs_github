# Workflow B — Spec-first 5-step

**트리거**: 신규 기능 / 변경 인텐트 OR 기획 공백 감지 OR 사용자 인텐트 변경 (SG-* 결정).

## 5 단계 흐름

```
[Trigger: 신규 인텐트 OR 기획 공백 감지]
  ↓
1. 인텐트 → spec 작성
   Team: iteration-spec-author + iteration-spec-classifier
   Output: docs/ 신규 file (frontmatter + tier + audience)
  ↓
2. 재구현성 검증
   Team: iteration-spec-validator + iteration-spec-coherence
   Output: reimplementability score (≥ 0.9 PASS)
  ↓
3. PASS? → 프로토타입 가능성 검토
   Team: iteration-prototype-validator
   Output: feasibility (구현 가능 / 부분 가능 / 불가능)
  ↓
4. 가능 → Impl-first 7-step cycle 진입 (Step 1)
   부분 가능 → 기획 정정 → Step 2 재검증
   불가능 → 사용자 escalation (자율 한계, 명시 필요)
  ↓
5. 결정 archive
   Team: iteration-decision-archivist
   Output: 사용자 결정 (B-Q*, SG-*) 영구 기록
```

## 단계별 상세

### Step 1 — 인텐트 → spec 작성

| 항목 | 값 |
|------|-----|
| 팀 | iteration-spec-author + iteration-spec-classifier |
| 입력 | 사용자 인텐트 (자연어) OR 공백 감지 결과 |
| 출력 | `docs/` 신규 file |
| 필수 | frontmatter (`title`, `owner`, `tier`, `audience`, `legacy-id`, `last-updated`) |
| classifier 역할 | tier (`contract` / `feature` / `internal`) + audience (`user` / `developer` / `art-designer`) 분류 |
| 원칙 | additive only — 기존 문단 건드리지 않고 신규 섹션 추가 |

### Step 2 — 재구현성 검증

| 항목 | 값 |
|------|-----|
| 팀 | iteration-spec-validator + iteration-spec-coherence |
| 입력 | Step 1 의 신규 spec |
| 도구 | `tools/reimplementability_audit.py` + `tools/spec_drift_check.py` |
| 출력 | reimplementability score (0~1) |
| PASS 조건 | score ≥ 0.9 AND coherence 충돌 0 |
| FAIL 시 | spec-author 가 결손 항목 수정 → 재검증 |

### Step 3 — 프로토타입 가능성 검토

| 항목 | 값 |
|------|-----|
| 팀 | iteration-prototype-validator |
| 입력 | Step 2 PASS 한 spec |
| 출력 | feasibility 분류 |
| 분류 | `구현 가능` / `부분 가능` / `불가능` |
| 판정 기준 | tech stack / dependency / hardware / external 의존성 검토 |

### Step 4 — 분기

| feasibility | 처리 |
|-------------|------|
| 구현 가능 | Impl-first 7-step Step 1 진입 (자동) |
| 부분 가능 | 기획 정정 (spec-author 자율) → Step 2 재검증 |
| 불가능 | 사용자 escalation — 자율 한계 명시 (예: vendor 외부 의존, hardware 부재) |

### Step 5 — 결정 archive

| 항목 | 값 |
|------|-----|
| 팀 | iteration-decision-archivist |
| 입력 | 사용자 결정 (B-Q*, SG-*, 인텐트 명시) |
| 출력 | `~/.claude/projects/{project}/memory/` 영구 기록 + Conductor_Backlog audit row |
| 트리거 | Step 4 escalation OR 사용자 explicit decision |
| 형식 | 결정 ID + 날짜 + 결정 내용 + 영향 범위 + supersedes/replaces 관계 |

## 자율 escalation 한계

다음은 사용자 명시 결정 필수 (V9.4 Mode A 한계 + V10.0 명시):

| 영역 | 사유 |
|------|------|
| vendor 외부 메일 / RFI/RFQ | 회사명 노출 / 외부 visible |
| destructive 시스템 변경 | DB drop, prod 배포, 거대 dependency |
| git config 자율 변경 | remote URL 등 |
| 사용자 인텐트 변경 | SG-023 같은 큰 결정 |
| memory 사용자 본인 결정 메모 | 임의 폐기 금지 |
| Hardware 의존성 (RFID 등) | vendor 도착 의존 |

## Exit 조건

```
exit = (
  spec_drift D1=0 AND
  reimplementability_pass_rate ≥ 0.9 AND
  feasibility != "불가능"
)
OR user explicit stop
OR escalation 후 사용자 응답 대기 (block, 자동 CONTINUE 금지)
```

`불가능` feasibility 시 — IL-2 예외: 사용자 응답 대기는 stop 이 아닌 BLOCK 상태. 응답 도착 시 Step 4 재진입.

## Workflow 전환

| 상황 | 다음 workflow |
|------|---------------|
| Step 4 = 구현 가능 | Impl-first 7-step Step 1 자동 진입 |
| Step 5 archive 후 | iteration cycle 종료 (사용자 stop) OR 다음 phase |
