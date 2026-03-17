---
name: audit
description: Daily configuration audit and improvement suggestions
---

# /audit - 일일 설정 점검

CLAUDE.md, 커맨드, 에이전트, 스킬의 일관성과 품질을 점검합니다.

## Usage

```bash
/audit              # 통합 점검 (설정 + 프롬프트 품질·최적화 + 트렌드 + 자동 적용)
/audit config       # 설정 점검만
/audit issues       # GitHub 추적 이슈 상태 확인만
/audit quick        # 빠른 점검 (버전/개수만)
/audit deep         # 심층 점검 (내용 분석 포함)
/audit fix          # 발견된 문제 자동 수정
/audit baseline     # 현재 상태를 기준으로 저장

# 솔루션 추천
/audit suggest              # 전체 영역 솔루션 추천
/audit suggest security     # 보안 도구 추천
/audit suggest ci-cd        # CI/CD 도구 추천
/audit suggest code-review  # 코드 리뷰 도구 추천
/audit suggest mcp          # MCP 서버 추천
/audit suggest deps         # 의존성 관리 도구 추천
/audit suggest --save       # 추천 결과 저장
```

## 통합 워크플로우 (기본 동작)

`/audit` 단독 실행 시 설정 점검 + 프롬프트 품질 점검·최적화 + 트렌드 분석 + 자동 적용을 한번에 수행합니다.

```
/audit 실행
    │
    ├─ [Phase 1] 설정 점검 (9개 영역)
    │       ├─ [1/9] CLAUDE.md 점검
    │       ├─ [2/9] 커맨드 점검
    │       ├─ [3/9] 에이전트 점검
    │       ├─ [4/9] 스킬 점검
    │       ├─ [5/9] 문서 동기화 점검
    │       ├─ [6/9] GitHub 추적 이슈 상태 확인
    │       ├─ [7/9] Plugin Health Check (v24.0)
    │       ├─ [8/9] Skill TDD Audit (v24.0)
    │       └─ [9/9] Setup Audit (deep/HEAVY만)
    │
    ├─ [Phase 1.5] Prompt Quality Check + Auto-Optimize (필수)
    │       ├─ python -m prompt_learning.src eval --base-path C:/claude --json
    │       ├─ 규칙 기반 품질 점수 산출 (구조/명확성)
    │       ├─ 저점수 (< 70%) 프롬프트 자동 최적화 (dry-run)
    │       │   └─ python -m prompt_learning.src optimize --base-path C:/claude --dry-run
    │       └─ 최적화 제안 요약 출력 (적용 여부는 사용자 확인)
    │
    ├─ [Phase 2] 트렌드 분석 + 자동 적용
    │       ├─ [1/6] Gmail 인증 확인
    │       │       └─ 실패 시: Phase 2 스킵 (Phase 1 결과만 출력)
    │       ├─ [2/6] 임시보관함 브리핑 메일 수집
    │       │       └─ 없으면: "메일 없음" 표시 후 Phase 3으로
    │       ├─ [3/6] 트렌드 추출 + 갭 분석
    │       ├─ [4/6] 개선 아이디어 출력
    │       ├─ [5/6] 자동 적용 + 커밋
    │       └─ [6/6] 브리핑 메일 자동 삭제
    │
    └─ [Phase 3] 통합 결과 요약
            ├─ 설정 점검 결과
            ├─ 트렌드 분석 결과 (있을 경우)
            └─ 전체 건강도 점수
```

### Phase 간 연계 규칙

| 조건 | 동작 |
|------|------|
| [7/9] Plugin Health | 항상 실행. plugin-fusion-rules.md 기반 플러그인 건강도 점검 |
| [8/9] Skill TDD | 항상 실행. superpowers 17개 스킬 → /auto Phase 매핑 검증 |
| [9/9] Setup Audit | `/audit deep` 또는 HEAVY 모드 시만 실행. claude-code-setup 최적화 제안 |
| Phase 1.5 | 항상 실행. eval → 저점수 감지 시 optimize (dry-run) 자동 실행 |
| Gmail 인증 성공 + 메일 있음 | Phase 2 전체 실행 (분석 → 적용 → 커밋 → 삭제) |
| Gmail 인증 성공 + 메일 없음 | "브리핑 메일 없음" 표시, Phase 2 스킵 |
| Gmail 인증 실패 | Phase 2 전체 스킵, 안내 메시지 출력 |

### 통합 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Unified Audit Report - 2026-02-10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Phase 1] 설정 점검 (9항목)
  [1/9] ✅ CLAUDE.md: v12.0.0, 24 커맨드, 19 에이전트, 47 스킬
  [2/9] ✅ 커맨드: 24개 검사 완료
  [3/9] ✅ 에이전트: 19개 검사 완료
  [4/9] ✅ 스킬: 47개 검사 완료
  [5/9] ⚠️ 문서 동기화: 1개 불일치
  [6/9] 🔴 추적 이슈: 2개 OPEN (#28847, #28922)
  [7/9] ✅ Plugin Health: 5/5 플러그인 정상, Iron Laws 3/3 주입 확인
  [8/9] ✅ Skill TDD: 17/17 스킬 매핑 완료, Cross-cutting 3/3 확인
  [9/9] ⏭️ Setup Audit: 스킵 (deep/HEAVY만)

[Phase 1.5] Prompt Quality Check
  📊 스캔: 42 agent, 22 command, 35 skill (총 99개)
  📊 평균 점수: 82.3%
  ⚠️ 저점수: 3개 (< 70%)
  🔧 최적화 제안: 3개 (dry-run)
    - agent/writer: 61.2% → frontmatter 추가, 섹션 구조 보강
    - skill/deploy: 58.0% → 트리거 조건 명시 필요
    - command/auth: 65.5% → 모호 키워드 제거

[Phase 2] 트렌드 분석
  📬 브리핑 메일: 3개 수집
  📊 트렌드: 9개 (구현 7, 부분 1, 미구현 1)
  🔧 자동 적용: 1개 제안 적용 완료
  🗑️ 메일 삭제: 3개 완료

[종합]
  설정 건강도: 95%
  플러그인 건강도: 100% (5/5)
  스킬 매핑률: 100% (17/17)
  프롬프트 건강도: 82.3%
  워크플로우 성숙도: 78%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## /audit config - 설정 점검

`/audit config`로 설정 점검만 별도 실행할 수 있습니다. `/audit` 통합 실행의 Phase 1과 동일합니다.

### 1. CLAUDE.md 검사

| 항목 | 검사 내용 |
|------|----------|
| 버전 | 버전 번호 존재 여부 |
| 커맨드 개수 | 기재된 개수 vs 실제 파일 수 |
| 에이전트 개수 | 기재된 개수 vs 실제 파일 수 |
| 스킬 개수 | 기재된 개수 vs 실제 파일 수 |

### 2. 커맨드 검사 (`.claude/commands/*.md`)

| 항목 | 검사 내용 |
|------|----------|
| frontmatter | `---` 블록 존재 |
| name 필드 | `name:` 정의 |
| description 필드 | `description:` 정의 |
| Usage 섹션 | 사용법 문서화 |

### 3. 에이전트 검사 (`.claude/agents/*.md`)

| 항목 | 검사 내용 |
|------|----------|
| 역할 정의 | Role/역할 섹션 |
| 전문 분야 | Expertise/전문 분야 섹션 |
| 도구 정의 | Tools/도구 섹션 |

### 4. 스킬 검사 (`.claude/skills/*/SKILL.md`)

| 항목 | 검사 내용 |
|------|----------|
| SKILL.md | 파일 존재 |
| 트리거 조건 | trigger/트리거 정의 |

### 5. 문서 동기화 검사

| 문서 | 경로 | 검사 내용 |
|------|------|----------|
| COMMAND_REFERENCE.md | `docs/05-references/` | 모든 커맨드 포함 |
| AGENTS_REFERENCE.md | `docs/05-references/` | 모든 에이전트 포함 |

### 6. GitHub 추적 이슈 검사

`.claude/config/tracked-issues.json`에 등록된 GitHub 이슈의 상태를 확인합니다.

| 항목 | 검사 내용 |
|------|----------|
| 설정 파일 | `tracked-issues.json` 존재 여부 |
| 이슈 상태 | `gh issue view {number} -R {repo} --json state` 실행 |
| 상태 표시 | 🔴 OPEN / 🟢 CLOSED |

**실행 방법:**
```bash
# 각 이슈에 대해:
gh issue view <number> -R <repo> --json state,title,assignees,labels
```

**tracked-issues.json 구조:**
```json
{
  "issues": [
    {
      "repo": "anthropics/claude-code",
      "number": 28847,
      "label": ".claude.json race condition",
      "added": "2026-02-27",
      "reason": "v2.1.59 cascade amplification bug"
    }
  ]
}
```

**이슈 관리 명령:**
```bash
/audit issues                    # 추적 이슈 상태 확인
/audit issues add <repo>#<num> "<label>" "<reason>"   # 이슈 추가
/audit issues remove <num>       # 이슈 제거
```

### 7. Plugin Health Check (v24.0)

`references/plugin-fusion-rules.md` 기반으로 플러그인 활성화 상태를 점검합니다.

| 항목 | 검사 내용 |
|------|----------|
| 설치된 플러그인 | 5개 플러그인 존재 여부 (feature-dev, code-review, superpowers, claude-code-setup, typescript-lsp) |
| Project Type Detection | 프로젝트 루트 파일 기반 타입 감지 정확성 (package.json, tsconfig.json 등) |
| 복잡도-플러그인 매핑 | LIGHT/STANDARD/HEAVY별 활성화 플러그인이 fusion-rules와 일치 |
| Iron Laws 주입 | 3개 Iron Laws가 REFERENCE.md의 Gate 지점에 존재 |
| Phase 0.4 코드 | SKILL.md에 Plugin Activation Scan 섹션 존재 |

**검사 방법:**
```bash
# 플러그인 존재 확인
Glob(".claude/skills/*/SKILL.md")  # 로컬 스킬로 흡수된 플러그인
Grep("Iron Law", "REFERENCE.md")   # Iron Laws 주입 확인
Grep("Plugin Activation", "SKILL.md")  # Phase 0.4 섹션 확인
```

### 8. Skill TDD Audit (v24.0)

superpowers 17개 스킬이 /auto Phase에 올바르게 매핑되었는지 검증합니다.

| 항목 | 검사 내용 |
|------|----------|
| 스킬 매핑 완전성 | 17개 스킬 모두 Phase 매핑 존재 (fusion-rules.md §3) |
| 주입 시점 일치 | 각 스킬의 주입 시점이 SKILL.md/REFERENCE.md와 일치 |
| Cross-cutting 주입 | 3개 Iron Laws가 모든 Gate에 적용 |
| 미사용 스킬 감지 | 매핑은 있으나 실제 코드에서 참조 없는 스킬 |

**17개 스킬 체크리스트:**
```
Phase 0: using-superpowers
Phase 1: brainstorming, writing-plans, writing-skills
Phase 2: test-driven-development, subagent-driven-development,
         executing-plans, requesting-code-review,
         receiving-code-review, dispatching-parallel-agents,
         using-git-worktrees
Phase 3: systematic-debugging, verification-before-completion
Phase 4: finishing-a-development-branch
Cross:   verification-before-completion, test-driven-development,
         systematic-debugging
```

### 9. Setup Audit (v24.0, `/audit deep` 또는 HEAVY만)

claude-code-setup 플러그인의 automation-recommender를 활용한 설정 최적화 점검입니다.

| 항목 | 검사 내용 |
|------|----------|
| Hook 최적화 | 현재 Hook 구성의 효율성 및 누락 감지 |
| 에이전트 최적화 | 에이전트 정의 품질 및 역할 중복 |
| 스킬 최적화 | 스킬 트리거 충돌 및 커버리지 갭 |
| MCP 서버 | 설치된 MCP 서버 활용도 점검 |

**실행 조건:** `/audit deep` 또는 복잡도 HEAVY 모드에서만 실행 (일반 `/audit`에서는 스킵)

## 점검 흐름

```
/audit 실행
    │
    ├─ [1/9] CLAUDE.md 점검
    │       ├─ 버전 확인
    │       ├─ 커맨드 개수 일치
    │       ├─ 에이전트 개수 일치
    │       └─ 스킬 개수 일치
    │
    ├─ [2/9] 커맨드 점검
    │       ├─ 파일별 frontmatter
    │       └─ 필수 섹션 확인
    │
    ├─ [3/9] 에이전트 점검
    │       └─ 파일별 필수 섹션
    │
    ├─ [4/9] 스킬 점검
    │       └─ SKILL.md 존재 및 내용
    │
    ├─ [5/9] 문서 동기화 점검
    │       ├─ COMMAND_REFERENCE.md
    │       └─ AGENTS_REFERENCE.md
    │
    ├─ [6/9] GitHub 추적 이슈 점검
    │       ├─ .claude/config/tracked-issues.json 읽기
    │       └─ 각 이슈 gh issue view로 상태 확인
    │
    ├─ [7/9] Plugin Health Check (v24.0)
    │       ├─ 5개 플러그인 존재 확인
    │       ├─ Project Type Detection 검증
    │       ├─ 복잡도-플러그인 매핑 검증
    │       └─ Iron Laws 3개 주입 확인
    │
    ├─ [8/9] Skill TDD Audit (v24.0)
    │       ├─ 17개 스킬 Phase 매핑 검증
    │       ├─ 주입 시점 일치 확인
    │       └─ 미사용/미매핑 스킬 감지
    │
    └─ [9/9] Setup Audit (v24.0, deep/HEAVY만)
            ├─ automation-recommender 실행
            ├─ Hook/에이전트/스킬 최적화 제안
            └─ MCP 서버 활용도 점검
```

## 출력 형식

### 정상 시

```
🔍 Configuration Audit - 2025-12-12

[1/9] CLAUDE.md 점검...
  ✅ 버전: 10.1.0
  ✅ 커맨드: 14개 일치
  ✅ 에이전트: 18개 일치
  ✅ 스킬: 13개 일치

[2/9] 커맨드 점검...
  ✅ 14개 파일 검사 완료

[3/9] 에이전트 점검...
  ✅ 18개 파일 검사 완료

[4/9] 스킬 점검...
  ✅ 13개 디렉토리 검사 완료

[5/9] 문서 동기화 점검...
  ✅ COMMAND_REFERENCE.md 동기화됨
  ✅ AGENTS_REFERENCE.md 동기화됨

[6/9] GitHub 추적 이슈 점검...
  🔴 #28847 .claude.json race condition — OPEN (anthropics/claude-code)
  🔴 #28922 .claude.json corruption meta-bug — OPEN (anthropics/claude-code)

[7/9] Plugin Health Check...
  ✅ 5개 플러그인 감지됨
  ✅ Project Type: Python + Claude Code
  ✅ Iron Laws 3개 주입 확인

[8/9] Skill TDD Audit...
  ✅ 17/17 스킬 Phase 매핑 완료
  ✅ Cross-cutting 3개 주입 확인

[9/9] Setup Audit... (deep 모드 아님 — 스킵)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 모든 점검 통과
   총 검사: 9개 영역 (1개 스킵)
   문제: 0개 (추적 이슈 2개 OPEN)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 문제 발견 시

```
🔍 Configuration Audit - 2025-12-12

[1/9] CLAUDE.md 점검...
  ✅ 버전: 10.1.0
  ⚠️ 커맨드 개수 불일치: 문서 13개, 실제 14개
  ✅ 에이전트: 18개 일치
  ✅ 스킬: 13개 일치

[2/9] 커맨드 점검...
  ✅ 14개 파일 검사 완료

[3/9] 에이전트 점검...
  ✅ 18개 파일 검사 완료

[4/9] 스킬 점검...
  ✅ 13개 디렉토리 검사 완료

[5/9] 문서 동기화 점검...
  ⚠️ COMMAND_REFERENCE.md에 /audit 누락
  ✅ AGENTS_REFERENCE.md 동기화됨

[6/9] GitHub 추적 이슈 점검...
  🔴 #28847 .claude.json race condition — OPEN (anthropics/claude-code)
  🔴 #28922 .claude.json corruption meta-bug — OPEN (anthropics/claude-code)

[7/9] Plugin Health Check...
  ✅ 5개 플러그인 감지됨
  ⚠️ Iron Law #2 (Debugging) REFERENCE.md 주입 누락

[8/9] Skill TDD Audit...
  ✅ 17/17 스킬 Phase 매핑 완료
  ⚠️ writing-skills: Phase 1.3 매핑 있으나 REFERENCE.md 참조 없음

[9/9] Setup Audit... (deep 모드 아님 — 스킵)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ 4개 문제 발견 (추적 이슈 2개 OPEN)

1. CLAUDE.md 커맨드 개수 업데이트 필요
   현재: 13개 → 수정: 14개

2. COMMAND_REFERENCE.md 업데이트 필요
   누락: /audit

3. Iron Law #2 REFERENCE.md 주입 누락
   위치: Step 3.1 QA FAIL 시 Debugging D0-D4

4. writing-skills 스킬 REFERENCE.md 참조 누락
   위치: Phase 1.3 계획 수립

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
자동 수정을 실행할까요? (Y/N)
```

## 자동 수정 가능 항목

| 항목 | 자동 수정 | 설명 |
|------|----------|------|
| 개수 불일치 | ✅ | CLAUDE.md의 개수 숫자 업데이트 |
| 버전 업데이트 | ✅ | 패치 버전 자동 증가 |
| 문서 동기화 | ✅ | 누락된 항목 추가 |
| frontmatter 누락 | ❌ | 수동 작성 필요 |
| 내용 개선 | ❌ | 수동 검토 필요 |

**자동 수정 정책:**
- `/audit` (통합 실행): ✅ 항목은 사용자 확인 없이 즉시 자동 적용 + 커밋
- `/audit config`: 문제 발견 시 보고만 (수동 수정)
- `/audit fix`: ✅ 항목 즉시 자동 적용 + 커밋

## /audit deep - 심층 점검

추가로 다음을 검사합니다:

- 커맨드 간 중복 기능 감지
- 에이전트 역할 중복 검사
- 스킬 트리거 충돌 검사
- 사용되지 않는 파일 감지

## /audit baseline - 기준 상태 저장

현재 상태를 기준으로 저장하여 향후 Drift(변경) 감지에 활용합니다.

```bash
/audit baseline

# 출력:
# ✅ 기준 상태 저장됨
# 📁 .claude/baseline/config-baseline.yaml
# - CLAUDE.md: checksum abc123
# - 커맨드: 14개
# - 에이전트: 18개
# - 스킬: 13개
```

## 권장 사용 시점

| 시점 | 권장 명령 |
|------|----------|
| 매일 작업 시작 | `/audit` (통합 점검) |
| 빠른 상태 확인 | `/audit quick` |
| 설정만 점검 | `/audit config` |
| 주간 심층 점검 | `/audit deep` |
| 릴리즈 전 | `/audit deep` |
| 트렌드만 확인 | `/audit trend --dry-run` |

---

## /audit suggest - 솔루션 추천 (신규)

웹과 GitHub를 검색하여 현재 프로젝트에 적합한 최신 도구/솔루션을 추천합니다.

### 추천 영역

| 영역 | 검색 대상 | 추천 내용 |
|------|----------|----------|
| `security` | Snyk, Semgrep, Gitleaks | SAST, 의존성 취약점, 시크릿 스캐닝 |
| `ci-cd` | GitHub Actions, Spacelift, Harness | CI/CD 파이프라인, GitOps |
| `code-review` | Qodo Merge, CodeRabbit, Codacy | AI 코드 리뷰, 자동 PR 분석 |
| `mcp` | MCP Stack, Stainless | Claude Code MCP 서버 |
| `deps` | Dependabot, Renovate | 의존성 자동 업데이트 |

### 추천 흐름

```
/audit suggest [영역] 실행
    │
    ├─ [1/4] 현재 설정 분석
    │       ├─ MCP 서버 목록 (.claude.json)
    │       ├─ 사용 중인 도구 (ruff, pytest 등)
    │       └─ package.json / pyproject.toml
    │
    ├─ [2/4] GitHub 트렌드 검색
    │       ├─ gh api search/repositories
    │       └─ 스타 수, 최근 업데이트 기준
    │
    ├─ [3/4] 웹 검색 (Exa MCP)
    │       ├─ "[영역] best tools 2025"
    │       └─ 최신 블로그/문서 분석
    │
    └─ [4/4] 추천 리포트 생성
            ├─ 현재 스택과의 호환성
            ├─ Make vs Buy 분석
            └─ 설치/설정 가이드
```

### 출력 예시

```
🔍 Solution Recommendations - Security
Date: 2025-12-12

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 현재 상태
✅ 사용 중: ruff (린트), pip-audit (의존성)
⚠️ 부족: SAST, 시크릿 스캐닝

## 추천 솔루션

### 1. Snyk (⭐ 강력 추천)
├─ 용도: 의존성 취약점 + 컨테이너 보안
├─ GitHub Stars: 5.2K+
├─ 호환성: ✅ Python, Node.js 지원
└─ 설치:
   npm install -g snyk
   snyk auth && snyk test

### 2. Semgrep
├─ 용도: 커스텀 룰 기반 SAST
├─ GitHub Stars: 10K+
└─ 설치:
   pip install semgrep
   semgrep --config=auto .

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Make vs Buy 분석

| 항목 | Make | Buy (Snyk) |
|------|------|------------|
| 초기 비용 | 높음 | 낮음 |
| 유지보수 | 직접 | 자동 |
| 권장 | ❌ | ✅ |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sources:
- https://snyk.io/
- https://semgrep.dev/
```

### /audit suggest mcp - MCP 서버 추천

```
🔍 Solution Recommendations - MCP Servers

## 현재 MCP 설정
✅ context7, sequential-thinking, taskmanager, exa

## 추천 MCP 서버

### 1. github-mcp-server (⭐ 강력 추천)
├─ 용도: GitHub API 90+ 도구 통합
├─ 기능: PR, Issue, Actions, Releases
└─ 설치:
   claude mcp add github --transport http \
     https://api.githubcopilot.com/mcp/

### 2. postgres-mcp
├─ 용도: PostgreSQL 직접 쿼리
└─ 설치:
   claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres

## 워크플로우 개선 효과

| MCP 추가 | 개선되는 커맨드 |
|----------|----------------|
| github | /issue, /pr, /auto |
| postgres | /research code --deps |
```

### --save 옵션

추천 결과를 파일로 저장합니다.

```bash
/audit suggest security --save

# 저장 위치: .claude/research/audit-suggest-security-2025-12-12.md
```

---

## /audit trend - 트렌드 기반 워크플로우 개선 자동화

> **참고**: `/audit` 통합 실행에 `trend --apply`가 포함되어 있으므로, 별도로 트렌드만 실행하고 싶을 때 이 서브커맨드를 사용하세요.

Gmail 임시보관함의 Claude Code 브리핑 메일을 분석하여 현재 워크플로우와 비교하고, 개선 아이디어를 제안한 뒤 메일을 삭제합니다.

### Usage

```bash
/audit trend                    # 전체 워크플로우 (분석 → 제안 → 메일 삭제)
/audit trend --apply            # 완전 자동화 (분석 → 적용 → 커밋 → 메일 삭제)
/audit trend --dry-run          # 분석만 (메일 삭제 안 함)
/audit trend --save             # 분석 결과를 파일로 저장
```

### 워크플로우

```
/audit trend 실행
    │
    ├─ [1/5] Gmail 인증 확인
    │       └─ python -m lib.gmail status --json
    │       └─ 실패 시: "python -m lib.gmail login" 안내 후 중단
    │
    ├─ [2/5] 임시보관함 브리핑 메일 수집
    │       └─ python -m lib.gmail search "in:draft subject:Claude Code" --limit 10 --json
    │       └─ 메일 없으면: "브리핑 메일이 없습니다" 출력 후 종료
    │       └─ 각 메일 본문 읽기: python -m lib.gmail read "<id>" --json
    │       └─ 수집된 메일 ID 목록 보관 (삭제용)
    │
    ├─ [3/5] 트렌드 추출 + 현재 워크플로우 비교
    │       ├─ Analyst 에이전트로 메일 본문 분석
    │       │   └─ TeamCreate("audit-trend") → Task(name="analyst", team_name="audit-trend",
    │       │          subagent_type="analyst", model="sonnet") → TeamDelete()
    │       │
    │       ├─ 현재 워크플로우 인벤토리 수집
    │       │   ├─ 커맨드: .claude/commands/*.md 목록
    │       │   ├─ 스킬: .claude/skills/*/SKILL.md 목록
    │       │   ├─ 에이전트: .claude/agents/*.md 목록
    │       │   └─ 규칙: .claude/rules/*.md 목록
    │       │
    │       └─ 갭 분석 수행
    │           ├─ 이미 구현된 트렌드 (스킵)
    │           ├─ 부분 구현된 트렌드 (개선 제안)
    │           └─ 미구현 트렌드 (신규 제안)
    │
    ├─ [4/5] 개선 아이디어 제안 출력
    │       └─ 갭 분석 결과를 구조화된 보고서로 출력
    │       └─ --save 시: .claude/research/audit-trend-<date>.md 저장
    │
    └─ [5/5] 브리핑 메일 삭제 (--dry-run 아닐 때)
            └─ 사용자 확인: AskUserQuestion("N개 브리핑 메일을 삭제할까요?")
            └─ 승인 시: 각 메일 python -m lib.gmail trash "<id>"
            └─ 거부 시: "메일 유지됨" 출력
```

### 트렌드 분석 카테고리

| 카테고리 | 비교 대상 | 분석 내용 |
|---------|----------|----------|
| 에이전트 패턴 | 현재 에이전트 목록 | 새로운 에이전트 역할/체인 패턴 |
| 워크플로우 자동화 | 현재 커맨드/스킬 | CI/CD, Plan Mode 등 프로세스 개선 |
| 컨텍스트 관리 | /session, .omc/ | 세션 지속성, 메모리 관리 전략 |
| 모델 활용 | 현재 티어링 설정 | 모델별 최적 사용 사례 업데이트 |
| 커뮤니티 도구 | 현재 설치된 MCP/플러그인 | 인기 플러그인/도구 벤치마킹 |

### 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Trend Analysis Report - 2026-02-09
 소스: Gmail 브리핑 메일 3개 (2026-02-06 ~ 2026-02-08)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[트렌드 요약]
  총 트렌드: 9개
  이미 구현: 7개
  부분 구현: 1개
  미구현:    1개

[이미 구현 - 변경 불필요]
  1. CLI 모델 티어링 (Haiku/Sonnet/Opus) → OMC 32 에이전트 시스템
  2. 전문 에이전트 체인 → PDCA 워크플로우 (Planner→Architect→Executor)
  3. Plan Mode + 진행상황 기록 → PDCA docs/ 산출물
  4. 200K 컨텍스트 활용 → /session compact + Architect opus
  5. 반복 디버깅 → Ralph 루프 5개 조건
  6. 커스텀 스킬/Hooks 생태계 → 53개 스킬 + Hook 시스템
  7. Custom Instructions → CLAUDE.md + .claude/rules/ 10개

[부분 구현 - 개선 제안]
  1. 세션 간 의미론적 메모리
     현재: /session save + .omc/notepads/ (파일 기반)
     트렌드: ensue-skill (의미론적/시간적 DB 검색)
     제안: /session에 키워드 검색 기능 추가 검토

[미구현 - 신규 제안]
  1. GitHub Actions @claude 멘션 자동 반응
     현재: CLI 발동 Only (/pr, /issue)
     트렌드: @claude 멘션 → 자동 PR 생성, 코드 리뷰
     제안: /audit ci 서브커맨드로 설정 검사 + 템플릿 제안

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 성숙도: 78% (7/9 완전 구현)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 메일 삭제 확인

```
브리핑 메일 3개를 삭제할까요?
  - 2026-02-08: "Claude Code 관련 SNS 콘텐츠 일일 브리핑"
  - 2026-02-07: "Claude Code 관련 SNS 콘텐츠 일일 브리핑"
  - 2026-02-06: "Claude Code 관련 SNS 콘텐츠 일일 브리핑"

[삭제] / [유지]
```

### 검색 쿼리 커스터마이징

기본 검색 쿼리: `in:draft subject:Claude Code`

다른 브리핑 형식이 있는 경우:

```bash
/audit trend --query "in:draft subject:워크플로우 개선"
/audit trend --query "in:draft from:bot@company.com"
```

### `--apply` 완전 자동화 워크플로우

`--apply` 옵션은 기존 5단계에 **Step 4.5(자동 적용 + 커밋)**를 추가하여 6단계로 실행합니다.

```
/audit trend --apply 실행
    │
    ├─ [1/6] Gmail 인증 확인 (기존과 동일)
    ├─ [2/6] 임시보관함 브리핑 메일 수집 (기존과 동일)
    ├─ [3/6] 트렌드 추출 + 갭 분석 (기존과 동일)
    ├─ [4/6] 개선 아이디어 제안 출력 (기존과 동일)
    │
    ├─ [5/6] 자동 적용 + 커밋 (--apply 전용)
    │       ├─ 제안 중 복잡도 LOW/MEDIUM만 자동 적용 (HIGH는 별도 세션 안내)
    │       ├─ 각 제안별 executor 에이전트 위임
    │       │   └─ TeamCreate("audit-apply") → Task(name="applier", team_name="audit-apply",
    │       │          subagent_type="executor", model="sonnet",
    │       │          prompt="<제안 내용을 기반으로 파일 수정>") → TeamDelete()
    │       ├─ 적용 완료 후 변경 파일 확인
    │       │   └─ git diff --stat
    │       └─ Conventional Commit 생성
    │           └─ git add <변경 파일들>
    │           └─ git commit -m "feat(workflow): /audit trend 자동 적용 - <요약>"
    │
    └─ [6/6] 브리핑 메일 삭제 (사용자 확인 없이 자동 삭제)
```

**`--apply` 동작 규칙:**

| 규칙 | 내용 |
|------|------|
| 적용 대상 | 복잡도 LOW/MEDIUM 제안만 (파일 1-3개 수정) |
| HIGH 복잡도 | "별도 세션에서 처리 필요" 안내 후 스킵 |
| 커밋 메시지 | `feat(workflow): /audit trend 자동 적용 - <날짜>` |
| 메일 삭제 | 사용자 확인 없이 자동 (이미 적용 완료이므로) |
| 실패 시 | `git checkout -- .`으로 롤백 후 수동 처리 안내 |

**복잡도 판단 기준:**

| 복잡도 | 기준 | 자동 적용 |
|--------|------|----------|
| LOW | 설정값 변경, 파라미터 수정 (1파일) | ✅ |
| MEDIUM | 섹션 추가, 템플릿 수정 (2-3파일) | ✅ |
| HIGH | 새 스킬/커맨드 생성, 아키텍처 변경 (4+파일) | ❌ 스킵 |


---

## Related

- `/check` - 코드 품질 검사
- `/research web` - 웹 리서치
- `/session compact` - 세션 관리
- `docs/DAILY_IMPROVEMENT_SYSTEM.md` - 자동화 시스템 상세
