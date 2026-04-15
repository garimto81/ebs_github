---
title: CR-049-blindstructure-endpoints
owner: conductor
tier: internal
legacy-id: CCR-049
last-updated: 2026-04-15
---

# CCR-049: BlindStructure 관리 엔드포인트 추가 (WSOP LIVE 정렬)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team3 |
| **변경 대상** | `contracts/api/API-01-backend-api.md`<br/>`contracts/data/DATA-02-entities.md` |
| **변경 유형** | add |
| **리스크 등급** | MEDIUM |

## 변경 근거

WSOP LIVE Staff App(Page 1603666061)은 BlindStructure 템플릿 기반 CRUD + Flight별 적용 엔드포인트 8종을 제공. EBS API-01에 BlindStructure 편집 API 부재. 정식 전체 개발에서 WSOP LIVE 패턴 준거.

## 적용된 파일

- `contracts/api/API-01-backend-api.md`
- `contracts/data/DATA-02-entities.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-blindstructure-endpoints.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team3) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-049] BlindStructure 관리 엔드포인트 추가 (WSOP LIVE 정렬)`
