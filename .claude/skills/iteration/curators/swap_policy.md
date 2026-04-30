# Hot-Swap Curator Policy

## 목적

iteration cycle 의 phase 별 ACTIVE curator 가 매 phase 종료 시 STANDBY curator 와 교체. 진화 메커니즘 폭주 0 + 매 phase 1회 개선만 hard-cap.

## 동작 (사용자 명시 — 자동 교체)

```
Phase N (홀수):
  curator-a = ACTIVE (registry 결정 + agent 선택)
  curator-b = STANDBY (대기, 작업 X)

[Phase N 종료 = exit_criteria 충족 시점]
  ↓
swap 전 단계 (한 번만 수행):
  1. curator-b 가 curator-a 의 phase N 작업 전수 검사
     - 모든 결정 log
     - 선택한 agent 들과 결과
     - 누락 / 비효율 식별
  2. curator-b 가 curator-a 의 prompt 1회 개선 (개선안 적용)
  ↓
Phase N+1 (짝수):
  curator-b = ACTIVE (개선된 prompt 로)
  curator-a = STANDBY (대기)

[Phase N+1 종료]
  ↓
swap 전 (한 번만):
  1. curator-a 가 curator-b 의 phase N+1 작업 전수 검사
  2. curator-a 의 prompt 1회 개선 (curator-b 가 적용)
  ↓
Phase N+2: curator-a = ACTIVE (개선된 prompt) ...
```

## 핵심 규칙

| 규칙 | 정책 |
|------|------|
| **자동 교체** | phase 종료 시 항상. 조건 X. |
| **검사 횟수** | swap 직전 1회. 검사하지 않음 = swap 무효. |
| **개선 횟수** | swap 직전 1회. 개선 0 OR 개선 2회+ 모두 violation. |
| **무한 진화 방지** | 매 phase 1회 개선 hard-cap → 메커니즘 차원에서 폭주 0. |
| **rotation_log.md** | 매 swap entry 자동 기록 (timestamp + version diff + 검사 요약 + 개선 내용). |

## 동시 활성 = 1

| 역할 | 권한 |
|------|------|
| **ACTIVE** | 결정 권한 (해당 phase 의 모든 agent 선택). registry scan 자율. |
| **STANDBY** | 대기. phase 종료 직전에만 검사+개선 작업. ACTIVE 의 결정 권한 없음. |

충돌 0 — 동시에 결정 내리지 않음.

## 검사 항목 (swap 직전 STANDBY 작업)

```
1. 결정 log 분석
   - ACTIVE 가 선택한 agent 들
   - reuse vs 신규 비율
   - 의사결정 트리

2. 결과 평가
   - 각 agent 의 산출물 (PR / 문서 / e2e 결과)
   - exit_criteria 충족 여부
   - 누락 항목

3. 비효율 식별
   - 불필요한 agent 호출
   - 중복 작업
   - registry signature 충돌

4. 개선안 도출 (1회만)
   - prompt 명확화
   - registry rule 추가
   - 다음 phase 의 예상 함정 회피
```

## 개선 적용 (swap 시점 STANDBY → 새 ACTIVE 가 적용)

```
1. STANDBY 가 도출한 개선안을 자기 prompt 에 1회 반영
   (curator-a 가 STANDBY 일 땐 curator-a 의 prompt 개선)
2. 적용된 prompt 로 다음 phase 의 ACTIVE 역할 수행
3. 동일 phase 에서 추가 self-improvement X
```

## rotation_log.md 형식

```markdown
## Phase N (YYYY-MM-DD HH:MM:SS)

- ACTIVE → STANDBY: curator-a → curator-b
- 검사 요약:
  - ACTIVE 가 선택한 agent: [list]
  - reuse / 신규 비율: 9/1
  - 누락: 0
  - 비효율 식별: [list]
- 개선 내용 (curator-a prompt 1회):
  - Before: ...
  - After: ...
  - Reason: ...
```

## 무한 진화 방지 메커니즘 (왜 이 정책으로 충분한가)

| 메커니즘 | 효과 |
|----------|------|
| 1회 개선 hard-cap | self-improvement 무한 루프 자체 불가 |
| swap 직전만 검사 | 실시간 self-monitoring overhead 0 |
| ACTIVE / STANDBY 분리 | self-modify 불가 (다른 curator 가 개선) |
| 매 phase 자동 swap | 한 curator 의 monopoly 불가 |

## 위반 처리

| 위반 | 처리 |
|------|------|
| swap 시점에 검사 0 | rotation_log 에 `WARNING: no inspection` 기록 + 이전 prompt 유지 |
| 개선 2회+ | 첫 개선만 채택, 나머지 무시. `WARNING: multiple improvements` 기록 |
| ACTIVE swap 거부 (자율 결정) | violation. ACTIVE 강제 STANDBY. circuit_breaker 카운트 +1 |
| rotation_log 누락 | 다음 phase 시작 차단. 누락 entry 추가 후 재개 |
