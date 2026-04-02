---
name: upload-jira
description: "백로그 문서를 Jira에 업로드하는 스킬. /upload-jira 형태로 실행. 사용자가 지라 업로드, Jira 생성, 티켓 생성을 언급할 때 트리거."
---

# /upload-jira

`backlogs/` 문서를 읽어서 Jira에 Epic/Story 티켓을 자동 생성합니다.

## 사용법

```
/upload-jira
```

## 전제 조건

- working 브랜치에서 실행해야 함
- `backlogs/` 디렉토리가 존재해야 함
- 백로그 문서가 backlog-convention 형식을 따라야 함

## 실행 순서

### Step 1. 현재 상태 확인

- working 브랜치인지 확인
- `backlogs/` 존재 여부 확인
- `backlogs/README.md`를 읽어 전체 구조 파악

### Step 2. 업로드 대상 확인

- 모든 Epic/Story 파일을 읽음
- 이미 백로그 문서에 `**Jira**:` 필드가 있는 Story는 **스킵** (이미 업로드됨)
- Jira에서 정확 일치 검색으로 중복 확인:
  ```
  JQL: summary = "[EBS-AI][방송 셋업] 게임 설정" AND project = PV
  ```
- 신규 생성 대상 목록을 사용자에게 보여주고 확인 요청

### Step 3. Jira 프로젝트 메타 확인

업로드 전 PV 프로젝트의 메타데이터를 확인합니다:

- `getJiraIssueTypeMetaWithFields`로 Epic/Story 생성에 필요한 필드 확인
- Epic Name 커스텀 필드가 있는지 확인 (있으면 Summary와 동일하게 설정)
- `getIssueLinkTypes`로 사용 가능한 링크 타입 확인 (Dependencies 연결용)

### Step 4. Epic 생성

각 Epic 파일에서:

```
Jira 필드 매핑:
  - Project: PV
  - Issue Type: Epic
  - Summary: [EBS-AI][{Feature}] {Epic 이름}
  - Description: 개요 + 근거 문서 링크 (Confluence 링크 포함)
  - Component: EBS
  - Labels: 버전, 관련 태그
  - Epic Name: Summary와 동일 (필드가 존재하는 경우)
```

### Step 5. Story 생성

각 Story에서:

```
Jira 필드 매핑:
  - Project: PV
  - Issue Type: Story
  - Summary: [EBS-AI][{Feature}][{Epic}] {설명}
  - Description: Description + References + Acceptance Criteria + Notes
  - Epic Link: Step 4에서 생성된 Epic
  - Component: EBS
  - Priority: High / Medium / Low
  - Labels: 버전, 관련 태그
```

> Description에 AC 체크리스트, References, Notes를 모두 포함하여 작성합니다.

### Step 6. Dependencies 연결

같은 Epic 내 Story 간 Dependencies가 있으면 Jira 이슈 링크로 연결합니다:

1. `getIssueLinkTypes`로 사용 가능한 링크 타입 조회
2. "Blocks" 또는 유사한 타입을 선택
3. `createIssueLink`로 연결

```
Jira Issue Link:
  - Type: "Blocks" (또는 프로젝트에서 사용 가능한 유사 타입)
  - Inward: 선행 Story (blocks)
  - Outward: 후행 Story (is blocked by)
```

### Step 7. 백로그 문서 업데이트

생성된 Jira 티켓 키를 백로그 문서의 각 Story에 기록합니다:

```markdown
### S1. 게임 타입을 선택한다

- **Jira**: [PV-9999](https://ggnetwork.atlassian.net/browse/PV-9999)
- **Summary**: [EBS-AI][방송 셋업][게임 설정] 게임 타입을 선택한다
...
```

Epic 파일 상단에도 Epic 티켓 키를 기록합니다:

```markdown
# Epic: [EBS-AI][방송 셋업] 게임 설정

- **Jira**: [PV-9998](https://ggnetwork.atlassian.net/browse/PV-9998)
```

업데이트 후 커밋:
```bash
git add backlogs/
git commit -m "backlog: Jira 티켓 키 연동 (PV-xxxx)"
```

### Step 8. 결과 보고

- 생성된 Epic 수 / Story 수
- 각 티켓 키와 링크
- Dependencies 연결 결과
- 스킵된 항목 (이미 존재)
- 실패한 항목이 있으면 보고

## 주의사항

- 중복 생성 방지: 백로그 문서의 `**Jira**:` 필드 + JQL 정확 일치 검색
- 생성 전 반드시 사용자 확인
- 실패 시 이미 생성된 티켓 목록 보고 (롤백은 수동)
- 재실행 안전: `**Jira**:` 필드가 있는 Story는 자동 스킵
