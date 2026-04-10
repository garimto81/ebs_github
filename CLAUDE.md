# EBS Conductor CLAUDE.md — 5팀 구조 (Team 0)

## Role

Team 0 — Conductor. 최상위 오케스트레이션, 계약 관리, 통합 테스트 소유.

**이 파일은 Conductor 세션용입니다.** 팀별 개발은 각 `team*/CLAUDE.md`를 따릅니다.

---

## 프로젝트 설계 원칙 (CRITICAL)

### 원칙 1 — WSOP LIVE Confluence 정렬 (2026-04-10 추가)

**"WSOP LIVE Confluence 문서를 기반으로, 동일하게 설계할 수 있는 것은 최대한 동일하게 설계한다."**

- **Why**: EBS는 WSOP LIVE 생태계의 일부로 기획되며, 실제 운영 조직(기획/개발/QA/방송)이 WSOP LIVE 문서 체계에 이미 익숙하다. 패턴을 재발명하면 학습 비용 + drift 위험이 중복 발생한다.
- **기준 레포**: `C:/claude/wsoplive/` (1,361 Confluence 페이지 미러)
- **적용 대상**:
  - 문서 구조 (Edit History, 개요, 상세, 검증/예외)
  - 폴더 네이밍 (Backend/Frontend/API/개발 공통 등 도메인 기반)
  - Confluence 메타데이터 (page_id, version, last_modified 프론트매터)
  - 용어/레이블 (WSOP LIVE가 이미 정의한 것은 재사용)
  - 동기화 메커니즘 (`confluence_sync.py` 단방향 pull 패턴)
- **적용 예외 (의도적 divergence 허용)**:
  - EBS 고유 요구(다팀 병렬, RFID 하드웨어, 실시간 오버레이)
  - WSOP LIVE에 존재하지 않는 메커니즘(Layered Scope Guard, CCR inbox, hook 강제)
  - Divergence 시 **이유를 문서화**(`Why:` 필드)하여 정렬 누락과 의도적 분기를 구분한다.
- **How to apply**:
  1. 신규 문서 작성 전 `wsoplive/docs/confluence-mirror/` 에서 유사 주제 페이지 확인
  2. 구조/네이밍/용어를 우선 일치
  3. EBS 고유 요구 때문에 달라야 할 부분만 justify + document
  4. 설계 완료 후 critic 평가로 "WSOP LIVE 패턴 O / EBS 독자 X / 부분일치 △" 3분류 리뷰

**금지**: "WSOP LIVE에 없으니 새로 만든다"는 즉흥 판단. **먼저 유사 패턴 검색**, 없을 때만 EBS 고유 설계로 진행.

---

## 소유 경로

| 경로 | 내용 | 역할 |
|------|------|------|
| `contracts/` | API/Data/Spec 계약 + `team-policy.json` SSOT | 단독 소유 — 팀 수정 금지 |
| `integration-tests/` | HTTP 기반 통합 테스트 | 팀 간 API 계약 검증 |
| `docs/01-strategy/` | Foundation PRD | 전략 문서 |
| `docs/00-reference/` | WSOP 분석, Production Plan | 참고 자료 |
| `docs/05-plans/` | 로드맵, 이행 계획, CCR (승격본) | 계획 문서 |
| `docs/05-plans/ccr-inbox/` | 팀 CCR 초안 inbox | 팀이 자기 팀 prefix draft 작성 |
| `docs/06-reports/` | 완료 보고서 | 현황 추적 |
| `docs/07-archive/` | PokerGFX 분석, legacy | 아카이빙 |
| `docs/mockups/`, `docs/images/` | 공유 그래픽 자산 | 모든 팀 참조 |
| `docs/backlog.md` | **stub only** (분할 전환 완료) | 기존 파일은 pointer |
| `docs/backlog/team{N}.md` | 팀별 PENDING 백로그 | 각 팀 쓰기, 타 팀 차단 |
| `docs/backlog/conductor.md` | 크로스팀/인프라 백로그 + DONE 역사 | Conductor 쓰기 |
| `docs/backlog/_aggregate.md` | 읽기 전용 집계 뷰 | `tools/backlog_aggregate.py` 생성 |
| `tools/` | Python 유틸 (`backlog_aggregate.py`, `ccr_promote.py` 등) | 운영 도구 |

---

## 충돌 방지 아키텍처 (Layered Scope Guard)

```
Layer 1  pre_tool_guard.check_team_scope    ← HARD BLOCK (hook, EBS 전용 자동 활성)
Layer 2  contracts/team-policy.json         ← SSOT (모든 소비자의 유일 입력)
Layer 3  /auto Phase 0a cwd 자동 감지       ← LLM 컨텍스트 로더
Layer 4  docs/backlog/team{N}.md 분할       ← git merge 경쟁 구조적 제거
Layer 5  docs/05-plans/ccr-inbox/           ← 팀→Conductor 제안 경로
Layer 6  .claude/logs/scope-guard-*.jsonl   ← 감사 로그 (append-only)
```

**핵심 규칙**:
- 팀은 `contracts/`, `docs/05-plans/`, `docs/backlog/` 의 **자기 것 외** 파일을 쓸 수 없다 (hook이 차단).
- `contracts/` 변경은 반드시 `ccr-inbox/CCR-DRAFT-teamN-*.md` 제출 → Conductor `tools/ccr_promote.py` → CCR-{NNN} 승격 순서.
- `/auto-team1`, `/auto-team2` 등 팀별 스킬은 **존재하지 않는다**. 단일 `/auto`가 cwd 기반으로 자동 분기한다.

### 팀 식별 우선순위 (hook + skill 동일)

1. `EBS_TEAM` 환경변수 (worktree env로 주입 시)
2. git 브랜치 prefix `teamN/*`
3. cwd 가 `team{N}-*` 하위
4. fallback → `conductor`

### Conductor가 CCR을 처리하는 흐름 (v3 — 배치 모드)

```
사용자가 Claude Code 세션에서 "ccr promote" 자연어 입력
  ↓
Claude Conductor LLM이 CLAUDE.md §계약 관리 절차 따라 수행:

  1. Phase A — Collection (일괄 읽기)
     python tools/ccr_promote.py --validate-only   (전체 inbox JSON)
     → 유효 draft들을 가능한 한 한 번에 Read. 토큰 예산 초과 시 chunking:
       · 1차 기준 (강제): target_files 교집합 있는 draft는 같은 chunk
       · 2차 기준: 같은 도메인 파일끼리 묶음 (API-*, BS-01-* 등)
       · 3차 기준: 독립 draft는 번호순으로 잔여 예산에 채움

  2. Phase B — Planning (배치 계획)
     → target_files 교집합 기준으로 그룹핑
     → 각 그룹의 target contract는 1번만 Read (토큰 절약 + 일관성)
     → Merge 플랜: Intent 추출 + 충돌 검사
                    + 병합 순서(add → modify → rename → remove)
                    + Idempotency 판정 (의도 단위)
     → 불확실성 플래그: 충돌/모호/Spec Gap 있는 그룹 마킹 → Phase D

  3. Phase C — Execution (실제 contracts/ 프로젝트 문서 수정)
     → 그룹별로 draft 의도를 반영한 1회 통합 Edit 을 target 파일에 적용
       · Diff 초안 복붙 금지, 기존 섹션 컨벤션에 맞춰 재구성
       · 같은 target에 복수 draft → 순차 재Read 금지, 1회 통합
       · 대상 파일 부재 시 sibling 스타일로 Write 신규 생성
     → 편집이 끝난 draft만 마감:
       python tools/ccr_promote.py --complete <draft> --number N \
         --applied-files "<실제 수정된 파일 csv>" [--skipped]
       → promoting/CCR-N-*.md 로그 생성
       → backlog NOTIFY append (중복 방지)
       → draft → archived/ 이동

  4. Phase D — Clarification (사용자 문의)
     → 플래그된 그룹만 AskUserQuestion 으로 구조화된 선택지 제시
     → 응답 후 해당 그룹만 재실행. 임의 판정 금지.

  5. Phase E — Finalize
     python tools/backlog_aggregate.py
     → 사용자에게 최종 리포트 + commit 승인 요청
     → git add contracts/ docs/ && git commit -m "[CCR-NNN..MMM] ..."
```

**핵심**: "작업 실행"은 **실제 `contracts/` 프로젝트 문서를 draft 의도에 맞게 수정**하는 것이 본체이며, `--complete` CLI 호출은 편집 완료 후의 마감 절차일 뿐이다. 실제 편집은 LLM이 Read/Edit/Write 도구로 직접 수행하고, Python 스크립트는 검증(JSON)과 마감(로그·NOTIFY·archive)만 담당한다.

### (선택) Git worktree 물리 격리

4팀 동시 개발 강도가 올라가면 worktree 도입 권장:

```bash
git worktree add ../ebs-wt/team1 -b team1/main
git worktree add ../ebs-wt/team2 -b team2/main
git worktree add ../ebs-wt/team3 -b team3/main
git worktree add ../ebs-wt/team4 -b team4/main
# 각 worktree에서 `export EBS_TEAM=teamN` 권장
```

브랜치 prefix `teamN/` 는 hook의 detect_team 2순위 식별자이므로,
worktree를 쓰지 않더라도 feature 브랜치 명명 규칙을 `teamN/feature-name` 으로 유지하면 자동 식별된다.

---

## 팀 레지스트리

| 팀 | 폴더 | 기술 | 소유 API |
|----|------|------|----------|
| **Team 1** | `team1-frontend/` | Quasar (Vue 3)+TypeScript | consumes API-01,05,06 |
| **Team 2** | `team2-backend/` | FastAPI+SQLite/PostgreSQL | implements API-01,02,05,06 |
| **Team 3** | `team3-engine/` | Pure Dart | publishes API-04 OutputEvent |
| **Team 4** | `team4-cc/` | Flutter/Dart+Rive | implements API-03,05; consumes API-04 |

---

## 계약 관리 (CCR 프로세스)

### CCR 파일 저장 위치 (CRITICAL — 혼동 금지)

| 상태 | 저장 위치 | 파일명 패턴 | 편집 권한 |
|------|----------|-------------|----------|
| **Draft (제안 초안, 진행 중)** | `docs/05-plans/ccr-inbox/` | `CCR-DRAFT-{teamN\|conductor}-{YYYYMMDD}[-slug].md` | 제안팀만 (hook 강제) |
| **Promoted CCR (승격본, 처리 중)** | `docs/05-plans/ccr-inbox/promoting/` | `CCR-{NNN}-{slug}.md` | Conductor만 (체크리스트 수정, 본문·원본 draft 임베드 섹션 금지) |
| **Archived draft (처리 완료된 원본)** | `docs/05-plans/ccr-inbox/archived/` | `CCR-DRAFT-*.md` | `ccr_promote.py` 자동 이동, 이후 read-only |

**배타 규칙**:
- `docs/05-plans/` **루트에는 CCR 관련 파일이 존재하지 않는다**. 루트는 계획 파일(`*.plan.md`, `PLAN-*.md`) 전용. 루트에 `CCR-*.md`가 있으면 **규칙 위반**.
- 모든 CCR 라이프사이클 파일은 `docs/05-plans/ccr-inbox/` 하위에 존재한다:
  - `ccr-inbox/CCR-DRAFT-*.md` — 아직 처리되지 않은 draft
  - `ccr-inbox/promoting/CCR-NNN-*.md` — 승격된 CCR (번호 할당됨, Conductor가 `contracts/` 수정 작업 중 또는 완료)
  - `ccr-inbox/archived/CCR-DRAFT-*.md` — 승격 완료되어 보관된 원본 draft
- 승격본 파일 내부의 `## 원본 Draft` 섹션은 **추적성용 임베드 사본**이다. 이 섹션 편집 금지.

### 계약 변경 필요 시 (팀 → Conductor)

팀이 `contracts/` 수정을 시도하면 hook이 차단하고 CCR draft 경로를 안내합니다.
팀 세션에서 해야 할 일:

1. **Draft 작성** → `docs/05-plans/ccr-inbox/CCR-DRAFT-{teamN}-{YYYYMMDD}[-slug].md`
   (자기 팀 prefix만 hook이 허용. 템플릿: `docs/05-plans/ccr-inbox/README.md`)

2. **필수 필드 기재**:
   - `제안팀`, `제안일`, `영향팀` (**빈 배열 금지**), `변경 대상 파일`, `변경 유형`, `변경 근거`
   - 영향팀은 `contracts/team-policy.json` 의 `api_dependencies` 에서 자동 도출 가능

3. **완료 후 Conductor에게 알림** (별도 채널, 예: Slack/commit message)

### Conductor 승격 작업 (v3 — 배치 계획 워크플로우)

**트리거**: 사용자가 Claude Code 세션에서 "ccr promote" / "ccr-promote" / "CCR 승격" 을 자연어로 입력한다. Claude는 아래 절차를 따라 `ccr-inbox/`의 draft들을 **일괄 읽고 → 배치 계획을 수립한 뒤 → 그룹 단위로 실제 `contracts/` 파일을 수정**한다.

**용어 정의 (CRITICAL)**: **"작업 실행" = 실제 `contracts/` 프로젝트 문서를 draft 의도에 맞게 Read/Edit/Write 수정하는 것**이 본체이며, `python tools/ccr_promote.py --complete` 호출은 편집이 끝난 draft를 마감(로그·NOTIFY·archive)하는 후속 절차일 뿐이다. 편집 없이 마감만 호출하는 것은 금지된다.

**절차** (Claude가 수행):

1. **Phase A — Collection (일괄 읽기)**
   - `python tools/ccr_promote.py --validate-only` 로 전체 inbox 메타 + 번호 후보 + `target_files` 를 JSON으로 획득.
   - invalid draft는 사유 확인 후 건너뜀.
   - 유효 draft들을 **가능한 한 한 번에** Read (제목·변경 근거·변경 요약·Diff 초안·영향 분석).
   - 토큰 예산(약 50k 기준)을 초과하면 **chunking**:
     - **1차 기준 (강제)**: `target_files` 교집합이 있는 draft는 **반드시 같은 chunk**.
     - **2차 기준**: 같은 도메인 파일끼리 묶음 (`contracts/api/API-*`, `contracts/specs/BS-01-*` 등).
     - **3차 기준**: 독립 draft는 번호 순으로 잔여 예산에 채움.
   - 각 chunk는 Phase B/C 를 독립적으로 수행.

2. **Phase B — Planning (배치 계획 수립)**
   - **그룹핑**: chunk 내 draft들을 `target_files` 교집합 기준으로 그룹화.
   - **1회 Read**: 각 그룹의 target `contracts/` 파일을 그룹당 1번만 Read (같은 파일에 N개 draft가 와도 1번).
   - **Merge 플랜**: Intent 추출 → 충돌 검사 → 병합 순서(add → modify → rename → remove) → Idempotency 판정(의도 단위, skip/partial/apply).
   - **불확실성 플래그**: 아래 중 하나라도 해당되면 그룹을 "needs clarification"으로 마킹 → Phase D로 분기.
     - 두 draft의 intent가 직접 충돌 (섹션 삭제 vs 섹션 수정)
     - target 파일이 없고 sibling 스타일 유추도 불가
     - 부분 반영인데 누락분 해석이 복수
     - 상위 계약(`team-policy.json`, `DATA-04-db-schema` 등)의 불변 조건과 어긋남
     - Spec Gap 수준의 미확정 기획 전제

3. **Phase C — Execution (실제 `contracts/` 프로젝트 문서 수정)**
   - 그룹별로 **draft 의도를 반영한 1회 통합 Edit** 을 target 파일에 적용. 이 단계가 CCR의 본체 작업이다.
     - Diff 초안 복붙 금지 — 기존 섹션 번호·Edit History 포맷·컨벤션에 맞춰 재구성.
     - 같은 target에 복수 draft → 순차 재Read 금지, 1회 통합 Edit.
     - 대상 파일 부재 시 sibling 스타일로 `Write` 신규 생성.
     - 이 단계가 끝난 시점에 해당 그룹의 `contracts/` 파일은 draft 의도대로 실제 수정 완료된 상태여야 한다.
   - **편집이 끝난 draft만** 마감 호출:
     ```
     python tools/ccr_promote.py --complete <draft-filename> \
       --number <NNN> --applied-files "<실제 수정된 파일 csv>" [--skipped]
     ```
     - `--applied-files` 는 실제로 수정된 파일만 정직하게 나열.
     - `promoting/CCR-NNN-*.md` 로그 파일 생성 (원본 body 임베드 없음).
     - 영향팀 `docs/backlog/team{X}.md` 에 `NOTIFY-CCR-{NNN}` append (중복 방지).
     - 원본 draft → `archived/` 이동.

4. **Phase D — Clarification (사용자 문의)**
   - 플래그된 그룹은 Phase C 를 건너뛰고 **다른 명확한 그룹을 먼저 실행**한 뒤 마지막에 `AskUserQuestion` 으로 구조화된 선택지 제시.
   - 응답 후 해당 그룹만 재실행. **임의 판정 절대 금지**.

5. **Phase E — Finalize**
   - `python tools/backlog_aggregate.py` 집계 갱신.
   - 최종 리포트: chunk별 처리 결과, 그룹별 성공/skip/보류, 신규 생성 파일, 수동 검토 포인트.
   - **Commit** (사용자 별도 승인 후): `git commit -m "[CCR-NNN..MMM] ..."`.

**금지**:
- `python tools/ccr_promote.py` 를 인자 없이 실행 → deprecation 경고만 출력. 새 워크플로우로 유도.
- Draft의 Diff 초안을 기존 문서에 **그대로 복붙** 금지.
- **동일 target 파일의 복수 draft를 순차 재Read 방식으로 처리 금지** — 반드시 동일 그룹으로 묶어 1회 통합 Edit.
- **`contracts/` 실제 편집 없이 `--complete` 만 호출 금지** (의도적 skip은 `--skipped` 플래그 사용).
- **불확실한 상황에서 임의 판정 금지** — Phase D 로 에스컬레이션.
- `integration-tests/` 수정 금지 (TODO 로그만 기록).
- git commit은 사용자 승인 없이 금지.

### 계약 파일 (Conductor 단독 소유)

```
contracts/
├── api/              ← API-01~06 (읽기 전용)
├── data/             ← DATA-01~06 + PRD (읽기 전용)
└── specs/            ← BS-00~07 (읽기 전용)
```

---

## 문서 표준 (WSOP LIVE 준수)

**모든 EBS 문서는 WSOP LIVE Confluence 표준을 따릅니다.**
참고: `C:\claude\wsoplive\docs\confluence-mirror\` (1,361페이지 미러)

### 필수 구조

1. **Edit History 테이블** (최상단)
   ```markdown
   | 날짜 | 항목 | 내용 |
   |------|------|------|
   | 2026-04-10 | 5팀 구조 | contracts/ 도입 |
   ```

2. **개요** — 1~3줄 목적
3. **상세 내용** — 기능별/화면별 분리, 최대 3단계 헤더
4. **검증/예외** — 유효성, edge case, 에러

### 상세도 규칙

- 기능 설명은 **모든 경우의 수** 열거 (경우의 수 행렬 표)
- 상태값은 반드시 **테이블 정의** (상태명 + 설명 + 전환)
- 트리거는 **발동 주체 명시** (CC 수동 / RFID 자동 / 엔진 자동)
- UI 텍스트는 **영문 우선** + 한글 설명
- 수치/규칙 정확도 (예: "8~20자", "99.5% 이상")

### 이미지

- 기능 기획서에 스크린샷/목업 **필수**
- 파일명: `{문서명}-{기능명}.png`
- 이미지 없으면 텍스트 대체 설명만

---

## Spec Gap 프로세스 (CRITICAL)

구현 중 기획 문서에 명시되지 않은 판단 필요 시, **임의 구현 금지**.

### 절차

1. **Gap 문서 추가** → `{팀폴더}/qa/spec-gap.md`
   ```markdown
   ### GAP-L-001 Settings Graphic Editor 탭 표시/숨김
   - **발견일**: 2026-04-10
   - **심각도**: Medium
   - **관련 문서**: contracts/specs/BS-03-settings/
   - **누락 내용**: Graphic Editor 탭 노출 조건 미정
   - **임시 구현**: 항상 표시 (Admin만 접근 가능)
   - **기획 보강 요청**: BS-03에 "Operator/Viewer는 Graphic Editor 탭 숨김" 명시
   ```

2. **임시 구현** 수행 (workaround 문서화 필수)
3. **기획 보강** 또는 **CCR 제출** (심각도에 따라)
4. **RESOLVED 처리** ← 기획 확정 후만

### Gap 문서 위치

| 팀 | 경로 |
|----|------|
| Team 1 | `team1-frontend/qa/lobby/QA-LOBBY-03-spec-gap.md` |
| Team 2 | `team2-backend/qa/spec-gap.md` |
| Team 3 | `team3-engine/qa/QA-GE-10-spec-gap.md` |
| Team 4 | `team4-cc/qa/commandcenter/spec-gap.md` (또는 `qa/graphic-editor/`) |

**금지**:
- Gap 문서 없이 workaround 코드 커밋
- RESOLVED 처리 시 기획 문서 업데이트 없이 종료

---

## 백로그 관리

**단일 글로벌 백로그** → `docs/backlog.md`

### 항목 형식

```markdown
### [B-NNN] 제목
- **날짜**: YYYY-MM-DD
- **teams**: [team1, team2]        ← 신규 필드
- **설명**: 구체적 요구사항
- **수락 기준**: 완료 판단 기준
- **관련 PRD**: contracts/ 스펙
```

### 필터링

팀은 `teams:` 필드로 자신의 항목만 필터링.
크로스팀 항목(`teams: [team2, team4]` 등)이 가시화되어 조정 용이.

---

## 통합 테스트

`integration-tests/` — HTTP/WebSocket 기반 계약 검증

### 규칙

- **소스 임포트 금지** — 다른 팀 폴더의 소스 직접 import 불가
- **HTTP/WebSocket only** — 각 팀 서비스 엔드포인트 호출
- 시나리오 포맷: `.http` (REST Client 호환)

### 서비스 엔드포인트

| 서비스 | 포트 | 팀 |
|--------|------|-----|
| Backend (BO) | `http://localhost:8000` | Team 2 |
| Engine Harness | `http://localhost:8080` | Team 3 |
| WebSocket (Lobby) | `ws://localhost:8000/ws/lobby` | Team 2 |
| WebSocket (CC) | `ws://localhost:8000/ws/cc` | Team 2 |

---

## Games PRD 규칙

`team3-engine/specs/games/` 문서는 **Confluence 업로드 대상**.

**금지**:
- Markdown 링크 `[text](url)`, 앵커 링크 금지
- 다른 문서명 언급 금지
- 참조 내용은 이 문서 내 직접 설명으로 대체

**결과**: 각 문서는 독립 완결적이어야 함.

---

## Claude Code 세션 분리

**중요**: Conductor 세션과 팀 세션은 분리 운영.

| 세션 | 루트 폴더 | CLAUDE.md | 범위 |
|------|----------|----------|------|
| **Conductor** | `C:/claude/ebs/` | 이 파일 | contracts/, docs/, integration-tests |
| **Team 1** | `C:/claude/ebs/team1-frontend/` | `team1-frontend/CLAUDE.md` | src/, qa/, ui-design |
| **Team 2** | `C:/claude/ebs/team2-backend/` | `team2-backend/CLAUDE.md` | src/, specs/, qa |
| **Team 3** | `C:/claude/ebs/team3-engine/` | `team3-engine/CLAUDE.md` | ebs_game_engine/, specs/, qa |
| **Team 4** | `C:/claude/ebs/team4-cc/` | `team4-cc/CLAUDE.md` | src/, specs/, qa/, ui-design |

**팀 세션의 금지 사항**:
- `../../contracts/` 파일 수정
- 다른 팀 폴더 접근
- Conductor 전용 문서 수정

---

## 참고 문서

| 문서 | 경로 | 용도 |
|------|------|------|
| **Foundation PRD** | `docs/01-strategy/PRD-EBS_Foundation.md` | EBS Core 아키텍처 정의 |
| **Production Plan** | `docs/00-reference/2026-WSOP-Production-Plan-V2.pdf` | WSOP 프로덕션 원본 |
| **PokerGFX 역설계** | `docs/07-archive/legacy-repos/ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md` | 벤치마크 |
| **PokerGFX User Manual** | `docs/00-reference/PokerGFX-User-Manual.md` | 사용자 매뉴얼 (152KB) |
| **Field Registry** | `docs/00-reference/field-registry.json` | 설정 필드 소유권 SSOT |

---

## 설계 자산 (ebs_ui → 통합 완료)

| 자산 | 통합 위치 | 원본 |
|------|----------|------|
| **Action Tracker** (CC 44기능, 8화면) | `team4-cc/ui-design/reference/action-tracker/` | ebs_ui/ebs-action-tracker |
| **Console** (6탭, 99+ 설정) | `team1-frontend/ui-design/reference/console/` | ebs_ui/ebs-console |
| **Skin Editor** (Vue3 PoC) | `team4-cc/ui-design/reference/skin-editor/` | ebs_ui/ebs-skin-editor |

## 아카이브된 레거시 레포

| 레포 | 아카이브 위치 |
|------|-------------|
| ebs_reverse | `docs/07-archive/legacy-repos/ebs_reverse/` |
| ebs_reverse_app | `docs/07-archive/legacy-repos/ebs_reverse_app/` |
| ebs_app | `docs/07-archive/legacy-repos/ebs_app-README.md` |
| ebs_bo | `docs/07-archive/legacy-repos/ebs_bo-README.md` |
| ebs_ecosystem | `docs/07-archive/legacy-repos/ebs_ecosystem/` |
| ebs_github | `docs/07-archive/legacy-repos/ebs_github/` |
| ebs_poc | `docs/07-archive/legacy-repos/ebs_poc/` |
| ebs_table | `docs/07-archive/legacy-repos/ebs_table/` |

---

**마지막 업데이트**: 2026-04-10 (v4.1.0 — Layered Scope Guard: hook + team-policy.json + backlog 분할 + CCR inbox 도입)
