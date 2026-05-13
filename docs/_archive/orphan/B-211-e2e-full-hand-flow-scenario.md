---
id: B-211
title: "B-211 — End-to-End 풀 핸드 플로우 통합 테스트 시나리오"
owner: conductor
tier: internal
status: PENDING
type: backlog
severity: HIGH
blocker: true
source: docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md
last-updated: 2026-05-09
---

## 개요

`integration-tests/`에 단계별 .http 18개가 있으나 deal→preflop→flop→turn→river→showdown→pot 분배 전 파이프라인을 검증하는 E2E 시나리오가 0건. 회귀 검출 불가능.

## 근거

- 기획: `Foundation.md` Ch.5 의존성 사슬 (RFID→Engine→CC→BO→Overlay)
- 통합 테스트 갭: 본 보고서 §5 — "End-to-End 핸드" 행 통째로 비어있음
- 단위는 충분 (각 단계 ✅), 조립이 미완

## 작업 범위

1. `integration-tests/scenarios/v99-full-hand-flow.http` 작성
2. Mock RFID + Engine harness + BO + CC + (Overlay) 풀 체인 시나리오
3. 핸드 1회 완주: 카드 인식 → 액션 6키 입력 → 팟 계산 → showdown → winner → BO commit
4. CI 워크플로 통합 (`.github/workflows/`) — 통합 테스트 자동 실행

## 완료 기준

- [ ] `v99-full-hand-flow.http` GREEN
- [ ] 각 단계별 4팀 합의 (assertion 정의)
- [ ] CI에서 자동 실행
- [ ] 회귀 시 즉시 검출 가능

## 예상 비용

3-5 day (Conductor + 각 팀 1명 합동).

## 의존

- B-210 부분 완료 후 시작 권장 (또는 Overlay assertion stub로 먼저 가능)

## 관련

- 본 보고서: §5 통합 계약 vs 통합 테스트 갭 분석
- B-210 (Overlay Rive 매핑)
