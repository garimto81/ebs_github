---
id: B-332
title: "Engine 응답이 게임 상태 SSOT 임을 API-04 계약에 명시"
status: DONE
priority: P0
created: 2026-04-22
completed: 2026-05-11
completed-stream: S8
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §B.3 (통신 매트릭스 — 병행 dispatch) / §B.4 (DB SSOT + WS push)"
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

- [x] 3 문서 모두 "Engine SSOT" 용어 등장 + Foundation §B.4 (=구 §6.4) 참조 ✅ 2026-05-11 (Harness §SSOT 선언 / Overlay §1.1·§1.3 / OutputEvent_Serialization §4.1)
- [x] "BO ack = audit 참고값" 원칙 명시 ✅ 2026-05-11 (3 문서 모두)
- [x] Mermaid 시퀀스에 동일 correlation_id 로 병행 dispatch 표현 ✅ 2026-05-11 (Harness §5.2 신설)
- [x] subscriber 팀(team4) 대상 `notify: team4` 커밋 ✅ 2026-05-11

## 완료 요약 (2026-05-11)

본 항목은 점진적으로 완성됨:

| 시점 | 추가 작업 | 파일 |
|------|----------|------|
| 2026-04-22 | §개요 SSOT 선언 블록 신설 | Harness_REST_API.md (B-332 1차) |
| 2026-04-22 | §1.3 GameState SSOT 주석 | Overlay_Output_Events.md (B-332 1차) |
| 2026-04-22 | §4.1 SSOT 선언 추가 | OutputEvent_Serialization.md (B-332 1차) |
| 2026-05-08 | §SSOT 선언 stateless 명시 보강 | Harness_REST_API.md (S8 D3 audit) |
| **2026-05-11** | **§5.2 병행 dispatch Mermaid 신설** | **Harness_REST_API.md (B-332 마무리)** |

마무리 컴포넌트인 Mermaid sequenceDiagram 이 §5.2 에 추가되며 4/4 수락 기준 모두 충족. B-330 과 함께 동일 PR (#227) 에 누적.

## 관련

- Foundation §B.3 (통신 매트릭스), §B.4 (DB SSOT + WS push). 백로그 본문의 §6.3/§6.4 numbering 은 Foundation v11 재설계 후 §B.x 로 재배치됨
- 연동: B-330 (Engine 별도 프로세스, 동시 완료 2026-05-11), B-335 (WriteGameInfo SSOT, 후속)
