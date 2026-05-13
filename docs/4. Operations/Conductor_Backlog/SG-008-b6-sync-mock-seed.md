---
id: SG-008-b6
title: "POST /api/v1/sync/mock/seed 운영 환경 노출 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.2 Backend/Engineering/
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
tier: internal
backlog-status: open
---

# SG-008-b6 — `POST /api/v1/sync/mock/seed` 운영 환경 노출

## 배경

SG-008 §"b분류" 에서 승격. Mock seed endpoint — 개발/테스트 환경에서 WSOP LIVE 데이터를 모사. 운영(Production) 환경 노출 시 위험.

## 대상 endpoint (code-only)

- `POST /api/v1/sync/mock/seed` — mock WSOP LIVE 데이터 seed

## 논점

1. 운영 환경 노출 여부 — `APP_ENV=development` 에서만 활성화? Admin 전용?
2. 기능 자체 유지 — 개발팀 인계 시 필요? (데모 환경 구축용)
3. `/sync/mock/reset` (b7) 와 쌍으로 동일 판정 필요

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. dev/staging only (`APP_ENV != production` 가드) | 운영 안전 + 개발 편의 유지 | env 가드 테스트 필수 |
| 2. Admin only, 운영에서도 허용 | 데모 환경 구축 유연 | 운영 DB 오염 위험 (실수로 실행 시) |
| 3. 코드 삭제, dev seed 는 `seed/` 디렉토리 CLI 스크립트로 대체 | 운영 위험 0 + 명시적 | 개발팀 인계 시 CLI 사용법 학습 필요 |

## Default 제안

**옵션 1 (dev/staging only env 가드)**. 이유:
- EBS 개발팀 인계 프로젝트 — 인계 초기 단계는 mock 데이터로 local smoke test 가 자주 필요
- env 가드는 FastAPI middleware 에서 단 2줄로 구현 가능 (`if settings.APP_ENV == "production": raise HTTPException(404)`)
- `/sync/mock/reset` 과 쌍으로 동일 정책 적용 (SG-008-b7 에서 공유)

**스펙 제안 초안**:
- `POST /api/v1/sync/mock/seed` — Admin only + `APP_ENV in {development, staging}` 가드
- Body: `{ dataset: "minimal" | "full" | "{series_id}" }` — seed 규모 선택
- Response: `{ seeded: { series: N, events: N, flights: N, tables: N } }`
- Production 환경에서 호출 시 404 Not Found (endpoint 가 존재하지 않는 것처럼)
- Backend_HTTP.md 에 `§Development Utilities` 섹션 신설 (b6/b7/b9 묶음)

## 수락 기준

- [ ] 옵션 선택 (b7, b9 와 일관성 필수)
- [ ] 옵션 1: Backend_HTTP.md §Development Utilities 섹션 + env 가드 구현 확인
- [ ] 옵션 2: Backend_HTTP.md 에 Admin-only 명시, 운영 DB 보호 조치 추가 (confirmation token 등)
- [ ] 옵션 3: team2 코드 삭제 + seed/ CLI README 작성


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
