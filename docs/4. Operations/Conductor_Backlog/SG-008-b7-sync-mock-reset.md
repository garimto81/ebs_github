---
id: SG-008-b7
title: "DELETE /api/v1/sync/mock/reset 운영 환경 노출 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
---

# SG-008-b7 — `DELETE /api/v1/sync/mock/reset` 운영 환경 노출

## 배경

SG-008 §"b분류" 에서 승격. Mock reset endpoint — mock seed 데이터 제거. SG-008-b6 (mock/seed) 와 **쌍** 으로 동일 정책 적용.

## 대상 endpoint (code-only)

- `DELETE /api/v1/sync/mock/reset` — mock seed 삭제

## 논점

SG-008-b6 과 동일 — 운영 환경에서 **DB 전체 wipe 가능성**이 있어 b6 보다 위험도 높음.

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. dev/staging only env 가드 (b6 과 동일) | 운영 안전 | 인계 시 가드 숙지 필요 |
| 2. Admin only + confirmation token 필수 (운영 포함) | 유연성 | 운영 DB wipe 위험 여전 |
| 3. 코드 삭제 (seed/ CLI 로 대체) | 최대 안전 | 개발 편의 손실 |

## Default 제안

**옵션 1 (dev/staging only env 가드)**. 이유:
- SG-008-b6 과 페어 정책 — 하나만 막으면 seed 후 reset 불가로 무용지물
- reset 은 destructive operation 의 전형 — 운영 환경에서는 "존재조차 하지 말아야" 가드 기본
- 만약 운영 환경에서 reset 이 필요한 업무 요구가 있다면 **별도 endpoint** 로 Confirmation flow 와 함께 설계 (현재 범위 밖)

**스펙 제안 초안**:
- `DELETE /api/v1/sync/mock/reset` — Admin only + `APP_ENV in {development, staging}` 가드
- Body: `{ confirm: true }` (명시적 confirm flag)
- Response: `{ deleted: { series: N, events: N, flights: N, tables: N } }`
- Production 환경에서 호출 시 404 Not Found
- Backend_HTTP.md §Development Utilities 섹션에 b6 과 함께 묶음

## 수락 기준

- [ ] 옵션 선택 (b6 과 동일해야 함)
- [ ] 옵션 1: Backend_HTTP.md §Development Utilities 보강 + env 가드 구현 확인
- [ ] 옵션 2: confirmation token 메커니즘 별도 SG 로 승격
- [ ] 옵션 3: team2 코드 삭제


## Resolution

**2026-04-20: 옵션 1 채택** — Admin + profile gate (dev/test only)

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: Admin + profile gate (dev/test only) | team2 session |
