---
id: B-334
title: "OutputEventBuffer_Boundary §2-§3 탭 모드 / 다중창 모드 / Engine 3분법으로 재구성"
backlog-status: open
priority: P1
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §5.0 (2 런타임 모드) / §6.3 (프로세스 경계)"
mirror: none
---

# [B-334] OutputEventBuffer 계약을 탭/다중창/Engine 3분법으로 재구성 (P1)

## 배경

Foundation §5.0 이 2 런타임 모드를 신설:

| 모드 | CC↔Overlay 관계 |
|------|-----------------|
| 탭 모드 (기본) | 단일 Flutter 프로세스 내 라우팅 — **in-process** |
| 다중창 모드 (PC 옵션) | Lobby/CC/Overlay 독립 OS 프로세스 — **BO 경유 WS broadcast** (§6.3 "앱 간 직접 IPC 없음") |

그리고 §6.3 은 Engine 이 **항상** 별도 프로세스 (Docker 또는 `dart run`) 임을 확정.

그러나 `OutputEventBuffer_Boundary.md §2` 는 "CC + Overlay + Engine 이 같은 Flutter 앱" 을 Phase 1 기본으로 가정해 2 가지 분기 (in-process / 프로세스 분리) 만 다룸. 실제로는 **3 가지** 조합이 존재한다.

## 수정 대상

### `APIs/OutputEventBuffer_Boundary.md`

§2-§3 을 다음 3 시나리오로 재구성:

1. **시나리오 A — 탭 모드 (기본)**
   - Engine ↔ CC: REST (harness port 8080)
   - CC ↔ Overlay: in-process Dart Stream (§2 현존 코드 유지)
   - OutputEventBuffer 위치: CC 프로세스 내부

2. **시나리오 B — 다중창 모드**
   - Engine ↔ CC: REST (동일)
   - CC ↔ Overlay: BO 경유 WS (`/ws/cc` 구독 후 Overlay 에 broadcast)
   - OutputEventBuffer 위치: CC 측 enqueue + WS broadcast → Overlay 프로세스는 수신 후 즉시 렌더 (delay 는 CC 가 소유)

3. **시나리오 C — Replay/Debug (Harness 직접 호출)**
   - Harness → 테스트 코드 (REST poll)
   - OutputEvent 직렬화 `API-04.1` 로 검증

표 1 책임 분할 매트릭스도 "탭 모드 / 다중창 모드" 열로 분리.

### 관련 파일
- `APIs/Overlay_Output_Events.md` §1.1-§1.2 (B-330 에서 재작성 예정) 와 정합
- `APIs/OutputEvent_Serialization.md` §1 in-process 주석 정리 (B-330 과 동시 수정)

## 수락 기준

- [ ] §2 시나리오 A / §2.5 시나리오 B / §2.6 시나리오 C 구조 확립
- [ ] 책임 분할 매트릭스에 모드별 열 추가
- [ ] Mermaid 또는 ASCII 로 3 시나리오 데이터 흐름 시각화
- [ ] §5 성능 예산 에 다중창 WS hop latency 항목 추가 (BO 중계 20-50ms)

## 관련

- Foundation §5.0, §6.3, §6.4
- 연동 선행: B-330 (Engine 별도 프로세스), B-332 (SSOT)
