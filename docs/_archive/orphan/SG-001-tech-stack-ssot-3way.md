---
id: SG-001
title: "기획 공백: Lobby/GE 기술 스택 SSOT 3중화 (Conductor vs BS_Overview vs team1)"
type: spec_gap
sub_type: spec_contradiction  # Type C
status: DONE
owner: conductor
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/2. Development/2.5 Shared/BS_Overview.md §1
  - CLAUDE.md §"팀 레지스트리 & 개발자 동선"
  - team1-frontend/CLAUDE.md
  - docs/1. Product/Foundation.md Ch.5
protocol: Spec_Gap_Triage
discovered_via: 2026-04-20 direct-critic Phase 3 재해석
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=DONE, spec_contradiction 해소 완료"
---
# SG-001 — Lobby/GE 기술 스택 SSOT 3중화 (Type C 해소)

## 공백 서술

EBS Lobby (+Graphic Editor) 의 기술 스택에 대해 **세 문서가 서로 다른 답**을 내놓고 있음:

| 문서 | Lobby 기술 | 근거 |
|------|-----------|------|
| Conductor CLAUDE.md §"팀 레지스트리" (2026-04-20 이전) | Quasar (Vue 3) + TypeScript | v6.0.0 기준 기재 |
| BS_Overview.md §1 | Quasar Framework (Vue 3) + TypeScript | CCR-016 SSOT 선언 (2026-04-10) |
| team1-frontend/CLAUDE.md | Flutter/Dart + Riverpod + Freezed + Dio + go_router + rive | 커밋 70d6d7a "Quasar→Flutter 전면 전환" (2026-04-17) |

프로토타입 실제 코드 상태:
- `team1-frontend/pubspec.yaml` → `name: ebs_lobby`, description "Flutter Desktop"
- `team1-frontend/lib/` → Flutter 활성 (142 .dart, 마지막 커밋 d70110a 2026-04-17)
- `team1-frontend/src/` → Quasar 잔재 (80 .vue/.ts, 마지막 커밋 8a942a6 2026-04-14, dormant)
- `package.json`, `quasar.config.js`, `node_modules/` → 미정리

## 발견 경위

- 2026-04-20 direct-critic Phase 3: "앱 실행 실패" 증상을 빌드 문제로 진단했으나, 사용자 의도 재정의(기획서 완결 프로젝트) 하에 Type C 모순으로 재분류
- 증상: 신규 세션이 Conductor CLAUDE.md 또는 BS_Overview SSOT 선언을 신뢰 시 `pnpm install` 시도 → postinstall hook 의 `quasar prepare` 실행 → 실제 Flutter 빌드 체인과 경합

## 영향받는 챕터

- Conductor CLAUDE.md §"팀 레지스트리 & 개발자 동선": team1 기술 컬럼
- BS_Overview §1 "앱 아키텍처 용어": Lobby, Graphic Editor rows
- Foundation.md Ch.5 "사용자가 만지는 것": Lobby/CC 기술 서술
- team1-frontend/CLAUDE.md: 이미 Flutter 기재 (동기화된 쪽)

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 정렬 |
|------|------|------|----------------|
| **1. Quasar 복귀** | 원칙 1(WSOP LIVE Staff Page=Web) 유지 | team1 커밋 70d6d7a 역행. Flutter 전환 작업 폐기 | 완전 정렬 |
| **2. Flutter 채택 + 원칙 1 예외 justify** | 팀 실제 결정 존중, 작업 연속성 | WSOP LIVE Staff Page 와 divergence. Why: 필드로 justify 필요 | 의도적 divergence |
| **3. 듀얼 런타임 (Quasar Web + Flutter Desktop 병행)** | 유연성 | 유지보수 2배, 팀 혼란 | 부분 정렬 |

## 결정 (2026-04-20)

**채택: 대안 2 — Flutter 채택 + 원칙 1 예외 justify**

**이유**:
- 2026-04-17 커밋 `70d6d7a` 에서 team1 이 이미 Flutter 로 전면 전환 완료 (결정 기록 존재)
- 프로토타입 활성 코드가 Flutter 쪽에 집중 (142 .dart vs 80 .vue, 커밋 활동도 Flutter 우세)
- Desktop Flutter 가 RFID HAL 직접 접근, rive 프리뷰 통합 등 EBS 고유 요구(원칙 1 §"적용 예외") 에 부합
- 기획자 (사용자) 2026-04-20 권고: "Flutter 로 정렬"

**Why (원칙 1 divergence justify)**:
- WSOP LIVE Staff Page 는 Web (Flutter 가 아님). EBS Lobby 는 의도적 divergence.
- EBS 고유 요구: RFID HAL 시리얼 접근, 테이블별 Command Center (Flutter) 와 동일 스택 공유, rive 프리뷰 성능
- 추상 레벨 정렬: "Staff Page 라는 관제 허브 역할" 자체는 유지. 런타임만 Flutter Desktop.

## 영향 챕터 업데이트 (이 SG 와 함께 커밋)

- [x] BS_Overview §1 Lobby/GE 행 Flutter 로 갱신 + CCR-016 resolution 행 추가
- [x] BS_Overview frontmatter reimplementability: FAIL → PASS
- [x] Roadmap.md §2.5 Shared / §2.1 Frontend FAIL → PASS 재판정
- [x] 2026-04-20 커밋 이전 Conductor CLAUDE.md §"팀 레지스트리" 는 직전 커밋 9726bfd 에서 프로젝트 의도 주입 과정에 통합 업데이트됨
- [ ] Foundation.md Ch.5 서술 재검토 — Ch.5 구체 본문에 기술 스택 명시가 없으면 NO-OP (확인 후 진행)

## 후속 작업 (Implementation Backlog 이전)

- [ ] `team1-frontend/src/`, `package.json`, `quasar.config.js`, `node_modules/`, `pnpm-lock.yaml`, `build/`, `.quasar/` 정리 (team1 세션에서만 가능)
- [ ] `_archive-quasar/` 는 보존 유지 (archive 표시)
- [ ] team1 `pnpm postinstall` hook 제거

## 재구현 가능성 재판정

- BS_Overview §1: **FAIL → PASS** (단일 SSOT 확립)
- Foundation.md Ch.5: UNKNOWN 유지 (본문 챕터별 개별 판정 별도 필요)
