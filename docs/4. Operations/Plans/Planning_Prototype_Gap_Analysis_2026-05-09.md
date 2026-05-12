---
title: 기획-프로토타입 정합성 분석 보고서 (2026-05-09)
owner: conductor
tier: internal
last-updated: 2026-05-09
related:
  - 1. Product/Foundation.md
  - 1. Product/Lobby.md
  - 1. Product/Command_Center.md
  - 1. Product/Back_Office.md
  - 2. Development/2.5 Shared/Risk_Matrix.md
  - 4. Operations/Conductor_Backlog.md
  - 4. Operations/Roadmap.md
---

# 기획-프로토타입 정합성 분석 보고서

> **분석 대상**: EBS (Live Poker Broadcasting System) 전체
> **기준일**: 2026-05-09
> **방법**: 3-stream 병렬 Explore (기획 / 정본 / 코드) → 교차 검증 → 갭 매트릭스
> **신뢰도**: HIGH (모든 결론 file:line 인용 가능, READ-ONLY 분석)

---

## Context

직전 작업으로 `C:\Claude\EBS`가 `garimto81/ebs_github` 메인 레포로 연결됨(commit `10aa78e` push, 2026-05-09). 본 보고서는 레포 내용을 진단해 다음 phase(통합 QA / Phase 5) 진입 전 의사결정을 돕는 산출물.

### 분석 축

1. **기획 (`docs/1. Product/`)**: Foundation + 3 PRD + Game_Rules + SSOT 정책 → "무엇을 만들 것인가"
2. **정본 (`docs/2. Development/`)**: 8 Overview + APIs + Behavioral_Specs → "어떻게 만들 것인가"
3. **프로토타입 (`team{1-4}/`, `schemas/`, `integration-tests/`, `infra/`)**: 실제 코드 → "현재 어디까지 만들었는가"

### 분석 목표

- 세 축의 정합성 매트릭스 산출
- 임계 갭(블로커) 식별
- 권장 다음 단계 5선 (의존성·병렬화 정렬)

---

## Executive Summary

| 차원 | 점수 | 판정 |
|------|:----:|:----:|
| 기획 ↔ 정본 정합성 | 9.0 / 10 | 매우 높음 (Phase 0 cascade 완료, PRD 충돌 0건) |
| 정본 ↔ 프로토타입 정합성 | 7.0 / 10 | 양호 (구조·계약 PASS, 일부 핵심 매핑 미완) |
| 프로토타입 자체 완성도 | 7.5 / 10 | Partial (4팀 평균 70-80%, 통합 단계 진입 가능) |
| **종합 — 통합 QA 진입 준비도** | **7.5 / 10** | **준비 가능. 단 3개 Critical Gap 해소 필요** |

**한 줄 진단**: EBS는 **기획 SSOT가 견고하고 4팀 모두 코드 70-80% 완성** 상태. **부품은 충분, 조립이 미완**. 3개 Critical Gap (Overlay Rive 매핑 / E2E 핸드 플로우 통합 테스트 / Backend 커버리지 17%p) 해소 시 Phase 5 진입 가능.

---

## 1. 정합성 매트릭스 — 4 컴포넌트 × 3 축

| 컴포넌트 | 기획 (PRD) | 정본 (Overview/API) | 프로토타입 (코드) | Δ (갭) |
|---------|-----------|--------------------|------------------|--------|
| **Lobby (team1)** | `Lobby.md` (2026-05-07) — 5화면 시퀀스 정의 | `2.1 Frontend/Lobby/Overview.md` ~1000줄, 66 API 정의 | Flutter Web, 7 features, 10 tests | ⚠ Quasar 잔재(node_modules, pnpm-lock) 미정리 / Players·Audit_Log·Hand_History 미구현(8선언 vs 6실측) |
| **Command Center (team4)** | `Command_Center.md` v4.0 (2026-05-07) — 1×10 그리드, 6키, HandFSM 9-state | `2.4 Command Center/Command_Center_UI/Overview.md` 813줄, 20+ 이벤트 | Flutter Desktop, 6 features, 25 tests, Engine 3-stage UI 완성 | 🔴 Overlay Rive 21 OutputEvent **매핑 0/21** (skeleton) |
| **Game Engine (team3)** | `Foundation.md` Ch.5 §B.1 — 21 OutputEvent / Game_Rules 22종 | `2.3 Game Engine/Behavioral_Specs/Overview.md`, OutputEvent 21종 정의 | Pure Dart, 25 variants, 40 tests, 21/21 OutputEvent ✅ | △ Draw 7종/Stud 3종 variant 테스트 완결성 / HandEvaluator Low·Sidepot |
| **Back Office (team2)** | `Back_Office.md` (2026-05-08) — 9영역 채택/13제외 | `2.2 Backend/Back_Office/Overview.md` 351줄, 77+ API | FastAPI, 261 tests / 78% cov, 16 routers, 13 services | ⚠ 커버리지 95% 목표 대비 -17%p / reports.py MV mock / decks.py DB session(IMPL-003) |

**판정**: 4 컴포넌트 모두 기획→정본→코드의 cascade 사슬은 형성되어 있음. **단절은 Overlay 매핑 한 곳뿐** — 그러나 이것이 시각적 최종 산출물의 진입점이라 **리스크 가중치는 가장 높음**.

---

## 2. Critical Gap 리스트 (우선순위 정렬)

| # | 갭 | Severity | Owner | 기획 근거 | 현 상태 | 블로커? |
|:-:|----|:--------:|:-----:|----------|---------|:-------:|
| 1 | **Overlay Rive 21 OutputEvent 매핑** | 🔴 HIGH | team4 | `Foundation.md` Ch.5 §B.1 (오버레이 = MVP 핵심 산출물) | OutputEvent 21종 정의 PASS, Rive 위젯 매핑 skeleton | YES — 시청자 산출물 미생성 |
| 2 | **End-to-End 핸드 플로우 통합 테스트** | 🔴 HIGH | Conductor + 4팀 | `Foundation.md` Ch.5 의존성 사슬 (RFID→Engine→CC→BO→Overlay) | `integration-tests/`에 단계별 .http 18개, **deal→flop→showdown 풀 핸드 시나리오 없음** | YES — 회귀 검출 불가 |
| 3 | **Backend 커버리지 17%p 갭** | 🟠 MEDIUM | team2 | `Back_Office.md` Ch.7 SLO (가용성 99.5%, 50+ commit/sec) | 261/261 PASS, 78% / 95% 목표, `B-Q10-95-coverage-roadmap.md` | NO (단계적 해소 가능) |
| 4 | **NFR "정확성" 정량 수치 부재** | 🟠 MEDIUM | Conductor (Foundation) | `Foundation.md` Ch.1 Scene 4 — "정확성"이 5 핵심가치 1순위 | 응답·가용·복구는 수치화, 정확성은 정성 표현만 | NO (운영 KPI 누락) |
| 5 | **team1 Quasar 잔재 정리** | 🟡 LOW | team1 | `1. Product.md` γ하이브리드 — Flutter 통일 결정 | node_modules, pnpm-lock.yaml, .quasar/ 잔존 (기술 부채) | NO |
| 6 | **RFID 실하드웨어(ST25R3911B)** | 🟡 LOW (의도적 deferral) | team4 + HW팀 | MVP 필수 (`Foundation.md` Ch.5 §C.3) | MockRfidReader만, SG-011로 Phase 2 명시 deferral | NO (1단계 폴백 충분) |
| 7 | **decks.py / reports.py 실DB 전환** | 🟡 LOW | team2 | API-01 (Backend_HTTP.md) | 다수 mock, IMPL-003 진행 | NO (점진 전환) |
| 8 | **CI/CD 워크플로 정리** | 🟡 LOW | Conductor | — | 14 워크플로 중 1개 active(team1-e2e), legacy 다수 | NO (운영 정리 차원) |

**핵심 통찰**: 8개 갭 중 **블로커는 #1, #2 두 건뿐**. 둘 다 "단위는 있고 통합이 빈" 패턴. 즉 **부품은 충분, 조립이 미완**.

---

## 3. 정합 강점 (잘 된 것)

기획-프로토타입 정합도가 높은 영역. 현재 페이스 유지가 권장되는 부분.

| 영역 | 증거 |
|------|------|
| **PRD 간 정의 충돌 0건** | Lobby/CC/BO 3 PRD + Foundation 5/8 cascade, last-updated 2026-05 최신, SG-033 cascade PASS |
| **계약(Contract) 명확성** | 100+ REST endpoint (API-01), 20+ WS event (API-05), 21 OutputEvent (API-04), JWT TTL 환경별 명시 (BS-01) |
| **공유 타입 패키지** | `shared/ebs_common/` — Permission RBAC, UuidIdempotency, SeqTracker, ws_event_envelope (Freezed 직렬화) → team1·team4 path dep로 일관 |
| **22 게임규칙 외부 표현화** | `Game_Rules/{Flop,Draw,Seven_Card,Betting}` → Engine 25 variant 구현 (NLH/PLH/Omaha/ShortDeck/Draw/Stud/Razz/Badugi 등) |
| **인프라 운영성** | Docker Compose 5 서비스 (bo:8000, redis:16379, engine:8080, lobby-web:3000, cc-web:3001), `ebs-net` bridge, health check 정의 |
| **거버넌스 명문화** | Risk_Matrix LOW/MEDIUM/HIGH 분류, v7 free_write + decision_owner (CCR 폐기 2026-04-27), Stream_Entry_Guide |
| **Engine 분리도** | team3 Pure Dart (Flutter/HTTP 의존 없음), `bin/harness.dart`에만 dart:io — SSOT 의존 격리 우수 |
| **Auth SSOT** | BS-01 (46KB) — JWT 환경별 TTL(dev 1h/live 12h), 2FA 4-level, Rate Limiting, Session reauth 60s 타임아웃 |

---

## 4. 도메인 모델 일관성 — FSM 사슬 검증

기획 → 정본 → 코드 전 영역에 동일하게 구현되어야 하는 핵심 모델.

| 모델 | 기획 (Foundation) | 정본 (BS-00) | 코드 (구현) | 일관성 |
|-----|:-----------------:|:------------:|:----------:|:------:|
| **TableFSM** | EMPTY → SETUP → LIVE → PAUSED → CLOSED | ✅ §3.1 | team2 enum / team1 view-model | ✅ |
| **HandFSM** | 9-state (SETUP_HAND 재삽입 v4.0) | ✅ §3.2 | team3 lib/core/state | ✅ |
| **SeatFSM** | 9-state (WSOP LIVE 준거) | ✅ §3.3 | team2 + team1 매핑 | ✅ |
| **DeckFSM** | UNREGISTERED→REGISTERING→REGISTERED→MOCK | ✅ §3.4 | team4 RFID provider | ✅ |
| **EventFSM** | 6-state (Created~Canceled) | ✅ §3.5 | team2 schema | ✅ |
| **ClockFSM** | STOPPED/RUNNING/PAUSED/BREAK/DINNER_BREAK | ✅ §3.7 | 🟡 team3 구체화 진행중 | △ |
| **Settings 5-level scope** | User > Table > Event > Series > Global | ✅ BS-03 (2026-04-27 PASS) | team2 settings_kv (11 test PASS), team1 5탭 교차검증중 | ✅ |

**결론**: FSM 6/7 완전 정합. ClockFSM 1건만 team3 구체화 진행 중 — 일관성 점수 매우 높음.

---

## 5. 통합 계약 vs 통합 테스트 갭 분석

| 통합 지점 | 계약 정의 | 단위 테스트 | 통합 테스트 | E2E 시나리오 |
|----------|:---------:|:-----------:|:-----------:|:------------:|
| Lobby ↔ BO REST | API-01 (77 endpoint) | ✅ team2 261 | ✅ `auth-10*.http`, `lobby-30*.http` | ⚠ rebalance saga만 |
| Lobby ↔ BO WebSocket | API-05 (3 채널, 20+ event) | ✅ envelope 직렬화 | ✅ `seq-replay-*.http` | ⚠ 연결복구만 |
| CC ↔ Engine HTTP | Harness_REST_API.md | ✅ team3 39 + team4 stub | △ engine-cc-bridge | ❌ 없음 |
| CC ↔ Overlay (Rive) | API-04 21 OutputEvent | △ team3 21/21 정의, team4 0/21 매핑 | ❌ 없음 | ❌ 없음 |
| RFID HAL → CC | API-03 IRfidReader | ✅ MockRfidReader | ✅ `rfid-50*.http` | ⚠ Mock만 |
| **End-to-End 핸드** | `Foundation.md` Ch.5 사슬 | (각 단계 ✅) | ❌ **없음** | ❌ **없음** |

**임계 갭**: "End-to-End 핸드" 행이 통째로 비어있음. 즉 **실제 시청자 화면이 나오는 전 파이프라인을 검증하는 테스트가 없다**. 이게 #1, #2 갭의 직접 원인.

---

## 6. 권장 다음 단계 (우선순위 5선)

기획 위배 없이 갭을 단계적으로 해소하는 행동안. 의존성 정렬 + 병렬화 가능 항목 표시.

| 순위 | 액션 | 기대 효과 | 예상 비용 | Owner | 의존 |
|:----:|------|----------|----------|:-----:|:----:|
| **1** | **Overlay Rive 21 OutputEvent 매핑 sprint** — `team4-cc/src/lib/features/overlay/`에 21종 OutputEvent → Rive state machine 매핑 위젯 작성. Engine harness stub로 single-event smoke test부터. | MVP 시각 산출물 동작 가능. 통합 QA 진입 1차 차단 해소 | 1-2 week (team4) | team4 | team3 OutputEvent 정의 (완료) |
| **2** | **End-to-End 풀 핸드 통합 테스트 시나리오** — `integration-tests/scenarios/v99-full-hand-flow.http` 작성: deal→preflop→flop→turn→river→showdown→pot 분배. RFID Mock + Engine harness + BO + CC + Overlay 풀 체인. | 회귀 검출 가능. 4팀 협업 단절점 가시화 | 3-5 day (Conductor + 각 팀 1명) | #1 부분 완료 후 (또는 Overlay assertion 생략하고 먼저) |
| **3** | **Backend 커버리지 78% → 90% (1차)** — `B-Q10-95-coverage-roadmap.md` 따라 reports.py MV 실구현 + decks.py DB 세션 교체(IMPL-003) + publishers.py 실 wiring. 95%는 다음 단계. | SLO 99.5% 달성 신뢰도 상승. team2 부채 청산 | 1 week (team2) | 독립 진행 가능 |
| **4** | **NFR "정확성" 정량 KPI 정의** — `Foundation.md` Ch.1에 항목 추가 (예: 핸드 분배 결정 일치율 ≥ 99.99%, OutputEvent 누락률 ≤ 0.01%, 측정 인프라 명시). 운영 대시보드 메트릭 후속. | 1단계 완전안정화(X4) 판정 기준 확보. 2단계 무인화 진입 기준선 | 2-3 day (Conductor + team2 협의) | 독립 진행 가능 |
| **5** | **team1 Quasar 잔재 정리 + 미구현 feature 매니페스트 갱신** — node_modules/pnpm-lock/.quasar/ 삭제, Players/Audit_Log/Hand_History 3 feature를 정본 8선언과 정합 (구현하든 선언에서 빼든). | 기술 부채 감소. team1 빌드 단순화 | 0.5 day (team1) | 독립 진행 가능 |

**병렬화 권장**: **1 + 3 + 5 동시 진행** 가능 (각각 다른 팀). 2는 1 부분 완료 후 시작이 효율적이지만 Overlay assertion을 stub로 두고 먼저 시작도 가능.

---

## 7. 검증 방법 (재현 가능)

이 보고서의 모든 결론은 다음 명령으로 재검증 가능 (READ-ONLY).

```powershell
# 1. PRD 정합성: last-updated 확인
Select-String -Path "C:\Claude\EBS\docs\1. Product\*.md" -Pattern "last-updated:"

# 2. 정본 8 Overview 존재 확인
Get-ChildItem "C:\Claude\EBS\docs\2. Development\**\Overview.md" -Recurse

# 3. 21 OutputEvent 정의 위치
Get-Content "C:\Claude\EBS\team3-engine\ebs_game_engine\lib\core\actions\output_event.dart" | Select-String "class.*Event"

# 4. Backend 테스트 카운트
Get-ChildItem "C:\Claude\EBS\team2-backend\tests\" -Recurse -Filter "test_*.py" | Measure-Object

# 5. 통합 테스트 시나리오
Get-ChildItem "C:\Claude\EBS\integration-tests\" -Recurse -Filter "*.http" | Measure-Object

# 6. Overlay Rive 매핑 검색 (없음을 확인)
Select-String -Path "C:\Claude\EBS\team4-cc\src\lib\features\overlay\**\*.dart" -Pattern "OutputEvent" -List
```

각 명령의 예상 결과:

| # | 예상 결과 |
|:-:|----------|
| 1 | 5개 PRD 모두 `2026-05-0[7-8]` (3주 이내) |
| 2 | 정확히 8개 파일 |
| 3 | 21개 sealed class |
| 4 | ~48 파일 (261 tests) |
| 5 | ~18 .http |
| 6 | skeleton만 매칭, 21 OutputEvent enum 매핑 없음 |

---

## 8. 변경 거버넌스 (Risk Matrix 기반)

권장 액션 5선의 변경 거버넌스 분류 (`docs/2. Development/2.5 Shared/Risk_Matrix.md` 기준).

| 순위 | 변경 유형 | 영향팀 | 거버넌스 |
|:----:|:--------:|:------:|----------|
| 1 | `add` only (위젯 신규) | 1팀 (team4) | LOW — publisher 직접 반영 |
| 2 | `add` only (시나리오 신규) | ≤4팀 | MEDIUM — 영향팀 전원 approve (cross-team test) |
| 3 | `modify` (비파괴) | 1팀 (team2) | LOW |
| 4 | `modify` (Foundation NFR 추가) | ≥3팀 | **MEDIUM** — Conductor 결정, decision_owner 명시 |
| 5 | `remove` (Quasar 잔재) + `modify` (manifest 정합) | 1팀 (team1) | LOW |

---

## 9. Phase 5 진입 체크리스트

본 보고서 권장 액션 1~3 완료 시 다음 항목으로 검증 후 Phase 5(통합 QA) 진입:

- [ ] Overlay에서 21/21 OutputEvent → Rive state machine 매핑 PASS (team4)
- [ ] `v99-full-hand-flow.http` 시나리오 GREEN (4팀 합의)
- [ ] team2 backend 커버리지 ≥ 90% (78% → 90%, 95%는 다음 단계)
- [ ] (선택) NFR 정확성 KPI Foundation에 명시
- [ ] CI에서 위 시나리오 자동 실행 (workflow 추가 또는 기존 통합)

---

## 10. 분석 출처 & 신뢰도

| 항목 | 출처 |
|------|------|
| 기획 분석 | Explore agent 1 — `docs/1. Product/` 8개 파일 정독 |
| 정본 분석 | Explore agent 2 — `docs/2. Development/**/Overview.md` 8개 + 팀 CLAUDE.md 4개 + 2.5 Shared |
| 코드 분석 | Explore agent 3 — `team{1-4}/`, `schemas/`, `integration-tests/`, `infra/`, `tools/` 구조 sampling |
| 종합 | Conductor 교차 검증 |

**제한**:
- 코드 분석은 디렉토리 구조 + 빌드 메타 + 테스트 파일 카운트 중심. 모든 비즈니스 로직 확인은 아님.
- 일부 수치(테스트 카운트, 라인 수)는 분석 시점 기준. 후속 변경 시 재측정 필요.
- 본 보고서는 **READ-ONLY** 분석 — 어떤 코드/문서도 수정하지 않음.

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-09 | v1.0 | 최초 작성 | - | 메인 레포 연결 직후 진단 요청 |
