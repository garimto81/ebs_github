---
title: Display
owner: team1
tier: internal
legacy-id: BS-03-03
last-updated: 2026-04-20
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "SG-003 §Tab 3 Display. theme/density/font_size_scale/timezone/show_debug_overlay"
sg_reference: SG-003
scope: user
---

# BS-03-03 Display — 수치 표시 형식

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Console PRD v9.7 §2.8b 기반 — Blinds/Precision/Mode 3서브그룹, 17 컨트롤 |

---

## 개요

Display 섹션은 Settings의 세 번째 탭으로, 오버레이에 표시되는 **수치 형식**을 영역별로 제어한다. 3-Column 구조: Blinds(블라인드 표시/통화) → Precision(영역별 정밀도) → Mode(Amount/BB 전환). PokerGFX GFX 3 탭의 Display 설정을 계승한다.

> 참조: Console PRD v9.7 §2.8b Display 탭

---

## 1. 컨트롤 목록

### 1.1 Blinds 서브그룹 (ID 1~6)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 1 | Blinds (col) | — | — | 서브그룹 헤더 | — |
| 2 | Show Blinds | Select | When Changed | 블라인드 표시 조건 (Always/When Changed/Never) | Blinds Graphic 표시/숨김 |
| 3 | Show Hand # | Switch | OFF | 핸드 번호 동시 표시 | Blinds Graphic에 핸드# 추가 |
| 4 | Currency Symbol | Input | $ | 통화 기호 (₩, €, £ 등 자유 입력) | 모든 금액 영역 일괄 적용 |
| 5 | Trailing Currency | Switch | OFF | 통화 기호 후치 (ON: "100₩", OFF: "₩100") | 금액 표시 형식 |
| 6 | Divide by 100 | Switch | OFF | 센트→달러 변환 (전체 금액 /100) | 모든 금액 영역 일괄 적용 |

**동작**:

- **Show Blinds**: "Always"는 항상 표시. "When Changed"는 블라인드 레벨 변경 직후 일시적 표시 후 자동 숨김 (토너먼트 레벨 변경 시각 알림). "Never"는 완전 숨김.
- **Currency Symbol**: Blinds Graphic, Board Graphic(팟), Leaderboard(칩카운트) 등 **모든 금액 영역**에 일괄 적용.
- **Divide by 100**: 내부 센트 단위 값을 달러 단위로 변환. Blinds + Board + Leaderboard 세 영역에 동시 적용.

### 1.2 Precision 서브그룹 (ID 7~12)

5개 영역의 수치 정밀도를 독립적으로 제어한다.

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 7 | Precision (col) | — | — | 서브그룹 헤더 | — |
| 8 | Leaderboard Precision | Select | Exact Amount | 리더보드 칩카운트 정밀도 | 리더보드 수치 형식 |
| 9 | Player Stack Precision | Select | Smart k-M | Player Graphic 스택 정밀도 | 플레이어 칩 표시 |
| 10 | Player Action Precision | Select | Smart Amount | 액션 금액 정밀도 | BET/RAISE 표시 |
| 11 | Blinds Precision | Select | Smart Amount | Blinds Graphic 수치 정밀도 | 블라인드 표시 |
| 12 | Pot Precision | Select | Smart Amount | Board Graphic 팟 정밀도 | 팟 표시 |

**정밀도 옵션**:

| 옵션 | 설명 | 예시 |
|------|------|------|
| **Exact Amount** | 천 단위 쉼표 전체 금액 | 1,234,567 |
| **Smart k-M** | 1,000+ → k, 1,000,000+ → M | 1.2k, 1.2M |
| **Smart Amount** | 금액 크기에 따라 소수점 자동 조절 | 작은 금액=정확, 큰 금액=반올림 |
| **Divide** | 지정 값으로 나눠 표시 | 설정값 기반 |

> 5개 영역이 독립 설정이므로 리더보드는 정확 금액, 액션은 축약 등 혼합 가능.

### 1.3 Mode 서브그룹 (ID 13~17)

금액 표시를 절대 금액(Amount) 또는 Big Blind 배수(BB)로 전환한다.

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 13 | Mode (col) | — | — | 서브그룹 헤더 | — |
| 14 | Chipcounts Mode | Select | Amount | 칩카운트 표시 단위 (Amount/BB) | Player Graphic 칩 표시 |
| 15 | Pot Mode | Select | Amount | 팟 표시 단위 (Amount/BB) | Board Graphic 팟 표시 |
| 16 | Bets Mode | Select | Amount | 베팅 표시 단위 (Amount/BB) | 액션 금액 표시 |
| 17 | Display Side Pot | Switch | ON | 사이드팟 금액 별도 표시 | 보드 영역 사이드팟 |

**동작**:

- 3개 Mode 컨트롤은 각각 독립적으로 Amount/BB 전환 가능.
- BB 모드 활성화 시 해당 영역의 수치가 현재 BB 기준 배수로 표시 (예: 스택 50,000 / BB 1,000 → "50 BB").
- BB 모드 시 해당 영역의 Precision 설정(8~12)은 무시, Currency Symbol도 "BB" 접미사로 자동 대체.
- 토너먼트 방송에서 시청자가 상대적 칩량을 직관적으로 비교하는 표준 방식.

---

## 2. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 변경 | Admin 수동 | Admin이 Display 탭에서 설정 변경 |
| `ConfigChanged` | 시스템 자동 | BO DB 갱신 후 WebSocket 이벤트 발행 |
| 블라인드 레벨 변경 | 게임 엔진 자동 | "When Changed" 시 일시적 표시 트리거 |

---

## 3. 경우의 수 매트릭스

| 조건 | Blinds 설정 변경 | Precision 변경 | Mode 변경 |
|------|:---------------:|:-------------:|:--------:|
| CC IDLE | 즉시 적용 (FREE) | 즉시 적용 (FREE) | 즉시 적용 (FREE) |
| CC 핸드 진행 중 | 즉시 적용 (FREE) | 즉시 적용 (FREE) | 즉시 적용 (FREE) |
| BO 서버 미실행 | 변경 불가 | 변경 불가 | 변경 불가 |
| BB = 0 (블라인드 미설정) | — | — | BB 모드 사용 불가 ("BB 미설정" 경고) |
| Trailing Currency ON + BB Mode | — | — | BB 접미사 우선 (Currency 무시) |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| D-1 | Admin | Show Blinds를 "When Changed"로 설정 | 레벨 변경 시만 일시적 블라인드 표시 | "Never": 블라인드 완전 숨김 |
| D-2 | Admin | Currency Symbol을 "€"로 변경 | 모든 금액 영역에 € 기호 적용 | Trailing ON: "100€" 형태 |
| D-3 | Admin | Player Stack을 "Smart k-M"으로 설정 | 1,234,567 → "1.2M" 표시 | Exact Amount: 전체 수치 표시 |
| D-4 | Admin | Chipcounts Mode를 BB로 전환 | 칩이 BB 배수로 표시 | BB=0: "BB 미설정" 경고 |
| D-5 | Admin | Pot Mode만 BB, 나머지 Amount 유지 | 팟만 BB 배수, 나머지 실제 금액 | — |
| D-6 | Admin | Display Side Pot ON | 사이드팟 금액 보드에 별도 표시 | 사이드팟 미발생: 표시 없음 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Display 탭 접근 불가 |
| BO 서버 미실행 | 읽기 전용 |
