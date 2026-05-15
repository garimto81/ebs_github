---
title: CR-030-bs05-multi-table-ops
owner: conductor
tier: internal
legacy-id: CCR-030
last-updated: 2026-04-15
confluence-page-id: 3819275464
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275464/EBS+CR-030-bs05-multi-table-ops
mirror: none
---

# CCR-030: BS-05 Multi-Table 운영자 시나리오 명시

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md`<br/>`contracts/specs/BS-05-command-center/BS-05-00-overview.md` |
| **변경 유형** | add |

## 변경 근거

이전 critic 분석에서 W7(다중 테이블 운영자 시나리오 없음)으로 식별된 공백. WSOP LIVE 등 대형 대회는 **1명의 운영자가 여러 테이블을 동시에 관리**하는 경우가 일반적이지만, 현재 BS-05는 "1 CC = 1 Table = 1 Overlay"의 1:1:1 대응만 정의하고 운영자 측면의 다중 테이블 관리는 미정의다. 이로 인해 (1) 운영자가 다중 CC 인스턴스를 어떻게 전환하는지, (2) 핸드 충돌 시 어느 테이블을 우선하는지, (3) 키보드 단축키 포커스 처리 등이 불명확하다. 본 CCR은 이 공백을 명시적으로 해소한다.

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md`
- `contracts/specs/BS-05-command-center/BS-05-00-overview.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-multi-table-ops.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-030] BS-05 Multi-Table 운영자 시나리오 명시`
