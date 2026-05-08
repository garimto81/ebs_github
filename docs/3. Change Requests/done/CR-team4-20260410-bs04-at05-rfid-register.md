---
title: CR-team4-20260410-bs04-at05-rfid-register
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs04-at05-rfid-register
---

# CCR-DRAFT: BS-04 AT-05 RFID Register 화면 명세 추가

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2]
- **변경 대상 파일**: contracts/specs/BS-04-rfid/BS-04-05-register-screen.md, contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md
- **변경 유형**: add
- **변경 근거**: CCR-DRAFT-team4-20260410-bs05-at-screens에서 AT-05 RFID Register 화면을 "BS-04 참조"로 연결했으나, **BS-04에는 해당 화면의 행동 명세가 없다**. WSOP 원본 `EBS UI Design Action Tracker.md` §3.2 및 `team4-cc/ui-design/reference/action-tracker/analysis/`에 54장 카드 UID 매핑 등록 화면이 정의되어 있지만 계약에는 반영되지 않았다. 본 CCR은 이 공백을 메운다.

## 변경 요약

1. **BS-04-05-register-screen.md 신규**: AT-05 RFID Register 화면의 UI, 상태머신, 등록 플로우, 검증 규칙
2. **BS-04-01-deck-registration.md 수정**: 등록 흐름의 UI 부분을 BS-04-05 참조로 분리

## 변경 내용

### 1. BS-04-05-register-screen.md (신규 파일)

```markdown
# BS-04-05 RFID Register Screen (AT-05)

> **참조**: BS-04-01-deck-registration, BS-04-04-hal-contract, API-03-rfid-hal-interface, BS-05-00-overview §AT 화면 카탈로그

## 역할

AT-05 RFID Register는 **54장의 RFID 카드 UID를 카드 얼굴(Rank + Suit)과 매핑**하는
운영자 화면이다. 덱 교체 또는 신규 덱 도입 시 반드시 수행.

- 페르소나: Operator 이상 (Viewer는 접근 불가)
- 사용 시점: 방송 준비 단계, 덱 교체 시, 카드 손상 시 개별 재등록
- 54장 = 52장 + Joker 2장 (Joker는 제외 가능, BS-04-01 참조)

## 진입 경로

- AT-01 Main M-01 Toolbar → Menu → "Deck Registration"
- Lobby → Table → Settings → "Register Deck"
- 핫키: 미지정 (충돌 회피)

## 화면 구성

```
┌─────────────────────────────────────────────────────┐
│ ← Back                              RFID Register  │
│                                                    │
│ Deck Name: [__________]                            │
│ Progress: [██████░░░░░░] 18 / 54                   │
│                                                    │
│ ┌─────────────────────────────────────────────┐    │
│ │  4 × 13 Grid (수트 × 랭크)                    │    │
│ │  ♠ A K Q J T 9 8 7 6 5 4 3 2                 │    │
│ │  ♥ A K Q J T 9 8 7 6 5 4 3 2                 │    │
│ │  ♦ A K Q J T 9 8 7 6 5 4 3 2                 │    │
│ │  ♣ A K Q J T 9 8 7 6 5 4 3 2                 │    │
│ │  [Joker 1] [Joker 2]                         │    │
│ └─────────────────────────────────────────────┘    │
│                                                    │
│ Currently expecting: ♠ A                           │
│ [Skip] [Restart] [Save & Exit]                     │
└─────────────────────────────────────────────────────┘
```

## 등록 플로우

```
1. Deck Name 입력 (필수, 1~40자)
    │
2. [Start Registration] 버튼 클릭
    │
3. 시스템이 ♠A → ♠K → ... → ♣2 → Joker1 → Joker2 순서로 순차 요청
    │
    ├─ 운영자가 물리 카드를 RFID 리더에 탭
    │   ├─ 성공: 해당 카드 셀이 녹색으로 전환 + 다음 카드로 진행
    │   ├─ 이미 등록된 UID: "이미 등록된 UID입니다" 경고 + 같은 카드 유지
    │   └─ 리더 오류: "리더 통신 실패" 경고 + 재시도 버튼
    │
    ├─ [Skip] 버튼: 현재 카드 건너뛰기 (Joker 전용, 일반 카드는 Skip 금지)
    │
    └─ [Restart]: 모든 등록 초기화 후 처음부터
    │
4. 54장 등록 완료 시 "Registration Complete" 다이얼로그
    │
5. [Save & Exit]: Backend에 POST /decks 호출
    │
6. Lobby/CC에 `DeckRegistered` WebSocket 이벤트 전파
```

## 카드 셀 시각 상태

| 상태 | 색상 | 아이콘 |
|------|------|:------:|
| 대기 (Pending) | 회색 `#616161` | — |
| 현재 요청 중 (Expected) | 노란 펄스 `#FFD600` | ▶ |
| 등록 완료 (Registered) | 녹색 `#2E7D32` | ✓ |
| 건너뜀 (Skipped) | 어두운 회색 + 점선 | ⊘ |
| 오류 (Error) | 빨강 `#DD0000` | ✕ |

## 등록 순서

- **기본**: Spade → Heart → Diamond → Club 순
- **각 수트 내**: A → K → Q → J → T → 9 → ... → 2
- **Joker**: 일반 카드 완료 후 Joker 1, 2 (Skip 가능)

**대안 순서** (설정): `random` 모드 제공 — 어떤 카드든 탭하면 시스템이 자동 인식. 단, 순서 모드가 오탐을 낮춤(같은 UID의 잘못된 매핑 방지).

## 중복 UID 방지

- 각 UID는 **단일 카드에만 매핑**
- 이미 등록된 UID를 다시 탭하면 해당 카드 셀로 자동 포커스 이동 ("이 카드는 이미 ♠A로 등록됨. 수정하시겠습니까?")
- 수정 시 기존 매핑 제거 후 새 매핑

## 저장 검증

- Backend 전송 전 54장 모두 등록되었는지 확인 (Joker 제외 옵션 시 52장)
- 중복 UID 없는지 재검증
- Deck Name 중복 검사 (동일 테이블 내)

## 서버 프로토콜

| 동작 | API | Payload |
|------|-----|---------|
| 등록 저장 | POST /decks | { deck_name, cards: [{ uid, rank, suit }, ...] } |
| 목록 조회 | GET /decks | — |
| 활성 덱 설정 | PATCH /tables/{id}/active_deck | { deck_id } |
| WebSocket 알림 | API-05 `DeckRegistered` | { deck_id, deck_name, card_count } |

## 예외 처리

| 상황 | 동작 |
|------|------|
| RFID 리더 끊김 | 즉시 등록 중단, 경고 배너, 재연결 대기 |
| 중복 UID (다른 카드에 매핑됨) | 경고 + 기존 매핑 수정 여부 질문 |
| 운영자 실수로 잘못된 카드 탭 | 해당 셀 롱프레스 → "재등록" 선택 |
| 부분 등록 상태에서 [Back] | "진행 상황 저장 안 됨. 나가시겠습니까?" 경고 |
| Backend 저장 실패 | 로컬에 임시 저장, 재전송 재시도 |

## 권한

- Admin: 전체 기능
- Operator: 등록/수정 가능
- Viewer: 접근 불가

## 구현 위치

- `team4-cc/src/lib/features/rfid_register/screens/register_screen.dart`
- `team4-cc/src/lib/features/rfid_register/providers/registration_provider.dart`
- `team4-cc/src/lib/features/rfid_register/services/deck_validator.dart`

## 참조

- BS-04-01-deck-registration §등록 정책
- BS-04-04-hal-contract §IRfidReader 이벤트
- `Backend_HTTP.md` (legacy-id: API-01) §Decks API
- API-03-rfid-hal-interface §DeckRegistered 이벤트
- `WebSocket_Events.md` (legacy-id: API-05) §DeckRegistered (있으면 확인, 없으면 Cross-reference CCR 필요)
```

### 2. BS-04-01-deck-registration.md §UI 섹션 수정

```markdown
## UI (AT-05 Register Screen)

> **참조**: BS-04-05-register-screen.md

AT-05 화면의 상세 명세는 `BS-04-05-register-screen.md`로 이관. 본 문서는 등록
**정책**만 다룬다:

- 54장 full registration 또는 52장 (Joker 제외) 선택
- 등록 순서: 기본 sequential, 옵션 random
- 중복 UID 방지
- 저장 시 Backend POST /decks
```

## Diff 초안

```diff
+++ contracts/specs/BS-04-rfid/BS-04-05-register-screen.md (신규)
  (전체 내용 위 §1 참조)

 # contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md

-## UI
-
-등록 화면은 4×13 그리드 + Joker 2장...
-[기존 상세 UI 설명]
+## UI (AT-05 Register Screen)
+
+> 참조: BS-04-05-register-screen.md
+
+상세 UI 명세는 BS-04-05로 이관. 본 문서는 등록 정책만 다룬다:
+- 54장 / 52장 선택
+- sequential / random 순서
+- 중복 UID 방지
+- POST /decks 저장
```

## 영향 분석

### Team 2 (Backend)
- **영향**:
  - `POST /decks` API가 API-01에 이미 정의되어 있는지 확인
  - `DeckRegistered` WebSocket 이벤트가 API-05에 있는지 확인
  - 없을 경우 Team 2가 별도 Cross-reference CCR 제출
- **예상 리뷰 시간**: 1시간

### Team 4 (self)
- **영향**:
  - `team4-cc/src/lib/features/rfid_register/` 신규 모듈 구현
  - 54장 카드 Grid UI 구현
  - Mock RFID로 등록 플로우 E2E 테스트 (BS-04 Mock 우선 원칙)
  - 등록 상태 Riverpod Provider 구현
- **예상 작업 시간**:
  - 화면 UI: 8시간
  - 등록 로직: 6시간
  - Mock 통합 테스트: 4시간
  - 총 18시간

### 마이그레이션
- 없음 (신규 기능)

## 대안 검토

### Option 1: BS-04에 AT-05 명세 없이 Team 4 자유 구현
- **장점**: 계약 단순
- **단점**: 
  - CCR-016(BS-05 AT 화면 체계)이 AT-05를 "BS-04 참조"로 걸어둔 상태에서 BS-04에 해당 화면이 없음 → dangling reference
  - 구현자가 `team4-cc/ui-design/reference/action-tracker/` 복사본에만 의존
- **채택**: ❌

### Option 2: BS-04-05 신규 파일로 분리 (본 제안)
- **장점**: 
  - AT-05 화면 명세가 BS-04 네임스페이스 안에 위치 (관련 도메인과 일치)
  - BS-04-01은 정책, BS-04-05는 UI로 역할 분리
- **단점**: 파일 1개 추가
- **채택**: ✅

### Option 3: BS-04-01에 UI 상세 추가 (기존 파일 확장)
- **장점**: 파일 추가 없음
- **단점**: BS-04-01이 정책+UI+에러까지 모두 담게 되어 가독성 저하
- **채택**: ❌

## 검증 방법

### 1. 계약 참조 일관성
- [ ] CCR-016의 "AT-05 | RFID Register | Settings 또는 메뉴 | BS-04-rfid" 참조가 이제 BS-04-05를 가리킴
- [ ] BS-04-01과 BS-04-05 사이에 양방향 참조

### 2. API 일관성
- [ ] API-01에 POST /decks 존재 확인
- [ ] API-05에 DeckRegistered 이벤트 존재 확인 (없으면 Team 2 CCR 필요)

### 3. Mock 모드 검증
- [ ] MockRfidReader의 `autoRegisterDeck()` API로 54장 자동 등록 시뮬레이션
- [ ] 중복 UID 주입 시 경고 동작 확인
- [ ] 리더 끊김 주입 시 재연결 경로 확인

### 4. Real 모드 검증
- [ ] ST25R3911B 실제 하드웨어로 54장 순차 등록 E2E
- [ ] 등록 완료 시간 측정 (목표: 3분 이내 54장)

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (POST /decks, DeckRegistered 이벤트 존재 확인)
- [ ] Team 4 기술 검토 (Mock 및 Real 모드 구현 가능성)
