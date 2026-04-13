# CCR Inbox — 팀 → Conductor 제안 경로

## 목적

팀이 `contracts/` (API/Data/Specs) 변경을 제안하는 유일한 경로입니다.
Hook(`pre_tool_guard.check_team_scope`)이 팀의 `contracts/` 직접 수정을 차단하므로,
변경이 필요하면 이 폴더에 **자기 팀 prefix의 CCR 초안 파일**을 작성해야 합니다.

## CCR 파일 저장 위치 (CRITICAL)

모든 CCR 라이프사이클 파일은 `docs/05-plans/ccr-inbox/` **하위**에 존재합니다. `docs/05-plans/` 루트에는 계획 파일(`*.plan.md`, `PLAN-*.md`)만 존재하며 CCR 관련 파일은 없습니다.

| 단계 | 위치 | 파일명 | 설명 |
|------|------|--------|------|
| **1. Draft (작성 중)** | `ccr-inbox/` | `CCR-DRAFT-{team\|conductor}-{YYYYMMDD}[-slug].md` | 팀이 제안 초안을 작성 |
| **2. Promoted (처리 중)** | `ccr-inbox/promoting/` | `CCR-{NNN}-{slug}.md` | promoter가 번호 할당 후 생성. Conductor가 `contracts/` 실제 수정 중 또는 완료. 체크리스트 보유. |
| **3. Archived (완료된 원본)** | `ccr-inbox/archived/` | `CCR-DRAFT-*.md` | promoter가 자동 이동. 이후 read-only. |

**혼동 방지**: `promoting/CCR-{NNN}-*.md` 파일 내부에 `## 원본 Draft` 섹션이 있고 그 안에 `# CCR-DRAFT: ...` 제목이 보일 수 있습니다. 이것은 **승격본이 추적성을 위해 원본 draft를 임베드한 사본**이며, draft의 실제 저장 위치가 아닙니다. 편집 금지.

**배타 규칙**:
- `docs/05-plans/` 루트에 `CCR-*.md`가 존재하면 **규칙 위반** — `ccr-inbox/` 하위로 이동해야 합니다.
- 승격본(`CCR-{NNN}-*.md`)은 **오직** `ccr-inbox/promoting/`에만 존재합니다.
- Draft(`CCR-DRAFT-*.md`)는 **오직** `ccr-inbox/` 루트(작성 중) 또는 `ccr-inbox/archived/`(완료)에만 존재합니다.

## 워크플로우

**v3 이후 (2026-04-10)**: 모든 draft를 먼저 일괄 읽고 배치 계획을 세운 뒤 그룹 단위로 실행한다. 여기서 **"실행"은 실제 `contracts/` 프로젝트 문서를 draft 의도에 맞게 Read/Edit/Write 수정**하는 것을 뜻한다. `ccr_promote.py --complete` CLI 호출은 편집이 끝난 draft를 마감하는 **후속 절차**일 뿐이다.

**v4 Fast-Track (2026-04-12)**: 리스크 등급에 따라 처리 경로가 분기됩니다.
- **LOW**: publisher 팀이 직접 `contracts/` 반영 가능 (자동 검증 + 영향팀 1명 approve)
- **MEDIUM**: 영향팀 전원 approve 후 publisher 팀이 직접 반영
- **HIGH**: 기존 v3 Conductor 배치 처리 (Phase A-E)
- 리스크 판정: `python tools/ccr_validate_risk.py --draft <파일명>`
- 분류 정책: `contracts/ccr-risk-matrix.md`

```
team2-backend/ 세션
  ↓ /auto "API-05에 hand_evaluated 이벤트 추가"
  ↓ hook이 contracts/api/API-05.md 직접 수정 차단
  ↓ LLM이 아래 경로에 draft 작성:

docs/05-plans/ccr-inbox/CCR-DRAFT-team2-20260410-hand-evaluated.md
  ↓ 필수 필드(제안팀, 영향팀 [team4], 변경 대상, 변경 유형, 변경 근거) 기재

conductor 세션 — "ccr promote" 자연어 입력
  ↓
  ↓ [Phase A] Collection — 일괄 읽기
  ↓   python tools/ccr_promote.py --validate-only   (전체 inbox JSON)
  ↓   유효 draft 일괄 Read. 토큰 초과 시 chunking:
  ↓     · 1차 (강제): target_files 교집합 draft는 같은 chunk
  ↓     · 2차: 같은 도메인 파일끼리 묶음
  ↓     · 3차: 독립 draft는 잔여 예산에 채움
  ↓
  ↓ [Phase B] Planning — 배치 계획
  ↓   target_files 교집합 기준 그룹핑
  ↓   그룹당 target contract 1회 Read
  ↓   Merge 플랜: Intent 추출 + 충돌 검사
  ↓               + 병합 순서(add → modify → rename → remove)
  ↓               + Idempotency 판정(의도 단위)
  ↓   불확실성 플래그: 충돌/모호/Spec Gap → needs-clarification
  ↓
  ↓ [Phase C] Execution — 실제 contracts/ 프로젝트 문서 수정
  ↓   그룹별로 draft 의도 통합 → 1회 Edit 적용
  ↓     · Diff 초안 복붙 금지, 기존 섹션 컨벤션에 맞춰 재구성
  ↓     · 같은 target에 복수 draft → 순차 재Read 금지, 1회 통합
  ↓     · 대상 파일 부재 시 sibling 스타일로 Write 신규 생성
  ↓   편집이 끝난 draft만 마감:
  ↓     python tools/ccr_promote.py --complete <draft> --number N \
  ↓       --applied-files "contracts/api/API-05-websocket-events.md"
  ↓       → promoting/CCR-N-hand-evaluated.md 로그 생성
  ↓       → backlog/team4.md 에 NOTIFY-CCR-N append (중복 방지)
  ↓       → draft → archived/ 이동
  ↓
  ↓ [Phase D] Clarification — 플래그된 그룹만
  ↓   AskUserQuestion 으로 구조화된 선택지 제시
  ↓   응답 후 해당 그룹만 재실행. 임의 판정 금지.
  ↓
  ↓ [Phase E] Finalize
  ↓   python tools/backlog_aggregate.py
  ↓   사용자 리포트 + commit 승인 요청
  ↓   git add contracts/ docs/ && git commit -m "[CCR-NNN..MMM] ..."
```

## Draft 파일명 규칙

```
CCR-DRAFT-{proposer}-{YYYYMMDD}[-{slug}].md
```

- `proposer`: 제안 주체. `team1`, `team2`, `team3`, `team4`, 또는 `conductor`.
  - 팀(team1~team4): hook이 해당 팀 prefix만 쓰기 허용. 다른 팀 draft 생성 금지.
  - `conductor`: Conductor 세션에서 직접 작성하는 CCR 초안. 팀 경계 이동, 다팀 영향 구조적 변경, CCR 프로세스 자체 개선 등 팀이 단독으로 낼 수 없는 제안용.
- `YYYYMMDD`: 작성일.
- `slug`: **영문 kebab-case만 허용** (소문자 a-z, 숫자 0-9, 하이픈). 선택.
  - 한글/공백/특수문자/대문자 금지.
  - 정규식: `[a-z0-9][a-z0-9-]*`
  - `ccr_promote.py`가 승격 시 이 slug을 `CCR-{NNN}-{slug}.md` 승격본 파일명에 **그대로 재사용**한다.
  - slug이 없거나 영문 규칙에 맞지 않으면 `slugify(title)` 폴백 (title에서 한글 제거 후 생성).

**예시 (정상)**:
- `CCR-DRAFT-team2-20260410-hand-evaluated.md`
- `CCR-DRAFT-team4-20260410-overlay-equity.md`
- `CCR-DRAFT-team1-20260410-tech-stack-ssot.md`

**예시 (금지)**:
- `CCR-DRAFT-team2-20260410-한글슬러그.md` — 한글 금지
- `CCR-DRAFT-team2-20260410-Upper-Case.md` — 대문자 금지
- `CCR-DRAFT-team2-20260410-slug with space.md` — 공백 금지

> **왜 영문만?**: 승격본 파일 경로(`docs/05-plans/CCR-NNN-*.md`)가 URL·grep·CLI 도구에서 안정적으로 동작하도록. 기존 CCR-001~019 중 일부는 과거 규칙(한글 허용)으로 생성되어 혼재하지만, 2026-04-10부터는 영문 only.

**예시**:
- `CCR-DRAFT-team2-20260410.md`
- `CCR-DRAFT-team2-20260410-hand-evaluated.md`
- `CCR-DRAFT-team4-20260410-overlay-equity.md`

## Draft 템플릿 (필수 필드)

```markdown
# CCR-DRAFT: {한 줄 제목}

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team4]                  ← 필수. 빈 배열 금지.
- **변경 대상 파일**: contracts/api/API-05-websocket.md
- **변경 유형**: add | modify | remove | rename
- **변경 근거**: Overlay equity 실시간 표시 요구사항 (B-XXX)
- **리스크 등급**: LOW | MEDIUM | HIGH     ← 선택. `tools/ccr_validate_risk.py`로 자동 판정 가능.
- **조언 기한**: 2026-04-15               ← 선택 (Phase 2). 기한 내 NACK 없으면 자동 승인.

## 변경 요약

WS `cc_event` 채널에 `hand_evaluated` 이벤트 추가.

## Diff 초안

```diff
 ## Events
 
 ### cc_event (channel)
+- **hand_evaluated**
+  - Trigger: Flop/Turn/River 후 엔진이 equity 계산 완료 시
+  - Payload: `{ table_id, hand_id, street, equities: [{player_id, equity_pct}] }`
+  - Consumer: team4 Command Center → Overlay
```

## 영향 분석

- **Team 4**: Overlay Equity Bar 컴포넌트 신설 필요. 약 4시간.
- **Team 2**: 브로드캐스트 로직 추가, Redis pub/sub 키 `cc:hand_evaluated`.
- **마이그레이션**: 없음 (신규 이벤트이므로 기존 소비자 영향 0).

## 대안 검토

1. **REST 폴링**: 지연 발생, 탈락.
2. **SSE**: 단방향만 가능, WS로 통합 채택.

## 검증 방법

- 단위: Team 4 overlay에 mock 이벤트 주입 → 0.5초 내 렌더링.
- 통합: Engine → Backend → WS → CC → Overlay 전체 플로우.

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토
- [ ] Team 4 기술 검토
```

## 필수 필드 검증 (`ccr_promote.py` 거부 규칙)

| 필드 | 검증 | 누락 시 |
|------|------|---------|
| `제안팀` | `teamN` 형식 | 거부 |
| `제안일` | `YYYY-MM-DD` 형식 | 거부 |
| `영향팀` | `[teamN, ...]` 형식, **빈 배열 금지** | 거부 |
| `변경 대상 파일` | `contracts/**` 경로 | 거부 |
| `변경 유형` | add/modify/remove/rename 중 하나 | 거부 |
| `변경 근거` | 1줄 이상 | 거부 |
| `리스크 등급` | LOW/MEDIUM/HIGH | 자동 판정 (누락 허용) |
| `조언 기한` | YYYY-MM-DD | 기본값 3영업일 (누락 허용) |

## 금지 사항

- 다른 팀 prefix의 draft 파일 작성 금지 (hook이 차단).
- 영향팀 필드를 `[]` 빈 배열로 기재 금지 (promote 거부).
- 직접 `contracts/` 파일 수정 금지 (hook이 차단).
- `CCR-001-*.md` 같은 승격된 파일에 팀이 수정 금지 (hook이 차단).

## Conductor 작업 (v3 — 배치 계획)

**실행 주체**: Claude Code 세션의 Conductor LLM. 사용자가 "ccr promote" 자연어 입력 → Claude가 아래 절차 수행.

**용어 정의**: "작업 실행" = **실제 `contracts/` 프로젝트 문서를 draft 의도에 맞게 Read/Edit/Write 수정**. `--complete` 호출은 편집 완료 후의 **마감 절차**일 뿐이며, 편집 없이 마감만 호출하는 것은 금지된다.

```bash
# 1. [Phase A] 일괄 검증 — JSON 출력 (base_number + 전체 drafts 배열)
python tools/ccr_promote.py --validate-only
# 출력 예:
# {
#   "inbox": "docs/05-plans/ccr-inbox",
#   "total": 28,
#   "valid": 28,
#   "invalid": 0,
#   "base_number": 1,
#   "drafts": [
#     {"draft": "...", "number": 1, "valid": true, "target_files": [...], ...},
#     ...
#   ]
# }

# 2. [LLM 수행] Phase A — draft 일괄 Read
#    유효 draft들을 가능한 한 한 번에 Read.
#    토큰 예산 초과 시 chunking:
#      · 1차 (강제): target_files 교집합 draft는 같은 chunk에 강제로 묶음
#      · 2차: 같은 도메인 파일끼리 (API-*, BS-01-* 등)
#      · 3차: 독립 draft는 번호순으로 잔여 예산에 채움

# 3. [LLM 수행] Phase B — 그룹핑 + 플랜 수립
#    · target_files 교집합 기준으로 그룹화
#    · 각 그룹의 target contract 1회 Read (N개 draft여도 1번만)
#    · Merge 플랜: Intent 추출 + 충돌 검사
#                   + 병합 순서 (add → modify → rename → remove)
#                   + Idempotency 판정 (의도 단위)
#    · 불확실성 플래그: 충돌/모호/Spec Gap → Phase D로 분기

# 4. [LLM 수행] Phase C — 실제 contracts/ 파일 수정 (본체 작업)
#    그룹별로 draft 의도를 반영한 1회 통합 Edit을 target 파일에 적용.
#    · Diff 초안 복붙 금지, 기존 섹션 컨벤션에 맞춰 재구성
#    · 같은 target에 복수 draft → 순차 재Read 금지, 1회 통합 Edit
#    · 대상 파일 부재 시 sibling 스타일로 Write 신규 생성
#    이 단계가 끝난 시점에 그룹의 contracts/ 파일은 draft 의도대로
#    실제 수정 완료된 상태여야 한다.

# 5. 편집이 끝난 draft만 마감 (draft별 호출, 그룹 내 병렬 가능)
python tools/ccr_promote.py --complete CCR-DRAFT-team2-20260410-jwt-expiry.md \
    --number 6 \
    --applied-files "contracts/specs/BS-01-auth/BS-01-auth.md,contracts/api/API-06-auth-session.md"
#    또는 이미 반영된 경우 (편집 없이 로그만):
python tools/ccr_promote.py --complete CCR-DRAFT-team2-20260410-jwt-expiry.md \
    --number 6 --skipped

# 6. [선택] Phase D — 플래그된 그룹만 사용자 문의
#    AskUserQuestion 으로 구조화된 선택지 제시 → 응답 후 해당 그룹만 재실행.
#    임의 판정 절대 금지.

# 7. [Phase E] 집계 갱신 + commit 승인
python tools/backlog_aggregate.py
# 사용자 리포트 후:
git add contracts/ docs/ && git commit -m "[CCR-NNN..MMM] ..."
```

**주의**:
- `python tools/ccr_promote.py` (인자 없이) 는 **deprecated**. 실행하면 경고 출력 후 종료.
- 실제 contracts/ 편집은 LLM이 Read/Edit/Write 도구로 수행. Python 스크립트는 검증(JSON)과 마감(로그·NOTIFY·archive)만.
- `--skipped` 플래그: 이전 세션에서 이미 반영되었거나 재처리 대상이 아닌 경우 로그만 남기고 편집 없이 마감.
- **Chunking 기준은 `target_files` 교집합이 1차**. 같은 파일을 건드리는 draft는 반드시 한 chunk + 한 그룹에 함께 넣는다 (순서 의존성을 chunk 경계 밖으로 밀어내면 v2의 재Read 누적 문제가 재발함).
- **편집 없이 `--complete` 만 호출 금지**. 의도적 skip은 반드시 `--skipped` 플래그로 명시.

## 참고

- 정책 SSOT: `contracts/team-policy.json`
- Hook: `C:/claude/.claude/hooks/pre_tool_guard.py` → `check_team_scope`
- 집계: `tools/backlog_aggregate.py`
