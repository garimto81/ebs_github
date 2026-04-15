---
title: CR-017-wsop-parity
owner: conductor
tier: internal
legacy-id: CCR-017
last-updated: 2026-04-15
---

# CCR-017: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team1 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2, team4 |
| **변경 대상** | `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md`<br/>`contracts/specs/BS-02-lobby/BS-02-03-table.md`<br/>`contracts/specs/BS-03-settings/BS-03-04-rules.md`<br/>`contracts/specs/BS-01-auth/BS-01-02-rbac.md`<br/>`contracts/data/DATA-02-entities.md` |
| **변경 유형** | modify |

## 변경 근거

WSOP LIVE Confluence 미러(`C:\claude\wsoplive\docs\confluence-mirror\`) 원본 표준과의 parity 확보. Lobby/Settings UI 기획서에는 선반영 완료(UI-01 §9, UI-03 §1.1 및 Rules 탭 주석)했으나, 현재 `contracts/` 에는 대응 enum/필드가 없어 Team 1 은 mock 데이터로만 동작 가능한 상태. 본 CCR 로 5 개 영역의 계약 확장을 제안한다.

## 적용된 파일

- `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md`
- `contracts/specs/BS-02-lobby/BS-02-03-table.md`
- `contracts/specs/BS-03-settings/BS-03-04-rules.md`
- `contracts/specs/BS-01-auth/BS-01-02-rbac.md`
- `contracts/data/DATA-02-entities.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260410-wsop-parity.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/60-event-flight-status-enum.http`, `integration-tests/scenarios/61-table-is-pause-constraint.http`, `integration-tests/scenarios/62-rbac-bit-flag.http`)
- [ ] git commit `[CCR-017] WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC`
