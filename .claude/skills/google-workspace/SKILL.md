---
name: google-workspace
description: >
  This skill should be used when the user needs Google Workspace API integration for Docs, Sheets, Drive, or Calendar with OAuth 2.0 authentication.
version: 2.8.0

triggers:
  keywords:
    - "google workspace"
    - "google docs"
    - "google sheets"
    - "google calendar"
    - "스프레드시트"
    - "구글 문서"
    - "gdocs"
    - "--gdocs"
    - "prd gdocs"
  file_patterns:
    - "**/credentials.json"
    - "**/token.json"
    - "**/google*.py"
    - "**/sheets*.py"
    - "**/drive*.py"
  context:
    - "Google API 연동"
    - "스프레드시트 데이터 처리"
    - "문서 자동화"
    - "이메일 발송 자동화"
  url_patterns:
    - "drive.google.com"
    - "docs.google.com"
    - "sheets.google.com"

auto_trigger: true
---

# Google Workspace Integration Skill

Google Workspace API 통합을 위한 전문 스킬입니다.

## WebFetch 사용 금지 (CRITICAL)

Google 서비스 URL (`docs.google.com`, `drive.google.com`, `sheets.google.com`, `calendar.google.com`, `mail.google.com`)에 WebFetch 절대 금지. OAuth 2.0 인증 필요하므로 401 반환됨. 대신 Python API 클라이언트 사용.

## URL에서 문서 ID 추출

| URL 패턴 | 추출 위치 |
|----------|----------|
| `docs.google.com/document/d/{ID}/edit` | `/d/` 뒤, `/edit` 앞 |
| `drive.google.com/drive/folders/{ID}` | `/folders/` 뒤 |
| `docs.google.com/spreadsheets/d/{ID}/edit` | `/d/` 뒤, `/edit` 앞 |

## `/auto --gdocs` 처리 규칙 (CRITICAL)

1. CLAUDE.md에서 Google Docs ID 조회 (필수)
2. ID 있음 -> `--doc-id` 옵션으로 기존 문서 업데이트
3. ID 없음 -> 새 문서 생성 후 CLAUDE.md에 ID 등록
4. 실행: `cd C:\claude && python -m lib.google_docs convert "파일.md" --doc-id {ID}`

**금지**: CLAUDE.md 확인 없이 convert 실행 (중복 문서), 기존 ID 무시 (공유 링크 깨짐)

## 인증 파일 경로 (고정)

| 파일 | 경로 |
|------|------|
| OAuth 클라이언트 | `C:\claude\json\desktop_credentials.json` |
| OAuth 토큰 | `C:\claude\json\token.json` |
| 서비스 계정 | `C:\claude\json\service_account_key.json` |

서비스 계정은 저장 용량 할당량 없어 **Drive 업로드 불가** -> OAuth 2.0 사용.

## 인증 방식 선택

| 작업 | 인증 방식 | 파일 |
|------|----------|------|
| 파일 업로드/쓰기 | OAuth 2.0 | `desktop_credentials.json` |
| 파일 읽기 | 서비스 계정 또는 OAuth | 둘 다 가능 |
| 자동화 (읽기만) | 서비스 계정 | `service_account_key.json` |

## gws CLI Integration (2-Tier Hybrid)

### 백엔드 선택 규칙

| 조건 | 백엔드 | 이유 |
|------|--------|------|
| `gws` CLI 설치됨 | gws subprocess (Tier 1) | Sheets/Docs 읽기 조회에 빠름 |
| `gws` 미설치 | Python API (Tier 2) | 완전한 fallback |
| `gws` 호출 실패 | Python API 자동 전환 | 무중단 |
| converter.py / table_renderer | Python API 고정 | 120KB Batch API, 복잡 렌더링 |

### gws CLI 명령 예시

| 작업 | gws CLI (Tier 1) |
|------|-------------------|
| Sheets 읽기 | `gws sheets spreadsheets values get --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1:Z100"}'` |
| Sheets 쓰기 | `gws sheets spreadsheets values update --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1","valueInputOption":"USER_ENTERED"}' --body '{"values":[["data1","data2"]]}'` |
| Docs 읽기 | `gws docs documents get --params '{"documentId":"DOC_ID"}'` |

Markdown→Google Docs 변환(`converter.py`), 테이블 렌더링(`table_renderer`)은 Python API 유지.

## 핵심 API 사용법

### Sheets 읽기/쓰기

```python
from lib.google_docs.auth import get_credentials
from googleapiclient.discovery import build

creds = get_credentials()
service = build('sheets', 'v4', credentials=creds)

# 읽기
result = service.spreadsheets().values().get(spreadsheetId=id, range=range).execute()

# 쓰기
service.spreadsheets().values().update(
    spreadsheetId=id, range=range, valueInputOption='USER_ENTERED', body={'values': data}
).execute()
```

### Drive 파일 목록/업로드

```python
service = build('drive', 'v3', credentials=creds)

# 목록 조회
service.files().list(q="'folder_id' in parents and trashed=false", pageSize=100,
    fields="files(id, name, mimeType, modifiedTime)").execute()

# 업로드 (OAuth 필수)
from googleapiclient.http import MediaFileUpload
service.files().create(body={'name': 'file.pdf', 'parents': [folder_id]},
    media_body=MediaFileUpload('file.pdf'), fields='id,webViewLink').execute()
```

### Docs 읽기/변환

```python
# API 직접 읽기
service = build('docs', 'v1', credentials=creds)
doc = service.documents().get(documentId='DOC_ID').execute()

# Markdown -> Google Docs 변환
# cd C:\claude && python -m lib.google_docs convert "파일.md"
```

## 서브 프로젝트에서 사용 시

**반드시 루트에서 실행**: `cd C:\claude && python -m lib.google_docs convert "{절대_파일_경로}"`
서브 프로젝트에서 직접 실행 시 `ModuleNotFoundError` 발생.

## 권한 범위 (Scopes)

| 서비스 | 읽기 전용 | 전체 접근 |
|--------|----------|----------|
| Sheets | `spreadsheets.readonly` | `spreadsheets` |
| Drive | `drive.readonly` | `drive` |
| Gmail | `gmail.readonly` | `gmail.modify` |
| Calendar | `calendar.readonly` | `calendar` |

**권장**: 필요한 최소 권한만 요청

## 할당량

| API | 제한 |
|-----|------|
| Sheets | 300 요청/분/프로젝트 |
| Drive | 10,000 요청/100초/사용자 |
| Gmail | 250 요청/초/사용자 |

**초과 방지**: 배치 요청, 지수 백오프 재시도, 캐싱

## 문서 스타일 요약 (파랑 계열)

| 요소 | 크기 | 색상 |
|------|------|------|
| Title | 26pt Bold | `#1A4D8C` |
| H1 | 18pt Bold | `#1A4D8C` (하단 구분선) |
| H2 | 14pt Bold | `#3373B3` |
| H3+ | 12pt Bold | `#404040` |
| 본문 | 11pt | `#404040` |
| 테이블 헤더 | Bold | 배경 `#E6E6E6` |

페이지: A4, 여백 72pt, 줄간격 115%. 네이티브 테이블은 2단계 렌더링.

## Anti-Patterns

| 금지 | 대안 |
|------|------|
| credentials.json 커밋 | .gitignore 추가 |
| 과도한 권한 요청 | 최소 Scope |
| API 호출 무한 루프 | 에러 핸들링 |
| WebFetch로 Google URL 접근 | Python API 사용 |

## 트러블슈팅

| 증상 | 해결 |
|------|------|
| 인증 오류 | token.json 삭제 후 재인증 |
| 권한 오류 (403) | API 활성화 + Scope 확인 |
| storageQuotaExceeded | 서비스 계정 -> OAuth 전환 |
| 할당량 초과 (429) | 지수 백오프 재시도 |

## 상세 참조
API 코드 예시, 스타일 상세, PRD 관리 시스템, 이미지 삽입, 다이어그램 생성: `REFERENCE.md`
