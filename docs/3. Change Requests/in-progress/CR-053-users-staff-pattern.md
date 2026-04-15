---
title: CR-053-users-staff-pattern
owner: conductor
tier: internal
legacy-id: CCR-053
last-updated: 2026-04-15
---

# CCR-053: Users 엔드포인트에 WSOP LIVE Staff 패턴 (Suspend/Lock/Download) 추가

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/api/API-01-backend-api.md`<br/>`contracts/data/DATA-02-entities.md`<br/>`contracts/data/DATA-04-db-schema.md`<br/>`contracts/specs/BS-01-auth/BS-01-auth.md` |
| **변경 유형** | add |
| **리스크 등급** | LOW |

## 변경 근거

WSOP LIVE Staff App(`GET/PUT /Series/{sId}/Staffs/*`, Page 1597768061) 은 유저 생명주기 관리를 Suspend/Lock 2-축 패턴으로 운영. EBS 현행 API-01 §5.2 는 CRUD 5종만 보유하여 운영 관점 상태 제어(일시 정지, 보안 잠금) 수단이 부재. 정식 전체 개발 단계에서 WSOP LIVE 운영 패턴에 정렬 필요. 기존 CRUD는 Phase 1 초기 provisioning + 긴급 수정 용도로 유지.

## 적용된 파일

- `contracts/api/API-01-backend-api.md`
- `contracts/data/DATA-02-entities.md`
- `contracts/data/DATA-04-db-schema.md`
- `contracts/specs/BS-01-auth/BS-01-auth.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-users-staff-pattern.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-053] Users 엔드포인트에 WSOP LIVE Staff 패턴 (Suspend/Lock/Download) 추가`
