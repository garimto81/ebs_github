---
name: daily
description: >
  Daily Dashboard v3.0 - 3소스 통합 학습+액션 추천 엔진.
  Gmail/Slack/GitHub 증분 수집, AI 크로스소스 분석, 액션 초안 생성.
  프로젝트 전문가 모드 + Config Auto-Bootstrap.
version: 3.0.0

triggers:
  keywords:
    - "daily"
    - "오늘 현황"
    - "일일 대시보드"
    - "프로젝트 진행률"
    - "전체 현황"
    - "데일리 브리핑"
    - "morning briefing"
    - "아침 브리핑"
    - "daily-sync"
    - "일일 동기화"
    - "업체 현황"
    - "vendor status"
  file_patterns:
    - "**/daily/**"
    - "**/checklists/**"
    - "**/daily-briefings/**"
  context:
    - "업무 현황"
    - "프로젝트 관리"

capabilities:
  - daily_dashboard
  - incremental_collection
  - cross_source_analysis
  - action_recommendation
  - attachment_analysis
  - expert_context_loading
  - config_auto_bootstrap
  - gmail_housekeeping
  - slack_lists_update

model_preference: sonnet
auto_trigger: true
---

# Daily Skill v3.0 - 9-Phase Pipeline

3소스(Gmail/Slack/GitHub) 증분 수집 + AI 크로스소스 분석 + 액션 추천 엔진.

**패러다임**: "수집+표시" -> "학습+액션 추천"

**Design Reference**: `C:\claude\docs\02-design\daily-redesign.design.md`

## 실행 규칙 (CRITICAL)

**이 스킬이 활성화되면 반드시 아래 9-Phase Pipeline을 순차 실행하세요!**

```
Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
Config   Expert  Collect  Attach  AI     Action  Project  Gmail    State
Bootstrap Context  (incr)  Analyze Analyze Recom   Ops    Housekp  Update
```

---

## Phase 0: Config Bootstrap

CWD에서 `.project-sync.yaml`을 탐색하고, 없으면 자동 생성합니다.

**Step 0.1: 파일 탐색**

```
Read: .project-sync.yaml
# 없으면 Step 0.2로
# 있으면 version 필드 확인:
#   v1.0 → 호환 모드 (읽기만, meta.auto_generated=false 간주)
#   v2.0 + auto_generated=true → 자동 갱신 허용
#   v2.0 + auto_generated=false → 읽기만
```

**Step 0.2: 자동 생성 (파일 없을 때)**

```bash
# 프로젝트 식별
# 1순위: Read CLAUDE.md → 프로젝트명, 기술 스택, 목표 추출
# 2순위: Read README.md → fallback
# 3순위: 디렉토리명 사용

# 소스 탐색
python -m lib.gmail status --json          # Gmail 인증 + 이메일 주소
python -m lib.slack status --json          # Slack 인증 + 워크스페이스
gh auth status                             # GitHub 인증 + 레포

# 프로젝트 타입 자동 분류
# vendor_management: "업체", "vendor", "RFP", "견적" 키워드
# development: src/, package.json, setup.py 존재
# infrastructure: Dockerfile, terraform 존재
# research: docs/ 비중 높음
# content: "영상", "media", "upload" 키워드
```

Write `.project-sync.yaml` v2.0:
```yaml
version: "2.0"
project_name: "{auto-detected}"
meta:
  auto_generated: true
  confidence: 0.0-1.0
  generated_at: "ISO timestamp"
  pending_additions: []
daily:
  sources:
    gmail: { enabled: true/false }
    slack: { enabled: true/false, channel_id: "{fuzzy-matched}" }
    github: { enabled: true/false, repo: "{from git remote}" }
  project_type: "{auto-classified}"
```

**Error**: CLAUDE.md/README.md 모두 없으면 디렉토리명 기반 최소 설정 생성.

---

## Phase 1: Expert Context Loading

프로젝트 전문가 컨텍스트를 3-Tier로 구성합니다.

```
# Tier 1: Identity Context (500t)
Read: CLAUDE.md + .project-sync.yaml
→ 프로젝트명, 목표, 기술 스택, 핵심 용어, 데이터 소스, communication_style

# Tier 2: Operational Context (2000t)
Read: .omc/daily-state/<project>.json → learned_context 섹션
→ entities(업체, 사람, 상태), patterns(반복 패턴)

# Tier 3: Deep Context (3000t, 있을 때만)
Read: docs/ 핵심 문서 (README, PRD, 아키텍처)
Read: .omc/daily-state/<project>.learned-context.json
→ 도메인 지식, 이전 분석 결과 축적
```

Output: expert_context JSON (Phase 4, 5 prompt에 주입)

**Error**: CLAUDE.md 없으면 Tier 1 최소 구성. daily-state 없으면 Tier 2 생략 (초회).

---

## Phase 2: Incremental Data Collection

3소스에서 증분 수집합니다. `.omc/daily-state/<project>.json`에 커서를 저장하여 다음 실행 시 신규 데이터만 수집합니다.

**Step 0: 인증 확인**

```bash
python -m lib.gmail status --json    # authenticated, valid 확인
python -m lib.slack status --json    # authenticated, valid 확인
gh auth status                       # exit code 확인
```

인증 실패 소스는 이번 실행에서 skip. 활성 소스 0개면 에러 출력 후 중단.

**Step 1: Gmail 수집**

```python
from lib.gmail import GmailClient
client = GmailClient()

# 초회: historyId 시딩 + 7일 lookback
profile = client.get_profile()          # historyId 획득
emails = client.list_emails(query="newer_than:7d", max_results=50)

# 증분: History API
result = client.list_history(
    start_history_id=state["cursors"]["gmail"]["history_id"],
    history_types=["messageAdded"],
    max_results=100
)
# historyId 404 → list_emails(query="after:...") fallback
```

**Step 2: Slack 수집**

```python
from lib.slack import SlackClient
client = SlackClient()

# 초회: 7일 lookback
messages = client.get_history(channel=channel_id, limit=100, oldest=str(time.time()-604800))

# 증분: last_ts 이후
messages = client.get_history(channel=channel_id, limit=100, oldest=state["cursors"]["slack"]["last_ts"])
```

**Step 3: GitHub 수집**

```bash
gh issue list --since "{last_check}" --json number,title,state,author,updatedAt,labels
gh pr list --json number,title,state,author,updatedAt,reviewDecision
gh api repos/{owner}/{repo}/commits --jq '.[0:10] | .[] | {sha: .sha[0:7], message: .commit.message[0:80], date: .commit.author.date}'
```

---

## Phase 3: Attachment Analysis

Phase 2에서 수집된 이메일의 첨부파일을 AI로 분석합니다.

**대상 필터**: PDF, Excel, 이미지 (PNG/JPG)

**SHA256 캐시**: `state.cache.attachments[sha256]`에 이전 분석 결과 저장. 동일 첨부파일 재분석 방지.

**다운로드**:

```python
data = client.download_attachment(message_id, attachment_id)  # lib/gmail/client.py
```

**분석 방법**:

| 타입 | 조건 | 방법 |
|------|------|------|
| PDF (20p 이하) | `page_count <= 20` | Claude Read tool 직접 분석 |
| PDF (20p 초과) | `page_count > 20` | `lib/pdf_utils` PDFExtractor 청크 분할 후 분석 |
| Excel/CSV | - | 구조 요약 (행/열, 헤더, 샘플 5행) |
| 이미지 | PNG/JPG | Claude Vision 분석 |

**분석 관점**: expert_context.analysis_perspective 적용
- `vendor_management`: "견적서인가? 금액, 유효기간, 조건은?"
- `development`: "API 스펙인가? 변경점, breaking change는?"

**Error**: 다운로드 실패 → skip, PDF 암호화 → skip 후 보고

---

## Phase 4: AI Cross-Source Analysis

expert_context를 주입하여 프로젝트 전문가로서 분석합니다.

**Step 1: 소스별 독립 분석**

Claude가 Phase 2 raw data + Phase 3 첨부파일 분석 결과를 읽고 각 소스별 분석:

- **Gmail**: 발신자, 핵심 내용, 긴급도(URGENT/HIGH/MEDIUM/LOW), 필요 액션, 견적 정보, 상태 추론
- **Slack**: 의사결정 사항, 액션 아이템, 미해결 질문, 엔티티 매칭
- **GitHub**: PR 상태, 이슈 상태, CI/CD 상태

**Step 2: 크로스 소스 연결 분석**

소스 간 연결점 탐지:
1. 동일 주제 감지 (Gmail + Slack 동시 언급)
2. 액션 연결 (이메일 요청 → GitHub 이슈/PR)
3. 상태 불일치 (Gmail "완료" vs GitHub 이슈 open)
4. 타임라인 구성 (동일 주제의 소스별 이벤트 시간순 연결)

**Prompt 상세**: `docs/02-design/daily-redesign.design.md` Section 3.2, 3.3 참조

**Error**: 단일 소스만 활성 → 크로스 소스 분석 생략, 독립 분석만 수행

---

## Phase 5: Action Recommendation

분석 결과 기반으로 구체적 액션 초안을 생성합니다.

| 액션 유형 | 생성 조건 |
|----------|----------|
| 이메일 회신 초안 | 미응답 48h+, 견적 수신, 명시적 요청 |
| Slack 메시지 초안 | 미응답 질문, follow-up 필요 |
| GitHub 액션 | PR 리뷰 대기 3일+, 이슈 미응답 |

**톤 캘리브레이션**: `communication_style` 참조
- `email_tone`: professional / casual / formal
- `slack_tone`: casual / professional
- `language`: ko / en / mixed

**제한**: 최대 10건, URGENT → HIGH → MEDIUM 정렬, 각 액션에 예상 소요 시간 명시

**Prompt 상세**: `docs/02-design/daily-redesign.design.md` Section 3.4 참조

**Error**: 분석 결과 없으면 "현재 추가 액션이 필요하지 않습니다" 표시

---

## Phase 6: Project-Specific Operations

`.project-sync.yaml`의 `project_type`에 따라 조건부 실행합니다.

**vendor_management 타입**:
- Slack Lists 갱신 (ListsSyncManager)
- 업체 상태 자동 전이 (StatusInferencer)
- 견적 비교표 (QuoteFormatter)

```bash
cd {project_path} && python -c "
import sys; sys.path.insert(0, 'scripts/sync')
from lists_sync import ListsSyncManager
manager = ListsSyncManager()
manager.update_item('{vendor}', status='{status}', quote='{quote}', last_contact='{date}')
manager.generate_summary_message()
manager.post_summary()
"
```

**development 타입**:
```bash
gh run list --limit 5 --json databaseId,status,conclusion,name,createdAt
gh pr list --state open --json number,title,headRefName,updatedAt
gh api repos/{owner}/{repo}/milestones --jq '.[] | {title, open_issues, closed_issues}'
```

**Error**: config_file 없으면 Phase 6 skip. Slack Lists API 실패 → 경고 출력 후 계속.

---

## Phase 7: Gmail Housekeeping

`.project-sync.yaml`의 `housekeeping` 설정에 따라 Gmail 정리합니다.

**7a. 라벨 자동 적용** (`gmail_label_auto: true`):
- Phase 2 이메일 중 라벨 없는 것 필터
- vendor_domains 매칭 시 자동 라벨 적용
- 시스템 메일 제외 (noreply, notifications, drive-shares)

**7b. INBOX 정리** (`inbox_cleanup` 설정):

| 모드 | 동작 |
|------|------|
| `"auto"` | 자동 archive |
| `"confirm"` | 대상 목록 표시 후 AskUserQuestion으로 확인 |
| `"skip"` | 건너뜀 (기본) |

**Error**: Gmail API 실패 → 해당 동작 skip, 경고 출력

---

## Phase 8: State Update

**Phase A (수집 직후 - 커서 기록)**:
```python
state["cursors"]["gmail"]["history_id"] = new_history_id
state["cursors"]["gmail"]["last_timestamp"] = datetime.utcnow().isoformat() + "Z"
state["cursors"]["slack"]["last_ts"] = last_message_ts
state["cursors"]["github"]["last_check"] = datetime.utcnow().isoformat() + "Z"
state["last_run"] = datetime.utcnow().isoformat() + "Z"
state["run_count"] += 1
```

**Phase B (분석 후 - 캐시 + 학습 기록)**:
```python
state["cache"]["attachments"][sha] = analysis  # 첨부파일 캐시
state["learned_context"]["entities"].update(new_entities)
state["learned_context"]["patterns"].extend(new_patterns)
```

**Config 자동 갱신** (`auto_generated: true`인 경우만):
- 새 도메인 감지 시 `pending_additions`에 추가

**Error**: 파일 쓰기 실패 → 다음 실행에서 동일 데이터 재수집 (데이터 손실 없음)

---

## 출력 형식

```
================================================================================
                   Daily Dashboard v3.0 (YYYY-MM-DD Day)
                   프로젝트: {project_identity}
================================================================================

[소스 현황] --------------------------------------------------------
  Gmail: {N}건 ({new}건 신규) {auth_status}
  Slack: {N}건 ({new}건 신규) {auth_status}
  GitHub: 이슈 {N}건, PR {N}건 {auth_status}

[크로스 소스 인사이트] ------------------------------------------------
  1. {topic}: {insight} (소스: Gmail+Slack)

[액션 아이템] --------------------------------------------------------

  URGENT ({N}건)
  #{id}. [{type}] {target}
     초안: {draft_preview}
     소요: {estimated_time} | 사유: {reason}

  HIGH ({N}건)
  #{id}. [{type}] {target}
     초안: {draft_preview}
     소요: {estimated_time} | 사유: {reason}

[소스별 상세] --------------------------------------------------------
  Gmail / Slack / GitHub 각 상세

[첨부파일 분석] --------------------------------------------------------
  * {filename}: {summary}

================================================================================
  총 액션: {total}건 | 예상 소요: 약 {total_time}분
  다음 실행 시: 증분 수집 (커서 저장됨)
================================================================================
```

**vendor_management 추가 섹션**: 업체 현황표, 견적 비교, Slack Lists 갱신 결과
**development 추가 섹션**: CI/CD 상태, 브랜치 상태, 마일스톤 진행률

---

## 서브커맨드

| 커맨드 | 설명 |
|--------|------|
| `/daily` | 전체 대시보드 (9-Phase 전체) |
| `/daily ebs` | EBS 데일리 브리핑 (기존 EBS 전용 워크플로우) |

### EBS 브리핑 모드

`/daily ebs`는 기존 EBS 전용 워크플로우를 유지합니다.

```bash
cd C:\claude\ebs\tools\morning-automation && python main.py --post
```

상세 워크플로우: 이전 v2.0.0 EBS 섹션과 동일.

---

## 변경 이력

| 버전 | 변경 |
|------|------|
| 3.0.0 | 9-Phase Pipeline 전면 재설계. Secretary 의존 제거. 증분 수집, 첨부파일 AI 분석, 크로스소스 분석, 액션 추천 엔진, Config Auto-Bootstrap, Expert Context Loading 추가. daily-sync 기능 흡수. |
| 2.0.0 | EBS 브리핑 모드 통합 (`/daily ebs`) |
| 1.1.0 | 스킬 체인 연동 (Gmail, Secretary) |
| 1.0.0 | 초기 릴리스 |
