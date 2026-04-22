---
id: B-330
title: "Foundation §6.3 Engine 별도 프로세스 원칙을 API-04 전반에 전파"
status: PENDING
priority: P0
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §6.3 (프로세스 경계) / §6.4 (실시간 동기화)"
---

# [B-330] Foundation §6.3 Engine 별도 프로세스 원칙을 API-04 전반에 전파 (P0)

## 배경

2026-04-22 Foundation.md 재설계로 §6.3 이 다음을 확정:

> **Engine 배포 방식**: 별도 프로세스 (Docker container 또는 `dart run bin/harness.dart`). In-process 패키지 import (Option B) 는 비채택 — 바이너리 호환 복잡도 + 엔진 업데이트 시 CC 재빌드 강제 + 로그/오류 격리 약화.

그러나 team3 API 문서 3종은 여전히 Engine 이 CC 프로세스 내부에 있다는 전제로 쓰여 있다:

| 문서 | 위반 구절 |
|------|----------|
| `Overlay_Output_Events.md` §1.1-§1.2 | "CC Input → Game Engine → GameState 업데이트" / "in-process Dart 함수 호출" |
| `OutputEventBuffer_Boundary.md` §2 | "CC + Overlay + Engine 이 같은 Flutter 앱 내에서 실행되는 경우 (Phase 1 기본)" |
| `OutputEvent_Serialization.md` §1 | "CC 내부(같은 Flutter 프로세스)는 Dart 객체를 직접 전달할 수도 있으나" |

## 수정 대상

1. **`APIs/Overlay_Output_Events.md`**
   - §1.1 파이프라인: "CC Input → Engine (REST) → CC → Overlay" 로 재작성. Engine 이 in-process 가 아님을 명시
   - §1.2 데이터 전달 방식 표: CC↔Engine 은 REST (≤ 20ms 로컬), CC↔Overlay 만 탭 모드 in-process / 다중창 모드 BO 경유
   - §개요 "동일 프로세스" 원칙 수정: "CC 와 Overlay 는 같은 Flutter 바이너리 (탭 모드) 또는 독립 프로세스 (다중창 모드)" / "Engine 은 항상 별도 프로세스"

2. **`APIs/OutputEventBuffer_Boundary.md`**
   - §2 제목 변경: "Dart Stream 인터페이스 (in-process)" → "Dart Stream 인터페이스 (탭 모드 — CC+Overlay in-process)"
   - §2 전제 수정: "CC + Overlay + Engine 이 같은 Flutter 앱" → "CC + Overlay 만 같은 Flutter 앱 (탭 모드). Engine 은 항상 REST 원격"
   - §3 "WebSocket 경로 (프로세스 분리 시)" 를 **기본 경로**로 승격. Engine→CC 는 REST pull, 다중창 모드의 CC→Overlay 는 BO 경유 WS broadcast

3. **`APIs/OutputEvent_Serialization.md`**
   - §1 "in-process vs 네트워크" 주석 수정: "Engine→CC 는 항상 JSON. CC→Overlay 는 탭 모드 때만 Dart 객체 직접 전달 가능"

## 수락 기준

- [ ] 3 문서 모두에서 "Engine 이 CC 프로세스 내부" 가정을 제거
- [ ] "탭 모드 / 다중창 모드 / Engine" 3 주체 구분 명시
- [ ] `Overlay_Output_Events.md §1.1` 파이프라인 Mermaid 를 Foundation §6.3 시나리오 A/B 와 정합
- [ ] 관련 subscriber 팀(team4) 에 `notify: team4` 커밋 태그

## 관련

- Foundation §4.4, §5.0, §6.3, §6.4
- 연동 항목: B-334 (OutputEventBuffer 3 런타임 분법)
