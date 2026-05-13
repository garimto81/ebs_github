---
id: B-213
title: "B-213 — NFR \"정확성\" 정량 KPI 정의"
owner: conductor
tier: internal
status: PENDING
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md
last-updated: 2026-05-09
---

## 개요

`Foundation.md` Ch.1 Scene 4에서 "정확성"이 5 핵심가치 1순위로 명시되어 있으나 정량 수치가 없음. 응답시간(<100ms), 가용성(99.5%), 복구시간(5초)은 명시. 정확성만 정성 표현.

## 근거

- 기획: `Foundation.md` Ch.1 Scene 4 — "정확성·안정성·단단한 HW·명확한 연결·오류 없는 처리"
- 1단계 완전안정화(X4) 판정 기준 부재
- 2단계 무인화(Vision Layer) 진입 기준선 부재

## 작업 범위 (제안)

`Foundation.md` Ch.1 또는 Ch.7에 다음 KPI 추가:

| KPI | 제안 목표 | 측정 방식 |
|-----|----------|----------|
| 핸드 분배 결정 일치율 | ≥ 99.99% | Engine 출력 vs 운영자 검수 |
| OutputEvent 누락률 | ≤ 0.01% | Audit log 회귀 분석 |
| 카드 인식 오류율 | ≤ 0.1% | RFID raw vs 결정 비교 |
| 팟 계산 정확도 | 100% | 자동 회귀 테스트 |
| 시간 여행 복구 정확도 | 100% | snapshot reload 검증 |

## 완료 기준

- [ ] Foundation에 KPI 항목 추가 (PR 합의)
- [ ] 측정 인프라 명시 (BO audit + Engine harness 활용 방안)
- [ ] 운영 대시보드 메트릭 후속 백로그 등록 (선택)

## 예상 비용

2-3 day (Conductor + team2 협의).

## 의존

- 독립 진행 가능

## 관련

- 본 보고서: §2 #4
- B-Q12 (100ms SLA measurement) — 측정 인프라 참고
