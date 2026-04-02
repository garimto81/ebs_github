# 백로그 규칙

## 계층 구조

| 구분 | 기준 | 제목 패턴 |
|------|------|----------|
| **Feature** | 큰 기능 영역 | `[EBS] {Feature}` |
| **Epic** | Feature 안의 독립된 하위 영역 | `[EBS][{Feature}] {Epic}` |
| **Story** | Epic 안에서 독립적으로 완료/검증 가능한 단위 | `[EBS][{Feature}][{Epic}] {설명}` |

### 예시

```
Feature: [EBS] 방송 셋업
  Epic:    [EBS][방송 셋업] 게임 설정
    Story:   [EBS][방송 셋업][게임 설정] 게임 타입을 선택한다
    Story:   [EBS][방송 셋업][게임 설정] RFID 덱을 매핑한다
  Epic:    [EBS][방송 셋업] 플레이어 관리
    Story:   [EBS][방송 셋업][플레이어 관리] 좌석을 배치한다
    Story:   [EBS][방송 셋업][플레이어 관리] 칩을 설정한다
  Epic:    [EBS][방송 셋업] 베팅 설정
    Story:   [EBS][방송 셋업][베팅 설정] 블라인드를 설정한다
    Story:   [EBS][방송 셋업][베팅 설정] Ante 유형을 선택한다
```

### 쪼개기 기준

- Feature가 너무 크면 Epic으로 나눈다
- Epic이 너무 크면 Story로 나눈다
- Story는 독립적으로 완료 확인이 가능해야 한다
- Story는 한 스프린트 안에 끝낼 수 있는 크기여야 한다

## UI 사용자

이 제품의 UI 사용자는 **오퍼레이터 1명**입니다. 오버레이는 출력 전용(인터랙션 없음)이므로, Story는 기능 단위로 작성합니다.

## 문서 형식

### Feature 파일

```markdown
# Feature: [EBS] {Feature 이름}

## 개요

{이 Feature가 다루는 범위와 목적}

## 근거 문서

- [{기획 문서 경로}]({경로}) — [Confluence]({Confluence 링크})

## Epics

| Epic | Stories | 설명 |
|------|:-------:|------|
| [{Epic 이름}](epic-{슬러그}.md) | N개 | 설명 |
```

### Epic 파일

```markdown
# Epic: [EBS][{Feature}] {Epic 이름}

## 개요

{이 에픽이 다루는 범위와 목적}

## 근거 문서

- [{기획 문서 경로}]({경로}) — [Confluence]({Confluence 링크})

## Stories

### S1. {스토리 설명}

- **Summary**: [EBS][{Feature}][{Epic}] {스토리 설명}
- **Description**: 
  {상세 설명. 기획 문서의 어떤 부분을 구현하는지, 
  어떤 동작이 기대되는지 구체적으로 기술}
- **References**:
  - [{문서 경로} {섹션}]({경로}) — [Confluence]({링크})
- **Acceptance Criteria**:
  - [ ] {완료 조건 — 구체적이고 검증 가능하게}
  - [ ] {엣지 케이스 포함}
- **Priority**: High / Medium / Low
- **Labels**: `{버전}`, `{관련 태그}`
- **Notes**: {기술 참고 사항, 기획에 빠진 부분 지적 등}
```

### Story 상세도 기준

Story는 **받는 사람이 바로 작업에 들어갈 수 있는 수준**으로 작성합니다:

- Description에 기획 문서의 관련 섹션을 구체적으로 명시
- References에 저장소 문서 경로 + Confluence 링크 병기
- AC는 정상 케이스 + 엣지 케이스 모두 포함
- 기획에 명시되지 않았지만 구현에 필요한 부분은 Notes에 기재

## Priority 기준

| 등급 | 기준 |
|------|------|
| **High** | 다른 Story가 의존하거나, 핵심 플로우에 필수 |
| **Medium** | 주요 기능이지만 다른 Story와 독립적 |
| **Low** | 부가 기능, 개선 사항, 있으면 좋은 것 |

## Labels

| Label | 용도 |
|-------|------|
| `vX.Y.Z` | 소속 버전 |
| 게임명 (예: `holdem`, `omaha`) | 관련 게임 |
| 기능 태그 (예: `overlay`, `rfid`, `betting`) | 관련 기능 영역 |

## 파일 구조

```
backlogs/
  ├── README.md                              # 백로그 인덱스
  ├── feature-broadcast-setup.md             # Feature 파일
  ├── epic-broadcast-setup-game-config.md    # Epic 파일
  ├── epic-broadcast-setup-player-mgmt.md
  ├── feature-hand-lifecycle.md
  ├── epic-hand-lifecycle-dealing.md
  └── ...
```
