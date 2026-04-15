---
id: GAP-BO-007
title: 타임아웃 기본값 카탈로그 부재 (Late Reg, Call Limit, Waiting Room)
status: OPEN
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-007] 타임아웃 기본값 카탈로그 부재 (Late Reg, Call Limit, Waiting Room)

- **관찰**: 현재 BO-02 동기화 프로토콜과 IMPL-10에 타임아웃 기본값이 흩어져 있음. WSOP는 `LateRegDay/LateRegLevel/LateRegDuration`, `CallLimit`, Waiting Room TTL을 각각 관리.
- **참조**:
  - WSOP `Tournament.md` (LateRegDuration)
  - WSOP `Waiting API.md` (Call Limit)
- **구현 가능성**: 미결 — 기획 보강 요청 (product 오너 확정 필요)
- **액션**:
  1. IMPL-10 §6에 타임아웃 카탈로그 임시 기본값 명시 (출처: WSOP 평균값)
  2. Product 오너에게 EBS 운영 기준 확정 요청 (backlog.md 항목 등록)
  3. 확정 시 IMPL-10 §6 갱신 + Phase 1 CCR 불필요 (team2 내부)
- **상태**: OPEN — 기획 보강 대기

---
