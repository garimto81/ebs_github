---
id: IMPL-005
title: "구현: team2 API 48 D2 endpoint 라우터 실구현 (SG-008-a 후속)"
type: implementation
status: SCANNER_FALSE_POSITIVE_DOMINANT  # 실제 누락은 소수, 대부분 scanner prefix 매칭 한계
owner: team2
created: 2026-04-26
analyzed: 2026-04-26
spec_ready: true
blocking_spec_gaps:
  - SG-010 (scanner 정밀화 — api detector 의 router prefix 인식)
  - SG-008-b1~b9 (default 옵션 채택 confirm)
  - SG-008-b10~b12 (삭제 권고 endpoint)
implements_chapters:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.17
related_code:
  - team2-backend/src/routers/  (auth/configs/sync/skins/blind_structures/payout_structures 등 이미 존재)
---

## 2026-04-26 분석 결과 — Scanner False Positive Dominant

**핵심 발견**: 48 D2 중 대다수는 실제 코드 미구현이 아닌 **scanner prefix 매칭 한계** (SG-010).

### 검증

team2-backend/src/routers/ 디렉토리에 이미 다음 라우터 존재:
- `auth.py` — `/auth/me`, `/auth/session`, `/auth/logout` 모두 구현됨 (line 230, 239, 249)
- `configs.py` — `/configs`, `/configs/output`, `/configs/resolved` 라우터 존재
- `sync.py` — `/sync/mock-seed`, `/sync/mock-reset`, `/sync/trigger` 존재
- `skins.py` — upload/download endpoint 존재
- `blind_structures.py`, `payout_structures.py` — CRUD 존재

**Scanner 한계**: 코드의 router prefix (`APIRouter(prefix="/auth")`) + 메인 앱 mount (`app.mount("/api/v1")`) 합성 시 effective path 가 `/api/v1/auth/me` 인데, scanner 는 router 파일 단위로 `/auth/me` 만 추출 → spec `/api/v1/auth/me` 와 mismatch.

### 실제 누락 endpoint (검증 후 분류 필요)

| 그룹 | 가능 누락 | 비고 |
|------|----------|------|
| A. Series sub-resources | `DELETE /series/{_}/blind-structures/{_}` 등 — 라우터 존재하나 DELETE handler 누락 가능 | 검증 필요 |
| B. Skin metadata | `GET /api/v1/skins/{_}/metadata` — SG-021 (Rive 내장 메타데이터) 후속 | SG-021 결정 후 |
| C. Phase 1 미지원 (삭제 권고) | `POST /events/{_}/undo`, `POST /tables/{_}/launch-cc` | SG-008-b10/b11 default 채택 = 삭제 |
| D. Sync mock | `POST /api/v1/sync/mock-seed/reset` — 라우터 존재하나 prefix drift 가능 | 검증 필요 |

### 권장 작업 (후속)

1. **SG-010 우선**: scanner 의 router prefix 인식 개선 → 대부분의 D2 가 자동 해소
2. **그룹 A 검증**: 각 series/blind-structures/payout-structures 의 GET/POST/DELETE/PATCH 4 verb 모두 구현되어 있는지 router 파일 단위 검증
3. **그룹 C 삭제**: SG-008-b10/b11 default 옵션 (Phase 1 미지원 → 삭제) 확정 시 endpoint 제거
4. **그룹 B**: SG-021 (Rive 메타데이터) 결정 후 진행

본 IMPL-005 는 **단일 PR 로 해결 불가** — scanner 정밀화 + 그룹별 분해 필요.

---

> **현재 권고**: 본 IMPL-005 를 IMPL-005-A (그룹 A 검증), IMPL-005-B (스캐너 정밀화), IMPL-005-C (삭제 PR) 로 분해. Conductor 단일 세션 범위 초과.

# IMPL-005 — team2 API 48 D2 endpoint 라우터 실구현

## 배경

2026-04-26 fresh scan: api 계약 D2=48 (baseline 42 + 6 신규). Backend_HTTP §5.17 에 77개 endpoint 가 편입 완료되었으나 라우터 실구현이 대기 상태. 일부는 SG-008-b 옵션 채택 후 추가된 신규 endpoint.

## 48개 D2 분류

scan 결과 head (logs/drift_report_2026-04-26.json):

```
DELETE /auth/session                       ← SG-008-b5 (logout 옵션 1)
DELETE /series/{_}/blind-structures/{_}    ← CRUD 완결 (b 옵션 default 권고)
DELETE /series/{_}/payout-structures/{_}   ← CRUD 완결
GET    /api/session/{_}                    ← legacy prefix 정정 검토 (SG-008 a)
GET    /api/v1/auth/me                     ← SG-008-b4 (옵션 1 확장)
GET    /api/v1/skins/{_}/metadata          ← SG-021 신설 (Rive 내장 메타 후속)
GET    /api/v1/tables/{_}/state/snapshot   ← SG-008 a 핵심
GET    /configs                            ← SG-008 a CRUD 완결
GET    /configs/output                     ← SG-008 a
GET    /configs/resolved                   ← SG-008 a
GET    /events/replay                      ← SG-008-b10 default (Phase1 미지원 — 삭제 권고)
GET    /events/{_}/blind-structure         ← SG-008 a CRUD
... (총 48건)
```

## 우선순위 그룹

| 그룹 | 처리 | 비고 |
|------|------|------|
| **A. 핵심 CRUD 완결 (~30건)** | 라우터 skeleton 실구현 | DB 모델 존재 (SG-008 a 편입) |
| **B. SG-008-b1~b9 옵션 반영 (~10건)** | default 옵션 채택 후 구현 | SG-008-b1~b9 confirm 필요 |
| **C. SG-008-b10~b12 삭제 권고 (~3건)** | code 삭제 또는 endpoint 미노출 | 사용처 검증 필수 |
| **D. SG-021 후속 (~2건)** | Rive 메타데이터 endpoint (skin upload/validate) | SG-021 결정 후 |
| **E. 미분류 (~3건)** | scanner 정밀화 후 재판정 (SG-010) | api detector prefix drift 흡수 잔재 |

## 수락 기준

- [ ] team2: 그룹 A 30건 라우터 실구현 (Backend_HTTP §5.17 명세 준수)
- [ ] team2: 그룹 B 10건 SG-008-b1~b9 default 채택 후 구현
- [ ] team2: 그룹 C 3건 endpoint 삭제 + B-088 Backend_HTTP 행 제거
- [ ] team2: 그룹 D 2건 SG-021 결정 후 구현
- [ ] team2: pytest 247 baseline + 신규 시나리오 추가 (각 endpoint 최소 1 happy path)
- [ ] conductor: scan 재실행 → api D2 ≤ 5 (그룹 E 잔여 + scanner 잔재)
- [ ] conductor: `Spec_Gap_Registry §4.1 REST API` 행 갱신

## 구현 메모

- SG-008-b 옵션 채택 confirm 패턴: 각 SG 파일 frontmatter `default 권고` 채택 시 commit 메시지에 `confirms: SG-008-b{N}` 표기
- Backend_HTTP §5.17 의 envelope 패턴 (data/error/pagination) 준수
- 기존 247 pytest baseline 회귀 0 보장
