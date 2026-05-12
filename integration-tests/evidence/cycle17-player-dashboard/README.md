# Cycle 17 — Player Dashboard 4 핵심 필드 cascade Evidence

**날짜**: 2026-05-13
**Stream**: S2 (Lobby)
**Cascade**: `lobby-player-dashboard` (PR #393 카테고리 #1)

## 4 핵심 필드

| # | 필드 | 표시 형태 | 데이터 소스 |
|:-:|------|----------|------------|
| 1 | **Name** | `firstName lastName` 텍스트 | `players.first_name + last_name` |
| 2 | **Country** | 🇰🇷 + `KR` (국기 emoji + ISO Alpha-2) | `players.country_code` |
| 3 | **Position** | `D` / `SB` / `BB` / `UTG` / `MP` / `CO` / `HJ` chip | hand-time derived (Game Engine cascade) |
| 4 | **Stack** | `1,250,000` (콤마 separator) | `table_players.chips` (실시간) |

## 정본 명세

- `docs/2. Development/2.1 Frontend/Lobby/Overview.md` §Player 독립 레이어 — Cycle 17 cascade 박스
- Position chip 색상 매핑: D=amber, SB=blue, BB=indigo, 기타=grey
- 국기 emoji 변환: ISO Alpha-2 → Regional Indicator Symbol (`0x1F1E6 + (code - 0x41)`)

## Evidence

| 파일 | 출처 | 비고 |
|------|------|------|
| `01-player-dashboard-4fields.png` | Flutter widget golden test | 6 player mock (D/SB/BB/UTG/CO + null) |

### Widget golden test 명세

- 코드: `team1-frontend/test/features/players/players_dashboard_cycle17_test.dart`
- Golden 출력: `team1-frontend/test/features/players/goldens/cycle17-player-dashboard.png`
- 실행: `cd team1-frontend && flutter test test/features/players/players_dashboard_cycle17_test.dart --update-goldens`

### Playwright spec (live container 검증 대기)

- 코드: `integration-tests/playwright/tests/cycle17-player-dashboard.spec.ts`
- 사전 요구: `ebs-lobby-web` container 가 cycle 17 변경 포함 image 로 rebuild
- 현재 docker image 는 cycle 11 기반이라 미반영 → S11 cascade cycle 18 build 후 실행
- 실행: `cd integration-tests/playwright && npm test -- cycle17-player-dashboard.spec.ts`

## QA Pass Criteria §1 (3 단계 사용자 확인 절대 경로)

1. **Widget test PASS** (이번 PR) — flutter test 통과 + golden PNG 생성
2. **lobby-web image rebuild** — cycle 18 S11 build cascade 의존
3. **Playwright spec PASS** — live 컨테이너에서 4 필드 가시 확인 (사용자 최종 확인)

## Cascade 발신

- broker channel: `cascade:lobby-player-dashboard`
- 수신자: S3 (CC — player dashboard 연동), S8 (Engine — position derive), S11 (DevOps — image rebuild)

## 다음 단계 (carry-over)

- [ ] S7: BO API `players` 응답에 `position` 필드 추가 (현재 frontend optional null fallback)
- [ ] S8: Game Engine 이 hand-time position 을 BO 로 publish (event-sourcing)
- [ ] S11: lobby-web docker image rebuild → cycle 18
- [ ] S9: live Playwright spec 실행 + screenshot 갱신
