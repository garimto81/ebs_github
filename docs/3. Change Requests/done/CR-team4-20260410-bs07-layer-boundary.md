---
title: CR-team4-20260410-bs07-layer-boundary
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# CCR-DRAFT: BS-07 Overlay Layer 1/2/3 경계 및 자동화 범위 명시

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2, team3]
- **변경 대상 파일**: contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md, contracts/specs/BS-07-overlay/BS-07-00-overview.md
- **변경 유형**: add
- **변경 근거**: 현재 BS-07-00-overview.md §3에 "EBS Layer 1 — Overlay 그래픽 8종"이 정의되어 있으나, **Layer 2와 Layer 3의 경계**가 계약 레벨에 명시되지 않았다. Foundation PRD Ch.6를 참조만 하는 상태. EBS Core 정의(v41.0.0)에 따르면 "EBS=Layer 1만 책임, Layer 2/3는 외부 팀 담당"이 핵심 원칙이지만, BS-07 계약 내에 명시되지 않아 Team 2/3/4가 구현 범위를 혼동할 위험이 있다. 또한 Layer 1 8종 중 일부(Action Badge, Position)는 "반자동"으로 표시되어 운영자 개입 시점이 불명확하다. 본 CCR은 Layer 경계와 자동화 정도를 계약에 확정한다.

## 변경 요약

1. `BS-07-06-layer-boundary.md` 신규: Layer 1/2/3 경계, 각 Layer 책임 주체, 자동화 정도 매트릭스
2. `BS-07-00-overview.md` §3에 BS-07-06 참조 추가

## 변경 내용

### 1. BS-07-06-layer-boundary.md (신규 파일)

```markdown
# BS-07-06 Layer Boundary

> **참조**: BS-07-00-overview §3 Layer 1 그래픽 8종, Foundation PRD Ch.6 Layer 구조

## 원칙

EBS Core는 **Layer 1만 책임**한다. Layer 2/3은 외부 팀(포스트프로덕션, 
방송 디자인)이 담당하며, EBS는 Layer 2/3에 필요한 **데이터만 API로 제공**한다.

**인용**: Foundation PRD v41.0.0 §6 
> "EBS=실시간 라이브(경쟁: PokerGFX) / 포스트프로덕션=종합편집(경쟁: Adobe)"

## Layer 정의

### Layer 1 — EBS Core 자동 생성 (본 계약 범위)

**정의**: RFID 감지 또는 CC 입력 직후 **즉시** 생성되는 그래픽. 지연 없음.

**책임**: Team 3 (Game Engine) + Team 4 (Overlay 렌더링)

**그래픽 8종** (BS-07-00 §3 참조):

| # | 그래픽 | 트리거 주체 | 자동화 정도 |
|:-:|--------|------------|:---------:|
| 1 | HoleCards | RFID CardDetected | **완전 자동** |
| 2 | Board | RFID CardDetected (board slot) | **완전 자동** |
| 3 | Action Badge | CC ActionPerformed | **반자동** (아래 참조) |
| 4 | Pot Display | Engine bet 누적 | **완전 자동** |
| 5 | Equity Bar | Engine EquityUpdated | **완전 자동** |
| 6 | Player Info | BO PlayerUpdated or WSOP LIVE API | **완전 자동** |
| 7 | Outs | Engine 카드 계산 | **완전 자동** |
| 8 | Player Position | CC SeatAssign or Engine StartHand | **반자동** |

### Layer 2 — 준자동 통계/분석 (EBS 범위 외)

**정의**: 실시간 계산 가능하지만 운영자 판단이 필요한 그래픽. 방송 중 운영자가 
"Push to GFX" 버튼으로 수동 발송.

**책임**: 외부 팀 또는 EBS Phase 2 확장

**예시 (WSOP 원본 기준)**:
- VPIP/PFR 통계 Overlay (BS-05-07 AT-04 Push)
- 3-Bet/Aggression Factor 실시간 바
- 플레이어 Chip Flow 차트
- Hand Strength Heat Map

**EBS 역할**: API-01 `GET /tables/{id}/stats` 엔드포인트로 **데이터만 제공**. 
렌더링은 Layer 2 시스템(외부)이 담당.

### Layer 3 — 사전 제작 콘텐츠 (EBS 범위 외)

**정의**: 방송 전에 제작되어 방송 중 재생되는 정적/녹화 콘텐츠.

**책임**: 외부 팀 (방송 디자인, 영상 편집)

**예시**:
- 오프닝 타이틀 영상
- 스폰서 로고 인트로
- 플레이어 프로필 소개 영상
- 승자 축하 영상
- 대회 로고, 배경 그래픽

**EBS 역할**: 없음. Layer 3 시스템이 독립적으로 방송 송출.

## 자동화 정도 상세

### 완전 자동 (Fully Automatic)

- 트리거 이벤트 수신 즉시 그래픽 생성/갱신
- 운영자 개입 없음
- 구현 위치: Overlay 앱이 `ActionRequested`, `CardDetected`, `EquityUpdated` 이벤트 리스너
- 지연 목표: < 100ms

### 반자동 (Semi-Automatic)

운영자 개입이 필요한 경우:

#### Action Badge
- CC가 액션 입력 시 자동 생성되지만 **Security Delay** 적용 가능 (BS-07-07 참조)
- Admin이 설정한 delay(0~60초) 경과 후 Overlay에 표시
- 운영자가 수동으로 "Hide Badge" 가능

#### Player Position
- 핸드 시작 시 Engine이 포지션 계산 → 자동 생성
- 운영자가 수동으로 "Dead Button Override" 가능 (BS-06 참조)

### 비자동 (Manual Only, Layer 2로 이관)

- 플레이어 프로필 카드 Push
- 핸드 히스토리 재생
- 통계 비교 Overlay (Player A vs Player B)

## 책임 매트릭스

| 그래픽 범주 | 트리거 | 렌더링 | 데이터 | Layer |
|-----------|:-----:|:-----:|:-----:|:-----:|
| HoleCards | Team 4 (RFID) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Board | Team 4 (RFID) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Action Badge | Team 4 (CC) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Pot Display | Team 3 (Engine) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Equity Bar | Team 3 (Engine) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Player Info | Team 2 (BO) | Team 4 (Overlay) | Team 2 (WSOP LIVE) | 1 |
| Outs | Team 3 (Engine) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| Player Position | Team 3 (Engine) | Team 4 (Overlay) | Team 3 (Engine) | 1 |
| VPIP/PFR Stats | Team 4 (CC Push) | **외부** | Team 2 (API) | 2 |
| Hand Strength Heat | — | **외부** | Team 3 (API) | 2 |
| 오프닝 타이틀 | — | **외부** | — | 3 |
| 스폰서 로고 | — | **외부** | — | 3 |

## Phase 2 확장 여지

EBS가 Layer 2 일부를 자동화로 확장할 수 있는 영역:

- 실시간 VPIP 계산 → Overlay 자동 표시 (Phase 2)
- 올인 equity 분포 시각화 (Phase 2)
- Run It 2/3 결과 애니메이션 (Phase 2)

단, Phase 2 확장은 **별도 CCR로 결정**. Phase 1은 Layer 1 8종만 구현.

## 구현 경계

### Team 4 (Overlay)의 코드 경계

```dart
// lib/features/overlay/
// ├── layer1/           ← 본 계약 범위
// │   ├── hole_cards.dart
// │   ├── board.dart
// │   ├── action_badge.dart
// │   ├── pot_display.dart
// │   ├── equity_bar.dart
// │   ├── player_info.dart
// │   ├── outs.dart
// │   └── player_position.dart
// │
// ├── layer2_push/      ← Phase 2 확장 영역 (현재 미구현)
// │
// └── common/           ← 공통 유틸
```

**금지**: Team 4는 `layer2_push/` 구현 금지. 해당 영역은 별도 CCR 승인 후에만 구현.

## 참조

- BS-07-00-overview §3 Layer 1 그래픽 8종
- Foundation PRD v41.0.0 Ch.6 Layer 구조
- BS-05-07-statistics §방송 GFX Push (Layer 2로의 데이터 제공)
- API-01-backend-api §Stats 엔드포인트 (Layer 2 소비자)
- BS-07-07-security-delay §Security Delay (Action Badge 적용)
```

### 2. BS-07-00-overview.md §3 섹션 수정

```diff
 ## 3. EBS Layer 1 — Overlay 그래픽 8종
 
-> 참조: Foundation PRD Ch.6 Layer 1
+> 참조: Foundation PRD Ch.6 Layer 1, **BS-07-06-layer-boundary.md** (Layer 1/2/3 경계, 책임 매트릭스)

 RFID가 카드를 읽거나, 운영자가 CC에서 액션을 입력하는 순간 **자동으로 즉시 생성**되는 그래픽이다.
 ...
```

## 영향 분석

### Team 2 (Backend)
- **영향**:
  - `GET /tables/{id}/stats` 엔드포인트가 Layer 2 "데이터 제공" 책임임을 인식
  - Layer 2 렌더링 로직은 Backend 범위 외 (외부 시스템)
- **예상 리뷰 시간**: 1시간

### Team 3 (Game Engine)
- **영향**:
  - Game Engine이 Layer 1의 8종 그래픽 트리거 이벤트를 모두 발행하는지 확인
  - Layer 2/3 관련 API는 "데이터 조회"만 제공
- **예상 리뷰 시간**: 2시간

### Team 4 (self)
- **영향**:
  - `lib/features/overlay/` 디렉토리 구조를 `layer1/`과 `layer2_push/`로 분리
  - Phase 1에서는 `layer1/` 8개 파일만 구현
  - `layer2_push/` 디렉토리는 빈 상태로 두고 README에 "Phase 2, 별도 CCR 필요" 명시
- **예상 작업 시간**: 2시간 (문서 작업 + 디렉토리 구조화)

### 마이그레이션
- 없음

## 대안 검토

### Option 1: Layer 경계 명시하지 않고 Foundation PRD만 참조
- **단점**: 
  - Foundation PRD는 전략 문서라 구현 세부 미포함
  - Team 4가 Layer 2 일부를 "자동화하면 좋겠다" 판단 시 범위 확장 위험
- **채택**: ❌

### Option 2: BS-07-06 신규 작성 (본 제안)
- **장점**:
  - 계약 레벨 경계 명확
  - 책임 매트릭스로 구현 범위 재확인
  - Phase 2 확장 경로 문서화
- **채택**: ✅

### Option 3: Layer 2/3도 BS-07 범위에 포함
- **단점**: 
  - EBS Core 정의(v41.0.0)와 정면 충돌
  - 과도한 범위 확장
- **채택**: ❌

## 검증 방법

### 1. 계약 일관성
- [ ] BS-07-00 §3의 8종 그래픽 리스트가 BS-07-06의 "완전 자동/반자동" 표와 1:1 일치
- [ ] Foundation PRD v41.0.0 Ch.6의 Layer 정의와 일관

### 2. 구현 경계 확인
- [ ] Team 4 `lib/features/overlay/layer1/` 폴더에 8개 파일 스텁 생성
- [ ] `lib/features/overlay/layer2_push/` 폴더는 비어있고 README.md만 포함

### 3. Phase 2 확장 예시
- [ ] 본 CCR 승인 후 Phase 2의 "VPIP 자동화" CCR이 별도 제출되면 `layer2_push/` 폴더에 구현 가능

### 4. 외부 팀 인터페이스
- [ ] Layer 2 외부 시스템이 `GET /tables/{id}/stats` API만 호출하여 데이터 수신
- [ ] Layer 3은 EBS와 독립 동작 (상호 의존 없음)

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (Stats API = Layer 2 데이터 제공 책임 확인)
- [ ] Team 3 기술 검토 (Layer 1 트리거 이벤트 완결성)
- [ ] Team 4 기술 검토 (디렉토리 구조, Phase 2 경계)
