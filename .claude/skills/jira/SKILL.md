---
name: jira
version: 1.0.0
description: >
  This skill should be used when the user needs Jira project, board, Epic, or issue queries and structured analysis via Atlassian REST API.
triggers:
  keywords:
    - "--jira"
    - "jira"
    - "지라"
    - "epic"
    - "에픽"
---

# Jira 조회/분석 스킬 (`--jira`)

> `/auto "작업" --jira <command> <target>` — Jira 프로젝트, 보드, Epic, 이슈 조회 및 분석

## 개요

Jira REST API v3 + Agile API를 사용하여 프로젝트/보드/Epic/이슈를 조회하고 구조화된 분석 결과를 제공한다.
Confluence와 동일한 Atlassian API token 인증을 사용한다.

## 사용법

```
/auto "작업" --jira epics <board_id>          # 보드의 Epic 분석
/auto "작업" --jira project <key>             # 프로젝트 정보
/auto "작업" --jira board <id>                # 보드 정보
/auto "작업" --jira search "<jql>"            # JQL 검색
/auto "작업" --jira issue <key>               # 이슈 상세
```

### 파라미터

| 파라미터 | 필수 | 설명 |
|----------|:----:|------|
| `<command>` | YES | `epics`, `project`, `board`, `search`, `issue` |
| `<target>` | YES | board_id, project_key, issue_key, 또는 JQL 문자열 |

## 커맨드 상세

| 커맨드 | API | 설명 |
|--------|-----|------|
| `project <key>` | REST API v3 | 프로젝트 기본 정보 (이름, 리드, 스타일) |
| `board <id>` | Agile API | 보드 정보 (이름, 타입, 프로젝트) |
| `epics <board_id>` | Agile API + REST API v3 | Epic 목록 + Description 추출 + Story/Sub-task 분석 |
| `search "<jql>"` | REST API v3 | JQL 쿼리 결과 (이슈 목록) |
| `issue <key>` | REST API v3 | 이슈 상세 (ADF Description 포함) |

## 환경변수

| 변수 | 필수 | 설명 |
|------|:----:|------|
| `ATLASSIAN_EMAIL` | YES | Atlassian 계정 이메일 |
| `ATLASSIAN_API_TOKEN` | YES | Atlassian API 토큰 |
| `JIRA_BASE_URL` | NO | 기본값: `https://ggnetwork.atlassian.net` |

> **인증 우선순위**: 셸 환경변수 → Windows User 환경변수 (PowerShell fallback)

## 실행 스크립트

**핵심 스크립트**: `lib/jira/jira_client.py`

```bash
# 직접 실행
python lib/jira/jira_client.py epics 2049
python lib/jira/jira_client.py project PV
python lib/jira/jira_client.py search "project=PV AND issuetype=Bug"
python lib/jira/jira_client.py issue PV-6466
```

## /auto 통합 동작

`--jira` 옵션이 `/auto`에 전달되면 **Step 2.0 (옵션 처리)** 단계에서 실행:

1. command + target 파라미터 파싱
2. `lib/jira/jira_client.py <command> <target>` 실행
3. 결과를 컨텍스트로 수집 → 후속 작업에 활용
4. `epics` 커맨드 시 구조화된 분석 보고서 자동 생성

## 주요 기능

### ADF → 텍스트 변환
Jira Cloud의 Atlassian Document Format (ADF)을 자동으로 구조화된 텍스트로 변환:
- heading → `## 제목`
- bulletList → `- 항목`
- strong → `**볼드**`
- codeBlock → 코드 블록

### Epic 분석
`epics` 커맨드 실행 시:
- 보드의 모든 Epic 조회 (Agile API)
- 각 Epic의 Description에서 Story/Sub-task 구조 추출
- 하위 이슈 수 카운팅 (JQL)

## 이슈 타입 규칙 (HARD RULE)

| 규칙 | 설명 |
|------|------|
| **Story 생성 금지** | `issuetype: Story (10001)` 사용 절대 금지 |
| **허용 타입** | Epic (`10000`) 또는 작업 (`11514`) 만 사용 |
| **하위 이슈** | Epic 하위는 반드시 `작업 (11514)`으로 생성. `parent: {key: epic_key}` 연결 |
| **Component `[EBS]` 필수** | EBS 관련 이슈 생성 시 component에 `[EBS]` 항상 추가 |

```python
# CORRECT
EPIC_TYPE_ID = "10000"
TASK_TYPE_ID = "11514"   # 작업

# WRONG — 절대 금지
STORY_TYPE_ID = "10001"  # Story ← 사용 금지
```

## 에러 처리

| 에러 | 처리 |
|------|------|
| 인증 실패 (401) | 환경변수 확인 안내 + 중단 |
| 프로젝트/보드 미존재 (404) | key/id 확인 안내 + 중단 |
| API deprecated (410) | 엔드포인트 버전 안내 |
| 잘못된 JQL (400) | JQL 구문 오류 메시지 출력 |

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**
