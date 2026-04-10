# CCR-032: BS-05 시각/동작 명세 구체화 (카드 슬롯 FSM, 포지션 색상, 애니메이션)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-03-seat-management.md`<br/>`contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md`<br/>`contracts/specs/BS-07-overlay/BS-07-02-animations.md` |
| **변경 유형** | modify |

## 변경 근거

WSOP 원본(`EBS UI Design Action Tracker.md` §2.2, §5, §6)에 정의된 시각/동작 규격이 현재 BS-05에 누락되어 구현자마다 다르게 해석될 위험. 특히 카드 슬롯 5상태 FSM은 RFID UX의 핵심이며, 포지션 마커 색상은 라이브 방송 시청자 식별에 직접 영향한다. 또한 이전 critic 분석의 W10(RFID 5초 대기 의미 불명확)을 해소한다.

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-03-seat-management.md`
- `contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md`
- `contracts/specs/BS-07-overlay/BS-07-02-animations.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-visual-spec.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-032] BS-05 시각/동작 명세 구체화 (카드 슬롯 FSM, 포지션 색상, 애니메이션)`
