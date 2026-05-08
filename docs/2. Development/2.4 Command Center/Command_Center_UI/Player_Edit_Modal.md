---
title: Player Edit Modal
owner: team4
tier: internal
legacy-id: BS-05-09
last-updated: 2026-04-15
---

# BS-05-09 Player Edit Modal (AT-07)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-07 Player Edit 모달 — 좌석별 플레이어 정보 수정 (CCR-028) |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — 1×10 그리드 PlayerGrid 의 SeatCell 9 행 (행 4 Country / 행 5 Name 등) 인라인 편집 진입점이 본 모달. 트리거: PlayerGrid 셀 내 행 4·5·7·8 tap → AT-07 모달 open. SSOT: `Overview.md §3.0`, `Seat_Management.md §"v4.0 1×10 그리드 + SeatCell 9 행"`. |

---

## 개요

AT-07은 특정 좌석의 플레이어 정보(이름, 국적, 스택, 이미지 등)를 편집하는 모달이다. 핸드 진행 중에도 일부 필드는 실시간 편집 가능하다.

> **v4.0 컨텍스트** (2026-05-07): 본 모달은 1×10 가로 그리드 PlayerGrid 의 SeatCell 9 행 stacked 구조 (S1~S10) 에서 인라인 편집 행 (4 Country / 5 Name / 7 Stack / 8 Bet) tap 시 진입한다. 4 영역 위계 (StatusBar / TopStrip / PlayerGrid / ActionPanel) 중 PlayerGrid 영역의 셀 단위 편집 진입점.

> **참조**: `BS-05-00 §6 AT 카탈로그`, `Seat_Management.md` (legacy-id: BS-05-03), `Overview.md §3.0` (4 영역 위계).

---

## 1. 편집 가능 필드

| 필드 | 타입 | 편집 가능 시점 | 실시간 반영 |
|------|------|----------------|:-----------:|
| `player_name` | string (1~40자) | 항상 | ✓ |
| `player_id` | string | 항상 (Lobby DB 검색 연동) | ✓ |
| `nationality` | ISO 3166-1 alpha-3 | 항상 | ✓ |
| `stack` | int | IDLE 또는 PAUSED에서만 | — |
| `avatar_url` | string (URL) | 항상 | ✓ |
| `vip_level` | enum | 항상 | ✓ |
| `seat_status` | enum (active/sitting_out/eliminated) | IDLE에서만 | — |

---

## 2. 진입 경로

- **AT-01 M-05 좌석 카드 행** → 좌석 **롱프레스** → Context menu → "Edit Player"
- **우클릭** (마우스/트랙패드) → Context menu
- 키보드 단축키: 미지정

---

## 3. UI

- 모달 크기: **480 × auto**
- 섹션: `Identity` / `Finance` / `Appearance`
- 하단 버튼: `Save` / `Cancel` / `Reset Seat` (좌석 Clear)

---

## 4. 핸드 진행 중 제한

핸드가 진행 중이면 `stack` 및 `seat_status` 필드는 **회색 처리**된다. 이름·국적·아바타는 즉시 편집 가능하며 `PlayerUpdated` WebSocket 이벤트로 Lobby와 Overlay에 방송된다.

---

## 5. Sitting Out 즉시/지연 정책 (CCR-031, W8 해소)

| 현재 HandFSM | 토글 | 적용 시점 |
|--------------|------|-----------|
| IDLE | Sitting Out ON | **즉시** 적용 (현재 핸드 참여 제외) |
| IDLE | Sitting Out OFF | **즉시** 적용 |
| PRE_FLOP ~ HAND_COMPLETE | Sitting Out ON | **다음 핸드** 적용 (현재 핸드는 유지) |
| PRE_FLOP ~ HAND_COMPLETE | Sitting Out OFF | **다음 핸드** 적용 |

> **의도**: 핸드 중간 Sitting Out 전환이 `active_seats` 배열을 바꾸어 Engine 혼란을 유발하는 것을 방지.

---

## 6. 서버 프로토콜

| 동작 | API |
|------|-----|
| 플레이어 조회 | `GET /api/v1/tables/{id}/seats/{n}/player` |
| 플레이어 수정 | `PATCH /api/v1/tables/{id}/seats/{n}/player` |
| 좌석 Clear | `DELETE /api/v1/tables/{id}/seats/{n}/player` |
| WebSocket 알림 | `PlayerUpdated` (API-05 §5) |

---

## 7. RBAC

| Role | 조회 | 편집 (이름/국적/아바타) | 편집 (stack/status) |
|------|:----:|:----:|:----:|
| Admin | ✓ | ✓ | ✓ |
| Operator | ✓ | ✓ | ✓ (자기 할당 테이블만) |
| Viewer | ✓ | ✗ | ✗ |

---

## 8. 연관 문서

- `BS-05-00 §6` — AT 카탈로그
- `Seat_Management.md` (legacy-id: BS-05-03) — 좌석 FSM
- `API-05-websocket-events §5` — PlayerUpdated 이벤트
- `API-01-backend-api` — seats/player 엔드포인트
