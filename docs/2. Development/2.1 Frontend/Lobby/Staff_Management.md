---
title: Staff Management
owner: team1
tier: feature
last-updated: 2026-04-16
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "Staff 관리 기획 완결 (WSOP LIVE parity)"
---
# Staff Management

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "02. Staff Admin" (Confluence p1597800711) + "10. Special Staff Permissions" (p1664516856) + "Staff Role 관련 기획" (p1900216321) + "Role 설정 효율화" (p3717955592) 기반 |

---

## 개요

Staff 계정 CRUD, Role 관리, Permission Matrix 설정 화면. WSOP LIVE Staff App §02 Staff Admin + §10 Special Staff Permissions 의 Role 체계를 EBS 3-Role (Admin/Operator/Viewer) 에 매핑하고, 향후 확장 가능한 구조로 설계한다.

---

## 1. 기능 범위

| 기능 | 설명 |
|------|------|
| **계정 CRUD** | Staff 계정 생성/수정/삭제. Email + Password + Role 설정 |
| **Role 목록** | 기본 Role 3종 + 특수 Role (Chip Reporter, Clock Display) |
| **Permission Matrix** | Role별 페이지/기능 접근 권한 매트릭스 편집 |
| **Role Export/Import** | CSV 기반 Role 설정 Export/Import (시리즈 간 재사용) |
| **계정 일괄 생성** | 특수 Role (Dealer, Chip Reporter 등) 대량 계정 생성 |
| **Force Logout** | 활성 세션 강제 종료 |
| **Account Lock** | 계정 비활성화 (is_active=false) |

---

## 2. 화면 구조

### 2.1 Staff 목록

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Email | 읽기 전용 + 링크 | 클릭 시 상세 |
| Display Name | 읽기 전용 | |
| Role | Badge | Admin / Operator / Viewer / Chip Reporter 등 |
| Status | Badge | Active / Locked |
| Last Login | 읽기 전용 | |

필터: Role Dropdown, Search by Name/Email

### 2.2 Staff 생성/편집

| 필드 | 컨트롤 | 기본값 | Validation |
|------|--------|--------|-----------|
| Email | Input (email) | — | 필수, 중복 불가 |
| Password | Input (password) | — | 최소 8자 |
| Confirm Password | Input (password) | — | Password 일치 검증 |
| Display Name | Input (text) | — | 필수 |
| Role | Dropdown | Operator | |

### 2.3 Role & Permission Matrix

| Role | 기본 | 권한 수정 | 비고 |
|------|:----:|:---------:|------|
| Admin (= TD) | O | 가능 | 전체 접근 |
| Operator (= Floor/TA) | O | 가능 | 할당 테이블 한정 |
| Viewer | O | 가능 | 읽기 전용 |
| Chip Reporter | O | 불가 (고정) | 칩 입력만 |
| Clock Display | O | 불가 (고정) | Clock 읽기 전용 |

**WSOP LIVE → EBS Role 매핑:**

| WSOP LIVE Role | EBS Role | 비고 |
|---------------|---------|------|
| SysOp | Admin | 시스템 최상위 |
| Staff Admin | Admin | 계정 관리 |
| Tournament Director (TD) | Admin | 대회 총괄 |
| Tournament Admin (TA) | Operator | 대회 운영 |
| Floor Manager | Operator | 현장 관리 |
| Table Dealer | Operator (테이블 한정) | CC 접근만 |
| Chip Reporter | Chip Reporter | 특수 Role |
| Clock Display | Clock Display | 특수 Role |

### 2.4 Role Export/Import

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| 체크박스 | 각 Role 앞 | Bulk Export 선택 |
| Bulk Export CSV (N) | 버튼 | 선택 Role 설정 다운로드 |
| Bulk Upload | 버튼 | 동일 명칭 존재 시 Error |
| 단건 Export | Role 편집 내 버튼 | |
| 단건 Import | Role 편집 내 버튼 | 이름은 적용 안 함, 설정만 |

---

## 3. 데이터 흐름

| 동작 | API | 비고 |
|------|-----|------|
| Staff 목록 | `GET /Users` | Backend_HTTP §5.2 |
| Staff 생성 | `POST /Users` | role 필드 포함 |
| Staff 수정 | `PUT /Users/:id` | |
| Staff 삭제 | `DELETE /Users/:id` | |
| Force Logout | 미정의 | 미결: CCR 필요 |
| Role Permission 조회/수정 | 미정의 | 미결: CCR 필요 |
| Role Export/Import | 미정의 | 미결: CCR 필요 |

---

## 4. RBAC

| 동작 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| Staff 목록 조회 | O | X | X |
| Staff 생성/수정/삭제 | O | X | X |
| Role Permission 편집 | O | X | X |
| Role Export/Import | O | X | X |
| Force Logout / Account Lock | O | X | X |

---

## 5. WSOP LIVE Parity

| WSOP LIVE 기능 | EBS 적용 | 비고 |
|---------------|:-------:|------|
| Staff 계정 CRUD | Apply | `/Users` API |
| 특수 Role 권한 고정 (Chip Reporter, Clock Display 등) | Apply | |
| 대량 계정 생성 (연번 이메일) | Apply | @ebs.local 도메인 |
| Series Display On/Off | Remove | EBS에 Player App 없음 |
| Series Complete/Disable | Apply | Series 레벨 관리에서 처리 |
| Role Export/Import CSV | Add | WSOP LIVE 2026 개선사항 반영 |
| Role Copy/Paste Configuration | Add | WSOP LIVE 2026 개선사항 반영 |

---

## 6. 미결 사항

- 미결: CCR 필요 — Role Permission Matrix 상세 (페이지/기능별 접근 제어 목록)
- 미결: CCR 필요 — Force Logout / Account Lock API 엔드포인트
- 미결: CCR 필요 — Role Export/Import CSV 포맷 정의
- 미결: CCR 필요 — Phase 2 GGPass S2S 연동 시 Staff 동기화 전략 (Backend_HTTP §14)
