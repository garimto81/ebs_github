---
name: calendar
description: >
  This skill should be used when the user needs Google Calendar event management
  including listing, creating, deleting events, and checking today/week schedule.
version: 1.0.0

triggers:
  keywords:
    - "calendar"
    - "일정"
    - "schedule"
    - "event"
    - "today's events"
    - "오늘 일정"
    - "이번주 일정"
    - "google calendar"
    - "--calendar"
  context:
    - "일정 조회"
    - "일정 생성"
    - "캘린더 관리"
    - "회의 일정"

auto_trigger: true
---

# Google Calendar Skill

Google Calendar 이벤트 관리 스킬. `gws` CLI wrapper + Python API fallback 하이브리드.

## WebFetch 사용 금지 (CRITICAL)

`calendar.google.com` URL에 WebFetch 절대 금지. OAuth 2.0 인증 필요. Python API 또는 CLI 사용.

## 인증

| 파일 | 경로 |
|------|------|
| OAuth 클라이언트 | `C:\claude\json\desktop_credentials.json` |
| Calendar 토큰 | `C:\claude\json\token_calendar.json` |

미인증 시: `cd C:\claude && python -m lib.calendar login`

## CLI 사용법

```bash
# 인증
cd C:\claude && python -m lib.calendar login

# 상태 확인
cd C:\claude && python -m lib.calendar status

# 오늘 일정
cd C:\claude && python -m lib.calendar today

# 이번주 일정
cd C:\claude && python -m lib.calendar week

# 향후 N일 일정
cd C:\claude && python -m lib.calendar list --days 14

# 일정 검색
cd C:\claude && python -m lib.calendar list --query "회의"

# 일정 생성 (시간 지정)
cd C:\claude && python -m lib.calendar create "회의" "2026-03-15 14:00" "2026-03-15 15:00"

# 일정 생성 (종일)
cd C:\claude && python -m lib.calendar create "휴가" "2026-03-20"

# 캘린더 목록
cd C:\claude && python -m lib.calendar calendars

# JSON 출력
cd C:\claude && python -m lib.calendar today --json
```

## Python API 사용법

```python
from lib.calendar import CalendarClient, CreateEventRequest
from datetime import datetime

client = CalendarClient()

# 오늘 일정
events = client.today()

# 이번주 일정
events = client.week()

# 일정 생성
from lib.calendar.models import CreateEventRequest
req = CreateEventRequest(
    summary="회의",
    start_time=datetime(2026, 3, 15, 14, 0),
    end_time=datetime(2026, 3, 15, 15, 0),
)
event = client.create_event(req)
```

## 백엔드 선택 로직

| 조건 | 백엔드 | 이유 |
|------|--------|------|
| `gws` CLI 설치됨 | gws subprocess | JSON 출력, 빠른 실행 |
| `gws` 미설치 | Python Google API | 완전한 fallback |
| `gws` 호출 실패 | Python API 자동 전환 | 무중단 |

## 서브 프로젝트에서 사용 시

**반드시 루트에서 실행**: `cd C:\claude && python -m lib.calendar ...`

## Claude MCP Calendar 도구와의 관계

| 용도 | 도구 | 이유 |
|------|------|------|
| 대화형 일정 조회 | Claude MCP (`gcal_*`) | 즉시 가능, 인증 내장 |
| 자동화/배치 작업 | `lib.calendar` CLI | 스크립트 통합, JSON 출력 |
| `/auto` 워크플로우 | `lib.calendar` CLI | Agent Teams 통합 |

## Anti-Patterns

| 금지 | 대안 |
|------|------|
| WebFetch로 calendar.google.com 접근 | Python API 또는 CLI 사용 |
| token_calendar.json 커밋 | .gitignore 확인 |
