---
id: B-215
title: "B-215 — Dev 환경 시드 사용자 자동화"
owner: team2
tier: internal
status: PARTIAL_DONE
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
last-updated: 2026-05-10
---

## 개요

E2E 검증 진행 중 dev 시드 사용자 부재로 login 401 발생. 발견 결과 BO 컨테이너에 `tools/seed_admin.py` + `tools/seed_demo_data.py` 이미 존재. 발견·실행 완료, **단 자동화는 미완**.

## 현 상태 (2026-05-10)

| 항목 | 상태 |
|------|:----:|
| seed_admin.py 존재 | ✅ (admin/operator/viewer role 옵션, 환경 분리 지원) |
| seed_demo_data.py 존재 | ✅ (E2E_Demo competition + 8 series + 14 events + 8 flights + 10 Day-2 tables) |
| 두 도구 idempotent | ✅ |
| docker compose 자동 호출 | ❌ **미완** — 매번 수동 `docker exec ebs-bo python tools/seed_*.py` 필요 |

## 작업 범위 (남은 자동화)

1. BO 컨테이너 entrypoint(`team2-backend/entrypoint.sh`)에 `AUTH_PROFILE=dev`일 때 자동 seed_admin 호출
2. (선택) `EBS_SEED_DEMO=true` 환경변수 시 seed_demo_data도 자동
3. README.md / Quickstart_Local_Cluster.md 업데이트 — 자동화 후 수동 명령 불필요 표시

## 완료 기준

- [ ] `docker compose --profile web up -d` (no extra args) → admin@ebs.local 자동 시드
- [ ] login 200 + 8 series 응답을 자동 검증하는 smoke test 추가

## 참조

- 발견 보고: `docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md` §0 Errata + §6
- BS-01 Authentication.md
- Quickstart_Local_Cluster.md (M5)
