---
title: Spec Gap Triage — 프로토타입 실패 → 기획 환원 프로토콜
owner: conductor
tier: internal
last-updated: 2026-04-20
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "프로토콜 자체는 독립 해석·적용 가능"
related:
  - CLAUDE.md §"프로토타입 실패 대응 프로토콜"
  - Roadmap.md
  - Conductor_Backlog/_template_spec_gap.md
  - memory: feedback_prototype_failure_as_spec_signal.md
---

# Spec Gap Triage — 프로토타입 실패 → 기획 환원 프로토콜

> **전제 (~~2026-04-20~~ → 2026-04-27 SG-023 재정의)**: EBS = **production 출시 프로젝트**. 프로토타입/구현 완벽 동작 ↔ 기획서 완벽.
> 실행 실패는 (a) **기획 공백/모순의 신호** (계속 유효) 또는 (b) **구현/인프라 실수의 신호** (production 인텐트 추가). "빌드 에러 수정" 으로 단순 환원 금지하되, Type A (구현 실수) 의 경우 즉시 수정도 가능.

### B-Q9 — Type 분류 의 production 의미 (SG-024 cascade, 2026-04-27)

본 SG-024 거버넌스 확장 cascade 에서 Conductor 자율 처리. 각 Type 의 production 의미:

| Type | spec_validation 의미 (이전) | production 의미 (현재, SG-023~024) |
|:----:|----------------------------|------------------------------------|
| **A** | 기획엔 답 있음, 구현 실수 → 구현 PR | **즉시 수정 우선** (기획 환원 불필요) |
| **B** | 기획 공백 → 기획 보강 PR 먼저 | 기획 보강 후 진행 (계속 유효) |
| **C** | 기획 모순 → 기획 정렬 PR 먼저 | 기획 정렬 우선 (계속 유효) |
| **D** | 기획-구현 drift → 사용자 판정 (코드 vs 기획) | production 에서는 "**코드가 진실 (운영 자산 보호)**" 판정 가능. 단 의미적 충돌 시 사용자 escalation |

> 참조: memory `project_intent_production_2026_04_27`, SG-023, SG-024, Phase_1_Decision_Queue Group E/F.

## 1. 프로토콜 개요 (Flow)

```
프로토타입 실패 감지 (빌드/테스트/런타임)
  └─ Step 1: 해당 증상이 연결되는 docs/ 챕터 탐색
  └─ Step 2: Type 분류 (A/B/C)
  └─ Step 3: Type 별 대응 순서 결정
  └─ Step 4: 결과 추적 (Roadmap.md reimplementability + Backlog)
```

## 2. Type 분류 기준

### Type A — 빌드 실수

**정의**: 기획에 명확한 답이 있고, 팀 간 해석도 일치. 구현만 틀림.

**판정 조건 (모두 충족)**:
- [ ] 관련 docs 챕터가 단일 파일에 명시됨
- [ ] 4팀 CLAUDE.md / API 문서 간 해석 일치
- [ ] 기획 문서에 "수락 기준" 이 구체적으로 존재
- [ ] 증상이 즉시 재현되고 스택 트레이스가 코드 줄을 가리킴

**대응 순서**:
1. 구현 PR 작성
2. 테스트 통과 확인
3. 관련 `Prototype_Scenario` 재실행 → PASS 전환

### Type B — 기획 공백

**정의**: 기획에 결정이 없거나 불완전. 팀마다 다른 가정으로 구현.

**판정 조건 (하나 이상 해당)**:
- [ ] 관련 챕터가 존재하지 않음 (e.g. `ENGINE_URL` 환경변수 표준 문서 부재)
- [ ] 챕터가 "TODO / TBD" 표시를 남김
- [ ] 팀 간 CLAUDE.md 가 다른 기본값/패턴 명시
- [ ] API 문서에 해당 엔드포인트/이벤트 스펙 없음

**대응 순서**:
1. **먼저** `Conductor_Backlog/SG-XXX-<slug>.md` 생성 (`_template_spec_gap.md` 사용)
2. decision_owner (챕터 소유자) 에게 notify
3. 결정 확정 후 관련 챕터 additive 보강 PR
4. `Roadmap.md` 의 해당 챕터 `reimplementability` 업데이트
5. 그 다음 구현 PR (Implementation Backlog)

### Type C — 기획 모순

**정의**: 기획 문서 간에 서로 다른 답이 적혀 있어 구현 자체가 결정 불가.

**판정 조건 (하나 이상 해당)**:
- [ ] 두 문서가 같은 대상에 다른 값 명시 (e.g. Conductor "Quasar" vs 팀 "Flutter")
- [ ] 같은 규칙의 두 해석이 양립 불가 (e.g. "순수 Dart 금지" vs harness `dart:io` 필연)
- [ ] 구현이 문서보다 앞서 있으나 문서 미동기화 (e.g. OutputEvent 21종 vs 18종)

**대응 순서**:
1. **먼저** `Conductor_Backlog/SG-XXX-<slug>.md` 생성, `type: spec_contradiction` 명시
2. 충돌하는 모든 문서 목록화
3. Conductor 또는 decision_owner 가 단일 SSOT 확정
4. **모든** 충돌 문서 일괄 정렬 PR (분산 수정 금지)
5. `Roadmap.md` 해당 챕터 재판정
6. 그 다음 구현 PR

## 3. Hook 연동

`.claude/hooks/post_build_fail.py` 가 Bash 실행 후 exit_code != 0 인 build/test 명령을 감지하여 이 프로토콜을 세션에 리마인드합니다.

감지 대상 패턴:
- `flutter pub|run|test|build|analyze`
- `dart run|test|pub`
- `pytest`, `ruff check`, `uvicorn`, `python -m alembic|pytest|uvicorn`
- `pnpm|npm install|run|test|build`
- `quasar dev|build`
- `docker compose up|build`, `build_runner`

감지 시 stdout 에 3-Type 분류 요청 출력 (차단 아님, 리마인드만).

## 4. Backlog 이동 흐름

```
발견 (빌드 실패)
  └─ Type A → Conductor_Backlog/Implementation/IMPL-XXX.md (spec_ready: true)
  └─ Type B → Conductor_Backlog/Spec_Gaps/SG-XXX.md
     └─ 해결 후 → Conductor_Backlog/Implementation/IMPL-XXX.md
  └─ Type C → Conductor_Backlog/Spec_Gaps/SG-XXX.md (type: spec_contradiction)
     └─ SSOT 정렬 PR → Roadmap 재판정 → Implementation/
```

팀 소유 Backlog 에서 동일 패턴 발견 시 Conductor 에게 notify (cross-team decision 필요).

## 5. 위반 전례 (학습 데이터)

### 2026-04-20 direct-critic P0 권고의 오판

**증상**: "앱 실행 거의 모두 실패"

**초기 critic 리포트 진단** (잘못됨):
- P0-2: "team1-frontend/src/, package.json, quasar.config.js 등 Quasar 잔재 삭제"
- Type A 로 암묵적 가정

**사용자 재정의 후 재분석**:
- 실제 원인: Conductor CLAUDE.md "Quasar" vs 팀 "Flutter" vs BS_Overview §1 "Quasar" 의 **3중 SSOT 모순**
- 실제 Type: **C (기획 모순)**
- 올바른 순서: (1) 기술 스택 SSOT 단일화 PR → (2) 파일 정리 PR

**교훈**: 빠른 파일 정리는 허점을 코드에 각인시킨다. 먼저 기획 정렬 후 정리.

## 6. 메트릭 (집계 대상)

- Roadmap.md 의 reimplementability 분포 (PASS / UNKNOWN / FAIL)
- Conductor_Backlog/Spec_Gaps/ 의 평균 해결 시간
- Spec_Gap → Implementation 전환율 (Backlog 분석)
- post_build_fail hook 발동 빈도 + Type 분류 결과 분포

## 7. Type D — 기획-코드 불일치 (Spec Drift)

**정의**: 기획 문서와 구현 코드 사이에 선언적 불일치가 존재. Type A/B/C 와 달리 빌드 실패 없이 은밀히 누적되어 외부 인계 시 재구현 불가 위험을 만든다.

### 7.1 Sub-type 분류

| ID | 정의 | 예시 |
|----|------|------|
| **D1** | 기획 有 / 코드 有 / 값 불일치 | 문서 "POST /users" vs 코드 "POST /api/v1/users" |
| **D2** | 기획 有 / 코드 無 (미구현) | 문서에 엔드포인트 있으나 router 미구현. TODO skeleton 존재 시 D4 로 승격 |
| **D3** | 기획 無 / 코드 有 (undocumented) | router 에 DELETE 구현, 문서에는 언급 없음 |
| **D4** | 기획 ↔ 코드 PASS | 스캐너가 양쪽 일치 확인 |

### 7.2 해소 규칙

| Sub-type | 진실 판정 | 조치 |
|---|---|---|
| **D1 (코드가 진실)** | 최근 커밋으로 검증된 스펙. 테스트 통과 이력. **(단, §7.2.1 선결 조건 필수)** | **기획 정정 PR** (Conductor 즉시, additive) |
| **D1 (기획이 진실)** | 문서가 공식 설계이고 코드가 drift. | **코드 수정 PR** (팀 세션 위임, SG 승격) |
| **D1 (둘 다 틀림)** | 양쪽 모두 stale 또는 모순. | **SG 신규** (`type: spec_drift`) — 재판정 |
| **D2** | 기획만 존재. | 기존 TODO / Backlog 조회 후 등재. 없으면 SG 승격. |
| **D3 (코드 유지)** | 구현은 타당한 기능. **(단, §7.2.1 선결 조건 필수)** | **기획 보강 PR** (Conductor 즉시, additive) |
| **D3 (코드 삭제)** | 실수로 추가된 dead endpoint. | **코드 삭제 PR** (팀 세션) + Backlog 등재 |

### 7.2.1 "코드가 진실" 판정 요건 (2026-04-20 보강)

**"D1 (코드가 진실)" 또는 "D3 (코드 유지 → 기획 보강)" 결정은 아래 조건 모두 충족 시에만 성립:**

- [ ] 해당 코드가 최근 30일 내 CI/테스트 녹색 이력 보유
- [ ] 프로토타입 앱이 해당 기능 **안정 동작** 상태 (빌드 에러 없이 시연 가능)
- [ ] 구현자(팀) 가 "이 값이 의도적" 이라 명시적 확인

위 중 하나라도 미충족 → **기본적으로 "기획이 진실"** 또는 SG 승격.

**본 프로젝트는 2026-04-20 현재 불안정 상태이므로 `default = 기획 진실`.**

#### 결정 흐름 (기획 진실 default 시)

| 상황 | 처리 |
|------|------|
| 기획에 당연히 필요 (CRUD 완결성, 명시적 use case) | **기획 추가** (Conductor 즉시 additive PR) |
| 기획 결정 필요 (RBAC, 공개 범위, 설계 옵션) | **SG 승격** — decision_owner 판정 |
| 기획에 없고 필요성 모호 | **코드 삭제** (팀 세션) + Backlog 등재 |

> 위반 전례 참조: MEMORY `feedback_prototype_failure_as_spec_signal.md §"위반 전례"` 2026-04-20 SG-008 v1 "역방향 문서화" 계획 반성.

### 7.3 감지 도구

**`tools/spec_drift_check.py`** — 7 계약 자동 스캔 (정규식 기반 best-effort):
- `--api` REST 엔드포인트 (Backend_HTTP.md / Auth_and_Session.md ↔ team2 routers)
- `--events` OutputEvent (Overlay_Output_Events.md §6.0 ↔ output_event.dart)
- `--fsm` BS_Overview §3 FSM 상태 ↔ 각 팀 enum
- `--schema` Database/Schema.md ↔ init.sql + Alembic migrations
- `--rfid` RFID_HAL_Interface.md ↔ i_rfid_reader.dart
- `--settings` Settings.md ↔ migration 0005
- `--websocket` (stub — WebSocket_Events.md §4 ↔ websocket/*.py, 후속 구현)

실행:
```bash
python tools/spec_drift_check.py --all
python tools/spec_drift_check.py --all --format=json  # Registry 자동 갱신
```

`.claude/hooks/pre_push_drift_check.py` — `git push` 전 drift 증가를 경고 (non-blocking).

### 7.4 Registry

**Source of Truth**: `docs/4. Operations/Spec_Gap_Registry.md`
- 현재 drift 목록 + 해소 상태
- SG 승격 index
- 정기 scan 결과 기록

### 7.5 Cross-reference

- **Type A** 와의 차이: Type A 는 빌드 실패가 원인, Type D 는 빌드 통과하나 선언이 불일치.
- **Type B** 와의 차이: Type B 는 기획이 공백, Type D 는 기획 있으나 코드와 값이 다름.
- **Type C** 와의 차이: Type C 는 기획끼리 모순, Type D 는 기획-코드 간 모순.
