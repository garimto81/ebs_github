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
- 이미 Jira에 올라간 티켓이 있는지 확인 (Summary로 JQL 검색)
- 신규 생성 대상 목록을 사용자에게 보여주고 확인 요청

### Step 3. Epic 생성

각 Epic 파일에서:

```
Jira 필드 매핑:
  - Project: PV
  - Issue Type: Epic
  - Summary: [EBS-AI][{Feature}] {Epic 이름}
  - Description: 개요 + 근거 문서 링크
  - Component: EBS
  - Labels: 버전, 관련 태그
```

### Step 4. Story 생성

각 Story에서:

```
Jira 필드 매핑:
  - Project: PV
  - Issue Type: Story
  - Summary: [EBS-AI][{Feature}][{Epic}] {설명}
  - Description: Description + References + Notes
  - Epic Link: Step 3에서 생성된 Epic
  - Component: EBS
  - Priority: High / Medium / Low
  - Labels: 버전, 관련 태그
  - Acceptance Criteria: AC 체크리스트 (Description에 포함)
```

### Step 5. Dependencies 연결

같은 Epic 내 Story 간 Dependencies가 있으면:

```
Jira Issue Link:
  - Type: "is blocked by" / "blocks"
  - 대상: 같은 Epic 내 해당 Story 티켓
```

### Step 6. 백로그 문서 업데이트

생성된 Jira 티켓 키를 백로그 문서에 기록:

```markdown
### S1. 게임 타입을 선택한다

- **Jira**: [PV-9999](https://ggnetwork.atlassian.net/browse/PV-9999)
- **Summary**: [EBS-AI][방송 셋업][게임 설정] 게임 타입을 선택한다
...
```

### Step 7. 결과 보고

- 생성된 Epic 수 / Story 수
- 각 티켓 키와 링크
- Dependencies 연결 결과
- 실패한 항목이 있으면 보고

## 주의사항

- 중복 생성 방지: Summary로 기존 티켓 검색 후 이미 있으면 스킵
- 생성 전 반드시 사용자 확인
- 실패 시 이미 생성된 티켓 목록 보고 (롤백은 수동)
