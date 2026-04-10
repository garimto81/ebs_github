# EBS Conductor CLAUDE.md — 5팀 구조 (Team 0)

## Role

Team 0 — Conductor. 최상위 오케스트레이션, 계약 관리, 통합 테스트 소유.

**이 파일은 Conductor 세션용입니다.** 팀별 개발은 각 `team*/CLAUDE.md`를 따릅니다.

---

## 소유 경로

| 경로 | 내용 | 역할 |
|------|------|------|
| `contracts/` | API/Data/Spec 계약 | 단독 소유 — 팀 수정 금지 |
| `integration-tests/` | HTTP 기반 통합 테스트 | 팀 간 API 계약 검증 |
| `docs/01-strategy/` | Foundation PRD | 전략 문서 |
| `docs/00-reference/` | WSOP 분석, Production Plan | 참고 자료 |
| `docs/05-plans/` | 로드맵, 이행 계획, CCR | 계획 문서 |
| `docs/06-reports/` | 완료 보고서 | 현황 추적 |
| `docs/07-archive/` | PokerGFX 분석, legacy | 아카이빙 |
| `docs/mockups/`, `docs/images/` | 공유 그래픽 자산 | 모든 팀 참조 |
| `docs/backlog.md` | 글로벌 백로그 | 크로스팀 항목 (teams: 태그) |
| `tools/` | Python 유틸 스크립트 | 운영 도구 |

---

## 팀 레지스트리

| 팀 | 폴더 | 기술 | 소유 API |
|----|------|------|----------|
| **Team 1** | `team1-frontend/` | React 19+Vite 6+Zustand | consumes API-01,05,06 |
| **Team 2** | `team2-backend/` | FastAPI+SQLite/PostgreSQL | implements API-01,02,05,06 |
| **Team 3** | `team3-engine/` | Pure Dart | publishes API-04 OutputEvent |
| **Team 4** | `team4-cc/` | Flutter/Dart+Rive | implements API-03,05; consumes API-04 |

---

## 계약 관리 (CCR 프로세스)

### 계약 변경 필요 시

1. **CCR 문서 작성** → `docs/05-plans/CCR-{NNN}-{제목}.md`
   ```markdown
   # CCR-001: API-05 WebSocket 새 이벤트 추가
   
   - **영향팀**: Team 2 (서버), Team 4 (CC)
   - **변경 내용**: `cc_event` 채널에 `hand_evaluated` 이벤트 추가
   - **이유**: Overlay 실시간 equity 표시 필요
   ```

2. **Conductor 검토** → 영향팀 통보
3. **영향팀 승인** → Conductor가 계약 수정
4. **Edit History 업데이트** → commit: `[CCR-NNN]`

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

**마지막 업데이트**: 2026-04-10 (v4.0.0 — 전체 생태계 통합 완료)
