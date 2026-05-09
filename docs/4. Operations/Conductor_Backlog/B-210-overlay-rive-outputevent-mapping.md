---
id: B-210
title: "B-210 — Overlay Rive 21 OutputEvent 매핑 sprint"
owner: team4
tier: internal
status: PENDING
type: backlog
severity: HIGH
blocker: true
source: docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md
linked-overview: docs/2. Development/2.4 Command Center/Overlay/Overview.md
last-updated: 2026-05-09
---

## 개요

Engine(team3)에 21 OutputEvent enum이 정의되어 있지만, Overlay(team4)에서 21/21 매핑이 0% 상태(skeleton만). MVP 시각 산출물의 진입점이라 통합 QA 진입의 1차 블로커.

## 근거

- 기획: `Foundation.md` Ch.5 §B.1 — 오버레이는 21 OutputEvent를 Rive 트리거로 소비
- 정본: `2.4 Command Center/Overlay/Overview.md` — Rive state machine 매핑 명시
- 코드: `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart` 21 sealed class ✅
- 갭: `team4-cc/src/lib/features/overlay/**/*.dart` 에 OutputEvent enum 매핑 위젯 없음

## 작업 범위

1. 21 OutputEvent별 Rive state machine 매핑 위젯 작성
2. Engine harness stub로 single-event smoke test 추가
3. (선택) 매핑 카탈로그 문서 `Overlay/Mapping_Catalog.md` 생성

## 완료 기준

- [ ] 21/21 OutputEvent → Rive widget 매핑 PASS
- [ ] `team4-cc/test/overlay/output_event_mapping_test.dart` GREEN
- [ ] B-211 풀 핸드 시나리오에서 Overlay assertion 활성화

## 예상 비용

1-2 week (team4 dev 1명 풀타임 또는 2명 병행).

## 의존

- team3 OutputEvent 정의 (완료, 21/21 PASS)
- team3 harness HTTP 안정 (완료)

## 관련

- 본 보고서: `docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md` §2 #1
- Phase 5 진입 체크리스트 1번 항목
