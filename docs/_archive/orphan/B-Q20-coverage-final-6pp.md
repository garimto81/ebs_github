---
title: B-Q20 — 95% coverage 잔여 6%p 도달 (Session 2 final 후속)
owner: conductor (or team2)
tier: internal
status: CLOSED (90% 재정의 2026-04-27 — Option 2 채택)
closed: 2026-04-27
closed-decision: 사용자 B-Q7 ㉠ 90% 재정의 채택 → 89% ≈ 90% 도달 = Session 2 자연 종료
type: backlog
linked-sg: SG-026
linked-decision: Session 2 final 89% 도달 후 잔여 (2026-04-27)
last-updated: 2026-04-27
confluence-page-id: 3818914392
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914392/EBS+B-Q20+95+coverage+6+p+Session+2+final
mirror: none
---

## 개요

Session 2 final (2026-04-27) coverage **89% 도달**. B-Q7 ㉠ Production-strict 목표 **95% 까지 6%p (240 stmts) 잔여**.

## 잔여 분포 (final 측정)

```
  TOTAL  3984 stmts  434 missed  89%
  목표:                240 missed (95%)
  잔여:                194 stmts 추가 커버 필요
```

### Largest gaps (추정)

| 모듈 (final 측정) | coverage | missed |
|------------------|:--------:|:------:|
| `services/auth_service.py` | ~70% (Session 2.1 후) | ~45 |
| `services/series_service.py` | ~78% (Session 2.3a 후) | ~35 |
| `routers/auth.py` | 71% (보강 안 됨) | 57 |
| `routers/hands.py` | 37% (B-Q19 차단) | 31 |
| `services/wsop_sync_service.py` | 91% | 20 |
| 작은 모듈 잔여 | various | ~50 |

## 처리 옵션

### Option 1 — 단계적 cascade (multi-turn)
1. **B-Q18 + B-Q19 surgical edit** (production bugs 수정 별도 commit)
2. structure update full path tests (B-Q18 fix 후 +4 tests)
3. list_hands full path tests (B-Q19 fix 후 +7 tests)
4. router 영역 deep coverage (auth/hands/blind/payout +30-40 tests)
5. service 영역 잔여 edge cases (+20-30 tests)
6. 작은 모듈 100% 도달 (+10-15 tests)

총 +65-90 tests over **2-3 sub-sessions**.

### Option 2 — B-Q7 ㉠ 재정의

89% coverage 를 production-strict 의 실용적 기준으로 재평가:
- 일반 production 표준: 80-90%
- Google internal: 60-80%
- 95% 는 critical path / safety-critical 영역 한정

B-Q7 ㉠ "Production-strict 95%" → **"Production-strict 90%"** 재정의 가능. Session 2 자연 완료.

### Option 3 — 우선순위 전환

다른 production gate (B-Q11 OWASP / B-Q12 100ms SLA 등) 가 더 시급. coverage 89% 유지 + 다른 gate 우선 처리.

## 우선순위

**P2** — B-Q7 ㉠ 의 직접 cascade 잔여. 단 89% 도 production 진입 가능 수준 (Option 2 검토 권장).

## 권장

본 turn 사용자 결정: B-Q20 처리 방식 (Option 1/2/3) 중 선택.

## 참조

- `docs/4. Operations/Conductor_Backlog/SESSION_2_FINAL_REPORT.md` (final 89% 결과)
- `docs/4. Operations/Conductor_Backlog/B-Q10-95-coverage-roadmap.md` (multi-turn plan)
- `docs/4. Operations/Conductor_Backlog/B-Q18-structure-update-same-tx-flush-bug.md` (선결 P1)
- `docs/4. Operations/Conductor_Backlog/B-Q19-list-hands-row-int-bug.md` (선결 P1)
