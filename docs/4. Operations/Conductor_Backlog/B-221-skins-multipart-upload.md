---
id: B-221
title: "B-221 — POST /api/v1/skins/upload multipart endpoint (CCR-013, D8 resolution)"
owner: team2
tier: internal
status: IMPLEMENTED
type: backlog
severity: HIGH
blocker: false
source: docs/2. Development/2.5 Shared/Authentication/D6_D7_D8_Decision_2026-05-10.md
related-issue: 196
last-updated: 2026-05-10
implemented-at: 2026-05-10
implemented-by: conductor (Issue #196 cascade)
---

## 개요

Issue #196 D8 결정 — CCR-013 §1 spec 정합 (.gfskin ZIP multipart upload) backend 구현. 기존 `POST /api/v1/skins`는 JSON metadata만 처리, 실제 .gfskin 파일 업로드 endpoint 부재. Conductor 결정 (a)에 따라 신규 endpoint 추가.

## 작업 (완료)

| 변경 | 파일 |
|------|------|
| `POST /api/v1/skins/upload` multipart endpoint 신규 | `team2-backend/src/routers/skins.py` |
| `_validate_gfskin_bytes` helper (`tools/validate_gfskin.py` 재사용) | 동 파일 |
| `SKINS_STORAGE_ROOT` env-driven storage path | 동 파일 |
| `MAX_GFSKIN_BYTES` 50MB SG-004 guard | 동 파일 |
| Decision cascade 문서 | `docs/2. Development/2.5 Shared/Authentication/D6_D7_D8_Decision_2026-05-10.md` |

## 검증

```bash
# Healthcheck (sample .gfskin로)
curl -X POST http://localhost:8000/api/v1/skins/upload \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -F "file=@sample.gfskin"

# 예상 응답: 201 + manifest meta
# 위반 케이스: 422 + SG-004 code (GFSKIN_*)
```

## 완료 기준

- [x] `POST /api/v1/skins/upload` 등록 (admin role)
- [x] 7-stage validation (validate_gfskin.py 재사용)
- [x] SG-004 error codes 13종 매핑
- [x] Storage 경로 env-driven
- [x] Skin row 생성 + manifest metadata mirror
- [x] D6/D7 cascade 문서

## 향후 (별도 백로그)

- B-222 (선택): JSON-only `POST /skins` deprecation timeline
- DELETE `/skins/{id}` storage cleanup
- Storage backend 추상화 (S3 등)

## 참조

- Issue #196: https://github.com/garimto81/ebs_github/issues/196
- D6/D7/D8 Decision Cascade: `docs/2. Development/2.5 Shared/Authentication/D6_D7_D8_Decision_2026-05-10.md`
- SG-004 .gfskin format: `docs/4. Operations/Conductor_Backlog/SG-004-gfskin-zip-format.md`
- CCR-013: `docs/2. Development/2.1 Frontend/Graphic_Editor/References/CCR-013.md` (또는 동등 위치)
- Validator: `tools/validate_gfskin.py`
