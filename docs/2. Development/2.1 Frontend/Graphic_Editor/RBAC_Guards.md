---
title: RBAC Guards
owner: team1
tier: internal
legacy-id: BS-08-04
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-08-04 RBAC 가드 기획 완결"
---
# BS-08-04 RBAC Guards — Admin/Operator/Viewer 게이트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | UI + API 이중 RBAC gate 행동 매트릭스 (CCR-011) |

---

## 개요

Graphic Editor는 Admin 전용 편집 기능이다. 권한은 **UI gate** (클라이언트 측 버튼/메뉴 숨김)와 **API gate** (서버 측 403 응답) 이중으로 강제한다. Viewer는 GE 탭 자체에 접근할 수 없다.

> **범위**: GER-01~05 (BS-00 §7.4).

---

## 1. 역할 × 행동 매트릭스

| 행동 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| GE 탭 접근 | ✓ | ✓ | ✗ (GER-03) |
| 스킨 목록 조회 | ✓ | ✓ | — |
| 스킨 프리뷰 | ✓ | ✓ | — |
| 메타데이터 조회 | ✓ | ✓ (GER-02) | — |
| **Upload `.gfskin`** | ✓ | ✗ (GER-01) | — |
| **PATCH metadata** | ✓ | ✗ (GER-01) | — |
| **PUT activate** | ✓ | ✗ (GER-01) | — |
| **DELETE skin** | ✓ | ✗ (GER-01) | — |
| Active skin 확인 | ✓ | ✓ | — |

---

## 2. UI Gate (GER-01 ~ GER-03)

### 2.1 GE 탭 접근 (GER-03)

- **Viewer 로그인**: Lobby 사이드바에 "Graphic Editor" 메뉴 항목 **숨김**
- **Viewer가 직접 URL 접근** (`/lobby/graphic-editor`): 라우터 가드가 감지 → `/lobby/unauthorized` redirect
- **라우터 가드 구현**: `go_router` `redirect` callback 에서 Riverpod `authProvider.role` 확인 (2026-04-21 Flutter 전환)

### 2.2 Admin 전용 버튼 (GER-01)

다음 버튼은 **Operator/Viewer 세션에서 DOM 생성 자체가 되지 않는다**:

- "Upload `.gfskin`"
- "Edit metadata"
- "Activate"
- "Delete"

Operator 세션은 읽기 전용 뷰만 표시:

- 스킨 목록
- 프리뷰 canvas (비인터랙티브)
- 메타데이터 필드 (disabled input)

### 2.3 Operator 읽기 전용 (GER-02)

- 모든 폼 필드 `disabled` 또는 `readonly`
- 편집 툴팁 비활성화
- 상단에 배너: "읽기 전용 모드 — 편집 권한이 필요합니다"

---

## 3. API Gate (GER-04)

UI gate는 악의적 클라이언트가 우회할 수 있으므로, 서버가 모든 mutation 엔드포인트에서 역할을 재검증한다.

### 3.1 보호 대상 엔드포인트

| Method | Path | 최소 역할 |
|--------|------|-----------|
| POST | /api/v1/skins | Admin |
| PATCH | /api/v1/skins/{id}/metadata | Admin |
| PUT | /api/v1/skins/{id}/activate | Admin |
| DELETE | /api/v1/skins/{id} | Admin |
| GET | /api/v1/skins | Admin, Operator |
| GET | /api/v1/skins/{id} | Admin, Operator |
| GET | /api/v1/skins/{id}/metadata | Admin, Operator |
| GET | /api/v1/skins/active | Admin, Operator, (CC service account) |

### 3.2 권한 검증 로직

```
FastAPI dependency:
  require_role(["Admin"])
    ↓
  JWT payload에서 role 추출
    ↓
  role not in allowed_roles?
    → 403 Forbidden + ErrorCode "AUTH_ROLE_DENIED"
  else:
    → handler 진입
```

### 3.3 403 응답 포맷

```json
{
  "error": "AUTH_ROLE_DENIED",
  "message": "이 작업은 Admin 권한이 필요합니다.",
  "required_role": "Admin",
  "current_role": "Operator"
}
```

---

## 4. 에러 UX (GER-05)

403 응답을 받으면 클라이언트는 **토스트 알림**을 표시한다 (라우팅/로그아웃 없음):

- **Operator**: "Admin 권한이 필요한 작업입니다. Admin에게 문의하세요."
- **Viewer가 직접 API 호출 시도** (URL bar 등): "접근 권한이 없습니다." + 즉시 `/lobby/unauthorized` redirect

로그: 403은 서버 audit log에 `role_deny` 이벤트로 기록되어 감사 추적에 활용.

---

## 5. CC Service Account 예외

CC(Team 4 Flutter)는 사용자 로그인이 아니라 **서비스 계정** 토큰으로 인증된다. 이 토큰은 `role: "cc_service"` 을 가지며:

- `GET /api/v1/skins/active` — 허용 (현재 active skin 확인)
- `GET /api/v1/skins/{id}` — 허용 (`.gfskin` 다운로드)
- 그 외 mutation — 거부

CC 서비스 계정 토큰 발급은 `BS-01-auth.md` 참조.

---

## 6. RBAC 행동 테스트 시나리오

1. **Viewer로 로그인** → `/lobby/graphic-editor` 직접 접근 → `/lobby/unauthorized` redirect 확인
2. **Operator로 로그인** → GE 탭 진입 → 리스트 표시 확인, Upload 버튼 **부재** 확인
3. **Operator가 curl로 직접 POST** → 403 응답 + `AUTH_ROLE_DENIED` 확인
4. **Admin으로 로그인** → 전체 CRUD 수행 → 각 응답 코드 확인

---

## 7. 요구사항 매핑

| ID | 섹션 |
|----|------|
| GER-01 Admin 전용 버튼 표시 | §2.2 |
| GER-02 Operator 읽기 전용 | §2.3 |
| GER-03 Viewer 탭 차단 | §2.1 |
| GER-04 API gate | §3 |
| GER-05 403 에러 UX | §4 |

---

## 8. 연관 문서

- `BS-01-auth.md §RBAC` — 역할 정의
- `API-06-auth-session.md` — JWT 페이로드 구조
- `API-07-graphic-editor.md §RBAC` — 엔드포인트별 최소 역할
- `BS-08-01~03` — Admin 동작 플로우
