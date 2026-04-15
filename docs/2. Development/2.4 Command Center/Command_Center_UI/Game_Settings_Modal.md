---
title: Game Settings Modal
owner: team4
tier: internal
legacy-id: BS-05-08
last-updated: 2026-04-15
---

# BS-05-08 Game Settings Modal (AT-06)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-06 Game Settings 모달 — CC 내부 즉시 편집 범위 (CCR-028, Option A) |

---

## 개요

AT-06은 **핸드 진행 중** 운영자가 즉시 변경해야 하는 게임 규칙을 편집하는 모달이다. BS-03 Settings Global과 의도적으로 **경계를 분리**하며, Lobby 경유 원격 변경이 방송 지연 원인이 되는 것을 방지한다.

> **참조**: `BS-05-00 §6 AT 카탈로그`, `BS-03-settings` (글로벌 설정과의 경계).

---

## 1. 범위 (Option A: 최소 채택)

| 필드 | 설명 | 편집 가능 시점 |
|------|------|----------------|
| `game_type` | Hold'em / PLO / Mix 등 | IDLE 상태에서만 |
| `blind_structure_id` | 블라인드 구조 전환 | IDLE 상태에서만 |
| `ante_override` | 앤티 금액 임시 조정 | IDLE 상태에서만 |
| `straddle_enabled_seats` | 좌석별 Straddle ON/OFF | 항상 가능 (다음 핸드 적용) |
| `allow_run_it_twice` | Run It Twice 허용 | IDLE 상태에서만 |
| `cap_bb_multiplier` | Cap Game BB 배수 (None = 무제한) | IDLE 상태에서만 |

### 1.1 범위 외 (BS-03 Settings Global 담당)

- 테이블 공통 설정 (테이블 이름, 좌석 수, 카메라 각도)
- 스킨/오버레이 시각 설정
- NDI/HDMI 출력 설정
- 사용자 계정 및 권한

---

## 2. UI

- 모달 크기: **600 × auto**
- 탭: `Game` / `Blinds` / `Rules`
- 하단 버튼: `Apply` / `Cancel`
- 핸드 진행 중 편집 불가 필드는 회색 + 툴팁 "Only editable in IDLE state"

---

## 3. 진입 경로

- M-01 Toolbar → Menu → "Game Settings"
- 키보드 단축키: 미지정

---

## 4. 상태별 동작

| TableFSM | HandFSM | 접근 | 편집 제한 |
|----------|---------|:----:|-----------|
| EMPTY / SETUP | IDLE | ✓ | 제한 없음 |
| LIVE | IDLE | ✓ | 제한 없음 |
| LIVE | PRE_FLOP ~ RIVER | ✓ | IDLE 전용 필드 회색 처리 |
| LIVE | SHOWDOWN / HAND_COMPLETE | ✓ | IDLE 전용 필드 회색 처리 |
| PAUSED | * | ✓ (읽기 전용) | Admin만 편집 가능 |
| CLOSED | * | ✗ | — |

---

## 5. 서버 프로토콜

| 동작 | API |
|------|-----|
| 현재 설정 조회 | `GET /api/v1/tables/{id}/game-settings` |
| 설정 적용 | `PATCH /api/v1/tables/{id}/game-settings` |
| WebSocket 알림 | `ConfigChanged` (API-05 §5) |

---

## 6. 검증

- `game_type` 변경 → 다음 `WriteGameInfo` 프로토콜에 반영
- `blind_structure_id` 변경 → DATA-04 Blind 구조 참조 일관성 확인
- `straddle_enabled_seats` → `active_seats` 부분집합

---

## 7. RBAC

| Role | 접근 | 편집 |
|------|:----:|:----:|
| Admin | ✓ | ✓ |
| Operator | ✓ | ✓ (자기 할당 테이블만) |
| Viewer | ✗ | — |

---

## 8. 연관 문서

- `BS-05-00 §6` — AT 카탈로그
- `BS-03-settings` — 글로벌 설정
- `API-05-websocket-events §9` — WriteGameInfo 프로토콜
- `API-01-backend-api` — REST 엔드포인트
