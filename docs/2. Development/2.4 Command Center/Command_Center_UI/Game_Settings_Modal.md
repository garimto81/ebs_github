---
title: Game Settings — Rules 탭 상세 규격
owner: team4
tier: internal
legacy-id: BS-05-08
last-updated: 2026-04-16
---

# BS-05-08 Game Settings — Table Settings Rules 탭 상세 규격

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | AT-06 Game Settings 모달 — CC 내부 즉시 편집 범위 (CCR-028, Option A) |
| 2026-04-15 | 용어/접근 설계 명확화 | 3축 정의 + 카테고리 A/B/C + 섹션 조건부 렌더링 |
| 2026-04-16 | Settings 통합 | 독립 모달(AT-06) → Table Settings Rules 탭으로 통합. 본 문서는 Rules 탭의 **상세 규격 부록**으로 재정의 |

---

## 개요

이 문서는 `Settings.md §Rules 탭 상세` 의 **구현 상세 규격** (필드별 검증 규칙, UI 컴포넌트, 에러 메시지, 조건부 렌더링 시나리오)을 정의한다.

**진입 경로**: CC Toolbar `[⚙]` 버튼 → Table Settings → **Rules 탭**

> **참조**: `Settings.md §Rules 탭 상세`, `BS-05-00 §6 AT 카탈로그`
>
> **변경 이력**: 2026-04-16 이전에는 독립 모달(AT-06, Toolbar Menu → Game Settings)로 정의됨. Settings.md 4단 스코프 체계와 중복 진입 경로 발생 → Rules 탭으로 통합.

## 0. 핵심 용어 정의

본 문서의 모든 규칙은 아래 3개 축의 조합으로 정의된다. 이 정의는 CC 전체에 공통 (다른 문서에서도 같은 의미로 사용).

| 용어 | 조건 | 예시 |
|------|------|------|
| **핸드 간격 (idle between hands)** | `HandFSM ∈ {IDLE, HAND_COMPLETE}` **AND** 다음 `NewHand` 트리거가 아직 발동되지 않음 | 130번 핸드 종료 직후 ~ 131번 핸드 NewHand 클릭 전 구간 |
| **핸드 진행 중 (hand in progress)** | `HandFSM ∈ {SETUP_HAND, PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN, RUN_IT_MULTIPLE}` | 131번 핸드 NewHand 이후 HAND_COMPLETE 도달 전까지 |
| **테이블 라이브 (table live)** | `TableFSM == LIVE` | 별개 축. HandFSM 과 무관하게 판정 |

> **중요**: "IDLE 전용" 이라는 종전 표현은 폐기한다. 아래 §4 의 카테고리 A 필드는 **핸드 진행 중 그 필드에 도달하는 조작 경로 자체가 존재해서는 안 된다** — disabled 상태로라도 노출하지 않는다.

---

## 1. 범위 (Option A: 최소 채택)

각 필드는 §0 3 축 중 **편집 가능 시점** 에 따라 카테고리 A/B/C 로 분류된다.

| 필드 | 설명 | 카테고리 | 편집 가능 시점 |
|------|------|:--------:|----------------|
| `game_type` | Hold'em / PLO / Mix 등 | **A** | 핸드 간격 only |
| `blind_structure_id` | 블라인드 구조 전환 | **A** | 핸드 간격 only |
| `ante_override` | 앤티 금액 임시 조정 | **A** | 핸드 간격 only |
| `straddle_enabled_seats` | 좌석별 Straddle ON/OFF | **B** | 항상 가능 (다음 핸드부터 적용) |
| `allow_run_it_twice` | Run It Twice 허용 | **A** | 핸드 간격 only |
| `cap_bb_multiplier` | Cap Game BB 배수 (None = 무제한) | **A** | 핸드 간격 only |

### 1.1 범위 외 (BS-03 Settings Global 담당)

### 1.1 범위 외 (BS-03 Settings Global 담당)

- 테이블 공통 설정 (테이블 이름, 좌석 수, 카메라 각도)
- 스킨/오버레이 시각 설정
- NDI/HDMI 출력 설정
- 사용자 계정 및 권한

### 1.2 카테고리 정의 (용어 재활용)

| 카테고리 | 의미 | 편집 가능 시점 | UI 접근 정책 |
|:-------:|------|----------------|-------------|
| **A. hand-boundary-only** | 진행 중 변경하면 현재 hand 의 판정/팟/카드 수 전제가 깨지는 필드 | **핸드 간격** 에만 | 핸드 진행 중 **섹션 자체 숨김** (disabled 노출 금지) |
| **B. live-adjustable** | 현재 hand 에는 영향 없고 다음 hand 부터 적용되는 필드 | 상시 | 항상 노출. 저장 시 "다음 핸드부터 적용" 명시 |
| **C. setup-only** | 테이블이 LIVE 되기 전에만 가능 | `TableFSM != LIVE` 일 때만 | `LIVE` 이후 섹션 숨김 |

---

## 2. UI

- 모달 크기: **600 × auto**
- 탭: `Game` / `Blinds` / `Rules`
- 하단 버튼: `Apply` / `Cancel`

### 2.1 섹션 조건부 렌더링 규약

모달은 렌더링 시 `HandFSM` · `TableFSM` 을 watch 하여 다음 규칙으로 구성한다. **disabled(회색) 노출은 금지** — 해당 필드에 도달할 조작 경로 자체가 없어야 한다.

```
if handInProgress:
    카테고리 A 필드가 속한 섹션은 렌더링 건너뜀.
    해당 자리에 info placeholder: "현재 {hand_number}번 핸드 진행 중. 핸드 종료 후 변경 가능."
    키보드 포커스도 해당 섹션 entry 에 진입 불가 (FocusNode.canRequestFocus = false)
if tableFsm != LIVE:
    카테고리 C 필드 섹션 노출. LIVE 이후 숨김.
카테고리 B 필드:
    항상 노출. 저장 시 "다음 핸드부터 적용" 라벨.
```

### 2.2 시나리오 예시

1. 130번 핸드 `HAND_COMPLETE` 도달 → 운영자가 Menu → Game Settings 열음 → `핸드 간격` 이므로 **카테고리 A 섹션 전체 노출** → `game_type` 을 Hold'em → Razz 변경 → Apply → 131번 NewHand 시 Razz 로 시작.
2. 131번 핸드 `FLOP` 에서 운영자가 실수로 Menu → Game Settings 열음 → `핸드 진행 중` 이므로 `Game` 탭의 카테고리 A 섹션은 placeholder 로 치환되어 **접근 불가**. `Rules` 탭의 `straddle_enabled_seats` (B) 만 편집 가능.

### 2.3 안전 장치 (서버)

UI 차단에도 불구하고 REST `PATCH /api/v1/tables/{id}/game-settings` 요청이 카테고리 A 필드를 핸드 진행 중에 변경하려 하면 서버가 `409 Conflict` + `{"error": "hand_in_progress", "field": "game_type"}` 반환. CC 는 이 응답을 받으면 Sentry 로그 + "상태 불일치 감지됨" 토스트 (본래 도달해선 안 될 경로).

---

## 3. 진입 경로

- M-01 Toolbar → Menu → "Game Settings"
- 키보드 단축키: 미지정

---

## 4. 상태별 동작

§0 용어와 §1.2 카테고리를 기준으로 판정한다.

| TableFSM | 핸드 간격 여부 | 접근 | 카테고리 A | 카테고리 B | 카테고리 C |
|----------|:-------------:|:----:|:---------:|:---------:|:---------:|
| EMPTY / SETUP | — (hand 없음) | ✓ | ✓ | ✓ | ✓ |
| LIVE | 간격 | ✓ | ✓ | ✓ | ✗ (LIVE 이후 숨김) |
| LIVE | 진행 중 | ✓ | ✗ (섹션 숨김) | ✓ | ✗ |
| PAUSED | * | ✓ (읽기 전용) | ✗ | ✗ | ✗ — Admin만 편집 |
| CLOSED | * | ✗ | — | — | — |

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
