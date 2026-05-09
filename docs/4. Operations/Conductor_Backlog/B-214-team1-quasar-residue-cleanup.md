---
id: B-214
title: "B-214 — team1 Quasar 잔재 정리 + feature 매니페스트 정합"
owner: team1
tier: internal
status: PENDING
type: backlog
severity: LOW
blocker: false
source: docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md
last-updated: 2026-05-09
---

## 개요

`1. Product.md` γ하이브리드에서 Flutter 통일 결정됐으나 team1-frontend에 Quasar(이전 스택) 잔재 존재. 또한 정본 8 feature 선언 vs 실측 6 feature 불일치.

## 근거

- 기획: `1. Product.md` γ하이브리드 — Flutter 통일
- 잔재: `team1-frontend/` 내 node_modules, pnpm-lock.yaml, .quasar/ 등
- 미구현 feature: Players, Audit_Log, Hand_History (정본 선언만, 코드 없음)

## 작업 범위

1. Quasar 잔재 삭제 (node_modules, pnpm-lock.yaml, .quasar/, package.json 등)
2. Players/Audit_Log/Hand_History 3 feature 결정:
   - (a) 구현 — 별도 백로그 등록
   - (b) 정본 선언에서 제거 — `Lobby/Overview.md` 갱신
3. team1 빌드 단순화 검증 (`flutter build windows --release` PASS)

## 완료 기준

- [ ] Quasar 관련 파일 0개
- [ ] 정본 feature 선언 ↔ 코드 일치
- [ ] team1 빌드 PASS

## 예상 비용

0.5 day (team1).

## 의존

- 독립 진행 가능

## 관련

- 본 보고서: §2 #5
- SG-013 (lobby tournaments nomenclature)
