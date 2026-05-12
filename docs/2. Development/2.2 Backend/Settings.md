---
title: Settings (Backend Env)
owner: team2
tier: internal
last-updated: 2026-05-12
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "Backend env-driven settings (export folders + export_defaults JSON). Frontend `pref.*` 키의 system default 권위 정본 — `api_db_export_folder/export_logs_folder/export_defaults`."
---

# Backend Settings — 환경변수 기반 system default 정본

본 문서는 EBS Back Office 컨테이너가 환경변수에서 읽어 들이는 **사용자 prefence 의 system default** 정본 spec 이다. Frontend (`docs/2. Development/2.1 Frontend/Settings/{UI,Preferences}.md`) 의 `pref.*` 키는 사용자별 override 권한을 가지며, 미설정 시 본 문서의 env-driven default 가 적용된다.

> **2026-05-12 Cycle 4 (#264)**: 기존 Frontend Settings 의 backtick 형태 spec key (`pref.api_db_export_folder`, `pref.export_logs_folder`, `preferences.export_defaults`) 의 권위 정본을 본 문서로 이전. spec_drift_check `--settings` D2 (frontend 미구현) 분류를 backend env-driven 으로 재정의 — 본 키들은 frontend UI 우선이 아닌 backend 환경 설정 우선임을 명시.

---

## 1. 변경 이력

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-05-12 | 신규 작성 (Cycle 4 #264) | api_db_export_folder + export_logs_folder + export_defaults env spec 신설. `team2-backend/src/app/config.py` + `docker-compose.yml` 정합. |

---

## 2. 위치 & 우선순위

```
정본 1순위    : team2-backend/src/app/config.py  (Settings dataclass 필드)
정본 2순위    : team2-backend/docker-compose.yml  (compose env: 매핑)
파생 view    : docs/2.1 Frontend/Settings/UI.md  (UI 사용자 표현)
파생 view    : docs/2.1 Frontend/Settings/Preferences.md  (UI 사용자 표현)
```

읽기 순서 (runtime):

```
.env / 환경변수 (override)
    ↓
src/app/config.py Settings 인스턴스 필드 (default 정의)
    ↓
사용자 preference (DB user_preferences 행) — 사용자 명시 override
    ↓
API 응답 / UI 표시
```

**기본 정책**: env 미설정 시 컨테이너는 안전한 default 로 동작한다. 사용자 preference 가 비어 있으면 env default 가 노출된다.

---

## 3. 키 카탈로그

### 3.1 `api_db_export_folder`

| 항목 | 값 |
|------|-----|
| env 변수 | `API_DB_EXPORT_FOLDER` |
| config 필드 | `settings.api_db_export_folder` (`team2-backend/src/app/config.py`) |
| default | `/app/data/exports/db` |
| 타입 | 절대 경로 string (POSIX, 컨테이너 내부) |
| 용도 | 핸드/대회 데이터를 DB dump 형태로 export 할 때 사용되는 디렉토리. Admin only API export endpoint 가 본 경로에 산출물 저장. |
| frontend 대응 | `pref.api_db_export_folder` (`docs/2.1 Frontend/Settings/UI.md` Export 섹션) — FolderPicker UI 로 사용자가 override 가능. 단 사용자 권한이 컨테이너 내부 경로에 한정됨 (host bind mount 후 host path 매핑은 운영자 책임). |

**docker-compose volume bind 권장**:

```yaml
services:
  bo:
    environment:
      - API_DB_EXPORT_FOLDER=/app/data/exports/db
    volumes:
      - bo-exports-db:/app/data/exports/db
```

### 3.2 `export_logs_folder`

| 항목 | 값 |
|------|-----|
| env 변수 | `EXPORT_LOGS_FOLDER` |
| config 필드 | `settings.export_logs_folder` |
| default | `/app/data/exports/logs` |
| 타입 | 절대 경로 string |
| 용도 | Audit log / system log 일괄 export 시 산출물 저장 경로. `audit_events` 테이블 일괄 dump endpoint 가 사용. |
| frontend 대응 | `pref.export_logs_folder` (UI.md Export 섹션) — FolderPicker UI override 가능. |

### 3.3 `export_defaults`

| 항목 | 값 |
|------|-----|
| env 변수 | `EXPORT_DEFAULTS` |
| config 필드 | `settings.export_defaults` |
| default | JSON 문자열 — 아래 JSON 본문 참조 |
| 타입 | JSON 문자열 (config 읽을 때 `json.loads` 후 dict) |
| 용도 | Export 산출물의 기본 옵션 (포맷, 헤더 포함 여부, 행 제한 등). 사용자가 individual export 시 override 하지 않으면 본 값 적용. |
| frontend 대응 | `preferences.export_defaults` (`docs/2.1 Frontend/Settings/Preferences.md` §7) — JSON object form 으로 사용자 override. |

**기본 JSON**:

```json
{
  "format": "csv",
  "includeHeaders": true,
  "maxRows": 100000,
  "timezone": "UTC",
  "compression": "none"
}
```

| 필드 | 값 | 의미 |
|------|------|------|
| `format` | `csv` \| `json` \| `xlsx` | 산출물 포맷 |
| `includeHeaders` | bool | 헤더 행 포함 여부 (csv/xlsx 한정) |
| `maxRows` | int | 산출물 최대 행 수 (메모리 보호) |
| `timezone` | string (IANA TZ) | 타임스탬프 표현 TZ |
| `compression` | `none` \| `gzip` \| `zip` | 산출 파일 압축 |

---

## 4. 사용 흐름 (Runtime)

```
[1] 컨테이너 기동
    docker compose up -d
       ↓
    pydantic-settings 가 .env / env vars 읽기
       ↓
    Settings.api_db_export_folder = "/app/data/exports/db"  (또는 env override)
       ↓
[2] API 호출 (예: GET /api/v1/admin/exports/db)
    admin 권한 검증 → settings.api_db_export_folder 디렉토리에 산출물 저장
       ↓
[3] 사용자 preference 조회 (GET /api/v1/Users/{me}/Preferences)
    user_preferences 행에 pref.api_db_export_folder 가 비어 있으면
    응답 default 로 settings.api_db_export_folder 노출
       ↓
[4] 사용자 override (PUT /api/v1/Users/{me}/Preferences)
    body 에 {"pref.api_db_export_folder": "/data/custom"} → user_preferences 행 갱신
    이후 GET 응답은 사용자 값 우선
```

---

## 5. 운영 메모

| 항목 | 내용 |
|------|------|
| 권한 | export endpoint 는 Admin only (`require_role("admin")`). Operator/Viewer 는 본 경로에 직접 접근하지 않음. |
| 디스크 안전 | 산출물 누적 방지를 위해 cron / 운영 절차로 주기 정리. SG-008-b1 audit retention 정책과 연계. |
| 컨테이너 격리 | 본 경로는 항상 컨테이너 내부 절대 경로. host 와의 매핑은 `docker-compose.yml` volumes 섹션 책임. |
| dev 검증 | `docker exec ebs-bo python -c "from src.app.config import settings; print(settings.api_db_export_folder, settings.export_logs_folder)"` |

---

## 6. 관련 문서

- 정본 1차 spec: 본 문서
- Frontend UI 표현: `../2.1 Frontend/Settings/UI.md` (Export 섹션)
- Frontend Preferences JSON: `../2.1 Frontend/Settings/Preferences.md` §7
- 컨테이너 env 매핑: `../../../team2-backend/docker-compose.yml`
- config 코드: `../../../team2-backend/src/app/config.py`
- spec drift gate: `tools/spec_drift_check.py --settings` (Cycle 4 후 backend D2 3건 해소)
