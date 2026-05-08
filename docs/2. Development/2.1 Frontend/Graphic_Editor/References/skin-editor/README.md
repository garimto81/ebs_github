---
title: README
owner: team1
tier: internal
last-updated: 2026-04-15
---

# skin-editor/ — ⚠️ team1 소유 (CCR-011)

## 상태

**이 폴더는 team1-frontend 소유권 이관 대기 중** (2026-04-14).

- CCR-011 (2026-04-10): Graphic Editor / Skin Editor 소유권 team1 Lobby로 이관
- team4는 Skin **Consumer** 역할 (skin_updated WebSocket 이벤트 수신 후 Overlay 리렌더)
- Skin Editor 원본 PRD 15종은 team1이 BS-08 구현 시 직접 필요한 자료

## 이관 계획

→ `team1-frontend/ui-design/reference/skin-editor/` 로 이동 예정.

## team4 Consumer 역할에 필요한 문서

이 폴더 파일을 읽을 필요는 없다. team4는 다음만 참조:

- `../../../../../Contracts/Data/DATA-07-gfskin-schema.md` — ZIP 포맷 + JSON Schema
- `../../../Specs/BS-07-overlay/BS-07-03-*.md` — Overlay 로드 FSM
- `WebSocket_Events.md` (legacy-id: API-05) — `skin_updated` 이벤트

## 금지

- team4 세션에서 이 폴더 파일 수정 금지 (CCR-011 소유권)
- team4 Consumer 로직 구현 시 이 폴더 PRD 인용 금지 — contracts/DATA-07 + specs/BS-07만 사용
