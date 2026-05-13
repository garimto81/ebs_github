---
id: SG-008-b3
title: "GET /api/v1/audit-logs/download 포맷 + rate limit 판정"
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
tier: internal
backlog-status: open
---

# SG-008-b3 — `GET /api/v1/audit-logs/download` 포맷 + rate limit

## 배경

SG-008 §"b분류" 에서 승격. 전량 다운로드 endpoint — 대용량/고비용 API 로 운영 상 위험. SG-008-b2 (audit-logs 리소스 존재 여부) 결정에 의존.

## 대상 endpoint (code-only)

- `GET /api/v1/audit-logs/download` — 전체 audit_logs dump

## 논점

1. 출력 포맷 — CSV (Excel 친화) vs NDJSON (line-delimited JSON, streaming 친화) vs JSON array
2. rate limit — 대용량 query 는 Admin 이라도 빈번 호출 시 DB 부담. per-user 얼마나?
3. 기간 제약 — 전체 dump 허용 vs `?from_ts&to_ts` 필수
4. async 생성 (백그라운드 job) vs sync stream

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. sync streaming NDJSON, Admin only, rate limit 1/hour | 구현 간단 (FastAPI `StreamingResponse`). 구조화 | 대량 시 연결 유지 부담 |
| 2. async job — POST trigger + GET status/download | 안정적. 대용량 대응 | 구현 복잡 (job table + background worker) |
| 3. 코드 삭제 (b2 에서 audit-logs 자체 삭제 시) | Drift 해소 | 감사 기능 약화 |

## Default 제안

**옵션 1 (sync streaming NDJSON, rate limit 1/hour, 기간 제약 `from_ts-to_ts` required, 최대 90일)**. 이유:
- 프로토타입 단계 — 복잡한 async job 인프라 과잉
- NDJSON 은 AWS Athena/BigQuery import, jq 파싱 모두 friendly
- WSOP LIVE `Staff App §AuditLog Export` 도 sync CSV 방식이지만 EBS 는 JSON 생태계 우위라 NDJSON 선택
- rate limit 은 운영 보호 최소선

**스펙 제안 초안**:
- `GET /api/v1/audit-logs/download?from_ts={iso}&to_ts={iso}&format=ndjson`
- `format=csv` 도 지원 (default=ndjson)
- RBAC: Admin only + rate limit (e.g. 1/hour per user)
- 기간: 최대 90일, from/to 필수
- Response headers: `Content-Type: application/x-ndjson`, `Content-Disposition: attachment; filename=audit_{from}_{to}.ndjson`

## 수락 기준

- [ ] 옵션 선택 (SG-008-b2 결정 후)
- [ ] b2 옵션 1 선택 시 본 SG 진행. b2 옵션 2/3 선택 시 본 SG 자동 종결
- [ ] 옵션 1 선택 시: Backend_HTTP.md 섹션 + rate limit 정책 Authentication.md 보강
- [ ] 옵션 2 선택 시: 별도 SG 승격 (async job infrastructure)
- [ ] 옵션 3 선택 시: team2 코드 삭제 PR


## Resolution

**2026-04-20: 옵션 1 채택** — Admin-only CSV streaming export

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: Admin-only CSV streaming export | team2 session |
