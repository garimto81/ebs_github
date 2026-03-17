# /auto REFERENCE - Phase 전환 상세 워크플로우 (v25.0 — OOP Coupling/Cohesion)

> **동기화 안내**: SKILL.md는 판단 로직과 흐름만 기술. 코드 블록(Task/SendMessage 패턴)과 Gate 조건 상세는 이 파일이 Primary Source입니다.
> **v24.0**: Plugin Fusion — 5개 플러그인 자동 활성화 + superpowers 17 스킬 흡수 + Iron Laws 3개 전 Phase 주입. 상세: `references/plugin-fusion-rules.md`
> **v23.0**: Phase 0→4 재구성 (DESIGN→PLAN 통합, Code Review→BUILD 통합). SKILL.md 468→299줄 경량화.
> **v22.3**: PRD-First 워크플로우 추가. **v22.1**: Agent Teams 단일 패턴. Skill() 호출 0개.

### Phase 매핑 (v22.4 → v23.0)

| v22.4 | v23.0 | 변경 |
|-------|-------|------|
| Phase 0 (INIT) | Phase 0 (INIT) | 유지 |
| Phase 0.5 (PRD) | Phase 1, Step 1.1 (PRD) | PLAN에 통합 |
| Phase 1 (PLAN) | Phase 1, Steps 1.2-1.3 | PLAN에 통합 |
| Phase 2 (DESIGN) | Phase 1, Step 1.4 | PLAN에 통합 |
| Phase 3 (DO) | Phase 2 (BUILD) | Code Review 내장 |
| Phase 4 (CHECK) | Phase 3 (VERIFY) | — |
| Phase 5 (ACT) | Phase 4 (CLOSE) | — |

---

## Contract Definitions (v25.0)

Phase 간 자료 결합도(1단계)를 보장하기 위한 표준 Contract JSON 스키마.

### InitContract (Phase 0 → Phase 1)
```json
{
  "feature": "string",
  "mode": "LIGHT | STANDARD | HEAVY",
  "complexity_score": "number (0-6)",
  "plugins": ["string[]"],
  "iron_laws": ["TDD", "Debugging", "Verification"],
  "options": { "skip_prd": false, "skip_analysis": false, "eco": null },
  "team_name": "string"
}
```

### PlanContract (Phase 1 → Phase 2)
```json
{
  "prd_path": "string",
  "plan_path": "string",
  "requirements": [{ "id": "R1", "description": "string", "priority": "MUST|SHOULD|COULD" }],
  "affected_files": ["string[]"],
  "acceptance_criteria": ["string[]"],
  "oop_scorecard": {
    "coupling_pass": true,
    "cohesion_pass": true,
    "srp_pass": true,
    "dip_pass": true,
    "isp_pass": true
  }
}
```

### BuildContract (Phase 2 → Phase 3)
```json
{
  "changed_files": ["string[]"],
  "test_results": "PASS | FAIL",
  "build_status": "PASS | FAIL",
  "lint_status": "PASS | FAIL",
  "gap_match_rate": "number (0-100)",
  "review_verdict": "APPROVE | REVISE",
  "oop_score": {
    "avg_coupling": "number",
    "max_coupling": "number",
    "avg_cohesion": "number",
    "worst_cohesion": "number",
    "srp_violations": "number",
    "dip_violations": "number",
    "circular_deps": "number"
  }
}
```

### VerifyContract (Phase 3 → Phase 4)
```json
{
  "qa_cycles": "number",
  "qa_final_status": "PASS | FAIL",
  "e2e_status": "PASS | FAIL | SKIPPED",
  "architect_final_verdict": "APPROVE | REJECT",
  "unresolved_issues": ["string[]"]
}
```

### ContextProvider 패턴 (의존성 주입)

Lead가 Plugin/Iron Laws를 에이전트 prompt에 직접 삽입하는 대신, `{context_injection}` 플레이스홀더를 사용합니다:

```
# 에이전트 prompt 템플릿에서:
prompt="... {context_injection} ..."

# Lead가 주입 시:
context_injection = build_context(mode, plugins, iron_laws)
# → Iron Laws + Plugin rules + Vercel BP 등을 일괄 생성
```

에이전트 prompt 템플릿 변경 없이, ContextProvider 빌드 로직만 수정하면 주입 내용 변경 가능.

---

## 출력 토큰 초과 방지 프로토콜 (v22.4)

> 상세 규칙: `.claude/rules/12-large-document-protocol.md`

### PRD/Plan 문서 작성 시 청킹 강제 규칙

**prd-writer, design-writer, reporter** 에이전트 호출 시 prompt에 반드시 포함:

```
대형 문서 작성 프로토콜 (MANDATORY):
1. 문서 규모 예측 후 300줄+ → 스켈레톤-퍼스트 패턴 사용
2. Write(헤더/목차만) → Edit(섹션별 순차 추가)
3. 단일 Write로 전체 문서 생성 금지
4. 토큰 초과 시 → Continuation Loop (max 3회, 중단점부터 재개)
5. 타임아웃 발생 시 → 전체 재생성 금지, 미완료 섹션만 재시도
```

### Mermaid 다이어그램 작성 규칙

**prd-writer, planner, reporter** 에이전트가 저장 파일(.md)에 Mermaid 다이어그램을 포함할 때 prompt에 반드시 포함:

```
Mermaid 다이어그램 규칙 (MANDATORY):
1. 한 레벨(같은 깊이) 노드 최대 4개. 5개+ 시 subgraph 또는 2단 재배치로 분할
2. 리프 노드 총합 ≤ 6. 7~8개 → 분할 또는 LR 전환 필수. 9개+ → Overview+Detail 분할 필수
3. 노드 레이블: 한글 8자/영문 15자 이내. 초과 시 <br/>로 2줄 분할 (3줄 금지)
4. 노드 레이블 줄바꿈: \n 금지 → <br/> 사용 필수
5. 노드 6개+ 또는 subgraph 포함 시 단계적 빌드업 (Stage별 1~2개 추가)
6. %%{init}%% 설정은 GitHub에서 무시됨 — 가독성 문제는 분할로 해결
7. 상세: .claude/rules/11-ascii-diagram.md 참조
```

### 에이전트 타임아웃 처리 (Phase 1, 2, 4)

문서 생성 에이전트(prd-writer, design-writer, reporter)가 5분+ 무응답 시:

```
[금지] Lead가 직접 전체 문서 생성 시도 → 동일한 토큰 초과 유발
[금지] 전체 문서 재생성 Fallback

[올바른 처리]
1. 완료된 파일 부분 확인 (Read 도구)
2. 미완료 섹션 목록 파악
3. 새 에이전트를 미완료 섹션만 담당하도록 spawn
4. Circuit Breaker: 동일 실패 3회 → 사용자 알림 + 수동 판단 요청
```

---

## 에이전트 Fallback 매핑 (커스텀 에이전트 미인식 시)

`.claude/agents/` 커스텀 에이전트가 로드되지 않을 때 빌트인 에이전트로 대체한다.
`Agent type '{name}' not found` 에러 발생 시 아래 매핑으로 즉시 재시도 **(HARD RULE — 사용자 질문 없이 자동 적용)**:

### Fallback 적용 (HARD RULE)

"Agent type not found" 에러 발생 시:
1. 즉시 아래 매핑으로 재호출 (사용자 질문 없이 자동)
2. Tier 1 → 플러그인 빌트인 대체 시도
3. Tier 1 실패 → Tier 2 general-purpose + model 오버라이드
4. Tier 2도 실패 시 에러 보고 후 중단

```
Agent(subagent_type="executor-high", ...) → 에러 발생
  └─ "Agent type not found" 감지
  └─ 아래 매핑에서 대체 에이전트 선택
  └─ Agent(subagent_type="general-purpose", model="opus", ...) 재호출
  └─ prompt 첫 줄에 역할 명시 추가
```

### Tier 1: 플러그인 빌트인 대체 (모델 제어 가능)

| 커스텀 에이전트 | Fallback | model 오버라이드 | 비고 |
|----------------|----------|:----------------:|------|
| architect | feature-dev:code-architect | — | READ-ONLY prompt 명시 |
| critic | feature-dev:code-reviewer | — | Adversarial 검토 |
| code-reviewer | superpowers:code-reviewer | — | 코드 리뷰 |
| explore | Explore | — | 코드 탐색 |
| planner | Plan | — | 계획 수립 |

### Tier 2: general-purpose 대체 (model 파라미터 필수)

| 커스텀 에이전트 | model 오버라이드 | prompt 첫 줄 역할 명시 |
|----------------|:----------------:|----------------------|
| executor-high | `model="opus"` | `역할: Complex multi-file task executor. 모든 도구 사용 가능.` |
| executor | `model="sonnet"` | `역할: Focused task executor for implementation work.` |
| executor-low | `model="haiku"` | `역할: Simple single-file task executor.` |
| designer-high | `model="sonnet"` | `역할: Complex UI architecture and design systems.` |
| designer | `model="sonnet"` | `역할: UI/UX Designer-Developer. 스타일링 + 코드 생성.` |
| designer-low | `model="haiku"` | `역할: Simple styling and minor UI tweaks.` |
| qa-tester-high | `model="sonnet"` | `역할: Comprehensive production-ready QA testing.` |
| qa-tester | `model="sonnet"` | `역할: QA Runner. 6종 검증 (lint, type, unit, integration, build, security).` |
| writer | `model="haiku"` | `역할: Technical documentation writer.` |
| gap-detector | `model="haiku"` | `역할: 설계-구현 Gap 정량 분석기. Match Rate 계산.` |
| build-fixer | `model="sonnet"` | `역할: Build/TypeScript error fixer. 최소 diff로 빌드 수정.` |
| build-fixer-low | `model="haiku"` | `역할: Simple build error fixer. 단순 타입 에러 수정.` |
| researcher | `model="sonnet"` | `역할: External documentation & reference researcher.` |
| researcher-low | `model="haiku"` | `역할: Quick documentation lookups.` |
| analyst | `model="haiku"` | `역할: Pre-planning consultant for requirements analysis.` |
| architect-low | `model="haiku"` | `역할: Quick code questions & simple lookups.` |
| architect-medium | `model="sonnet"` | `역할: Architecture & Debugging Advisor - Medium complexity.` |
| code-reviewer-low | `model="haiku"` | `역할: Quick code quality checker.` |
| explore-high | `model="sonnet"` | `역할: Complex architectural search for deep system understanding.` |
| explore-medium | `model="haiku"` | `역할: Thorough codebase search with reasoning.` |
| scientist-high | `model="opus"` | `역할: Complex research, hypothesis testing, and ML specialist.` |
| scientist | `model="sonnet"` | `역할: Data analysis and research execution specialist.` |
| scientist-low | `model="haiku"` | `역할: Quick data inspection and simple statistics.` |
| security-reviewer | `model="sonnet"` | `역할: Security vulnerability detection specialist (OWASP Top 10).` |
| security-reviewer-low | `model="haiku"` | `역할: Quick security scan specialist.` |
| tdd-guide | `model="sonnet"` | `역할: TDD specialist enforcing Red-Green-Refactor methodology.` |
| tdd-guide-low | `model="haiku"` | `역할: Quick test suggestion specialist.` |
| vision | `model="haiku"` | `역할: Visual/media file analyzer for images, PDFs, and diagrams.` |
| frontend-dev | `model="sonnet"` | `역할: 프론트엔드 개발 및 UI/UX. React/Next.js 성능 최적화.` |
| ai-engineer | `model="sonnet"` | `역할: LLM 애플리케이션, RAG 시스템, 프롬프트 엔지니어링 전문가.` |
| catalog-engineer | `model="haiku"` | `역할: WSOPTV 카탈로그 및 제목 생성 전문가 (Block F/G).` |
| cloud-architect | `model="opus"` | `역할: 클라우드 인프라, 네트워크, 비용 최적화 전문가.` |
| claude-expert | `model="haiku"` | `역할: Claude Code, MCP, 에이전트, 프롬프트 엔지니어링 전문가.` |
| data-specialist | `model="sonnet"` | `역할: 데이터 분석, 엔지니어링, ML 파이프라인 전문가.` |
| database-specialist | `model="sonnet"` | `역할: DB 설계, 최적화, Supabase 전문가.` |
| devops-engineer | `model="sonnet"` | `역할: DevOps 전문가 (CI/CD, K8s, Terraform, 트러블슈팅).` |
| github-engineer | `model="sonnet"` | `역할: GitHub 및 Git 워크플로우 전문가.` |

### Fallback 사용 시 필수사항

1. **model 오버라이드 필수** (Tier 2): `Agent(subagent_type="general-purpose", model="opus", ...)` — 원래 에이전트의 모델 티어 유지
2. **prompt 역할 명시**: prompt 첫 줄에 `역할: {원래 에이전트 설명}` 추가
3. **READ-ONLY 에이전트**(architect): prompt에 `파일 수정 절대 금지. Read/Grep/Glob만 허용.` 명시
4. **Phase 4 보고서 기록**: Fallback 사용 에이전트와 원인을 보고서에 기록
5. **Lead 직접 실행 금지**: Fallback이 있더라도 Lead가 직접 구현하지 않음 (CLAUDE.md 규칙 3)

---

## Agent Teams 운영 규칙 (v21.0)

**모든 에이전트 호출은 Agent Teams in-process 방식을 사용합니다. Skill() 호출 0개.**

**모델 결정**: 에이전트 정의 파일(`.claude/agents/*.md`)의 `model:` 필드가 기본 모델을 결정합니다. Agent() 호출 시 선택적으로 `model` 파라미터(`"sonnet"`, `"opus"`, `"haiku"`)를 명시하여 오버라이드 가능합니다. Fallback(general-purpose) 시 `model` 명시 필수.
- Opus 티어: executor-high, architect, planner, critic, scientist-high (복잡한 구현/판단/계획/연구)
- Sonnet 티어: executor, code-reviewer, qa-tester, designer (반복 실행)
- Haiku 티어: explore, explore-medium, writer, analyst, vision, gap-detector, catalog-engineer, claude-expert (탐색/간단 문서/체크리스트)
- 복잡도에 따라 적절한 subagent_type을 선택하여 모델 티어를 제어합니다.

### 팀 라이프사이클

1. **Phase 0**: `TeamCreate(team_name="pdca-{feature}")` — PDCA 시작 시 1회
2. **Phase 1-4**: `Agent(subagent_type="에이전트", name="역할", description="설명", team_name="pdca-{feature}")` → `SendMessage` → 완료 대기 → `shutdown_request`
3. **Phase 4**: 보고서 생성 후 Safe Cleanup (아래 절차)

### Phase 4 Safe Cleanup 절차 (v22.2)

**정상 종료 (5단계):**
1. writer teammate 완료 확인 (Mailbox 수신)
2. 모든 활성 teammate에 `SendMessage(type="shutdown_request")` 순차 전송
3. 각 teammate 응답 대기 (최대 5초). 무응답 시 다음 단계로 진행 (**차단 금지**)
4. `TeamDelete()` 실행
5. TeamDelete 실패 시 수동 fallback (⚠️ `rm -rf`는 tool_validator 차단 → Python 필수):
   ```bash
   python -c "import shutil,pathlib; [shutil.rmtree(pathlib.Path.home()/'.claude'/d/'pdca-{feature}', ignore_errors=True) for d in ['teams','tasks']]"
   ```

**세션 비정상 종료 후 복구:**
- 고아 팀 감지: `ls ~/.claude/teams/` — `pdca-*` 디렉토리가 남아있으면 고아 팀
- 복구 순서: `TeamDelete()` 시도 → 실패 시 Python 수동 정리
- 고아 task 정리 (UUID 형식만):
  ```bash
  python -c "import shutil,pathlib,re; [shutil.rmtree(p,ignore_errors=True) for p in pathlib.Path.home().joinpath('.claude','tasks').iterdir() if p.is_dir() and re.match(r'^[0-9a-f-]{36}$',p.name)]"
  ```
- stale todo 정리:
  ```bash
  python -c "import pathlib,time; [p.unlink() for p in pathlib.Path.home().joinpath('.claude','todos').glob('*.json') if time.time()-p.stat().st_mtime > 86400]"
  ```

**Context Compaction 후 팀 소실 시:**
- 증상: `TeamDelete()` 호출 시 "team not found" 에러
- 처리: 에러 무시하고 수동 정리 실행
- 원인: Issue #23620 — compaction 후 `~/.claude/teams/{name}/config.json` 미재주입

**VS Code 환경 (isTTY=false) 무한 대기 방지:**
- `settings.json`의 `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 확인 (in-process 모드)
- teammate 무응답 시 5초 후 강제 진행 (shutdown_request 응답 불필요)

### Teammate 운영 규칙

1. **Spawn 시 role name 명시**: `name="doc-analyst"`, `name="verifier"` 등 역할 명확히
2. **Task 할당**: `TaskCreate` → `SendMessage`로 teammate에게 작업 전달
3. **완료 대기**: Mailbox 자동 수신 (Lead가 polling 불필요)
4. **순차 작업**: 이전 teammate `shutdown_request` 완료 후 다음 teammate spawn
5. **병렬 작업**: 독립 작업은 동시 spawn 가능 (Phase 1.0 분석 등)

### Context 분리 장점 (vs 기존 단일 context)

| 기존 단일 context | Agent Teams |
|--------------|-------------|
| 결과가 Lead context에 합류 → overflow | Mailbox로 전달 → Lead context 보호 |
| foreground 3개 상한 필요 | 제한 없음 (독립 context) |
| "5줄 요약" 강제 | 불필요 |
| compact 실패 위험 | compact 실패 없음 |

---

## 세션 강제 종료 (`/auto stop`) + Lead 타임아웃 패턴

### 🚨 Nuclear Option — Ctrl+C도 안 될 때 (외부 터미널 긴급 종료)

> **이 상황**: Claude Code 자체가 frozen. Ctrl+C 무효. `/auto stop` 입력 불가.
> **원인**: Node.js 이벤트 루프가 teammate IPC await 상태에서 블락. SIGINT 큐에만 쌓이고 처리 불가.
> **해결**: **별도** PowerShell/CMD 창에서 외부 스크립트 실행.

```
┌─────────────────────────────────────────────────────┐
│  Claude Code가 frozen?                               │
│                                                      │
│  Step 1: 새 PowerShell 창 열기 (Win+X → Terminal)    │
│                                                      │
│  Step 2: 긴급 종료 스크립트 실행                       │
│  > python C:\claude\.claude\scripts\emergency_stop.py│
│                                                      │
│  또는 즉시 전체 종료 (확인 없이):                      │
│  > python C:\claude\.claude\scripts\emergency_stop.py│
│    --force                                           │
│                                                      │
│  Step 3: Claude Code 재시작                           │
│  > claude                                            │
└─────────────────────────────────────────────────────┘
```

**emergency_stop.py 실행 순서:**
1. `~/.claude/teams/` + `~/.claude/tasks/` 고아 항목 전체 삭제
2. `~/.claude/todos/` stale TODO 초기화
3. `node.exe` (Claude Code) PID 탐색 → `taskkill /F /PID` 강제 종료

**왜 Ctrl+C가 무효인가?**
- Claude Code(Node.js)는 teammate 완료 메시지를 `await`로 기다림
- 이벤트 루프가 `await` 상태에서 IPC 소켓 read()를 OS 레벨로 대기
- Windows CTRL_C_EVENT → Node.js SIGINT 핸들러 → 이벤트 루프가 처리해야 하는데
  이벤트 루프 자체가 블락 → SIGINT 핸들러가 실행될 기회가 없음
- 결과: Ctrl+C가 눌려도 프로세스 상태 변화 없음

**수동 긴급 종료 (스크립트 없을 때):**
```powershell
# 새 PowerShell 창에서:

# 1) Claude Code PID 확인
wmic process where "name='node.exe'" get processid,commandline

# 2) 해당 PID 강제 종료
taskkill /F /PID <확인된_PID>

# 3) 고아 팀 Python 정리
python -c "import shutil,pathlib; home=pathlib.Path.home(); [shutil.rmtree(p,ignore_errors=True) for d in ['teams','tasks'] for p in (home/'.claude'/d).iterdir() if p.is_dir()]"
```

---

### `/auto stop` — 즉시 실행 절차 (5단계)

> **전제**: Claude가 아직 명령을 받을 수 있는 상태일 때.
> Claude 자체가 frozen이면 위의 **Nuclear Option** 사용.

Agent Teams hang 또는 강제 중단 필요 시 **순서대로** 실행:

**Step 1: Shutdown Request 전송**
```
SendMessage(type="shutdown_request", recipient="{teammate-name}", content="강제 중단")
# 모든 활성 teammate에 순차 전송 → 최대 5초 대기 → 무응답 시 Step 2 진행
```

**Step 2: TeamDelete 시도**
```
TeamDelete()
# 성공 → 종료
# "Cannot cleanup team with N active member(s)" 에러 → Step 3 진행
# "team not found" 에러 → 이미 삭제됨, 정상 종료
```

**Step 3: Python shutil.rmtree() 강제 삭제**

> ⚠️ `rm -rf ~/.claude/teams/...`는 `tool_validator.py`에 의해 **차단**됨. 반드시 Python 사용.

```bash
python -c "import shutil,pathlib; [shutil.rmtree(pathlib.Path.home()/'.claude'/d/'pdca-{feature}', ignore_errors=True) for d in ['teams','tasks']]"
```

**Step 4: TeamDelete 재시도**
```
TeamDelete()  # shutil 삭제 후 재시도. "team not found"도 정상.
```

**Step 5: 잔여 리소스 확인**
```bash
# 팀/태스크 디렉토리 잔존 여부 확인
ls ~/.claude/teams/ | grep pdca
ls ~/.claude/tasks/ | grep pdca
```

---

### Lead 타임아웃 패턴 (Hang 방지)

**문제**: Lead가 teammate 완료 메시지를 무한 대기 → hang 발생

**해결**: 모든 `Agent()` 호출 시 `description` 필수 설정. Heartbeat 타임아웃으로 teammate 자동 종료.

```
# ❌ hang 위험 — description 누락
Agent(subagent_type="executor-high", name="impl-manager", team_name="pdca-{feature}", prompt="...")

# ✅ 올바른 패턴 (description 필수)
Agent(subagent_type="executor-high", name="impl-manager", description="4조건 자체 루프 구현 관리", team_name="pdca-{feature}", prompt="...")
# → Heartbeat 타임아웃으로 teammate 자동 종료, Lead 다음 단계 진행 가능
```

**에이전트별 모델 티어:**

| 에이전트 역할 | subagent_type | 모델 (agent 정의) |
|-------------|---------------|------------------|
| explore (탐색) | explore | haiku |
| code-reviewer, qa-tester | code-reviewer / qa-tester | sonnet |
| executor (단일 구현) | executor | sonnet |
| critic, architect (검증) | critic / architect | opus |
| planner (계획) | planner | opus |
| executor-high (복잡 구현) | executor-high | opus |
| impl-manager (4조건 루프) | executor-high | opus |

**5분 Heartbeat Timeout:**
- Claude Code 내장 메커니즘 — teammate가 5분+ tool call 없으면 자동 비활성화
- Agent 호출의 유일한 자동 종료 메커니즘

**Hang 발생 시 즉시 확인:**
```
1. ~/.claude/teams/ 에 pdca-* 디렉토리 잔존 여부
2. ~/.claude/tasks/ 에 관련 디렉토리 잔존 여부
3. Agent() 호출에 description 설정 여부
4. teammate에 완료 메시지 도달 여부
```

---

## Worktree 통합 (`--worktree` 옵션)

### Step 0.1: Worktree 설정 (Phase 0, TeamCreate 직후)

`--worktree` 옵션 지정 시 Phase 0에서 팀 생성 직후 실행:

```bash
# 1. worktree 생성
git worktree add "C:/claude/wt/{feature}" -b "feat/{feature}" main

# 2. .claude junction 생성
cmd /c "mklink /J \"C:\\claude\\wt\\{feature}\\.claude\" \"C:\\claude\\.claude\""

# 3. 검증
git worktree list
ls "C:/claude/wt/{feature}/.claude/commands"
```

성공 확인 후 이후 Phase의 모든 파일 경로에 worktree prefix 적용:
- `docs/01-plan/` → `C:\claude\wt\{feature}\docs\01-plan\`
- 구현 파일 → `C:\claude\wt\{feature}\` 하위

### Teammate Prompt 패턴 (`--worktree` 시)

모든 teammate prompt에 경로 prefix 주입:

```
# 기존
prompt="docs/01-plan/{feature}.plan.md를 참조하여 설계 문서를 작성하세요."

# --worktree 시
prompt="모든 파일은 C:\\claude\\wt\\{feature}\\ 하위에서 작업하세요.
       C:\\claude\\wt\\{feature}\\docs\\01-plan\\{feature}.plan.md를 참조하여 설계 문서를 작성하세요."
```

### Phase 4 Worktree Cleanup (TeamDelete 직전)

`--worktree` 옵션 시 Phase 4 보고서 생성 완료 후, TeamDelete 직전 실행:

```bash
# 1. junction 제거
cmd /c "rmdir \"C:\\claude\\wt\\{feature}\\.claude\""

# 2. worktree 제거
git worktree remove "C:/claude/wt/{feature}"

# 3. 정리
git worktree prune
```

### Agent Teams 병렬 격리 (HEAVY 모드)

HEAVY(4-6점) 시 teammate별 별도 worktree로 완전 격리:

```bash
# Phase 2 병렬 구현 시
git worktree add "C:/claude/wt/{feature}-impl" "feat/{feature}"
git worktree add "C:/claude/wt/{feature}-test" "feat/{feature}"
cmd /c "mklink /J \"C:\\claude\\wt\\{feature}-impl\\.claude\" \"C:\\claude\\.claude\""
cmd /c "mklink /J \"C:\\claude\\wt\\{feature}-test\\.claude\" \"C:\\claude\\.claude\""
```

```
Agent(subagent_type="executor-high", name="impl", description="구현 실행", team_name="pdca-{feature}", prompt="C:\\claude\\wt\\{feature}-impl\\ 경로에서 구현. 다른 경로 수정 금지.")
Agent(subagent_type="executor-high", name="tester", description="테스트 작성", team_name="pdca-{feature}", prompt="C:\\claude\\wt\\{feature}-test\\ 경로에서 테스트 작성. 다른 경로 수정 금지.")
```

cleanup 시 모든 sub-worktree도 함께 제거.

---

## Phase 0→4 PDCA 전체 흐름

```
  Phase 0        Phase 1           Phase 2            Phase 3          Phase 4
  INIT    ──→    PLAN       ──→    BUILD       ──→    VERIFY    ──→    CLOSE
  옵션 파싱       PRD 생성         구현 실행           QA 사이클        보고서
  팀 생성         사전 분석         코드 리뷰           E2E 검증         팀 정리
  복잡도 판단     계획+설계 수립    Architect Gate      최종 판정         커밋
```

---

## Phase 1, Step 1.1: PRD (요구사항 문서화 — 구현 전 필수)

> **CRITICAL**: 요구사항 요청 시 반드시 PRD 문서를 먼저 생성/수정한 후 구현을 진행합니다.
> **목적**: 사용자 요구사항을 공식 문서화하여 구현 범위를 명확히 하고, 이후 Phase에서 PRD를 기준으로 검증합니다.
> **스킵 조건**: `--skip-prd` 옵션 명시 시 스킵 가능.

### Step 1.1.1: 기존 PRD 탐색

```
# docs/00-prd/ 디렉토리에서 기존 PRD 탐색
existing_prd = Glob("docs/00-prd/{feature}*.prd.md")

# 관련 PRD가 없으면 docs/00-prd/ 전체 탐색하여 연관 문서 확인
if not existing_prd:
    all_prds = Glob("docs/00-prd/*.prd.md")
    # 유사 이름이나 관련 주제의 PRD가 있으면 참조 대상으로 표시
```

### Step 1.1.2: PRD 생성 또는 수정

**신규 PRD 생성 (기존 PRD 없음):**
```
Agent(subagent_type="executor-high", name="prd-writer", description="PRD 문서 작성", team_name="pdca-{feature}",
     prompt="[Phase 1 PRD 생성] 사용자 요구사항을 PRD 문서로 작성하세요.

     === 사용자 요청 ===
     {user_request}

     === 기존 관련 PRD 요약 ===
     {existing_prds_summary}  (없으면 '없음')

     === PRD 템플릿 (필수 섹션) ===

     # {feature} PRD

     ## 0. Market Context (선택)
     - 시장 배경 / 고객 페인포인트
     - 비즈니스 Impact 범위
     - Target Segment / Volume
     - Appetite: {Small 2주 | Big 6주} (이 기능에 투자할 시간 예산)

     ## 1. 배경 및 목적
     - 왜 이 기능/변경이 필요한지
     - 해결하려는 문제

     ## 2. 요구사항
     ### 2.1 기능 요구사항 (Functional Requirements)
     - FR-001: {요구사항 1}
     - FR-002: {요구사항 2}
     (각 요구사항에 번호 부여, 검증 가능한 수준으로 구체적 기술)

     ### 2.2 비기능 요구사항 (Non-Functional Requirements)
     - NFR-001: 성능, 보안, 접근성 등 해당 사항

     ## 3. 기능 범위 (Scope)
     ### 3.1 포함 (In Scope)
     - 이번에 구현할 항목
     ### 3.2 제외 (Out of Scope)
     - 이번에 구현하지 않을 항목

     ## 4. 제약사항 (Constraints)
     - 기술적 제약, 일정 제약, 의존성

     ## 5. 우선순위 (Priority)
     | 요구사항 | 우선순위 | 근거 |
     |---------|---------|------|
     | FR-001  | P0 필수 | ... |
     | FR-002  | P1 권장 | ... |

     ## 6. 수용 기준 (Acceptance Criteria)
     - AC-001: {검증 가능한 수용 기준}
     - AC-002: ...

     ## Changelog
     | 날짜 | 변경 내용 | 작성자 |
     |------|---------|--------|
     | {오늘 날짜} | 초기 작성 | auto |

     === 출력 ===
     파일 경로: docs/00-prd/{feature}.prd.md
     디렉토리가 없으면 생성하세요.")
SendMessage(type="message", recipient="prd-writer", content="PRD 문서 작성 시작.")
# 완료 대기 → shutdown_request
```

**기존 PRD 수정 (PRD 존재 시):**
```
Agent(subagent_type="executor-high", name="prd-writer", description="PRD 문서 작성", team_name="pdca-{feature}",
     prompt="[Phase 1 PRD 수정] 기존 PRD를 새 요구사항에 맞게 수정하세요.

     === 기존 PRD 파일 ===
     docs/00-prd/{existing_prd_file}

     === 추가/변경 요구사항 ===
     {user_request}

     === 수정 규칙 ===
     1. 기존 요구사항(FR-xxx)은 보존하되, 변경된 항목은 명시적으로 표시
     2. 새 요구사항은 기존 번호 체계에 이어서 추가 (FR-003, FR-004 ...)
     3. 삭제된 요구사항은 ~~취소선~~ 처리 (이력 보존)
     4. ## Changelog 섹션에 변경 이력 추가
     5. 범위(Scope) 섹션도 요구사항 변경에 맞게 갱신
     6. 수용 기준(Acceptance Criteria)도 요구사항 변경에 맞게 갱신")
SendMessage(type="message", recipient="prd-writer", content="PRD 수정 시작.")
# 완료 대기 → shutdown_request
```

### Step 1.1.3: 사용자 승인 (MANDATORY)

```
# PRD 내용을 사용자에게 제시
prd_content = Read("docs/00-prd/{feature}.prd.md")

# 사용자에게 PRD 요약 출력
print("=== PRD 작성 완료 ===")
print("파일: docs/00-prd/{feature}.prd.md")
print("요구사항 {N}건, 수용 기준 {M}건")
print("========================")

# AskUserQuestion으로 승인 요청
AskUserQuestion:
  question: "PRD 문서를 확인해주세요. 진행 방식을 선택하세요."
  options:
    - "승인 (Phase 1 PLAN 진입)"
    - "수정 요청 (PRD 수정 후 재확인)"
    - "직접 수정 (사용자가 PRD 파일 직접 편집)"

# 승인 → Phase 1 진입
# 수정 요청 → 사용자 피드백 반영 후 Step 1.1.2 재실행 (max 3회)
# 직접 수정 → 사용자가 파일 편집 완료 후 Phase 1 진입
# 3회 수정 초과 → 현재 PRD로 Phase 1 진입 + 경고 출력
```

### PRD→Phase 1 Gate

PRD 승인 후 Phase 1 진입 전 최소 검증:

| # | 검증 항목 | 확인 방법 |
|:-:|----------|----------|
| 1 | PRD 파일 존재 | `docs/00-prd/{feature}.prd.md` 존재 |
| 2 | 요구사항 1건 이상 | `FR-` 패턴 1개 이상 존재 |
| 3 | 수용 기준 1건 이상 | `AC-` 패턴 1개 이상 존재 |

미충족 시: PRD 보완 후 재검증 (1회). 2회 실패 → Phase 1 진입 허용 (경고 포함).

### PRD와 이후 Phase 연계

| Phase | PRD 활용 |
|-------|---------|
| Phase 1 PLAN | Planner가 PRD 참조하여 계획 수립 |
| Phase 1 DESIGN | Design 문서에 PRD 요구사항 번호 매핑 |
| Phase 2 BUILD | impl-manager가 PRD 요구사항 기반 구현 |
| Phase 3 VERIFY | Architect가 PRD 수용 기준 기반 검증 |
| Phase 4 CLOSE | 보고서에 PRD 대비 달성률 포함 |

---

## Phase 1, Steps 1.2-1.3: PLAN (사전 분석 → 복잡도 판단 → 계획 수립)

### Step 1.0: 사전 분석 (병렬 Teammates)

```
# 병렬 spawn (독립 작업)
Agent(subagent_type="explore", name="doc-analyst", description="문서 탐색 분석", team_name="pdca-{feature}", prompt="docs/, .claude/ 내 관련 문서 탐색. 중복 범위 감지 필수. 결과를 5줄 이내로 요약.")

Agent(subagent_type="explore", name="issue-analyst", description="이슈 탐색 분석", team_name="pdca-{feature}", prompt="gh issue list 실행하여 유사 이슈 탐색. 연관 이슈 태깅 필요. 결과를 5줄 이내로 요약.")

# [Intent Inference] analyst(sonnet) — 사용자 의도 심층 분석
Agent(subagent_type="analyst", name="intent-analyst", description="사용자 의도 심층 분석", team_name="pdca-{feature}",
     prompt="[Phase 1 Intent Analysis] 사용자 요청의 의도를 심층 분석하세요.
             사용자 요청: {user_request}
             분석 항목:
             1. 명시적 요구사항 — 사용자가 직접 말한 것
             2. 암묵적 요구사항 — 당연히 기대하지만 말하지 않은 것
             3. 배경 맥락 — 왜 이 요청을 했는지 동기 추론
             4. 범위 경계 — 포함/제외 판단 (과잉 구현 방지)
             5. 위험 시나리오 2건+ — 잘못 해석하면 발생할 문제
             6. Planner 핵심 지시 (3줄 이내) — 계획 수립 시 반드시 반영할 사항
             코드베이스를 Glob/Grep으로 탐색하여 기술적 맥락을 파악한 뒤 분석하세요.")

# Mailbox로 결과 수신 후 모든 teammate shutdown_request
SendMessage(type="shutdown_request", recipient="doc-analyst")
SendMessage(type="shutdown_request", recipient="issue-analyst")
SendMessage(type="shutdown_request", recipient="intent-analyst")
```

**산출물**: 문서 중복 여부, 연관 이슈 번호, Intent Analysis (Phase 1.3에 사용)

### Step 1.1: 복잡도 점수 판단 (MANDATORY - 6점 만점)

| # | 조건 | 1점 기준 | 0점 기준 |
|:-:|------|---------|---------|
| 1 | **파일 범위** | 3개 이상 파일 수정 예상 | 1-2개 파일 |
| 2 | **아키텍처** | 새 패턴/구조 도입 | 기존 패턴 내 수정 |
| 3 | **의존성** | 새 라이브러리/서비스 추가 | 기존 의존성만 사용 |
| 4 | **모듈 영향** | 2개 이상 모듈/패키지 영향 | 단일 모듈 내 변경 |
| 5 | **사용자 명시** | `ralplan` 키워드 포함 | 키워드 없음 |
| 6 | **Appetite 선언** | "제대로/production-ready" 명시 | "빠르게/간단히/hotfix" 또는 미선언 |

**판단 로그 출력 (항상 필수):**
```
=== 복잡도 판단 ===
파일 범위: {0|1}점 ({근거})
아키텍처: {0|1}점 ({근거})
의존성:   {0|1}점 ({근거})
모듈 영향: {0|1}점 ({근거})
사용자 명시: {0|1}점
Appetite: {0|1}점 ({빠르게→0 | 제대로→1 | 미선언→0})
총점: {score}/6 -> {LIGHT|STANDARD|HEAVY}
===================
```

**복잡도 모드:**
- **0-1점**: LIGHT (간단, executor-high 단일)
- **2-3점**: STANDARD (보통, executor-high 루프)
- **4-6점**: HEAVY (복잡, Planner-Critic Loop)

### Step 1.1b: Plugin Activation Scan (Phase 0.4)

복잡도 판단 직후, 프로젝트 루트 파일 감지 + 복잡도 모드 기반으로 플러그인을 자동 활성화합니다.
상세 매핑 테이블: `references/plugin-fusion-rules.md`

```python
# Phase 0.4 — Lead가 직접 실행하는 플러그인 감지 로직
activated_plugins = []

# 1. Project Type Detection
if Glob("tsconfig.json"):
    activated_plugins.append("typescript-lsp")
if Glob("package.json"):
    pkg = Read("package.json")
    if '"react"' in pkg or '"next"' in pkg:
        activated_plugins.extend(["frontend-design", "code-review"])
    else:
        activated_plugins.append("code-review")
if Glob("next.config.*"):
    activated_plugins.append("frontend-design")
if Glob("pyproject.toml") or Glob("setup.py") or Glob("*.py"):
    activated_plugins.append("code-review")
if Glob(".claude/"):
    activated_plugins.extend(["claude-code-setup", "superpowers"])

# 2. Complexity-Tier Escalation
if mode in ["STANDARD", "HEAVY"]:
    activated_plugins.extend(["superpowers", "code-review"])
if mode == "HEAVY":
    activated_plugins.extend(["feature-dev", "claude-code-setup"])

# 3. Deduplicate
activated_plugins = list(set(activated_plugins))

# 4. Iron Laws 주입 (superpowers 활성 시)
iron_laws = ""
if "superpowers" in activated_plugins:
    iron_laws = Read("C:\\claude\\.claude\\references\\plugin-fusion-rules.md")
    # Section 8 Iron Laws를 impl-manager/QA/Gate prompt에 주입

# 5. 활성화 로그 출력 (항상 필수)
# === Plugin Activation ===
# 프로젝트 타입: {detected_types}
# 복잡도 모드: {mode}
# 활성 플러그인: {activated_plugins}
# Iron Laws: {TDD, Debugging, Verification}
# ===========================
```

**Iron Laws prompt 주입 (superpowers 흡수):**

impl-manager, QA Runner, Architect Gate prompt에 아래를 추가:

```
=== Iron Laws (MANDATORY) ===
1. TDD: 실패 테스트 없이 프로덕션 코드 작성 금지. 테스트 먼저 작성.
2. Debugging: Root cause 조사 없이 수정 금지. D0-D4 체계 준수.
3. Verification: 증거 없이 완료 선언 금지. 빌드/테스트/lint 결과 첨부 필수.
```

### Step 1.2: 계획 수립 (명시적 호출)

**LIGHT (0-1점): Planner sonnet teammate**
```
Agent(subagent_type="planner", name="planner", description="계획 수립", team_name="pdca-{feature}", prompt="... (복잡도: LIGHT {score}/6, 단일 파일 수정 예상).
     PRD 참조: docs/00-prd/{feature}.prd.md (있으면 반드시 기반으로 계획 수립).
     PRD의 요구사항 번호(FR-xxx)를 Plan 항목에 매핑하세요.
     사용자 확인/인터뷰 단계를 건너뛰세요. 바로 계획 문서를 작성하세요.
     === Intent Analysis (Step 1.0 산출물) ===
             {intent_analysis_result}
             위 분석의 암묵적 요구사항과 범위 경계를 계획에 반영하세요.
     === Mermaid 다이어그램 규칙 ===
             한 레벨 노드 최대 4개 (5개+ 시 subgraph 분할). 줄바꿈: <br/> 사용 (\n 금지). 노드 6개+ 시 단계적 빌드업.
     docs/01-plan/{feature}.plan.md 생성.")
SendMessage(type="message", recipient="planner", content="계획 수립 시작. 완료 후 TaskUpdate로 completed 처리.")
# 완료 대기 → shutdown_request
```

**STANDARD (2-3점): Planner opus teammate**
```
Agent(subagent_type="planner", name="planner", description="계획 수립", team_name="pdca-{feature}", prompt="... (복잡도: STANDARD {score}/6, 판단 근거 포함).
     PRD 참조: docs/00-prd/{feature}.prd.md (있으면 반드시 기반으로 계획 수립).
     PRD의 요구사항 번호(FR-xxx)를 Plan 항목에 매핑하세요.
     사용자 확인/인터뷰 단계를 건너뛰세요. 바로 계획 문서를 작성하세요.
     === Intent Analysis (Step 1.0 산출물) ===
             {intent_analysis_result}
             위 분석의 암묵적 요구사항과 범위 경계를 계획에 반영하세요.
     === Mermaid 다이어그램 규칙 ===
             한 레벨 노드 최대 4개 (5개+ 시 subgraph 분할). 줄바꿈: <br/> 사용 (\n 금지). 노드 6개+ 시 단계적 빌드업.
     docs/01-plan/{feature}.plan.md 생성.")
SendMessage(type="message", recipient="planner", content="계획 수립 시작. 완료 후 TaskUpdate로 completed 처리.")
# 완료 대기 → shutdown_request
```

**HEAVY (4-6점): Planner-Critic Loop (max 5 iterations)**

```
critic_feedback = ""      # Lead 메모리에서 관리
iteration_count = 0

Loop (max 5 iterations):
  iteration_count += 1

  # Step A: Planner Teammate
  Agent(subagent_type="planner", name="planner-{iteration_count}", description="계획 수립 반복",
       team_name="pdca-{feature}",
       prompt="[Phase 1 HEAVY] 계획 수립 (Iteration {iteration_count}/5).
               작업: {user_request}
               이전 Critic 피드백: {critic_feedback}
               계획 문서 작성 후 사용자 확인 단계를 건너뛰세요.
               Critic teammate가 reviewer 역할을 대신합니다.
               계획 완료 시 바로 '계획 작성 완료' 메시지를 전송하세요.
               필수 포함: 배경, 구현 범위, 영향 파일, 위험 요소.
               === Intent Analysis (Step 1.0 산출물) ===
               {intent_analysis_result}
               위 분석의 암묵적 요구사항과 범위 경계를 계획에 반영하세요.
               === Mermaid 다이어그램 규칙 ===
               한 레벨 노드 최대 4개 (5개+ 시 subgraph 분할). 줄바꿈: <br/> 사용 (\n 금지). 노드 6개+ 시 단계적 빌드업.
               출력: docs/01-plan/{feature}.plan.md")
  SendMessage(type="message", recipient="planner-{iteration_count}", content="계획 수립 시작.")
  # 결과 수신 대기 → shutdown_request

  # Step B: Architect Teammate
  Agent(subagent_type="architect", name="arch-{iteration_count}", description="기술적 타당성 검증",
       team_name="pdca-{feature}",
       prompt="[Phase 1 HEAVY] 기술적 타당성 검증.
               Plan 파일: docs/01-plan/{feature}.plan.md
               검증 항목: 1. 파일 경로 존재 여부 2. 의존성 충돌 3. 아키텍처 일관성 4. 성능/보안 우려
               소견을 5줄 이내로 요약하세요.")
  SendMessage(type="message", recipient="arch-{iteration_count}", content="타당성 검증 시작.")
  # 결과 수신 대기 → shutdown_request

  # Step C: Critic Teammate (Adversarial Weakness Analyzer)
  Agent(subagent_type="critic", name="critic-{iteration_count}", description="adversarial 약점 분석",
       team_name="pdca-{feature}",
       prompt="[Phase 1 HEAVY] Adversarial Plan 공격 (Iteration {iteration_count}/5).
               Plan 파일: docs/01-plan/{feature}.plan.md
               Architect 소견: {architect_feedback}
               이전 iteration 약점 수정 이력: {previous_weakness_fixes}
               당신은 adversarial 분석자입니다. 이 문서의 약점, 결함, 모순, 누락만 찾으세요.
               === 6가지 공격 벡터 ===
               A1 논리적 결함: 빠진 단계, 근거 없는 가정, 순환 논리
               A2 실패 시나리오: 외부 의존성 실패, 해피패스 붕괴, 미처리 엣지 케이스
               A3 모호성: '적절히','필요 시','가능하면','등' 등 모호어, 측정 불가 기준
               A4 내부 모순: 섹션 간 불일치, 기존 아키텍처 충돌, 목표-범위 불일치
               A5 누락 컨텍스트: 미존재 파일 참조, 미언급 의존성, 미고려 이해관계자
               A6 과잉 설계: 요구사항에 없는 기능/추상화, 조기 최적화, 범위 확장
               A7 OOP 설계 위반: 제어 결합도(3+), God Module(응집도 6-7), 순환 의존성, DIP 위반, 공통 결합도
               모든 벡터에서 공격하세요. 약점마다 문제-위치-영향을 명시하세요.
               이해할 수 없거나 도메인 지식이 부족한 부분은 QUESTION으로 표시하세요.
               반드시 첫 줄에 VERDICT: DESTROYED, VERDICT: QUESTION, 또는 VERDICT: SURVIVED를 출력하세요.
               SURVIVED는 Critical 0건 + Major 0건일 때만. 첫 iteration에서 SURVIVED는 거의 불가능합니다.")
  SendMessage(type="message", recipient="critic-{iteration_count}", content="Plan 공격 시작.")
  # 결과 수신 대기 → shutdown_request

  # Step D: Lead 판정
  critic_message = Mailbox에서 수신한 critic 메시지
  first_line = critic_message의 첫 줄

  if "VERDICT: SURVIVED" in first_line:
      → Loop 종료, Phase 2 진입
  elif "VERDICT: QUESTION" in first_line:
      → Loop 즉시 중단
      → critic_message에서 질문 목록 추출
      → AskUserQuestion으로 사용자에게 질문 전달
      → 사용자 답변을 다음 iteration의 previous_weakness_fixes에 주입
      → 다음 iteration 재개
  elif "VERDICT: DESTROYED" in first_line:
      → critic_feedback = critic_message에서 VERDICT: 줄 이후 전체 (약점 목록)
      → 누적 피드백이 1,500t 초과 시 최신 2회분만 유지
        (이전: "Iteration {N}: {핵심 요약 1줄}" 형태로 압축)
      → Planner에게 critic_feedback 전달하여 문서 재설계
      → 다음 iteration
  else:
      → DESTROYED로 간주 (안전 기본값)

  if iteration_count >= 5 and not SURVIVED:
      → # 설계 자체에 근본적 문제가 있음 — 강제 통과 금지
      → 미해결 약점 요약 보고서 작성 (남은 Critical/Major 약점 전체 목록)
      → AskUserQuestion으로 사용자에게 보고:
        "Critic 5회 반복 후에도 다음 약점이 해결되지 않았습니다: {남은 약점 요약}.
         설계 자체에 근본적 문제가 있을 수 있습니다."
        옵션:
        1. "요구사항 재정의" → Phase 1 처음부터 재시작 (PRD 재검토)
        2. "미해결 약점 수용 후 진행" → Plan에 WARNING 섹션 추가 + Phase 2 진입
        3. "작업 중단" → wip 커밋 + TeamDelete + 세션 종료
```

**Critic 판정 파싱 규칙:**
- 판정 추출: Critic 메시지 첫 줄에서 `VERDICT: DESTROYED`, `VERDICT: QUESTION`, 또는 `VERDICT: SURVIVED` 키워드 확인
- 키워드 불일치: 첫 줄에 VERDICT 없으면 DESTROYED로 간주
- DESTROYED 시: `VERDICT:` 줄 이후 전체 약점 목록을 critic_feedback에 저장 → Planner에게 전달하여 문서 재설계
- QUESTION 시: Loop 즉시 중단 → 질문 목록 추출 → AskUserQuestion으로 사용자에게 전달 → 답변 후 다음 iteration 재개
- 피드백 1,500t 이하: 전체 누적 유지 / 초과: 최신 2회분 전문 + 이전은 1줄 압축 / 5회 초과: 사용자 보고 + 판단 요청 (강제 통과 금지)

**산출물**: `docs/01-plan/{feature}.plan.md`

### Step 1.2 LIGHT: Lead Quality Gate (v22.1 신규)

LIGHT(0-1점) 모드에서 Planner(sonnet) 완료 후 Lead가 직접 수행하는 최소 검증:

```
# Lead Quality Gate (에이전트 추가 비용: 0)
plan_content = Read("docs/01-plan/{feature}.plan.md")

# 조건 1: plan 파일 존재 + 내용 있음 (빈 파일 거부)
if not plan_content or len(plan_content.strip()) < 50:
    → Planner 1회 재요청 ("계획 내용이 부족합니다. 최소 배경, 구현 범위, 영향 파일을 포함하세요.")

# 조건 2: 파일 경로 1개 이상 언급
if no file path pattern (e.g., "src/", ".py", ".ts", ".md") found:
    → Planner 1회 재요청 ("구현 대상 파일 경로를 1개 이상 포함하세요.")

# 미충족 시 1회만 재요청. 2회째 실패 → 그대로 Phase 2 진입 (LIGHT이므로 과도한 차단 불필요)
```

### Step 1.2 STANDARD: Critic-Lite 단일 검토 (v22.1 신규)

STANDARD(2-3점) 모드에서 Planner(opus) 완료 후 Critic-Lite 1회 검토:

```
Agent(subagent_type="critic", name="critic-lite", description="Critic-Lite 단일 약점 공격", team_name="pdca-{feature}",
     prompt="[Phase 1 STANDARD Critic-Lite] Adversarial Plan 공격 (1회).
             Plan 파일: docs/01-plan/{feature}.plan.md

             당신은 adversarial 분석자입니다. 이 문서의 약점만 찾으세요.
             === 7가지 공격 벡터 ===
             A1 논리적 결함: 빠진 단계, 근거 없는 가정, 순환 논리
             A2 실패 시나리오: 외부 의존성 실패, 해피패스 붕괴, 미처리 엣지 케이스
             A3 모호성: '적절히','필요 시','가능하면','등' 등 모호어, 측정 불가 기준
             A4 내부 모순: 섹션 간 불일치, 기존 아키텍처 충돌, 목표-범위 불일치
             A5 누락 컨텍스트: 미존재 파일 참조, 미언급 의존성
             A6 과잉 설계: 요구사항에 없는 기능/추상화
             A7 OOP 설계 위반: 제어 결합도(3+), God Module(응집도 6-7), 순환 의존성, DIP 위반, 공통 결합도

             반드시 첫 줄에 VERDICT: DESTROYED, VERDICT: QUESTION, 또는 VERDICT: SURVIVED를 출력하세요.
             약점마다 문제-위치-영향을 명시하세요. 이해 불가 시 QUESTION으로 표시.
             SURVIVED는 Critical 0건 + Major 0건일 때만.")
SendMessage(type="message", recipient="critic-lite", content="Plan 공격 시작.")
# 완료 대기 → shutdown_request

# VERDICT 파싱
critic_message = Mailbox에서 수신한 critic-lite 메시지
if "VERDICT: SURVIVED" in first_line:
    → Phase 2 진입
elif "VERDICT: QUESTION" in first_line:
    → 질문 추출 → AskUserQuestion으로 사용자에게 전달 → 답변과 함께 Planner 1회 수정
    → 수정본 수용 (추가 Critic 검토 없음, 무한 루프 방지)
elif "VERDICT: DESTROYED" in first_line:
    → Planner 1회 수정 (critic_feedback = 약점 목록 전달)
    → 수정본 수용 (추가 Critic 검토 없음, 무한 루프 방지)
else:
    → DESTROYED로 간주
```

### Step 1.3: 이슈 연동 (GitHub Issue)

**Step 1.0에서 연관 이슈 발견 시**: `gh issue comment <issue-number> "관련 Plan: docs/01-plan/{feature}.plan.md"`

**신규 이슈 생성 필요 시**: `gh issue create --title "{feature}" --body "Plan: docs/01-plan/{feature}.plan.md" --label "auto"`

---

## Plan→Build Gate: Plan 검증 (MANDATORY)

| # | 필수 섹션 | 확인 방법 |
|:-:|----------|----------|
| 1 | 배경/문제 정의 | `## 배경` 또는 `## 문제 정의` 헤딩 존재 |
| 2 | 구현 범위 | `## 구현 범위` 또는 `## 범위` 헤딩 존재 |
| 3 | 예상 영향 파일 | 파일 경로 목록 포함 |
| 4 | 위험 요소 | `## 위험` 또는 `위험 요소` 헤딩 존재 |

**누락 시**: Plan 문서를 먼저 보완한 후 Phase 2로 진행.

---

## 복잡도 분기 상세 (Phase 1-4 실행 차이)

### LIGHT 모드 (0-1점)

| Phase/Step | 실행 |
|------------|------|
| 1.1 PRD | PRD 생성/수정 + 사용자 승인 (`--skip-prd`로 스킵 가능) |
| 1.2-1.3 PLAN | Explore teammates (haiku) x2 + Planner (sonnet) + Lead Quality Gate |
| 1.4 DESIGN | **스킵** (설계 문서 생성 없음) |
| 2.1 BUILD | Executor teammate (opus) 단일 실행 |
| 2.2-2.3 | — (Code Review, Architect Gate 없음) |
| 3.1 VERIFY | QA Runner 1회 |
| 3.2-3.3 | Architect 최종 검증 (E2E 스킵) |
| 4 CLOSE | sonnet 보고서 |

### STANDARD 모드 (2-3점)

| Phase/Step | 실행 |
|------------|------|
| 1.1 PRD | PRD 생성/수정 + 사용자 승인 (`--skip-prd`로 스킵 가능) |
| 1.2-1.3 PLAN | Explore teammates (haiku) x2 + Planner (opus) + Critic-Lite |
| 1.4 DESIGN | Executor teammate (opus) — 설계 문서 생성 |
| 2.1 BUILD | impl-manager teammate (opus) — 4조건 자체 루프 |
| 2.2-2.3 | Code Review + Architect Gate (외부 검증, max 2회 rejection) |
| 3.1 VERIFY | QA Runner 3회 + Architect 진단 + Domain-Smart Fix |
| 3.2 E2E | E2E 백그라운드 + Architect 최종 검증 |
| 3.3 E2E | E2E 실패 처리 (진단 + Domain-Smart Fix, max 2회) |
| 4 CLOSE | gap < 90% → executor teammate (최대 5회) |

### HEAVY 모드 (4-6점)

| Phase | 실행 |
|-------|------|
| Phase 1.1 | PRD 생성/수정 + 사용자 승인 (`--skip-prd`로 스킵 가능) |
| Phase 1.2-1.3 | Explore teammates (haiku) x2 + Planner-Critic Loop (max 5 iter, A1-A6 adversarial 공격) |
| Phase 1.4 | Executor-high teammate (opus) — 설계 문서 생성 |
| Phase 2.1 | impl-manager teammate (opus) — 4조건 자체 루프 + 병렬 가능 |
| Phase 2.2-2.3 | Code Review + Architect Gate (외부 검증, max 2회 rejection) |
| Phase 3.1 | QA Runner 5회 + Architect 진단 + Domain-Smart Fix |
| Phase 3.2 | E2E 백그라운드 + Architect 최종 검증 |
| Phase 3.3 | E2E 실패 처리 (진단 + Domain-Smart Fix, max 2회) |
| Phase 4 | gap < 90% → executor teammate (최대 5회) |

### 자동 승격 규칙 (Phase 중 복잡도 상향 조정)

| 승격 조건 | 결과 |
|----------|------|
| 빌드 실패 2회 이상 | LIGHT → STANDARD |
| QA 3사이클 초과 (STANDARD→HEAVY만) | STANDARD → HEAVY |
| 영향 파일 5개 이상 | LIGHT/STANDARD → HEAVY |
| Architect REJECT 2회 | 현재 모드 유지, Phase 3 진입 허용 (사용자 알림) |

---

## Phase 1, Step 1.4: DESIGN (설계 통합 — STANDARD/HEAVY만)

> **CRITICAL**: `architect`는 READ-ONLY (Write/Edit 도구 없음). 설계 문서 **생성**에는 executor 계열 사용 필수.

**LIGHT 모드: 스킵** (설계 문서 생성 없음, Phase 2에서 직접 구현)

**STANDARD 모드: Executor opus teammate**
```
Agent(subagent_type="executor-high", name="design-writer", description="설계 문서 작성", team_name="pdca-{feature}",
     prompt="docs/01-plan/{feature}.plan.md를 참조하여 설계 문서를 작성하세요.
     필수 포함: 구현 대상 파일 목록, 인터페이스 설계, 데이터 흐름, 테스트 전략.
     출력: docs/02-design/{feature}.design.md")
SendMessage(type="message", recipient="design-writer", content="설계 문서 생성 요청. 완료 후 TaskUpdate로 completed 처리.")
# 완료 대기 → shutdown_request
```

**HEAVY 모드: Executor-high opus teammate**
```
Agent(subagent_type="executor-high", name="design-writer", description="설계 문서 작성", team_name="pdca-{feature}",
     prompt="docs/01-plan/{feature}.plan.md를 참조하여 설계 문서를 작성하세요.
     필수 포함: 구현 대상 파일 목록, 인터페이스 설계, 데이터 흐름, 테스트 전략, 예상 위험 요소.
     출력: docs/02-design/{feature}.design.md")
SendMessage(type="message", recipient="design-writer", content="설계 문서 생성 요청. 완료 후 TaskUpdate로 completed 처리.")
# 완료 대기 → shutdown_request
```

**산출물**: `docs/02-design/{feature}.design.md`

### Design→Build Gate: Design 검증

| # | 필수 항목 | 확인 방법 |
|:-:|----------|----------|
| 1 | 구현 대상 파일 목록 | 구체적 파일 경로 나열 존재 |
| 2 | 인터페이스/API 설계 | 함수/클래스 시그니처 정의 |
| 3 | 테스트 전략 | 테스트 범위/방법 언급 존재 |
| 4 | 데이터 흐름 | 입출력 흐름 기술 존재 |

---

## Phase 2: BUILD (옵션 처리 + 구현 + 코드 리뷰 + Architect Gate)

### Step 2.0: 옵션 처리 (있을 경우)

옵션이 있으면 구현 진입 전에 처리. 실패 시 에러 출력 후 중단 (조용한 스킵 금지).

> 아래 인라인 옵션 외 `--slack`, `--gmail`, `--interactive`, `--con` 워크플로우는 본 파일 하단 별도 섹션 참조.

#### `--mockup [파일]` — 3-Tier 자동 목업 생성 (4-Step)

정본: `mockup-hybrid/SKILL.md` v2.1. 3-Tier 라우팅(Mermaid/HTML/Stitch)이 출력 형식을 자동 결정.

**Step 1: 라우팅 + 기본 HTML 생성 (Lead 직접 Python 호출)**
```python
import sys; sys.path.insert(0, 'C:/claude'); sys.path.insert(0, 'C:/claude/.claude')
from pathlib import Path
from lib.mockup_hybrid import MockupOptions

# MockupRouter는 analyzer → 3-Tier 라우팅 → adapter 선택 → HTML 생성
# options.bnw=True 시 html_adapter가 B&W 기본 팔레트를 자동 적용
from skills.mockup_hybrid.core.router import MockupRouter
router = MockupRouter()
options = MockupOptions(bnw={bnw_flag})
# --quasar 옵션 시 Quasar Material Design, --mockup-q 시 White Minimal
if mockup_q_flag:
    options = MockupOptions(style="quasar-white")
elif quasar_flag:
    options = MockupOptions(style="quasar")
result = router.route(prompt="{prompt}", options=options)
# 산출물: docs/mockups/{name}.html
```

**Mode A: 문서 기반** (`--mockup docs/02-design/auth.design.md`)
```
target_doc = options.get("mockup")  # 문서 경로
# Read(target_doc) → 헤딩 기반 섹션 분리 → 키워드 매칭 분류 (NEED/SKIP/EXIST)
# NEED 섹션 → 3-Tier 라우팅 (Mermaid/HTML/Stitch)
```

**Mode B: 단건** (`/auto "대시보드 화면" --mockup`)
```
# 3-Tier 라우팅 (키워드 기반) → HTML/Mermaid/Stitch 자동 선택
```

**Step 2: designer 스타일링 (HTML 선택 시)**
```
# 조건: backend == HTML
# --mockup-q 시 Quasar White Minimal, --quasar 시 Quasar Material Design
if options.style == "quasar-white":
    Agent(subagent_type="designer", name="mockup-designer", description="Quasar White 목업 디자인", team_name="pdca-{feature}",
         prompt="[Mockup Quasar White] docs/mockups/{name}.html을 Quasar White Tone Minimal로 스타일링.
                 Quasar UMD 컴포넌트 사용: q-toolbar, q-card flat bordered, q-input outlined, q-btn color='grey-8'.
                 self-closing 태그 금지 (<q-input /> → <q-input></q-input>).
                 Roboto 300/400/500/700. --q-primary: #374151, Page BG: #ffffff.
                 Header: bg-white text-dark + border-bottom. Card: flat bordered.
                 max-width: 720px, max-height: 1280px.
                 designer.md의 Quasar White Tone Minimal 섹션 참조.")
elif options.style == "quasar":
    Agent(subagent_type="designer", name="mockup-designer", description="Quasar 목업 디자인", team_name="pdca-{feature}",
         prompt="[Mockup Quasar] docs/mockups/{name}.html을 Quasar Material Design으로 스타일링.
                 Quasar UMD 컴포넌트 사용: q-toolbar, q-card, q-input outlined, q-btn, q-table.
                 self-closing 태그 금지 (<q-input /> → <q-input></q-input>).
                 Roboto 300/400/500/700. --q-primary 중심 색상.
                 max-width: 720px, max-height: 1280px.
                 designer.md의 Quasar Material Design 섹션 참조.")
else:
    Agent(subagent_type="designer", name="mockup-designer", description="목업 디자인", team_name="pdca-{feature}",
         prompt="[Mockup B&W] docs/mockups/{name}.html을 Refined Minimal B&W 스타일로 스타일링.
                 팔레트: #222326, #555555, #8a8a8a, #767676, #e5e5e5, #F4F5F8, #fff만.
                 emoji/SVG/icon font 금지. Inter 400/500/600 단일 서체.
                 max-width: 720px, max-height: 1280px.
                 designer.md의 B&W Refined Minimal 섹션 참조.")
SendMessage(type="message", recipient="mockup-designer", content="스타일링 시작.")
# 완료 대기 → shutdown_request
# Mermaid 선택 시 이 Step 스킵
```

**Step 3: PNG 캡처 (Lead 직접 Bash 실행)**
```bash
python -c "
import sys; sys.path.insert(0, 'C:/claude')
from pathlib import Path
from lib.mockup_hybrid.export_utils import capture_screenshot, get_output_paths
html_path = Path('docs/mockups/{name}.html')
_, img_path = get_output_paths('{name}')
result = capture_screenshot(html_path, img_path, auto_size=True)
print(f'CAPTURED: {result}' if result else 'CAPTURE_FAILED')
"
```

**Step 4: 문서 삽입 (대상 문서가 있는 경우만, Lead 직접 Edit)**
- 캡처 성공: `![{name}](docs/images/mockups/{name}.png)` + `[HTML 원본](docs/mockups/{name}.html)`
- 캡처 실패: `[{name} 목업](docs/mockups/{name}.html)` + 경고 메시지
- 대상 문서 없음: 삽입 스킵

**B&W Refined Minimal** (기본 스타일): HTML 목업은 항상 B&W Refined Minimal로 생성. `--bnw`는 deprecated (파싱만, 무시됨).
- Mermaid 선택 시: 기본 흑백 (designer 스킵)
- HTML 선택 시: Step 1에서 기본 팔레트 적용 + Step 2에서 designer 스타일링
- 팔레트: #222326, #555555, #8a8a8a, #767676(WCAG AA), #e5e5e5, #F4F5F8, #fff

**`--quasar`** (Quasar Material Design): `MockupOptions(style="quasar")` → Quasar UMD 템플릿 선택.
- CDN: Vue 3 + Quasar 2 UMD + Roboto + Material Icons
- Quasar 컴포넌트: q-toolbar, q-card, q-input outlined, q-btn, q-table, q-drawer
- B&W 팔레트 적용 스킵 (Quasar 자체 Material Design 색상)
- self-closing 태그 금지 (`<q-input />` → `<q-input></q-input>`)

**`--mockup-q`** (Quasar White Minimal): `MockupOptions(style="quasar-white")` → Quasar White 템플릿 선택.
- 팔레트: #374151 (차콜 primary), #ffffff (Page BG), #e5e7eb (border)
- Header: bg-white text-dark + border-bottom (elevated 제거)
- Card: flat bordered. Button: color="grey-8"
- CDN/UMD 제약 동일 (self-closing 금지)

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--anno [파일]` — Screenshot→HTML→Annotation 워크플로우 (5-Step)

pywinauto UIA 기반 annotation의 한계(커스텀 컨트롤 30%+ 미검출, DPI drift)를 우회. Vision AI + HTML 재현 방식으로 정확한 bbox 추출.

**대상 스크린샷** (6장):
```
gfx1_live.png, gfx2_live.png, gfx3_live.png,
sources_live.png, outputs_live.png, system_live.png
경로: C:\claude\ui_overlay\docs\03-analysis\
```

**Step 1: Vision AI 분석 (Lead 직접)**
```
# Claude Vision API로 스크린샷 분석
# 출력: UI 요소 리스트 (name, group, approximate position, control_type)
# 그룹핑: 기능적 연관성 기준 (예: "Player Stats", "Board Cards")
```

**Step 2: designer HTML 생성**
```python
Agent(subagent_type="designer", name="anno-designer", description="Anno HTML 생성", team_name="pdca-{feature}",
     prompt="""[Anno HTML] {tab_name}_live.png 스크린샷을 참조하여 구조 중심 HTML 생성.

     필수 규칙:
     1. 모든 UI 요소에 data-element-id (고유 정수), data-element-name (영문), data-element-group (소속 그룹) 속성 필수
     2. viewport = 원본 스크린샷 해상도와 동일 (PIL.Image.open으로 확인)
     3. CSS absolute positioning 기반 (bbox 정확도 최우선)
     4. 레이아웃/배치/크기: 원본과 정확히 일치. 색상/폰트: 근사치 허용
     5. 출력: html_reproductions/{tab_name}_live.html

     Step 1 분석 결과: {vision_analysis}""")
SendMessage(type="message", recipient="anno-designer", content="HTML 생성 시작.")
# 완료 대기 → shutdown_request
```

**Step 3-5: anno_workflow.py 실행 (Lead Bash)**
```bash
# 단일 탭
python C:/claude/ui_overlay/scripts/anno_workflow.py --screenshot C:/claude/ui_overlay/docs/03-analysis/{tab}_live.png

# 전체 6장
python C:/claude/ui_overlay/scripts/anno_workflow.py --all
```

내부 동작:
- Step 3-4: `html_to_elements.py` — Playwright viewport=스크린샷 해상도 → `querySelectorAll('[data-element-id]')` → bbox JSON (`elements/{tab}_live.json`)
- Step 5: `annotate_screenshot.py` — JSON + 원본 PNG → annotated PNG (overview + detail)

**에러 처리**:
- `data-element-id` 없는 HTML: exit code 1 + 에러 메시지
- Playwright 미설치: `playwright install chromium` 안내
- 스크린샷/HTML 미존재: SKIP 메시지 + 다음 탭 진행

**산출물**:
- `html_reproductions/{tab}_live.html` — designer 생성 HTML
- `elements/{tab}_live.json` — element_schema v1.2 호환 (source: `"html_reproduction"`)
- annotated PNG — overview + detail

#### `--gdocs` — Google Docs PRD 동기화

```
# prd-sync 커맨드 실행 (Google Docs → 로컬 동기화)
Agent(subagent_type="executor-high", name="prd-syncer", description="PRD 동기화", team_name="pdca-{feature}",
     prompt="[PRD Sync] .claude/commands/prd-sync.md 워크플로우 실행.
             Google Docs의 PRD를 docs/00-prd/ 로컬에 동기화.
             google-workspace 스킬의 OAuth 2.0 인증 사용.")
SendMessage(type="message", recipient="prd-syncer", content="PRD 동기화 시작.")
# 완료 대기 → shutdown_request
# 동기화된 PRD 파일을 Phase 1에 반영
```

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--critic` — 약점/문제점 분석 + 웹 리서치 솔루션 제안 (3-Phase)

> **목적**: 대상 문서/코드/설계의 단점과 문제점을 adversarial하게 찾아내고, 각 문제에 대해 웹 리서치로 최선의 솔루션을 탐색하여 우선순위별로 제안.
> **파이프라인**: Phase A (Critic 분석) → Phase B (웹 리서치) → Phase C (솔루션 보고서)

```
# Phase A: Critic 분석 — 약점/문제점 발견
Agent(subagent_type="critic", name="critic-analyst", description="약점/문제점 adversarial 분석", team_name="pdca-{feature}",
     prompt="[Critic Mode] 아래 대상을 adversarial하게 분석하여 약점과 문제점을 찾아라.
             대상: {사용자가 지정한 문서/코드/설계 경로 또는 내용}

             Attack Vectors 6개(A1-A6) 모두 적용:
             A1: Logical Gaps — 논리적 빈틈, 근거 없는 가정
             A2: Failure Scenarios — 실패 시나리오, 미처리 엣지 케이스
             A3: Ambiguity & Vagueness — 모호한 표현, 측정 불가 기준
             A4: Contradictions — 내부 모순, 기존 아키텍처 충돌
             A5: Missing Context — 누락된 의존성/참조/이해관계자
             A6: Overengineering — 불필요한 복잡성, 범위 초과
             A7: OOP Design Violations — 제어 결합도(3+), God Module, 순환 의존성, DIP 위반, Fat Interface

             출력 형식:
             VERDICT: DESTROYED | QUESTION | SURVIVED

             ## Weaknesses Found
             ### [W1] {제목}
             - **Vector**: A1-A6
             - **Severity**: Critical | Major | Minor
             - **Problem**: 구체적 문제 설명
             - **Impact**: 방치 시 결과
             - **Search Query**: 이 문제의 솔루션을 찾기 위한 웹 검색 키워드 (영문)

             각 Weakness에 반드시 Search Query를 포함하라. Phase B 리서치에 사용된다.")
SendMessage(type="message", recipient="critic-analyst", content="Critic 분석 시작.")
# 완료 대기 → critic 결과 수신 → shutdown_request
```

```
# Phase B: 웹 리서치 — 각 Weakness별 최선 솔루션 탐색
# critic 결과에서 Critical/Major weakness의 Search Query 추출
Agent(subagent_type="researcher", name="solution-researcher", description="약점별 웹 솔루션 리서치", team_name="pdca-{feature}",
     prompt="[Solution Research] critic 분석에서 발견된 약점별로 웹 리서치를 수행하라.

             ## Critic 분석 결과:
             {Phase A critic-analyst의 결과 전문}

             ## 리서치 지침:
             1. Critical/Major severity 약점만 리서치 (Minor는 스킵)
             2. 각 weakness의 Search Query를 사용하여 WebSearch + WebFetch 실행
             3. 공식 문서, GitHub 이슈, Stack Overflow, 기술 블로그 우선
             4. 각 약점별 최소 2개 솔루션 후보 제시

             ## 출력 형식:
             ### [W1] {약점 제목}
             #### Solution A: {솔루션명}
             - **출처**: {URL}
             - **핵심**: 솔루션 요약 (3줄 이내)
             - **적용성**: HIGH | MEDIUM | LOW (현재 프로젝트 맥락)
             - **트레이드오프**: 장단점

             #### Solution B: {대안 솔루션}
             ...

             #### Recommendation: Solution {A|B} 선택 이유 (1줄)")
SendMessage(type="message", recipient="solution-researcher", content="웹 리서치 시작.")
# 완료 대기 → 리서치 결과 수신 → shutdown_request
```

```
# Phase C: 최종 보고서 종합 (Lead 직접 수행 — 10줄 이내 요약)
# critic 결과 + 리서치 솔루션을 우선순위별로 정렬하여 사용자에게 보고:
#
# ## --critic 분석 결과
#
# | # | 약점 | 심각도 | 추천 솔루션 | 출처 |
# |---|------|--------|-----------|------|
# | W1 | {제목} | Critical | {솔루션 요약} | {URL} |
# | W2 | {제목} | Major | {솔루션 요약} | {URL} |
#
# 심각도 순 정렬: Critical → Major
# Minor는 별도 축약 목록으로 첨부
```

**QUESTION 처리**: critic VERDICT가 QUESTION이면 Phase B 스킵 → 질문 목록을 사용자에게 전달 → 사용자 응답 후 Phase A 재실행.

**SURVIVED 처리**: critic VERDICT가 SURVIVED이면 Phase B 스킵 → "분석 대상에서 의미 있는 약점이 발견되지 않았습니다" 보고.

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--debate` — 3-AI 병렬 분석 합의 판정

```
# ultimate-debate 엔진 실행
Agent(subagent_type="executor-high", name="debate-runner", description="토론 실행", team_name="pdca-{feature}",
     prompt="[Debate] ultimate-debate 스킬 실행.
             주제: {사용자 요청 내용}
             실행: python .claude/skills/ultimate-debate/scripts/main.py --task '{주제}'
             결과를 .claude/debates/{task_id}/FINAL.md에 저장.
             최종 합의안을 요약하여 보고.")
SendMessage(type="message", recipient="debate-runner", content="토론 시작.")
# 완료 대기 → shutdown_request
# 합의 결과를 Phase 1 계획에 반영
```

> **전제조건**: Core Engine 사용 시 `cd C:\claude\packages\ultimate-debate && pip install -e .` 필수. 미설치 시 mock 모드로 폴백 (경고 출력).

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--research` — 코드베이스/외부 리서치

```
# research 스킬 실행 (RPI Phase 1)
Agent(subagent_type="researcher", name="researcher", description="리서치 실행", team_name="pdca-{feature}",
     prompt="[Research] {사용자 요청} 관련 리서치 수행.
             서브커맨드: code (코드 분석) | web (외부 검색) | plan (구현 계획) | review (코드 리뷰)
             결과 요약을 5줄 이내로 보고.")
SendMessage(type="message", recipient="researcher", content="리서치 시작.")
# 완료 대기 → shutdown_request
# 리서치 결과를 Phase 1 사전 분석에 반영
```

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--daily` — 일일 대시보드 (9-Phase Pipeline)

```
# daily 스킬 실행 (3소스 수집 + AI 분석 + 액션 추천)
Agent(subagent_type="executor-high", name="daily-runner", description="일일 대시보드 생성", team_name="pdca-{feature}",
     prompt="[Daily] daily 스킬의 9-Phase Pipeline 전체 실행 (Phase 0-8 순차).
             Design Reference: docs/02-design/daily-redesign.design.md
             3소스: Gmail/Slack/GitHub 증분 수집 → AI 크로스소스 분석 → 액션 추천.
             결과: 대시보드 요약 + 액션 추천 목록 (최대 10건).")
SendMessage(type="message", recipient="daily-runner", content="Daily 파이프라인 시작.")
# 완료 대기 → shutdown_request
# daily 결과를 Phase 1 계획에 반영 (현황 파악 용도)
```

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

#### `--jira <command> <target>` — Jira 조회/분석

```
# jira 스킬 실행 (Atlassian REST API + Agile API)
# 서브커맨드: epics <board_id> | project <key> | board <id> | search "<jql>" | issue <key>

# Step 1: command + target 파라미터 파싱
jira_command = options.get("jira_command")  # epics | project | board | search | issue
jira_target = options.get("jira_target")    # board_id | project_key | jql | issue_key

# Step 2: Jira 조회 실행
Agent(subagent_type="executor", name="jira-runner", description="Jira 조회 실행", team_name="pdca-{feature}",
     prompt="[Jira] --jira {jira_command} {jira_target} 실행.
             실행: cd C:\\claude && python lib/jira/jira_client.py {jira_command} {jira_target}
             결과를 구조화된 분석으로 보고.
             epics 커맨드 시 Epic별 Story/Sub-task 구조 분석 포함.
             인증은 스크립트가 Windows User 환경변수에서 자동 로드한다. 셸 환경변수 사전 확인 불필요.")
SendMessage(type="message", recipient="jira-runner", content="Jira 조회 시작.")
# 완료 대기 → shutdown_request
# Jira 결과를 Phase 1 계획에 컨텍스트로 반영
```

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

#### `--figma <url> [connect|rules|capture|auth]` — Figma 디자인 연동

```
# figma 스킬 실행 (MCP 플러그인 래퍼 → 5가지 variant)
# variant: implement (기본) | connect | rules | capture | auth

# Step 0: 인증 검증 (MANDATORY — 모든 모드 공통)
# mcp__plugin_figma_figma__whoami() 호출
# 실패 시 "Figma MCP 서버 미연결" 에러 출력 후 즉시 중단
# 성공 시 email, handle, plans 확인 → seat 권한 체크

# Step 1: 모드 판별 + URL 파싱
figma_args = options.get("figma_args", "")  # "<url>", "connect <url>", "rules", "capture", "auth"
figma_variant = "implement"  # 기본값
figma_url = None

if figma_args == "auth":
    figma_variant = "auth"
elif figma_args == "rules":
    figma_variant = "rules"
elif figma_args.startswith("capture"):
    figma_variant = "capture"
elif figma_args.startswith("connect "):
    figma_variant = "connect"
    figma_url = figma_args.split("connect ", 1)[1].strip()
else:
    figma_variant = "implement"
    figma_url = figma_args.strip()

# Step 2: URL 파싱 (implement/connect 모드)
if figma_url:
    # cd C:\claude && python lib/figma/url_parser.py '{figma_url}'
    # 반환: {"file_key": str, "node_id": str|None, "url_type": "design"|"branch"|"board"|"make"}
    # url_type == "board" → get_figjam 사용 (FigJam)
    # url_type != "board" → get_design_context 사용 (기본)

# Step 3: 모드별 실행
if figma_variant == "auth":
    # mcp__plugin_figma_figma__whoami() 결과 출력
    # 출력 형식: "Figma 인증: {email} | Plan: {plan} | Seat: {seat_type}"
    # 에러 시: "Figma MCP 서버 미연결. 플러그인 설정 확인 필요." 출력 후 중단
    whoami = mcp__plugin_figma_figma__whoami()
    print(f"Figma 인증: {whoami.email} | Plan: {whoami.plans} | Seat: {whoami.seat_type}")

elif figma_variant == "implement":
    Agent(subagent_type="designer", name="figma-designer", description="Figma 디자인 구현", team_name="pdca-{feature}",
         prompt="[Figma] implement 모드 실행.
                 URL: {figma_url}
                 파싱 결과: file_key={file_key}, node_id={node_id}, url_type={url_type}

                 실행 절차:
                 1. 인증 확인: mcp__plugin_figma_figma__whoami()
                 2. url_type에 따라 MCP 도구 선택:
                    - board → mcp__plugin_figma_figma__get_figjam(fileKey, nodeId)
                    - 기타 → mcp__plugin_figma_figma__get_design_context(fileKey, nodeId)
                 3. 필요 시 추가 도구:
                    - get_screenshot(fileKey, nodeId) — 시각적 참조
                    - get_variable_defs(fileKey, nodeId) — 디자인 토큰
                    - get_metadata(fileKey, nodeId) — 전체 구조 (nodeId 미지정 시)
                 4. 디자인 컨텍스트 분석:
                    - Code Connect 스니펫 → 기존 컴포넌트 직접 사용
                    - 디자인 토큰 → 프로젝트 토큰 시스템에 매핑
                    - Raw 값 → 스크린샷 참조하여 구현
                 5. 프로젝트 기존 컴포넌트/패턴과 매칭하여 코드 생성")
    SendMessage(type="message", recipient="figma-designer", content="Figma 디자인 구현 시작.")

elif figma_variant == "connect":
    Agent(subagent_type="executor-high", name="figma-connector", description="Figma 컴포넌트 연결", team_name="pdca-{feature}",
         prompt="[Figma] connect 모드 실행.
                 URL: {figma_url}
                 파싱 결과: file_key={file_key}, node_id={node_id}

                 실행 절차:
                 1. 인증 확인: mcp__plugin_figma_figma__whoami() — seat=Full 필수
                 2. 기존 매핑 확인: get_code_connect_map(fileKey, nodeId)
                 3. AI 매핑 제안: get_code_connect_suggestions(fileKey, nodeId)
                 4. 제안 결과를 사용자에게 검토 요청 (AskUserQuestion)
                 5. 승인된 매핑 저장: send_code_connect_mappings(fileKey, nodeId, mappings)
                    label: 프로젝트 프레임워크에 맞게 선택 (React|Vue|Svelte 등)")
    SendMessage(type="message", recipient="figma-connector", content="Figma 컴포넌트 매핑 시작.")

elif figma_variant == "rules":
    Agent(subagent_type="executor", name="figma-rules", description="디자인 시스템 규칙 생성", team_name="pdca-{feature}",
         prompt="[Figma] rules 모드 실행.
                 1. 인증 확인: mcp__plugin_figma_figma__whoami()
                 2. 프로젝트 프레임워크 감지 (package.json, tsconfig 등)
                 3. create_design_system_rules(clientFrameworks, clientLanguages) 호출
                 4. 반환된 규칙을 .claude/rules/ 에 저장")
    SendMessage(type="message", recipient="figma-rules", content="디자인 시스템 규칙 생성 시작.")

elif figma_variant == "capture":
    # Lead가 직접 실행 (interactive — 에이전트 위임 불가, 브라우저+폴링 필요)
    #
    # Step 1: outputMode 결정
    #   generate_figma_design() 호출 (outputMode 없이) → 사용자에게 AskUserQuestion
    #   선택지: newFile (planKey 필요), existingFile (fileKey 필요), clipboard
    #
    # Step 2: captureId 발급
    #   generate_figma_design(outputMode="newFile", fileName="...", planKey="...")
    #   → captureId 반환
    #
    # Step 3: 캡처 대상 준비
    #   a. 대상 HTML에 <script src="https://mcp.figma.com/.../capture.js" async></script> 주입
    #   b. 캡처 CSS 검증: body에 불필요한 background/padding이 없는지 확인
    #      - body: margin:0, padding:0, background:transparent, display:inline-block
    #      - wrapper/container: padding 제거, 체커보드/장식 배경 제거
    #      - capture-reset.css 링크 확인 (mockups/capture/ 내 파일)
    #   c. HTTP 서버 시작: python -m http.server {port} (npx http-server fallback)
    #   d. Headless 캡처 (브라우저 창 없음):
    #      cd C:\claude && python -c "from lib.mockup_hybrid.export_utils import capture_url; capture_url('http://localhost:{port}/{page}#figmacapture={captureId}&figmaendpoint=https%3A%2F%2Fmcp.figma.com%2Fmcp%2Fcapture%2F{captureId}%2Fsubmit&figmadelay=2000')"
    #
    # Step 4: 폴링 (5초 간격, max 10회)
    #   sleep 5 → generate_figma_design(captureId="{captureId}")
    #   status == "pending"/"processing" → 재시도
    #   status == "completed" → Figma 파일 URL 반환 + 브라우저 열기
    #   10회 초과 → "캡처 실패" 에러 출력 후 중단
    #
    # Mermaid 다이어그램: generate_diagram(name, mermaidSyntax) → FigJam URL 반환
    pass

# 완료 대기 → shutdown_request
# Figma 결과를 Phase 2 구현에 컨텍스트로 반영
```

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

#### Phase 0 옵션 파싱 — 스킵 플래그

```python
# --skip-prd: Phase 1 Step 1.1 PRD 스킵
if "--skip-prd" in options:
    # Step 1.1 건너뛰기 → Step 1.2 사전 분석부터 시작
    # 이유 기록 필수 (규칙 13-requirements-prd 준수)

# --skip-analysis: Phase 1 Step 1.2 사전 분석 스킵
if "--skip-analysis" in options:
    # Step 1.2 건너뛰기 → Step 1.3 계획 수립부터 시작

# --no-issue: Phase 1 Step 1.5 이슈 연동 스킵
if "--no-issue" in options:
    # Step 1.5 건너뛰기 (GitHub 이슈 생성/코멘트 안 함)

# --dry-run: 범용 판단만 출력 (실제 변경 없음)
if "--dry-run" in options:
    # Phase 0 복잡도 판단 + Phase 1 계획까지만 실행
    # 구현(Phase 2), 검증(Phase 3), 마감(Phase 4) 스킵
    # --con의 dry-run과 달리 전체 워크플로우에 적용

# --strict: Phase 3 E2E strict 모드
if "--strict" in options:
    # E2E 1회 실패 즉시 중단 (기본: max 2회 재시도)
    # Phase 3 Step 3.2 e2e-runner prompt에 strict_mode=True 주입
    # 상세: Phase 3 Step 3.2 E2E 백그라운드 섹션 참조

# --eco 세분화 (v25.0): 3단계 비용 절감
eco_level = 0
if "--eco-3" in options:
    eco_level = 3
elif "--eco-2" in options:
    eco_level = 2
elif "--eco" in options:
    eco_level = 1

if eco_level >= 1:
    # Level 1: Opus → Sonnet (architect, planner, critic, executor-high, scientist-high)
    # 모든 Opus 에이전트의 model을 "sonnet"으로 오버라이드

if eco_level >= 2:
    # Level 2: 비핵심 Sonnet → Haiku (추가 다운그레이드)
    # 대상: gap-detector, explore-medium, analyst, vision, catalog-engineer, claude-expert, researcher
    # 유지: code-reviewer, executor, designer, qa-tester, build-fixer, security-reviewer, tdd-guide

if eco_level >= 3:
    # Level 3: 전체 Sonnet → Haiku (프로토타이핑 전용)
    # WARNING: 프로덕션 워크플로우 금지. 코드 리뷰/보안 검토 품질 저하
    # 모든 Sonnet 에이전트의 model을 "haiku"로 오버라이드

# --worktree: feature worktree 격리
if "--worktree" in options:
    # Phase 0에서 git worktree add + .claude junction 생성
    # 모든 teammate prompt에 worktree 경로 prefix 주입
    # Phase 4 완료 후 worktree 정리 (사용자 확인)
    # 상세: 본 파일 'Worktree 통합' 섹션 참조
```

### Step 2.1: 모드별 구현 (명시적 호출)

**LIGHT 모드: Executor teammate (opus) 단일 실행**
```
Agent(subagent_type="executor-high", name="executor", description="구현 실행", team_name="pdca-{feature}",
     prompt="docs/01-plan/{feature}.plan.md 기반 구현 (설계 문서 없음). TDD 필수.")
SendMessage(type="message", recipient="executor", content="구현 시작. 완료 후 TaskUpdate로 completed 처리.")
# 완료 대기 → shutdown_request
```
- 4조건 검증 없음 (단일 실행)
- 빌드 실패 시 즉시 STANDARD 모드로 승격

**STANDARD 모드: impl-manager teammate (opus) — 4조건 자체 루프**
```
Agent(subagent_type="executor-high", name="impl-manager", description="4조건 자체 루프 구현 관리", team_name="pdca-{feature}",
     prompt="{impl-manager prompt 전문 — 아래 'impl-manager Prompt 전문' 섹션 참조}")
SendMessage(type="message", recipient="impl-manager", content="4조건 구현 루프 시작.")
# Lead는 IMPLEMENTATION_COMPLETED 또는 IMPLEMENTATION_FAILED 메시지만 수신
```

**HEAVY 모드: impl-manager teammate (opus) — 4조건 자체 루프 + 병렬 가능**
```
Agent(subagent_type="executor-high", name="impl-manager", description="4조건 자체 루프 구현 관리", team_name="pdca-{feature}",
     prompt="{impl-manager prompt 전문 — 아래 'impl-manager Prompt 전문' 섹션 참조}")
SendMessage(type="message", recipient="impl-manager", content="4조건 구현 루프 시작.")
# Lead는 IMPLEMENTATION_COMPLETED 또는 IMPLEMENTATION_FAILED 메시지만 수신
```

**HEAVY 병렬 실행 (독립 작업 2개 이상 시):**
```
# Lead가 설계 문서 분석 → 독립 작업 분할
Agent(subagent_type="executor-high", name="impl-api", description="API 구현 담당",
     team_name="pdca-{feature}",
     prompt="[Phase 2 HEAVY 병렬] API 구현 담당. {impl-manager 전체 prompt}.
             담당 범위: src/api/ 하위 파일만. 다른 경로 수정 금지.")
Agent(subagent_type="executor-high", name="impl-ui", description="UI 구현 담당",
     team_name="pdca-{feature}",
     prompt="[Phase 2 HEAVY 병렬] UI 구현 담당. {impl-manager 전체 prompt}.
             담당 범위: src/components/ 하위 파일만. 다른 경로 수정 금지.")

SendMessage(type="message", recipient="impl-api", content="API 구현 시작.")
SendMessage(type="message", recipient="impl-ui", content="UI 구현 시작.")
# 두 impl-manager 모두에서 IMPLEMENTATION_COMPLETED 수신 대기
# 하나라도 FAILED → Lead가 사용자에게 알림
```

**--worktree 병렬 격리** (Worktree 통합 섹션의 Agent Teams 병렬 격리 참조)

### Build→Verify Gate: impl-manager 완료 판정 + Architect Gate (v22.1)

- LIGHT: 빌드 통과만 확인 (Architect Gate 없음, Phase 3 직행)
- STANDARD/HEAVY: impl-manager `IMPLEMENTATION_COMPLETED` → **Step 2.2 Code Review → Step 2.3 Architect Gate 필수** → Phase 3
- impl-manager가 `IMPLEMENTATION_FAILED` 메시지 전송 시 Lead가 사용자에게 알림 + 수동 개입 요청
- --interactive 모드: 사용자 확인 요청

### Step 2.2: Code Review (STANDARD/HEAVY 필수)

구현 완료 후 **즉시** code-reviewer (sonnet) 실행. LIGHT 모드는 스킵.

```
# Code Review — 코드 품질 + Vercel BP 동적 주입
# Lead가 직접 프로젝트 유형 감지 후 Vercel BP 규칙 동적 주입

# === Vercel BP 동적 주입 메커니즘 (Lead 직접 실행) ===
has_nextjs = len(Glob("next.config.*")) > 0
has_react = False
pkg_files = Glob("package.json")
if pkg_files:
    has_react = '"react"' in Read("package.json")

if has_nextjs or has_react:
    vercel_bp_rules = Read("C:\claude\.claude\references\vercel-bp-rules.md")
    reviewer_prompt = f"구현 코드의 품질, 보안, 성능 이슈 분석.\n\n=== Vercel Best Practices ===\n{vercel_bp_rules}"
else:
    reviewer_prompt = "구현 코드의 품질, 보안, 성능 이슈 분석."

Agent(subagent_type="code-reviewer", name="code-reviewer", description="코드 리뷰", team_name="pdca-{feature}",
     prompt=reviewer_prompt)
SendMessage(type="message", recipient="code-reviewer", content="코드 품질 리뷰 시작. APPROVE 또는 REVISE + 수정 목록 제공.")
# code-reviewer 완료 대기 → shutdown_request

# === Hybrid Review (code-review 플러그인 활성 시, STANDARD/HEAVY) ===
# 내부 code-reviewer 결과 + 플러그인 5-agent 병렬 결과 병합
if "code-review" in activated_plugins and mode in ["STANDARD", "HEAVY"]:
    # code-review 플러그인 5개 병렬 에이전트:
    # 1. CLAUDE.md Compliance — CLAUDE.md 규칙 준수 검사
    # 2. Shallow Bug Scan — 표면 버그 탐지
    # 3. Git Blame Context — 변경 이력 기반 분석
    # 4. PR Comment Patterns — PR 코멘트 패턴 분석
    # 5. Code Comment Compliance — 코드 주석 품질 검사
    #
    # 플러그인 에이전트 결과를 내부 code-reviewer 결과와 병합:
    # - 내부 APPROVE + 플러그인 이슈 0건 → 최종 APPROVE
    # - 내부 APPROVE + 플러그인 이슈 있음 → 이슈 통합 후 REVISE
    # - 내부 REVISE → 플러그인 이슈도 수정 목록에 병합

# APPROVE → Step 2.3 Architect Gate 진입
# REVISE + 수정 목록 → executor로 수정 → code-reviewer 재검토 (max 2회)
```

### Step 2.3: Architect Verification Gate (STANDARD/HEAVY 필수)

impl-manager가 IMPLEMENTATION_COMPLETED를 보고한 후, 독립 Architect가 구현을 외부 검증합니다.

```
rejection_count = 0  # Lead 메모리에서 관리

# Architect 외부 검증
Agent(subagent_type="architect", name="impl-verifier", description="구현 검증", team_name="pdca-{feature}",
     prompt="[Phase 2 Architect Gate] 구현 외부 검증.
             Plan: docs/01-plan/{feature}.plan.md
             Design: docs/02-design/{feature}.design.md (있으면)

             구현된 코드가 Plan/Design 요구사항을 충족하는지 검증하세요.

             검증 항목:
             1. Plan의 모든 구현 항목이 실제 구현되었는지
             2. 설계 문서의 인터페이스/API가 구현과 일치하는지
             3. TDD 규칙 준수 (테스트 존재 여부)
             4. 빌드/lint 에러가 없는지 (ruff check, tsc --noEmit 등)
             5. 보안 취약점 (OWASP Top 10) 여부
             6. OOP 결합도/응집도 수준 (모듈 간 결합도 2단계 이하, 응집도 2단계 이하 목표)

             === OOP Score 평가 (v25.0) ===
             출력에 아래 OOP Score를 반드시 포함하세요:
             - avg_coupling: 모듈 간 평균 결합도 (1-6)
             - max_coupling: 최악 결합도
             - avg_cohesion: 모듈 내 평균 응집도 (1-7)
             - worst_cohesion: 최악 응집도
             - srp_violations: SRP 위반 모듈 수
             - dip_violations: DIP 위반 수
             - circular_deps: 순환 의존성 수

             OOP Gate 기준:
             - avg_coupling > 2.0 → REJECT
             - worst_cohesion > 4 → REJECT
             - circular_deps > 0 → REJECT
             - srp_violations > 0 → REJECT (STANDARD/HEAVY)

             === Iron Law #3: Verification (MANDATORY) ===
             증거 없이 APPROVE 금지. 아래 증거를 반드시 수집하고 판정에 포함하세요:
             - 빌드 결과 (exit code)
             - 테스트 결과 (pass/fail 수)
             - lint/type-check 결과

             반드시 첫 줄에 다음 형식으로 출력하세요:
             VERDICT: APPROVE 또는 VERDICT: REJECT
             DOMAIN: {UI|build|test|security|logic|other}

             REJECT 시 구체적 거부 사유와 수정 지침을 포함하세요.")
SendMessage(type="message", recipient="impl-verifier", content="구현 외부 검증 시작.")
# 완료 대기 → shutdown_request

# VERDICT 파싱
verifier_message = Mailbox에서 수신한 impl-verifier 메시지
if "VERDICT: APPROVE" in first_line:
    → Step 2.3b Gap Analysis (STANDARD/HEAVY만)
elif "VERDICT: REJECT" in first_line:
    rejection_count += 1
    domain = DOMAIN 값 추출
    rejection_reason = VERDICT 줄 이후 전체 내용

    if rejection_count >= 2:
        → "[Phase 2] Architect 2회 거부. 사용자 판단 필요." 출력
        → 사용자에게 알림 후 Phase 3 진입 허용 (완전 차단은 아님)
    else:
        → Step 2.4 Domain-Smart Fix 실행 → Architect 재검증
```

### Step 2.3b: Gap Analysis (STANDARD/HEAVY — Architect APPROVE 후)

Architect 정성 검증 통과 후, gap-detector로 설계-구현 정량 비교. LIGHT는 스킵.

```
# Gap Analysis — 7개 항목 정량 비교
Agent(subagent_type="gap-detector", name="gap-checker", description="설계-구현 정량 비교",
     team_name="pdca-{feature}",
     prompt="[Phase 2 Gap Analysis] 설계-구현 정량 비교.
             Plan: docs/01-plan/{feature}.plan.md
             Design: docs/02-design/{feature}.design.md (있으면)
             7개 항목 매칭 비교 → Match Rate(%) 산출.
             docs/03-analysis/{feature}.gap-analysis.md 출력.
             Match Rate >= 90%: APPROVE
             Match Rate < 90%: GAP_FOUND + 미구현 목록")
SendMessage(type="message", recipient="gap-checker", content="Gap 분석 시작.")
# 완료 대기 → shutdown_request

# 결과 파싱
if GAP_FOUND and match_rate < 90%:
    → executor로 갭 수정 → gap-detector 재검증 (max 1회)
if APPROVE or match_rate >= 90%:
    → 커밋 → Phase 3 진입
```

### Step 2.4: Domain-Smart Fix Routing

Architect REJECT 시 DOMAIN 값에 따라 전문 에이전트에게 수정 위임:

| Architect DOMAIN 값 | 에이전트 | subagent_type |
|---------------------|---------|---------------|
| UI, component, style | designer | `designer` |
| build, compile, type | build-fixer | `build-fixer` |
| test, coverage | executor | `executor` |
| security | security-reviewer | `security-reviewer` |
| logic, other | executor | `executor` |

```
# Domain-Smart Fix
Agent(subagent_type="{domain_agent}", name="domain-fixer", description="도메인별 수정",
     team_name="pdca-{feature}",
     prompt="[Phase 2 Domain Fix] Architect 거부 사유 해결.
             거부 사유: {rejection_reason}
             DOMAIN: {domain}
             수정 후 해당 검사를 재실행하여 통과를 확인하세요.")
SendMessage(type="message", recipient="domain-fixer", content="Architect 피드백 반영 시작.")
# 완료 대기 → shutdown_request → Step 3.2 Architect 재검증
```

---

## impl-manager Prompt 전문

Phase 2에서 impl-manager teammate에 전달하는 complete prompt:

```
[Phase 2 BUILD] Implementation Manager - 4조건 자체 루프

설계 문서: docs/02-design/{feature}.design.md
계획 문서: docs/01-plan/{feature}.plan.md

당신은 Implementation Manager입니다. 설계 문서를 기반으로 코드를 구현하고,
5가지 완료 조건을 모두 충족할 때까지 자동으로 수정/재검증을 반복합니다.

=== 4가지 완료 조건 (ALL 충족 필수) ===

1. TODO == 0: 설계 문서의 모든 구현 항목 완료. 부분 완료 금지.
2. 빌드 성공: 프로젝트 빌드 명령 실행 결과 에러 0개.
   - Python: ruff check src/ --fix (lint 통과)
   - Node.js: npm run build (빌드 통과)
   - 해당 빌드 명령이 없으면 이 조건은 자동 충족.
3. 테스트 통과: 모든 테스트 green.
   - Python: pytest tests/ -v (관련 테스트만 실행 가능)
   - Node.js: npm test 또는 jest
   - 테스트가 없으면 TDD 규칙에 따라 테스트 먼저 작성.
4. 에러 == 0: lint, type check 에러 0개.
   - Python: ruff check + mypy (설정 있을 때)
   - Node.js: tsc --noEmit (TypeScript일 때)

> 코드 품질 리뷰 책임은 code-reviewer 단독 담당 (v25.0 SRP 적용).

=== 자체 Iteration 루프 ===

최대 10회까지 반복합니다:
  1. 4조건 검증 실행
  2. 미충족 조건 발견 시 → 해당 문제 수정
  3. 수정 후 → 1번으로 (재검증)
  4. ALL 충족 시 → IMPLEMENTATION_COMPLETED 메시지 전송
  5. 10회 도달 시 → IMPLEMENTATION_FAILED 메시지 전송

=== Iron Law Evidence Chain ===

IMPLEMENTATION_COMPLETED 전송 전 반드시 다음 4단계 증거를 확보하세요:
  1. 모든 테스트 통과 (pytest/jest 실행 결과 캡처)
  2. 빌드 성공 (build command 실행 결과 캡처)
  3. Lint/Type 에러 0개 (ruff/tsc 실행 결과 캡처)
  4. 위 3개 결과를 IMPLEMENTATION_COMPLETED 메시지에 포함

증거 없는 완료 주장은 절대 금지합니다.

=== Completion Promise 경고 (v22.1) ===

IMPLEMENTATION_COMPLETED 선언은 독립 Architect가 외부 검증합니다.
거짓 완료 신호 전송 시 REJECTED 판정을 받게 됩니다.
자기 채점만으로 COMPLETED를 선언하지 마세요. 4조건을 실제로 검증한 증거를 포함하세요.

=== Zero Tolerance 규칙 ===

다음 행위는 절대 금지합니다:
  - 범위 축소: 설계 문서의 구현 항목을 임의로 제외
  - 부분 완료: "나머지는 나중에" 식의 미완성 제출
  - 테스트 삭제: 실패하는 테스트를 삭제하여 green 만들기
  - 조기 중단: 4조건 미충족 상태에서 COMPLETED 전송
  - 불확실 언어: "should work", "probably fine", "seems to pass" 등 사용 시
    → 해당 항목에 대해 구체적 검증을 추가로 실행

=== Red Flags 자체 감지 ===

다음 패턴을 자체 감지하고 경고하세요:
  - "should", "probably", "seems to" 등 불확실 언어 사용
  - TODO/FIXME/HACK 주석 추가
  - 테스트 커버리지 80% 미만
  - 하드코딩된 값 (매직 넘버, 매직 스트링)
  - 에러 핸들링 누락 (bare except, empty catch)

감지 시 처리: Red Flag 발견 → 해당 항목을 즉시 수정 후 다음 iteration으로 진행.
수정 불가 시 IMPLEMENTATION_FAILED 메시지에 Red Flag 목록을 포함하여 Lead에게 보고.

=== OOP Implementation Guard ===

구현 중 아래 패턴을 적극 적용하세요:

1. 의존성 주입 (DI):
   - 구체 클래스를 직접 생성하지 말 것 (new ConcreteClass() 금지)
   - 생성자/팩토리를 통해 외부에서 주입
   - 테스트 시 Mock 교체 가능한 구조

2. 단일 책임 원칙 (SRP):
   - 한 클래스/모듈 = 한 가지 이유로만 변경
   - 파일 크기 > 300줄 → 분리 검토
   - 메서드 > 5개 독립 관심사 → 분리 필수

3. 인터페이스 분리 원칙 (ISP):
   - 클라이언트가 사용하지 않는 메서드에 의존하지 않도록
   - Fat Interface 감지 시 → 역할별 작은 인터페이스로 분리

4. 금지 패턴:
   - 전역 변수로 모듈 간 상태 공유 (공통 결합도)
   - boolean 파라미터로 다른 모듈 동작 제어 (제어 결합도)
   - 다른 모듈의 private 멤버 직접 접근 (내용 결합도)
   - 상속 깊이 3단계 이상 (Composition 우선)

이 가이드라인을 어기면 code-reviewer에서 HIGH/CRITICAL 이슈로 판정됩니다.

=== 메시지 형식 ===

[성공 시]
IMPLEMENTATION_COMPLETED: {
  "iterations": {실행 횟수},
  "files_changed": [{변경 파일 목록}],
  "test_results": "{pytest/jest 결과 요약}",
  "build_results": "{빌드 결과 요약}",
  "lint_results": "{lint 결과 요약}"
}

[실패 시]
IMPLEMENTATION_FAILED: {
  "iterations": 10,
  "remaining_issues": [{미해결 문제 목록}],
  "last_attempt": "{마지막 시도 요약}",
  "recommendation": "{권장 조치}"
}

=== Background Operations ===

install, build, test 등 장시간 명령은 background로 실행하세요:
  - npm install → background
  - pip install → background
  - 전체 테스트 suite → foreground (결과 확인 필요)

=== Delegation ===

직접 코드를 작성하세요. 추가 teammate를 spawn하지 마세요.
이 teammate 내부에서의 에이전트 호출은 금지됩니다.
```

### 자동 재시도/승격/실패 로직

| 조건 | 처리 |
|------|------|
| impl-manager 4조건 루프 내 빌드 실패 | impl-manager 자체 재시도 (10회 한도 내) |
| impl-manager 10회 초과 (FAILED 반환) | Lead가 사용자에게 알림 + 수동 개입 요청 |
| LIGHT에서 빌드 실패 2회 | STANDARD 자동 승격 (impl-manager 재spawn) |
| QA 3사이클 초과 | STANDARD → HEAVY 자동 승격 |
| 영향 파일 5개 이상 감지 | LIGHT/STANDARD → HEAVY 자동 승격 |
| 진행 상태 추적 | `pdca-status.json`의 `implManagerIteration` 필드 |
| 세션 중단 후 resume | `pdca-status.json` 기반 Phase/iteration 복원 |

---

## Phase 3: VERIFY (QA Runner + Architect 진단 + 이중 검증 + E2E)

### Step 3.1: QA 사이클 — QA Runner + Architect Root Cause 진단 + Domain-Smart Fix (v22.1)

> **v22.1 핵심 변경**: Lead 직접 QA 실행 → QA Runner teammate 위임 (Lead context 보호).
> 실패 시 Architect 진단 선행 (맹목적 수정 금지).

```
# LIGHT 모드: QA 1회 실행, 실패 시 보고만 (진단/수정 사이클 없음)
if mode == "LIGHT":
    Agent(subagent_type="qa-tester", name="qa-runner", description="QA 실행", team_name="pdca-{feature}", prompt="[Phase 3 QA Runner] 6종 QA 실행. (LIGHT 모드)")
    SendMessage(type="message", recipient="qa-runner", content="QA 실행 시작.")
    # 완료 대기 → shutdown_request
    if QA_PASSED → Step 3.2
    if QA_FAILED → 실패 보고 + STANDARD 자동 승격 조건 확인
    return  # LIGHT는 Architect 진단 + Domain Fix 사이클 진입하지 않음

# STANDARD/HEAVY 모드: 아래 QA 사이클 적용
failure_history = []  # 실패 기록 배열 (Lead 메모리에서 관리)
max_cycles = STANDARD:3 / HEAVY:5
cycle = 0

while cycle < max_cycles:
  cycle += 1

  # Step A: QA Runner Teammate (Lead context 보호)
  Agent(subagent_type="qa-tester", name="qa-runner-{cycle}", description="QA 실행 사이클",
       team_name="pdca-{feature}",
       prompt="[Phase 3 QA Runner] 6종 QA 실행.
               === 6종 QA Goal ===
               1. lint: ruff check src/ --fix (Python) / eslint (JS/TS)
               2. test: pytest tests/ -v (Python) / jest/vitest (JS/TS)
               3. build: npm run build / pip install -e . (해당 시)
               4. typecheck: mypy (Python, 설정 시) / tsc --noEmit (TS)
               5. custom: '{custom_pattern}' (--custom 옵션 시만)
               6. interactive: tmux 테스트 (--interactive 옵션 시만)

               각 goal에 대해 실행 → 결과 수집 → PASS/FAIL 판정.
               해당하지 않는 goal (예: Python 프로젝트의 eslint)은 SKIP 처리.

               모든 goal PASS 시 → QA_PASSED 메시지 전송
               1개라도 FAIL 시 → QA_FAILED 메시지 전송 (실패 goal, 에러 상세, 실패 시그니처 포함)

               메시지 형식:
               QA_PASSED: { 'goals': [{goal, status, output}] }
               QA_FAILED: { 'goals': [{goal, status, output, signature}], 'failed_count': N }")
  SendMessage(type="message", recipient="qa-runner-{cycle}", content="QA 실행 시작.")
  # 완료 대기 → shutdown_request

  # Lead: QA Runner 결과 판정
  if QA_PASSED:
      → Step 3.2 (이중 검증) 진입

  if QA_FAILED:
    # Step B: 실패 기록 + Exit Condition 검사
    for each failed_goal in qa_result.goals:
      failure_entry = {
        "cycle": cycle,
        "type": failed_goal.goal,
        "detail": failed_goal.output,
        "signature": failed_goal.signature
      }
      failure_history.append(failure_entry)

    # Exit Condition 1: Environment Error (PATH, 도구 미설치 등)
    if qa_result contains environment error pattern:
        → 즉시 중단 + "[Phase 3] 환경 오류 감지: {detail}. 환경 설정 필요." 출력
        → Phase 3 종료

    # Exit Condition 2: Same Failure 3x
    for each failure in failure_history:
      same_failures = [f for f in failure_history if f.signature == failure.signature]
      if len(same_failures) >= 3:
        → 조기 종료 + "[Phase 3] 동일 실패 3회: {signature}. Root cause 보고." 출력
        → Phase 3 종료

    # Step C: Systematic Debugging D0-D4 (Iron Law #2 — Root cause 없이 수정 금지)
    # superpowers systematic-debugging 흡수: Architect 단순 진단 → D0-D4 체계 강화
    Agent(subagent_type="architect", name="diagnostician-{cycle}", description="Systematic Debugging D0-D4 진단",
         team_name="pdca-{feature}",
         prompt="[Phase 3 Systematic Debugging] QA 실패 Root Cause 분석 — D0-D4 체계.
                 실패 내역: {qa_failed_details}
                 이전 실패 이력: {failure_history 요약}

                 === Systematic Debugging Protocol (Iron Law #2) ===
                 D0 SYMPTOM: 증상 수집 — 에러 메시지, 실패 테스트, 로그 패턴 정리
                 D1 HYPOTHESIS: 가설 수립 — 가능한 원인 2-3개 나열, 우선순위 부여
                 D2 VERIFY: 가설 검증 — Grep/Read로 코드 확인, 가설별 증거 수집
                 D3 ROOT_CAUSE: Root Cause 확정 — 검증된 가설 기반 원인 1개 확정

                 === D0-D4 책임 분리 (v25.0) ===
                 D0: qa-runner 소유 (증상 보고)
                 D1-D3: architect 소유 (READ-ONLY 진단)
                 D4: domain-fixer 소유 (수정 계획+실행)

                 D4 FIX_PLAN: 수정 계획 — 파일명:라인 수준 구체적 수정 지시 (domain-fixer에게 전달)

                 반드시 다음 형식으로 출력하세요:
                 D0_SYMPTOM: {증상 요약}
                 D1_HYPOTHESIS: {가설 목록}
                 D2_EVIDENCE: {검증 증거}
                 D3_ROOT_CAUSE: {확정된 원인 1줄}
                 DIAGNOSIS: {root cause 1줄 요약}
                 FIX_GUIDE: {구체적 수정 지시 — 파일명:라인 수준}
                 DOMAIN: {UI|build|test|security|logic|other}

                 진단 없이 '이것저것 시도해보세요' 식의 모호한 지시는 금지.
                 가설→검증→확정 순서를 반드시 따르세요.")
    SendMessage(type="message", recipient="diagnostician-{cycle}", content="Root cause 진단 시작.")
    # 완료 대기 → shutdown_request

    # Step D: Domain-Smart Fix (Architect 진단 기반)
    domain = diagnostician 메시지에서 DOMAIN 추출
    diagnosis = diagnostician 메시지에서 DIAGNOSIS 추출
    fix_guide = diagnostician 메시지에서 FIX_GUIDE 추출

    # Domain Routing
    domain_agent_map = {
        "UI": "designer", "component": "designer", "style": "designer",
        "build": "build-fixer", "compile": "build-fixer", "type": "build-fixer",
        "test": "executor", "coverage": "executor",
        "security": "security-reviewer",
        "logic": "executor", "other": "executor"
    }
    agent_type = domain_agent_map.get(domain, "executor")

    Agent(subagent_type=agent_type, name="fixer-{cycle}", description="수정 실행",
         team_name="pdca-{feature}",
         prompt="[Phase 3 Domain Fix] 진단 기반 QA 실패 수정.
                 DIAGNOSIS: {diagnosis}
                 FIX_GUIDE: {fix_guide}
                 DOMAIN: {domain}
                 이전 실패 이력: {failure_history 요약}
                 수정 후 해당 검사를 재실행하여 통과를 확인하세요.")
    SendMessage(type="message", recipient="fixer-{cycle}", content="진단 기반 수정 시작.")
    # 완료 대기 → shutdown_request

    → 다음 cycle로 (Step A 재실행)

# Exit Condition 3: Max Cycles 도달
→ "[Phase 3] QA {max_cycles}회 도달. 미해결: {remaining_issues}" 출력
→ 사용자에게 미해결 이슈 보고
```

### 4종 Exit Conditions 상세

| 우선순위 | 조건 | 감지 방법 | 처리 |
|:--------:|------|----------|------|
| 1 | Environment Error | QA Runner가 "command not found", "PATH", "not installed" 패턴 보고 | 즉시 중단 + 환경 문제 보고 |
| 2 | Same Failure 3x | failure_history 내 동일 signature 3회 누적 | 조기 종료 + root cause 보고 |
| 3 | Max Cycles 도달 | cycle >= max_cycles | 미해결 이슈 목록 보고 |
| 4 | Goal Met | QA_PASSED 수신 | Step 3.2 이중 검증 진입 |

### Interactive Testing (v22.1 신규, --interactive 옵션 시)

`--interactive` 옵션 시 QA Runner의 goal 6(interactive)이 활성화됩니다:

```
# QA Runner 내부에서 직접 실행 (goal 6)
# tmux new-session -d -s qa-test
# tmux send-keys -t qa-test '명령어' Enter
# tmux capture-pane -t qa-test -p
# 결과를 QA_PASSED/QA_FAILED 형식으로 보고
```

> **주의**: Interactive testing은 tmux가 설치된 환경에서만 작동합니다.

### Step 3.1b: UI Layout Verification (자동 — 조건 충족 시)

**트리거 조건**: 아래 모두 충족 시 자동 실행
1. `docs/mockups/*.html` 1개 이상 존재
2. 현재 Build에서 CSS/SCSS 파일 변경 발생 (`git diff --name-only | grep -E '\.(css|scss)$'`)

**실행 내용**:

```python
# Lead 직접 실행 (에이전트 위임 없음)
import subprocess, json
from pathlib import Path

# 1. 트리거 조건 확인
mockups = list(Path("docs/mockups").glob("*.html"))
css_changed = subprocess.run(
    ["git", "diff", "--name-only"],
    capture_output=True, text=True
).stdout
has_css_change = any(f.endswith(('.css', '.scss')) for f in css_changed.splitlines())

if mockups and has_css_change:
    # 2. 각 목업에 대해 밸런스 측정
    for mockup in mockups:
        result = subprocess.run(
            ["python", "C:/claude/lib/mockup_hybrid/balance_checker.py", str(mockup)],
            capture_output=True, text=True
        )
        metrics = json.loads(result.stdout)

        if metrics["verdict"] == "FAIL":
            # QA 리포트에 밸런스 경고 포함
            balance_warnings.append(f"⚠️ {mockup.name}: {metrics['failures']}")

    # 3. Before/After 비교 (git diff에 CSS 포함 시)
    for mockup in mockups:
        rel_path = mockup.relative_to(Path.cwd())
        # git show main 버전 → temp 파일 → Playwright 캡처 → before.png
        # 현재 버전 → after.png
        # Vision AI 비교 → 변경 요약 1줄
```

**밸런스 기준 판정** (기본값):
- 열 높이 편차 ≤ 50px
- 정보 밀도 편차 ≤ 20%
- 여백 비율 25-35%
- 스크롤 필요 열 ≤ 1개

**결과 처리**:
- PASS → 로그만 출력 (`[Phase 3.1b] UI Balance: PASS`)
- FAIL → QA 리포트에 밸런스 경고 포함 (QA 사이클 실패로 취급하지 않음, 경고만)

**목업 일괄 갱신** (추가 조건: `docs/mockups/*.html` 2개+ 존재 + 공유 CSS 변경):
- Phase 2 BUILD 완료 직후 영향받는 목업 자동 업데이트 + 캡처

---

### Step 3.2: E2E 검증 + Architect 최종 검증

**E2E 인덱스 체크 (Step 3.2 진입 시 1회 평가):**

```
# E2E 실행 조건 인덱싱 — 3개 조건 모두 충족 시만 e2e_enabled = true
e2e_enabled = (
    mode != "LIGHT"                               # LIGHT 모드 아님
    and not skip_e2e                              # --skip-e2e 옵션 아님
    and Glob("playwright.config.{ts,js}")         # Playwright 설정 파일 존재
)
# e2e_enabled == false → E2E 관련 모든 단계 스킵 (Step 3.2.1, 3.2.3, 3.3 전체)
```

**LIGHT 모드: Architect teammate만 (E2E 스킵)**
```
Agent(subagent_type="architect", name="verifier", description="검증 실행", team_name="pdca-{feature}",
     prompt="구현된 기능이 docs/01-plan/{feature}.plan.md 요구사항과 일치하는지 검증.")
SendMessage(type="message", recipient="verifier", content="검증 시작. APPROVE/REJECT 판정 후 TaskUpdate 처리.")
# verifier 완료 대기 → shutdown_request
# e2e_enabled == false → Step 3.3 스킵
```

**STANDARD/HEAVY 모드: E2E 백그라운드 + Architect 최종 검증**
```
# Step 3.2.1: E2E 백그라운드 spawn (e2e_enabled 시 — 포그라운드 검증과 병렬)
if e2e_enabled:
    Agent(subagent_type="qa-tester", name="e2e-runner", description="E2E 테스트 실행", team_name="pdca-{feature}",
         prompt="[Phase 3 E2E Background] E2E 테스트 백그라운드 실행.
         1. 프레임워크 감지:
            - playwright.config.* -> npx playwright test --reporter=list
            - cypress.config.* -> npx cypress run --reporter spec
            - vitest.config.* (browser) -> npx vitest run --reporter verbose
         2. 감지된 프레임워크로 실행 (첫 번째 매칭 우선)
         3. 결과 요약: 총 테스트 수, PASS 수, FAIL 수
         4. 실패 시: 실패 테스트명 + 에러 메시지 (첫 3줄)
         5. 출력 형식: E2E_PASSED 또는 E2E_FAILED + 실패 상세 목록
         --strict 모드: {strict_mode} (true 시 1회 실패 즉시 E2E_FAILED 보고)")
    SendMessage(type="message", recipient="e2e-runner", content="E2E 백그라운드 실행 시작.")
    # ※ 완료 대기하지 않음 — 아래 포그라운드 검증과 병렬 진행

# Step 3.2.2: Architect 최종 검증 (포그라운드)
Agent(subagent_type="architect", name="verifier", description="검증 실행", team_name="pdca-{feature}",
     prompt="구현된 기능이 docs/01-plan/{feature}.plan.md 요구사항과 일치하는지 최종 검증 (type=FINAL).

             === Unified Verification Protocol (v25.0) ===
             이것은 FINAL 검증입니다. Phase 2.3 이후 변경된 delta만 검증하세요.
             이전 검증에서 APPROVE된 항목은 재검증하지 마세요.

             === Iron Law #3: Verification (MANDATORY) ===
             증거 없이 APPROVE 금지. 아래 증거를 반드시 수집하고 판정에 포함:
             - 빌드 결과 (exit code)
             - 테스트 결과 (pass/fail 수)
             - lint/type-check 결과
             VERDICT: APPROVE 또는 VERDICT: REJECT 형식으로 판정.")
SendMessage(type="message", recipient="verifier", content="검증 시작. APPROVE/REJECT 판정 후 TaskUpdate 처리.")
# verifier 완료 대기 → shutdown_request

# Step 3.2.3: E2E 결과 수집 (포그라운드 검증 완료 후)
if e2e_enabled:
    # e2e-runner는 이미 백그라운드에서 병렬 실행 중
    # Mailbox에서 e2e-runner 메시지 수신 대기
    # 이미 완료된 경우 → 즉시 수신 / 아직 실행 중 → 대기
    e2e_result = wait_for_message(from="e2e-runner")
    SendMessage(type="shutdown_request", recipient="e2e-runner")
    if e2e_result == "E2E_PASSED":
        # 정상 진행 → Step 3.3 스킵
        pass
    elif e2e_result == "E2E_FAILED":
        e2e_failures = e2e_result.failures
        if strict_mode:
            # --strict: 즉시 중단 + 실패 보고 → Phase 4 미진입
            report_e2e_failure(e2e_failures)
            return
        # 비-strict → Step 3.3 E2E 실패 처리 진입
```

**HEAVY 모드: 동일 구조 (Architect + E2E 백그라운드)**

HEAVY 모드에서도 Architect는 ``, e2e-runner는 `` 사용:
```
Agent(subagent_type="qa-tester", name="e2e-runner", description="E2E 테스트 실행", ..., ...)  # 백그라운드
Agent(subagent_type="architect", name="verifier", description="검증 실행", ..., ...)
```

- e2e-runner: E2E 테스트 (백그라운드 병렬 -- Playwright/Cypress/Vitest 자동 감지)
- Architect: Plan 대비 구현 일치 최종 검증 (APPROVE/REJECT)

> code-reviewer는 Phase 2 Step 2.2에서 이미 수행되었으므로 Phase 3에서는 생략합니다.

### Step 3.3: E2E 실패 처리 (e2e_enabled + E2E_FAILED 시만)

> **인덱싱**: `e2e_enabled == false` 또는 `E2E_PASSED`면 이 Step 전체를 스킵합니다.
> Step 3.2.3에서 E2E_FAILED를 수신한 경우에만 진입합니다.

**진입 조건 (모두 충족 시):**
- `e2e_enabled == true` (Step 3.2.0에서 평가)
- Step 3.2.3에서 `E2E_FAILED` 수신
- `strict_mode == false` (strict 시 Step 3.2.3에서 이미 중단)

**E2E 실패 수정 루프 (max 2회):**
```
e2e_fix_attempts = 0
max_e2e_fixes = 2

Loop (max_e2e_fixes):
    e2e_fix_attempts += 1

    # A. Architect E2E 실패 root cause 진단
    Agent(subagent_type="architect", name="e2e-diagnostician", description="E2E 진단", team_name="pdca-{feature}",
         prompt="[E2E Failure Diagnosis] Playwright E2E 테스트 실패 분석.
         실패 상세: {e2e_failures}
         1. 실패 root cause 식별 (UI 렌더링, 네트워크, 타이밍, 셀렉터 등)
         2. 수정 지침 (FIX_GUIDE) 작성
         3. DOMAIN 분류: UI/build/test/security/기타
         출력: DIAGNOSIS + FIX_GUIDE + DOMAIN")
    SendMessage(type="message", recipient="e2e-diagnostician", content="E2E 실패 진단 시작.")
    # 완료 대기 → shutdown_request

    # B. Domain-Smart Fix (Step 2.4 동일 라우팅)
    Agent(subagent_type="{domain-agent}", name="e2e-fixer", description="E2E 수정", team_name="pdca-{feature}",
         prompt="E2E 진단 기반 수정.
         DIAGNOSIS: {diagnosis}
         FIX_GUIDE: {fix_guide}
         수정 후 npx playwright test --reporter=list 로 검증.")
    SendMessage(type="message", recipient="e2e-fixer", content="E2E 수정 시작.")
    # 완료 대기 → shutdown_request

    # C. E2E 재실행
    Agent(subagent_type="qa-tester", name="e2e-rerun", description="E2E 재실행", team_name="pdca-{feature}",
         prompt="npx playwright test --reporter=list 재실행. E2E_PASSED 또는 E2E_FAILED 보고.")
    SendMessage(type="message", recipient="e2e-rerun", content="E2E 재실행 시작.")
    # 완료 대기 → shutdown_request

    if e2e_rerun_result == "E2E_PASSED":
        break  # 성공 → Phase 4 진입
    # E2E_FAILED → 다음 iteration

# 2회 초과: 미해결 E2E 실패 경고 포함하여 Phase 4 진입 허용
if e2e_fix_attempts >= max_e2e_fixes:
    warn("E2E 테스트 {len(e2e_failures)}건 미해결. Phase 4 보고서에 포함.")
```

**스킵 조건 (인덱싱 — Step 3.3 전체 비활성화):**
- `e2e_enabled == false` (LIGHT 모드, Playwright 미설치, `--skip-e2e`)
- Step 3.2.3에서 `E2E_PASSED` 수신
- `strict_mode == true` + `E2E_FAILED` (Step 3.2.3에서 이미 중단됨)

### Step 3.4: TDD 커버리지 보고 (있을 때만)

**Python 프로젝트:**
```bash
pytest --cov --cov-report=term-missing
```

**JavaScript/TypeScript 프로젝트:**
```bash
jest --coverage
```

**출력:** 커버리지 퍼센트, 미커버 라인 번호 (80% 미만 시 경고)

---

## Vercel BP 검증 규칙

Phase 2 Step 2.2에서 code-reviewer teammate prompt에 동적 주입하는 규칙:

> 상세: `.claude/references/vercel-bp-rules.md`
>
> 주입 시 해당 파일을 Read하여 code-reviewer prompt에 포함 (절대 경로: `C:\claude\.claude\references\vercel-bp-rules.md`)

**동적 주입 조건:**
- `Glob("next.config.*")` 결과 존재 또는 `package.json` 내 `"react"` dependency 존재 시 주입
- 웹 프로젝트가 아닌 경우 생략

---

## Phase 4: CLOSE (결과 기반 자동 실행 + 팀 정리)

### Phase 3↔4 루프 가드

```
phase3_reentry_count = 0  # Lead 메모리에서 관리
MAX_PHASE3_REENTRY = 3

# Phase 4 → Phase 3 재진입 시
phase3_reentry_count += 1
if phase3_reentry_count >= MAX_PHASE3_REENTRY:
    → "[Phase 4] Phase 3 재진입 {MAX_PHASE3_REENTRY}회 초과." 출력
    → 유의미 변경 커밋: git status --short → 변경사항 있으면 git add -A && git commit -m "wip({feature}): 루프 한계 초과 - 진행 중 변경사항 보존"
    → "미해결 이슈 보고 후 종료." 출력
    → TeamDelete()
```

### 누적 iteration 추적 (Lead 메모리)

```
cumulative_iteration_count = 0  # Phase 3-4 전체 누적
MAX_CUMULATIVE_ITERATIONS = 5

# executor 수정 실행 시
cumulative_iteration_count += 1
if cumulative_iteration_count >= MAX_CUMULATIVE_ITERATIONS:
    → "[Phase 4] 누적 {MAX_CUMULATIVE_ITERATIONS}회 개선 시도 초과. 최종 결과 보고." 출력
    → writer(reporter)
    → 유의미 변경 커밋: git status --short → 변경사항 있으면 git add -A && git commit -m "wip({feature}): 최대 개선 시도 후 현재 상태 보존"
    → TeamDelete()
```

| Check 결과 | 자동 실행 | 다음 |
|-----------|----------|------|
| gap < 90% | executor teammate (최대 5회 반복) | Phase 3 재실행 |
| gap >= 90% + Architect APPROVE | writer teammate | TeamDelete → 완료 |
| Architect REJECT | executor teammate (수정) | Phase 3 재실행 |

**Case 1: gap < 90%**
```
Agent(subagent_type="executor-high", name="iterator", description="반복 수정", team_name="pdca-{feature}",
     prompt="[Gap Improvement] 설계-구현 갭을 90% 이상으로 개선하세요. gap-checker 결과에서 미구현/불일치 항목을 식별하고 순차적으로 수정하세요. 최대 5회 반복.")
SendMessage(type="message", recipient="iterator", content="갭 자동 개선 시작.")
# 완료 대기 → shutdown_request → Phase 3 재실행
```

**Case 2: gap >= 90% + APPROVE**
```
# 보고서: LIGHT->writer(haiku), STANDARD/HEAVY->executor-high(opus)
Agent(subagent_type="writer", name="reporter", description="보고서 작성", team_name="pdca-{feature}",
     prompt="PDCA 사이클 완료 보고서를 생성하세요.
     포함: Plan 요약, Design 요약, 구현 결과, Check 결과, 교훈
     출력: docs/04-report/{feature}.report.md")
SendMessage(type="message", recipient="reporter", content="보고서 생성 요청.")
# 완료 대기 → shutdown_request
# 유의미 변경 커밋 (MANDATORY):
#   git status --short 확인
#   변경사항 있으면: git add -A && git commit -m "docs(report): {feature} PDCA 완료 보고서"
# → TeamDelete()
```

**Case 3: Architect REJECT**
```
Agent(subagent_type="executor-high", name="fixer", description="수정 실행", team_name="pdca-{feature}",
     prompt="Architect 거부 사유를 해결하세요: {rejection_reason}")
SendMessage(type="message", recipient="fixer", content="피드백 반영 시작.")
# 완료 대기 → shutdown_request → Phase 3 재실행
```

---

## `--slack` 옵션 워크플로우

Slack 채널의 모든 메시지를 분석하여 프로젝트 컨텍스트로 활용합니다.

**Step 1: 인증 확인**
```bash
cd C:\claude && python -m lib.slack status --json
```
- `"authenticated": false` -> 에러 출력 후 중단

**Step 2: 채널 히스토리 수집**
```bash
python -m lib.slack history "<채널ID>" --limit 100 --json
```

**Step 3: 메시지 분석 (Analyst Teammate)**
```
Agent(subagent_type="analyst", name="slack-analyst", description="Slack 분석", team_name="pdca-{feature}",
     prompt="SLACK CHANNEL ANALYSIS
     채널: <채널ID>
     분석 항목: 주요 토픽, 핵심 결정사항, 공유 문서 링크, 참여자 역할, 미해결 이슈, 기술 스택
     출력: 구조화된 컨텍스트 문서")
SendMessage(type="message", recipient="slack-analyst", content="Slack 채널 분석 요청.")
# 완료 대기 → shutdown_request
```

**Step 4: 컨텍스트 파일 생성**
`.claude/context/slack/<채널ID>.md` 생성 (프로젝트 개요, 핵심 결정사항, 관련 문서, 기술 스택, 미해결 이슈, 원본 메시지)

**Step 5: 메인 워크플로우 실행**
- 생성된 컨텍스트 파일을 Read하여 Phase 1 (PLAN)에 전달

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

---

## `--gmail` 옵션 워크플로우

Gmail 메일을 분석하여 프로젝트 컨텍스트로 활용합니다.

**사용 형식:**
```bash
/auto --gmail                           # 안 읽은 메일 분석
/auto --gmail "검색어"                   # Gmail 검색 쿼리로 필터링
/auto --gmail "작업 설명"                # 메일 기반 작업 실행
/auto --gmail "from:client" "응답 초안"  # 검색 + 작업 조합
```

**Step 1: 인증 확인 (MANDATORY)**
```bash
cd C:\claude && python -m lib.gmail status --json
```
- `"authenticated": true` → Step 2 진행
- `"authenticated": false` → **"Gmail 인증 실패. `python -m lib.gmail login` 실행 필요." 에러 출력 후 즉시 중단**

**Step 2: 메일 수집**

| 입력 패턴 | 실행 명령 |
|----------|----------|
| `--gmail` (검색어 없음) | `python -m lib.gmail unread --limit 20 --json` |
| `--gmail "from:..."` | `python -m lib.gmail search "from:..." --limit 20 --json` |
| `--gmail "subject:..."` | `python -m lib.gmail search "subject:..." --limit 20 --json` |
| `--gmail "newer_than:7d"` | `python -m lib.gmail search "newer_than:7d" --limit 20 --json` |

**Step 3: 메일 분석 (Analyst Teammate)**
```
Agent(subagent_type="analyst", name="gmail-analyst", description="Gmail 분석", team_name="pdca-{feature}",
     prompt="GMAIL ANALYSIS
     분석 항목: 요청사항/할일 추출, 발신자 우선순위, 회신 필요 메일, 첨부파일, 키워드 연관성, 리스크
     출력: 구조화된 이메일 분석 문서 (마크다운)")
SendMessage(type="message", recipient="gmail-analyst", content="Gmail 분석 요청.")
# 완료 대기 → shutdown_request
```

**Step 4: 컨텍스트 파일 생성**
`.claude/context/gmail/<timestamp>.md` 생성

**Step 5: 후속 작업 분기**

| 사용자 요청 | 실행 |
|------------|------|
| 검색만 | 분석 결과 출력 후 종료 |
| "응답 초안" | 각 메일에 대한 회신 초안 생성 |
| "할일 생성" | TaskCreate로 TODO 항목 생성 |
| 구체적 작업 | 메인 워크플로우 실행 (메일 컨텍스트 포함) |

**에러 처리**: Task 실패 시 에러 메시지 출력 + Phase 2 BUILD 중단. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

---

## `--interactive` 옵션 워크플로우

각 PDCA Phase 전환 시 사용자에게 확인을 요청합니다.

| Phase 전환 | 선택지 | 기본값 |
|-----------|--------|:------:|
| Phase 1 PLAN 완료 → Phase 2 BUILD | 진행 / 수정 / 건너뛰기 | 진행 |
| Phase 2 BUILD 완료 → Phase 3 VERIFY | 진행 / 수정 | 진행 |
| Phase 3 VERIFY 결과 → Phase 4 CLOSE | 자동 개선 / 수동 수정 / 완료 | 자동 개선 |

**Phase 전환 시 출력 형식:**
```
===================================================
 Phase {N} {이름} 완료 -> Phase {N+1} {이름} 진입 대기
===================================================
 산출물: {파일 경로}
 소요 teammates: {agent (model)}
 핵심 결정: [1줄 요약]
===================================================
```

**--interactive 미사용 시** (기본 동작): 모든 Phase를 자동으로 진행합니다.

**에러 처리**: AskUserQuestion 실패 시 기본값(진행)으로 자동 선택. 옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.

---

## `--con` 옵션 워크플로우

Markdown 파일을 Confluence Storage Format으로 변환하여 지정 페이지에 발행합니다.

```bash
/auto "기능 구현" --con <page_id>           # PRD/Plan 문서 자동 발행
/auto "기능 구현" --con <page_id> <file.md>  # 지정 파일 발행
```

### 파라미터

| 파라미터 | 필수 | 설명 |
|----------|:----:|------|
| `<page_id>` | YES | Confluence 페이지 ID (숫자) |
| `<file.md>` | NO | 발행할 MD 파일 경로. 미지정 시 PRD 또는 Plan 문서 자동 탐지 |

### 변환 파이프라인

```
MD 파일 읽기 → Mermaid 블록 추출 → mmdc PNG 렌더링
→ pandoc MD→HTML 변환 → HTML 후처리 (ac:image, table auto-width, p-wrap)
→ 첨부파일 업로드 → 페이지 본문 업데이트 (version +1)
```

### HTML 후처리 규칙

| 변환 | 설명 |
|------|------|
| `<img>` → `<ac:image>` | `<ri:attachment ri:filename="..."/>` 매크로 |
| 이미지 720px 제한 | 원본 너비 > 720px인 이미지에 `ac:width="720"` 속성 추가 (PIL 측정) |
| `<table>` | `data-layout="default"` auto-width 스타일링 |
| `<th>/<td>` 내용 | `<p>` 태그 래핑 (Confluence 필수) |

### 실행 스크립트

```bash
python lib/confluence/md2confluence.py <file.md> <page_id>
python lib/confluence/md2confluence.py <file.md> <page_id> --dry-run  # 미리보기
```

### 필수 도구 및 환경변수

| 도구 | 용도 |
|------|------|
| `pandoc` | MD→HTML |
| `mmdc` | Mermaid→PNG |
| `Pillow` | 이미지 너비 측정 (720px 제한) |
| `requests` | REST API |

> **인증**: 스크립트가 Windows User 환경변수에서 자동 로드 (winreg fallback). 셸 환경변수 사전 확인 불필요.

### 에러 처리

| 에러 | 처리 |
|------|------|
| 인증 실패 (401) | 환경변수 확인 안내 + 중단 |
| 페이지 미존재 (404) | page_id 확인 안내 + 중단 |
| mmdc 미설치 | Mermaid 블록을 코드 블록으로 유지 + 경고 |
| 이미지 파일 누락 | 누락 파일 목록 출력 + 나머지 계속 진행 |
| pandoc 실패 | 에러 메시지 출력 + 중단 |

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

### Step 2.0 통합 처리 흐름

```python
# 1. page_id 파라미터 파싱
page_id = options.get("con")  # 숫자 문자열

# 2. 발행 대상 파일 결정
if explicit_file:
    target = explicit_file
else:
    target = f"docs/00-prd/{feature}.prd.md"  # 또는 plan.md

# 3. 실행
# python lib/confluence/md2confluence.py <target> <page_id>

# 4. 결과 보고 (성공/실패 + 페이지 버전)
```

---

## /work 통합 안내 (완료)

`/work`는 `/auto`로 통합되었습니다 (v19.0).

| 기존 | 신규 | 상태 |
|------|------|------|
| `/work --loop` | `/auto` | 리다이렉트 완료 (v17.0) |
| `/work "작업"` | `/auto "작업"` | 리다이렉트 완료 (v19.0) |

**변경 없는 기능:**
- 5-Phase PDCA 워크플로우 동일
- 브랜치 자동 생성, 이슈 연동
- TDD 강제 규칙

**v20.1 변경:**
- 모든 에이전트 호출을 Agent Teams in-process 방식으로 전환
- Context 분리로 compact 실패 문제 근본 해결
- TeamCreate/TeamDelete 라이프사이클 추가
- Phase 1 Step 1.4 DESIGN: architect(READ-ONLY) → executor/executor-high(Write 가능)로 교체
- LIGHT Phase 3: Architect 검증 추가 (code-reviewer는 스킵)
- 토큰 사용량 약 1.5-2배 증가 (독립 context 비용)

**v22.1 변경:**
- Phase 1: Graduated Plan Review (LIGHT=Lead QG, STANDARD=Critic-Lite, HEAVY=A1-A6 adversarial 공격)
- Phase 2: Step 2.2 Architect Verification Gate (STANDARD/HEAVY 필수, 외부 검증)
- Phase 2: Step 2.3 Domain-Smart Fix Routing (designer/build-fixer/security-reviewer/executor)
- Phase 2: impl-manager Completion Promise 경고 추가
- Phase 3: QA Runner teammate로 Lead context 보호 (Lead 직접 QA → 위임)
- Phase 3: 6종 QA Goal (lint, test, build, typecheck, custom, interactive)
- Phase 3: Architect Root Cause 진단 필수 (맹목적 수정 금지)
- Phase 3: 4종 Exit Conditions 명시화 (Environment/Same3x/MaxCycles/GoalMet)
- Phase 3: Domain-Smart Fix Routing (Phase 2와 동일 패턴)
- Frontmatter agents 추가: qa-tester, build-fixer, security-reviewer, designer

**v21.0 변경:**
- `/auto` 내부 Skill() 호출 완전 제거 (ralplan, ralph, ultraqa → Agent Teams 단일 패턴)
- Phase 1 HEAVY: Skill(ralplan) → Planner-Critic Loop (max 5 iter)
- Phase 2 STD/HEAVY: Skill(ralph) → impl-manager 4조건 자체 루프 (max 10 iter)
- Phase 3 Step 3.1: Lead 직접 QA + Executor 수정 위임
- Phase 3 Step 3.2: code-reviewer에 Vercel BP 규칙 동적 주입
- State 파일 의존 0개 (Agent Teams lifecycle으로 대체)
- Stop Hook 충돌 자연 해소 (state 파일 미생성)
- `pdca-status.json`: `ralphIteration` → `implManagerIteration` 필드 변경

---

## Resume (`/auto resume`) — Context Recovery

`/clear` 또는 새 세션 시작 후:
1. `docs/.pdca-status.json` 읽기 → `primaryFeature`와 `phaseNumber` 확인
2. 산출물 존재 검증: Plan 파일, Design 파일 유무로 실제 진행 Phase 교차 확인
3. Git 상태 확인: `git branch --show-current`, `git status --short`
4. Phase 2 중단 시: `implManagerIteration` 필드로 impl-manager 반복 위치 확인
5. `TeamCreate(team_name="pdca-{feature}")` 새로 생성 (이전 팀은 복원 불가)
6. 해당 Phase부터 재개 (완료된 Phase 재실행 금지)

### Resume 시 impl-manager 재개

`pdca-status.json`에 추가되는 필드:
```json
{
  "implManagerIteration": 5,
  "implManagerStatus": "in_progress",
  "implManagerRemainingIssues": ["test failure in X", "lint error in Y"]
}
```

Resume 시:
- iteration 5회 미만 → 해당 지점부터 재개
- iteration 5회 이상 소진 → 처음부터 재시작
- impl-manager teammate를 새로 spawn하면서 prompt에 포함:
  ```
  "이전 시도에서 {N}회까지 진행됨. 남은 이슈: {remaining_issues}.
   이전 시도의 변경 사항은 이미 파일에 반영되어 있음. 이어서 진행."
  ```

### Agent Teams Context 장점

| 기존 (단일 context) | 신규 (Agent Teams) |
|-----------------|-------------------|
| 결과가 Lead context에 합류 → overflow | 결과가 Mailbox로 전달 → Lead context 보호 |
| foreground 3개 상한 필요 | 제한 없음 (독립 context) |
| "5줄 요약" 강제 필요 | 불필요 (context 분리) |
| compact 실패 위험 | compact 실패 없음 |

Context limit 발생 시: `claude --continue` 또는 `/clear` 후 `/auto resume`

---

## 자율 발견 모드 상세

| Tier | 이름 | 발견 대상 | 실행 |
|:----:|------|----------|------|
| 0 | CONTEXT | context limit 접근 | `/clear` + `/auto resume` 안내 |
| 1 | EXPLICIT | 사용자 지시 | 해당 작업 실행 |
| 2 | URGENT | 빌드/테스트 실패 | `/debug` 실행 |
| 3 | WORK | pending TODO, 이슈 | 작업 처리 |
| 4 | SUPPORT | staged 파일, 린트 에러 | `/commit`, `/check` |
| 5 | AUTONOMOUS | 코드 품질 개선 | 리팩토링 제안 |
