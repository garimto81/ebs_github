---
title: Layer Boundary
owner: team4
tier: internal
legacy-id: BS-07-06
last-updated: 2026-04-15
---

# BS-07-06 Layer Boundary

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Layer 1/2/3 경계 + Layer 1 자동화 정도 매트릭스 (CCR-035) |

---

## 원칙

EBS Core는 **Layer 1만 책임**한다. Layer 2/3은 외부 팀(포스트프로덕션, 방송 디자인)이 담당하며, EBS는 Layer 2/3에 필요한 **데이터만 API로 제공**한다.

> **인용**: Foundation (Confluence SSOT) Ch.4
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

### 1.4 비-Overlay — Lobby 내부 데이터 화면 (참고 명시)

Layer 1/2/3 분류 외부에 **Lobby 내부 화면** 이 존재한다. 시청자에게 송출되지 않으며 운영자/관리자만 본다.

| 화면 | SSOT | Overlay 출력 여부 |
|------|------|:----------------:|
| Lobby Tournaments / Tables / Players / Staff / Settings / History / Hand History | `2.1 Frontend/Lobby/**` | **❌ Overlay 비대상** |
| Lobby `Hand_History.md` (Hand Browser / Detail / Player Stats) | `2.1 Frontend/Lobby/Hand_History.md` | **❌ Overlay 비대상**. CC → BO → DB 에 저장된 핸드 데이터를 Lobby UI 가 직접 조회 |

> Hand History 의 hole card 마스킹 RBAC (Viewer ★ 마스킹) 은 Lobby 내부 표시 정책이며 Overlay 의 `HoleCardsRevealed` 송출 정책 (§API-04 / Scene_Schema.md) 과 별개의 메커니즘이다. 동일 데이터지만 표시 채널/규칙이 다름.

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

### 3.1 Layer 2/3 외부 시스템용 API

Layer 2/3 시스템이 EBS에서 필요로 하는 데이터:

| API | 용도 | Layer |
|-----|------|:-----:|
| `GET /api/v1/tables/{id}/state` | 현재 테이블 전체 상태 | 2, 3 |
| `GET /api/v1/tables/{id}/statistics` | 플레이어 통계 (VPIP/PFR 등) | 2 |
| `GET /api/v1/tables/{id}/hands?limit=50` | 최근 핸드 히스토리 | 2 |
| `API-05 WebSocket` | 실시간 이벤트 스트림 | 2 |

Layer 2/3 외부 시스템은 이 API를 소비하여 자체 렌더링 파이프라인을 구축한다.

### 3.2 Layer 1 — team3 ↔ team4 내부 계약 (API-04)

Layer 1 의 그래픽들은 **team3 Game Engine** 이 GameState 변경 시 발행하는 `OutputEvent` 를 **team4 Overlay renderer** 가 수신하여 Rive 애니메이션을 트리거한다. 이 in-process 계약은 `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` (API-04) 가 정본이다.

| 구분 | 위치 |
|------|------|
| OutputEvent sealed class 정의 **(21종, 실측)** | team3 `ebs_game_engine/lib/core/actions/output_event.dart` |
| 이벤트 카탈로그 + payload 스키마 | `Overlay_Output_Events.md §6 씬 업데이트 이벤트` |
| OutputEventBuffer (security delay) 구현 | team4 `src/lib/features/overlay/services/output_event_buffer.dart` (CCR-056) |
| Backstage/Broadcast 이중 출력 | team4 `src/lib/features/overlay/services/dual_output_manager.dart` |

**21종 요약** (2026-04-15 실측, 상세 payload 는 API-04 참조):

| # | Event | 분류 | Layer 1 영향 |
|---|-------|------|-------------|
| OE-01 | `StateChanged` | 진행 | Phase 배너, 전환 애니메이션 |
| OE-02 | `ActionProcessed` | 진행 | 액션 라벨, seat glow |
| OE-03 | `PotUpdated` | 진행 | Pot Display 숫자 애니메이션 |
| OE-04 | `BoardUpdated` | 진행 | 보드 카드 슬라이드 |
| OE-05 | `ActionOnChanged` | 진행 | action-on 좌석 glow 이동 |
| OE-06 | `WinnerDetermined` | 종결 | Winner 하이라이트 준비 |
| OE-07 | `Rejected` | 에러 | 액션 거부 토스트 |
| OE-08 | `UndoApplied` | 복구 | 이전 scene 으로 롤백 애니메이션 |
| OE-09 | `HandCompleted` | 종결 | Pot sweep + winner reveal |
| OE-10 | `EquityUpdated` | 진행 | Equity Bar |
| OE-11 | `CardRevealed` | 카드 | 홀/보드 카드 reveal 애니메이션 |
| OE-12 | `CardMismatchDetected` | 에러 | 경고 배너 (RFID↔수동 불일치) |
| OE-13 | `SevenDeuceBonusAwarded` | 특별 | 보너스 배너 (7-2 룰) |
| OE-14 | `HandTabled` | 특별 | table hand 공개 |
| OE-15 | `HandRetrieved` | 복구 | 취소된 hand 복원 |
| OE-16 | `HandKilled` | 복구 | hand 폐기 처리 |
| OE-17 | `MuckRetrieved` | 복구 | 머크된 카드 재공개 |
| OE-18 | `FlopRecovered` | 복구 | 잘못 공개된 flop 회수 |
| OE-19 | `DeckIntegrityWarning` | 에러 | 덱 무결성 경고 |
| OE-20 | `DeckChangeStarted` | 운영 | 덱 교체 진행 표시 |
| OE-21 | `GameTransitioned` | 운영 | Mix 게임 종목 전환 |

**소비자(team4) 가 계약 외 동작을 하지 않도록 하는 규칙**:

1. 새 Layer 1 기능을 추가하려면 먼저 API-04 에 OutputEvent 를 추가 (team3 소유).
2. team4 는 신규 이벤트를 수신할 때 **정의되지 않은 필드에 의존하지 않는다**. sealed class pattern 의 컴파일 시점 exhaustiveness 로 누락 감지.
3. team3 가 이벤트를 deprecate 하려면 최소 1 sprint 사전 공지 + API-04 Edit History 업데이트.

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
- `Foundation (Confluence SSOT) Ch.4` — EBS Core 경계 원칙
- `BS-05-07-statistics` — Layer 2 통계 Push 트리거 (AT-04)
- `API-01-backend-api §통계` — Layer 2 데이터 엔드포인트
