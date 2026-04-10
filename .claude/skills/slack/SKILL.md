---
name: slack
description: >
  Slack 메시징 스킬. Browser OAuth 인증, 메시지 전송/수신, 채널 관리.
  "slack", "슬랙 메시지", "slack 전송" 요청 시 사용.
version: 1.0.0
triggers:
  keywords:
    - "slack"
    - "슬랙"
    - "slack message"
    - "슬랙 메시지"
    - "send to slack"
    - "slack 전송"
    - "slack 채널"
    - "slack login"
    - "slack 인증"
  patterns:
    - "slack (login|send|history|channels|user|status)"
    - "슬랙.*(보내|전송|읽|채널)"
  file_patterns:
    - "**/slack*.py"
    - "**/slack_*.json"
  context:
    - "Slack 연동"
    - "채널 메시지"
    - "팀 커뮤니케이션"
capabilities:
  - slack_oauth
  - send_message
  - read_history
  - list_channels
  - get_user_info
model_preference: sonnet
auto_trigger: true
---

# Slack Skill

Slack API 연동 스킬. Browser OAuth 2.0 인증, 메시지 전송/수신, 채널 관리 기능 제공.

## Prerequisites

### 1. Slack App 생성

1. https://api.slack.com/apps 접속
2. "Create New App" > "From scratch"
3. App Name 입력, Workspace 선택
4. "OAuth & Permissions" 메뉴 이동

### 2. Redirect URL 설정

**OAuth & Permissions** 페이지에서 **Redirect URLs** 섹션에 추가:
```
http://localhost:8765/slack/oauth/callback
```

### 3. OAuth Scopes 설정

Bot Token Scopes에 다음 추가:
- `chat:write` - 메시지 전송
- `channels:read` - 공개 채널 목록
- `channels:history` - 공개 채널 히스토리
- `groups:read` - 비공개 채널 목록
- `groups:history` - 비공개 채널 히스토리
- `im:write` - DM 전송
- `users:read` - 사용자 정보

### 4. Credentials 저장

`C:\claude\json\slack_credentials.json` 파일 생성.

**방법 A: Bot Token 직접 입력 (권장 - 간단함)**

```json
{
  "bot_token": "xoxb-YOUR-BOT-TOKEN"
}
```

Bot Token은 **OAuth & Permissions** 페이지 상단의 **Bot User OAuth Token** 복사.

**방법 B: OAuth 인증 (브라우저 팝업)**

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```

Client ID/Secret은 "Basic Information" 페이지에서 확인.

### 5. 인증 실행

```powershell
python -m lib.slack login
```

- **Bot Token 방식**: 즉시 검증 후 완료
- **OAuth 방식**: 브라우저가 열리고 Slack 인증 후 토큰 자동 저장

## Commands

| Command | Description |
|---------|-------------|
| `python -m lib.slack login` | OAuth 인증 (최초 1회) |
| `python -m lib.slack status` | 인증 상태 확인 |
| `python -m lib.slack send <channel> <message>` | 메시지 전송 |
| `python -m lib.slack update <channel> <ts> <message>` | 기존 메시지 갱신 |
| `python -m lib.slack history <channel>` | 메시지 히스토리 |
| `python -m lib.slack channels` | 채널 목록 |
| `python -m lib.slack user <user_id>` | 사용자 정보 |
| `python -m lib.slack list-items <list_id>` | Slack List 항목 조회 |
| `python -m lib.slack list-add <list_id> <title>` | Slack List에 항목 추가 |

## Usage Examples

### 메시지 전송

```powershell
# 채널에 메시지 전송
python -m lib.slack send "#general" "Hello, world!"

# 스레드 답장
python -m lib.slack send "C01234567" "Reply" --thread "1234567890.123456"
```

### 메시지 읽기

```powershell
# 최근 10개 메시지
python -m lib.slack history "#general" --limit 10

# 기본 100개
python -m lib.slack history "C01234567"
```

### 채널 목록

```powershell
# 공개 채널만
python -m lib.slack channels

# 비공개 포함
python -m lib.slack channels --private
```

## Python API

```python
from lib.slack import SlackClient, login, get_token

# 인증 (최초 1회)
login()

# 클라이언트 생성
client = SlackClient()

# 메시지 전송
result = client.send_message("#general", "Hello!")
print(result.permalink)

# 히스토리 읽기
messages = client.get_history("#general", limit=10)
for msg in messages:
    print(f"{msg.user}: {msg.text}")

# 채널 목록
channels = client.list_channels(include_private=True)
for ch in channels:
    print(f"#{ch.name} ({ch.id})")
```

## Claude 강제 실행 규칙 (MANDATORY)

**Slack 키워드 감지 시 Claude는 반드시 다음을 자동으로 수행해야 합니다.**

### Step 1: 인증 상태 확인 (항상 먼저)

```powershell
cd C:\claude && python -m lib.slack status --json
```

**결과 해석:**
- `"authenticated": true, "valid": true` → Step 2로 진행
- `"authenticated": false` → 사용자에게 로그인 안내:
  ```
  Slack 인증이 필요합니다. 다음 명령을 실행하세요:
  python -m lib.slack login
  ```

### Step 2: 요청별 명령 실행

| 사용자 요청 | 실행할 명령 |
|-------------|-------------|
| "채널 목록 보여줘" | `python -m lib.slack channels --json` |
| "비공개 채널 포함" | `python -m lib.slack channels --private --json` |
| "메시지 보내줘" | `python -m lib.slack send "#채널" "메시지"` |
| "메시지 읽어줘" | `python -m lib.slack history "채널" --limit 20 --json` |
| "사용자 정보" | `python -m lib.slack user "U12345" --json` |
| "슬랙 분석해줘" | 채널 목록 조회 후 각 채널별 history 분석 |

### Step 3: JSON 결과 파싱 및 응답

`--json` 플래그 출력을 파싱하여 사용자에게 읽기 쉬운 형태로 응답합니다.

**예시 - 채널 목록:**
```json
{"count": 5, "channels": [{"id": "C123", "name": "general", ...}]}
```
→ "5개 채널이 있습니다: #general, #random, ..."

### 필수 행동 (MUST)

| 규칙 | 설명 |
|------|------|
| ✅ `cd C:\claude &&` 접두사 | 프로젝트 루트에서 모듈 실행 |
| ✅ `--json` 플래그 사용 | 결과 파싱 용이 |
| ✅ Bash tool 직접 사용 | lib/slack CLI 실행 |
| ✅ 에러 발생 시 상세 안내 | 인증 방법, 봇 초대 방법 등 |

### 금지 행동 (NEVER)

| 금지 | 이유 |
|------|------|
| ❌ slack_token.json 직접 읽기 | 보안 위험 |
| ❌ WebFetch로 Slack API 호출 | OAuth 토큰 필요 |
| ❌ "인프라가 없습니다" 응답 | Bash로 직접 CLI 실행 가능 |
| ❌ 사용자에게 수동 실행 요청 | Claude가 직접 실행 |

### 채널 분석 워크플로우

사용자가 "슬랙 분석", "채널 분석" 요청 시:

```powershell
# 1. 전체 채널 목록
cd C:\claude && python -m lib.slack channels --private --json

# 2. 각 채널별 최근 메시지 (예: 상위 3개 채널)
python -m lib.slack history "C채널ID1" --limit 50 --json
python -m lib.slack history "C채널ID2" --limit 50 --json

# 3. 결과 종합하여 분석 리포트 작성
```

## Workflow (Legacy)

사용자가 Slack 관련 요청 시:

1. **토큰 확인**: `python -m lib.slack status --json` 실행
2. **없으면**: `python -m lib.slack login` 안내
3. **있으면**: 요청된 작업 실행 (`--json` 플래그 사용)
4. **결과 출력**: JSON 파싱 후 읽기 쉬운 형태로 응답

## Error Handling

| Error | Solution |
|-------|----------|
| `SlackCredentialsNotFoundError` | slack_credentials.json 생성 필요 |
| `SlackAuthError` | `python -m lib.slack login` 재실행 |
| `SlackRateLimitError` | 잠시 후 재시도 (자동 대기) |
| `SlackChannelNotFoundError` | 채널 ID 확인 또는 봇 초대 필요 |

## File Locations

| File | Purpose |
|------|---------|
| `C:\claude\json\slack_credentials.json` | OAuth 앱 인증정보 (사용자 생성) |
| `C:\claude\json\slack_token.json` | 액세스 토큰 (자동 생성) |
| `C:\claude\lib\slack\` | 라이브러리 소스 코드 |

## Rate Limits

Slack API 2026 Rate Limits 준수:
- `chat.postMessage`: 3초 간격
- `conversations.history`: 1.2초 간격
- `conversations.list`: 3초 간격
- `users.info`: 0.6초 간격

자동으로 rate limiting 적용됨.
