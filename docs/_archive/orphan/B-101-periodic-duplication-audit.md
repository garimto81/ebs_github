---
id: B-101
title: "주기적 중복 audit (상시 항목) — 월 1회 Foundation + 주요 계약 문서"
status: RECURRING
source: docs/4. Operations/Conductor_Backlog/B-100-redesign-wave-2026-04-22.md (F1.7 lessons learned)
owner: conductor
created: 2026-04-22
frequency: monthly (1st week)
---

# B-101 — 주기적 중복 audit

## 배경

F1.7 (`docs/1. Product/Foundation.md` 중복 정리, 2026-04-22 commit `a756f6c`) 에서 다음 사실이 드러났다:

- "추가 전용(additive) 원칙" 은 올바른 설계 철학이지만, **기존 문단 감사(audit) 가 동반되지 않으면** 동일 정보가 여러 포맷(ASCII / Mermaid / Table / Bullet)으로 반복 진술되는 overlap 이 누적됨.
- F1/F1.6 대규모 증분 후 2시간 경과 시점에 이미 **§6.3 에 3중 중복** (Mermaid + ASCII + 매트릭스) 발생.
- 누적된 중복은 **외부 인계 완결성을 해친다** — 개발팀이 "어느 것이 정본인가?" 에 답할 수 없음.

## 목표

주요 문서의 중복 항목을 정기적으로 감지하고 제거하여:

1. 외부 인계 문서의 **SSOT 명확성** 유지
2. **읽기 재미 + 정확성** 양립 (Foundation 모토)
3. 팀 세션이 신규 섹션 작성 시 어느 정본을 참조할지 빠르게 판정

## 대상 문서 (우선순위)

| 순위 | 문서 | 빈도 | 사유 |
|:---:|------|:---:|------|
| 1 | `docs/1. Product/Foundation.md` | 월 1회 | Confluence 발행, 가장 많이 수정, overlap 위험 최고 |
| 2 | `docs/2. Development/2.5 Shared/BS_Overview.md` | 월 1회 | 팀 공통 계약, 용어 사전 정본 |
| 3 | `docs/2. Development/2.5 Shared/*.md` (Risk_Matrix / Authentication / EBS_Core 등) | 분기 1회 | 변경 빈도 낮음 |
| 4 | `docs/1. Product/Game_Rules/**` | 분기 1회 | Confluence 발행, 각 PRD 독립 완결성 |
| 5 | `docs/4. Operations/Roadmap.md` · `Spec_Gap_Registry.md` | 월 1회 (agile) | 상태 변화 빈번, stale 정보 유입 위험 |

## 실행 Protocol (5-Phase)

### Phase 1. 대상 선정
- 월 1회 audit 트리거 시점 (매월 첫째 주)
- 지난 audit 이후 commit 활동 분석 → 수정량 상위 2~3 문서 우선 지정

### Phase 2. Critic 5-Phase 적용 (F1.7 패턴)
1. **모호성 원천 (Ambiguity Sources)** — 용어 혼재, 포맷 불일치 식별
2. **Overlap 매트릭스** — 동일 정보가 여러 곳에 있는지 표로 매핑
3. **반박 근거** — 각 overlap 에 대해 "유지 근거 있는가?" 검증
4. **Judgement** — A-level(즉시 제거) / B-level(cross-ref) / C-level(유지) / D-level(편집 흔적) 분류
5. **제거 실행 계획** — 섹션별 Edit 단위

### Phase 3. 중복 Cluster 분류
F1.7 에서 검증된 4 레벨 분류 적용:
- **A-level**: 동일 정보 100% 중복, 고유 가치 없음 → **삭제**
- **B-level**: 부분 중복, 다른 각도 → **cross-ref 추가**
- **C-level**: 의도된 중복 (자체 완결성) → **유지**
- **D-level**: 과거 편집 흔적, 메타 정보 → **정리**

### Phase 4. 실행 + 검증
- `/team "F{N}.X Foundation 중복 audit — YYYY-MM"` 호출
- Edit 기반 섹션별 수정 (Write 재생성 금지)
- `wc -l` 및 `git diff --stat` 로 증감 확인
- Cross-ref 유효성 검증 (깨진 참조 없는지)

### Phase 5. Lessons Capture
- audit 결과를 본 파일 하단 History 테이블에 1행 추가
- 반복 발견되는 중복 패턴이 있으면 BS_Overview 용어 사전 (F2.5) 에 등재 제안

## Acceptance Criteria (audit 1회 완료 기준)

- [ ] 대상 문서 전수 정독 완료
- [ ] A-level 중복 전부 제거
- [ ] B-level 중복에 cross-ref 추가
- [ ] D-level 편집 흔적 정리
- [ ] History 테이블 갱신
- [ ] Commit + push (refactor 커밋 prefix 사용)

## History

| 날짜 | 대상 문서 | commit | 제거 A-level | 추가 cross-ref | 정리 D-level | 순 증감 |
|------|----------|--------|:-----------:|:-------------:|:-----------:|:------:|
| 2026-04-22 (F1.7 pilot) | Foundation.md | `a756f6c` | 2건 | 2건 | 2건 | -21 lines |

## 관련

- F1.7 pilot: Foundation.md 중복 정리 commit `a756f6c`
- F2.5: BS_Overview 용어 entry schema (정본/참조 섹션) — 본 audit 의 전제 조건
- 도구: `tools/spec_drift_check.py` (관련 drift 검증)
- 문서 표준: `docs/README.md` 대형 문서 프로토콜

## 금지

- Write 로 문서 전면 재작성 금지 — 섹션별 Edit 만 허용
- "추가 전용 원칙" 을 audit 불필요의 변명으로 삼기 금지 — 양자는 보완 관계
- A-level 중복을 "혹시 필요할 수도" 로 보존하기 금지 — 정확성 우선
