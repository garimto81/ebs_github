# Gmail Workflows (상세 참조)

> 이 문서는 `gmail` 스킬의 상세 워크플로우 가이드입니다.

## Prerequisites

### 1. Google Cloud Console 설정

1. https://console.cloud.google.com/ 접속
2. 프로젝트 선택 또는 생성
3. **APIs & Services** > **Library** 이동
4. **Gmail API** 검색 후 **Enable**

### 2. OAuth Credentials 생성

1. **APIs & Services** > **Credentials** 이동
2. **Create Credentials** > **OAuth client ID**
3. **Application type**: Desktop app
4. **Name**: Gmail CLI (또는 원하는 이름)
5. **Create** 클릭

### 3. Credentials 다운로드

1. 생성된 OAuth client에서 **Download JSON** 클릭
2. 파일을 `C:\claude\json\desktop_credentials.json`에 저장

**파일 구조 예시:**
```json
{
  "installed": {
    "client_id": "xxx.apps.googleusercontent.com",
    "client_secret": "xxx",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "redirect_uris": ["http://localhost"]
  }
}
```

### 4. OAuth Consent Screen 설정

1. **APIs & Services** > **OAuth consent screen**
2. **User Type**: External (또는 Internal if Google Workspace)
3. **App name**, **User support email**, **Developer contact** 입력
4. **Scopes**: `gmail.readonly`, `gmail.send`, `gmail.modify` 추가
5. **Test users**: 본인 이메일 추가 (테스트 모드일 경우)

### 5. 인증 실행

```powershell
cd C:\claude && python -m lib.gmail login
```

- 브라우저가 열리고 Google 계정 선택 화면 표시
- 권한 승인 후 자동으로 토큰 저장
- 토큰 저장 위치: `C:\claude\json\token_gmail.json`

## gws CLI Commands (Tier 1 — Primary)

gws CLI가 설치되어 있으면 Python API 대신 gws를 우선 사용합니다.

```powershell
# 받은편지함 (최근 10개)
gws gmail users messages list --params '{"userId":"me","q":"in:inbox","maxResults":10}'

# 안 읽은 메일
gws gmail users messages list --params '{"userId":"me","q":"is:unread","maxResults":10}'

# 메일 검색
gws gmail users messages list --params '{"userId":"me","q":"from:boss@company.com subject:meeting","maxResults":20}'

# 메일 상세 읽기
gws gmail users messages get --params '{"userId":"me","id":"18d5f7c8e9a0b123","format":"full"}'

# 프로필 조회
gws gmail users getProfile --params '{"userId":"me"}'

# 라벨 목록
gws gmail users labels list --params '{"userId":"me"}'

# 스레드 조회
gws gmail users threads get --params '{"userId":"me","id":"18d5f7c8e9a0b123"}'
```

> **참고**: 메일 전송(`send`), 답장(`reply`)은 Base64 인코딩이 필요하므로 Python API만 지원합니다.

## Usage Examples (Tier 2 — Python Fallback)

### 받은편지함 확인

```powershell
# 최근 10개 메일
python -m lib.gmail inbox

# 최근 20개 메일 (JSON 출력)
python -m lib.gmail inbox --limit 20 --json
```

### 안 읽은 메일 확인

```powershell
# 안 읽은 메일 목록
python -m lib.gmail unread

# JSON 형식으로 출력
python -m lib.gmail unread --json
```

### 메일 검색

```powershell
# 특정 발신자로부터
python -m lib.gmail search "from:boss@company.com"

# 제목에 특정 단어
python -m lib.gmail search "subject:meeting"

# 첨부파일 있는 메일
python -m lib.gmail search "has:attachment"

# 날짜 범위
python -m lib.gmail search "after:2024/01/01 before:2024/12/31"

# 복합 검색
python -m lib.gmail search "from:client@example.com subject:invoice has:attachment"
```

### 메일 전송

```powershell
# 단순 텍스트 메일
python -m lib.gmail send "recipient@example.com" "회의 안건" "내일 오후 3시 회의 참석 부탁드립니다."

# CC 포함
python -m lib.gmail send "recipient@example.com" "주간 보고" "첨부 참조" --cc "manager@example.com"

# HTML 메일
python -m lib.gmail send "recipient@example.com" "공지" "<h1>공지사항</h1><p>내용...</p>" --html
```

### 메일 상세 읽기

```powershell
# 메일 ID로 상세 내용 확인
python -m lib.gmail read "18d5f7c8e9a0b123"

# 읽음 표시와 함께
python -m lib.gmail read "18d5f7c8e9a0b123" --mark-read
```

## Python API

```python
from lib.gmail import GmailClient, login, get_token

# 인증 (최초 1회)
login()

# 클라이언트 생성
client = GmailClient()

# 받은편지함
emails = client.list_emails(query="in:inbox", max_results=10)
for email in emails:
    print(f"{email.sender}: {email.subject}")

# 안 읽은 메일
unread = client.list_emails(query="is:unread", max_results=5)

# 메일 검색
results = client.list_emails(query="from:boss@company.com", max_results=20)

# 메일 전송
result = client.send(
    to="recipient@example.com",
    subject="안녕하세요",
    body="메일 본문입니다."
)
print(f"Sent: {result.permalink}")

# 답장
client.reply(email_id="...", body="답장 내용")

# 라벨 관리
labels = client.list_labels()
client.modify_labels(email_id, add_labels=["STARRED"])

# 읽음/안읽음 표시
client.mark_as_read(email_id)
client.mark_as_unread(email_id)

# 보관/삭제
client.archive(email_id)
client.trash(email_id)
```

## Gmail Search Query 문법

| 검색 조건 | 쿼리 예시 |
|-----------|----------|
| 발신자 | `from:example@gmail.com` |
| 수신자 | `to:me@gmail.com` |
| 제목 | `subject:meeting` |
| 첨부파일 | `has:attachment` |
| 안 읽음 | `is:unread` |
| 읽음 | `is:read` |
| 별표 | `is:starred` |
| 중요 | `is:important` |
| 날짜 이후 | `after:2024/01/01` |
| 날짜 이전 | `before:2024/12/31` |
| 라벨 | `label:work` |
| 받은편지함 | `in:inbox` |
| 보낸편지함 | `in:sent` |
| 스팸 | `in:spam` |
| 휴지통 | `in:trash` |

## Error Handling

| Error | Solution |
|-------|----------|
| `GmailCredentialsNotFoundError` | desktop_credentials.json 생성 필요 |
| `GmailAuthError` | `python -m lib.gmail login` 재실행 |
| `GmailRateLimitError` | 잠시 후 재시도 |
| 403 Permission Denied | OAuth Consent Screen에서 scope 확인 |

## File Locations

| File | Purpose |
|------|---------|
| `C:\claude\json\desktop_credentials.json` | OAuth 클라이언트 (사용자 생성) |
| `C:\claude\json\token_gmail.json` | 액세스 토큰 (자동 생성) |
| `C:\claude\lib\gmail\` | 라이브러리 소스 코드 |

## Rate Limits

Gmail API 2026 Rate Limits 준수:
- 읽기: 250 요청/초
- 전송: 분당 100개 (일반 계정)
- 대량 전송: Google Workspace 계정 필요

## /auto 옵션 연동

`/auto --gmail` 옵션으로 Gmail 컨텍스트를 작업에 주입할 수 있습니다.

```
/auto --gmail "최근 클라이언트 메일 분석하고 응답 초안 작성"
→ Step 1: Gmail 인증 확인
→ Step 2: 메일 검색/조회
→ Step 3: 분석 결과를 컨텍스트로 사용
→ Step 4: 메인 워크플로우 실행
```

## Security Notes

- OAuth 토큰은 로컬에만 저장됨
- refresh_token으로 자동 갱신
- 만료 시 재인증 필요
- credentials.json은 절대 커밋하지 않음 (.gitignore)
