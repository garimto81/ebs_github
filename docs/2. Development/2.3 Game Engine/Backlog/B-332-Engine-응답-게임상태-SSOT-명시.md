---
id: B-332
title: "Engine 응답이 게임 상태 SSOT 임을 API-04 계약에 명시"
status: PENDING
priority: P0
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §6.3 §1.1.1 (병행 dispatch) / §6.4 (Engine SSOT)"
mirror: none
---

# [B-332] Engine 응답이 게임 상태 SSOT 임을 API-04 계약에 명시 (P0)

## 배경

Foundation §6.3 병행 dispatch 시나리오 A/B + §6.4 "Engine SSOT" 원칙:

> 게임 상태(hands/cards/pots)는 **Engine 응답이 최종 SSOT**. BO WS 는 audit 용 참고값. BO 실패 시 warn-only (게임 진행 계속, §1.1.1 실패 매트릭스)

CC 는 Orchestrator 로서 BO/Engine 을 **병렬** 호출 (동일 correlation_id). Engine 응답이 gameState + outputEvents 기준이고, BO ack 는 audit 참고값.

team3 API 문서는 이 SSOT 원칙을 명시하지 않아 소비자(CC/team4) 가 Engine 을 참고값으로 오해할 여지가 있다.

## 수정 대상

### `APIs/Harness_REST_API.md`
- 신규 §0 또는 §개요 말미에 "SSOT 선언" 블록 추가:
  > Engine 응답은 **게임 상태(hands/cards/pots/actionOn/legalActions) 의 최종 SSOT**. CC 는 Engine 응답을 받는 즉시 provider 에 반영해야 하며, BO WS 로 도달한 ack 는 audit 참고값이다.
- §5 "사용 흐름 예시" 에 병행 dispatch (BO/Engine 동시 호출) 시퀀스 추가

### `APIs/Overlay_Output_Events.md`
- §1.1 파이프라인 재작성 (B-330 과 연동): CC Orchestrator → BO/Engine 병렬 → Engine gameState/outputEvents SSOT → Overlay 렌더
- §1.3 GameState 필드 표 상단에 "Engine 응답이 SSOT. BO WS payload 는 audit/monitor 용" 주석

### `APIs/OutputEvent_Serialization.md`
- §4 "경계 및 소비 모델" 에 "Engine SSOT: Engine.applyFull() → ReduceResult.outputEvents 가 최종 발행. BO 재발행본은 audit 참고값" 추가

## 수락 기준

- [ ] 3 문서 모두 "Engine SSOT" 용어 등장 + Foundation §6.4 참조
- [ ] "BO ack = audit 참고값" 원칙 명시
- [ ] Mermaid 시퀀스에 동일 correlation_id 로 병행 dispatch 표현
- [ ] subscriber 팀(team4) 대상 `notify: team4` 커밋

## 관련

- Foundation §6.3 §1.1.1, §6.4
- 연동: B-330 (Engine 별도 프로세스), B-335 (WriteGameInfo SSOT)
