---
title: CR-conductor-20260414-skin-updated-ws
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-conductor-20260414-skin-updated-ws
confluence-page-id: 3819078749
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078749/EBS+CR-conductor-20260414-skin-updated-ws
---

# CCR-DRAFT: API-05에 skin_updated WebSocket 이벤트 추가

- **제안팀**: conductor
- **제안일**: 2026-04-14
- **영향팀**: [team2, team4]
- **변경 대상 파일**: contracts/api/`WebSocket_Events.md` (legacy-id: API-05) (modify)
- **변경 유형**: modify
- **변경 근거**: CCR `ge-ownership-move`의 멀티 CC 동기화 결단(D11)에 따라, Activate 시 서버가 모든 CC/Overlay 인스턴스에 `skin_updated` 이벤트를 broadcast 해야 한다. 현재 API-05에는 해당 이벤트가 없다. Team 4 기존 CCR(`CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md §BS-08-05`)은 `SkinChanged` 이름을 사용하나, `*_updated` 명명 관습(WSOP parity, CCR-016)에 맞춰 `skin_updated`로 표준화. CCR-015 seq 단조증가 정책 준수.

## 변경 요약

API-05에 `skin_updated` 이벤트 서브타입 추가. Payload에 `skin_id`, `version`, `seq`, `transition_type` 포함. 기존 seq 정책(CCR-015) 준수.

## Diff 초안

### `WebSocket_Events.md` (legacy-id: API-05) 수정

```diff
 ## Events

 ### cc_event (channel)

 - **hand_evaluated**
   - ...
 - **player_action**
   - ...

+- **skin_updated**
+  - Trigger: Admin이 Lobby GE에서 `PUT /api/v1/skins/{id}/activate` 성공 시 (API-07)
+  - Consumer: CC/Overlay (Team 4)
+  - Payload:
+    ```json
+    {
+      "type": "skin_updated",
+      "seq": 42,
+      "payload": {
+        "skin_id": "sk_01HVQK...",
+        "version": 3,
+        "transition_type": "fade",
+        "broadcasted_at": "2026-04-14T10:30:00Z"
+      }
+    }
+    ```
+  - seq: 단조증가 (CCR-015)
+  - transition_type: BS-07-03 §5.2의 5종 enum 중 하나 (cut/fade/slide/dissolve/black)
+  - Action (Consumer): `GET /api/v1/skins/{skin_id}` → `.gfskin` bytes 로드 → BS-07-03 §3.1 로드 FSM 수행 → 기존 스킨과 transition_type에 따라 교체
+  - 로드 실패 시: BS-07-03 §4 폴백 스킨으로 전환
```

### Replay 엔드포인트 (CCR-015 기존 정책 재사용)

- `GET /api/v1/events/replay?from_seq=42&channel=cc_event` — 재연결 시 놓친 이벤트 조회
- CC/Overlay가 재시작 또는 network gap 후 `GET /api/v1/skins/active`를 먼저 호출하여 current active skin_id를 확인하고, `GET /events/replay`로 놓친 seq 재생

## 영향 분석

| 팀 | 영향 | 공수 |
|----|------|------|
| Team 2 | Activate 엔드포인트에서 WS broadcast 코드 추가, seq 증가 로직 | 0.5주 |
| Team 4 | `skin_updated` 이벤트 수신 핸들러 추가 (BS-07-03 §5 로드 FSM 재사용) | 0.25주 |

## 대안 검토

1. **REST 폴링**: CC가 주기적으로 `/skins/active` 호출. 단점: 지연, 대역폭. ❌
2. **SSE (Server-Sent Events)**: 단방향만. 기존 WS 인프라 있어서 불필요. ❌
3. **본 CCR (WebSocket event)**: 기존 API-05 인프라 재사용, 즉시성 확보. ✅

## 검증 방법

- Integration test `02-activate-triggers-reload.http`: PUT /activate → WS subscribe에서 `skin_updated` 단일 수신, seq 단조증가 검증
- Integration test `07-multi-cc-sync.http`: 2+ WS 클라이언트 동시 subscribe → 같은 seq 수신, 시간차 < 500ms

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 WS broadcast 인프라 확인
- [ ] Team 4 BS-07-03 §5 재사용 가능성 확인

## 참고 사항

- **선행 조건**: CCR `ge-api-spec` (API-07 PUT /activate 정의)
- **연관 CCR**: CCR-015 (seq 단조증가 정책), CCR-016 (WSOP parity 명명 관습)
- **Plan 파일**: `C:/Users/AidenKim/.claude/plans/floating-percolating-petal.md`
