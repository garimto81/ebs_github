# 백로그 규칙

## Epic / Story 기준

| 구분 | 기준 | 예시 |
|------|------|------|
| **Epic** | 하나의 독립된 기능 영역 | 방송 셋업, 딜링, 베팅 액션, 쇼다운 |
| **Story** | Epic 안에서 독립적으로 완료/검증 가능한 단위 | 게임 타입 선택, 플레이어 시팅, 블라인드 설정 |

### Story 쪼개기 기준

- 독립적으로 완료 확인이 가능한가?
- 한 스프린트 안에 끝낼 수 있는 크기인가?
- 너무 크면 쪼개고, 너무 작으면 합친다

## UI 사용자

이 제품의 UI 사용자는 **오퍼레이터 1명**입니다. 오버레이는 출력 전용(인터랙션 없음)이므로, Story는 기능 단위로 작성합니다.

## Epic 문서 형식

```markdown
# Epic: {에픽 제목}

## 개요

{이 에픽이 다루는 범위와 목적}

## 근거 문서

- {참조하는 기획 문서 경로와 섹션}

## Stories

### S1. {스토리 제목}

- **Summary**: {한 줄 요약 — Jira 티켓 제목으로 사용}
- **Description**: {상세 설명}
- **Acceptance Criteria**:
  - [ ] {완료 조건 1}
  - [ ] {완료 조건 2}
- **Priority**: High / Medium / Low
- **Labels**: `{release 버전}`, `{관련 태그}`
```

## Priority 기준

| 등급 | 기준 |
|------|------|
| **High** | 이 Epic의 다른 Story가 의존하거나, 핵심 플로우에 필수 |
| **Medium** | 주요 기능이지만 다른 Story와 독립적 |
| **Low** | 부가 기능, 개선 사항, 있으면 좋은 것 |

## Labels

| Label | 용도 |
|-------|------|
| `release/vX.Y.Z` | 소속 릴리즈 버전 |
| 게임명 (예: `holdem`, `omaha`) | 관련 게임 |
| 기능 태그 (예: `overlay`, `rfid`, `betting`) | 관련 기능 영역 |

## 파일 구조

```
backlogs/
  ├── README.md                    # 백로그 인덱스 (전체 Epic/Story 목록 + 문서 버전)
  ├── epic-broadcast-setup.md
  ├── epic-dealing.md
  └── ...
```
