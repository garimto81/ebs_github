# EBS Implementation Roadmap — Strategy ↔ Sibling Repo Bridge

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Foundation PRD v41.0.0 → sibling 레포 실행 브릿지. 캐노니컬 144 feature ID 재사용. |
| 2026-04-08 | 설계 문서 패키지 완성 | 74개 설계 문서 작성 완료. 산출물 인벤토리 섹션 추가 |

---

## 개요

이 문서는 **기획 → 실행 전환을 위한 단일 브릿지**다. 새 ID 체계나 백로그를 만들지 않고, 이미 존재하는 다음 자산들을 연결한다:

1. **전략**: `docs/01-strategy/PRD-EBS_Foundation.md` v41.0.0 (Phase 1 POC 5단계 + KPI + 5-Phase 로드맵)
2. **캐노니컬 ID**: `docs/01-strategy/EBS-Feature-Catalog.md` v1.0.0 (144개, MW-/OUT-/G1-/G2-/G3-/SYS-/SK-/GEB-/GEP-)
3. **로드맵 다이어그램**: EBS-Kickoff-2026 Phase 1~5 sibling 레포 매핑 (원본: archive 보존)
4. **행동 명세**: `contracts/specs/BS-00~07/` + `team3-engine/specs/engine-spec/BS-06-*` (전체 완성 — 2026-04-08)
5. **기존 UI 자산**: `team4-cc/ui-design/reference/action-tracker/`, `team1-frontend/ui-design/reference/console/`

> **정의**: 이 레포(`garimto81/ebs`)는 **기획 레포**다 (`CLAUDE.md` 명시). 실제 구현 코드는 sibling 레포에서 살고, 이 문서는 어떤 항목이 어느 sibling 레포로 가는지를 기록한다.

---

## 1. Sibling 레포 매핑

`EBS-Kickoff-2026.md` Phase 1 다이어그램(line 119-135) 기준:

| Sibling 레포 | 위치 | Phase 1 역할 | Phase 2 역할 |
|---|---|---|---|
| **`ebs (HW)`** | `docs/07-archive/legacy-repos/ebs_poc/` (아카이브) | ST25R3911B + 12대 안테나 프로토타입 | 12대 안정화, 인식률 ≥ 99.5% |
| **`ebs (FW)`** | TBD (MCU 펌웨어 전용) | ISO 14443-A UID 읽기 → Serial UART | 카드 매핑 갱신, 에러 복구 |
| **`ui_overlay`** | `team4-cc/` (통합) | 기초 카드 표시 UI | Console 5탭 + Riv 합성 |
| **`ebs_ui`** | `team*/ui-design/reference/` (통합) | Action Tracker 8 mockup, Console v9.7.0 | BS-03/05 구현 참조 자산 |

> **TBD 항목**: `ebs (HW)`/`ebs (FW)` 의 정확한 GitHub 레포 이름은 별도 결정. 이 문서는 _개념적_ sibling으로 표기한다.

---

## 2. Phase 1 POC (2026 H1) — 5단계 시나리오

`PRD-EBS_Foundation.md` line 1002-1011 §"Phase 1 POC 데모 시나리오" verbatim 매핑.

| # | 시나리오 | Mock/Real | Sibling 레포 | 캐노니컬 IDs (Catalog) | 기존 자산 | 미해결 작업 |
|:-:|---|:---:|---|---|---|---|
| 1 | 로그인 | Mock | `ui_overlay` | (Phase 1 ★1 catalog 무) | `ebs_ui\ebs-console\` 인증 화면 디자인 | Mock 인증 화면 1개 |
| 2 | 카드덱 등록 | Real | `ebs(HW)` + `ebs(FW)` + `ui_overlay` | **MW-005** (RFID 연결 상태 12대), **SYS-004** (카드 인식 12대) | 없음 — 전부 신규 | 52장 UID→Suit/Rank 매핑 절차 + 등록 GUI |
| 3 | 게임 초기 설정 | Mock | `ui_overlay` | **MW-001** (게임 선택), **MW-002** (시작/종료) | `ebs_ui\ebs-action-tracker\` AT 8 mockup | 홀덤 하드코딩 + Mock 플레이어 6명 등록 |
| 4 | RFID 입력 | Real | `ebs(HW)` + `ebs(FW)` | **SYS-004** 실제 동작 | `BS-06-01-holdem-lifecycle.md` ASSIGNED→DEALT 전이 | ST25R3911B Serial UART → host bridge |
| 5 | 오버레이 출력 | Real | `ui_overlay` | **G1-004** (홀카드), **G1-006** (보드) | Riv 자산 없음 | Riv 1종 + Flutter rive 런타임 통합 |

### Phase 1 KPI (PRD §성공 지표 (KPI), line 1041-1048)

| 지표 | Phase 1 목표 | 측정 방법 |
|---|---|---|
| RFID 인식률 | ≥ 99.5% | 테스트 세션 |
| 카드 → 화면 지연 | < 200ms | E2E 측정 |
| 연속 운영 | ≥ 4시간 | 무중단 테스트 |

### Phase 1 완료 정의

PRD §5-Phase 로드맵 (line 985) "RFID 52장 → 서버 → 오버레이 연결 성공" — 위 5단계 시나리오 E2E 한 번 통과.

---

## 3. Phase 2 (2026 H2) — Hold'em 1종 완벽 완성 → 2027-01 런칭

Phase 2의 캐노니컬 범위는 `EBS-Feature-Catalog.md` "Phase 2 필수" 컬럼이다. 이 문서는 _재구현하지 않고_ Phase 2 필수 ID를 sibling 레포 트랙으로 분할한다.

### 3.1 Phase 2 ★2 IDs by Sibling

**`ui_overlay` (Console + Lobby + CC + 오버레이)**:

| 트랙 | Catalog IDs | BS 참조 |
|---|---|---|
| Main Window | MW-001~004, 006, 008~010 | BS-02-lobby (이미 채움) |
| Outputs | OUT-001~003, 005~009 | BS-03-settings (TBD) |
| GFX1 게임 제어 | G1-001~015 | `BS-06-01~08-holdem-*` (이미 채움) |
| GFX2 통계 | G2-001~009 | BS-07-overlay (TBD) |
| GFX3 방송 연출 | G3-001~002 | BS-07-overlay (TBD) |
| System | SYS-002~003, 006~010 | BS-03-settings (TBD) |
| Skin Editor | SK-001~005 | BS-03-settings (TBD) |

**`ebs(HW)` + `ebs(FW)`**:

| 트랙 | Catalog IDs | BS 참조 |
|---|---|---|
| Game Engine Board | GEB-001~008 | BS-04-rfid (TBD) |
| Game Engine Player | GEP-001~008 | BS-04-rfid (TBD) |

> **합계**: Phase 2 ★2 catalog 72개 중 Hold'em 1종에 필요한 부분만 우선 구현. 22종 확장은 Phase 3.

### 3.2 Phase 2 KPI (PRD line 1041-1048)

| 지표 | Phase 2 목표 |
|---|---|
| RFID 인식률 | ≥ 99.9% |
| 카드 → 화면 지연 | < 100ms |
| 연속 운영 | ≥ 12시간 |
| PokerGFX 복제율 | ≥ 90% |

### 3.3 Phase 2 완료 정의

PRD line 986: "Hold'em 1종 8시간 연속 방송 가능" + 2027-01 프로덕션 런칭.

---

## 4. 행동 명세 보강 작업 (이 레포에서 진행)

`contracts/specs/README.md` "작성 우선순위" 표 + sibling 레포 작업과 병렬 가능. 빈 디렉터리만 나열:

| 우선 | 디렉터리 | 현재 | 필요 | 활용 자산 |
|:---:|---|:---:|---|---|
| 1 | `BS-01-auth/` | 비어있음 | 로그인/세션/RBAC 경우의 수 | `CLAUDE.md` RBAC 정의 |
| 2 | `BS-04-rfid/` | 비어있음 | 52장 스캔, 카드 감지, 에러 복구 | PRD §15 워크플로우 (line 1118+) |
| 3 | `BS-05-command-center/` | 비어있음 | 8개 액션 버튼 경우의 수, Undo | `ebs_ui\ebs-action-tracker\` AT 44기능 + 8 mockup |
| 4 | `BS-07-overlay/` | 비어있음 | 10개 요소 트리거/갱신/애니메이션 | `docs/07-archive/01-pokergfx-analysis/` element catalog |
| 5 | `BS-03-settings/` | 비어있음 | 4섹션 (Output/Overlay/Game/Statistics) | `ebs_ui\ebs-console\` v9.7.0 |

> **이미 채움**: `BS-02-lobby/BS-02-lobby.md`, `team3-engine/specs/engine-spec/BS-06-01~08-holdem-*.md` — 작업 불필요.

---

## 5. 수정/생성 대상 파일

**신규 (이 PR)**:
- `docs/05-plans/ebs-implementation-roadmap.plan.md` ← 이 파일 1개

**후속 PR (이 레포 내 — Section 4 보강)**:
- `contracts/specs/BS-01-auth/BS-01-auth.md`
- `contracts/specs/BS-04-rfid/BS-04-rfid.md`
- `contracts/specs/BS-05-command-center/BS-05-command-center.md`
- `contracts/specs/BS-07-overlay/BS-07-overlay.md`
- `contracts/specs/BS-03-settings/BS-03-settings.md` (필요 시)

**후속 작업 (sibling 레포 — 이 레포 외부)**:
- `ebs(HW)`, `ebs(FW)`, `ui_overlay` 각각의 Phase 1 5단계 항목 (Section 2 표)
- 각 sibling 레포에 본 plan을 링크하는 README 또는 ROADMAP 항목 추가

**금지 (이 레포에서 절대 생성 금지)**:
- `src/backend/`, `src/app/`, `src/firmware/`, `src/overlay/` — 기획 레포 원칙 위배
- `docs/backlog.md`, `docs/milestones/` — 컨벤션 부재 (`docs/05-plans/*.plan.md`만 사용)
- `B-EBS-###` 신규 ID — `EBS-Feature-Catalog.md` 캐노니컬 IDs (MW/OUT/G1/G2/G3/SYS/SK/GEB/GEP) 재사용

---

## 6. 검증 (E2E)

### 이 PR 자체 검증

1. `git status` → 추가된 파일 1개 (`docs/05-plans/ebs-implementation-roadmap.plan.md`)
2. 인용된 모든 캐노니컬 ID(MW-/OUT-/G1-/G2-/G3-/SYS-/SK-/GEB-/GEP-)는 `docs/01-strategy/EBS-Feature-Catalog.md`에 존재
3. PRD 인용 line 번호(1002-1011, 985-1048, 1118+)는 `docs/01-strategy/PRD-EBS_Foundation.md` v41.0.0과 일치
4. Sibling 레포 이름(`ebs (HW)`, `ebs (FW)`, `ui_overlay`)은 `EBS-Kickoff-2026.md` line 121-135 다이어그램과 일치
5. BS 디렉터리 상태(빈/채움 구분)는 실제 파일 시스템과 일치

### 장기 검증 (이 PR 범위 외)

Phase 1 POC 5단계 시나리오 E2E 데모 (PRD line 1002 표 기준) — sibling 레포 코드가 채워진 후.

---

## 7. 실행 순서

1. **즉시**: 이 plan 파일 머지 (단일 PR)
2. **1주 내**: Section 4의 빈 BS 디렉터리 4~5개를 별도 PR로 채움 (각각 작은 PR)
3. **병행**: Section 2 5개 행 각각에 대해 해당 sibling 레포에 tracking issue 개설 (각 issue는 이 plan + 캐노니컬 ID 인용)
4. **Phase 2 진입 시**: Section 3.1 ★2 IDs를 sibling 레포 별로 분배하여 별도 plan 파일 생성 (예: `docs/05-plans/ebs-phase2-holdem.plan.md`)

> **원칙**: 이 문서는 _브릿지_ 다. 구현 트래킹은 sibling 레포 issue/PR이 담당하고, 이 문서는 PRD 변경에 따라 갱신된다.

---

## 8. 설계 문서 패키지 인벤토리 (2026-04-08 완성)

이 기획 레포에서 완성된 설계 문서 전체 목록. sibling 구현 레포는 이 문서들만으로 코드를 작성한다.

### 행동 명세 (`contracts/specs/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| BS-00 정의서 | 1 | 용어·상태·트리거·FSM·Mock 모드 — 모든 문서의 기반 |
| BS-01 Auth | 1 | 로그인·세션·RBAC·JWT 인증 |
| BS-02 Lobby | 1 | 5계층 네비게이션, Lobby-CC 1:N 관계, 124개 필드, Mock RFID 경로 |
| BS-03 Settings | 5 | Output/Overlay/Game/Statistics 4섹션 |
| BS-04 RFID | 5 | 덱 등록, 카드 감지, **수동 입력(일급 경로)**, HAL 계약 |
| BS-05 Command Center | 7 | 8개 액션 버튼, 좌석 관리, Undo, 키보드 단축키 |
| BS-06 Game Engine | 2 + 17 | 트리거 경계 + engine-spec(Hold'em+Flop+Draw+Stud) |
| BS-07 Overlay | 5 | 10개 요소, Rive 애니메이션, 스킨, 씬 JSON |

### Back Office (`team2-backend/specs/back-office/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| BO-01~11 | 12 | 3-앱 관계도, CRUD, 데이터 동기화, WSOP LIVE 연동, 감사 로그, 리포팅 |

### API 계약 (`contracts/api/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| API-01~06 | 7 | 백엔드 66개 엔드포인트, WSOP LIVE 연동, **RFID HAL 인터페이스(Mock 정본)**, Overlay 출력, WebSocket, Auth |

### 데이터 모델 (`contracts/data/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| DATA-01~06 | 7 | ER 다이어그램, 20개 엔티티, 5개 FSM, DB 스키마, 마이그레이션, 시드 데이터 |

### 기술 구현 (`team2-backend/specs/impl/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| IMPL-01~09 | 10 | 기술 스택, 5레포 구조, 상태 관리, 라우팅, DI, 에러, 로깅, 테스트, 빌드 |

### 테스트 설계 (`team4-cc/specs/testing/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| TEST-01~05 | 6 | 테스트 피라미드, E2E 10개 시나리오, 게임 엔진 32개 fixture, Mock 데이터, QA 56항목 |

### UI 설계 (`docs/03-ui-design/`)

| 문서 | 파일 수 | 핵심 내용 |
|------|:------:|----------|
| UI-00~05 | 7 | 디자인 시스템, Lobby/CC/Settings/Overlay 와이어프레임, 컴포넌트 라이브러리 |

**총계: 74개 신규 문서**
