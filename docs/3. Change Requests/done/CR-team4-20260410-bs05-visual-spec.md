---
title: CR-team4-20260410-bs05-visual-spec
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs05-visual-spec
---

# CCR-DRAFT: BS-05 시각/동작 명세 구체화 (카드 슬롯 FSM, 포지션 색상, 애니메이션)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md
- **변경 유형**: modify
- **변경 근거**: WSOP 원본(`EBS UI Design Action Tracker.md` §2.2, §5, §6)에 정의된 시각/동작 규격이 현재 BS-05에 누락되어 구현자마다 다르게 해석될 위험. 특히 카드 슬롯 5상태 FSM은 RFID UX의 핵심이며, 포지션 마커 색상은 라이브 방송 시청자 식별에 직접 영향한다. 또한 이전 critic 분석의 W10(RFID 5초 대기 의미 불명확)을 해소한다.

## 변경 요약

4가지 시각/동작 규격을 BS-05에 추가:

1. **카드 슬롯 5상태 FSM** (EMPTY → DETECTING → DEALT/FALLBACK/WRONG_CARD) + 색상 코드
2. **포지션 마커 색상** (Dealer 빨강, SB 노랑, BB 파랑, UTG 초록)
3. **좌석 상태 배경색** (VACANT/active/folded/sitting_out/all_in 각각 명시)
4. **action-glow 애니메이션 규격** (box-shadow 펄스, 0.8초 주기)

## 변경 내용

### 1. BS-05-04-manual-card-input.md §카드 슬롯 상태머신 (신규 섹션)

```
EMPTY ──RFID 신호──▶ DETECTING ──매핑 성공(≤5s)──▶ DEALT
  │                        │
  │                        ├──매핑 실패(>5s)──▶ FALLBACK → AT-03 자동 진입
  │                        │
  │                        └──중복 UID──▶ WRONG_CARD (#DD0000)
  │
  └──운영자 클릭──▶ AT-03 수동 진입
```

**상태별 시각 규격**:

| 상태 | 시각 | 색상 코드 | 애니메이션 |
|------|------|---------|----------|
| EMPTY | 점선 테두리 빈 슬롯 | — | 없음 |
| DETECTING | 노란 펄스 애니메이션 | `#FFD600` | `detect-pulse 0.6s infinite alternate` |
| DEALT | 카드 이미지 표시 | — | 0.2s fade-in |
| FALLBACK | AT-03 모달 자동 열림 | — | 모달 slide-up 0.3s |
| WRONG_CARD | 빨간 테두리 + 경고 아이콘 | `#DD0000` | 0.4s shake |

**W10 해소 (RFID 5초 대기 의미)**:

> 5초는 **카드 슬롯당 독립 측정**한다. 슬롯이 DETECTING 상태로 진입한 시점부터 5초 경과 시 FALLBACK으로 전이한다.
>
> 예시: Seat 1 홀카드가 1번째 슬롯은 즉시 감지(DEALT), 2번째 슬롯은 미감지 상태라면:
> - Seat 1 1번째: 즉시 DEALT
> - Seat 1 2번째: DETECTING 진입 후 5초 대기 → FALLBACK (AT-03 자동 진입)
> - Seat 2 홀카드: 독립 타이머로 동작 (Seat 1의 타이머에 영향받지 않음)

### 2. BS-05-03-seat-management.md §시각 규격 (신규 섹션)

#### 포지션 마커 색상 (M-03 좌석 라벨 행)

| 포지션 | 표시 | CSS 색상 | 근거 |
|--------|------|---------|------|
| Dealer | 🔴 빨간 원 + "D" | `#E53935` (Material Red 600) | WSOP 원본 포커 관습 |
| SB (Small Blind) | 🟡 노란 원 + "SB" | `#FDD835` (Material Yellow 600) | WSOP 원본 |
| BB (Big Blind) | 🔵 파란 원 + "BB" | `#1E88E5` (Material Blue 600) | WSOP 원본 |
| UTG | 🟢 초록 원 + "UTG" | `#43A047` (Material Green 600) | WSOP 원본 |
| 일반 | ⚪ 흰색 원 (포지션 숫자) | `#FFFFFF` | Neutral fallback |

#### 좌석 상태 배경색 (M-05 좌석 카드 행)

| SeatFSM × Player 상태 | 배경색 | 투명도 | 추가 요소 |
|----------------------|--------|:------:|----------|
| VACANT | `#616161` (Gray 700) | 100% | "OPEN" 텍스트 |
| OCCUPIED + active | `#2E7D32` (Green 800) | 100% | — |
| OCCUPIED + active + action_on | `#2E7D32` + action-glow 펄스 | 100% | 노란 테두리 강조 |
| OCCUPIED + folded | `#616161` (Gray 700) | 40% | — |
| OCCUPIED + sitting_out | `#616161` (Gray 700) | 60% | "AWAY" 텍스트 |
| OCCUPIED + all_in | `#000000` (Black) | 100% | "ALL-IN" 텍스트 (흰색) |

#### action-glow 애니메이션 규격

- **효과**: box-shadow 펄스 (Preattentive Processing 원리)
- **주기**: 0.8초 (`infinite alternate`)
- **근거**: `team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md` §4.4 참조

```css
@keyframes action-glow {
  from {
    box-shadow: 0 0 0 0 rgba(253, 216, 53, 0.4);
  }
  to {
    box-shadow: 0 0 16px 4px rgba(253, 216, 53, 1.0);
  }
}

.seat-cell[data-action-on="true"] {
  animation: action-glow 0.8s infinite alternate;
}
```

### 3. BS-07-02-animations.md §참조 추가

`BS-07 Overlay` 애니메이션 명세에 다음 참조 추가:

> **참조**: CC 쪽 `action-glow` 애니메이션은 `BS-05-03-seat-management.md §시각 규격` 참조. Overlay는 동일한 좌석 강조를 Rive 애니메이션으로 재현하되, 색상 코드(`#2E7D32`, `#FDD835` 등)와 주기(0.8s)는 동일하게 유지한다.

## Diff 초안

```diff
 # BS-05-04-manual-card-input.md

 ## 2. RFID 감지 및 폴백

+### 2.x 카드 슬롯 상태머신
+
+```
+EMPTY ──RFID 신호──▶ DETECTING ──매핑 성공(≤5s)──▶ DEALT
+  │                        │
+  │                        ├──매핑 실패(>5s)──▶ FALLBACK → AT-03 자동 진입
+  │                        │
+  │                        └──중복 UID──▶ WRONG_CARD (#DD0000)
+  │
+  └──운영자 클릭──▶ AT-03 수동 진입
+```
+
+**상태별 시각 규격**:
+
+| 상태 | 색상 | 애니메이션 |
+|------|------|----------|
+| EMPTY | — | 없음 |
+| DETECTING | #FFD600 | detect-pulse 0.6s |
+| DEALT | — | fade-in 0.2s |
+| FALLBACK | — | modal slide-up 0.3s |
+| WRONG_CARD | #DD0000 | shake 0.4s |
+
+**5초 대기 규칙** (W10 해소): 카드 슬롯당 독립 측정.
+DETECTING 진입 시점부터 5초. 다른 슬롯은 독립 타이머.
```

```diff
 # BS-05-03-seat-management.md

 ## 4. 시각 표현

+### 4.x 포지션 마커 색상 (M-03)
+
+| 포지션 | 색상 | CSS |
+|--------|------|-----|
+| Dealer | 빨강 | #E53935 |
+| SB | 노랑 | #FDD835 |
+| BB | 파랑 | #1E88E5 |
+| UTG | 초록 | #43A047 |
+| 일반 | 흰색 | #FFFFFF |
+
+### 4.y 좌석 상태 배경색 (M-05)
+
+| 상태 | 배경 | 투명도 |
+|------|------|:------:|
+| VACANT | #616161 | 100% |
+| active | #2E7D32 | 100% |
+| active + action_on | #2E7D32 + glow | 100% |
+| folded | #616161 | 40% |
+| sitting_out | #616161 | 60% |
+| all_in | #000000 | 100% |
+
+### 4.z action-glow 애니메이션
+
+- 효과: box-shadow 펄스
+- 주기: 0.8s infinite alternate
+- 근거: Preattentive Processing (EBS-AT-Design-Rationale §4.4)
```

## 영향 분석

### Team 1 (Lobby)
- **영향**: Lobby의 CC 활성 모니터링 뷰에서도 동일 색상 체계를 따를지 결정 필요. 일관성을 위해 동일 색상 권장.
- **필요 작업**: BS-02-lobby §CC 모니터링 섹션에 "색상 코드는 BS-05-03 §시각 규격 참조" 명시 (별도 후속 CCR 없이 본 CCR에 포함).
- **예상 리뷰 시간**: 1시간

### Team 4 (self)
- **영향**: 
  - 구현 시 색상값을 `team4-cc/src/lib/foundation/theme/seat_colors.dart` 상수로 고정
  - action-glow 애니메이션을 Flutter `AnimationController`로 구현 (또는 Rive)
  - 카드 슬롯 상태머신을 `lib/features/command_center/models/card_slot_state.dart`에 enum으로 정의
- **예상 작업 시간**: 시각 상수 2시간 + 애니메이션 구현 4시간 + 카드 슬롯 FSM 구현 3시간 = 약 9시간

### 마이그레이션
- 없음 (신규 시각 규격)

## 대안 검토

### Option 1: 시각 규격 구현자 위임
- **장점**: CCR 부담 없음
- **단점**: 
  - 팀별/화면별 색상 불일치 → 라이브 방송 시청자 혼란
  - 포지션 식별 어려움 (특히 6시간+ 방송 피로 상황)
  - QA 회귀 시 "기준 없음"으로 검증 불가
- **채택**: ❌

### Option 2: WSOP 색상 체계 그대로 채택 (본 제안)
- **장점**: 
  - 원본 설계 근거 존재 (`EBS-AT-Design-Rationale.md` §4.4)
  - Material Design 표준 팔레트 사용으로 접근성 확보
  - PokerGFX 역설계 자산 재사용
- **단점**: Material 색상에 고정 (향후 브랜드 변경 시 재정의 필요)
- **채택**: ✅

### Option 3: EBS 자체 색상 체계
- **장점**: 브랜딩 일관성
- **단점**: 
  - 설계 근거 없음 (디자인 리서치 추가 필요)
  - WSOP 원본과 차이 발생 이유를 추가 문서화해야 함
- **채택**: ❌

## 검증 방법

### 1. 시각 검증 (목업 대조)
- `team4-cc/ui-design/reference/action-tracker/mockups/v4/` HTML 목업의 색상 값을 Playwright로 추출
- 본 CCR의 색상 코드(`#E53935`, `#FDD835`, `#1E88E5`, `#43A047`, `#2E7D32`, `#616161`, `#000000`, `#FFD600`, `#DD0000`)와 1:1 대조
- 불일치 시 mockup 또는 CCR 중 정확한 쪽으로 확정

### 2. 접근성 검증 (WCAG 2.1 AA)
- 녹색 배경(`#2E7D32`) + 흰색 텍스트 대비율: 5.14:1 (AA 통과 ≥ 4.5:1)
- 검정 배경(`#000000`) + 노란 포지션 마커(`#FDD835`) 대비율: 17.4:1 (AAA 통과)
- 회색 배경(`#616161`) + 흰색 텍스트 대비율: 5.74:1 (AA 통과)
- 모든 조합을 WebAIM Contrast Checker로 검증

### 3. 애니메이션 성능
- `action-glow`가 10좌석 동시 펄스 시 60fps 유지 확인
- Flutter DevTools Performance 탭으로 측정
- 목표: 프레임 드롭 < 5% (50~60fps 구간)

### 4. 카드 슬롯 FSM 상태 전이 테스트
- 단위 테스트: EMPTY → DETECTING → DEALT 정상 경로
- 단위 테스트: EMPTY → DETECTING → (5s timeout) → FALLBACK
- 단위 테스트: EMPTY → DETECTING → (중복 UID) → WRONG_CARD → EMPTY (재시도)
- 독립 타이머 테스트: Seat 1 Slot 2가 timeout되어도 Seat 2 Slot 1 영향 없음 확인

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby CC 모니터링 색상 일관성)
- [ ] Team 4 기술 검토 (Flutter 구현 가능성, Rive 연동)
