# BS-07-06 Layer Boundary

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Layer 1/2/3 경계 + Layer 1 자동화 정도 매트릭스 (CCR-035) |

---

## 원칙

EBS Core는 **Layer 1만 책임**한다. Layer 2/3은 외부 팀(포스트프로덕션, 방송 디자인)이 담당하며, EBS는 Layer 2/3에 필요한 **데이터만 API로 제공**한다.

> **인용**: Foundation PRD v41.0.0 §6
> "EBS = 실시간 라이브(경쟁: PokerGFX) / 포스트프로덕션 = 종합편집(경쟁: Adobe)"

---

## 1. Layer 정의

### 1.1 Layer 1 — EBS Core 자동 생성 (본 계약 범위)

**정의**: RFID 감지 또는 CC 입력 직후 **즉시** 생성되는 그래픽. 지연 없음.

**책임**: Team 3 (Game Engine) + Team 4 (Overlay 렌더링)

**그래픽 8종** (`BS-07-00 §3` 참조):

| # | 그래픽 | 트리거 주체 | 자동화 정도 |
|:-:|--------|------------|:-----------:|
| 1 | HoleCards | RFID `CardDetected` | **완전 자동** |
| 2 | Board | RFID `CardDetected` (board slot) | **완전 자동** |
| 3 | Action Badge | CC `ActionPerformed` | **반자동** (§2 참조) |
| 4 | Pot Display | Engine bet 누적 | **완전 자동** |
| 5 | Equity Bar | Engine `EquityUpdated` | **완전 자동** |
| 6 | Player Info | BO `PlayerUpdated` or WSOP LIVE API | **완전 자동** |
| 7 | Outs | Engine 카드 계산 | **완전 자동** |
| 8 | Player Position | CC `SeatAssign` or Engine `StartHand` | **반자동** (§2 참조) |

### 1.2 Layer 2 — 준자동 통계/분석 (EBS 범위 외)

**정의**: 실시간 계산 가능하지만 운영자 판단이 필요한 그래픽. 방송 중 운영자가 "Push to GFX" 버튼으로 수동 발송.

**책임**: 외부 팀 또는 EBS Phase 2 확장

**예시 (WSOP 원본 기준)**:
- VPIP/PFR 통계 Overlay (`BS-05-07 AT-04 Push`)
- 3-Bet/Aggression Factor 실시간 바
- 플레이어 Chip Flow 차트
- Hand Strength Heat Map

**EBS 역할**: `API-01 GET /tables/{id}/statistics` 엔드포인트로 **데이터만 제공**. 렌더링은 Layer 2 시스템(외부)이 담당.

### 1.3 Layer 3 — 사전 제작 콘텐츠 (EBS 범위 외)

**정의**: 방송 전에 제작되어 방송 중 재생되는 정적/녹화 콘텐츠.

**책임**: 외부 팀 (방송 디자인, 영상 편집)

**예시**:
- 오프닝 타이틀 영상
- 스폰서 로고 인트로
- 플레이어 프로필 소개 영상
- 승자 축하 영상
- 대회 로고, 배경 그래픽

**EBS 역할**: 없음. 외부 시스템이 NDI/HDMI로 EBS Overlay와 믹스한다.

---

## 2. 반자동 그래픽 상세

### 2.1 Action Badge

- **완전 자동 요소**: 액션 종류 결정 (Fold / Check / Bet / Call / Raise / All-In) — `ActionPerformed` 이벤트 기반
- **반자동 요소**: 표시 지속 시간, 강조 여부 — 운영자가 `BS-03-04-rules` 설정 또는 실시간 키보드 입력으로 조정 가능
- **이유**: 특정 액션(특히 All-In)은 운영자가 시청자에게 강조할 시점을 직접 결정할 수 있어야 한다

### 2.2 Player Position

- **완전 자동 요소**: Dealer/SB/BB/UTG 위치 계산 (Engine이 규칙에 따라 결정)
- **반자동 요소**: `SeatAssign` 이벤트로 CC 운영자가 좌석 변경 가능 (예: 플레이어 도중 퇴장 → 좌석 재배치)
- **이유**: 플레이어 이동이 실시간으로 발생하므로 운영자 개입 필요

---

## 3. 데이터 제공 API 요약

Layer 2/3 시스템이 EBS에서 필요로 하는 데이터:

| API | 용도 | Layer |
|-----|------|:-----:|
| `GET /api/v1/tables/{id}/state` | 현재 테이블 전체 상태 | 2, 3 |
| `GET /api/v1/tables/{id}/statistics` | 플레이어 통계 (VPIP/PFR 등) | 2 |
| `GET /api/v1/tables/{id}/hands?limit=50` | 최근 핸드 히스토리 | 2 |
| `API-05 WebSocket` | 실시간 이벤트 스트림 | 2 |

Layer 2/3 외부 시스템은 이 API를 소비하여 자체 렌더링 파이프라인을 구축한다.

---

## 4. 판단 기준 (신규 요구사항 분류)

신규 Overlay 기능 요구사항이 들어올 때 다음 기준으로 Layer를 판단한다:

| 판단 | Layer |
|------|:-----:|
| 실시간성 < 100ms 필요 + Engine/CC 직접 트리거 | Layer 1 |
| 실시간 계산 가능하지만 운영자 판단 개입 | Layer 2 |
| 사전 제작 가능하고 정적/녹화 콘텐츠 | Layer 3 |

Layer 1이 아닌 경우 EBS는 **API 제공**만 하고 렌더링은 외부에 위임한다.

---

## 5. 연관 문서

- `BS-07-00-overview §3` — Layer 1 그래픽 8종 원본 정의
- `Foundation PRD v41.0.0 §6` — EBS Core 경계 원칙
- `BS-05-07-statistics` — Layer 2 통계 Push 트리거 (AT-04)
- `API-01-backend-api §통계` — Layer 2 데이터 엔드포인트
