---
title: Roadmap
owner: conductor
tier: internal
last-updated: 2026-04-20
intent: spec-completeness (not product-launch)
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "자립 가능: 기획서 완결성 로드맵 구조 자체는 독립 해석 가능"
---

# EBS 기획서 완결성 로드맵

> **프로젝트 의도** (2026-04-20 재정의): EBS 는 **개발팀 인계용 기획서 완결** 프로젝트. 실제 제품 출시가 아님. 프로토타입(`team1~4/`)은 **기획서 검증 도구**.
> **쌍방향 인과**: 프로토타입 완벽 동작 ↔ 기획서 완벽.
>
> **이 문서는** 각 기획 챕터가 "외부 개발팀이 받아 재구현 가능한 상태" 인가를 추적합니다. 제품 출시 로드맵이 아닙니다.
>
> SSOT 정렬 진척표 → `SSOT_Alignment_Progress.md` 로 분리 (2026-04-20).

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
| Foundation Ch.7 Overlay & RFID | team4 | **FAIL (B)** | CC 기동 시 engine 없으면 graceful 대기 계약 부재 | `ENGINE_URL` 환경변수 표준 누락 |
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
| APIs/RFID_HAL | UNKNOWN | Mock + 실제 HAL 인터페이스 호환 | — |
| RFID_Cards/** | UNKNOWN | 52 카드 코드맵 | — |
| Command_Center_UI/** | UNKNOWN | 좌석 관리 + 액션 버튼 + 카드 입력 | — |
| Overlay/** | **FAIL (B)** | engine 미기동 시 graceful 계약 없음 | `ENGINE_URL` 환경변수 미명시 |
| Manual_Card_Input | PASS | RFID 실패 → 수동 입력 전환 | 2026-04-17 보강 완료 |

### 2.5 Shared (conductor)

| 챕터 / 문서 | 재구현 가능성 | 공백/모순 |
|-------------|:---:|-----------|
| BS_Overview (§1 Tech Stack) | PASS | SG-001 resolved 2026-04-20. Flutter 채택 + 원칙 1 divergence justify. CCR-016 SSOT 유지 |
| Authentication | UNKNOWN | — |
| Network_Config | UNKNOWN | — |
| Risk_Matrix | UNKNOWN | — |
| team-policy.json | PASS | v7 governance 명시 |
| EBS_Core.md (참조됨) | **FAIL (B)** | 파일 부재. CLAUDE.md L286 이 존재하지 않는 파일 참조 |

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

| 상태 | 개수 | 비율 |
|:---:|:---:|:---:|
| PASS | 8 | ~18% |
| UNKNOWN | 26 | ~59% |
| **FAIL** | 8 | ~18% |
| N/A | 2 | ~5% |

**최우선 FAIL 5건 (기획 공백/모순, 2026-04-20 SG-001 해소 후)**:
1. ~~Foundation Ch.5 — 기술 스택 SSOT 3중화 (C)~~ → **SG-001 resolved 2026-04-20**
2. Foundation Ch.7 — ENGINE_URL 표준 부재 (B)
3. ~~team1 Engineering — Quasar/Flutter 결정 미문서화 (C)~~ → **SG-001 resolved 2026-04-20** (후속: Engineering.md 재확인)
4. team3 API-04 — 구현 21종 vs 문서 18종 (C)
5. team3 순수 Dart 규칙 vs harness `dart:io` (C) — BS_Overview §1 에 부분 해소 (harness 예외 명시), team3 CLAUDE.md §Build 규칙은 별도 조치
6. team4 Overlay — engine 의존 graceful 계약 부재 (B)
7. ~~Shared BS_Overview §1 — Tech Stack SSOT 현실 괴리 (C)~~ → **SG-001 resolved 2026-04-20**
8. Shared EBS_Core.md — 참조되지만 파일 부재 (B)

## 거버넌스

- 챕터 상태 변경은 Conductor 판정 (decision_owner) + 해당 팀 공동 서명
- `tools/reimplementability_audit.py` 가 챕터 frontmatter `reimplementability` 필드 자동 집계
- 새 챕터 추가 시 frontmatter 에 `reimplementability: UNKNOWN` 기본값
- 관련 프로토콜: `Spec_Gap_Triage.md` (프로토타입 실패 시 Type A/B/C 환원)

## 이력

- **2026-04-20** — 전면 재설계. "SSOT Alignment Roadmap" → "기획서 완결성 로드맵" 전환. SSOT 정렬 진척표는 `SSOT_Alignment_Progress.md` 로 분리.
