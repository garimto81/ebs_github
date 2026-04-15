# CCR-035: BS-07 Overlay Layer 1/2/3 경계 및 자동화 범위 명시

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2, team3 |
| **변경 대상** | `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md`<br/>`contracts/specs/BS-07-overlay/BS-07-00-overview.md` |
| **변경 유형** | add |

## 변경 근거

현재 BS-07-00-overview.md §3에 "EBS Layer 1 — Overlay 그래픽 8종"이 정의되어 있으나, **Layer 2와 Layer 3의 경계**가 계약 레벨에 명시되지 않았다. Foundation PRD Ch.6를 참조만 하는 상태. EBS Core 정의(v41.0.0)에 따르면 "EBS=Layer 1만 책임, Layer 2/3는 외부 팀 담당"이 핵심 원칙이지만, BS-07 계약 내에 명시되지 않아 Team 2/3/4가 구현 범위를 혼동할 위험이 있다. 또한 Layer 1 8종 중 일부(Action Badge, Position)는 "반자동"으로 표시되어 운영자 개입 시점이 불명확하다. 본 CCR은 Layer 경계와 자동화 정도를 계약에 확정한다.

## 적용된 파일

- `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md`
- `contracts/specs/BS-07-overlay/BS-07-00-overview.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs07-layer-boundary.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2, team3) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-035] BS-07 Overlay Layer 1/2/3 경계 및 자동화 범위 명시`
