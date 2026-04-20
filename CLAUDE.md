# EBS Conductor CLAUDE.md — 5팀 구조 (Team 0)

## 🎯 프로젝트 의도 (최상위 전제, 2026-04-20 재정의)

**EBS = 개발팀 인계용 기획서 완결 프로젝트**. 실제 제품 출시가 아니다.

- 최종 산출물: `docs/` 기획 문서 + `team1~4/` **프로토타입** (production 아님)
- 사용자 = 기획자. 외부 개발팀 인계 대상
- 쌍방향 인과: **프로토타입 완벽 동작 ↔ 기획서 완벽**
- 성공 기준: "외부 개발팀이 기획서+프로토타입만으로 재구현 가능한가"
- **MVP / Phase / 런칭 일정 / 업체 선정 = 이 프로젝트 범위 밖**

### 프로토타입 실패 대응 프로토콜 (Type A/B/C)

앱 실행/빌드/테스트 실패 감지 시 **먼저** Type 분류:

| Type | 의미 | 우선 조치 |
|:---:|------|-----------|
| **A** | 기획엔 답 있음, 구현 실수 | 구현 PR |
| **B** | 기획 공백 (팀마다 다른 가정) | **기획 보강 PR 먼저** |
| **C** | 기획 모순 (기획서 간 충돌) | **기획 정렬 PR 먼저** |

상세: `docs/4. Operations/Spec_Gap_Triage.md`

---

## Role

Team 0 — Conductor. **기획서 편집장 + 완결성 판정자 + 기획-프로토타입 추적 체계 관리자** 가 최우선 역할. 그 다음 최상위 오케스트레이션, 문서 구조 소유, 통합 테스트 소유.

**이 파일은 Conductor 세션용입니다.** 팀별 개발은 각 `team*/CLAUDE.md`를 따릅니다.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-17 | v6.0.0 (docs v11) | CCR 완전 폐기. 3 홈 폴더(1 Product / 2 Development / 4 Operations). `free_write_with_decision_owner` v7 거버넌스. 브랜치 강제 hook 강화. |
| 2026-04-15 | v5.0.0 (docs v10) | 단일 `docs/` 원칙. `contracts/`, `docs/01-strategy`, `docs/05-plans`, `team*/specs|ui-design|qa` 폐지 |
| 2026-04-10 | v4.0.0 | 5팀 구조 확정 |

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

### 3 홈 레벨

| 폴더 | 답하는 질문 | 소유 |
|------|-------------|------|
| `docs/1. Product/` | "이 제품이 무엇인가?" (Foundation, Architecture, Game Rules, PokerGFX Reference) | Conductor |
| `docs/2. Development/` | "어떻게 만드나?" (팀별 상세 설계 + 공통 계약) | 각 팀 / Conductor |
| `docs/4. Operations/` | "어떻게 운영하나?" (Roadmap, Backlog, Plans, Reports) | Conductor |

> `docs/3. Change Requests/` 는 역사 폴더로 존치 (활성 프로세스 아님).

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
| `docs/4. Operations/**` | Conductor |
| `docs/mockups/**`, `docs/images/**` | Conductor |
| `docs/_generated/**` | CI only (수작업 편집 금지) |
| `team{N}-*/**` (코드/설정) | 해당 팀 |
| `integration-tests/**` | Conductor |

> **SSOT**: `docs/2. Development/2.5 Shared/team-policy.json` (v7, `governance_model: free_write_with_decision_owner`). Hook · `tools/*` 모두 이 파일 하나만 참조.
>
> **거버넌스 모델 (v7, 2026-04-17)**: **쓰기 권한 ≠ 결정 권한**. 모든 세션이 모든 docs 를 자유 편집할 수 있다. 위 표의 "owner" 컬럼은 **결정 권한자**(decision_owner) — 의미적 충돌 발생 시 최종 판정. 쓰기 제한은 hook 으로 차단하지 않는다.

---

## 멀티 세션 충돌 방지 (v6, 3계층 방어)

| Layer | 메커니즘 | 자산 |
|-------|---------|------|
| **L1. 세션-당-브랜치** | Conductor=`main` 직접, 팀=`work/team{N}/{date}-{slug}` 자동 체크아웃, `/team-merge` 로 ff merge. **Subdir(`ebs/team{N}-*/`) · Worktree(`ebs-team{N}-<slug>/`) 모두 지원** (→ `docs/4. Operations/Multi_Session_Workflow.md`) | `.claude/hooks/session_branch_init.py`, `.claude/hooks/branch_guard.py`, `tools/team_merge.py` |
| **L2. Active-edit 레지스트리** | `meta/active-edits` orphan 브랜치에 세션별 claim JSON. SessionStart 시 활성 항목 컨텍스트 주입, PreEdit 시 충돌 1회 경고(같은 호출 재시도 시 통과). bypass 시 침묵. TTL 2h. | `.claude/hooks/_registry.py`, `active_edits_session_start.py`, `active_edits_preedit.py`, `active_edits_session_end.py`, `tools/active_edits_gc.py` |
| **L3. 핫스팟 파일 분해** | `Backlog/`, `Spec_Gaps/`, `Conductor_Backlog/` 디렉토리 + 항목당 1파일. 집계는 `tools/backlog_aggregate.py` 가 `_generated/` 에 자동 생성 | `tools/backlog_decompose.py` (1회), `tools/backlog_aggregate.py` |

상세 설계 근거: `~/.claude/plans/shimmering-roaming-neumann.md`

---

## 문서 변경 거버넌스 (v7 — free_write + decision_owner)

모든 세션이 모든 docs 를 자유 편집할 수 있다. 의미적 충돌 시 decision_owner 가 최종 판정.

### 원칙

1. **자유 편집**: hook 으로 쓰기를 차단하지 않음
2. **추가 전용 (additive)**: 기존 문단·스키마·코드 블록을 가급적 건드리지 않고 새 하위 섹션으로 보강
3. **decision_owner notify**: 커밋 메시지 또는 active-edits 레지스트리로 알림
4. **충돌 시**: rebase 중 감지 → decision_owner 가 의미적 판정 (§"멀티 세션 충돌 방지" 참조)
5. **Backlog 연동**: 기획 보강 후 후속 구현 작업을 Backlog 에 추가

### decision_owner 매핑

`team-policy.json` 의 `teams[*].owns` + `contract_ownership[*].publisher` 참조.

### Publisher 직접 편집 권한

`team-policy.json`의 `contract_ownership` 에 등록된 publisher 팀은 자기 소유 계약 파일을 직접 수정 가능:

| 팀 | 직접 수정 가능 경로 |
|----|---------------------|
| team2 | `docs/2. Development/2.2 Backend/{APIs,Database,Back_Office}/**` |
| team3 | `docs/2. Development/2.3 Game Engine/APIs/**` |
| team4 | `docs/2. Development/2.4 Command Center/APIs/**` |

파괴적 변경(remove/rename/breaking) 시 subscriber 팀 전원 사전 합의 + Conductor 에스컬레이션 필수.

### 기획 공백 발견 시

구현 중 기획 문서에 명시되지 않은 판단이 필요하면:

1. **공백 식별** — "이 판단은 어느 문서가 답해야 하는가?" 를 먼저 정한다
2. **해당 문서 보강** — 추가 전용(additive) 원칙으로 즉시 보강
3. **decision_owner notify** — 커밋 메시지 또는 active-edits 레지스트리로 알림
4. **구현 계속** — 보강된 문서에 기반하여 결정적으로 구현. 임의 판단 금지

### Backlog 규칙

구현 대상은 팀 `Backlog.md` (또는 `Backlog/` 항목 파일) 에 등재한다. 공백을 발견하고 기획 문서를 보강한 뒤, 후속 구현 작업을 Backlog 에 추가해야 구현 추적이 끊기지 않는다.

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
- `docs/2. Development/2.5 Shared/`, `docs/1. Product/`, `docs/4. Operations/` 수정 (Conductor 소유)
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
| Foundation | `docs/1. Product/Foundation.md` (EBS 기초 기획서, Confluence SSOT: page 3625189547) |
| Product Landing (Architecture / Team Structure / Communication Rules 통합) | `docs/1. Product/1. Product.md` |
| PokerGFX Reference | `docs/1. Product/References/PokerGFX_Reference.md` |
| EBS Core (3입력→오버레이) | `docs/2. Development/2.5 Shared/EBS_Core.md` |
| Risk Matrix | `docs/2. Development/2.5 Shared/Risk_Matrix.md` |
| Roadmap | `docs/4. Operations/Roadmap.md` |

---

**마지막 업데이트**: 2026-04-17 (v6.0.0 — CCR 완전 폐기, v7 거버넌스, 브랜치 강제 강화)
