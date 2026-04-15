# EBS Conductor CLAUDE.md — 5팀 구조 (Team 0)

## Role

Team 0 — Conductor. 최상위 오케스트레이션, 문서 구조 소유, 통합 테스트 소유.

**이 파일은 Conductor 세션용입니다.** 팀별 개발은 각 `team*/CLAUDE.md`를 따릅니다.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | v5.0.0 (docs v10) | 단일 `docs/` 원칙. 4 홈 폴더(1 Product / 2 Development / 3 Change Requests / 4 Operations). `contracts/`, `docs/01-strategy`, `docs/05-plans`, `team*/specs|ui-design|qa` 폐지 — 모두 `docs/2. Development/2.N {팀}/` 로 흡수 |
| 2026-04-10 | v4.1.0 | Layered Scope Guard (hook + team-policy.json + backlog 분할 + CCR inbox) |
| 2026-04-10 | v4.0.0 | 5팀 구조 확정, `contracts/` 분리 |

---

## 프로젝트 설계 원칙 (CRITICAL)

### 원칙 1 — WSOP LIVE Confluence 정렬

**"WSOP LIVE Confluence 문서를 기반으로, 동일하게 설계할 수 있는 것은 최대한 동일하게 설계한다."**

- **기준 레포**: `C:/claude/wsoplive/` (1,361 Confluence 페이지 미러)
- **적용 대상**: 문서 구조 · 폴더 네이밍 · Confluence 메타데이터 · 용어/레이블 · 동기화 메커니즘
- **적용 예외 (의도적 divergence)**: EBS 고유 요구(RFID 하드웨어, 실시간 오버레이, 다팀 병렬)는 `Why:` 필드로 justify
- **How to apply**:
  1. 신규 문서 작성 전 `wsoplive/docs/confluence-mirror/` 에서 유사 주제 페이지 확인
  2. 구조/네이밍/용어를 우선 일치
  3. 고유 요구 때문에 달라야 할 부분만 justify + document

**금지**: "WSOP LIVE에 없으니 새로 만든다"는 즉흥 판단. 먼저 유사 패턴 검색.

### 원칙 2 — 단일 `docs/` 경로 (v10)

**모든 문서는 레포 루트 `docs/` 아래에만 존재한다.** 팀 폴더(`team1-frontend/`, `team2-backend/`, `team3-engine/`, `team4-cc/`)는 **코드 전용**이며 `specs/`, `ui-design/`, `qa/` 폴더를 갖지 않는다.

---

## 문서 구조 (v10)

### 4 홈 레벨

| 폴더 | 답하는 질문 | 소유 |
|------|-------------|------|
| `docs/1. Product/` | "이 제품이 무엇인가?" (Foundation, Architecture, Game Rules, PokerGFX Reference) | Conductor |
| `docs/2. Development/` | "어떻게 만드나?" (팀별 상세 설계 + 공통 계약) | 각 팀 / Conductor |
| `docs/3. Change Requests/` | "무엇을 바꾸나?" (CR lifecycle: pending → in-progress → done) | 팀(draft) / Conductor(승격 이후) |
| `docs/4. Operations/` | "어떻게 운영하나?" (Roadmap, Backlog, Plans, Reports) | Conductor |

추가:
- `docs/mockups/`, `docs/images/` — 공유 그래픽 자산
- `docs/_generated/` — CI 자동 생성 인덱스 (수작업 편집 금지)

### `2. Development/` 5 섹션

| 섹션 | 소유 팀 | 기술 |
|------|---------|------|
| `2.1 Frontend/` | team1 | Quasar (Vue 3) + TypeScript |
| `2.2 Backend/` | team2 (publisher: API-01/05/06, DATA-*, BO) | FastAPI + SQLite/PostgreSQL |
| `2.3 Game Engine/` | team3 (publisher: API-04 OutputEvent) | Pure Dart |
| `2.4 Command Center/` | team4 (publisher: RFID HAL) | Flutter/Dart + Rive |
| `2.5 Shared/` | Conductor | 팀 간 공통 계약(BS Overview, Authentication, EBS Core, Risk Matrix, `team-policy.json`) |

### Ownership & Scope Guard v5

| Path prefix | Owner |
|-------------|-------|
| `docs/1. Product/Game_Rules/**` | Conductor (+ team3 publisher) |
| `docs/1. Product/**` (그 외) | Conductor |
| `docs/2. Development/2.1 Frontend/**` | team1 |
| `docs/2. Development/2.2 Backend/**` | team2 (API/DB/BO 포함, publisher Fast-Track) |
| `docs/2. Development/2.3 Game Engine/**` | team3 (Overlay API 포함, publisher Fast-Track) |
| `docs/2. Development/2.4 Command Center/**` | team4 (RFID HAL 포함, publisher Fast-Track) |
| `docs/2. Development/2.5 Shared/**` | Conductor |
| `docs/3. Change Requests/pending/CR-teamN-*.md` | 해당 팀 |
| `docs/3. Change Requests/{in-progress,done}/**` | Conductor |
| `docs/4. Operations/**` | Conductor |
| `docs/mockups/**`, `docs/images/**` | Conductor |
| `docs/_generated/**` | CI only (수작업 편집 금지) |
| `team{N}-*/**` (코드/설정) | 해당 팀 |
| `integration-tests/**` | Conductor |

> **SSOT**: `docs/2. Development/2.5 Shared/team-policy.json`. Hook · `tools/*` 모두 이 파일 하나만 참조.
>
> **자동화 상태**: 정책 SSOT + `tools/ccr_*.py` 검증은 구현되어 있으나, **PreToolUse hook 기반 강제 차단은 미구현**(가정 컴포넌트). 실제 경계는 정책 파일 + CCR 프로세스 + 사람 규율로 운영한다.

---

## CCR 프로세스 (docs v10 경로)

### CR 라이프사이클 파일 위치

| 상태 | 경로 | 파일명 | 편집 권한 |
|------|------|--------|----------|
| **Draft** | `docs/3. Change Requests/pending/` | `CR-teamN-YYYYMMDD[-slug].md` | 제안팀만 |
| **Promoted (진행 중)** | `docs/3. Change Requests/in-progress/` | `CR-NNN-{slug}.md` | Conductor |
| **Archived (완료)** | `docs/3. Change Requests/done/` | 원본 draft + 승격본 | read-only |

> 구 `docs/05-plans/ccr-inbox/{,promoting,archived}/` 은 v10 에서 폐기. `CCR-DRAFT-*.md` → `CR-teamN-*.md` 접두사 변경.

### 리스크 분류 (v4 Fast-Track)

| 등급 | 처리 경로 | Conductor 필요 |
|------|----------|---------------|
| LOW (추가 전용, 영향팀 ≤1) | publisher 직접 반영 + 영향팀 1명 approve | 불필요 |
| MEDIUM (비파괴 수정, 영향팀 ≤2) | publisher 직접 반영 + 영향팀 전원 approve | 불필요 |
| HIGH (파괴적 변경, 영향팀 3+) | 풀 프로세스 (Phase A–E) | **필수** |

- 리스크 판정: `python tools/ccr_validate_risk.py --draft <파일명>`
- 승격 도구: `python tools/ccr_promote.py` (신규 경로 인식)
- 정책: `docs/2. Development/2.5 Shared/team-policy.json` + `docs/2. Development/2.5 Shared/Risk_Matrix.md`

### Publisher Fast-Track

`team-policy.json`의 `contract_ownership` 에 등록된 publisher 팀은 자기 소유 계약 파일을 직접 수정할 수 있다.

| 팀 | 직접 수정 가능 경로 |
|----|---------------------|
| team2 | `docs/2. Development/2.2 Backend/{APIs,Database,Back_Office}/**` |
| team3 | `docs/2. Development/2.3 Game Engine/APIs/**` |
| team4 | `docs/2. Development/2.4 Command Center/APIs/**` |

**단**, 수정 후 `python tools/ccr_validate_risk.py --draft <파일명>` 사후 검증 실행 필수. 리스크 등급이 허용 범위를 초과하면 풀 CCR 절차로 전환.

### Conductor 승격 워크플로우 (v3 배치 모드)

트리거: 사용자가 "ccr promote" / "CCR 승격" 자연어 입력.

1. **Phase A — Collection**: `python tools/ccr_promote.py --validate-only` → JSON 으로 전체 `pending/` 메타 획득. 유효 draft 일괄 Read.
2. **Phase B — Planning**: `target_files` 교집합으로 그룹핑, target 파일은 그룹당 1회만 Read, Intent 추출 + 충돌 검사 + 병합 순서(add → modify → rename → remove).
3. **Phase C — Execution**: 그룹별 1회 통합 Edit 으로 실제 docs 수정. 편집 완료 후 `python tools/ccr_promote.py --complete <draft> --number N --applied-files "<csv>"` 마감.
4. **Phase D — Clarification**: 충돌·모호·Spec Gap 그룹만 `AskUserQuestion` 으로 에스컬레이션.
5. **Phase E — Finalize**: `python tools/backlog_aggregate.py` → 사용자 리포트 → git commit `[CR-NNN..MMM] ...`.

**핵심**: "작업 실행" = 실제 docs 파일을 Read/Edit/Write 로 수정하는 것이 본체. `--complete` 는 로그·NOTIFY·archive 마감 절차일 뿐. 편집 없이 `--complete` 만 호출 금지.

---

## Spec Gap 프로세스 (CCR-first)

구현 중 기획 문서에 명시되지 않은 판단 필요 시, **임의 구현 금지**.

### 경로 분기

**1단계: `docs/2. Development/2.N {팀}/**` (팀 내부) 외 변경이 필요한가?**

#### Path A — Shared/다른 팀 경로 변경 필요
1. **CR draft 먼저 작성**: `docs/3. Change Requests/pending/CR-teamN-YYYYMMDD-slug.md`
2. 임시 구현 (workaround 문서화)
3. 해당 팀의 `Spec_Gaps.md` 에는 **pointer만** 기록:
   ```markdown
   ### GAP-{팀}-NNN {제목}
   - **발견일**: YYYY-MM-DD
   - **CR**: `CR-teamN-YYYYMMDD-slug.md` 제출됨 (Conductor 승격 대기)
   - **임시 구현**: {workaround 1줄}
   - **Status**: OPEN (CR 승격 대기)
   ```
4. Conductor 승격 → 실제 반영
5. Gap 항목 RESOLVED 업데이트

#### Path B — 팀 내부 판단만 필요
1. 팀 `Spec_Gaps.md` 에 직접 기록
2. 임시 구현
3. 팀 내부 결정 후 RESOLVED

### Gap 문서 위치 (v10)

| 팀 | 경로 |
|----|------|
| team1 | `docs/2. Development/2.1 Frontend/Spec_Gaps.md` |
| team2 | `docs/2. Development/2.2 Backend/Spec_Gaps.md` |
| team3 | `docs/2. Development/2.3 Game Engine/Spec_Gaps.md` |
| team4 | `docs/2. Development/2.4 Command Center/Spec_Gaps.md` |

---

## 백로그 관리 (v10)

| 경로 | 내용 |
|------|------|
| `docs/2. Development/2.{1..4} {팀}/Backlog.md` | 팀별 PENDING/IN_PROGRESS/DONE |
| `docs/4. Operations/Conductor_Backlog.md` | 크로스팀/인프라 백로그 + DONE 역사 |
| `docs/_generated/by-team/` | 집계 뷰 (`tools/backlog_aggregate.py`) |

---

## 통합 테스트

`integration-tests/` — HTTP/WebSocket 기반 계약 검증

- **소스 임포트 금지** — 다른 팀 폴더의 소스 직접 import 불가
- **HTTP/WebSocket only** — 각 팀 서비스 엔드포인트 호출
- 시나리오 포맷: `.http` (REST Client 호환)

| 서비스 | 포트 | 팀 |
|--------|------|-----|
| Backend (BO) | `http://localhost:8000` | team2 |
| Engine Harness | `http://localhost:8080` | team3 |
| WebSocket (Lobby) | `ws://localhost:8000/ws/lobby` | team2 |
| WebSocket (CC) | `ws://localhost:8000/ws/cc` | team2 |

---

## Game Rules (Confluence 발행)

`docs/1. Product/Game_Rules/` 문서는 Confluence 업로드 대상.

**금지**: Markdown 링크 `[text](url)`, 앵커 링크, 다른 문서명 언급. 각 문서는 독립 완결적이어야 함.

---

## 문서 표준 (WSOP LIVE 준수)

### 필수 구조

1. **Frontmatter** (파일 최상단)
   ```yaml
   ---
   title: ...
   owner: team1 | team2 | team3 | team4 | conductor
   tier: contract | feature | internal
   legacy-id: BS-02-02   # 마이그레이션 추적용
   confluence-page-id: 123456
   last-updated: 2026-04-15
   ---
   ```

2. **Edit History 테이블** (frontmatter 아래)
3. **개요** — 1~3줄 목적
4. **상세 내용** — 기능별/화면별 분리, 최대 3단계 헤더
5. **검증/예외** — 유효성, edge case, 에러

### 파일명 규칙

| 규칙 | 예시 |
|------|------|
| 홈 레벨 | `1. Product/`, `4. Operations/` |
| 섹션 하위 (팀) | `2.1 Frontend/`, `2.5 Shared/` |
| feature 폴더 PascalSnake | `Lobby/`, `RFID_Cards/`, `Holdem/` |
| 일반 파일 `Pascal_Snake_Case.md` | `Event_and_Flight.md`, `Auth_and_Session.md` |
| feature 내부 고정 파일 | `UI.md`, `QA.md` |
| 섹션 landing | 폴더명과 동일한 `.md` (`1. Product.md`) |
| legacy ID | frontmatter `legacy-id:` 만 (파일명에서 번호 prefix 제거) |

### 이미지

- 기능 기획서에 스크린샷/목업 **필수**
- `docs/images/` 공유 또는 feature 폴더 하위 `visual/screenshots/`

---

## WSOP LIVE 정렬 매핑

| WSOP LIVE 패턴 | EBS v10 | 일치도 |
|---------------|---------|--------|
| 홈 레벨 번호 prefix (`1.`, `2.`) | 동일 채택 | O |
| 섹션 하위 번호 (`6.N`) | `2.N` 팀 하위번호 | O |
| `Backend/Frontend/` 도메인 폴더 | `2.2 Backend/`, `2.1 Frontend/` | O |
| Confluence 프론트매터 | `confluence-page-id` | O |
| 단방향 pull (`confluence_sync.py`) | 동일 패턴 | O |
| — | `2.5 Shared/` (EBS 고유 다팀 병렬 + BS-00/01) | △ EBS 고유 |
| — | `3. Change Requests/` (CCR 프로세스) | X EBS 고유 |

---

## 팀 레지스트리 & 개발자 동선

| 팀 | 코드 폴더 | 문서 폴더 | 소유 API |
|----|-----------|-----------|----------|
| Team 1 | `team1-frontend/` | `docs/2. Development/2.1 Frontend/` | consumes API-01/05/06 |
| Team 2 | `team2-backend/` | `docs/2. Development/2.2 Backend/` | publishes API-01/05/06, DATA-*, BO |
| Team 3 | `team3-engine/` | `docs/2. Development/2.3 Game Engine/` | publishes API-04 OutputEvent |
| Team 4 | `team4-cc/` | `docs/2. Development/2.4 Command Center/` | publishes RFID HAL; consumes API-04 |

**개발자 워크플로우**:
- 코드 작업 → `cd team{N}-*/` (해당 팀 폴더)
- 문서 작업 → `cd "docs/2. Development/2.{N} {팀명}/"`
- 팀 폴더에는 `CLAUDE.md`, `README.md`, `src/`, `test/` 등 **코드 자산만** 존재

---

## Claude Code 세션 분리

| 세션 | 루트 | CLAUDE.md |
|------|------|-----------|
| Conductor | `C:/claude/ebs/` | 이 파일 |
| Team 1 | `C:/claude/ebs/team1-frontend/` | `team1-frontend/CLAUDE.md` |
| Team 2 | `C:/claude/ebs/team2-backend/` | `team2-backend/CLAUDE.md` |
| Team 3 | `C:/claude/ebs/team3-engine/` | `team3-engine/CLAUDE.md` |
| Team 4 | `C:/claude/ebs/team4-cc/` | `team4-cc/CLAUDE.md` |

**팀 세션 금지**:
- `docs/2. Development/2.5 Shared/`, `docs/1. Product/`, `docs/3. Change Requests/in-progress,done/`, `docs/4. Operations/` 수정 (CR 프로세스 경유)
- 다른 팀 문서 폴더(`docs/2. Development/2.N`) 수정
- 다른 팀 코드 폴더 접근

---

## 진입점 & 검수

| 용도 | 경로 |
|------|------|
| 전체 문서 인덱스 | `docs/_generated/full-index.md` |
| API 전체 보기 | `docs/_generated/by-topic/APIs.md` |
| 섹션별 인덱스 | `docs/1. Product/1. Product.md` 등 9개 landing |
| 문서 표준/규칙 | `docs/README.md` |

---

## 참고 문서

| 문서 | 경로 |
|------|------|
| Foundation | `docs/1. Product/Foundation.md` (v41.0.0) |
| Architecture | `docs/1. Product/Architecture.md` |
| Team Structure | `docs/1. Product/Team_Structure.md` |
| Communication Rules | `docs/1. Product/Communication_Rules.md` |
| PokerGFX Reference | `docs/1. Product/PokerGFX_Reference.md` |
| EBS Core (3입력→오버레이) | `docs/2. Development/2.5 Shared/EBS_Core.md` |
| Risk Matrix | `docs/2. Development/2.5 Shared/Risk_Matrix.md` |
| Roadmap | `docs/4. Operations/Roadmap.md` |

---

**마지막 업데이트**: 2026-04-15 (v5.0.0 — docs v10 단일 경로 구조 전환)
