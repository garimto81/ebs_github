---
title: Prototype Build Plan
owner: conductor
tier: internal
stream: S6
phase: P3
status: SKELETON-v0.3.0
last-updated: 2026-05-08
mode: validation
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
| 2026-05-08 | v0.3.0-skeleton | 사용자 directive Q1~Q5 답변 | §1/§3/§4.3/§4.4/§6 본문 채움 + §7 RESOLVED + Q6 신규 + fixture 6종 생성 + issue #189 |
| 2026-05-08 | v0.3.1-skeleton | autonomous iteration | huge-51mb gitignore 전환, §2 Stream 상태 갱신 (S1/S4 ACTIVE, S2/S3 NOT INIT), §5 fixture/ENV 의존 명세, `_doc-integrity.sh` 신설 (CCR-014/016/025/035 자동 검증 5/5 PASS) |

## Reader Anchor

EBS 프로토타입 빌드 + 통합 테스트 SSOT (Stream S6, Phase P3). 선행 Stream(S1/S2/S3/S4)의 P2 산출물을 입력으로 받아 Build 단계 + 검증 매트릭스를 정의한다. **현재 본 문서는 SKELETON 상태이며 본문 채움은 후속 세션에서 진행된다.**

---

## §1. 목적 / 범위

> 답하는 질문: **"무엇을, 어느 단계까지 만들어 검증하는가?"**

본 plan 의 mode = **validation** (기획서 검증용). production 출시 plan 이 아니다 (사용자 결정 2026-05-08, §7 Q1 RESOLVED).

### 1.1 검증 대상

EBS Core 흐름 = `WSOP LIVE + RFID + CC → Engine → Overlay`. 본 plan 은 이 중:

| 컴포넌트 | mode |
|----------|------|
| WSOP LIVE 입력 | mock (HTTP/JSON 합성) |
| **RFID 하드웨어** | **mock-only** (프로젝트 범위 밖, §7 Q2 RESOLVED) |
| Command Center | 정상 통합 (HTTP/WebSocket 검증) |
| Engine | 정상 통합 (harness HTTP) |
| Overlay | mock 렌더 + skin_updated 이벤트 |

### 1.2 production cascade 와의 경계

본 plan 의 결과(PASS/FAIL/UNKNOWN 보고서) = **production cascade 진입 게이트의 input**. SG-023 (2027-01 런칭, MVP 홀덤 1종) 에 직접 기여하지만 production 본체 plan 은 별도 (`Conductor_Backlog/B-040/B-055/B-067` 와의 정합은 Conductor 자율 판단 — §7 Q5 OPEN, issue #189).

---

## §2. 선행 Stream Inputs (read-only 의존)

| Stream | 산출물 | 사용처 | 상태 (2026-05-08) |
|:-:|--------|--------|:----------------:|
| S1 | `docs/1. Product/Foundation.md` | 비전·정체성 정합 | **ACTIVE** (init #169 + Foundation v4.5 #157) |
| S2 | `docs/1. Product/Lobby_PRD.md` | Lobby ↔ Backend 통합 시나리오 | **NOT INITIALIZED** |
| S3 | `docs/1. Product/Command_Center_PRD.md` | CC ↔ Engine ↔ Overlay 시나리오 | **NOT INITIALIZED** |
| S4 | `docs/1. Product/RIVE_Standards.md` | Overlay state machine 검증 | **ACTIVE** (init #172 + frontmatter 표준화) |
| S1 | `docs/1. Product/Game_Rules/**` | Engine harness 룰 분기 | **ACTIVE** (S1 일부) |

> 각 Stream의 P2 PR 머지 시 본 표의 `상태` 갱신. blocked_by 는 없으나 §3 Stage 3 (cascade 정합 검증) 진행 시 모든 P2 산출물 머지 필요.
> 자율 갱신 명령: `git log origin/main --oneline -50 | grep -E "feat\(S[1-5]\)|docs\(.*S[1-5]"`

---

## §3. Build 단계

validation mode 의 Build 단계 = **"기획서가 재구현 가능한지 검증할 수 있는 최소 단위 통합"** 으로 정의 (§7 Q1+Q2+Q5 RESOLVED).

| 단계 | 산출물 | 검증 게이트 | 의존 |
|:----:|--------|------------|------|
| Stage 1 | 통합 테스트 26건 (16 작성 완료 + 10 작성 필요) | backend mock-stack 위 **모두 PASS** | §4.4 fixture 6종 + JWT env |
| Stage 2 | §4.3 자동화 가능 영역 자동 검증 추가 (UI snapshot diff 후보) | UI 자동 비교 PASS | Stage 1 + S2/S3 P5 머지 |
| Stage 3 | 의존 Stream(S2/S3/S4) P2 산출물과의 cascade 정합 검증 | `tools/doc_discovery.py --impact-of` 결과 0 drift | Stage 2 + 의존 Stream P2 PR 머지 |

### 3.1 mock-only 전제

RFID 하드웨어 (`IRfidReader` 인터페이스) 는 `MockRfidReader` 만 사용. UART 연결 / 펌웨어 / 안테나 검증은 본 plan 의 Build 단계에 **포함하지 않는다**. vendor 도착 후 cascade 는 별도 트랙 (`memory/project_rfid_out_of_scope_2026_04_29.md`).

### 3.2 B-040/055/067 와의 관계

`Conductor_Backlog` 의 Phase 2/3/4 항목(B-040 E2E, B-055 부하, B-067 운영 검증) 와 본 §3 은 영역이 겹친다. Conductor 자율 판단 진행 중 — issue #189. 본 §3 은 **방안 3 가정 (분할: 본 plan = validation, 백로그 = production cascade)** 으로 작성됨. 결정 후 SSOT/인덱스 관계 갱신.

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

§7 Q4 RESOLVED — 본 세션에서 책임자 확정 (HAL/Audio 제외).

| 영역 | 사유 | **책임자** |
|------|------|----------|
| RFID HAL (CCR-022) | 물리 리더 / 펌웨어 / 안테나 | **N/A** (mock-only, §7 Q2 RESOLVED. vendor 도착 후 별도 cascade) |
| UI / 시각 (CCR-028, CCR-030, CCR-032, CCR-034) | Flutter 앱 / Overlay 렌더 / 색상 일관성 | **S6 (본 stream)** — Stage 2 자동화 시도 + 수동 보완 |
| Audio (CCR-033) | 채널 정책 / 사운드 매핑 | **TBD** (HAL/Audio 제외, §7 Q4 RESOLVED. team4-cc QA 후보 또는 S9 활성화 시 흡수) |
| Layer 경계 (CCR-035) | 문서 정합성 review | **S6** — `integration-tests/scenarios/_doc-integrity.sh` (CCR-014/016/025/035 자동 검증, 5/5 PASS @v0.3.1) |

### 4.4 Fixture 파일 (생성 완료 — v0.3.0 신규)

§7 Q3 RESOLVED — 본 세션에서 default minimal stub 6종 생성 (`integration-tests/fixtures/`).

| 파일 | 크기 | 목적 | 생성자 |
|------|:----:|------|:------:|
| `wsop-2026-test.gfskin` | ~466 B | 정상 ZIP — 201 Created | S6 |
| `invalid-colors.gfskin` | ~471 B | schema 위반 — 422 | S6 |
| `huge-51mb.gfskin` | ~51 MiB | 50MB 초과 — 413 | S6 |
| `missing-skin-json.gfskin` | ~123 B | 구조 결함 — 422 | S6 |
| `missing-skin-riv.gfskin` | ~365 B | 구조 결함 — 422 | S6 |
| `invalid-rive-magic.gfskin` | ~466 B | Rive magic 위반 — 422 | S6 |

재생성: `python integration-tests/fixtures/_generate.py`. 자세한 한계 및 SSOT 참조: `integration-tests/fixtures/README.md`.

> **stub 한계** (§7 Q6 신규): `skin.riv` 는 RIVE magic + version=7 placeholder 만 채운 stub. 실제 Rive 파싱 통과는 보장 X. 본격 Rive 디스플레이 검증이 필요하면 Rive 공식 에디터로 만든 `.riv` 로 교체 follow-up.

---

## §5. 의존성·블로커

| 항목 | 상태 (2026-05-08) |
|------|:------------------:|
| Stream 활성화 의존 (`blocked_by`) | ✓ 없음 (S6 활성화 완료, init PR #173) |
| §3 Stage 1 진행 의존 | ✓ fixture 6종 + ENV (아래 참조) |
| §3 Stage 2 진행 의존 | S2/S3 NOT INITIALIZED → **블록** |
| §3 Stage 3 진행 의존 | S2/S3/S4 P2 산출물 머지 → **부분 블록** (S1/S4 ACTIVE, S2/S3 미초기화) |
| §4 시나리오 실행 의존 | Backend BO (`http://localhost:8000`), Engine Harness (`http://localhost:8080`), JWT 환경변수 4종 (`ADMIN_JWT`/`OPERATOR_JWT`/`VIEWER_JWT`/`CC_SERVICE_JWT`) |
| §4.4 fixture 의존 | tracked 5종 ✓ + `huge-51mb.gfskin` (gitignored, 실행 직전 `python integration-tests/fixtures/_generate.py` 필수) |
| §4.3 책임 영역 | UI/시각·Layer 경계 = S6 (현 세션 시작), Audio = TBD |

---

## §6. 검증 게이트

validation mode 게이트 = **"기획서 항목별 PASS/UNKNOWN/FAIL 보고서 생성 + UNKNOWN/FAIL 0 도달"** (§7 Q1 RESOLVED).

### 6.1 자동 검증 게이트

| 게이트 | 기준 | 출력 |
|--------|------|------|
| 통합 테스트 pass | 26건 (Stage 1 산출물) 모두 PASS | CI on-merge job |
| Cascade 정합 | `tools/doc_discovery.py --impact-of` drift = 0 | Stage 3 |
| Scope 위반 0 | `git diff origin/main..HEAD --stat` S6 own 만 | PR gate |

### 6.2 수동 검증 게이트

§4.3 표의 S6 own 영역 (UI/시각, Layer 경계) 만 본 plan 책임. Audio/HAL 제외 (§7 Q4 RESOLVED).

### 6.3 production cascade 진입 조건

본 게이트 통과 + Conductor 결정 (issue #189, B-040/055/067 통합/인덱스 관계 자율 판단) → production cascade(SG-023 2027-01 런칭) 입력으로 전달.

---

## §7. Open Questions

### 7.0 요약

| # | 질문 (한줄) | 상태 | 답·이슈 |
|:-:|-------------|:----:|---------|
| Q1 | 이 plan은 production용 가이드인가, validation용 명세인가? | **RESOLVED** | validation (2026-05-08) |
| Q2 | RFID mock-only 일 때 §3 Build 어디까지? | **RESOLVED** | 프로젝트 범위 밖, mock-only (2026-05-08) |
| Q3 | fixture 6종 누가 만드는가? | **RESOLVED** | S6 본 세션 default 제작 (2026-05-08) |
| Q4 | 자동 검증 안 되는 영역 책임자? | **RESOLVED** | S6 (HAL/Audio 제외) (2026-05-08) |
| Q5 | 본 plan vs B-040/055/067 관계? | **OPEN** | issue [#189](https://github.com/garimto81/ebs_github/issues/189) — Conductor 자율 판단 |
| Q6 | `skin.riv` stub 이 실제 Rive 파싱 통과? | **OPEN** | follow-up — 백엔드 검증 깊이에 따라 결정 |

### 7.1 Q1 — 이 프로젝트는 "진짜 출시용"인가 "기획서 검증용"인가?

> 비유: 건물 모델하우스를 만들고 있는 것인가, 진짜 입주할 건물을 짓고 있는 것인가.

**배경**: 2026-04-20 결정으로 "기획서 완결 + 프로토타입은 검증 도구"였다가, 2026-04-27 SG-023 + B-Q6 ㉠ 채택으로 production 모드로 전환. MVP=홀덤 1종, 2027-01 런칭. 그러나 B-Q5/Q7/Q8/Q9 (MVP 정의 / 품질 기준 / 업체 RFI / 거버넌스) 미결정 상태.

**이전 모호 지점**: production 모드 vs validation 모드 사이에서 §3 깊이를 어디로 정할지 결정 못 함.

**RESOLVED (2026-05-08)**: 사용자 답 = "**기획서 검증용**". 본 plan 의 mode = validation. §1 본문에 명시 + §3 Build 단계 = "재구현 가능성 검증 가능한 최소 단위 통합" 으로 정의.

### 7.2 Q2 — RFID 하드웨어를 가짜(mock)로만 처리할 때 §3에서 어디까지 빌드하는가?

> 비유: 자동차 센서가 외부 업체에서 6주 뒤 도착한다. 그 동안 가짜 센서로 운전 시뮬레이션을 어디까지 할 것인가.

**배경**: 2026-04-29 사용자 결정 — RFID 하드웨어 = 프로젝트 범위 밖. vendor 발송 2026-05-01, 도착 2026-05-29 ~ 2026-06-12. `IRfidReader` 인터페이스 + `MockRfidReader` 만 사용.

**이전 모호 지점**: §3 Build 단계에 hardware harness 항목을 포함할지 여부.

**RESOLVED (2026-05-08)**: 사용자 답 = "RFID 하드웨어 연동 = 프로젝트 범위 밖. **Mock-only** 로 작업". §3.1 mock-only 전제 명시 + §4.3 RFID HAL 책임자 = N/A.

### 7.3 Q3 — 통합 테스트 입력으로 들어갈 더미 .gfskin 파일 6종을 누가 만드는가?

> 비유: 시험을 보려면 시험지가 있어야 한다. 시험지 출제자가 정해지지 않았다.

**배경**: §4.4 fixture 6종 (정상 1 + 결함 5). `.gfskin` = ZIP (skin.json + skin.riv + cards/ + assets/). 정식 schema SSOT 는 `docs/2. Development/2.2 Backend/APIs/Graphic_Editor_API.md §4.1` (team2 read-only).

**이전 모호 지점**: 책임 후보 = Team 4 / Conductor / S3 / S6 — 미확정.

**RESOLVED (2026-05-08)**: 사용자 답 = "**이 세션에서 default 제작**". S6 가 minimal stub 6종을 `integration-tests/fixtures/_generate.py` 로 생성. §4.4 표 갱신.

### 7.4 Q4 — 자동 검증이 안 되는 영역(HAL/UI/시각/Audio)은 어디서 책임지는가?

> 비유: 자동 채점 시험과 사람 채점 시험을 분리. 사람 채점은 누가?

**배경**: §4.3 수동 검증 영역 4종 (RFID HAL, UI/시각, Audio, Layer 경계). 본 plan 은 HTTP/WebSocket 자동 검증 담당. 시각/감각 검증은 범위 밖. `team_assignment_v10_3.yaml` 의 `future_streams.S9` (QA Stream) 가 흡수 후보 (활성화 trigger 미발생).

**이전 모호 지점**: S9 활성화 vs 각 team 자체 QA 책임 분배.

**RESOLVED (2026-05-08)**: 사용자 답 = "**이 세션에서 책임짐 (HAL/Audio 제외)**". S6 가 UI/시각 + Layer 경계 책임. HAL = N/A (mock-only). Audio = TBD (별도 흡수자 결정 필요). §4.3 표 갱신.

### 7.5 Q5 — 본 plan과 Conductor_Backlog의 기존 항목들(B-040/B-055/B-067)이 중복인가, 인덱스 관계인가?

> 비유: 같은 회의록을 두 사람이 따로 정리하면 양쪽 모두 부정확해진다. 둘 중 하나가 SSOT 이고 다른 하나가 인덱스여야 한다.

**배경**: `Conductor_Backlog/B-040` (Phase 2 E2E), `B-055` (Phase 3 부하), `B-067` (Phase 4 운영 검증) 와 본 plan §3·§6 영역이 겹친다.

**현재 상태**: **OPEN** — 사용자 답 = "**Conductor 가 자율 판단해야함. 이슈 발행 필요**" (2026-05-08). GitHub issue **[#189](https://github.com/garimto81/ebs_github/issues/189)** 발행 완료. 본 plan §3 은 일단 방안 3 (영역 분할: plan = validation, 백로그 = production cascade) 가정으로 작성. Conductor 결정 후 필요 시 §3·§6 재구조.

### 7.6 Q6 — `skin.riv` minimal stub 이 실제 Rive 파싱을 통과하는가? (신규)

> 비유: 시험지가 인쇄돼 있긴 한데 실제로 답을 적을 수 있는 종이인지 검증 안 됨.

**배경**: §4.4 fixture 의 `skin.riv` 는 `RIVE` magic + `0x07000000` + 32 zero bytes 만 포함하는 stub. 실제 Rive runtime 이 파싱할 때 통과한다는 보장 없음.

**현재 상태**: **OPEN** — Backend 검증이 magic + size 만 체크하면 stub 으로 충분. 본격 Rive 디스플레이 검증이 필요하면 Rive 공식 에디터로 만든 `.riv` 로 교체 follow-up. Stage 1 통합 테스트 첫 실행 결과 확인 후 결정.

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-08 | v0.1.0-skeleton | 최초 작성 (skeleton) — frontmatter + 챕터 placeholder + Open Questions 5건 | - | S6 Stream Phase P3 deliverable 시작 (init PR #173) |
| 2026-05-08 | v0.3.0-skeleton | Q1~Q5 답변 반영: §1 validation 모드 + §3 Build 단계 본문 + §4.3 책임자 확정 + §4.4 fixture 6종 생성 완료 + §6 게이트 본문 + §7 RESOLVED 마크 + Q6 신규 (skin.riv stub follow-up). issue #189 발행 (Q5 OPEN). | PRODUCT | 사용자 directive 5건 답변 (2026-05-08) |
