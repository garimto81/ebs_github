# BS-01-02 RBAC — Permission Bit Flag

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | 문자열 역할 → Permission Bit Flag 확장 (CCR-017) |

---

## 개요

기존 EBS는 문자열 역할(`admin/operator/viewer`)로 RBAC를 체크했다. 본 문서는 WSOP LIVE parity를 위해 역할과 **별도로** `Permission Bit Flag`를 도입하여 **리소스별 세분화된 권한**을 표현한다.

> **참조**: 역할 정의는 `BS-01-auth.md §RBAC`. 엔드포인트별 역할 매트릭스는 각 API-0X 문서 하단.

---

## 1. 역할 (Role) — 기존 유지

| Role | 권한 범위 |
|------|----------|
| **Admin** | 전체 권한 (Series, Event, Flight, Table, Seat, Settings) |
| **Operator** | 할당 테이블 CC만 write 가능, 그 외 read |
| **Viewer** | 전체 read-only |

JWT payload에는 `role` 문자열과 `permission` 정수 필드가 **동시**에 포함된다. 기존 코드는 `role`을, 신규 코드는 `permission`을 사용해 점진 마이그레이션.

---

## 2. Permission Bit Flag

```
Permission {
  None   = 0     // 0b000 — 접근 차단
  Read   = 1     // 0b001 — 조회
  Write  = 2     // 0b010 — 생성/수정
  Delete = 4     // 0b100 — 삭제
}
```

### 2.1 조합

비트 연산으로 여러 권한을 동시에 표현한다:

| 값 | 2진 | 의미 |
|---:|-----|------|
| 0 | 000 | None (접근 차단) |
| 1 | 001 | Read only |
| 3 | 011 | Read + Write |
| 5 | 101 | Read + Delete (드물게 사용) |
| 7 | 111 | Read + Write + Delete (full) |

### 2.2 판정

클라이언트는 비트 연산으로 버튼/액션 활성화를 판단한다. **문자열 비교 금지**.

```typescript
// 올바른 사용
if ((user.permission & Permission.Write) !== 0) {
  showEditButton();
}

// 금지 (폐기됨)
if (user.role === 'admin' || user.role === 'operator') { ... }
```

---

## 3. 역할 × 리소스 권한 매트릭스

| 리소스 | Admin | Operator (자기 할당) | Operator (타 테이블) | Viewer |
|--------|:-----:|:--------------------:|:-------------------:|:------:|
| Series | 7 | 1 | 1 | 1 |
| Event | 7 | 1 | 1 | 1 |
| Flight | 7 | 1 | 1 | 1 |
| Table | 7 | 3 | 1 | 1 |
| Seat | 7 | 7 | 1 | 1 |
| Player | 7 | 7 | 1 | 1 |
| Settings.Rules | 7 | 3 | 1 | 1 |
| Settings.Outputs | 7 | 3 | 1 | 1 |
| Settings.GFX | 7 | 1 | 1 | 1 |
| Settings.Display | 7 | 1 | 1 | 1 |
| Graphic Editor (BS-08) | 7 | 1 | 1 | 0 |

**설명**:
- Operator는 자기 할당 테이블의 Table/Seat/Player/Rules/Outputs에 write 권한 (3 = Read + Write).
- Operator의 GFX/Display는 read-only (1) — 글로벌 설정이라 수정 권한 없음.
- Viewer는 Graphic Editor 탭 접근 차단 (0, BS-08-04 GER-03).
- Admin은 모든 리소스에 full (7).

---

## 4. 서버 판정 로직

서버는 각 엔드포인트에서 **역할 + 리소스 할당 + 권한 비트**를 조합해 판정한다.

```python
# FastAPI dependency 의사 코드
def require_permission(resource: str, required: Permission):
    def checker(current_user: User = Depends(get_user)):
        perm = compute_permission(current_user, resource)
        if (perm & required) == 0:
            raise HTTPException(403, "AUTH_PERMISSION_DENIED")
        return current_user
    return checker

def compute_permission(user: User, resource: str) -> int:
    if user.role == "admin":
        return 7  # full
    if user.role == "operator":
        if is_own_table_resource(user, resource):
            return TABLE_RESOURCE_PERMISSIONS[resource]  # 매트릭스
        return 1  # other = read only
    if user.role == "viewer":
        if resource == "graphic_editor":
            return 0
        return 1
    return 0
```

---

## 5. JWT payload 예시

```json
{
  "sub": "user_01HVQK...",
  "role": "operator",
  "permission": 3,
  "assigned_tables": ["tbl_01", "tbl_05"],
  "exp": 1743251456,
  "iat": 1743208256
}
```

- `role`: 기존 호환용 문자열
- `permission`: 클라이언트가 UI 게이트에 사용하는 기본 비트 (리소스별 세분화는 서버 API 호출 시 확정)
- `assigned_tables`: Operator가 write 할 수 있는 테이블 ID 목록

---

## 6. 마이그레이션

기존 문자열 역할 코드를 유지하면서 `permission` 필드를 **추가**한다.

**단계**:
1. **Phase 1**: JWT payload에 `permission` 추가 (기존 코드 영향 없음)
2. **Phase 2**: 클라이언트 코드를 비트 연산으로 점진 교체
3. **Phase 3**: 서버 권한 판정 로직을 비트 기반으로 전환
4. **Phase 4**: `role` 문자열은 로깅/표시 용으로만 유지

---

## 7. 에러 응답

비트 권한 부족 시 403 Forbidden:

```json
{
  "error": "AUTH_PERMISSION_DENIED",
  "message": "이 작업에 필요한 권한이 없습니다.",
  "required_permission": 2,
  "current_permission": 1,
  "resource": "settings.rules"
}
```

---

## 8. 연관 문서

- `BS-01-auth.md` — 역할 정의 및 JWT lifecycle
- `API-06-auth-session.md` — 로그인/refresh 응답에 `permission` 필드 포함
- `BS-08-04-rbac-guards.md` — Graphic Editor의 RBAC 특화 규칙
- `CCR-017` — 본 문서 신설 근거 (WSOP LIVE parity)
