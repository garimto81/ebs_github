---
id: B-212
title: "B-212 — Backend 커버리지 78% → 90% (B-Q10 1차 단계)"
owner: team2
tier: internal
status: PENDING
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md
linked-backlog: B-Q10
last-updated: 2026-05-09
---

## 개요

`B-Q10`이 95% 최종 목표 roadmap. 본 항목은 그 1차 단계 — **78% → 90% (12%p)** 우선 달성. 잔여 5%p는 후속.

## 근거

- 기획: `Back_Office_PRD.md` Ch.7 SLO (가용성 99.5%, 50+ commit/sec)
- 현재: 261/261 tests PASS, 78% (3984 stmts, 882 missed)
- 목표 1차: 90% (이번 백로그)
- 목표 최종: 95% (B-Q10)

## 작업 범위

1. `reports.py` MV 실구현 (현재 mock 6 endpoint)
2. `decks.py` DB session 교체 (IMPL-003 연동)
3. `publishers.py` trigger 실 wiring (20 event skeleton)
4. settings_kv.py 4-level resolver 회귀 (11 test PASS 유지)

## 완료 기준

- [ ] coverage ≥ 90% (`pytest --cov`)
- [ ] reports.py 6 endpoint 실 DB 응답
- [ ] IMPL-003 (decks DB session) DONE
- [ ] publishers 20 event 실호출

## 예상 비용

1 week (team2).

## 의존

- 독립 진행 가능 (B-210/B-211과 병렬)
- IMPL-003 (이미 진행 중)

## 관련

- B-Q10 (95% roadmap, 본 항목의 후속 5%p)
- IMPL-003 (decks DB session)
- 본 보고서: §2 #3
