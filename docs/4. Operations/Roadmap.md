---
title: Roadmap
owner: conductor
tier: internal
last-updated: 2026-04-27
intent: production-launch (SG-023 + B-Q6 ㉠ 채택)
previous_intent: "spec-completeness (2026-04-20 ~ 2026-04-26, SUPERSEDED 2026-04-27)"
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "자립 가능: 본 로드맵은 production 출시 + 기획서 완결성 이중 추적. SG-023/024 + B-Q6 ㉠ 채택 후 production 일정 + 기획 챕터 완결성 양쪽 모두 본 문서에서 추적."
---

# EBS Production Roadmap (SG-023 + B-Q6 ㉠, 2026-04-27)

> **프로젝트 의도** (~~2026-04-20 spec-completeness~~ → **2026-04-27 SG-023 production-launch**): EBS 는 **production 출시 프로젝트** (사용자 = 기획자 + production 출시 책임자).
> **timeline 기준** (B-Q6 ㉠ 채택 2026-04-27): MVP=홀덤1종, **2027-01 런칭** / **2027-06 Vegas**. 상세: memory `project_2027_launch_strategy.md` REACTIVATED.
> **품질 기준** (B-Q7 ㉠ 채택 2026-04-27): Production-strict — 95%+ coverage, 99.9% uptime, p99<200ms, OWASP audit, WCAG AA, 한+영.
> **쌍방향 인과 보존**: 프로토타입/구현 완벽 동작 ↔ 기획서 완벽. 본 로드맵은 (a) production 출시 일정 + (b) 기획 챕터 완결성 이중 추적.
>
> SSOT 정렬 진척표 → `SSOT_Alignment_Progress.md` 로 분리 (2026-04-20).

## Production Timeline (REACTIVATED 2026-04-27, B-Q6 ㉠)

| Phase | 기간 | 핵심 활동 | 상태 |
|-------|------|-----------|:----:|
| Phase 0 | ~ 2026-12 | MVP=홀덤1종 구현 + 검증 (현재 진행 중) | IN_PROGRESS |
| Phase 1 | 2027-01 | **런칭** (한국 시장 베타) | PLANNED |
| Phase 2 | 2027-02 ~ 2027-05 | 안정화 + 22종 게임 확장 + Backend 보강 | PLANNED |
| Phase 3 | 2027-06 | **Vegas** (글로벌 런칭) | PLANNED |
| Phase 4 | 2027-07 ~ | 스킨 에디터 + BO 본격 개발 | PLANNED |

**MVP 정의** (memory `project_2027_launch_strategy` 참조):
- 홀덤 1종, 8시간 연속 방송 가능
- Action Tracker = PokerGFX 완전 복제
- RIVE `.riv` 직접 로드 (스킨 에디터 1단계)
- RFID 수동 입력 폴백 = 1급 기능
- 출력: NDI + ATEM 스위처

## Production Quality Gates (B-Q7 ㉠ 채택)

| 측정 영역 | 기준 (Production-strict) |
|----------|--------------------------|
| Test coverage | **95%+** (현재 team2: 90% / 247 tests, 95% 도달 plan = B-Q10) |
| Uptime SLA | 99.9% (Phase 1 런칭 기준) |
| API 응답 시간 | p99 < 200ms (BLANK-1 100ms 전체 파이프라인 + endpoint 마진) |
| 에러율 | < 0.1% |
| 보안 | OWASP Top 10 준수 (B-Q11 audit plan) |
| 접근성 | WCAG 2.1 AA |
| i18n | 한글 + 영어 |

## 성공 기준 (Reimplementability)

| 상태 | 의미 |
|:---:|------|
| **PASS** | 외부 개발팀이 이 챕터 + 프로토타입 해당 컴포넌트만으로 재구현 가능 |
| **UNKNOWN** | 미판정 (재구현 가능성 검증 필요) |
| **FAIL** | 기획 공백(Type B) 또는 기획 모순(Type C) 존재. 인계 불가 |
| **N/A** | 보조 문서 (landing, README, template). 챕터 아님 |

검증 방법:
1. 챕터 독립성 (다른 챕터 참조 없이 자립 가능)
2. 프로토타입 해당 컴포넌트가 챕터 시나리오 완주
3. 챕터 간 용어/계약 일관성

---

## 1. Product — 개념·비전·참조

| 챕터 / 문서 | 소유 | 재구현 가능성 | 프로토타입 검증 시나리오 | 공백/모순 메모 |
|-------------|:---:|:---:|-------------------------|----------------|
| Foundation Ch.1 숨겨진 패의 마법 | conductor | PASS | (개념 문서, 프로토타입 무관) | — |
| Foundation Ch.2 시청자 화면 해부 | conductor | UNKNOWN | Overlay 가 8가지 요소 모두 렌더 | §4.2 Overlay 요소 수 확정 필요 |
| Foundation Ch.3 EBS 공간 경계 | conductor | PASS | (개념) | — |
| Foundation Ch.4 시스템 퍼즐 6조각 | conductor | UNKNOWN | 5 App + 1 HW 전부 기동 가능 | Mock RFID HAL 검증 완료 필요 |
| Foundation Ch.5 Lobby & CC 프론트엔드 | team1 + team4 | UNKNOWN | Lobby+CC 양쪽 Flutter 기동 가능 | **SG-001 resolved 2026-04-20**: Flutter 채택(원칙 1 divergence justify). 잔재 파일 정리는 team1 세션 후속 |
| Foundation Ch.6 Backend & Engine | team2 + team3 | UNKNOWN | BO REST + WS 3채널 + Engine harness 동시 기동 | — |
| Foundation Ch.7 Overlay & RFID | team4 | PASS | CC 기동 시 engine 없으면 graceful 대기 + Demo Mode fallback | **SG-002 RESOLVED 2026-04-20**: Foundation §6.3/§6.4 + §7.1 Overlay 배경 flag 로 ENGINE_URL + 3-stage fallback + 배경 투명/단색 이분법 확정 |
| Foundation Ch.8 현장의 하루 | conductor | UNKNOWN | 체크리스트 시나리오 프로토타입 완주 | — |
| Foundation Ch.9 비전/전략 | conductor | N/A | (비전 문서) | — |
| References/PokerGFX_Reference | conductor | PASS | — | — |
| Game_Rules/** | team3 | UNKNOWN | 22 게임 규칙 엔진 통과 | Confluence 발행 검증 필요 |

## 2. Development — 팀별 기획 + 프로토타입

### 2.1 Frontend (team1)

| 챕터 / 문서 | 재구현 가능성 | 프로토타입 검증 시나리오 | 공백/모순 |
|-------------|:---:|-------------------------|-----------|
| Login/** | UNKNOWN | 로그인 → JWT → Lobby 진입 | — |
| Lobby/** | UNKNOWN | Series→Event→Table 드릴다운 | — |
| Settings/** (6탭) | UNKNOWN | Outputs/GFX/Display/Rules/Stats/Preferences 각 저장-복원 | — |
| Graphic_Editor/** | UNKNOWN | `.gfskin` 업로드 → 프리뷰 → Activate | `.gfskin` 스키마 DATA-07 확정 필요 |
| Engineering.md | UNKNOWN | team1 세션이 SG-001 후속으로 Flutter 아키텍처 문서화 정합성 재확인 필요 |

### 2.2 Backend (team2)

| 챕터 / 문서 | 재구현 가능성 | 프로토타입 검증 시나리오 | 공백/모순 |
|-------------|:---:|-------------------------|-----------|
| APIs/Backend_HTTP | UNKNOWN | 66+ 엔드포인트 contract test | — |
| APIs/WebSocket_Events | UNKNOWN | seq 단조증가 + replay 시나리오 | — |
| APIs/Auth_and_Session | UNKNOWN | JWT access/refresh + OAuth | — |
| Database/Schema | UNKNOWN | init.sql ↔ SQLModel 일관 | Alembic baseline 검증 |
| Back_Office/Overview §1.2 matrix | PASS | — | — |
| Engineering/** | UNKNOWN | — | — |

### 2.3 Game Engine (team3)

| 챕터 / 문서 | 재구현 가능성 | 프로토타입 검증 시나리오 | 공백/모순 |
|-------------|:---:|-------------------------|-----------|
| APIs/Overlay_Output_Events | **FAIL (C)** | OutputEvent 구현 21종 vs 문서 18종 불일치 |
| Behavioral_Specs/Holdem/** | UNKNOWN | Holdem 전 스트릿 시나리오 | — |
| Behavioral_Specs/ (기타) | UNKNOWN | — | Draw 7종·Stud 3종 커버리지 검증 |
| (규칙) 순수 Dart 강제 | **FAIL (C)** | `bin/harness.dart` 가 `dart:io` 사용 필연. CLAUDE.md 금지 문구 수정 필요 |

### 2.4 Command Center (team4)

| 챕터 / 문서 | 재구현 가능성 | 프로토타입 검증 시나리오 | 공백/모순 |
|-------------|:---:|-------------------------|-----------|
| APIs/RFID_HAL | UNKNOWN | Mock + 실제 HAL 인터페이스 호환 | SG-011 **OUT_OF_SCOPE** (프로토타입 범위 밖). §2.1 single vs 6-stream divergence 는 개발팀 인계 후 제조사 SDK 기반 재결정 |
| RFID_Cards/** | UNKNOWN | 52 카드 코드맵 | — |
| Command_Center_UI/** | UNKNOWN | 좌석 관리 + 액션 버튼 + 카드 입력 | — |
| Overlay/** | PASS | engine 미기동 시 Demo Mode fallback (3-stage) | **SG-002 RESOLVED 2026-04-20** — Foundation §6.3 §6.4 §7.1 확정 |
| Manual_Card_Input | PASS | RFID 실패 → 수동 입력 전환 | 2026-04-17 보강 완료 |

### 2.5 Shared (conductor)

| 챕터 / 문서 | 재구현 가능성 | 공백/모순 |
|-------------|:---:|-----------|
| BS_Overview (§1 Tech Stack) | PASS | SG-001 resolved 2026-04-20. Flutter 채택 + 원칙 1 divergence justify. CCR-016 SSOT 유지 |
| Authentication | UNKNOWN | — |
| Network_Config | UNKNOWN | — |
| Risk_Matrix | UNKNOWN | — |
| team-policy.json | PASS | v7 governance 명시 |
| EBS_Core.md (참조됨) | PASS | **SG-005 RESOLVED 2026-04-20**: Foundation §Ch.6 + §Ch.7 병합 완료. CLAUDE.md 참조 `docs/1. Product/Foundation.md §Ch.6 + §Ch.7` 로 갱신 |

## 4. Operations

| 문서 | 재구현 가능성 | 비고 |
|------|:---:|------|
| Roadmap (이 문서) | PASS | — |
| SSOT_Alignment_Progress | PASS | 2026-04-20 분리 |
| Multi_Session_Workflow | UNKNOWN | L2 레지스트리 상태 검증 필요 |
| Network_Deployment | UNKNOWN | — |
| Conductor_Backlog | N/A | 추적 문서 |
| Spec_Gap_Triage (신규) | PASS | 프로토타입 실패 → 기획 환원 프로토콜 |

---

## 집계 (2026-04-20 기준)

### 1. 챕터 매트릭스 (수동 집계, 본 문서 §1-4 행 단위)

| 상태 | 개수 | 비율 |
|:---:|:---:|:---:|
| PASS | 13 | ~30% |
| UNKNOWN | 27 | ~61% |
| **FAIL** | 2 | ~5% |
| N/A | 2 | ~5% |
| 합계 | 44 | 100% |

> **2026-04-22 재집계**: Foundation 재설계로 SG-002 (Ch.7 Overlay + team4 Overlay) · SG-005 (EBS_Core.md 참조) 3건 PASS 전환. 잔존 FAIL 2 = team3 OutputEvent 문서 정합(C) + 순수 Dart 규칙 예외(C, 부분 해소됨).

> **주의**: 같은 상태 라벨이 표 헤더와 본문에 중복 등장하여 grep 기반 count 와 값이 다를 수 있음. 본 수치는 챕터·문서 행 단위 수동 집계.

### 2. 파일 단위 frontmatter (자동 집계, `tools/reimplementability_audit.py`)

2026-04-20 최신 실행 결과: PASS 4 / UNKNOWN 1 / MISSING 416 / FAIL 0 (도합 421 .md 파일).

> **해석**: 자동 집계는 **frontmatter 에 `reimplementability:` 필드가 있는 파일만** 센다. 대부분(99%)이 MISSING 이며 시범 적용만 이루어진 상태. 수동 집계(챕터 매트릭스)는 Conductor 가 계약 단위로 평가한 것이고, 자동 집계는 문서 파일 단위로 평가한 것이라 본질적으로 다른 측정치.

### 3. 수동/자동 괴리 해소 계획

- **단기**: 주요 계약 문서(API-01/04/05/06, RFID_HAL, Foundation Ch.2~8)에 frontmatter 추가 시범 (Conductor 범위 우선)
- **중기**: 팀 세션에서 팀 소유 문서 frontmatter 부여 (IMPL-001 retag 와 병행 가능)
- **수렴 기준**: 수동 집계 챕터 수 ≈ 자동 집계 PASS+UNKNOWN+FAIL 수 차이가 10% 이내

### 4. 최우선 FAIL 잔존 (2026-04-22 Foundation 재설계 후)

| # | 항목 | 유형 | 상태 |
|:--:|------|:----:|:----:|
| 1 | team3 API-04 — 구현 21종 vs 문서 18종 | C | Overlay_Output_Events.md §6.0 정정 완료 (2026-04-15). 문서 일관성만 유지 |
| 2 | team3 순수 Dart 규칙 vs harness `dart:io` | C | BS_Overview §1 + team3 CLAUDE.md 예외 명시 (2026-04-20) — **부분 해소** |
| 3 | Settings 6탭 / `.gfskin` / RFID codemap — Type B 공백 | B | SG-003 / SG-004 / SG-006 로 추적 (팀 세션 병렬 처리 중) |

~~Foundation Ch.5, team1 Engineering, BS_Overview §1 Tech Stack (SG-001 resolved 2026-04-20)~~
~~Foundation Ch.7 / team4 Overlay — ENGINE_URL (SG-002 resolved 2026-04-20)~~
~~Shared EBS_Core.md 파일 부재 (SG-005 resolved 2026-04-20 — Foundation §Ch.6 §Ch.7 병합)~~

### 5. Spec Gap 추적 index

| ID | 제목 | 상태 | 담당 |
|:--:|------|:----:|:---:|
| SG-001 | Lobby/GE 기술 스택 SSOT 3중화 | **DONE** 2026-04-20 | conductor |
| SG-002 | Engine 의존 계약 (ENGINE_URL + graceful + Overlay 배경 flag) | **DONE** 2026-04-20 | conductor (Foundation §6.3 §6.4 §7.1) |
| SG-003 | Settings 6탭 스키마 | PENDING | conductor + team1 |
| SG-004 | .gfskin ZIP DATA-07 포맷 | PENDING | conductor + team1 |
| SG-005 | Foundation Ch.6 시스템 연결 도식 (EBS_Core 병합) | **DONE** 2026-04-20 | conductor (Foundation §Ch.6 §Ch.7 병합) |
| SG-006 | RFID 52 카드 codemap | PENDING | conductor + team4 |

## 거버넌스

- 챕터 상태 변경은 Conductor 판정 (decision_owner) + 해당 팀 공동 서명
- `tools/reimplementability_audit.py` 가 챕터 frontmatter `reimplementability` 필드 자동 집계
- 새 챕터 추가 시 frontmatter 에 `reimplementability: UNKNOWN` 기본값
- 관련 프로토콜: `Spec_Gap_Triage.md` (프로토타입 실패 시 Type A/B/C 환원)

## 이력

- **2026-04-22** — Foundation 재설계 후 집계 동기화. SG-002 · SG-005 DONE 전환 (개별 파일 RESOLVED 상태와 정합). Ch.7 / Overlay / EBS_Core FAIL → PASS. 최우선 FAIL 5 → 3. (B-203)
- **2026-04-20** — 전면 재설계. "SSOT Alignment Roadmap" → "기획서 완결성 로드맵" 전환. SSOT 정렬 진척표는 `SSOT_Alignment_Progress.md` 로 분리.
