# Graphic Editor QA — ARCHIVED

이 디렉토리는 **CCR-011 (2026-04-10) 이전**의 team4 Graphic Editor QA 감사 기록입니다.

## 소유권 이관

**CCR-011**로 Graphic Editor의 소유권이 **team1 Lobby (Quasar+rive-js)** 로 이관되었습니다:

- GE UI 구현: `team1-frontend/src/screens/lobby/graphic-editor/`
- GE 행동 명세: `contracts/specs/BS-08-graphic-editor/` (BS-08-00~04, 5개 파일)
- GE API 스펙: `contracts/api/API-07-graphic-editor.md`
- GE 데이터 포맷: `contracts/data/DATA-07-gfskin-schema.md`
- **GE QA**: `team1-frontend/qa/graphic-editor/` (이관 대상, team1이 구현)

## team4의 잔여 역할 — Skin Consumer

team4 Overlay는 **`skin_updated` WebSocket 이벤트**(CCR-015)를 수신하여 BS-07-03 §5 로드 FSM으로 `.gfskin` ZIP을 in-memory 압축 해제(CCR-012) 후 Rive Canvas를 리렌더한다. GE UI 자체는 구현하지 않는다.

- Skin Consumer 구현: `team4-cc/src/lib/features/overlay/services/skin_consumer.dart`
- Skin 로더: `team4-cc/src/lib/repositories/skin_repository.dart`

## 이 디렉토리의 현 상태

- `graphic-editor/QA-GE-00-audit.md` — 과거 감사 결과 (3/10 위험 수준), history 보존
- `graphic-editor/QA-GE-01-strategy.md` — 과거 QA 전략, team1이 인용 가능
- `graphic-editor/QA-GE-02-checklist.md` — 과거 체크리스트 (예: Rive .riv 로딩 미구현 CRITICAL)

## 금지

- 이 디렉토리의 파일을 **수정 금지** (history 보존 전용)
- 신규 GE QA 작업은 `team1-frontend/qa/graphic-editor/`에서 수행
- team4 CLAUDE.md 금지 사항에 따라 `../team1-frontend/`에 직접 작성 금지 — team1이 인계받아 자체 작성

## 참조

- CCR-011 원본: `docs/05-plans/ccr-inbox/promoting/CCR-011-ge-ownership-move.md`
- Team 4 CLAUDE.md: `../../CLAUDE.md` (Role 섹션, Graphic Editor는 team1 소유 명시)
- BS-08 Graphic Editor: `../../../contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md`
