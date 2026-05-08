---
title: Prototype Build Plan
owner: conductor
tier: internal
stream: S6
phase: P3
status: SKELETON
last-updated: 2026-05-08
derivative-of:
  - "docs/1. Product/Foundation.md"
  - "docs/1. Product/Lobby_PRD.md"
  - "docs/1. Product/Command_Center_PRD.md"
  - "docs/1. Product/RIVE_Standards.md"
if-conflict: derivative-of takes precedence
predecessors:
  - path: "integration-tests/scenarios/README.md"
    relation: absorbed
    reason: "S6 흡수 대상 (team_assignment_v10_3.yaml absorbs_existing)"
provenance:
  triggered_by: stream_activation
  trigger_summary: "S6 Prototype Stream 첫 세션 — Phase P3 deliverable 시작"
  trigger_date: "2026-05-08"
  init_pr: "#173"
---

## Edit History

| 날짜 | 버전 | 트리거 | 변경 |
|------|:----:|--------|------|
| 2026-05-08 | v0.1.0-skeleton | S6 Stream 활성화 (PR #173) | 최초 skeleton 생성 |

## Reader Anchor

EBS 프로토타입 빌드 + 통합 테스트 SSOT (Stream S6, Phase P3). 선행 Stream(S1/S2/S3/S4)의 P2 산출물을 입력으로 받아 Build 단계 + 검증 매트릭스를 정의한다. **현재 본 문서는 SKELETON 상태이며 본문 채움은 후속 세션에서 진행된다.**

---

## §1. 목적 / 범위

> 답하는 질문: **"무엇을, 어느 단계까지 만들어 검증하는가?"**

(placeholder — 후속 세션에서 확정)

확정 필요 항목:
- Phase 3 prototype 의 정의 (EBS Core = `WSOP LIVE + RFID + CC → Engine → Overlay`) 중 어디까지 mock vs real?
- §7 Open Questions의 RFID mock-only 결정과의 정합 명시.
- Production intent (SG-023, MVP 2027-01 런칭) vs Phase 3 prototype validation 의 경계.

---

## §2. 선행 Stream Inputs (read-only 의존)

| Stream | 산출물 | 사용처 | 상태 |
|:-:|--------|--------|:----:|
| S1 | `docs/1. Product/Foundation.md` | 비전·정체성 정합 | TBD |
| S2 | `docs/1. Product/Lobby_PRD.md` | Lobby ↔ Backend 통합 시나리오 | TBD |
| S3 | `docs/1. Product/Command_Center_PRD.md` | CC ↔ Engine ↔ Overlay 시나리오 | TBD |
| S4 | `docs/1. Product/RIVE_Standards.md` | Overlay state machine 검증 | TBD |
| S1 | `docs/1. Product/Game_Rules/**` | Engine harness 룰 분기 | TBD |

> 각 Stream의 P2 PR 머지 시 본 표의 `상태` 갱신. blocked_by 는 없으나 §3 Build 단계 진행 시 의존.

---

## §3. Build 단계 (placeholder)

| 단계 | 산출물 | 검증 게이트 | 의존 |
|:----:|--------|------------|------|
| Stage 1 | (TBD) | (TBD) | - |
| Stage 2 | (TBD) | (TBD) | Stage 1 |
| Stage 3 | (TBD) | (TBD) | Stage 2 |

(placeholder — 단계 정의는 §2 Inputs 확정 후 작성)

---

## §4. 통합 테스트 매트릭스 (`integration-tests/` 흡수)

### 4.1 작성 완료 (16건)

자세한 매핑은 `integration-tests/scenarios/README.md` 참조. CCR 커버리지 그룹:

| 그룹 | 범위 | CCR |
|:----:|------|-----|
| 10~19 | Auth / Idempotency / Saga / WS Replay | 010, 018, 019, 020, 021 |
| 20~29 | Graphic Editor + DATA-07 + skin_updated | 011, 012, 013, 014, 015 |
| 30~39 | CC Launch / BO Recovery / WriteGameInfo / Statistics | 024, 027, 029, 031 |
| 40~49 | Overlay / Security Delay / Color sync | 023, 025, 033, 034, 036 |
| 50~59 | RFID / Deck Register | 022, 026 |
| 60~69 | team1 WSOP Parity (Event/Flight/Table/RBAC) | 016, 017 |

### 4.2 작성 필요 (10건)

| 우선순위 | 시나리오 | CCR |
|:--------:|---------|-----|
| High | `33-cc-action-on-response.http` | CCR-031 (W9, W15) |
| Medium | `24-ge-delete-active.http` | CCR-013 §8 |
| Medium | `25-gfskin-zip-validation.http` | CCR-012 |
| Medium | `41-overlay-messagepack.http` | CCR-023 |
| Low | `14-data-idempotency-audit.http` | CCR-018 |
| Low | `34-cc-statistics-push.http` | CCR-027 |
| Low | `35-cc-game-settings-modal.http` | CCR-028 |
| Low | `36-cc-player-edit-modal.http` | CCR-028 |
| Low | `42-overlay-color-override.http` | CCR-025 |
| Low | `63-blind-detail-type.http` | CCR-017 §3 |

### 4.3 수동 검증 영역 (`integration-tests/` 범위 밖)

| 영역 | 사유 | 책임 후보 |
|------|------|----------|
| RFID HAL (CCR-022) | 물리 리더 / 펌웨어 / 안테나 | team3-engine 또는 별도 HAL harness |
| UI / 시각 (CCR-028, CCR-030, CCR-032, CCR-034) | Flutter 앱 / Overlay 렌더 / 색상 일관성 | team4-cc QA |
| Audio (CCR-033) | 채널 정책 / 사운드 매핑 | team4-cc QA |
| Layer 경계 (CCR-035) | 문서 정합성 review | grep 기반 정합성 스크립트 |

→ S9 QA Stream(future) 활성 시 흡수 검토 (§7 Open Question).

### 4.4 Fixture 파일 (대기 중)

`integration-tests/fixtures/` 에 필요:
- `wsop-2026-test.gfskin` — 정상 ZIP
- `invalid-colors.gfskin` — schema 위반
- `huge-51mb.gfskin` — 50MB 초과
- `missing-skin-json.gfskin`, `missing-skin-riv.gfskin` — 구조 결함
- `invalid-rive-magic.gfskin` — Rive 포맷 위반

(생성 책임 미확정 — §7 Open Question)

---

## §5. 의존성·블로커

| 항목 | 상태 |
|------|:----:|
| Stream 활성화 의존 (`blocked_by`) | 없음 (S6 즉시 활성화 가능, PR #173 머지 완료) |
| §3 Build 단계 진행 의존 | S2/S3/S4 P2 PR 머지 필요 |
| §4 시나리오 실행 의존 | Backend BO (`http://localhost:8000`), Engine Harness (`http://localhost:8080`), JWT 환경변수 |
| Fixture 의존 | §4.4 .gfskin 파일 6종 |

---

## §6. 검증 게이트 (placeholder)

(후속 세션 — 본문 작성)

확정 필요 항목:
- E2E pass 기준 (전체 통과 / 부분 통과 허용 범위)
- 계약 충족 매트릭스 (CCR-010~036 각각의 PASS/FAIL 기준)
- Phase 3 → Phase 4 (운영 검증) 진입 조건
- 회귀 검증 frequency (CI on-merge / nightly / on-demand)

---

## §7. Open Questions

| # | 질문 | 영향 |
|:-:|------|------|
| Q1 | B-Q5~Q9 (MVP/Phase/런칭/업체/거버넌스/품질) 와 본 plan 의 정합? Production intent (SG-023) vs Phase 3 prototype validation 경계 | §1, §3 |
| Q2 | RFID 하드웨어 mock-only 결정 (`memory/project_rfid_out_of_scope_2026_04_29.md`) 이 §3 Build 단계 어디까지 영향? | §3, §4.3 |
| Q3 | §4.4 fixture 파일은 누가 작성? Team 4 vs Conductor vs S3 vs S6 자체? | §4.4 |
| Q4 | HAL/UI/시각 검증을 S9 QA Stream(future) 가 흡수해야 하는가? 본 plan 의 §4 범위 밖 표시 어떻게? | §4.3 |
| Q5 | §3 Build 단계 정의 시 docs `Conductor_Backlog/B-040` (Phase 2 통합 테스트 E2E), `B-055` (Phase 3 부하 테스트), `B-067` (Phase 4 전격 운영 검증) 와의 통합/위임 관계? | §3, §6 |

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-08 | v0.1.0-skeleton | 최초 작성 (skeleton) — frontmatter + 챕터 placeholder + Open Questions 5건 | - | S6 Stream Phase P3 deliverable 시작 (init PR #173) |
