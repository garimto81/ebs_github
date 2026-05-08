---
title: Register Screen
owner: team4
tier: internal
legacy-id: BS-04-05
last-updated: 2026-04-15
---

# BS-04-05 RFID Register Screen (AT-05)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-05 RFID Register 화면 UI·FSM·등록 플로우 (CCR-026) |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — AT-05 Register Screen 은 v4.0 4 영역 위계 (StatusBar / TopStrip / PlayerGrid / ActionPanel) 외부 셋업 화면 (Reader Panel). StatusBar `[⚙]` 또는 메뉴에서 진입. 카드 등록 결과는 deck SSOT 에 저장되며 게임 진행 중 인식된 RFID 가 등록된 카드면 PlayerGrid SeatCell 행 6 에 face-down 표시. SSOT: `Command_Center_UI/Overview.md §3.0`. |

---

## 개요

AT-05 RFID Register는 **RFID 카드 UID를 카드 얼굴(Rank + Suit)과 매핑**하는 운영자 화면이다. 덱 교체, 신규 덱 도입, 카드 손상 시 개별 재등록에 사용된다. **Phase 1 은 52장 고정** (4 suits × 13 ranks). Joker 포함 덱은 **Phase 2 범위** 이며 현재 구현되지 않는다 (아래 §1 참조).

> **v4.0 컨텍스트** (2026-05-07): AT-05 화면은 v4.0 4 영역 위계 외부 셋업 화면 (Reader Panel). 진입 경로는 StatusBar `[⚙]` 또는 우측 메뉴. 본 화면 자체 layout 은 v1.x 셋업 화면이며 1×10 그리드 PlayerGrid 와 무관. 등록된 카드는 게임 진행 시 PlayerGrid SeatCell 행 6 (Hole cards) 에 face-down 으로 mapping.

> **참조**: `Deck_Registration.md` (legacy-id: BS-04-01) (정책), `BS-04-04-hal-contract` (IRfidReader 이벤트), `RFID_HAL_Interface.md` (legacy-id: API-03) (DeckRegistered 이벤트), `BS-05-00-overview §AT 화면 카탈로그` (AT-05 위치), `Command_Center_UI/Overview.md §3.0` (4 영역 위계).

---

## 1. 역할 & 페르소나

| 항목 | 내용 |
|------|------|
| **역할** | 덱의 52장을 순차적으로 RFID 리더에 탭하여 UID↔카드 매핑 |
| **페르소나** | Operator 이상 (Viewer 접근 불가) |
| **사용 시점** | 방송 준비 단계, 덱 교체 시, 카드 손상 시 개별 재등록 |
| **총 카드 수 (Phase 1)** | **52장** (4 suits × 13 ranks). Hold'em/PLO/Omaha/Razz 등 표준 포커에서는 Joker 미사용 |
| **Phase 2 (미구현)** | `include_jokers` 설정 옵션 도입 예정. ON 시 54장 (+ Joker 1, Joker 2). Phase 2 착수 시 `at_05_rfid_register_screen.dart:_buildDeck()` 에 옵션 분기 추가 + 아래 §3 레이아웃의 `[Joker 1] [Joker 2]` 셀 조건부 렌더 |

> **구현 기준 (Phase 1)**: `at_05_rfid_register_screen.dart:_buildDeck()` 이 52장 고정 생성. 옵션 설정 UI 는 Phase 2 에서 신설. 현재는 어떠한 Joker 관련 분기도 실행되지 않는다.

---

## 2. 진입 경로

- **AT-01 Main** → M-01 Toolbar → Menu → "Deck Registration"
- **Lobby** → Table 선택 → Settings → "Register Deck"
- **핫키**: 미지정 (운영 중 실수 방지)

---

## 3. 화면 레이아웃

```
┌─────────────────────────────────────────────────────┐
│ ← Back                              RFID Register   │
│                                                     │
│ Deck Name: [__________]                             │
│ Progress: [██████░░░░░░] 18 / 52                    │
│                                                     │
│ ┌─────────────────────────────────────────────┐     │
│ │  4 × 13 Grid (수트 × 랭크)                    │     │
│ │  ♠ A K Q J T 9 8 7 6 5 4 3 2                 │     │
│ │  ♥ A K Q J T 9 8 7 6 5 4 3 2                 │     │
│ │  ♦ A K Q J T 9 8 7 6 5 4 3 2                 │     │
│ │  ♣ A K Q J T 9 8 7 6 5 4 3 2                 │     │
│ │  (Phase 2: [Joker 1] [Joker 2] 셀 추가 예정) │     │
│ └─────────────────────────────────────────────┘     │
│                                                     │
│ Currently expecting: ♠ A                            │
│ [Skip] [Restart] [Save & Exit]                      │
└─────────────────────────────────────────────────────┘
```

---

## 4. 등록 플로우

```
1. Deck Name 입력 (필수, 1~40자)
   │
2. [Start Registration] 버튼 클릭
   │
3. 시스템이 ♠A → ♠K → ... → ♣2 순서로 순차 요청 (Phase 1 은 52장으로 종료. Phase 2 에서 Joker 1 → Joker 2 추가 예정)
   │
   ├─ 운영자가 물리 카드를 RFID 리더에 탭
   │   ├─ 성공 → 해당 셀 녹색 전환 + 다음 카드로 진행
   │   ├─ 이미 등록된 UID → "이미 등록된 UID입니다" 경고 + 같은 카드 유지
   │   └─ 리더 오류 → "리더 통신 실패" 경고 + 재시도 버튼
   │
   ├─ [Skip] 버튼 → 현재 카드 건너뛰기 (Joker 전용, 일반 카드 Skip 금지)
   │
   └─ [Restart] → 모든 등록 초기화
   │
4. 52장 등록 완료 → "Registration Complete" 다이얼로그 (Phase 2: 54장 옵션 지원 예정)
   │
5. [Save & Exit] → Backend POST /decks
   │
6. Lobby/CC에 DeckRegistered WebSocket 이벤트 전파
```

---

## 5. 카드 셀 시각 상태

| 상태 | 색상 | 아이콘 |
|------|:----:|:------:|
| **대기 (Pending)** | 회색 `#616161` | — |
| **현재 요청 중 (Expected)** | 노란 펄스 `#FFD600` | ▶ |
| **등록 완료 (Registered)** | 녹색 `#2E7D32` | ✓ |
| **건너뜀 (Skipped)** | 어두운 회색 + 점선 | ⊘ |
| **오류 (Error)** | 빨강 `#DD0000` | ✕ |

---

## 6. 등록 순서 규칙

- **기본 (sequential)**: Spade → Heart → Diamond → Club
- **각 수트 내**: A → K → Q → J → T → 9 → ... → 2
- **Joker**: 일반 카드 완료 후 Joker 1, 2 (Skip 가능)
- **대안 순서 (설정, `random` 모드)**: 어떤 카드든 탭하면 시스템이 자동 인식. 단, sequential이 오탐을 낮춤(동일 UID가 잘못된 카드에 매핑되는 사고 방지).

---

## 7. 중복 UID 방지

- 각 UID는 **단일 카드에만 매핑**
- 이미 등록된 UID를 다시 탭하면 해당 카드 셀로 자동 포커스 이동:
  > "이 카드는 이미 ♠A로 등록됨. 수정하시겠습니까?"
- 수정 시 기존 매핑 제거 후 새 매핑

---

## 8. 저장 검증

- Backend 전송 전 52장이 모두 등록되었는지 확인 (Phase 2: include_jokers 옵션 시 54장)
- 중복 UID 없는지 재검증
- Deck Name 중복 검사 (동일 테이블 내)

---

## 9. 서버 프로토콜

| 동작 | API | Payload |
|------|-----|---------|
| 등록 저장 | `POST /api/v1/decks` | `{ deck_name, cards: [{ uid, rank, suit }, ...] }` |
| 목록 조회 | `GET /api/v1/decks` | — |
| 활성 덱 설정 | `PATCH /api/v1/tables/{id}/active_deck` | `{ deck_id }` |
| WebSocket 알림 | API-05 `DeckRegistered` | `{ deck_id, deck_name, card_count }` |

---

## 10. 예외 처리

| 상황 | 동작 |
|------|------|
| RFID 리더 끊김 | 즉시 등록 중단, 경고 배너, 재연결 대기 (API-03 §9.4) |
| 중복 UID (다른 카드에 매핑됨) | 경고 + 기존 매핑 수정 여부 질문 |
| 운영자 실수로 잘못된 카드 탭 | 해당 셀 롱프레스 → "재등록" 선택 |
| 부분 등록 상태에서 [Back] | "진행 상황 저장 안 됨. 나가시겠습니까?" 경고 |
| Backend 저장 실패 | 로컬 임시 저장, 재전송 재시도 |
| 안테나 튜닝 실패 (API-03 §10) | "안테나 튜닝 실패 — 물리 환경 점검 필요" 배너 |

---

## 11. 권한 (RBAC)

| Role | 접근 | 편집 |
|------|:----:|:----:|
| Admin | ✓ | ✓ |
| Operator | ✓ | ✓ |
| Viewer | ✗ | — |

---

## 12. 구현 위치

- `team4-cc/src/lib/features/rfid_register/screens/register_screen.dart`
- `team4-cc/src/lib/features/rfid_register/providers/registration_provider.dart`
- `team4-cc/src/lib/features/rfid_register/services/deck_validator.dart`

---

## 13. 연관 문서

- `Deck_Registration.md` (legacy-id: BS-04-01) — 등록 정책
- `RFID_HAL.md` (legacy-id: BS-04-04) — IRfidReader 이벤트
- `Backend_HTTP.md` (legacy-id: API-01) — Decks API
- `RFID_HAL_Interface.md` (legacy-id: API-03) — DeckRegistered 이벤트, 연결 FSM (§9)
- `WebSocket_Events.md` (legacy-id: API-05) — DeckRegistered WebSocket
- `Overview.md` (legacy-id: BS-05-00) — AT-05 화면 위치
