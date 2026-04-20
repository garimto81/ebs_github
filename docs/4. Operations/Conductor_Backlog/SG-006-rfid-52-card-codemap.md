---
id: SG-006
title: "RFID 52 카드 codemap — pre-registered deck + 초기 등록 절차"
type: spec_gap
status: RESOLVED
owner: conductor
decision_owners_notified: [team4]
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/2. Development/2.4 Command Center/RFID_Cards/
  - docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md
  - team4-cc/lib/features/command_center/services/  (rfid)
protocol: Spec_Gap_Triage
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, codemap + 초기 등록 절차 확정"
---
# SG-006 — RFID 52 카드 codemap

## 공백 서술

RFID HAL (API-03) 은 카드-UID 맵핑 인터페이스를 추상화하지만, 다음 "어떤 UID 가 어떤 카드인가" 의 사전 정의 절차가 문서화되지 않음:

- 카드 제조 시 UID 사전 등록 vs 현장 등록?
- 덱 단위 관리 (deck A, B, C) 여부
- 분실·손상 카드 처리 절차
- 운영자 UI 에서 "덱 등록" 플로우 미정의

Agent B 재분류로 UNKNOWN → FAIL (B).

## 결정 (default)

### 1. Deck 개념 도입

**채택**: **"Deck" = 52 카드의 사전등록된 집합** (고유 ID + 이름)

```sql
-- DATA-04 제안 (team2 세션 확정 위임)
CREATE TABLE decks (
  id UUID PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,  -- e.g., "Main Deck A", "Backup"
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'active',  -- 'active'|'retired'|'damaged'
  notes TEXT
);

CREATE TABLE deck_cards (
  deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
  card_code VARCHAR(3) NOT NULL,  -- 'AS', 'KH', '2C', ... (52종)
  rfid_uid VARCHAR(32) NOT NULL UNIQUE,  -- RFID tag UID (hex)
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  registered_by UUID REFERENCES users(id),
  PRIMARY KEY (deck_id, card_code)
);
```

### 2. 초기 등록 절차

**채택**: **3가지 모드 지원, Admin UI 에서 선택**

| 모드 | 절차 | 용도 |
|------|------|------|
| **A. 벌크 JSON 임포트** | `POST /decks/import` with JSON (52 rows) | 제조사가 사전 설정 파일 제공한 경우 |
| **B. 스캔 기반 (현장)** | Lobby Admin > Decks > New → 52회 RFID 리더에 카드 순차 제시 → UI 가 `card_code` (AS, KH, ...) 프롬프트 → UID 매핑 저장 | 일반적 운영. 52회 × 1초 ≈ 1분 |
| **C. 자동 순서 기반** | 카드를 고정 순서(AS→AH→AD→AC→KS→...) 로 제시 → UI 가 자동 `card_code` 할당 | 숙련 운영자 빠른 등록 (스킵 버튼 있음) |

### 3. 운영 시나리오 상태 머신

```
 [deck: none]
      │ new deck 생성
      ▼
 [deck: registering]  (< 52 cards)
      │ 52 등록 완료
      ▼
 [deck: active]       (게임 사용 가능)
      │ 카드 손상/분실 감지
      ▼
 [deck: partial]      (일부 카드 교체 필요)
      │ 전체 재등록 또는 retire
      ▼
 [deck: retired]
```

### 4. 손상·분실 카드 처리

- **1장 손상**: `deck_cards.rfid_uid` 교체 (새 카드 등록). `audit_events` 에 기록.
- **다량 손상**: deck 전체 retire + 새 deck 생성 권장
- **중복 UID 감지**: 스캔 시 기존 deck 에 이미 등록된 UID 면 즉시 경고 (cross-deck UID 유일성 enforce)

### 5. Mock 모드 (Demo Mode 연계)

SG-002 Demo Mode 와 통합:

- Mock deck `"Demo"` 을 시드 데이터로 자동 생성 (52 카드, UID = `DEMO_{CARD_CODE}`)
- Demo Mode 진입 시 MockRfidReader 가 이 deck 을 사용
- 실제 RFID 연결 시 Demo deck 은 자동 숨김

### 6. RFID UID 형식

RFID HAL (API-03) 의 ST25R3911B + ESP32 제조사 스펙:
- **UID 길이**: 7 bytes (14 hex chars) 또는 4 bytes (8 hex chars)
- **형식**: 대문자 hex, 콜론 없음 (예: `04A1B2C3D4E5F6`)
- **`deck_cards.rfid_uid`** 는 VARCHAR(32) 로 여유 (미래 확장)

## 영향 챕터 업데이트

- [x] 본 SG-006 문서
- [ ] `docs/2. Development/2.4 Command Center/RFID_Cards/Deck_Registration.md` 신규 (team4 세션)
- [ ] `docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` §Deck 섹션 추가 (team4)
- [ ] `docs/2. Development/2.2 Backend/Database/Schema.md` 에 `decks`, `deck_cards` 테이블 (team2)
- [ ] API-01 Backend_HTTP: `POST /decks`, `POST /decks/{id}/register`, `DELETE /decks/{id}` (team2)
- [ ] Lobby Admin UI: Decks 관리 화면 (team1)

## 수락 기준

- [ ] 3 등록 모드 중 최소 B (스캔 기반) 구현 + E2E 시연
- [ ] Demo deck 자동 생성 + Mock Mode 진입 시 사용 확인
- [ ] 손상 카드 교체 플로우 + audit_event 기록
- [ ] cross-deck UID 유일성 위반 시 에러 메시지 명확

## 재구현 가능성

- SG-006: **PASS**
- Roadmap "RFID 52 카드 codemap": UNKNOWN→FAIL → **PASS** (이 결정으로 해소)
