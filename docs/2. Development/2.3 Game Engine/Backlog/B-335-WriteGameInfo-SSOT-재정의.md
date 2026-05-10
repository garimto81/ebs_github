---
id: B-335
title: "NOTIFY-CCR-024 WriteGameInfo 22 필드 — Engine OutputEvent vs BO WS SSOT 재정의"
status: PENDING
priority: P1
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §6.4 (Engine SSOT 원칙)"
supersedes: "Backlog/_archived-2026-04/notify-ccr/NOTIFY-CCR-024-WriteGameInfo 22필드"
mirror: none
---

# [B-335] WriteGameInfo 22 필드 SSOT 재정의 (P1)

## 배경

Foundation §6.4 가 "Engine 응답이 게임 상태 SSOT. BO WS 는 audit 용 참고값" 을 확정.

NOTIFY-CCR-024 는 원래 API-05 WriteGameInfo 프로토콜의 22 필드 스키마 완결을 요청했으나, 이 22 필드가 어느 주체의 SSOT 인지 모호했다. Foundation §6.4 확정으로 이제 **기준 재정의 필요**:

- 22 필드 중 **게임 상태(hands/cards/pots/actionOn 등)** 는 → Engine OutputEvent SSOT
- 22 필드 중 **대회 메타(tournament meta, player stats, payout 등)** 는 → BO SSOT (WSOP LIVE sync 담당)

두 범주를 혼재시키면 SSOT 이분화가 깨진다. team3/team2 간 분할 재확정 필요.

## 수정 대상

1. **Conductor 조율**: team2 와 22 필드 분류 표 합의 (Conductor_Backlog 신규 항목 제안 필요)
2. **`APIs/Overlay_Output_Events.md`**: §1.4 "PokerGFX 스키마 대응" 표에 "Engine SSOT / BO SSOT" 컬럼 추가. 현재 "직접 계승 / 재명명 / 폐기" 3 등급만 있음
3. **팀2 계약 문서**: `docs/2. Development/2.2 Backend/APIs/` 의 WriteGameInfo/WebSocket 계약이 BO-SSOT 필드만 포함하도록 재정렬 (team2 결정)

## 수락 기준

- [ ] 22 필드가 Engine-SSOT / BO-SSOT 둘 중 하나로 명확히 분류
- [ ] Engine-SSOT 필드는 OutputEvent payload 로 커버 (§6.0 카탈로그와 대조)
- [ ] BO-SSOT 필드는 BO 문서에만 SSOT 정의
- [ ] Conductor 조율 record 생성 (team2 합의)

## 관련

- Foundation §6.3, §6.4
- Conductor_Backlog (신규 예상)
- 연동: B-332 (SSOT 명시)
