---
title: CR-023-api05-messagepack
owner: conductor
tier: internal
legacy-id: CCR-023
last-updated: 2026-04-15
---

# CCR-023: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/api/API-05-websocket-events.md` |
| **변경 유형** | modify |

## 변경 근거

현재 API-05는 모든 WebSocket 메시지를 **JSON envelope** 형식으로 정의한다. 그러나 WSOP LIVE 프로덕션 앱(Fatima.app)은 **SignalR + MessagePack**을 사용하여 PayLoad를 30~50% 압축하고 있다(출처: `wsoplive/.../Mobile-Dev/자료조사/Flutter(Riverpod) + SignalR(MessagePack) 연동.md`). EBS가 JSON을 고수하면 (1) 초당 수십 이벤트 발생 시 대역폭 부담, (2) 조직 내 검증된 MessagePack 라이브러리 Fork 자산 재사용 실패, (3) 향후 WSOP+ 통합 시 프로토콜 변환 레이어 필요라는 비용이 발생한다. 본 CCR은 SignalR 전환까지는 가지 않더라도 **JSON의 대안으로 MessagePack 직렬화를 선택 가능하게** 만드는 최소 변경을 제안한다 (Option C: MessagePack 채택, SignalR 미채택 타협안).

## 적용된 파일

- `contracts/api/API-05-websocket-events.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-api05-messagepack.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-023] API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)`
