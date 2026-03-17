---
name: gmail
description: >
  This skill should be used when the user requests Gmail operations like reading inbox, sending emails, searching messages, or managing labels via OAuth 2.0.
version: 1.0.0
triggers:
  keywords:
    - "gmail"
    - "지메일"
    - "email"
    - "이메일"
    - "메일"
    - "mail"
    - "inbox"
    - "받은편지함"
    - "unread"
    - "안읽은 메일"
    - "메일 확인"
    - "메일 보내"
    - "이메일 전송"
  patterns:
    - "gmail (login|inbox|unread|send|read|search|labels)"
    - "(메일|이메일).*(확인|읽|보내|전송|검색)"
    - "(unread|inbox|sent) (mail|email)"
  file_patterns:
    - "**/gmail*.py"
    - "**/gmail_*.json"
  context:
    - "Gmail 연동"
    - "이메일 자동화"
    - "메일 관리"
auto_trigger: true
---

# Gmail Skill

Gmail API 연동 스킬. OAuth 2.0 인증, 이메일 읽기/전송, 라벨 관리 기능 제공.

## 2-Tier Backend Selection

| 조건 | 백엔드 | 이유 |
|------|--------|------|
| `gws` CLI 설치됨 | gws subprocess (Tier 1) | JSON 출력, 빠른 실행 |
| `gws` 미설치 | Python API (Tier 2) | 완전한 fallback |
| `gws` 호출 실패 | Python API 자동 전환 | 무중단 |

선택 로직: `gws --version` 성공 여부 확인 → gws CLI 우선 → 실패 시 Python 자동 전환

## Commands

| 작업 | gws CLI (Tier 1) | Python API (Tier 2) |
|------|-------------------|---------------------|
| 인증 | - | `python -m lib.gmail login` |
| 상태 확인 | - | `python -m lib.gmail status` |
| 받은편지함 | `gws gmail +triage` | `python -m lib.gmail inbox` |
| 안 읽은 메일 | `gws gmail users messages list --params '{"userId":"me","labelIds":["INBOX","UNREAD"],"maxResults":10}'` | `python -m lib.gmail unread` |
| 메일 읽기 | `gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}'` | `python -m lib.gmail read <id>` |
| 메일 전송 | Python 권장 (Base64 인코딩 필요) | `python -m lib.gmail send <to> <subject> <body>` |
| 메일 검색 | `gws gmail users messages list --params '{"userId":"me","q":"검색어"}'` | `python -m lib.gmail search <query>` |
| 라벨 목록 | `gws gmail users labels list --params '{"userId":"me"}'` | `python -m lib.gmail labels` |

## Claude 강제 실행 규칙 (MANDATORY)

Gmail 키워드 감지 시 반드시 자동 수행:

**Step 1**: 인증 확인 → `cd C:\claude && python -m lib.gmail status --json`
- `"valid": true` → Step 2 진행
- `"authenticated": false` → 사용자에게 `python -m lib.gmail login` 안내

**Step 2**: 요청별 명령 실행 (gws 설치 시 Tier 1 우선, 미설치 시 Tier 2)

| 사용자 요청 | Tier 1 (gws CLI) | Tier 2 (Python, `--json` 필수) |
|-------------|-------------------|-------------------------------|
| "메일 확인해줘" | `gws gmail +triage` | `python -m lib.gmail inbox --json` |
| "안읽은 메일" | `gws gmail users messages list --params '{"userId":"me","labelIds":["INBOX","UNREAD"],"maxResults":10}'` | `python -m lib.gmail unread --json` |
| "메일 보내줘" | Python 사용 | `python -m lib.gmail send "주소" "제목" "본문"` |
| "메일 검색" | `gws gmail users messages list --params '{"userId":"me","q":"검색어"}'` | `python -m lib.gmail search "검색어" --json` |

**Step 3**: JSON 결과 파싱 → 사용자에게 읽기 쉬운 형태로 응답

### 필수/금지 행동

| 필수 | 금지 |
|------|------|
| `cd C:\claude &&` 접두사 | gmail_token.json 직접 읽기 |
| `--json` 플래그 사용 | WebFetch로 Gmail API 호출 |
| Bash tool 직접 사용 | "인프라가 없습니다" 응답 |
| 에러 시 상세 안내 | 사용자에게 수동 실행 요청 |

## /auto 통합 동작

`--gmail` 옵션이 `/auto`에 전달되면 **Step 2.0 (옵션 처리)** 단계에서 실행:

1. Gmail 인증 상태 확인 (`python -m lib.gmail status --json`)
2. 요청된 Gmail 작업 실행 (inbox/unread/send/search)
3. JSON 결과 파싱 → 컨텍스트로 수집
4. 결과를 후속 작업에 활용 (예: daily 보고서 데이터 소스)

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

## 상세 참조

> Prerequisites (Google Cloud Console 설정, OAuth), Usage Examples, Python API,
> Search Query 문법, Error Handling, File Locations, Rate Limits 등:
> **Read `references/gmail-workflows.md`**
