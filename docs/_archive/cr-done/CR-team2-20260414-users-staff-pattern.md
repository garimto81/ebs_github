---
title: CR-team2-20260414-users-staff-pattern
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-users-staff-pattern
confluence-page-id: 3818587324
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818587324/EBS+CR-team2-20260414-users-staff-pattern
mirror: none
---

# CCR-DRAFT: Users 엔드포인트에 WSOP LIVE Staff 패턴 (Suspend/Lock/Download) 추가

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/api/`Backend_HTTP.md` (legacy-id: API-01), contracts/data/DATA-02-entities.md, contracts/data/DATA-04-db-schema.md, contracts/specs/BS-01-auth/BS-01-auth.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff App(`GET/PUT /Series/{sId}/Staffs/*`, Page 1597768061) 은 유저 생명주기 관리를 Suspend/Lock 2-축 패턴으로 운영. EBS 현행 API-01 §5.2 는 CRUD 5종만 보유하여 운영 관점 상태 제어(일시 정지, 보안 잠금) 수단이 부재. 정식 전체 개발 단계에서 WSOP LIVE 운영 패턴에 정렬 필요. 기존 CRUD는 Phase 1 초기 provisioning + 긴급 수정 용도로 유지.

## 변경 요약

1. `contracts/api/API-01 §5.2 Users` 에 엔드포인트 3종 추가: `GET /users/download` (CSV), `PUT /users/:id/suspend`, `PUT /users/:id/lock`
2. `contracts/data/DATA-02 §User` 에 필드 2개 추가: `is_suspended: bool`, `is_locked: bool`
3. `contracts/data/DATA-04 users 테이블` 에 컬럼 2개 추가: `is_suspended BOOLEAN NOT NULL DEFAULT false`, `is_locked BOOLEAN NOT NULL DEFAULT false`
4. `contracts/specs/BS-01-auth/BS-01-auth.md` 에 §Provisioning 섹션 신설 (Phase별 유저 생성 전략 + Suspend/Lock 의미 차이)

## Diff 초안

### contracts/api/`Backend_HTTP.md` (legacy-id: API-01) §5.2

```diff
 ### 5.2 Users — 사용자 관리

+> **WSOP LIVE 대응**: `GET/PUT /Series/{seriesId}/Staffs/*` (Page 1597768061). EBS는 상태 제어(Suspend/Lock) 패턴을 그대로 준거하고, Phase 1 초기 provisioning용 CRUD 엔드포인트를 보조 수단으로 병행 유지.
+
 | Method | Path | 설명 | 역할 제한 |
 |:------:|------|------|:---------:|
 | GET | `/users` | 사용자 목록 (filter: `?email=`, `?role=`, `?is_suspended=`, pagination `?page=&size=`) | Admin |
+| GET | `/users/download` | 사용자 목록 CSV 다운로드 (동일 필터) | Admin |
 | GET | `/users/:id` | 사용자 상세 | Admin |
 | POST | `/users` | 사용자 생성 (Phase 1 provisioning) | Admin |
 | PUT | `/users/:id` | 사용자 수정 (display_name, is_active 만) | Admin |
+| PUT | `/users/:id/suspend` | 일시 정지 토글 (Admin 결정, 재로그인 차단) | Admin |
+| PUT | `/users/:id/lock` | 보안 잠금 토글 (보안 위반/자동 트리거 시) | Admin |
 | DELETE | `/users/:id` | 사용자 영구 제거 (Phase 2에서 soft delete로 전환 예정) | Admin |

+**PUT /users/:id/suspend — Request:**
+
+```json
+{ "is_suspended": true, "reason": "temporary leave" }
+```
+> Suspend 상태 사용자는 로그인 시도 시 401 + `SUSPENDED` 코드. 기존 세션 즉시 종료(토큰 블랙리스트 추가).
+
+**PUT /users/:id/lock — Request:**
+
+```json
+{ "is_locked": true, "reason": "5회 비밀번호 실패" }
+```
+> Lock은 보안 사유 자동 트리거 가능. Unlock은 Admin 수동. Suspend와 독립적.
```

### contracts/data/DATA-02-entities.md §User

```diff
 | Field | Type | Description |
 |---|---|---|
 | user_id | int | PK |
 | email | string | unique |
 | password_hash | string | bcrypt |
 | display_name | string | |
 | role | enum | Admin / Operator / Viewer |
 | is_active | bool | soft delete flag (false = 제거됨) |
+| is_suspended | bool | Admin 결정 일시 정지. true 시 로그인 차단. WSOP LIVE Staff.isSuspended 대응 |
+| is_locked | bool | 보안 위반 자동/수동 잠금. Suspend와 독립. WSOP LIVE Staff.isLocked 대응 |
 | created_at | timestamp | |
 | updated_at | timestamp | |
```

### contracts/data/DATA-04-db-schema.md users 테이블

```diff
 CREATE TABLE users (
   user_id INTEGER PRIMARY KEY AUTOINCREMENT,
   email TEXT NOT NULL UNIQUE,
   password_hash TEXT NOT NULL,
   display_name TEXT,
   role TEXT NOT NULL CHECK(role IN ('admin','operator','viewer')),
   is_active BOOLEAN NOT NULL DEFAULT true,
+  is_suspended BOOLEAN NOT NULL DEFAULT false,
+  is_locked BOOLEAN NOT NULL DEFAULT false,
   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
 );
+CREATE INDEX idx_users_status ON users(is_active, is_suspended, is_locked);
```

### contracts/specs/BS-01-auth/BS-01-auth.md §Provisioning (신설)

```diff
+## Provisioning — 유저 생성 전략 (Phase별)
+
+> **WSOP LIVE 대응**: Staff App은 POST/DELETE 엔드포인트가 없다. 유저는 외부 시스템(WSOP 조직 관리)에서 provisioning되고 Staff API는 상태 제어만 담당. EBS는 조직 외부 provisioning 시스템 부재 시점에 한해 내부 CRUD를 병행.
+
+| Phase | 유저 생성 방식 | 근거 |
+|---|---|---|
+| Phase 1 (현행) | Admin 수동 + 초기 seed 스크립트 | 조직 통합 전, 소규모 운영 |
+| Phase 2 | Google OAuth 자동 생성 (`allowed_email_domains` whitelist) | Vegas 운영, 조직 계정 연동 |
+| Phase 3 | WSOP LIVE Staff 단방향 동기화 | 완전 통합 |
+
+## Suspend vs Lock 의미 차이
+
+| 항목 | Suspend | Lock |
+|---|---|---|
+| 트리거 | Admin 수동 결정 | 보안 위반 자동 or Admin 수동 |
+| 사유 | 휴가, 일시 부재, 역할 재배치 대기 | 비밀번호 5회 실패, 의심 접근, 징계 |
+| 해제 | Admin Un-suspend | Admin Unlock (자동 해제 없음) |
+| is_active 영향 | 독립 | 독립 |
+| 로그인 응답 | 401 `SUSPENDED` | 401 `LOCKED` |
+| 동시 적용 | Suspend + Lock 동시 가능 (둘 중 하나라도 true면 차단) | 동일 |
```

## Divergence from WSOP LIVE (Why)

1. **POST /users, DELETE /users 유지**: WSOP LIVE에는 없음.
   - **Why**: Phase 1에서 외부 provisioning 시스템 부재. Admin이 수동 생성/제거 불가능하면 개발 환경 자체가 작동 안 함. Phase 3에서 WSOP LIVE 동기화 전환 시 이 2 엔드포인트는 내부 전용으로 축소될 예정.
2. **URL에서 Series 경로 생략**: WSOP LIVE `/Series/{sId}/Staffs/*` → EBS `/users/*`.
   - **Why**: EBS Phase 1에서 다중 Series 동시 운영 시나리오 없음. Users는 Series 독립. 추후 다중 조직 지원 시 URL 재설계 가능.
3. **`users` 테이블명 유지 (Staffs 로 rename 안 함)**:
   - **Why**: DB 마이그레이션 비용 대비 이득 낮음. API 레벨 용어는 "Users"로 통일.

## 영향 분석

- **Team 1 (Lobby Frontend)**:
  - 기존 Users 관리 화면에 Suspend/Lock 토글 UI 추가 (3-4시간)
  - CSV Download 버튼 추가 (1시간)
  - 로그인 실패 응답의 `SUSPENDED`/`LOCKED` 코드 분기 메시지 (1시간)
- **Team 4**: 영향 없음 (CC는 Users 관리 UI 미포함)
- **Team 2 (Backend)**:
  - 3 신규 엔드포인트 구현 + is_suspended/is_locked 로그인 가드 + 토큰 블랙리스트 연동
  - Alembic revision 추가 (users 테이블 컬럼 2개 + 인덱스)
- **마이그레이션**: 기존 users 행은 `is_suspended=false, is_locked=false` 디폴트. 서비스 중단 없음.

## 대안 검토

1. **Role로 Suspend 표현 (role='suspended')**: 탈락. Role은 권한 분류, 상태는 직교 속성. 2축 분리가 정상.
2. **users 테이블을 staffs 로 rename**: 탈락. DB 마이그레이션 비용 > WSOP LIVE 용어 일치 이득.
3. **Suspend/Lock 단일 필드로 통합 (`status` enum)**: 탈락. 동시 적용 시나리오 존재(정지 중 보안 잠금 추가). 2개 독립 플래그가 표현력 높음.

## 검증 방법

- 단위:
  - Suspend/Lock 토글 멱등성 (같은 값 재요청 시 204 또는 멱등 응답)
  - 로그인 가드 (is_suspended=true OR is_locked=true → 401)
  - CSV 다운로드 컬럼 순서/인코딩(UTF-8 BOM)
- 통합:
  - Admin이 유저 Suspend → 해당 유저 활성 세션 즉시 만료 → WebSocket 연결 강제 종료
- WSOP LIVE 정렬:
  - `isSuspend`/`isLocked` 필드명 WSOP LIVE 원본과 camelCase↔snake_case 매핑표 작성

## 승인 요청

- [ ] Team 1 기술 검토 (Users 관리 UI 영향)
- [ ] 리스크 판정: `python tools/ccr_validate_risk.py --draft CCR-DRAFT-team2-20260414-users-staff-pattern.md`
- [ ] DB 마이그레이션 전략 (Alembic revision 순서 확정)

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1597768061 | Staff App API / Staff (GET list/download/detail + PUT Suspend/Lock) |
| 1960411325 | Enum (Role, Staff Status) |
