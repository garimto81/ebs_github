# 일하는 방식

## 이 저장소는 무엇인가

EBS 포커 방송 시스템의 **기획 문서 저장소**입니다. 기획자가 게임 규칙과 제품 스펙을 작성하고, 이를 기반으로 개발자/디자이너가 협업합니다.

## 전체 그림

```
기획자가 main에 선별/완성된 기획 문서를 넣음
    │
    │  게임 규칙, 제품 스펙, 시나리오 등
    │
    ▼
/kickoff vX.Y.Z 실행
    │
    │  working 브랜치 생성
    │  문서 → Epic/Story 백로그 변환
    │
    ▼
협업 진행 (working 브랜치)
    │
    │  개발자/디자이너가 백로그 기반 작업
    │  피드백 → 문서 수정도 working 브랜치에서
    │  백로그 → Jira 업로드
    │
    ▼
/deliver vX.Y.Z 실행
    │
    │  published/vX.Y.Z/ 에 확정 문서 정리
    │  release 브랜치 생성
    │
    ▼
release/vX.Y.Z (확정본)
```

## 핵심 개념

| 개념 | 설명 |
|------|------|
| **기획 문서** | 게임 규칙, 제품 스펙, 시나리오 등. 기획자가 선별/완성하여 main에 투입 |
| **킥오프** | 문서가 준비되면 working 브랜치를 생성하고 백로그를 만드는 행위 |
| **백로그** | 기획 문서를 Epic/Story로 쪼갠 협업 일감. Jira로 관리 |
| **딜리버리** | 개발/디자인 작업이 완료되어 제품에 반영된 상태 |

## 가이드 목록

| 가이드 | 내용 |
|--------|------|
| [브랜치 전략](branch-strategy.md) | main, working, release, foundation 브랜치 규칙 |
| [릴리즈 워크플로우](release-workflow.md) | /kickoff 스킬 사용법과 전체 흐름 |
| [버저닝 규칙](versioning.md) | 문서 버전, 릴리즈 버전, semver 기준 |
| [디렉토리 구조](directory-structure.md) | 폴더별 역할 설명 |
| [커밋 메시지 규칙](commit-convention.md) | type: 설명 형식 |
| [네이밍 규칙](naming-convention.md) | 파일, 폴더, 브랜치 네이밍 |
| [백로그 규칙](backlog-convention.md) | Epic/Story 기준, 형식, Jira 필드 |
