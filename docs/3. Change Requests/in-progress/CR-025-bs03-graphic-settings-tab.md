# CCR-025: BS-03-02 Graphic Settings Tab 세부화 (team4 담당 영역)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-03-settings/BS-03-02-gfx.md` |
| **변경 유형** | modify |

## 변경 근거

`team4-cc/CLAUDE.md` §계약 참조에 "BS-03 Settings | Overlay/Skin 탭 (시각 설정 부분)"이 Team 4의 읽기 참조 대상으로 명시되어 있지만, 실제 BS-03-02-gfx.md의 Graphic Settings 탭 내용이 Team 4 관점(Overlay/Skin 편집 흐름)에서 어떤 필드를 설정할 수 있어야 하는지 불명확하다. CCR-025(BS-08 Graphic Editor 신규)와 CCR-024(BS-07 CC-Overlay 시각 일관성)에서 정의한 시각 자산(포지션 마커 색상, 좌석 배경, action-glow, Skin 팔레트 등)이 BS-03-02 Settings 탭에서 어떻게 노출되고 수정되는지 경계가 없어 Team 1이 Lobby Settings 구현 시 참조할 계약이 부족하다. 본 CCR은 BS-03-02의 **Graphic Settings 섹션을 team4 관점에서 확장**한다.

## 적용된 파일

- `contracts/specs/BS-03-settings/BS-03-02-gfx.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs03-graphic-settings-tab.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-025] BS-03-02 Graphic Settings Tab 세부화 (team4 담당 영역)`
