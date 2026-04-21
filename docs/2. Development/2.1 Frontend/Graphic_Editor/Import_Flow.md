---
title: Import Flow
owner: team1
tier: internal
legacy-id: BS-08-01
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-08-01 import 플로우 기획 완결"
---
# BS-08-01 Import Flow — `.gfskin` 업로드 FSM

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | ZIP 검증·JSON Schema 검증·Rive 파싱·업로드 FSM (CCR-011, GEI-01~08) |

---

## 개요

Admin이 `.gfskin` 파일을 Lobby GE 탭에서 업로드하는 흐름을 정의한다. 클라이언트와 서버가 동일한 검증 로직(DATA-07 §4)을 수행하며, 클라이언트는 업로드 전 프리뷰까지 제공한다.

> **범위**: GEI-01~08 (BS-00 §7.4).

---

## 1. Upload FSM

```
idle
  ↓ user picks file (GEI-01)
picking
  ↓ file selected (.gfskin extension)
validating_zip
  ↓ ZIP 구조 OK (GEI-02)
parsing_json
  ↓ skin.json 파싱 OK (GEI-03)
validating_schema
  ↓ DATA-07 JSON Schema 통과 (GEI-04)
parsing_rive
  ↓ skin.riv 파싱 OK (GEI-05)
previewing
  ↓ rive-js 렌더링 OK (GEI-06)
  ↓ user confirms
uploading
  ↓ POST /skins multipart 성공 (GEI-07)
saved
  ↓ user returns to list

실패 경로 (어느 상태에서나):
  → failed
    (GEI-08: 에러 메시지 + 재시도 또는 취소)
```

---

## 2. 상태별 상세

### 2.1 validating_zip (GEI-02)

- **입력**: 사용자가 선택한 파일 (extension `.gfskin`)
- **검증**:
  - ZIP magic bytes (`PK\x03\x04`)
  - 내부 엔트리 목록에 `skin.json` 존재 (루트)
  - 내부 엔트리 목록에 `skin.riv` 존재 (루트)
- **실패**: "잘못된 `.gfskin` 파일 — 필수 엔트리가 누락되었습니다" (목록 첨부)
- **기술**: `jszip`

### 2.2 parsing_json (GEI-03)

- **입력**: `skin.json` 바이트
- **처리**: UTF-8 디코딩 + `JSON.parse`
- **실패**: "`skin.json` 파싱 실패: {error position}"

### 2.3 validating_schema (GEI-04)

- **입력**: 파싱된 `skin.json` 객체
- **처리**: `ajv` + `DATA-07-gfskin-schema.md §2` (`$id: https://ebs/schemas/gfskin-1.0.json`)
- **실패**: 첫 violation path 표시 (예: `"colors.badge_check: must match pattern ^#[0-9A-Fa-f]{6}$"`)

### 2.4 parsing_rive (GEI-05)

- **입력**: `skin.riv` 바이트
- **처리**: `rive-js`의 `Rive` 생성자에 전달 (`file` 옵션)
- **실패**: "Rive 파일 파싱 실패 — 지원 버전인지 확인하세요"

### 2.5 previewing (GEI-06)

- **입력**: Rive 인스턴스 + `skin.json`
- **렌더링**: Zone 중앙에 canvas (`@rive-app/canvas`), default artboard + state machine
- **상호작용**: 상태 전환 토글(선택), 해상도 전환 preview
- **종료**: 사용자가 "Upload 확정" 버튼 클릭

### 2.6 uploading (GEI-07)

- **요청**: `POST /api/v1/skins` (API-07 §1)
  - `Content-Type: multipart/form-data`
  - `Authorization: Bearer {adminJwt}`
  - `Idempotency-Key: {uuid4}` (필수, CCR-003)
  - body: `file` (`.gfskin`), `name` (선택 override)
- **응답 201**: `{id, version, etag, url}` → 리스트에 새 스킨 추가, FSM saved
- **응답 409**: Idempotency-Key 재사용 → UI는 이미 처리됨을 안내
- **응답 422**: 서버 JSON Schema 검증 실패 → 에러 path 표시
- **응답 403**: Admin 권한 부족 → GER-05

### 2.7 failed (GEI-08)

- **상태 누적**: 모든 실패 상태에서 수렴
- **UI**:
  - 에러 메시지 (사용자 읽을 수 있는 한글 문구)
  - 상세 정보 접기 (기술 상세, 디버깅용)
  - 재시도 또는 취소 버튼
- **로깅**: 클라이언트 콘솔 + 서버 에러 리포트

---

## 3. 대역폭 / 성능

| 항목 | 권장값 |
|------|--------|
| `.gfskin` 최대 크기 | 50 MB (서버 `413 Payload Too Large`) |
| ZIP 해제 메모리 | 클라이언트 `jszip` (스트리밍 불필요) |
| 프리뷰 렌더링 frame rate | 60 fps 목표 |
| 업로드 timeout | 60 s |

---

## 4. 요구사항 매핑

| ID | 상태 | 섹션 |
|----|------|------|
| GEI-01 | picking | §1 / §2.1 |
| GEI-02 | validating_zip | §2.1 |
| GEI-03 | parsing_json | §2.2 |
| GEI-04 | validating_schema | §2.3 |
| GEI-05 | parsing_rive | §2.4 |
| GEI-06 | previewing | §2.5 |
| GEI-07 | uploading | §2.6 |
| GEI-08 | failed | §2.7 |

---

## 5. 연관 문서

- `DATA-07-gfskin-schema.md` — JSON Schema 원본
- `API-07-graphic-editor.md §1` — POST /skins 엔드포인트
- `BS-08-02-metadata-editing.md` — 업로드 후 메타 편집 흐름
