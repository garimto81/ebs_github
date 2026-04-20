---
id: SG-008-b12
title: "GET /api/v1/reports/{report_type} deprecate 시점 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
related_sg:
  - SG-007  # 6-endpoint reports 분할 대체
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
---

# SG-008-b12 — `GET /api/v1/reports/{report_type}` deprecate 시점

## 배경

SG-008 §"b분류" 에서 승격. 레거시 단일 `reports/{report_type}` 패턴은 SG-007 에서 **6개 전용 endpoint** 로 분할 대체 완료. 기존 generic endpoint 유지 여부 결정 필요.

## 대상 endpoint (code-only)

- `GET /api/v1/reports/{report_type}` — generic report dispatcher (legacy)

## 참조 SG

- **SG-007** — 6-endpoint 분할 완료:
  - `GET /api/v1/reports/events/summary`
  - `GET /api/v1/reports/events/{id}/entries`
  - `GET /api/v1/reports/events/{id}/payouts`
  - `GET /api/v1/reports/flights/{id}/summary`
  - `GET /api/v1/reports/tables/{id}/history`
  - `GET /api/v1/reports/players/{id}/stats`

## 논점

1. Legacy endpoint 클라이언트가 실제로 있는가? (Frontend/CC 에서 호출 중?)
2. 즉시 삭제 가능 vs 1-sprint deprecation 경고 기간?
3. 301 redirect 로 신규 endpoint 로 forwarding vs 410 Gone

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. 즉시 삭제 (클라이언트 호출 0 가정, grep 검증 후) | Drift 해소 최단 | 미발견 호출 시 runtime 에러 |
| 2. 1-sprint deprecation (410 Gone + 경고 헤더) + 다음 sprint 삭제 | 안전 | 중복 유지 기간 |
| 3. 301 redirect + 레거시 유지 | 호환성 최대 | 영구 중복. 새 endpoint 로의 마이그레이션 동기 약함 |

## Default 제안

**옵션 1 (즉시 삭제 — 사전 검증 후)**. 이유:
- EBS 는 개발팀 인계용 프로토타입 — 아직 외부 클라이언트 부재
- SG-007 분할이 2026-04 완료 (최근) — legacy 호출이 있었다면 이미 마이그레이션 됨
- Frontend(`team1-frontend/lib/**`), CC(`team4-cc/src/**`) 전수 grep 으로 사용처 0 확인 후 삭제 가능
- WSOP LIVE 는 generic dispatch 패턴 사용하지 않음 — 일관성 확보

**스펙 제안 초안 (옵션 1 채택 시)**:
- 사전 검증 단계 (team2 세션):
  ```bash
  grep -rn '/api/v1/reports/' team1-frontend/lib/ team4-cc/src/
  # 결과 0 이면 안전하게 삭제
  ```
- team2 코드 삭제 PR: `src/routers/reports.py` 의 generic dispatcher 제거 (6-endpoint 는 유지)
- Backend_HTTP.md §reports 섹션에서 legacy 언급 제거
- 호출 발견 시: 해당 호출 지점을 6-endpoint 중 하나로 마이그레이션 후 삭제

## 수락 기준

- [ ] team2 사전 검증: Frontend/CC 코드에서 `reports/{report_type}` 호출 0 확인
- [ ] 검증 통과 시: 옵션 1 진행 (코드 삭제 PR)
- [ ] 검증 실패 시: 호출 지점 파악 후 옵션 2 또는 3 재선택 + 마이그레이션 계획
- [ ] 삭제 후 `python tools/spec_drift_check.py --api` D3 에서 본 endpoint 해소 확인


## Resolution

**2026-04-20: 옵션 1 채택** — 즉시 삭제. SG-007 6-endpoint 로 완전 대체 (grep 검증 0 호출)

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: 즉시 삭제. SG-007 6-endpoint 로 완전 대체 (grep 검증 0 호출) | team2 session |
