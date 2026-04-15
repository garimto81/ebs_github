# CCR-036: BS-07 Security Delay (홀카드 공개 지연) 명세

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md`<br/>`contracts/api/API-04-overlay-output.md` |
| **변경 유형** | add |

## 변경 근거

라이브 포커 방송에서 **Security Delay**(방송 지연)는 치트 방지를 위한 필수 기능이다. 시청자(또는 공모자)가 실시간 방송을 보면서 플레이어와 통신하여 카드 정보를 전달할 수 없도록, 홀카드/액션을 **N초 지연 후** 방송에 표시한다. WSOP 원본(`EBS UI Design.md` §Delay)과 PokerGFX는 30~60초 지연을 기본으로 운영한다. 현재 API-04 Overlay Output에 출력 파이프라인이 정의되어 있지만 Security Delay 메커니즘이 없어 EBS가 프로덕션 방송에 사용될 수 없다. 본 CCR은 이 공백을 메운다.

## 적용된 파일

- `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md`
- `contracts/api/API-04-overlay-output.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs07-security-delay.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/40-overlay-security-delay.http`)
- [ ] git commit `[CCR-036] BS-07 Security Delay (홀카드 공개 지연) 명세`
