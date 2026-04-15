---
title: CR-056-deadlink-cleanup
owner: conductor
tier: internal
legacy-id: CCR-056
last-updated: 2026-04-15
---

# CCR-056: 외부 파일의 구 contracts/specs/BS-0X-* 경로 dead link 일괄 정리

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team1 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team4 |
| **변경 대상** | `contracts/api/API-07-graphic-editor.md` |
| **변경 유형** | modify |
| **리스크 등급** | HIGH |

## 변경 근거

team-policy v4 이관(BS-02/03/08 → team1-frontend/specs/)에도 불구하고 contracts/api/API-07-graphic-editor.md 가 구 경로 `contracts/specs/BS-08-graphic-editor/` 를 하드코딩 중. dead link. 원안 draft 는 docs/backlog, integration-tests, team4-cc 도 포함했으나 CCR 시스템은 contracts/ 범위 전용이므로 contracts 타겟 1건으로 축소. 그 외 경로는 각 팀/Conductor 별도 세션에서 직접 편집.

## 적용된 파일

- `contracts/api/API-07-graphic-editor.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260414-deadlink-cleanup.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-056] 외부 파일의 구 contracts/specs/BS-0X-* 경로 dead link 일괄 정리`
