# Google Workspace REFERENCE - 상세 API 코드 및 스타일

이 파일은 SKILL.md에서 분리된 상세 코드 예시, 스타일 가이드, PRD 관리 시스템 문서입니다.

---

## gws CLI Commands (Tier 1 — Primary)

gws CLI가 설치되어 있으면 Python API 대신 gws를 우선 사용합니다.

### Sheets

```powershell
# 스프레드시트 읽기
gws sheets spreadsheets values get --params '{"spreadsheetId":"1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms","range":"Sheet1!A:E"}'

# 스프레드시트 쓰기
gws sheets spreadsheets values update --params '{"spreadsheetId":"ID","range":"Sheet1!A1","valueInputOption":"USER_ENTERED"}' --body '{"values":[["a","b"]]}'

# 스프레드시트 추가
gws sheets spreadsheets values append --params '{"spreadsheetId":"ID","range":"Sheet1!A1","valueInputOption":"USER_ENTERED","insertDataOption":"INSERT_ROWS"}' --body '{"values":[["new","row"]]}'
```

### Drive

```powershell
# 파일 목록 조회
gws drive files list --params '{"q":"\"FOLDER_ID\" in parents and trashed=false","pageSize":100,"fields":"files(id,name,mimeType,modifiedTime)"}'

# 파일 검색
gws drive files list --params '{"q":"name contains \"보고서\" and trashed=false","pageSize":20}'
```

### Gmail

```powershell
# 메일 목록
gws gmail users messages list --params '{"userId":"me","q":"in:inbox","maxResults":10}'

# 메일 상세
gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}'
```

### Calendar

```powershell
# 일정 조회
gws calendar events list --params '{"calendarId":"primary","timeMin":"2026-03-12T00:00:00Z","maxResults":10,"singleEvents":true,"orderBy":"startTime"}'

# 일정 생성
gws calendar events insert --params '{"calendarId":"primary"}' --body '{"summary":"회의","start":{"dateTime":"2026-03-12T14:00:00+09:00"},"end":{"dateTime":"2026-03-12T15:00:00+09:00"}}'
```

> **전환하지 않는 것**: Docs Converter (`lib/google_docs/converter.py`), Drive Guardian, Table Renderer는 Batch API가 필요하므로 Python API만 사용합니다.

---

## OAuth 2.0 인증 코드

```python
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import os

SCOPES = ['https://www.googleapis.com/auth/drive']
CREDENTIALS_FILE = r'C:\claude\json\desktop_credentials.json'
TOKEN_FILE = r'C:\claude\json\token.json'

def get_credentials():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return creds
```

## 서비스 계정 인증 코드

```python
from google.oauth2 import service_account

SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = r'C:\claude\json\service_account_key.json'

def get_service_credentials():
    return service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES
    )
```

---

## Google Sheets 상세

### 스프레드시트 읽기

```python
from googleapiclient.discovery import build
from lib.google_docs.auth import get_credentials

def read_sheet(spreadsheet_id: str, range_name: str):
    creds = get_credentials()
    service = build('sheets', 'v4', credentials=creds)
    result = service.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id, range=range_name
    ).execute()
    return result.get('values', [])

data = read_sheet('1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms', 'Sheet1!A:E')
```

### 스프레드시트 쓰기

```python
def write_sheet(spreadsheet_id: str, range_name: str, values: list):
    creds = get_credentials()
    service = build('sheets', 'v4', credentials=creds)
    body = {'values': values}
    result = service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id, range=range_name,
        valueInputOption='USER_ENTERED', body=body
    ).execute()
    return result.get('updatedCells')
```

### 스프레드시트 추가 (Append)

```python
def append_sheet(spreadsheet_id: str, range_name: str, values: list):
    creds = get_credentials()
    service = build('sheets', 'v4', credentials=creds)
    body = {'values': values}
    result = service.spreadsheets().values().append(
        spreadsheetId=spreadsheet_id, range=range_name,
        valueInputOption='USER_ENTERED', insertDataOption='INSERT_ROWS', body=body
    ).execute()
    return result.get('updates').get('updatedRows')
```

---

## Google Drive 상세

### 프로젝트 폴더 조회

```python
from lib.google_docs.auth import get_credentials
from lib.google_docs.project_registry import get_project_folder_id

wsoptv_folder_id = get_project_folder_id('WSOPTV')
ebs_folder_id = get_project_folder_id('EBS')
```

### 파일 목록 조회

```python
def list_files(folder_id: str = None, mime_type: str = None):
    creds = get_credentials()
    service = build('drive', 'v3', credentials=creds)
    query_parts = []
    if folder_id:
        query_parts.append(f"'{folder_id}' in parents")
    if mime_type:
        query_parts.append(f"mimeType='{mime_type}'")
    query_parts.append("trashed=false")
    query = " and ".join(query_parts)
    results = service.files().list(
        q=query, pageSize=100,
        fields="files(id, name, mimeType, modifiedTime)"
    ).execute()
    return results.get('files', [])
```

### 파일 업로드

```python
from googleapiclient.http import MediaFileUpload

def upload_file(file_path: str, folder_id: str = None, mime_type: str = None):
    creds = get_credentials()
    service = build('drive', 'v3', credentials=creds)
    file_metadata = {'name': os.path.basename(file_path)}
    if folder_id:
        file_metadata['parents'] = [folder_id]
    media = MediaFileUpload(file_path, mimetype=mime_type)
    file = service.files().create(
        body=file_metadata, media_body=media, fields='id, name, webViewLink'
    ).execute()
    return file
```

### 파일 다운로드

```python
from googleapiclient.http import MediaIoBaseDownload
import io

def download_file(file_id: str, output_path: str):
    creds = get_credentials()
    service = build('drive', 'v3', credentials=creds)
    request = service.files().get_media(fileId=file_id)
    with io.FileIO(output_path, 'wb') as fh:
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
```

### Drive 프로젝트 폴더 구조

```
Google Drive (루트)
├── WSOPTV/              # WSOPTV 프로젝트
├── EBS/                 # EBS 프로젝트
├── 지지프로덕션/        # 지지프로덕션 프로젝트
├── 브로드스튜디오/      # 브로드스튜디오 프로젝트
├── _개인/               # 개인 파일
└── _아카이브/           # 아카이브 파일
```

### 공유 리소스

| 리소스 | 폴더/문서 ID |
|--------|-------------|
| Google AI Studio | `1JwdlUe_v4Ug-yQ0veXTldFl6C24GH8hW` |
| WSOPTV 와이어프레임 | `1kHuCfqD7PPkybWXRL3pqeNISTPT7LUTB` |
| WSOPTV UX 기획서 | `1tghlhpQiWttpB-0CP5c1DiL5BJa4ttWj-2R77xaoVI8` |

---

## Gmail 연동

### 이메일 발송

```python
import base64
from email.mime.text import MIMEText
from googleapiclient.discovery import build
from lib.google_docs.auth import get_credentials

def send_email(to: str, subject: str, body: str):
    creds = get_credentials()
    service = build('gmail', 'v1', credentials=creds)
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject
    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    return service.users().messages().send(userId='me', body={'raw': raw}).execute()
```

### 이메일 조회

```python
def list_emails(query: str = '', max_results: int = 10):
    creds = get_credentials()
    service = build('gmail', 'v1', credentials=creds)
    results = service.users().messages().list(userId='me', q=query, maxResults=max_results).execute()
    messages = results.get('messages', [])
    emails = []
    for msg in messages:
        detail = service.users().messages().get(
            userId='me', id=msg['id'], format='metadata',
            metadataHeaders=['From', 'Subject', 'Date']
        ).execute()
        emails.append(detail)
    return emails
```

---

## Google Calendar 연동

### 일정 조회

```python
from datetime import datetime, timedelta

def list_events(calendar_id: str = 'primary', days: int = 7):
    creds = get_credentials()
    service = build('calendar', 'v3', credentials=creds)
    now = datetime.utcnow().isoformat() + 'Z'
    end = (datetime.utcnow() + timedelta(days=days)).isoformat() + 'Z'
    events_result = service.events().list(
        calendarId=calendar_id, timeMin=now, timeMax=end,
        singleEvents=True, orderBy='startTime'
    ).execute()
    return events_result.get('items', [])
```

### 일정 생성

```python
def create_event(summary: str, start: datetime, end: datetime,
                 description: str = None, calendar_id: str = 'primary'):
    creds = get_credentials()
    service = build('calendar', 'v3', credentials=creds)
    event = {
        'summary': summary,
        'start': {'dateTime': start.isoformat(), 'timeZone': 'Asia/Seoul'},
        'end': {'dateTime': end.isoformat(), 'timeZone': 'Asia/Seoul'},
    }
    if description:
        event['description'] = description
    return service.events().insert(calendarId=calendar_id, body=event).execute()
```

---

## 문서 스타일 상세 가이드 (파랑 계열)

### 페이지 설정

| 항목 | 값 |
|------|-----|
| 페이지 크기 | A4 (595.28pt x 841.89pt) |
| 여백 | 72pt (1인치) 상하좌우 |
| 컨텐츠 너비 | 451.28pt |
| 줄간격 | 115% |
| 문단 간격 | 상: 0pt, 하: 4pt |

### 타이포그래피 상세

| 요소 | 크기 | 굵기 | 색상 | 여백(상/하) |
|------|------|------|------|------------|
| Title | 26pt | Bold (700) | `#1A4D8C` | 12/8pt |
| H1 | 18pt | Bold (700) | `#1A4D8C` | 18/6pt (하단 구분선) |
| H2 | 14pt | Bold (700) | `#3373B3` | 14/4pt |
| H3 | 12pt | Bold (700) | `#404040` | 10/4pt |
| H4 | 11pt | SemiBold (600) | `#404040` | 8/4pt |
| H5 | 11pt | SemiBold (600) | `#404040` | 6/4pt |
| H6 | 10pt | SemiBold (600) | `#666666` | 4/4pt |
| 본문 | 11pt | Regular (400) | `#404040` | 0/4pt |
| 인라인 코드 | 10.5pt | Regular | `#404040` | 배경 `#F2F2F2` |
| 코드 블록 | 10.5pt | Regular | `#404040` | 배경 `#F2F2F2`, 패딩 12pt |

### 색상 팔레트

```python
NOTION_COLORS = {
    'text_primary': '#404040',
    'text_secondary': '#666666',
    'text_muted': '#999999',
    'heading_primary': '#1A4D8C',
    'heading_secondary': '#3373B3',
    'heading_tertiary': '#404040',
    'background_gray': '#F2F2F2',
    'table_header_bg': '#E6E6E6',
    'table_header_text': '#404040',
    'table_border': '#CCCCCC',
}
```

### 강조 색상

| 색상 | HEX | 용도 | 배경 |
|------|-----|------|------|
| Red | `#DC2626` | 오류, 삭제 | `#FEE2E2` |
| Orange | `#D97706` | 경고 | `#FEF3C7` |
| Yellow | `#CA8A04` | 주의 | `#FEF9C3` |
| Green | `#059669` | 성공 | `#D1FAE5` |
| Blue | `#1A4D8C` | 정보 | `#DBEAFE` |
| Purple | `#7C3AED` | 특수 | `#EDE9FE` |

### Callout 박스 스타일

| 타입 | 아이콘 | 배경색 | 테두리색 |
|------|--------|--------|----------|
| info | i | `#DBEAFE` | `#1A4D8C` |
| warning | ! | `#FEF3C7` | `#D97706` |
| success | v | `#D1FAE5` | `#059669` |
| danger | x | `#FEE2E2` | `#DC2626` |
| tip | * | `#FEF9C3` | `#CA8A04` |
| note | n | `#F2F2F2` | `#999999` |

### 테이블 스타일

| 항목 | 값 |
|------|-----|
| 너비 | 18cm (510pt) |
| 컬럼 너비 | 1열: 18cm, 2열: 9cmx2, 3열: 6cmx3, 4열: 4.5cmx4 |
| 헤더 배경 | `#E6E6E6` |
| 셀 패딩 | 5pt |
| 테두리 | 1pt `#CCCCCC` |

### 네이티브 테이블 2단계 렌더링

1단계: 테이블 구조 생성 (batchUpdate -> 문서 끝 인덱스 조회 -> insertTable)
2단계: 테이블 내용 삽입 (문서 재조회 -> 셀 인덱스 추출 -> 역순 텍스트 삽입 -> 헤더 스타일)

관련 모듈: `lib/google_docs/table_renderer.py`, `lib/google_docs/converter.py`

### 줄바꿈 정책

| 항목 | 정책 |
|------|------|
| 단락 전환 | 줄바꿈 1개 허용 |
| 테이블/이미지 앞뒤 | 줄바꿈 제거 |
| 목록 항목 사이 | 줄바꿈 제거 |

### 금지 사항

구분선 반복, 불필요한 빈 줄, HTML 원본 링크, 150% 이상 줄간격, Letter 용지, Slate 색상

---

## 스타일 적용 코드 템플릿

### 표준 문서 스타일

```python
def apply_standard_style(service, doc_id):
    requests = [{
        "updateDocumentStyle": {
            "documentStyle": {
                "pageSize": {
                    "width": {"magnitude": 595.28, "unit": "PT"},
                    "height": {"magnitude": 841.89, "unit": "PT"}
                },
                "marginTop": {"magnitude": 72, "unit": "PT"},
                "marginBottom": {"magnitude": 72, "unit": "PT"},
                "marginLeft": {"magnitude": 72, "unit": "PT"},
                "marginRight": {"magnitude": 72, "unit": "PT"},
            },
            "fields": "pageSize,marginTop,marginBottom,marginLeft,marginRight"
        }
    }]
    doc = service.documents().get(documentId=doc_id).execute()
    end_index = max(el.get("endIndex", 1) for el in doc["body"]["content"])
    requests.append({
        "updateParagraphStyle": {
            "range": {"startIndex": 1, "endIndex": end_index - 1},
            "paragraphStyle": {
                "lineSpacing": 115,
                "spaceAbove": {"magnitude": 0, "unit": "PT"},
                "spaceBelow": {"magnitude": 4, "unit": "PT"},
            },
            "fields": "lineSpacing,spaceAbove,spaceBelow"
        }
    })
    service.documents().batchUpdate(documentId=doc_id, body={"requests": requests}).execute()
```

### 헤딩 스타일

```python
def apply_heading_style(service, doc_id, start_idx, end_idx, heading_level):
    COLORS = {
        "primary_blue": {"red": 0.10, "green": 0.30, "blue": 0.55},
        "accent_blue": {"red": 0.20, "green": 0.45, "blue": 0.70},
        "dark_gray": {"red": 0.25, "green": 0.25, "blue": 0.25},
    }
    HEADING_STYLES = {
        "TITLE": {"color": "primary_blue", "size": 26},
        "HEADING_1": {"color": "primary_blue", "size": 18, "border": True},
        "HEADING_2": {"color": "accent_blue", "size": 14},
        "HEADING_3": {"color": "dark_gray", "size": 12},
    }
    style = HEADING_STYLES.get(heading_level)
    if not style:
        return
    requests = [{
        "updateTextStyle": {
            "range": {"startIndex": start_idx, "endIndex": end_idx},
            "textStyle": {
                "foregroundColor": {"color": {"rgbColor": COLORS[style["color"]]}},
                "bold": True,
                "fontSize": {"magnitude": style["size"], "unit": "PT"}
            },
            "fields": "foregroundColor,bold,fontSize"
        }
    }]
    if style.get("border"):
        requests.append({
            "updateParagraphStyle": {
                "range": {"startIndex": start_idx, "endIndex": end_idx + 1},
                "paragraphStyle": {
                    "borderBottom": {
                        "color": {"color": {"rgbColor": COLORS["accent_blue"]}},
                        "width": {"magnitude": 1, "unit": "PT"},
                        "padding": {"magnitude": 4, "unit": "PT"},
                        "dashStyle": "SOLID"
                    }
                },
                "fields": "borderBottom"
            }
        })
    service.documents().batchUpdate(documentId=doc_id, body={"requests": requests}).execute()
```

---

## Markdown -> Google Docs 변환

### 지원 문법

| 문법 | 변환 결과 |
|------|----------|
| `# H1` ~ `###### H6` | 스타일링된 제목 |
| `**bold**` | 굵은 글씨 |
| `*italic*` | 기울임 |
| `` `code` `` | 인라인 코드 (배경 F2F2F2) |
| `~~strike~~` | 취소선 |
| `[text](url)` | 링크 |
| `- item` | 불릿 리스트 |
| `1. item` | 번호 리스트 |
| `- [ ]` / `- [x]` | 체크박스 |
| `> quote` | 인용문 |
| ` ``` ` | 코드 블록 |
| `| a | b |` | 네이티브 테이블 |
| `![alt](path)` | Drive 업로드 후 삽입 |
| `---` | H1 하단 구분선 스타일 |
| `<div style="border:...">` | Callout 박스 |

### HTML Callout 박스 자동 변환

| HTML 스타일 | 변환 결과 |
|------------|----------|
| `border:...red...` | 경고 Callout |
| `border:...orange...` | 주의 Callout |
| `border:...green...` | 성공 Callout |
| `border:...blue...` | 정보 Callout |

### 이미지 삽입 필수 규칙

반드시 `![alt](path)` 마크다운 이미지 문법 사용. 테이블 내 경로, 인라인 코드 경로는 이미지로 인식 안 됨.

### CLI 변환 도구

```powershell
python scripts/prd_to_google_docs.py tasks/prds/PRD-0001.md
python scripts/prd_to_google_docs.py --toc file.md       # 목차 포함
python scripts/prd_to_google_docs.py --folder ID file.md  # 특정 폴더
python scripts/prd_to_google_docs.py --no-folder file.md  # 내 드라이브
python scripts/prd_to_google_docs.py tasks/prds/*.md      # 배치 변환
```

---

## HTML 목업 -> 이미지 워크플로우

HTML 목업 -> Playwright 스크린샷 -> Google Docs 이미지 삽입

| 항목 | 값 |
|------|-----|
| 이미지 너비 | 18cm (510pt) |
| 가로 너비 | 540px |
| 최소 폰트 | 16px |
| 캡처 대상 | `#capture-area` |

```powershell
npx playwright screenshot docs/mockups/arch.html docs/images/arch.png --selector="#capture-area"
```

### 템플릿

| 템플릿 | 경로 |
|--------|------|
| base | `lib/google_docs/templates/base.html` |
| architecture | `lib/google_docs/templates/architecture.html` |
| flowchart | `lib/google_docs/templates/flowchart.html` |
| erd | `lib/google_docs/templates/erd.html` |
| ui-mockup | `lib/google_docs/templates/ui-mockup.html` |

---

## 이미지 삽입 (ImageInserter)

```python
from lib.google_docs.image_inserter import ImageInserter
from lib.google_docs.auth import get_credentials

creds = get_credentials()
inserter = ImageInserter(creds)
file_id, image_url = inserter.upload_to_drive(Path('diagram.png'))
inserter.insert_image_at_position(doc_id, image_url, position=100, width=400)
inserter.insert_image_after_text(doc_id, image_url, "## 아키텍처")
inserter.insert_image_after_heading(doc_id, image_url, "기술 아키텍처")
```

지원 형식: PNG, JPG/JPEG, GIF, WEBP, SVG

---

## 다이어그램 생성기

```python
from lib.google_docs.diagram_generator import DiagramGenerator

generator = DiagramGenerator()
html = generator.create_architecture_diagram(
    title="시스템 아키텍처",
    components=[
        {"name": "Frontend", "type": "client"},
        {"name": "API Gateway", "type": "gateway"},
        {"name": "Backend", "type": "server"},
    ]
)
```

---

## PRD 관리 시스템

### 아키텍처

/create prd (대화형) -> Google Docs (마스터) -> Local Cache (읽기 전용) -> .prd-registry.json

### 모듈 구조

```
lib/google_docs/                    # 핵심 변환 라이브러리
├── auth.py                 # OAuth 2.0 인증
├── converter.py            # Markdown -> Google Docs 변환
├── table_renderer.py       # 네이티브 테이블 렌더링
├── notion_style.py         # 파랑 계열 스타일
├── models.py               # 데이터 모델
└── cli.py                  # CLI

src/services/google_docs/           # PRD 관리 서비스
├── client.py              # API 클라이언트
├── prd_service.py         # PRD CRUD
├── cache_manager.py       # 캐시 동기화
├── metadata_manager.py    # 레지스트리 관리
└── migration.py           # 마이그레이션
```

### 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/create prd [name]` | Google Docs에 PRD 생성 |
| `/create prd [name] --local-only` | 로컬 Markdown만 생성 |
| `/prd-sync [PRD-ID]` | PRD 동기화 |
| `/prd-sync all` | 전체 동기화 |
| `/prd-sync list` | 목록 조회 |
| `/prd-sync stats` | 통계 |

### 레지스트리 구조

`.prd-registry.json`:
```json
{
  "version": "1.0.0",
  "last_sync": "2025-12-24T10:00:00Z",
  "next_prd_number": 2,
  "prds": {
    "PRD-0001": {
      "google_doc_id": "1abc...",
      "google_doc_url": "https://docs.google.com/document/d/.../edit",
      "title": "포커 핸드 자동 캡처",
      "status": "In Progress",
      "priority": "P0",
      "local_cache": "PRD-0001.cache.md",
      "checklist_path": "docs/checklists/PRD-0001.md"
    }
  }
}
```

### 마이그레이션

```bash
python scripts/migrate_prds_to_gdocs.py list      # 대상 목록
python scripts/migrate_prds_to_gdocs.py all       # 전체 마이그레이션
python scripts/migrate_prds_to_gdocs.py PRD-0001  # 단일 마이그레이션
```

---

## API 설정 흐름

1. Google Cloud Console 프로젝트 생성
2. API 활성화 (Sheets, Drive, Gmail, Calendar)
3. 인증 정보 생성 (OAuth 2.0 클라이언트 ID / 서비스 계정)
4. credentials.json 다운로드

## 환경 변수

```bash
GOOGLE_OAUTH_CREDENTIALS=C:\claude\json\desktop_credentials.json
GOOGLE_OAUTH_TOKEN=C:\claude\json\token.json
GOOGLE_SERVICE_ACCOUNT_FILE=C:\claude\json\service_account_key.json
GOOGLE_APPLICATION_CREDENTIALS=C:\claude\json\service_account_key.json
```

## 할당량 초과 재시도 코드

```python
import time
from googleapiclient.errors import HttpError

def api_call_with_retry(func, max_retries=5):
    for attempt in range(max_retries):
        try:
            return func()
        except HttpError as e:
            if e.resp.status == 429:
                wait_time = 2 ** attempt
                time.sleep(wait_time)
            else:
                raise
    raise Exception("Max retries exceeded")
```

## 서비스 계정 이메일

`archive-sync@ggp-academy.iam.gserviceaccount.com`

## 인증 파일

| 파일 | 용도 |
|------|------|
| `C:\claude\json\token_docs.json` | Google Docs OAuth 토큰 |
| `C:\claude\json\desktop_credentials.json` | OAuth 클라이언트 자격증명 |

## 참조 문서

- [Google Sheets API](https://developers.google.com/sheets/api)
- [Google Drive API](https://developers.google.com/drive/api)
- [Gmail API](https://developers.google.com/gmail/api)
- [Google Calendar API](https://developers.google.com/calendar/api)
- [Python Quickstart](https://developers.google.com/sheets/api/quickstart/python)
