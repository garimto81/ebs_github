---
title: NOTIFY team1 Round2 — registration_changed · sitin_called 이벤트 신설
owner: team2
tier: internal
confluence-page-id: 3834118330
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3834118330/Registration
---

# NOTIFY — team1 Round 2 에서 요청된 WebSocket 이벤트 2종

**발신**: team1  
**수신**: team2  
**일자**: 2026-04-15  
**근거 PR**: #4 (`work/team1/spec-gaps-round2-20260415`)

## 요청 사항

`docs/2. Development/2.1 Frontend/Lobby/Registration.md §8 WebSocket 이벤트` 에서 명시한 2종 이벤트 신설.

### 1. `registration_changed`

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | string | `"registration_changed"` |
| `seq` | int | CCR-021 단조증가 |
| `flight_id` | int | 대상 Flight |
| `player_id` | string | 대상 Player |
| `action` | enum | `"registered"` / `"cancelled"` / `"refunded"` / `"noshow_marked"` / `"eliminated"` |
| `reason` | string? | Cancel/Refund 사유 |
| `registered_count` | int | 현재 Registered 수 (카운트 카드 갱신용) |

발행 트리거: `POST /tournaments/:id/register`, `DELETE /registrations/:id`, `POST /registrations/:id/noshow` 등.

### 2. `sitin_called`

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | string | `"sitin_called"` |
| `seq` | int | — |
| `flight_id` | int | — |
| `player_id` | string | 호출 대상 |
| `table_id` | string | 배정 테이블 |
| `seat_no` | int | 배정 좌석 |
| `called_at` | string | ISO 시각 |
| `timeout_sec` | int | 응답 대기 시간 (기본 300 = 5분) |

발행 트리거: Auto Seating 에서 빈 자리 발생 시, 또는 TD 수동 호출 시.

## 클라이언트 처리

`Engineering.md §5.4 이벤트 구독 매트릭스` 추가 행:

| 이벤트 | 저장 store · 필드 | UI |
|--------|------------------|-----|
| `registration_changed` | `lobbyStore.registration[flight_id]` 목록 | Registration 탭 행 추가/삭제/상태 변경 |
| `sitin_called` | (알림만, 상태 저장 X) | Positive Toast "Player N 호출됨" |

## 액션

- [ ] team2: `WebSocket_Events.md §4.2` 에 이벤트 2종 명세 추가
- [ ] team2: Backend 구현 (Registration 상태 변경 훅)
- [ ] team1: 구현 시점 `Engineering.md §5.4` 에 추가 행 기록

## 참조

- `../../2.1 Frontend/Lobby/Registration.md §8`
